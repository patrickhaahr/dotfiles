# Frontend Testing Best Practices

**Version 0.1.0**  
January 2026

> **Note:**  
> This document is primarily for agents and LLMs to follow when writing,  
> reviewing, or maintaining frontend test suites. Humans may also find it useful,  
> but guidance here is optimized for automation and consistency by AI-assisted workflows.

---

## Abstract

Comprehensive frontend testing guide following the Testing Trophy methodology. Prioritizes confidence over coverage through strategic test distribution: static analysis (continuous), unit tests (many), integration tests (some), and E2E tests (few). Contains framework-specific patterns for SolidJS with Vitest, focusing on TypeScript-first development with real-world examples and anti-patterns.

---

## Table of Contents

1. [Testing Philosophy](#1-testing-philosophy)
   - 1.1 [The Testing Trophy](#11-the-testing-trophy)
   - 1.2 [What to Test](#12-what-to-test)
   - 1.3 [Test Quality Principles](#13-test-quality-principles)
2. [Static Analysis](#2-static-analysis)
   - 2.1 [TypeScript Configuration](#21-typescript-configuration)
   - 2.2 [ESLint for Tests](#22-eslint-for-tests)
3. [Unit Testing](#3-unit-testing)
   - 3.1 [Pure Functions](#31-pure-functions)
   - 3.2 [Utility Functions](#32-utility-functions)
   - 3.3 [Custom Hooks/Primitives](#33-custom-hooksprimitives)
4. [Integration Testing](#4-integration-testing)
   - 4.1 [Component Testing Fundamentals](#41-component-testing-fundamentals)
   - 4.2 [User Interaction Testing](#42-user-interaction-testing)
   - 4.3 [Async Behavior](#43-async-behavior)
   - 4.4 [Context and Providers](#44-context-and-providers)
5. [E2E Testing](#5-e2e-testing)
   - 5.1 [When to Use E2E](#51-when-to-use-e2e)
   - 5.2 [Playwright Patterns](#52-playwright-patterns)
6. [SolidJS-Specific Patterns](#6-solidjs-specific-patterns)
   - 6.1 [Reactive Testing](#61-reactive-testing)
   - 6.2 [Control Flow Components](#62-control-flow-components)
   - 6.3 [Resource Testing](#63-resource-testing)
7. [Mocking Strategies](#7-mocking-strategies)
   - 7.1 [Module Mocking](#71-module-mocking)
   - 7.2 [API Mocking](#72-api-mocking)
   - 7.3 [Timer Mocking](#73-timer-mocking)
8. [Common Anti-Patterns](#8-common-anti-patterns)

---

## 1. Testing Philosophy

### 1.1 The Testing Trophy

The Testing Trophy inverts the traditional testing pyramid, emphasizing integration tests for maximum confidence with minimum effort.

| Level | Distribution | Confidence | Speed | Maintenance |
|-------|-------------|------------|-------|-------------|
| **Static** | Continuous | High | Instant | Low |
| **Unit** | Many (~70%) | Medium | Fast | Low |
| **Integration** | Some (~20%) | High | Medium | Medium |
| **E2E** | Few (~10%) | Very High | Slow | High |

**Key Insight**: Integration tests provide the best ROI. They test real user behavior without the brittleness of E2E tests or the isolation of unit tests.

### 1.2 What to Test

**Test:**
- User-visible behavior (what they see, what they can do)
- Edge cases and error states
- Business logic and calculations
- Accessibility (can users with assistive tech use it?)

**Don't Test:**
- Implementation details (internal state, private methods)
- Third-party library behavior
- Static UI that rarely changes
- Every possible permutation

### 1.3 Test Quality Principles

1. **Tests should fail for the right reasons**: If behavior changes, tests should fail. If implementation changes, tests should pass.

2. **Tests should be deterministic**: Same code = same result. No flaky tests.

3. **Tests should be fast**: Slow tests don't get run.

4. **Tests should be maintainable**: Tests are code. Apply the same quality standards.

---

## 2. Static Analysis

**Impact: CONTINUOUS**

Static analysis catches bugs before tests even run. It's free confidence.

### 2.1 TypeScript Configuration

**Strict mode is non-negotiable for test confidence:**

```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "noPropertyAccessFromIndexSignature": true,
    "jsx": "preserve",
    "jsxImportSource": "solid-js",
    "types": ["vite/client", "@testing-library/jest-dom"]
  }
}
```

### 2.2 ESLint for Tests

```javascript
// eslint.config.js
import vitest from 'eslint-plugin-vitest'

export default [
  {
    files: ['**/*.test.ts', '**/*.test.tsx'],
    plugins: { vitest },
    rules: {
      'vitest/expect-expect': 'error',
      'vitest/no-identical-title': 'error',
      'vitest/no-focused-tests': 'error',
      'vitest/no-disabled-tests': 'warn'
    }
  }
]
```

---

## 3. Unit Testing

**Impact: FOUNDATIONAL**

Unit tests verify isolated logic. They're fast, stable, and easy to write.

### 3.1 Pure Functions

Test pure functions exhaustively - they're deterministic and have no side effects.

**Example: Testing a formatter**

```typescript
import { describe, it, expect } from 'vitest'
import { formatCurrency, formatDate, formatPercentage } from './formatters'

describe('formatCurrency', () => {
  it('formats positive numbers with two decimal places', () => {
    expect(formatCurrency(1234.5)).toBe('$1,234.50')
  })

  it('formats negative numbers with parentheses', () => {
    expect(formatCurrency(-1234.5)).toBe('($1,234.50)')
  })

  it('handles zero', () => {
    expect(formatCurrency(0)).toBe('$0.00')
  })

  it('rounds to two decimal places', () => {
    expect(formatCurrency(1.999)).toBe('$2.00')
    expect(formatCurrency(1.001)).toBe('$1.00')
  })
})
```

### 3.2 Utility Functions

**Example: Testing validation**

```typescript
import { describe, it, expect } from 'vitest'
import { validateEmail, validatePassword, ValidationResult } from './validators'

describe('validateEmail', () => {
  it('accepts valid emails', () => {
    expect(validateEmail('user@example.com')).toEqual({ valid: true })
    expect(validateEmail('user+tag@sub.example.co.uk')).toEqual({ valid: true })
  })

  it('rejects invalid emails', () => {
    expect(validateEmail('')).toEqual({ 
      valid: false, 
      error: 'Email is required' 
    })
    expect(validateEmail('notanemail')).toEqual({ 
      valid: false, 
      error: 'Invalid email format' 
    })
    expect(validateEmail('missing@domain')).toEqual({ 
      valid: false, 
      error: 'Invalid email format' 
    })
  })
})

describe('validatePassword', () => {
  it('requires minimum length', () => {
    expect(validatePassword('short')).toEqual({
      valid: false,
      error: 'Password must be at least 8 characters'
    })
  })

  it('requires uppercase letter', () => {
    expect(validatePassword('lowercase123')).toEqual({
      valid: false,
      error: 'Password must contain an uppercase letter'
    })
  })

  it('accepts valid passwords', () => {
    expect(validatePassword('ValidPass123!')).toEqual({ valid: true })
  })
})
```

### 3.3 Custom Hooks/Primitives

Test SolidJS primitives using `testEffect`:

```typescript
import { describe, it, expect } from 'vitest'
import { testEffect } from '@solidjs/testing-library'
import { useLocalStorage } from './useLocalStorage'

describe('useLocalStorage', () => {
  beforeEach(() => {
    localStorage.clear()
  })

  it('returns initial value when storage is empty', () => {
    return testEffect((done) => {
      const [value] = useLocalStorage('key', 'default')
      expect(value()).toBe('default')
      done()
    })
  })

  it('persists value to localStorage', () => {
    return testEffect((done) => {
      const [value, setValue] = useLocalStorage('key', 'initial')
      setValue('updated')
      expect(localStorage.getItem('key')).toBe('"updated"')
      expect(value()).toBe('updated')
      done()
    })
  })
})
```

---

## 4. Integration Testing

**Impact: HIGH**

Integration tests verify components work correctly from a user's perspective.

### 4.1 Component Testing Fundamentals

**The golden rule**: Test what users see and do, not implementation details.

**Example: Counter component**

```typescript
import { describe, it, expect } from 'vitest'
import { render, screen } from '@solidjs/testing-library'
import userEvent from '@testing-library/user-event'
import { Counter } from './Counter'

describe('Counter', () => {
  it('displays initial count', () => {
    render(() => <Counter initialCount={5} />)
    
    expect(screen.getByRole('button')).toHaveTextContent('Count: 5')
  })

  it('increments when clicked', async () => {
    const user = userEvent.setup()
    render(() => <Counter />)
    
    await user.click(screen.getByRole('button'))
    
    expect(screen.getByRole('button')).toHaveTextContent('Count: 1')
  })

  it('decrements with shift+click', async () => {
    const user = userEvent.setup()
    render(() => <Counter initialCount={5} />)
    
    await user.click(screen.getByRole('button'), { shiftKey: true })
    
    expect(screen.getByRole('button')).toHaveTextContent('Count: 4')
  })
})
```

### 4.2 User Interaction Testing

**Prefer `userEvent` over `fireEvent`**: `userEvent` simulates real browser behavior.

**Example: Form with validation**

```typescript
import { describe, it, expect, vi } from 'vitest'
import { render, screen, waitFor } from '@solidjs/testing-library'
import userEvent from '@testing-library/user-event'
import { ContactForm } from './ContactForm'

describe('ContactForm', () => {
  it('submits form with valid data', async () => {
    const user = userEvent.setup()
    const onSubmit = vi.fn()
    render(() => <ContactForm onSubmit={onSubmit} />)
    
    await user.type(screen.getByLabelText('Name'), 'John Doe')
    await user.type(screen.getByLabelText('Email'), 'john@example.com')
    await user.type(screen.getByLabelText('Message'), 'Hello!')
    await user.click(screen.getByRole('button', { name: 'Send' }))
    
    expect(onSubmit).toHaveBeenCalledWith({
      name: 'John Doe',
      email: 'john@example.com',
      message: 'Hello!'
    })
  })

  it('shows validation errors for empty fields', async () => {
    const user = userEvent.setup()
    render(() => <ContactForm onSubmit={vi.fn()} />)
    
    await user.click(screen.getByRole('button', { name: 'Send' }))
    
    expect(screen.getByText('Name is required')).toBeInTheDocument()
    expect(screen.getByText('Email is required')).toBeInTheDocument()
  })

  it('shows error for invalid email', async () => {
    const user = userEvent.setup()
    render(() => <ContactForm onSubmit={vi.fn()} />)
    
    await user.type(screen.getByLabelText('Email'), 'invalid')
    await user.click(screen.getByRole('button', { name: 'Send' }))
    
    expect(screen.getByText('Invalid email format')).toBeInTheDocument()
  })

  it('disables submit button while submitting', async () => {
    const user = userEvent.setup()
    const onSubmit = vi.fn(() => new Promise(r => setTimeout(r, 100)))
    render(() => <ContactForm onSubmit={onSubmit} />)
    
    await user.type(screen.getByLabelText('Name'), 'John')
    await user.type(screen.getByLabelText('Email'), 'john@example.com')
    await user.click(screen.getByRole('button', { name: 'Send' }))
    
    expect(screen.getByRole('button')).toBeDisabled()
    expect(screen.getByRole('button')).toHaveTextContent('Sending...')
  })
})
```

### 4.3 Async Behavior

**Use `waitFor` for async assertions:**

```typescript
import { describe, it, expect, vi } from 'vitest'
import { render, screen, waitFor } from '@solidjs/testing-library'
import { SearchResults } from './SearchResults'

vi.mock('./api', () => ({
  searchProducts: vi.fn()
}))

import { searchProducts } from './api'

describe('SearchResults', () => {
  it('shows loading state', async () => {
    vi.mocked(searchProducts).mockImplementation(
      () => new Promise(() => {}) // Never resolves
    )
    
    render(() => <SearchResults query="laptop" />)
    
    expect(screen.getByText('Searching...')).toBeInTheDocument()
  })

  it('displays results after search', async () => {
    vi.mocked(searchProducts).mockResolvedValue([
      { id: '1', name: 'MacBook Pro', price: 1999 },
      { id: '2', name: 'ThinkPad', price: 1299 }
    ])
    
    render(() => <SearchResults query="laptop" />)
    
    await waitFor(() => {
      expect(screen.getByText('MacBook Pro')).toBeInTheDocument()
    })
    expect(screen.getByText('ThinkPad')).toBeInTheDocument()
    expect(screen.queryByText('Searching...')).not.toBeInTheDocument()
  })

  it('shows empty state for no results', async () => {
    vi.mocked(searchProducts).mockResolvedValue([])
    
    render(() => <SearchResults query="xyz123" />)
    
    await waitFor(() => {
      expect(screen.getByText('No products found')).toBeInTheDocument()
    })
  })

  it('handles errors gracefully', async () => {
    vi.mocked(searchProducts).mockRejectedValue(new Error('Network error'))
    
    render(() => <SearchResults query="laptop" />)
    
    await waitFor(() => {
      expect(screen.getByRole('alert')).toHaveTextContent('Failed to search')
    })
  })
})
```

### 4.4 Context and Providers

**Create reusable test utilities:**

```typescript
// src/test/utils.tsx
import { render as solidRender, RenderOptions } from '@solidjs/testing-library'
import { ParentProps } from 'solid-js'
import { ThemeProvider } from '../contexts/Theme'
import { AuthProvider } from '../contexts/Auth'
import { I18nProvider } from '../contexts/I18n'

interface ProvidersProps extends ParentProps {
  theme?: 'light' | 'dark'
  locale?: string
}

function AllProviders(props: ProvidersProps) {
  return (
    <I18nProvider locale={props.locale ?? 'en'}>
      <ThemeProvider initialTheme={props.theme ?? 'light'}>
        <AuthProvider>
          {props.children}
        </AuthProvider>
      </ThemeProvider>
    </I18nProvider>
  )
}

interface CustomRenderOptions extends Omit<RenderOptions, 'wrapper'> {
  theme?: 'light' | 'dark'
  locale?: string
}

export function render(ui: () => JSX.Element, options: CustomRenderOptions = {}) {
  const { theme, locale, ...renderOptions } = options
  
  return solidRender(ui, {
    wrapper: (props) => (
      <AllProviders theme={theme} locale={locale}>
        {props.children}
      </AllProviders>
    ),
    ...renderOptions
  })
}

export * from '@solidjs/testing-library'
```

**Using the utility:**

```typescript
import { render, screen } from '../test/utils'
import { ThemeToggle } from './ThemeToggle'

describe('ThemeToggle', () => {
  it('shows moon icon in light mode', () => {
    render(() => <ThemeToggle />, { theme: 'light' })
    
    expect(screen.getByRole('button')).toHaveAttribute('aria-label', 'Switch to dark mode')
  })

  it('shows sun icon in dark mode', () => {
    render(() => <ThemeToggle />, { theme: 'dark' })
    
    expect(screen.getByRole('button')).toHaveAttribute('aria-label', 'Switch to light mode')
  })
})
```

---

## 5. E2E Testing

**Impact: CRITICAL PATHS ONLY**

E2E tests are slow and brittle. Use sparingly for critical user journeys.

### 5.1 When to Use E2E

**Good candidates:**
- Authentication flows (login, signup, password reset)
- Payment/checkout flows
- Multi-page workflows
- Features requiring real API integration

**Bad candidates:**
- Individual component behavior
- Edge cases (use integration tests)
- Visual styling (use visual regression tools)

### 5.2 Playwright Patterns

```typescript
// e2e/auth.spec.ts
import { test, expect } from '@playwright/test'

test.describe('Authentication', () => {
  test('user can sign up and log in', async ({ page }) => {
    // Sign up
    await page.goto('/signup')
    await page.fill('[name="email"]', 'newuser@example.com')
    await page.fill('[name="password"]', 'SecurePass123!')
    await page.fill('[name="confirmPassword"]', 'SecurePass123!')
    await page.click('button[type="submit"]')
    
    // Verify redirect to dashboard
    await expect(page).toHaveURL('/dashboard')
    await expect(page.locator('[data-testid="welcome-message"]'))
      .toContainText('Welcome, newuser@example.com')
  })

  test('shows error for invalid credentials', async ({ page }) => {
    await page.goto('/login')
    await page.fill('[name="email"]', 'wrong@example.com')
    await page.fill('[name="password"]', 'wrongpassword')
    await page.click('button[type="submit"]')
    
    await expect(page.locator('[role="alert"]'))
      .toContainText('Invalid email or password')
  })
})
```

---

## 6. SolidJS-Specific Patterns

### 6.1 Reactive Testing

**Always wrap components in arrow functions:**

```typescript
// WRONG: Breaks reactive ownership
render(<Counter />)

// CORRECT: Maintains reactive context
render(() => <Counter />)
```

**Testing signal updates:**

```typescript
import { describe, it, expect } from 'vitest'
import { render, screen } from '@solidjs/testing-library'
import userEvent from '@testing-library/user-event'

describe('reactive updates', () => {
  it('updates DOM synchronously with signal changes', async () => {
    const user = userEvent.setup()
    render(() => <Counter />)
    
    const button = screen.getByRole('button')
    
    // Signal changes are synchronous in SolidJS
    await user.click(button)
    expect(button).toHaveTextContent('1') // No waitFor needed!
    
    await user.click(button)
    expect(button).toHaveTextContent('2')
  })
})
```

### 6.2 Control Flow Components

**Testing `<Show>`:**

```typescript
describe('ConditionalContent', () => {
  it('shows content when condition becomes true', async () => {
    const user = userEvent.setup()
    render(() => <TogglePanel />)
    
    // Content hidden initially
    expect(screen.queryByText('Panel content')).not.toBeInTheDocument()
    
    await user.click(screen.getByRole('button', { name: 'Open' }))
    
    // Content visible after toggle
    expect(screen.getByText('Panel content')).toBeInTheDocument()
  })
})
```

**Testing `<For>`:**

```typescript
describe('ItemList', () => {
  it('renders correct number of items', () => {
    render(() => (
      <ItemList items={['Apple', 'Banana', 'Cherry']} />
    ))
    
    const items = screen.getAllByRole('listitem')
    expect(items).toHaveLength(3)
  })

  it('updates when items are added', async () => {
    const user = userEvent.setup()
    render(() => <DynamicList />)
    
    expect(screen.getAllByRole('listitem')).toHaveLength(0)
    
    await user.click(screen.getByRole('button', { name: 'Add Item' }))
    
    expect(screen.getAllByRole('listitem')).toHaveLength(1)
  })
})
```

### 6.3 Resource Testing

**Testing `createResource`:**

```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@solidjs/testing-library'
import { UserProfile } from './UserProfile'

vi.mock('./api', () => ({
  fetchUser: vi.fn()
}))

import { fetchUser } from './api'

describe('UserProfile', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('shows loading skeleton', () => {
    vi.mocked(fetchUser).mockImplementation(
      () => new Promise(() => {})
    )
    
    render(() => <UserProfile userId="1" />)
    
    expect(screen.getByTestId('profile-skeleton')).toBeInTheDocument()
  })

  it('renders user after load', async () => {
    vi.mocked(fetchUser).mockResolvedValue({
      id: '1',
      name: 'Jane Doe',
      email: 'jane@example.com'
    })
    
    render(() => <UserProfile userId="1" />)
    
    await waitFor(() => {
      expect(screen.getByRole('heading')).toHaveTextContent('Jane Doe')
    })
  })

  it('shows error state', async () => {
    vi.mocked(fetchUser).mockRejectedValue(new Error('User not found'))
    
    render(() => <UserProfile userId="999" />)
    
    await waitFor(() => {
      expect(screen.getByRole('alert')).toHaveTextContent('User not found')
    })
  })

  it('refetches when userId changes', async () => {
    vi.mocked(fetchUser)
      .mockResolvedValueOnce({ id: '1', name: 'User 1' })
      .mockResolvedValueOnce({ id: '2', name: 'User 2' })
    
    const { rerender } = render(() => <UserProfile userId="1" />)
    
    await waitFor(() => {
      expect(screen.getByText('User 1')).toBeInTheDocument()
    })
    
    // Note: In SolidJS, you'd typically use signals for this
    // This example assumes the component accepts a reactive userId
  })
})
```

---

## 7. Mocking Strategies

### 7.1 Module Mocking

**Basic module mock:**

```typescript
vi.mock('./analytics', () => ({
  trackEvent: vi.fn(),
  trackPageView: vi.fn()
}))
```

**Partial mock (keep some implementations):**

```typescript
vi.mock('./utils', async (importOriginal) => {
  const actual = await importOriginal<typeof import('./utils')>()
  return {
    ...actual,
    expensiveOperation: vi.fn(() => 'mocked')
  }
})
```

**Mock with different implementations per test:**

```typescript
import { vi, describe, it, beforeEach } from 'vitest'

vi.mock('./featureFlags')

import { isFeatureEnabled } from './featureFlags'

describe('FeatureFlagged component', () => {
  beforeEach(() => {
    vi.resetAllMocks()
  })

  it('shows feature when enabled', () => {
    vi.mocked(isFeatureEnabled).mockReturnValue(true)
    render(() => <NewFeature />)
    expect(screen.getByText('New Feature!')).toBeInTheDocument()
  })

  it('hides feature when disabled', () => {
    vi.mocked(isFeatureEnabled).mockReturnValue(false)
    render(() => <NewFeature />)
    expect(screen.queryByText('New Feature!')).not.toBeInTheDocument()
  })
})
```

### 7.2 API Mocking

**Using MSW (recommended for complex APIs):**

```typescript
// src/test/mocks/handlers.ts
import { http, HttpResponse } from 'msw'

export const handlers = [
  http.get('/api/users/:id', ({ params }) => {
    return HttpResponse.json({
      id: params.id,
      name: 'Test User',
      email: 'test@example.com'
    })
  }),

  http.post('/api/users', async ({ request }) => {
    const body = await request.json()
    return HttpResponse.json({ id: 'new-id', ...body }, { status: 201 })
  })
]

// src/test/setup.ts
import { setupServer } from 'msw/node'
import { handlers } from './mocks/handlers'

export const server = setupServer(...handlers)

beforeAll(() => server.listen({ onUnhandledRequest: 'error' }))
afterEach(() => server.resetHandlers())
afterAll(() => server.close())
```

### 7.3 Timer Mocking

```typescript
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'

describe('Debounced search', () => {
  beforeEach(() => {
    vi.useFakeTimers()
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('debounces search input', async () => {
    const onSearch = vi.fn()
    const user = userEvent.setup({ advanceTimers: vi.advanceTimersByTime })
    
    render(() => <DebouncedSearch onSearch={onSearch} delay={300} />)
    
    await user.type(screen.getByRole('searchbox'), 'test')
    
    // Not called immediately
    expect(onSearch).not.toHaveBeenCalled()
    
    // Fast-forward past debounce delay
    vi.advanceTimersByTime(300)
    
    expect(onSearch).toHaveBeenCalledWith('test')
    expect(onSearch).toHaveBeenCalledTimes(1)
  })
})
```

---

## 8. Common Anti-Patterns

### 8.1 Testing Implementation Details

```typescript
// WRONG: Testing internal state
it('sets isLoading to true', () => {
  const [isLoading] = createSignal(false)
  // Don't test signals directly
})

// CORRECT: Test user-visible behavior
it('shows loading spinner', () => {
  render(() => <LoadingButton />)
  expect(screen.getByRole('status')).toBeInTheDocument()
})
```

### 8.2 Using `fireEvent` Instead of `userEvent`

```typescript
// WRONG: Doesn't simulate real user behavior
fireEvent.click(button)

// CORRECT: Simulates actual browser events
const user = userEvent.setup()
await user.click(button)
```

### 8.3 Not Waiting for Async Operations

```typescript
// WRONG: May pass/fail randomly
render(() => <AsyncComponent />)
expect(screen.getByText('Loaded')).toBeInTheDocument()

// CORRECT: Wait for element
await waitFor(() => {
  expect(screen.getByText('Loaded')).toBeInTheDocument()
})
```

### 8.4 Snapshot Testing for Components

```typescript
// WRONG: Brittle, doesn't catch regressions
expect(container).toMatchSnapshot()

// CORRECT: Assert specific behavior
expect(screen.getByRole('button')).toHaveTextContent('Submit')
expect(screen.getByRole('button')).toBeEnabled()
```

### 8.5 Testing Styling/Layout

```typescript
// WRONG: Doesn't verify functionality
expect(element).toHaveStyle({ color: 'red' })

// CORRECT: Test semantic meaning
expect(element).toHaveAttribute('aria-invalid', 'true')
expect(screen.getByRole('alert')).toBeInTheDocument()
```

### 8.6 Over-Mocking

```typescript
// WRONG: Mock everything
vi.mock('./ComponentA')
vi.mock('./ComponentB')
vi.mock('./utils')
vi.mock('./hooks')

// CORRECT: Mock at boundaries (API, external services)
vi.mock('./api')
```

---

## References

- [SolidJS Testing Guide](https://docs.solidjs.com/guides/testing)
- [Solid Testing Library](https://github.com/solidjs/solid-testing-library)
- [Testing Library](https://testing-library.com/)
- [Vitest](https://vitest.dev/)
- [Playwright](https://playwright.dev/)
- [MSW](https://mswjs.io/)
- [Kent C. Dodds - Testing Trophy](https://kentcdodds.com/blog/the-testing-trophy-and-testing-classifications)
- [Testing Implementation Details](https://kentcdodds.com/blog/testing-implementation-details)
