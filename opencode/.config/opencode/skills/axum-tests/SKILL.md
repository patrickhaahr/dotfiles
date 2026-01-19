---
name: axum-tests
description: Expert guide for testing Axum web applications. Use this skill when writing unit tests, integration tests, or setting up test infrastructure for Axum handlers, extractors, middleware, and full application testing. Covers tower::ServiceExt patterns, TestClient usage, mocking state/dependencies, and best practices.
---

# Axum Testing Best Practices

Comprehensive guide for unit testing and integration testing Axum web applications using idiomatic Rust patterns.

## Test Dependencies

Add these to your `Cargo.toml` for testing:

```toml
[dev-dependencies]
tokio = { version = "1", features = ["full", "test-util"] }
tower = { version = "0.5", features = ["util"] }
http-body-util = "0.1"
serde_json = "1"

# Optional but recommended
axum-test = "16"  # High-level test client (alternative to manual tower::ServiceExt)
```

## Testing Approaches

Axum supports two primary testing strategies:

| Approach | Use Case | Complexity | Speed |
|----------|----------|------------|-------|
| **Handler Unit Tests** | Test business logic in isolation | Low | Fast |
| **Integration Tests** | Test full request/response cycle | Medium | Medium |

## Handler Unit Tests

Test handlers directly by calling them as async functions. Best for testing business logic without HTTP overhead.

### Basic Handler Test

```rust
use axum::{extract::State, Json};
use serde::{Deserialize, Serialize};

#[derive(Clone)]
struct AppState {
    db: MockDb,
}

#[derive(Serialize)]
struct User {
    id: u64,
    name: String,
}

async fn get_user(
    State(state): State<AppState>,
    axum::extract::Path(id): axum::extract::Path<u64>,
) -> Result<Json<User>, StatusCode> {
    state.db.find_user(id)
        .await
        .map(Json)
        .ok_or(StatusCode::NOT_FOUND)
}

#[cfg(test)]
mod tests {
    use super::*;
    use axum::extract::Path;

    #[tokio::test]
    async fn test_get_user_success() {
        // Arrange
        let mock_db = MockDb::with_user(User { id: 1, name: "Alice".into() });
        let state = AppState { db: mock_db };

        // Act
        let result = get_user(
            State(state),
            Path(1),
        ).await;

        // Assert
        let Json(user) = result.unwrap();
        assert_eq!(user.name, "Alice");
    }

    #[tokio::test]
    async fn test_get_user_not_found() {
        let state = AppState { db: MockDb::empty() };

        let result = get_user(State(state), Path(999)).await;

        assert_eq!(result.unwrap_err(), StatusCode::NOT_FOUND);
    }
}
```

### Testing Handlers with JSON Body

```rust
use axum::Json;

#[derive(Deserialize)]
struct CreateUser {
    name: String,
    email: String,
}

async fn create_user(Json(payload): Json<CreateUser>) -> impl IntoResponse {
    (StatusCode::CREATED, Json(json!({"id": 1, "name": payload.name})))
}

#[tokio::test]
async fn test_create_user() {
    let payload = CreateUser {
        name: "Bob".into(),
        email: "bob@example.com".into(),
    };

    let (status, Json(body)) = create_user(Json(payload)).await;

    assert_eq!(status, StatusCode::CREATED);
    assert_eq!(body["name"], "Bob");
}
```

## Integration Tests with `tower::ServiceExt`

Test the full HTTP request/response cycle using `tower::ServiceExt::oneshot`. This is the **recommended approach** for most Axum tests.

### Basic Integration Test

```rust
use axum::{
    body::Body,
    http::{Request, StatusCode},
    routing::get,
    Router,
};
use http_body_util::BodyExt;
use tower::ServiceExt;  // Provides `oneshot` method

fn create_app() -> Router {
    Router::new()
        .route("/health", get(|| async { "OK" }))
        .route("/users/{id}", get(get_user))
}

#[tokio::test]
async fn test_health_check() {
    let app = create_app();

    let response = app
        .oneshot(
            Request::builder()
                .uri("/health")
                .body(Body::empty())
                .unwrap()
        )
        .await
        .unwrap();

    assert_eq!(response.status(), StatusCode::OK);

    let body = response.into_body().collect().await.unwrap().to_bytes();
    assert_eq!(&body[..], b"OK");
}
```

