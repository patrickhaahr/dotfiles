# Global Agent Guidelines

This file contains guidelines for AI coding agents working across all projects.

## General Guidelines

### Skills
- Check if any skills available should be used

### Code Style
- Follow existing project conventions (check for .editorconfig, .prettierrc, eslintrc files)
- Use consistent indentation (detect from existing files)
- Use descriptive variable/function names (avoid single letters except loop counters)
- Design for testability using "functional core, imperative shell": keep pure business logic separate from code that does IO

### Imports
- Group imports: external packages first, then internal modules
- Remove unused imports
- Use absolute imports when configured in the project

### Error Handling
- Always handle errors explicitly (no silent failures)
- Use try-catch for async operations
- Log errors with context
- Return meaningful error messages

### Testing
- Write tests for new features
- Run tests before completing tasks
- Common test commands: `bun test`, `cargo test`

### File Operations
- Always read files before editing
- Preserve existing formatting and style
- Never create files unnecessarily - prefer editing existing ones
- Don't create documentation unless explicitly requested

## Project-Specific
Check for project-specific agent instructions in:
- `AGENTS.md` in project root

## Navigation Strategy
For ANY task involving file discovery or codebase exploration, use the `explore` subagent:
- Finding files by pattern (route*, *api*, handlers, etc.)
- Searching for code related to features, routes, endpoints
- Exploring directory structure or module organization
- Any task that would require multiple glob/grep calls

Do NOT use glob/grep tools directly for these tasks. Delegate to explore.
