---
name: skill-creator
description: Guide for creating effective Opencode Agent Skills. Use this when users want to create a new skill or update an existing one.
metadata:
  audience: developers
  type: guide
---

# Skill Creator

This skill guides the creation of Agent Skills for the Opencode environment.

## Opencode Skill Basics

Skills are directories containing a `SKILL.md` file that define reusable behaviors for agents.

### Locations
Skills are discovered in:
1. **Project**: `.opencode/skill/<name>/SKILL.md` (Recommended for project-specific tools)
2. **Global**: `~/.config/opencode/skill/<name>/SKILL.md` (Recommended for general tools)

### Directory Structure
```
skill-name/
├── SKILL.md (required)
└── (Optional resources like scripts/, references/, assets/)
```

### Naming Rules
*   **Name**: 1-64 characters, lowercase alphanumeric with hyphens (e.g., `git-release`, `database-helper`).
*   **Consistency**: The directory name MUST match the `name` field in the frontmatter.

## Creation Workflow

Follow these steps to create a new skill for the user.

### 1. Requirements Gathering
Ask the user:
*   **Goal**: What should the skill do?
*   **Scope**: Is this for the current project or global use?
*   **Triggers**: When should the agent use this skill?

### 2. Implementation
You can create the skill structure using the provided helper script or manually with your tools.

#### Option A: Using Helper Script
This skill includes a script to scaffold the directory and files.
Location: `~/.config/opencode/skill/skill-creator/scripts/init_skill.py`

```bash
# For project-local skill
python3 ~/.config/opencode/skill/skill-creator/scripts/init_skill.py <skill-name>

# For global skill
python3 ~/.config/opencode/skill/skill-creator/scripts/init_skill.py <skill-name> --global
```

#### Option B: Manual Creation
Use your tools (`bash`, `write`) to create the skill.

#### Step 2a: Create Directory
Create the directory based on the user's preference (Global or Project).
```bash
# Example for project skill
mkdir -p .opencode/skill/my-new-skill
```

#### Step 2b: Create SKILL.md
Write the `SKILL.md` file. It **MUST** start with YAML frontmatter.

**Template:**
```markdown
---
name: my-new-skill
description: A concise description (1-1024 chars) of what this skill does and when to use it.
---

## Overview
A brief explanation of the skill's purpose.

## Capabilities
* List key features

## Usage
Instructions for the agent on how to perform the tasks.
```

### 3. Verification
*   Ensure `SKILL.md` is all caps.
*   Verify `name` in frontmatter matches directory name.
*   Verify `description` is present.

## Best Practices
*   **Progressive Disclosure**: Keep `SKILL.md` concise. Move large documentation to `references/` subfolder and link to it.
*   **Scripts**: If the skill requires complex logic, save scripts in `scripts/` and instruct the agent to run them.
*   **Assets**: Store templates or static files in `assets/`.