### Testing POST Requests with JSON

```rust
use axum::{
    body::Body,
    http::{header, Request, StatusCode},
    routing::post,
    Router,
};
use serde_json::json;

#[tokio::test]
async fn test_create_user_integration() {
    let app = Router::new().route("/users", post(create_user));

    let payload = json!({
        "name": "Alice",
        "email": "alice@example.com"
    });

    let response = app
        .oneshot(
            Request::builder()
                .method("POST")
                .uri("/users")
                .header(header::CONTENT_TYPE, "application/json")
                .body(Body::from(serde_json::to_string(&payload).unwrap()))
                .unwrap()
        )
        .await
        .unwrap();

    assert_eq!(response.status(), StatusCode::CREATED);
}
```

### Testing with Application State

```rust
use axum::extract::State;

#[derive(Clone)]
struct AppState {
    db_pool: PgPool,
    cache: Arc<RwLock<HashMap<String, String>>>,
}

fn create_test_app(state: AppState) -> Router {
    Router::new()
        .route("/users", get(list_users))
        .route("/users/{id}", get(get_user))
        .with_state(state)
}

#[tokio::test]
async fn test_with_state() {
    // Create test state with mocked dependencies
    let state = AppState {
        db_pool: create_test_pool().await,
        cache: Arc::new(RwLock::new(HashMap::new())),
    };

    let app = create_test_app(state);

    let response = app
        .oneshot(Request::builder().uri("/users").body(Body::empty()).unwrap())
        .await
        .unwrap();

    assert_eq!(response.status(), StatusCode::OK);
}
```

## Testing with TestClient

For more ergonomic testing, use `axum::test_helpers::TestClient` (internal) or the `axum-test` crate:

### Using axum-test Crate (Recommended)

```rust
use axum_test::TestServer;

#[tokio::test]
async fn test_with_test_server() {
    let app = create_app();
    let server = TestServer::new(app).unwrap();

    // GET request
    let response = server.get("/health").await;
    response.assert_status_ok();
    response.assert_text("OK");

    // POST with JSON
    let response = server
        .post("/users")
        .json(&json!({"name": "Alice"}))
        .await;
    response.assert_status(StatusCode::CREATED);
}
```

### Manual TestClient Pattern

```rust
use reqwest::Client;
use std::net::SocketAddr;
use tokio::net::TcpListener;

async fn spawn_test_server(app: Router) -> SocketAddr {
    let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();

    tokio::spawn(async move {
        axum::serve(listener, app).await.unwrap();
    });

    addr
}

#[tokio::test]
async fn test_full_server() {
    let app = create_app();
    let addr = spawn_test_server(app).await;

    let client = Client::new();
    let response = client
        .get(format!("http://{}/health", addr))
        .send()
        .await
        .unwrap();

    assert_eq!(response.status(), 200);
}
```

## Mocking Dependencies

### Trait-Based Mocking

Define traits for dependencies to enable mocking:

```rust
use async_trait::async_trait;

#[async_trait]
pub trait UserRepository: Send + Sync {
    async fn find_by_id(&self, id: u64) -> Option<User>;
    async fn create(&self, user: CreateUser) -> Result<User, DbError>;
}

// Production implementation
pub struct PgUserRepository {
    pool: PgPool,
}

#[async_trait]
impl UserRepository for PgUserRepository {
    async fn find_by_id(&self, id: u64) -> Option<User> {
        sqlx::query_as!(User, "SELECT * FROM users WHERE id = $1", id as i64)
            .fetch_optional(&self.pool)
            .await
            .ok()
            .flatten()
    }

    async fn create(&self, user: CreateUser) -> Result<User, DbError> {
        // ... implementation
    }
}

// Mock implementation for tests
#[cfg(test)]
pub struct MockUserRepository {
    users: std::sync::Mutex<Vec<User>>,
}

#[cfg(test)]
impl MockUserRepository {
    pub fn new() -> Self {
        Self { users: std::sync::Mutex::new(vec![]) }
    }

    pub fn with_users(users: Vec<User>) -> Self {
        Self { users: std::sync::Mutex::new(users) }
    }
}

#[cfg(test)]
#[async_trait]
impl UserRepository for MockUserRepository {
    async fn find_by_id(&self, id: u64) -> Option<User> {
        self.users.lock().unwrap().iter().find(|u| u.id == id).cloned()
    }

    async fn create(&self, user: CreateUser) -> Result<User, DbError> {
        let new_user = User { id: 1, name: user.name, email: user.email };
        self.users.lock().unwrap().push(new_user.clone());
        Ok(new_user)
    }
}
```

