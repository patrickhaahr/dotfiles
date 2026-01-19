---
name: sqlx
description: Expert guide for using the SQLx Rust crate (async, pure Rust SQL toolkit). Use this skill when the user is working with SQL databases in Rust using SQLx.
---

## Overview
SQLx is an async, pure Rust SQL crate featuring compile-time checked queries without a DSL. It supports PostgreSQL, MySQL, MariaDB, and SQLite.
It is **not** an ORM but a toolkit for running raw SQL queries safely and efficiently.

## Capabilities
*   **Compile-time verification**: Checks queries against a live database at compile time using macros (`query!`, `query_as!`).
*   **Async/Await**: Built from the ground up for async execution (tokio, async-std, actix).
*   **Database Agnostic**: Supports multiple databases with a consistent API.
*   **Pure Rust**: Drivers are written in pure Rust (except SQLite which links to C library).
*   **Connection Pooling**: Built-in pooling with `Pool`.

## Usage

### Installation
Add `sqlx` to `Cargo.toml` with the necessary features (runtime + database).

```toml
# Example: Tokio + Postgres
[dependencies]
sqlx = { version = "0.8", features = [ "runtime-tokio", "tls-native-tls", "postgres" ] }
```

### Connection
Create a connection pool (recommended) or a single connection.

```rust
use sqlx::postgres::PgPoolOptions;

let pool = PgPoolOptions::new()
    .max_connections(5)
    .connect("postgres://user:pass@localhost/db").await?;
```

### Querying
Use `sqlx::query` (unprepared/prepared) or `sqlx::query!` (compile-time checked).

#### Runtime Query (Dynamic)
```rust
let row: (i64,) = sqlx::query_as("SELECT id FROM users WHERE email = $1")
    .bind("user@example.com")
    .fetch_one(&pool).await?;
```

#### Compile-time Checked Query (Macros)
Requires `DATABASE_URL` environment variable or `.env` file.

```rust
let countries = sqlx::query!(
        "SELECT country, count FROM countries WHERE organization = ?",
        organization
    )
    .fetch_all(&pool).await?;
```

### Migrations
Add migrations with `sqlx migrate add -r <description>` (use underscores instead of spaces in description). After adding, update the SQL code in `migrations/<timestamp>_<description>.up.sql` and `migrations/<timestamp>_<description>.down.sql`. Run migrations with `sqlx migrate run`. See `sqlx --help` and `sqlx migrate --help` for more options.

```rust
sqlx::migrate!("./migrations").run(&pool).await?;
```

## References
*   **Documentation**: [docs.rs/sqlx](https://docs.rs/sqlx) (Primary API reference)
*   **Repository**: [github.com/launchbadge/sqlx](https://github.com/launchbadge/sqlx) (Examples, FAQ)
*   **Examples**: See the `examples/` directory in the repository for patterns.
