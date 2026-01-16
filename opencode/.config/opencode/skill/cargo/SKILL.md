---
name: cargo
description: Guide for managing Cargo dependencies using cargo CLI commands instead of manually editing Cargo.toml. Use this skill when working on Rust projects that need dependency management.
---

## Overview

This skill ensures dependencies are always added to Rust projects using `cargo add` CLI commands rather than manually editing `Cargo.toml`. This guarantees the latest compatible versions are used and maintains proper dependency resolution.

## Usage

### Adding Dependencies

**NEVER** manually edit `Cargo.toml` to add dependencies. Always use:

```bash
cargo add crate_name
```

**With features:**
```bash
cargo add crate_name --features "feature1,feature2"
```

**Dev dependencies:**
```bash
cargo add crate_name --dev
```

**Build dependencies:**
```bash
cargo add crate_name --build
```

**With version constraint (only when necessary):**
```bash
cargo add crate_name --version "^1.0.0"
```

### Removing Dependencies

Use `cargo remove` instead of manually deleting from `Cargo.toml`:

```bash
cargo remove crate_name
cargo remove crate_name --dev
cargo remove crate_name --build
```

### Upgrading Dependencies

Use `cargo upgrade` to update dependencies (requires `cargo-edit` package):

```bash
cargo upgrade crate_name
cargo upgrade --all
cargo upgrade --dry-run
```

### Checking Dependency Status

```bash
cargo tree
cargo outdated
```

## When to Use

Use this skill whenever you need to:
- Add a new dependency to a Rust project
- Remove a dependency
- Update or upgrade dependencies
- Modify dependency features

## Best Practices

1. **Always use `cargo add`** - Never hardcode versions unless explicitly required
2. **Specify features** - Always include required features with `--features` flag
3. **Check dependency tree** - Use `cargo tree` after adding to verify transitive dependencies
4. **Test after changes** - Run `cargo build` and `cargo test` after dependency changes
5. **Use dry-run** - When unsure, use `--dry-run` flag to preview changes