### Using State with Trait Objects

```rust
#[derive(Clone)]
pub struct AppState {
    pub users: Arc<dyn UserRepository>,
}

fn create_app(state: AppState) -> Router {
    Router::new()
        .route("/users/{id}", get(get_user))
        .with_state(state)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_with_mock_repository() {
        let mock_repo = MockUserRepository::with_users(vec![
            User { id: 1, name: "Alice".into(), email: "alice@test.com".into() }
        ]);

        let state = AppState {
            users: Arc::new(mock_repo),
        };

        let app = create_app(state);

        let response = app
            .oneshot(Request::builder().uri("/users/1").body(Body::empty()).unwrap())
            .await
            .unwrap();

        assert_eq!(response.status(), StatusCode::OK);
    }
}
```

## Testing Custom Extractors

### Testing FromRequestParts Extractors

```rust
use axum::{
    async_trait,
    extract::FromRequestParts,
    http::{request::Parts, StatusCode},
};

pub struct CurrentUser(pub User);

#[async_trait]
impl<S> FromRequestParts<S> for CurrentUser
where
    S: Send + Sync,
{
    type Rejection = StatusCode;

    async fn from_request_parts(parts: &mut Parts, _state: &S) -> Result<Self, Self::Rejection> {
        let auth_header = parts
            .headers
            .get("Authorization")
            .and_then(|v| v.to_str().ok())
            .ok_or(StatusCode::UNAUTHORIZED)?;

        // Validate token and get user...
        Ok(CurrentUser(User { id: 1, name: "Test".into() }))
    }
}

#[tokio::test]
async fn test_current_user_extractor() {
    async fn handler(CurrentUser(user): CurrentUser) -> String {
        user.name
    }

    let app = Router::new().route("/me", get(handler));

    // Test with valid auth
    let response = app.clone()
        .oneshot(
            Request::builder()
                .uri("/me")
                .header("Authorization", "Bearer valid-token")
                .body(Body::empty())
                .unwrap()
        )
        .await
        .unwrap();

    assert_eq!(response.status(), StatusCode::OK);

    // Test without auth
    let response = app
        .oneshot(Request::builder().uri("/me").body(Body::empty()).unwrap())
        .await
        .unwrap();

    assert_eq!(response.status(), StatusCode::UNAUTHORIZED);
}
```

## Testing Middleware

### Testing Layer Middleware

```rust
use axum::middleware::{self, Next};
use axum::response::Response;
use axum::http::Request;

async fn auth_middleware(
    req: Request<Body>,
    next: Next,
) -> Result<Response, StatusCode> {
    let auth_header = req.headers()
        .get("Authorization")
        .and_then(|v| v.to_str().ok());

    match auth_header {
        Some(token) if token.starts_with("Bearer ") => Ok(next.run(req).await),
        _ => Err(StatusCode::UNAUTHORIZED),
    }
}

#[tokio::test]
async fn test_auth_middleware() {
    let app = Router::new()
        .route("/protected", get(|| async { "secret" }))
        .layer(middleware::from_fn(auth_middleware));

    // Without auth header
    let response = app.clone()
        .oneshot(Request::builder().uri("/protected").body(Body::empty()).unwrap())
        .await
        .unwrap();
    assert_eq!(response.status(), StatusCode::UNAUTHORIZED);

    // With valid auth header
    let response = app
        .oneshot(
            Request::builder()
                .uri("/protected")
                .header("Authorization", "Bearer valid-token")
                .body(Body::empty())
                .unwrap()
        )
        .await
        .unwrap();
    assert_eq!(response.status(), StatusCode::OK);
}
```

## Testing Error Responses

