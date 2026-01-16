---
name: rust-tests
description: Comprehensive guide to Rust testing best practices, including structure, unit vs integration testing, and specialized patterns for Axum/Tower applications.
---

# Rust Testing Best Practices

This skill provides actionable guidance on structuring, writing, and maintaining Rust tests. It covers unit tests, integration tests, and specific patterns for async/HTTP services (Axum).

## 1. Core Testing Philosophy

| Type | Location | Access | Scope | Purpose |
|------|----------|--------|-------|---------|
| **Unit** | `src/*.rs` (in `mod tests`) | Private & Public | Single function/module | Verify logic in isolation. |
| **Integration** | `tests/*.rs` | Public API only | Crate/Module | Verify components work together. |
| **Doc** | `src/*.rs` (/// comments) | Public API only | Public Interface | Documentation examples that run as tests. |

## 2. Test Organization & Placement

### Unit Tests
**Rule**: Place unit tests in the same file as the code they test, within a `#[cfg(test)] mod tests { ... }` module.
**Why**: Allows testing private functions/state. Keeps tests close to implementation.
**Example**:
```rust
// src/lib.rs
fn internal_adder(a: i32, b: i32) -> i32 {
    a + b
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_internal_adder() {
        assert_eq!(internal_adder(2, 2), 4);
    }
}
```

### Integration Tests
**Rule**: Place integration tests in the `tests/` directory at the crate root.
**Why**: Compiles as a separate crate, ensuring you only test the *public* API (consumer contract).
**Note**: Only available for **Library** crates. Binary crates (`src/main.rs`) generally cannot be tested via `tests/` unless logic is moved to `src/lib.rs`.

### The Binary vs. Library Dilemma
**Problem**: `src/main.rs` symbols are not exported. `tests/*.rs` cannot see them.
**Best Practice**: Move your core logic (including `main` setup) into `src/lib.rs`. Make `src/main.rs` a thin wrapper that calls the library.
**Alternative (for simple binaries)**: Write integration-style tests inside `src/main.rs` modules, but this pollutes the binary code structure.

## 3. Async & HTTP Testing (Axum/Tower)

### The `tower::ServiceExt::oneshot` Pattern
This is the "Gold Standard" for testing Axum applications without spawning a real network server.

**Rule**: Use `tower::ServiceExt::oneshot` to send a single request to your router.
**Location**:
*   `tests/api_*.rs` if your app construction is exposed in `lib.rs` (Recommended).
*   `src/tests.rs` if your app is purely defined in `main.rs` (Acceptable for smaller services).

**Why**:
*   **Fast**: No TCP overhead, no port conflicts.
*   **Deterministic**: Errors propagate directly.

**Example**:
```rust
// In src/lib.rs, expose your app builder
pub fn app() -> Router {
    Router::new().route("/health", get(|| async { "ok" }))
}

// In tests/api_health.rs
use axum::{
    body::Body,
    http::{Request, StatusCode},
};
use tower::ServiceExt; // for `oneshot`

#[tokio::test]
async fn health_check_works() {
    let app = my_app::app();

    // `oneshot` consumes the service, perfect for one-off tests
    let response = app
        .oneshot(Request::builder().uri("/health").body(Body::empty()).unwrap())
        .await
        .unwrap();

    assert_eq!(response.status(), StatusCode::OK);
}
```

### Test Isolation
**Rule**: Avoid global state.
**Strategy**:
1.  **Database**: Wrap tests in a transaction that rolls back, OR create a unique random DB name per test (requires `sqlx` or similar helpers).
2.  **App State**: Dependency inject your specific test config into the `app()` builder.

## 4. Best Practices & Tooling

### Naming Conventions
*   **Files**: `tests/health_check.rs`, `tests/user_signup.rs` (Feature-based naming).
*   **Functions**: `test_should_fail_when_email_missing`, `test_happy_path_signup`. Avoid `test_1`.

### Helper Modules
**Rule**: In `tests/`, files are crates. `tests/common.rs` gets compiled as a test file (and fails due to no tests).
**Fix**: Use `tests/common/mod.rs`. This allows it to be imported as `mod common;` without the test runner treating it as a test suite.

### Recommended Crates
*   `tokio-test`: Essential for async testing utilities.
*   `tower`: For `ServiceExt` (oneshot).
*   `pretty_assertions`: Colored diffs for `assert_eq!`.
*   `insta`: Snapshot testing (great for large JSON responses).
*   `mockall`: Strong mocking library if you need to mock traits (e.g., external email service).
*   `wiremock`: Mock HTTP servers for external API dependencies.

## 5. Decision Matrix

| Scenario | Recommendation |
|----------|----------------|
| **Testing internal helper** | Unit test in `src/` |
| **Testing public API logic** | Integration test in `tests/` |
| **Testing HTTP Endpoints** | `tests/` using `tower::oneshot` (requires Lib crate structure) |
| **Testing CLI Args** | Integration test in `tests/` invoking the binary via `std::process::Command` or `assert_cmd` |
| **Complex Logic Combinations** | Property-based testing (`proptest`) |
