---
name: axum
description: Expert guide and best practices for building production-ready web APIs with Axum 0.8+ in Rust. Use this skill when developing, refactoring, or structuring Axum applications.
---

# Rust Axum Best Practices Guide

A production-ready reference for building robust web APIs with Axum 0.8+.

## Project Structure

Organize your application with clear separation of concerns to enable scalability and maintainability.

```
src/
├── main.rs          # Entry point with minimal logic
├── config.rs        # Configuration management
├── state.rs         # Application state definition
├── error.rs         # Centralized error types
├── routes/          # Route modules by domain
│   ├── mod.rs
│   ├── health.rs    # Health check endpoints
│   └── users.rs     # User-related routes
├── handlers/        # Request handlers
│   ├── mod.rs
│   └── users.rs
├── models/          # Data structures
│   ├── mod.rs
│   └── user.rs
├── middleware/      # Custom middleware
│   ├── mod.rs
│   └── auth.rs
└── extractors/      # Custom extractors
    └── mod.rs
```

**Why this structure works:**
- **Domain-based routing**: Group related routes together; each module exports its own `Router`
- **Handler separation**: Keep business logic isolated from routing concerns
- **Centralized concerns**: Single source of truth for errors, config, and state
- **Scalability**: Easy to add new domains without touching existing files

## Dependencies

Use a minimal, focused set of production-ready crates:

```toml
[dependencies]
# Core async runtime
axum = { version = "0.8", features = ["macros"] }
tokio = { version = "1", features = ["full"] }
tower = { version = "0.5", features = ["timeout", "limit"] }
tower-http = { version = "0.6", features = [
    "cors",
    "trace",
    "compression-gzip",
    "request-id",
    "timeout",
] }

# Serialization
serde = { version = "1", features = ["derive"] }
serde_json = "1"

# Validation
validator = { version = "0.16", features = ["derive"] }

# Error handling
thiserror = "1"
anyhow = "1"

# Observability
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["env-filter", "json"] }

# Utilities
uuid = { version = "1", features = ["v4", "serde"] }
chrono = { version = "0.4", features = ["serde"] }
```

**Key choices explained:**
- **`tower-http` features**: Select only needed middleware to minimize compile time
- **`thiserror` + `anyhow`**: Use `thiserror` for library errors, `anyhow` for application-level error propagation
- **`validator`**: Compile-time guaranteed validation via derive macros

## Application State Management

### Pattern 1: Immutable State with `Arc`

For configuration and read-only data:

```rust
use std::sync::Arc;

#[derive(Clone)]
pub struct AppState {
    pub config: Arc<Config>,
    pub db_pool: PgPool,  // sqlx pools are already internally Arc'd
}

// In main.rs
let state = AppState::new(&config).await;
let app = Router::new()
    .merge(routes::api::router())
    .with_state(state);
```

**Why `Arc`?** Enables cheap cloning of state for each worker thread while maintaining a single source of truth. The `Clone` derive makes handler signatures cleaner.

### Pattern 2: Mutable State with `RwLock`

For in-memory caches or counters:

```rust
use std::sync::Arc;
use tokio::sync::RwLock;

#[derive(Clone)]
pub struct AppState {
    pub cache: Arc<RwLock<HashMap<String, Value>>>,
}

// Handler usage
async fn get_handler(State(state): State<AppState>) -> impl IntoResponse {
    let cache = state.cache.read().await;  // Non-blocking read lock
    match cache.get("key") {
        Some(val) => Json(val).into_response(),
        None => StatusCode::NOT_FOUND.into_response(),
    }
}
```

**Trade-off analysis:**
- **`RwLock`**: Multiple readers, single writer - ideal for read-heavy workloads
- **`Mutex`**: Simpler, but blocks all concurrent access - better for write-heavy or short critical sections
- **Atomic types**: For simple primitives like counters, use `std::sync::atomic` for lock-free operations

### Pattern 3: Substates with `FromRef`

Extract smaller state slices for modularity:

```rust
use axum::extract::FromRef;

#[derive(Clone)]
struct AppState {
    db: PgPool,
    cache: RedisClient,
}

#[derive(Clone)]
struct ApiState {
    db: PgPool,
}

impl FromRef<AppState> for ApiState {
    fn from_ref(state: &AppState) -> Self {
        Self { db: state.db.clone() }
    }
}

// Handler can now use either State<AppState> or State<ApiState>
```

