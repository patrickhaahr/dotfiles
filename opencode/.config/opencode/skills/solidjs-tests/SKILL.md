---
name: solidjs-tests
description: MUST USE SKILL when creating, modify, validating solidjs code. Following best patterns for SolidJS tests.
---

SolidJS uses fine-grained reactivity where components run **once** and only reactive expressions re-execute. This fundamentally changes testing patterns compared to React:

- **No re-renders**: Components don't re-execute on state changes
- **Reactive DOM updates**: Only specific DOM nodes update
- **Signal-based state**: State changes are synchronous but DOM updates may be batched

## Setup

### Dependencies

```bash
bun install -D vitest jsdom @solidjs/testing-library @testing-library/user-event @testing-library/jest-dom
```

### Vitest Configuration

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config'
import solidPlugin from 'vite-plugin-solid'

export default defineConfig({
  plugins: [solidPlugin()],
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./src/test/setup.ts'],
    // Ensure proper SolidJS transformation
    deps: {
      optimizer: {
        web: {
          include: ['@solidjs/testing-library']
        }
      }
    }
  },
  resolve: {
    conditions: ['development', 'browser']
  }
})
```

### Test Setup File

```typescript
// src/test/setup.ts
import '@testing-library/jest-dom/vitest'
import { afterEach } from 'vitest'
import { cleanup } from '@solidjs/testing-library'

// Cleanup after each test
afterEach(() => {
  cleanup()
})
```

### TypeScript Configuration

```json
{
  "compilerOptions": {
    "jsx": "preserve",
    "jsxImportSource": "solid-js",
    "types": ["vite/client", "@testing-library/jest-dom"]
  }
}
```

## Test File Organization

| Type | Location | Naming | Purpose |
|------|----------|--------|---------|
| Unit | `src/__tests__/` or co-located | `*.test.ts` | Pure functions, utilities |
| Component | Co-located or `src/__tests__/` | `*.test.tsx` | Component behavior |
| Integration | `src/__tests__/integration/` | `*.test.tsx` | Multiple components |
| E2E | `e2e/` | `*.spec.ts` | Full user flows |

## Component Testing

### Basic Component Test

```typescript
import { describe, it, expect } from 'vitest'
import { render, screen } from '@solidjs/testing-library'
import { Counter } from './Counter'

describe('Counter', () => {
  it('renders initial count', () => {
    render(() => <Counter initialCount={5} />)
    
    expect(screen.getByRole('button')).toHaveTextContent('5')
  })
})
```

**Key Pattern**: Always wrap component in arrow function `() => <Component />` - this is required for SolidJS's reactive ownership tracking.

### Testing User Interactions

```typescript
import { describe, it, expect } from 'vitest'
import { render, screen } from '@solidjs/testing-library'
import userEvent from '@testing-library/user-event'
import { Counter } from './Counter'

describe('Counter', () => {
  it('increments on click', async () => {
    const user = userEvent.setup()
    render(() => <Counter />)
    
    const button = screen.getByRole('button')
    expect(button).toHaveTextContent('0')
    
    await user.click(button)
    
    expect(button).toHaveTextContent('1')
  })

  it('handles rapid clicks', async () => {
    const user = userEvent.setup()
    render(() => <Counter />)
    
    const button = screen.getByRole('button')
    
    await user.click(button)
    await user.click(button)
    await user.click(button)
    
    expect(button).toHaveTextContent('3')
  })
})
```

### Testing Form Inputs

```typescript
import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@solidjs/testing-library'
import userEvent from '@testing-library/user-event'
import { LoginForm } from './LoginForm'

describe('LoginForm', () => {
  it('submits with user input', async () => {
    const user = userEvent.setup()
    const onSubmit = vi.fn()
    
    render(() => <LoginForm onSubmit={onSubmit} />)
    
    await user.type(screen.getByLabelText('Email'), 'test@example.com')
    await user.type(screen.getByLabelText('Password'), 'password123')
    await user.click(screen.getByRole('button', { name: 'Submit' }))
    
    expect(onSubmit).toHaveBeenCalledWith({
      email: 'test@example.com',
      password: 'password123'
    })
  })

  it('shows validation errors', async () => {
    const user = userEvent.setup()
    render(() => <LoginForm onSubmit={vi.fn()} />)
    
    await user.click(screen.getByRole('button', { name: 'Submit' }))
    
    expect(screen.getByText('Email is required')).toBeInTheDocument()
  })
})
```

## Reactive State Testing

### Testing Signal Changes

```typescript
import { describe, it, expect } from 'vitest'
import { render, screen } from '@solidjs/testing-library'
import userEvent from '@testing-library/user-event'
import { TodoList } from './TodoList'

