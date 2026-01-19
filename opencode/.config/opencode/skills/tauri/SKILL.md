---
name: tauri
description: Expert guide and best practices for building secure, cross-platform applications with Tauri v2. Covers capability-based security, plugin architecture, build optimization, and performance patterns.
---

# Tauri v2 Best Practices Guide

**Context:** Modern Tauri v2 development for cross-platform desktop and mobile applications

---

## 1. Security: Capability-Based Permission Model

**Practice:** Define granular capabilities in `src-tauri/capabilities/` instead of using wildcard permissions.

**Rationale:** Tauri v2 implements the principle of least privilege through explicit capability boundaries. Each capability creates a security sandbox between frontend and backend, preventing compromised frontend code from accessing unintended system resources.

**Implementation:**
```json
// src-tauri/capabilities/main.json
{
  "$schema": "../gen/schemas/desktop-schema.json",
  "identifier": "main-capability",
  "description": "Core capability for main window operations",
  "windows": ["main"],
  "permissions": [
    "core:default",
    "core:path:default",
    {
      "identifier": "fs:scope-app-recursive",
      "allow": [{"path": "$APPDATA/*"}]
    }
  ]
}
```

**Key Points:**
- Always include `$schema` for IDE validation
- Use descriptive `identifier` and `description` fields
- Scope filesystem access to specific directories
- Reference capabilities in `tauri.conf.json` under `app.security.capabilities`

---

## 2. Plugin Architecture: Modular Design

**Practice:** Treat all functionality as plugins. Use `tauri add <plugin>` for dependency management.

**Rationale:** Plugin-based architecture reduces compile times through selective compilation and makes dependencies explicit. The binary only includes functionality that is actually used.

**Commands:**
```bash
bun tauri add fs
bun tauri add shell
bun tauri add dialog
bun tauri add notification
```

**Rust initialization:**
```rust
// src-tauri/src/lib.rs
#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_fs::init())
        .plugin(tauri_plugin_shell::init())
        .plugin(tauri_plugin_dialog::init())
        .invoke_handler(tauri::generate_handler![my_custom_command])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
```

**Cargo.toml configuration:**
```toml
[dependencies]
tauri-plugin-fs = "2.0"
tauri-plugin-shell = "2.0"
tauri-plugin-dialog = "2.0"
# or from Git
tauri-plugin-fs = { git = "https://github.com/tauri-apps/plugins-workspace", branch = "v2" }
```

---

## 3. Build Optimization: Cargo Profile Configuration

**Practice:** Configure release profile for optimal size and speed balance.

**Rationale:** Aggressive optimization during compilation produces smaller, faster binaries. The compile time investment is amortized over many builds.

**Configuration:**
```toml
# src-tauri/Cargo.toml
[profile.release]
codegen-units = 1
lto = "fat"
opt-level = "z"
panic = "abort"
strip = true

[profile.dev]
debug = true
```

**Bundle optimization in tauri.conf.json:**
```json
{
  "build": {
    "removeUnusedCommands": true,
    "beforeBuildCommand": "",
    "beforeDevCommand": ""
  }
}
```

---

## 4. Memory Management: Backpressure via Pagination

**Practice:** Stream large datasets with pagination instead of monolithic JSON payloads.

**Rationale:** Prevents IPC serialization overhead from dominating memory usage. Frontend requests data at consumption rate, applying natural backpressure.

**Implementation:**
```rust
#[tauri::command]
async fn get_directory_entries(
    path: String,
    offset: usize,
    limit: usize
) -> Result<DirectoryPage, String> {
    let entries: Vec<_> = std::fs::read_dir(path)?
        .skip(offset)
        .take(limit)
        .collect::<Result<Vec<_>, _>>()?;
    
    Ok(DirectoryPage {
        entries: entries.into_iter().map(EntryInfo::from).collect(),
        has_more: entries.len() == limit,
        total_count: /* calculate if needed */
    })
}
```

---

## 5. Async Runtime: CPU Work Isolation

**Practice:** Use `tokio::task::spawn_blocking` for CPU-intensive operations.

**Rationale:** Prevents blocking the tokio event loop. Maintains command responsiveness by isolating CPU work to a separate thread pool.