```rust
use axum::response::{IntoResponse, Response};
use axum::Json;
use serde::Serialize;

#[derive(Debug, Serialize)]
struct ErrorResponse {
    error: String,
    message: String,
}

enum AppError {
    NotFound,
    BadRequest(String),
    Internal(anyhow::Error),
}

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let (status, error_response) = match self {
            AppError::NotFound => (
                StatusCode::NOT_FOUND,
                ErrorResponse { error: "not_found".into(), message: "Resource not found".into() }
            ),
            AppError::BadRequest(msg) => (
                StatusCode::BAD_REQUEST,
                ErrorResponse { error: "bad_request".into(), message: msg }
            ),
            AppError::Internal(_) => (
                StatusCode::INTERNAL_SERVER_ERROR,
                ErrorResponse { error: "internal_error".into(), message: "An error occurred".into() }
            ),
        };
        (status, Json(error_response)).into_response()
    }
}

#[tokio::test]
async fn test_error_responses() {
    async fn failing_handler() -> Result<(), AppError> {
        Err(AppError::NotFound)
    }

    let app = Router::new().route("/fail", get(failing_handler));

    let response = app
        .oneshot(Request::builder().uri("/fail").body(Body::empty()).unwrap())
        .await
        .unwrap();

    assert_eq!(response.status(), StatusCode::NOT_FOUND);

    let body = response.into_body().collect().await.unwrap().to_bytes();
    let error: ErrorResponse = serde_json::from_slice(&body).unwrap();
    assert_eq!(error.error, "not_found");
}
```

## Testing WebSockets

```rust
use axum::extract::ws::{Message, WebSocket, WebSocketUpgrade};
use tokio_tungstenite::connect_async;

async fn ws_handler(ws: WebSocketUpgrade) -> impl IntoResponse {
    ws.on_upgrade(handle_socket)
}

async fn handle_socket(mut socket: WebSocket) {
    while let Some(Ok(msg)) = socket.recv().await {
        if let Message::Text(text) = msg {
            socket.send(Message::Text(format!("Echo: {}", text).into())).await.ok();
        }
    }
}

#[tokio::test]
async fn test_websocket() {
    let app = Router::new().route("/ws", get(ws_handler));

    let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();

    tokio::spawn(async move {
        axum::serve(listener, app).await.unwrap();
    });

    let (mut ws_stream, _) = connect_async(format!("ws://{}/ws", addr))
        .await
        .unwrap();

    ws_stream.send(Message::Text("Hello".into())).await.unwrap();

    let msg = ws_stream.next().await.unwrap().unwrap();
    assert_eq!(msg, Message::Text("Echo: Hello".into()));
}
```

## Test Organization

### Recommended Project Structure

```
src/
├── handlers/
│   ├── mod.rs
│   └── users.rs       # Handler functions
├── routes/
│   └── mod.rs         # Router configuration
├── state.rs           # AppState definition
└── lib.rs

tests/
├── common/
│   └── mod.rs         # Shared test utilities
├── handlers/
│   └── users_test.rs  # Unit tests for handlers
└── integration/
    └── api_test.rs    # Full integration tests
```

### Shared Test Utilities

```rust
// tests/common/mod.rs
use crate::AppState;

pub async fn create_test_state() -> AppState {
    AppState {
        db: MockDb::new(),
        cache: Arc::new(RwLock::new(HashMap::new())),
    }
}

pub fn create_test_app() -> Router {
    // Create app with test configuration
}

pub async fn extract_body_json<T: DeserializeOwned>(response: Response<Body>) -> T {
    let body = response.into_body().collect().await.unwrap().to_bytes();
    serde_json::from_slice(&body).unwrap()
}
```

## Best Practices

### DO

- Use `tower::ServiceExt::oneshot` for integration tests (no server startup overhead)
- Create trait abstractions for external dependencies (databases, APIs)
- Test error paths and edge cases, not just happy paths
- Use `#[tokio::test]` for all async tests
- Keep test state isolated - each test should set up its own state
- Test middleware in isolation before testing with routes

### DON'T

- Don't start a real server for every test (use `oneshot` instead)
- Don't share mutable state between tests without proper synchronization
- Don't test private implementation details - test public API behavior
- Don't forget to test authentication/authorization edge cases
- Don't ignore response body validation - assert on both status AND body

### Testing Checklist

- [ ] Handler returns correct status codes
- [ ] Handler returns correct response body structure
- [ ] Handler handles invalid input gracefully
- [ ] Handler handles missing/unauthorized requests
- [ ] Middleware correctly modifies requests/responses
- [ ] Custom extractors reject invalid data
- [ ] Error responses follow consistent format
- [ ] Database operations are properly mocked
- [ ] Concurrent requests are handled correctly
