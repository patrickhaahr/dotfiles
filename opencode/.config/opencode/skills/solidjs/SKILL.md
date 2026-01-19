---
name: solidjs
description: Expert guide for SolidJS development, covering reactivity, component patterns, and migration from React.
---

## Overview
This skill provides best practices, patterns, and anti-patterns for developing with SolidJS. It focuses on the "Render Once" mental model, fine-grained reactivity, and avoiding common pitfalls when transitioning from React.

## Capabilities
*   **Reactivity Guidance**: Correct usage of Signals, Effects, and Memos.
*   **Component Patterns**: Proper props handling, control flow, and composition.
*   **Performance Optimization**: Store usage, batching, and code splitting.
*   **Debugging**: Identifying memory leaks and hydration issues.
*   **React Migration**: Checklist for converting React components to SolidJS.

## Usage
Consult this skill when:
*   Writing or refactoring SolidJS components.
*   Debugging reactivity issues (e.g., components not updating).
*   Migrating code from React to SolidJS.
*   Setting up new SolidJS project structures.

---

# SolidJS Best Practices Guide

## 1. Foundational Concepts: The Mental Model Shift

### 1.1 "Render Once" Architecture
SolidJS components execute **exactly once** to set up reactive dependencies. This is the most critical difference from React.

```tsx
// ❌ WRONG: React mental model - expecting re-execution
function Counter() {
  const [count, setCount] = createSignal(0);
  console.log("This runs ONCE, not on every update"); // Only logs once
  return <button onClick={() => setCount(count() + 1)}>{count()}</button>;
}

// ✅ CORRECT: Use effects for reactive logic
function Counter() {
  const [count, setCount] = createSignal(0);
  
  createEffect(() => {
    console.log("Count changed:", count()); // Logs on every change
  });
  
  return <button onClick={() => setCount(count() + 1)}>{count()}</button>;
}
```

### 1.2 Fine-Grained Reactivity vs Virtual DOM
React re-renders component trees; SolidJS updates individual DOM nodes. Updates are O(1) per signal, not O(n) per component tree.

## 2. Reactive Primitives: The Core API

### 2.1 Signals: Always Use Getter/Setter Pattern
`createSignal` returns a tuple: `[getter, setter]`. **Never** destructure the getter.

### 2.2 Derived State: Use `createMemo`
For expensive computations depending on signals. Automatically memoized.

```tsx
// ✅ CORRECT: Only recalculates when dependencies change
const expensiveResult = createMemo(() => heavyCalculation(props.data()));
```

### 2.3 Side Effects: Use `createEffect`
For DOM manipulation, logging, or external state sync. **Cleanup is mandatory for subscriptions.**

```tsx
createEffect(() => {
  const handler = () => console.log("clicked");
  document.addEventListener("click", handler);
  onCleanup(() => document.removeEventListener("click", handler));
});
```

### 2.4 Async Data: Use `createResource`
Handles loading, error states, and integrates with `<Suspense>`.

## 3. Component Patterns & Composition

### 3.1 Props Handling: No Destructuring
Props are reactive proxies. Destructuring breaks the proxy.

```tsx
// ❌ WRONG: Destructuring loses reactivity
function MyComponent({ name }) { ... }

// ✅ CORRECT: Access props directly
function MyComponent(props) {
  return <div>{props.name}</div>;
}

// ✅ CORRECT: Use splitProps for partial access
const [local, others] = splitProps(props, ["name"]);
```

### 3.2 Control Flow: Use Solid's Components
Never use `.map` or ternaries directly in JSX for dynamic lists/conditions. Use `<For>`, `<Show>`, `<Switch>`, and `<Match>`.

```tsx
// ✅ CORRECT
<For each={items()}>
  {(item) => <div>{item.name}</div>}
</For>
```

## 4. Performance Best Practices

*   **Minimize Signal Granularity**: Use `createStore` for collections, not arrays of signals.
*   **Batch Updates**: Use `batch(() => { ... })` to group multiple updates.
*   **Lazy Loading**: Use `lazy(() => import(...))` for routes.

## 5. Common Pitfalls & Anti-Patterns

*   **Infinite Loops**: Never update a signal you read in the same effect.
*   **Hydration Mismatches**: Use `isServer` checks or `<ClientOnly>` for browser APIs/random values.
*   **Mutating Resources**: Treat resources as immutable; use the `mutate` helper.

## 6. Migration Checklist from React

*   [ ] Replace `useState` with `createSignal`
*   [ ] Replace `useMemo` with `createMemo`
*   [ ] Replace `useEffect` with `createEffect` + `onCleanup`
*   [ ] Replace `useContext` with `useContext` (similar API)
*   [ ] Remove `useCallback` and `React.memo` (not needed)
*   [ ] Replace `.map()` with `<For>`
*   [ ] Replace ternaries with `<Show>`
*   [ ] Access props as `props.name` (no destructuring)