**Implementation:**
```rust
#[tauri::command]
async fn process_large_file(path: String) -> Result<String, String> {
    let handle = tokio::task::spawn_blocking(move || {
        let content = std::fs::read_to_string(path)?;
        // CPU-intensive processing here
        Ok::<_, String>(process_content(content))
    });
    
    handle.await.map_err(|e| e.to_string())?
}
```

---

## 6. Cross-Platform: Conditional Compilation

**Practice:** Abstract platform differences early using `cfg` attributes.

**Rationale:** System WebViews differ significantly (WebKitGTK, WKWebView, WebView2). Early abstraction prevents technical debt and ensures consistent behavior across platforms.

**Implementation:**
```rust
#[cfg(target_os = "linux")]
fn configure_webview() {
    std::env::set_var("WEBKIT_DISABLE_DMABUF_RENDERER", "1");
}

#[cfg(target_os = "windows")]
fn configure_webview() {
    std::env::set_var("WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS", 
        "--disable-features=msWebOOUI");
}

#[cfg(target_os = "macos")]
fn configure_webview() {
    // macOS-specific optimizations if needed
}
```

**Platform-specific capabilities:**
```json
// src-tauri/capabilities/desktop.json
{
  "$schema": "../gen/schemas/desktop-schema.json",
  "identifier": "desktop-capability",
  "platforms": ["linux", "macos", "windows"],
  "windows": ["main"],
  "permissions": ["global-shortcut:allow-register"]
}
```

---

## 7. Development Workflow: Tool Integration

**Practice:** Use consistent script commands and configure editor integration.

**Rationale:** Consistent commands across the development environment improve productivity. Modern package managers like `bun` offer speed and strict validation.

**package.json:**
```json
{
  "scripts": {
    "dev": "tauri dev",
    "build": "tauri build",
    "lint": "bun eslint .",
    "format": "prettier --write ."
  }
}
```

**Trust Boundaries Configuration:**
```json
// src-tauri/tauri.conf.json
{
  "app": {
    "security": {
      "csp": "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'",
      "capabilities": ["main-capability"]
    }
  }
}
```

---

## 8. Command Registration and Scope Control

**Practice:** Explicitly register and scope custom commands.

**Rationale:** By default, all registered commands are accessible to all windows. For finer control, use `AppManifest::commands` in build.rs.

**Implementation:**
```rust
// src-tauri/build.rs
fn main() {
    tauri_build::try_build(
        tauri_build::Attributes::new()
            .app_manifest(tauri_build::AppManifest::new().commands(&["safe_command"])),
    )
    .unwrap();
}
```

**Isolation pattern for high-security scenarios:**
```json
// src-tauri/tauri.conf.json
{
  "build": {
    "frontendDist": "../dist",
    "devPath": "http://localhost:1420"
  },
  "app": {
    "security": {
      "pattern": {
        "use": "isolation",
        "options": {
          "dir": "../dist-isolation"
        }
      }
    }
  }
}
```

---

## 9. Remote URL Access Control

**Practice:** Explicitly configure remote URL access when needed.

**Rationale:** By default, the Tauri API is only accessible to bundled code. Remote sources require explicit capability configuration.

**Implementation:**
```json
// src-tauri/capabilities/remote.json
{
  "$schema": "../gen/schemas/remote-schema.json",
  "identifier": "remote-capability",
  "description": "Allow remote development sources",
  "windows": ["main"],
  "remote": {
    "urls": ["https://*.localhost", "http://localhost:*"]
  },
  "permissions": ["core:default"]
}
```

**Security Note:** On Linux and Android, Tauri cannot distinguish between iframe requests and window requests. Use this feature cautiously.

---

## 10. Content Security Policy (CSP)

**Practice:** Define strict CSP in tauri.conf.json.

**Rationale:** CSP provides an additional security layer against XSS attacks and unauthorized script execution.

**Configuration:**
```json
{
  "app": {
    "security": {
      "csp": "default-src 'self'; connect-src 'self' https://api.example.com; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:;"
    }
  }
}
```

---

## 11. Window-Specific Capabilities

**Practice:** Assign different capabilities to different windows.

**Rationale:** Reduce attack surface by giving each window only the permissions it needs.

