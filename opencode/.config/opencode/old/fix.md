# Fix Prompt

## Description
A fix request means debugging and resolving an issue, error, or bug in the code.

## Usage
When the user includes "fix" in their prompt:
- Identify the root cause of the issue
- Implement a proper solution (not just a workaround)
- Add error handling if missing
- Write/update tests to prevent regression
- Verify the fix works with existing tests
- Check for similar issues elsewhere in the codebase

## Debugging Approach
1. Reproduce the issue
2. Examine error messages and stack traces
3. Check recent changes (git log/diff)
4. Add logging if needed to understand flow
5. Implement fix
6. Test thoroughly
7. Clean up any debug logging

## Example
"Fix the login timeout issue"

This means: investigate why login is timing out and implement a proper solution with error handling.