**Benefit**: Type-safe state extraction without passing the entire application state to every handler.

## Error Handling

### Centralized Error Type

Define a single `AppError` enum for consistent API responses:

```rust
// src/error.rs
use axum::{http::StatusCode, response::IntoResponse, Json};
use serde::Serialize;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum AppError {
    #[error("Resource not found")]
    NotFound,
    #[error("Validation error: {0}")]
    Validation(String),
    #[error("Unauthorized")]
    Unauthorized,
    #[error("Forbidden")]
    Forbidden,
    #[error("Conflict: {0}")]
    Conflict(String),
    #[error("Internal server error")]
    Internal(#[from] anyhow::Error),
}

#[derive(Serialize)]
struct ErrorResponse {
    error: String,
    message: String,
}

impl IntoResponse for AppError {
    fn into_response(self) -> axum::response::Response {
        let (status, error_type, message) = match &self {
            AppError::NotFound => (StatusCode::NOT_FOUND, "not_found", self.to_string()),
            AppError::Validation(msg) => (StatusCode::BAD_REQUEST, "validation_error", msg.clone()),
            AppError::Unauthorized => (StatusCode::UNAUTHORIZED, "unauthorized", self.to_string()),
            AppError::Forbidden => (StatusCode::FORBIDDEN, "forbidden", self.to_string()),
            AppError::Conflict(msg) => (StatusCode::CONFLICT, "conflict", msg.clone()),
            AppError::Internal(err) => {
                tracing::error!(error = ?err, "Internal server error");
                (StatusCode::INTERNAL_SERVER_ERROR, "internal_error", "An internal error occurred".to_string())
            }
        };

        let body = ErrorResponse {
            error: error_type.to_string(),
            message,
        };
        (status, Json(body)).into_response()
    }
}

pub type Result<T> = std::result::Result<T, AppError>;
```

**Why this pattern:**
- **Type safety**: Compiler guarantees error handling in handlers
- **Consistent responses**: All errors serialize to the same JSON structure
- **Security**: Internal errors are logged but not exposed to clients
- **Ergonomics**: `?` operator works seamlessly with `anyhow::Error` conversion

### Handler Usage

```rust
async fn create_user(
    State(state): State<AppState>,
    Json(payload): Json<CreateUser>,
) -> Result<(StatusCode, Json<User>)> {
    validate_payload(&payload)?;  // Returns AppError::Validation
    let user = state.db.create_user(payload).await?;  // Uses anyhow::Error -> AppError::Internal
    Ok((StatusCode::CREATED, Json(user)))
}
```

## Middleware Architecture

### Leverage Tower Ecosystem

Axum's key strength is Tower interoperability. Use `tower::ServiceBuilder` for intuitive ordering:

```rust
use tower::ServiceBuilder;
use tower_http::{
    compression::CompressionLayer,
    cors::CorsLayer,
    request_id::{MakeRequestUuid, PropagateRequestIdLayer, SetRequestIdLayer},
    timeout::TimeoutLayer,
    trace::TraceLayer,
};

let app = Router::new()
    .merge(routes::health::router())
    .merge(routes::api::router())
    .layer(
        ServiceBuilder::new()
            // Executes top-to-bottom
            .layer(TraceLayer::new_for_http())
            .layer(SetRequestIdLayer::x_request_id(MakeRequestUuid))
            .layer(PropagateRequestIdLayer::x_request_id())
            .layer(TimeoutLayer::new(Duration::from_secs(30)))
            .layer(CompressionLayer::new())
            .layer(CorsLayer::permissive())
    )
    .with_state(state);
```

**Middleware execution order** (top-to-bottom in `ServiceBuilder`):
1. **TraceLayer**: Log request start
2. **SetRequestIdLayer**: Generate request ID
3. **PropagateRequestIdLayer**: Forward ID to downstream services
4. **TimeoutLayer**: Enforce request deadline
5. **CompressionLayer**: Compress response body
6. **CorsLayer**: Add CORS headers
7. **Handler**: Your business logic

### Custom Middleware Functions

For simple transformations, use `axum::middleware::from_fn`:

```rust
use axum::{
    middleware::{self, Next},
    response::Response,
    http::Request,
};

async fn log_requests(req: Request, next: Next) -> Response {
    let uri = req.uri().clone();
    let method = req.method().clone();
    let start = std::time::Instant::now();
    
    let response = next.run(req).await;
    
    tracing::info!(
        method = %method,
        uri = %uri,
        status = %response.status(),
        elapsed_ms = start.elapsed().as_millis(),
        "Request completed"
    );
    
    response
}

// Apply to specific routes
let app = Router::new()
    .route("/api/users", get(list_users))
    .route_layer(middleware::from_fn(log_requests));
```

## Routing Patterns

### Modular Route Composition

Each domain exports its own router:

```rust
// src/routes/users.rs
use axum::{routing::{get, post}, Router};

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/users", post(create_user))
        .route("/users/:id", get(get_user))
        .route("/users/:id", put(update_user))
        .route("/users/:id", delete(delete_user))
}

// In main.rs
let app = Router::new()
    .merge(routes::users::router())
    .merge(routes::posts::router());
```

**Path parameter syntax**: Axum 0.8 uses `{id}` instead of `:id` to align with OpenAPI standards.

### Method Router Chaining

For REST resources, chain methods on the same path:

```rust
.use axum::routing::MethodRouter;

let user_routes = Router::new()
    .route("/users/:id", MethodRouter::new()
        .get(get_user)
        .put(update_user)
        .delete(delete_user)
    );
```

## Extractors

### Built-in Extractors

Order matters: path and header extractors must come before body extractors:

```rust
async fn handler(
    Path(user_id): Path<Uuid>,                    // Extract path param
    Query(params): Query<Pagination>,              // Extract query string
    TypedHeader(auth): TypedHeader<Authorization>, // Extract header
    Json(payload): Json<CreateUser>,               // Extract body (last!)
) -> Result<Json<User>> {
    // Handler logic
}
```

**Extractor failure handling**: If any extractor fails, Axum automatically returns a 400/404 response without calling your handler. This is by design for type safety.

### Custom Extractors

Implement `FromRequestParts` for authentication:

```rust
use axum::{
    async_trait,
    extract::FromRequestParts,
    http::{request::Parts, StatusCode},
    RequestPartsExt,
};

pub struct CurrentUser(User);

#[async_trait]
impl FromRequestParts<AppState> for CurrentUser {
    type Rejection = AppError;

    async fn from_request_parts(
        parts: &mut Parts,
        state: &AppState,
    ) -> Result<Self, Self::Rejection> {
        let TypedHeader(auth) = parts
            .extract::<TypedHeader<Authorization<Bearer>>>()
            .await
            .map_err(|_| AppError::Unauthorized)?;
        
        let user = state.db.get_user_by_token(auth.token()).await
            .map_err(|_| AppError::Unauthorized)?;
        
        Ok(Self(user))
    }
}

// Usage
async fn protected_handler(
    CurrentUser(user): CurrentUser,
) -> Result<Json<UserProfile>> {
    // User is guaranteed to be authenticated here
}
```

## Configuration Management

### Environment-based Config

```rust
// src/config.rs
#[derive(Clone)]
pub struct Config {
    pub port: u16,
    pub environment: String,
    pub database_url: String,
    pub jwt_secret: String,
}

impl Config {
    pub fn from_env() -> Self {
        Self {
            port: std::env::var("PORT")
                .ok()
                .and_then(|p| p.parse().ok())
                .unwrap_or(3000),
            environment: std::env::var("ENVIRONMENT")
                .unwrap_or_else(|_| "development".to_string()),
            database_url: std::env::var("DATABASE_URL")
                .expect("DATABASE_URL must be set"),
            jwt_secret: std::env::var("JWT_SECRET")
                .expect("JWT_SECRET must be set"),
        }
    }

    pub fn is_production(&self) -> bool {
        self.environment == "production"
    }
}
```

**Best practice**: Fail fast on missing required env vars in production; provide sensible defaults only for development.

## Graceful Shutdown

Handle SIGTERM and SIGINT for production deployments:

