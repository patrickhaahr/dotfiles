# Global Agent Guidelines

This file contains guidelines for AI coding agents working across all projects.

## General Guidelines

### Skills
- For every prompt, check if any skills available should be used

### Code Style
- Follow existing project conventions (check for .editorconfig, .prettierrc, eslintrc files)
- Use consistent indentation (detect from existing files)
- Prefer explicit types over implicit when working with TypeScript
- Use descriptive variable/function names (avoid single letters except loop counters)

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

### Git Workflow
- Write clear, concise commit messages
- Focus on "why" not "what" in commits
- Keep commits atomic (one logical change per commit)

### File Operations
- Always read files before editing
- Preserve existing formatting and style
- Never create files unnecessarily - prefer editing existing ones
- Don't create documentation unless explicitly requested

## Project-Specific Overrides
Check for project-specific agent instructions in:
- `AGENTS.md` in project root (overrides these global rules)
