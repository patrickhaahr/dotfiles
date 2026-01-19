# Framework Testing Template

This template defines the structure for framework-specific testing guides. Copy this file and replace placeholders when adding support for a new framework.

---

## Template Structure

```markdown
# {Framework} Testing Guide

## Overview
Brief description of the framework's testing ecosystem and philosophy.

## Setup

### Dependencies
\`\`\`bash
npm install -D {test-runner} {testing-library} {additional-deps}
\`\`\`

### Configuration
\`\`\`typescript
// vitest.config.ts or equivalent
\`\`\`

### TypeScript Configuration
\`\`\`json
// tsconfig.json additions
\`\`\`

## Test File Organization

| Type | Location | Naming |
|------|----------|--------|
| Unit | `src/__tests__/` or co-located | `*.test.ts` |
| Integration | `src/__tests__/` or co-located | `*.test.tsx` |
| E2E | `e2e/` | `*.spec.ts` |

## Component Testing

### Basic Component Test
\`\`\`typescript
// Render, query, assert pattern
\`\`\`

### Testing User Interactions
\`\`\`typescript
// Click, type, submit patterns
\`\`\`

### Testing Async Behavior
\`\`\`typescript
// Waiting for state updates, API calls
\`\`\`

## Reactive State Testing

### Testing State Changes
\`\`\`typescript
// Framework-specific reactive patterns
\`\`\`

### Testing Effects/Side Effects
\`\`\`typescript
// Testing reactive side effects
\`\`\`

## Mocking Strategies

### Mocking Modules
\`\`\`typescript
// vi.mock, vi.fn patterns
\`\`\`

### Mocking API Calls
\`\`\`typescript
// MSW or manual mocking
\`\`\`

### Mocking Context/Providers
\`\`\`typescript
// Wrapper patterns
\`\`\`

## Common Pitfalls

1. **Pitfall Name**: Description and solution
2. **Pitfall Name**: Description and solution

## Best Practices

- Practice 1
- Practice 2
- Practice 3

## References

- [Official Docs](link)
- [Testing Library Docs](link)
```

---

## Available Framework Guides

| Framework | File | Status |
|-----------|------|--------|
| SolidJS | `solidjs-tests.md` | Complete |
| React | `reactjs-tests.md` | Planned |
| Vue | `vue-tests.md` | Planned |
| Svelte | `svelte-tests.md` | Planned |
