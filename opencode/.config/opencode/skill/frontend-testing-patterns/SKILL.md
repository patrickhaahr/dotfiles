---
name: frontend-testing-patterns
description: Expert guide for frontend testing best practices following the Testing Trophy (Static, Unit, Integration, E2E). Provides framework-specific patterns for component, hook, and integration testing. Currently supports SolidJS with Vitest. Use this skill when writing, reviewing, or setting up frontend tests.
---

# Frontend Testing Patterns

Comprehensive testing guide for frontend applications following the Testing Trophy methodology. Prioritizes confidence over coverage with a focus on integration tests while maintaining appropriate test distribution.

## When to Apply

Reference these guidelines when:
- Writing tests for frontend components, hooks, or utilities
- Setting up a new testing environment
- Reviewing test code for best practices
- Choosing the right type of test for a feature
- Debugging flaky or slow tests

## Testing Trophy Distribution

| Level | Count | Focus | Tools |
|-------|-------|-------|-------|
| **Static** | Continuous | Type errors, linting | TypeScript, ESLint |
| **Unit** | Many | Pure functions, utilities | Vitest |
| **Integration** | Some | Component interactions, hooks | Vitest + Testing Library |
| **E2E** | Few | Critical user flows | Playwright |

## Framework-Specific Guides

This skill uses a modular structure. Consult the appropriate framework guide:

| Framework | File | Test Runner |
|-----------|------|-------------|
| **SolidJS** | [frameworks/solidjs-tests.md](frameworks/solidjs-tests.md) | Vitest |

> **Template**: See [frameworks/framework.md](frameworks/framework.md) for adding new frameworks.

## Quick Reference

### 1. Static Analysis (Continuous)

TypeScript catches bugs before tests run. Configure strict mode:

```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitReturns": true
  }
}
```

### 2. Unit Tests (Many)

Test pure functions and utilities in isolation:

```typescript
import { describe, it, expect } from 'vitest'
import { formatCurrency, validateEmail } from './utils'

describe('formatCurrency', () => {
  it('formats positive numbers correctly', () => {
    expect(formatCurrency(1234.56)).toBe('$1,234.56')
  })

  it('handles zero', () => {
    expect(formatCurrency(0)).toBe('$0.00')
  })
})
```

### 3. Integration Tests (Some)

Test component behavior from a user's perspective:

```typescript
// See framework-specific guide for syntax
// Focus on: user interactions, state changes, async behavior
```

### 4. E2E Tests (Few)

Test critical user journeys across multiple pages:

```typescript
import { test, expect } from '@playwright/test'

test('user can complete checkout', async ({ page }) => {
  await page.goto('/products')
  await page.click('[data-testid="add-to-cart"]')
  await page.click('[data-testid="checkout"]')
  await expect(page.locator('[data-testid="order-confirmation"]')).toBeVisible()
})
```

## How to Use

1. Read the base patterns in this file
2. Consult the framework-specific guide in `frameworks/`
3. Full expanded guide: `AGENTS.md`

Each framework guide contains:
- Project setup and configuration
- Component testing patterns
- Async and reactive testing
- Mocking strategies
- Common pitfalls
