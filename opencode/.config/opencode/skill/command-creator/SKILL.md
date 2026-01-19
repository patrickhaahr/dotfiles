---
name: command-creator
description: Create and configure custom commands for Opencode to automate repetitive tasks with custom prompts.
---

## Overview

The command-creator skill helps you define custom commands in Opencode. Custom commands let you specify prompts that run when you execute the command in the TUI with `/command-name`.

## Creating Commands

Commands are defined using markdown files in the `command/` directory:
- Global: `~/.config/opencode/command/<name>.md`
- Per-project: `.opencode/command/<name>.md`

The filename becomes the command name. Example: `test.md` creates `/test`.

**Example:** `.opencode/command/test.md`
```markdown
---
description: Run tests with coverage
agent: build
model: anthropic/claude-3-5-sonnet-20241022
---
Run the full test suite with coverage report and show any failures.
Focus on the failing tests and suggest fixes.
```

## Frontmatter Options

| Option | Required | Description |
|--------|----------|-------------|
| `description` | No | Brief description shown in TUI |
| `agent` | No | Agent to execute (defaults to current) |
| `subtask` | No | Force subagent invocation (true/false) |
| `model` | No | Override default model |

The prompt template follows the frontmatter section.

## Prompt Placeholders

### Arguments

- `$ARGUMENTS` - All arguments passed to the command
- `$1`, `$2`, `$3`... - Individual positional arguments

**Example:**
```markdown
---
description: Create a new component
---
Create a React component named $ARGUMENTS with TypeScript support.
```

Usage: `/component Button` → `$ARGUMENTS` = `Button`

### Shell Output

Use `` !`command` `` to inject bash output into prompts:

```markdown
---
description: Analyze test coverage
---
Here are the current test results:
!`npm test`

Based on these results, suggest improvements to increase coverage.
```

### File References

Use `@filename` to include file content in prompts:

```markdown
---
description: Review component
---
Review @src/components/Button.tsx for performance issues.
```

## Built-in Commands

Opencode includes built-in commands: `/init`, `/undo`, `/redo`, `/share`, `/help`. Custom commands can override these if they share the same name.

## Usage

When the skill is triggered:
1. Ask the user what command they want to create
2. Determine if it should be global or project-specific
3. Write the markdown file with frontmatter options and prompt
4. Explain how to use the command