**Implementation:**
```json
// src-tauri/capabilities/admin.json
{
  "$schema": "../gen/schemas/desktop-schema.json",
  "identifier": "admin-capability",
  "description": "Admin window with filesystem access",
  "windows": ["admin-panel"],
  "permissions": ["core:default", "fs:default", "shell:allow-open"]
}

// src-tauri/capabilities/user.json
{
  "$schema": "../gen/schemas/desktop-schema.json",
  "identifier": "user-capability",
  "description": "Regular user window with limited access",
  "windows": ["main", "settings"],
  "permissions": ["core:default", "dialog:default"]
}
```

---

## 12. Error Handling and Validation

**Practice:** Validate all inputs and return meaningful error messages.

**Rationale:** Frontend code should receive actionable error information while hiding implementation details.

**Implementation:**
```rust
#[tauri::command]
async fn read_config(path: String) -> Result<Config, String> {
    // Validate path
    if path.is_empty() {
        return Err("Path cannot be empty".to_string());
    }
    
    // Check file exists
    if !std::path::Path::new(&path).exists() {
        return Err(format!("File not found: {}", path));
    }
    
    // Read and parse
    std::fs::read_to_string(path)
        .map_err(|e| format!("Failed to read file: {}", e))?
        .parse()
        .map_err(|e| format!("Failed to parse config: {}", e))
}
```

---

## 13. State Management

**Practice:** Use Tauri state for managing application-wide resources.

**Rationale:** State provides a clean way to share resources across commands and manage application lifecycle.

**Implementation:**
```rust
struct AppState {
    db: Mutex<Database>,
    config: RwLock<AppConfig>,
}

#[tauri::command]
async fn get_config(state: tauri::State<AppState>) -> Result<AppConfig, String> {
    Ok(*state.config.read().map_err(|e| e.to_string())?)
}

#[tauri::command]
async fn update_config(
    new_config: AppConfig,
    state: tauri::State<AppState>,
) -> Result<(), String> {
    let mut config = state.config.write().map_err(|e| e.to_string())?;
    *config = new_config;
    Ok(())
}

fn main() {
    let state = AppState {
        db: Mutex::new(Database::new()?),
        config: RwLock::new(AppConfig::default()),
    };
    
    tauri::Builder::default()
        .manage(state)
        .invoke_handler(tauri::generate_handler![get_config, update_config])
        .run(tauri::generate_context!())
        .expect("error running app");
}
```

---

## 14. Performance Monitoring

**Practice:** Implement IPC performance tracking for critical paths.

**Rationale:** Identify bottlenecks in the IPC layer before they become user-facing issues.

**Implementation:**
```rust
use std::time::Instant;

#[tauri::command]
async fn expensive_operation(input: String) -> Result<String, String> {
    let start = Instant::now();
    
    // Perform operation
    let result = process_input(input)?;
    
    // Log timing (consider making this conditional)
    let elapsed = start.elapsed();
    if elapsed > Duration::from_millis(100) {
        println!("Warning: expensive_operation took {:?}", elapsed);
    }
    
    Ok(result)
}
```

---

## Core Principle: Explicit Contracts

Tauri v2 enforces **explicit contracts** between frontend and backend. Every command, permission, and plugin must be declared. This verbosity is Rust's safety model applied to the web/desktop boundary.

**Engineering Question:** "What is the minimum API surface does my frontend require?"

This principle underlies all best practices and ensures:
- Minimal attack surface
- Clear trust boundaries
- Explicit dependencies
- Predictable behavior

---

## Quick Reference

### Directory Structure
```
tauri-app/
├── src/                    # Frontend source
├── src-tauri/
│   ├── capabilities/       # Security permissions
│   │   ├── main.json
│   │   ├── desktop.json
│   │   └── mobile.json
│   ├── src/                # Rust backend
│   ├── Cargo.toml
│   └── tauri.conf.json
├── package.json
└── README.md
```

### Essential Commands
```bash
bun tauri add fs shell dialog notification
bun tauri dev
bun tauri build
cargo clippy -- -D warnings
```

### Security Checklist
- [ ] All capabilities include `$schema`
- [ ] Filesystem permissions are scoped (not default)
- [ ] CSP is configured
- [ ] Remote URLs are explicitly allowed if needed
- [ ] Windows have minimal required permissions
- [ ] Input validation on all commands
- [ ] Error messages don't leak sensitive information
