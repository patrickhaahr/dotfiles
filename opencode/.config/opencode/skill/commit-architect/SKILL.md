---
name: commit-architect
description: Analyzes git changes and creates well-structured, atomic commits following project conventions. Detects commit style, plans optimal commit grouping, and ensures proper separation of concerns.
---

## CORE PRINCIPLE: MULTIPLE COMMITS BY DEFAULT

**Hard Rule:**
- 3+ files → 2+ commits
- 5+ files → 3+ commits  
- 10+ files → 5+ commits

**Split by:** directory, concern, component type, or revertability

**Combine only when:**
- Same atomic unit (function + test)
- Splitting breaks compilation
- Justifiable in one sentence

**Self-check before committing:**
```
"Am I making 1 commit from 3+ files?" → STOP AND SPLIT
```

---

## PHASE 0: Context Gathering

Run in parallel:
```bash
git status && git diff --staged --stat && git diff --stat
git log -30 --oneline && git log -30 --pretty=format:"%s"
git branch --show-current
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
git rev-parse --abbrev-ref @{upstream} 2>/dev/null || echo "NO_UPSTREAM"
git log --oneline $(git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null)..HEAD 2>/dev/null
```

**Gather:** changed files, recent commit style, branch state, upstream tracking, local commits

### Sync Before Starting
**After gathering context, ALWAYS sync with upstream before making any changes:**

```bash
git pull --rebase
```

**If conflicts occur:**
- **DO NOT fix the conflicts**
- Stop immediately and notify the user
- The user will resolve conflicts before you continue

**Proceed only when:**
- `git pull --rebase` completes without conflicts, OR
- User has explicitly resolved any conflicts

---

## PHASE 1: Style Detection

**Analyze last 30 commits:**

```bash
git log -30 --pretty=format:"%s"
```

**Detection rules:**
| Style | Pattern | Example | Regex |
|-------|---------|---------|-------|
| `SEMANTIC` | `type: message` | `feat: add login` | `/^(feat|fix|chore|refactor|docs|test|ci|style|perf|build)(\(.+\))?:/` |
| `PLAIN` | Description only | `Add login feature` | No prefix, >3 words |
| `SHORT` | 1-3 words | `format`, `lint` | `^\w+(\s+\w+){0,2}$` |

**Decision:**
```
IF semantic >= 50% → SEMANTIC
ELSE IF short >= 30% → SHORT  
ELSE → PLAIN
```

**Output before proceeding:**
```
STYLE: [SEMANTIC | PLAIN | SHORT]
Examples: [3 actual messages from log]
```

---

## PHASE 2: Branch Analysis

```
Current branch: <name>
Upstream: true | false
Local commits: N
On main/master: true | false
```

**Strategy:**
- `main/master` → NEW_COMMITS_ONLY (never rewrite)
- All local commits → AGGRESSIVE_REWRITE (fixup/rebase OK)
- Pushed commits → CAREFUL_REWRITE (warn on force push)

---

## PHASE 3: Commit Planning

**Minimum commits:** `ceil(file_count / 3)`

**Split rules:**
1. **Different directories** → different commits
2. **Different concerns** → different commits (UI, logic, config, test)
3. **Implementation + test** → same commit

**Example:**
```
8 files:
  app/page.tsx, app/layout.tsx        → commit 1 (app layer)
  components/demo/*.tsx               → commit 2 (demo)
  components/pricing/*.tsx            → commit 3 (pricing)
  e2e/*.spec.ts                       → commit 4 (tests)
  messages/*.json                     → commit 5 (i18n)
```

**Dependency order:**
```
Level 0: utils, types, constants
Level 1: models, schemas
Level 2: services, business logic
Level 3: API endpoints
Level 4: config, infrastructure
```

**Output plan:**
```
COMMIT PLAN
===========
Files: N | Min commits: M | Planned: K | Status: PASS/FAIL

Commit 1: <message>
  - file1.py, file1_test.py
  Justification: implementation + test

Commit 2: <message>
  - file2.py
  Justification: independent utility

Order: Commit 1 → Commit 2 (Level 0 → Level 1)
```

**Requirements:**
- Each commit ≤4 files (or justified)
- Tests paired with implementation
- Total commits ≥ min_commits

---

## PHASE 4: Strategy Decision

**Choose FIXUP when:**
- Complements existing commit's intent
- Same feature, fixing bugs
- Review feedback
- Target commit exists locally

**Choose NEW COMMIT when:**
- New feature
- Independent unit
- Different issue/ticket

**Reset & rebuild:**
```bash
git reset --soft $(git merge-base HEAD main)
# Recommit in atomic units
```
**Only if:** all commits local + user allows

**Final plan:**
```yaml
strategy: FIXUP_THEN_NEW | NEW_ONLY | RESET_REBUILD
commits:
  - type: fixup/new
    files: [...]
    message: "..."
```

---

## PHASE 5: Execution

**Fixup commits:**
```bash
git add <files>
git commit --fixup=<hash>
# Repeat for all fixups
git rebase -i --autosquash $(git merge-base HEAD main)
```

**New commits:**
```bash
git add <files>
git commit -m "<message>"  # Use detected style
```

**Message format:**
| Style | Format |
|-------|--------|
| SEMANTIC | `feat: add login` |
| PLAIN | `Add login feature` |
| SHORT | `format`, `lint` |

**Validate:** matches detected style + similar to git log examples

---

## PHASE 6: Verification

```bash
git status  # Clean working directory
git log --oneline $(git merge-base HEAD main)..HEAD  # Review history
```

**Push strategy:**
- Fixups used → `git push --force-with-lease`
- New commits only → `git push`

**Final report:**
```
Created: N commits | M fixups merged
History:
  abc123 Add feature X
  def456 Fix bug Y

Next: git push [--force-with-lease]
```

---

## Quick Reference

**Style detection:**
- `feat:`, `fix:` → SEMANTIC
- `Add`, `Fix` → PLAIN
- `format`, `lint` → SHORT
- Mix → Use majority

**Decision tree:**
```
main/master? → NEW_COMMITS_ONLY (never rewrite)
All local? → AGGRESSIVE_REWRITE OK
Pushed? → CAREFUL_REWRITE (warn on force push)
Complements existing? → FIXUP
New feature? → NEW COMMIT
```

**Anti-patterns:**
1. One giant commit (3+ files → 2+ commits)
2. Default to semantic (detect from git log)
3. Separate test from implementation
4. Group by file type (group by feature)
5. Rewrite pushed history without permission
6. Leave working directory dirty
7. Skip justification for file grouping
8. Vague reasons ("related to X")

## Final Check

```
[ ] Min commits: ceil(N/3)?
[ ] Justified commits with 3+ files?
[ ] Different directories split?
[ ] Tests paired with implementation?
[ ] Dependency order correct?
```

**Stop conditions:**
- 1 commit from 3+ files → SPLIT
- Can't justify grouping → SPLIT
- Different dirs together → SPLIT
