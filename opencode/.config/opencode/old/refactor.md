# Refactor Prompt

## Description
A refactor request means improving code structure, readability, or performance without changing its external behavior.

## Usage
When the user includes "refactor" in their prompt:
- Preserve existing functionality (no breaking changes)
- Improve code organization and readability
- Reduce code duplication (DRY principle)
- Improve naming conventions
- Simplify complex logic
- Update tests if needed to match refactored code
- Ensure all tests pass after refactoring

## What to Look For
- Long functions (>50 lines) that can be broken down
- Repeated code patterns
- Complex conditionals that can be simplified
- Magic numbers/strings that should be constants
- Unclear variable or function names

## Example
"Refactor the authentication module"

This means: improve the code structure while maintaining the same authentication behavior.