describe('TodoList', () => {
  it('adds new todos reactively', async () => {
    const user = userEvent.setup()
    render(() => <TodoList />)
    
    const input = screen.getByPlaceholderText('Add todo')
    const addButton = screen.getByRole('button', { name: 'Add' })
    
    await user.type(input, 'Buy groceries')
    await user.click(addButton)
    
    // DOM updates synchronously with signal changes
    expect(screen.getByText('Buy groceries')).toBeInTheDocument()
    expect(input).toHaveValue('')
  })
})
```

### Testing createEffect with testEffect

For testing effects that need to track reactive changes:

```typescript
import { describe, it, expect } from 'vitest'
import { testEffect } from '@solidjs/testing-library'
import { createSignal, createEffect } from 'solid-js'

describe('Effect tracking', () => {
  it('tracks signal changes', () => {
    const [count, setCount] = createSignal(0)
    
    return testEffect((done) => {
      createEffect((run: number = 0) => {
        if (run === 0) {
          expect(count()).toBe(0)
          setCount(1)
        } else if (run === 1) {
          expect(count()).toBe(1)
          done()
        }
        return run + 1
      })
    })
  })
})
```

### Testing createResource (Async Data)

```typescript
import { describe, it, expect, vi } from 'vitest'
import { render, screen, waitFor } from '@solidjs/testing-library'
import { UserProfile } from './UserProfile'

// Mock the API
vi.mock('./api', () => ({
  fetchUser: vi.fn()
}))

import { fetchUser } from './api'

describe('UserProfile', () => {
  it('shows loading state', () => {
    vi.mocked(fetchUser).mockImplementation(
      () => new Promise(() => {}) // Never resolves
    )
    
    render(() => <UserProfile userId="1" />)
    
    expect(screen.getByText('Loading...')).toBeInTheDocument()
  })

  it('renders user data after fetch', async () => {
    vi.mocked(fetchUser).mockResolvedValue({
      name: 'John Doe',
      email: 'john@example.com'
    })
    
    render(() => <UserProfile userId="1" />)
    
    await waitFor(() => {
      expect(screen.getByText('John Doe')).toBeInTheDocument()
    })
    expect(screen.getByText('john@example.com')).toBeInTheDocument()
  })

  it('handles errors', async () => {
    vi.mocked(fetchUser).mockRejectedValue(new Error('Failed to fetch'))
    
    render(() => <UserProfile userId="1" />)
    
    await waitFor(() => {
      expect(screen.getByText('Error: Failed to fetch')).toBeInTheDocument()
    })
  })
})
```

## Testing Control Flow Components

### Testing `<Show>`

```typescript
import { describe, it, expect } from 'vitest'
import { render, screen } from '@solidjs/testing-library'
import userEvent from '@testing-library/user-event'
import { ToggleContent } from './ToggleContent'

describe('ToggleContent', () => {
  it('shows content when condition is true', async () => {
    const user = userEvent.setup()
    render(() => <ToggleContent />)
    
    expect(screen.queryByText('Hidden content')).not.toBeInTheDocument()
    
    await user.click(screen.getByRole('button', { name: 'Toggle' }))
    
    expect(screen.getByText('Hidden content')).toBeInTheDocument()
  })
})
```

### Testing `<For>`

```typescript
import { describe, it, expect } from 'vitest'
import { render, screen } from '@solidjs/testing-library'
import { ItemList } from './ItemList'

describe('ItemList', () => {
  it('renders list items', () => {
    const items = [
      { id: 1, name: 'Item 1' },
      { id: 2, name: 'Item 2' },
      { id: 3, name: 'Item 3' }
    ]
    
    render(() => <ItemList items={items} />)
    
    expect(screen.getAllByRole('listitem')).toHaveLength(3)
    expect(screen.getByText('Item 1')).toBeInTheDocument()
    expect(screen.getByText('Item 2')).toBeInTheDocument()
    expect(screen.getByText('Item 3')).toBeInTheDocument()
  })

  it('updates when items change', async () => {
    const user = userEvent.setup()
    render(() => <ItemList />)
    
    await user.click(screen.getByRole('button', { name: 'Add Item' }))
    
    expect(screen.getAllByRole('listitem')).toHaveLength(1)
  })
})
```

## Testing with Context

### Providing Context in Tests

```typescript
import { describe, it, expect } from 'vitest'
import { render, screen } from '@solidjs/testing-library'
import { ThemeProvider, useTheme } from './ThemeContext'
import { ThemedButton } from './ThemedButton'

describe('ThemedButton', () => {
  it('uses theme from context', () => {
    const wrapper = (props: { children: any }) => (
      <ThemeProvider theme="dark">
        {props.children}
      </ThemeProvider>
    )
    
    render(() => <ThemedButton />, { wrapper })
    
    expect(screen.getByRole('button')).toHaveClass('dark-theme')
  })
})
```

### Creating Test Utilities

```typescript
// src/test/utils.tsx
import { render, RenderOptions } from '@solidjs/testing-library'
import { ThemeProvider } from '../contexts/ThemeContext'
import { AuthProvider } from '../contexts/AuthContext'
import { JSX } from 'solid-js'

