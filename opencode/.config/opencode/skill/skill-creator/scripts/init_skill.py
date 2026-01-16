#!/usr/bin/env python3
import os
import argparse
import sys
from pathlib import Path

def create_skill(name, is_global=False):
    # validate name
    if not name.replace('-', '').isalnum() or not name.islower():
        print(f"Error: Name '{name}' must be lowercase alphanumeric with hyphens.")
        sys.exit(1)

    # Determine base path
    if is_global:
        base_path = Path.home() / ".config" / "opencode" / "skill"
    else:
        # Check if we are in a project root (look for .git or .opencode)
        # If .opencode exists, use it. Else create it.
        # Ideally we want to be in the project root.
        base_path = Path(".opencode") / "skill"

    skill_path = base_path / name

    if skill_path.exists():
        print(f"Error: Skill directory '{skill_path}' already exists.")
        sys.exit(1)

    print(f"Creating skill '{name}' at {skill_path}...")

    # Create directories
    try:
        os.makedirs(skill_path / "scripts", exist_ok=True)
        os.makedirs(skill_path / "references", exist_ok=True)
        os.makedirs(skill_path / "assets", exist_ok=True)
    except Exception as e:
        print(f"Error creating directories: {e}")
        sys.exit(1)

    # Create SKILL.md template
    skill_md_content = f"""---
name: {name}
description: [TODO: Add a concise description of what this skill does and when to use it]
---

# {name.replace('-', ' ').title()}

## Overview
[TODO: Describe the skill's purpose]

## Usage
[TODO: Describe how to use the skill]

## Resources
* Scripts are in `scripts/`
* References are in `references/`
* Assets are in `assets/`
"""
    
    with open(skill_path / "SKILL.md", "w") as f:
        f.write(skill_md_content)

    print(f"Skill '{name}' created successfully!")
    print(f"Next steps:")
    print(f"1. Edit {skill_path}/SKILL.md")
    print(f"2. Add scripts or references as needed.")

def main():
    parser = argparse.ArgumentParser(description="Initialize a new Opencode skill")
    parser.add_argument("name", help="Name of the skill (lowercase, hyphens)")
    parser.add_argument("--global", action="store_true", dest="is_global", help="Install skill globally (~/.config/opencode/skill)")
    
    args = parser.parse_args()
    create_skill(args.name, args.is_global)

if __name__ == "__main__":
    main()