```rust
use tokio::signal;

async fn shutdown_signal() {
    let ctrl_c = async {
        signal::ctrl_c().await
            .expect("Failed to install Ctrl+C handler");
    };

    #[cfg(unix)]
    let terminate = async {
        signal::unix::signal(signal::unix::SignalKind::terminate())
            .expect("Failed to install SIGTERM handler")
            .recv()
            .await;
    };

    #[cfg(not(unix))]
    let terminate = std::future::pending::<()>();

    tokio::select! {
        _ = ctrl_c => {
            tracing::info!("Received Ctrl+C, starting graceful shutdown");
        }
        _ = terminate => {
            tracing::info!("Received SIGTERM, starting graceful shutdown");
        }
    }
}

// In main.rs
axum::serve(listener, app)
    .with_graceful_shutdown(shutdown_signal())
    .await
    .unwrap();
```

## Testing

### Handler Unit Tests

Test handlers directly without starting a server:

```rust
#[tokio::test]
async fn test_create_user() {
    let state = setup_test_state().await;
    let payload = CreateUser { name: "Alice".into() };
    
    let response = handlers::users::create_user(
        State(state),
        Json(payload),
    ).await.unwrap();
    
    assert_eq!(response.0, StatusCode::CREATED);
    assert_eq!(response.1 .0.name, "Alice");
}
```

### Integration Tests with `tower::ServiceExt`

```rust
use tower::ServiceExt;  // for `oneshot`

#[tokio::test]
async fn test_health_check() {
    let app = create_test_app().await;
    
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
}
```

## Production Deployment Checklist

### Observability

```rust
// Initialize tracing with JSON output for log aggregation
tracing_subscriber::registry()
    .with(tracing_subscriber::EnvFilter::try_from_default_env()
        .unwrap_or_else(|_| "info,tower_http=debug".into()))
    .with(tracing_subscriber::fmt::layer().json())
    .init();

// Add request ID tracing
layer(SetRequestIdLayer::x_request_id(MakeRequestUuid))
layer(PropagateRequestIdLayer::x_request_id())
```

### Security

```rust
// CORS configuration (don't use permissive in production)
CorsLayer::new()
    .allow_origin("https://yourdomain.com".parse::<HeaderValue>().unwrap())
    .allow_methods([Method::GET, Method::POST, Method::PUT, Method::DELETE])
    .allow_headers([CONTENT_TYPE, AUTHORIZATION])
    .max_age(Duration::from_secs(86400))
```

### Performance

```rust
// Timeout configuration
.layer(TimeoutLayer::new(Duration::from_secs(30)))

// Request body size limits
.route("/upload", post(upload_handler))
.layer(DefaultBodyLimit::max(10 * 1024 * 1024))  // 10MB
```

## Common Anti-Patterns to Avoid

### ❌ Using `Extension` for State

```rust
// DON'T: Runtime errors if you forget to .layer(Extension(...))
.layer(Extension(pool))

// DO: Compile-time guarantee
.with_state(AppState { db: pool })
```

**Rationale**: `State<T>` is type-safe; `Extension` will compile but panic at runtime if missing.

### ❌ Blocking in Async Handlers

```rust
// DON'T: Blocks the executor thread
let data = std::fs::read_to_string("file.txt")?;

// DO: Use tokio's async filesystem
let data = tokio::fs::read_to_string("file.txt").await?;
```

### ❌ Overly Granular Routes

```rust
// DON'T: Split related routes across files
// routes/user_create.rs, routes/user_get.rs, routes/user_delete.rs

// DO: Group by resource
// routes/users.rs contains all /users/* routes
```

### ❌ Ignoring Extractor Order

```rust
// DON'T: Body extractor before path
async fn bad(Json(body): Json<Body>, Path(id): Path<Uuid>) { }

// DO: Path and query first
async fn good(Path(id): Path<Uuid>, Json(body): Json<Body>) { }
```

## State Management Decision Tree

```
Need shared state?
├── Immutable (config, pools)?
│   └── Use Arc<T> directly
├── Mutable (cache, counters)?
│   └── Use Arc<RwLock<T>> or Arc<Mutex<T>>
│       ├── Read-heavy? → RwLock
│       └── Write-heavy? → Mutex
├── Multiple state types?
│   └── Use FromRef pattern for substates
└── Per-request data?
    └── Use custom extractors, not global state
```