interface WrapperProps {
  children: JSX.Element
}

const AllProviders = (props: WrapperProps) => (
  <ThemeProvider>
    <AuthProvider>
      {props.children}
    </AuthProvider>
  </ThemeProvider>
)

export function renderWithProviders(
  ui: () => JSX.Element,
  options?: Omit<RenderOptions, 'wrapper'>
) {
  return render(ui, { wrapper: AllProviders, ...options })
}

export * from '@solidjs/testing-library'
```

## Mocking Strategies

### Mocking Modules

```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest'

vi.mock('./analytics', () => ({
  trackEvent: vi.fn()
}))

import { trackEvent } from './analytics'

describe('Button with analytics', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('tracks click events', async () => {
    const user = userEvent.setup()
    render(() => <TrackedButton />)
    
    await user.click(screen.getByRole('button'))
    
    expect(trackEvent).toHaveBeenCalledWith('button_click', {
      component: 'TrackedButton'
    })
  })
})
```

### Mocking Stores

```typescript
import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@solidjs/testing-library'

// Mock the store module
let mockCount = 0
vi.mock('./stores/counter-store', () => ({
  counterStore: {
    get count() { return mockCount }
  },
  increment: vi.fn()
}))

import { CounterDisplay } from './CounterDisplay'
import { increment } from './stores/counter-store'

describe('CounterDisplay', () => {
  it('displays store value', () => {
    mockCount = 42
    render(() => <CounterDisplay />)
    
    expect(screen.getByText('Count: 42')).toBeInTheDocument()
  })
})
```

### Mocking Router

```typescript
import { describe, it, expect } from 'vitest'
import { render, screen } from '@solidjs/testing-library'
import { UserPage } from './UserPage'

describe('UserPage', () => {
  it('renders with route params', () => {
    render(() => <UserPage />, {
      location: '/users/123'
    })
    
    expect(screen.getByText('User ID: 123')).toBeInTheDocument()
  })
})
```

## Common Pitfalls

### 1. Forgetting the Arrow Function Wrapper

```typescript
// WRONG: Breaks reactive ownership
render(<Counter />)

// CORRECT: Maintains reactive context
render(() => <Counter />)
```

### 2. Not Waiting for Async Updates

```typescript
// WRONG: May fail due to timing
render(() => <AsyncComponent />)
expect(screen.getByText('Loaded')).toBeInTheDocument()

// CORRECT: Wait for element to appear
render(() => <AsyncComponent />)
await waitFor(() => {
  expect(screen.getByText('Loaded')).toBeInTheDocument()
})
```

### 3. Testing Implementation Instead of Behavior

```typescript
// WRONG: Testing internal signal values
const [count] = createSignal(0)
expect(count()).toBe(0)

// CORRECT: Test what users see
expect(screen.getByRole('button')).toHaveTextContent('0')
```

### 4. Missing Cleanup

```typescript
// Ensure setup.ts has cleanup, or tests will leak
afterEach(() => {
  cleanup()
})
```

### 5. Destructuring Props in Component

```typescript
// WRONG: Loses reactivity - tests may pass but code is broken
function Counter({ count }: Props) {
  return <div>{count}</div>
}

// CORRECT: Access props directly
function Counter(props: Props) {
  return <div>{props.count}</div>
}
```

## Best Practices

1. **Test behavior, not implementation**: Focus on what users see and interact with
2. **Use `userEvent` over `fireEvent`**: More realistic user simulation
3. **Co-locate tests with components**: Easier to maintain
4. **Mock at module boundaries**: Don't mock SolidJS internals
5. **Keep tests synchronous when possible**: SolidJS updates are synchronous
6. **Use `data-testid` sparingly**: Prefer accessible queries (`getByRole`, `getByLabelText`)
7. **Test error boundaries**: Ensure graceful error handling
8. **Avoid snapshot tests for components**: They're brittle and don't catch regressions well

## Testing Pyramid Summary

| Level | Ratio | What to Test | Example |
|-------|-------|--------------|---------|
| Static | Continuous | Types, lint rules | `tsc --noEmit`, ESLint |
| Unit | ~70% | Utils, pure functions, formatters | `formatDate()`, `validateEmail()` |
| Integration | ~20% | Components, hooks, user flows | Form submission, list filtering |
| E2E | ~10% | Critical paths | Login, checkout, signup |

## References

- [SolidJS Testing Guide](https://docs.solidjs.com/guides/testing)
- [Solid Testing Library](https://github.com/solidjs/solid-testing-library)
- [Testing Library Docs](https://testing-library.com/docs/solid-testing-library/intro)
- [Vitest Documentation](https://vitest.dev/)
- [Kent C. Dodds - Testing Trophy](https://kentcdodds.com/blog/the-testing-trophy-and-testing-classifications)
