# Ralph Agent Runbook

Ralph is an autonomous coding agent loop that iterates through user stories in a PRD, implementing one story per iteration until all pass.

## How Ralph Works

```
┌─────────────────────────────────────────────────────────────┐
│  Ralph Loop (per iteration)                                 │
├─────────────────────────────────────────────────────────────┤
│  1. Read prd.json → find highest priority passes:false      │
│  2. Checkout/create branch from branchName                  │
│  3. Implement the single story                              │
│  4. Run quality checks (lint, test, typecheck)              │
│  5. If checks pass → commit: feat: [ID] - [Title]           │
│  6. Update prd.json: passes: true                           │
│  7. Append progress to progress.txt                         │
│  8. If all stories pass → <promise>COMPLETE</promise>       │
│  9. Otherwise → next iteration picks next story             │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

### Required: jq (JSON processor)

```bash
# Check if installed
command -v jq || echo "jq missing"

# Install (choose your platform)
# macOS:
brew install jq

# Ubuntu/Debian:
sudo apt-get install jq

# Windows (Git Bash / MSYS2):
pacman -S jq
# or via Chocolatey:
choco install jq
```

### Required: Claude Code OR Amp CLI

**Option A: Claude Code (recommended)**

```bash
# Install
npm install -g @anthropic-ai/claude-code

# Verify
claude --version
```

**Option B: Amp**

```bash
# Install per Amp documentation
# Verify
amp --version
```

## Repository Setup

### 1. Verify Ralph is vendored

Ralph scripts should be at `scripts/ralph/`:

```bash
ls -la scripts/ralph/
# Expected:
#   ralph.sh     (main entry point)
#   CLAUDE.md    (Claude Code agent instructions)
#   prompt.md    (Amp agent instructions)
```

If missing, clone from source:

```bash
# Option A: Submodule (trackable)
git submodule add https://github.com/snarktank/ralph.git scripts/ralph

# Option B: Vendor copy (simpler)
git clone --depth 1 https://github.com/snarktank/ralph.git /tmp/ralph
cp -r /tmp/ralph/scripts/ralph scripts/
rm -rf /tmp/ralph
```

### 2. Create/verify prd.json (repo root)

```json
{
  "branchName": "ralph/feature-name",
  "userStories": [
    {
      "id": "STORY-001",
      "title": "Short descriptive title",
      "description": "What needs to be done",
      "priority": 1,
      "passes": false,
      "acceptanceCriteria": [
        "Criterion 1",
        "Criterion 2"
      ]
    }
  ]
}
```

**Key fields:**

| Field | Purpose |
|-------|---------|
| `branchName` | Git branch Ralph will checkout/create |
| `userStories[].id` | Unique story identifier (used in commit message) |
| `userStories[].priority` | Lower number = higher priority |
| `userStories[].passes` | `false` = needs work; `true` = done |

### 3. Create/verify progress.txt (repo root)

```markdown
# Ralph Progress Log

## Codebase Patterns

- Pattern 1 discovered during work
- Pattern 2 discovered during work

---
Started: YYYY-MM-DD
---
```

The "Codebase Patterns" section at the top is read by Ralph before each iteration to understand repo conventions.

## Running Ralph

### From repo root (Linux/macOS/WSL)

```bash
# Using Claude Code (default max 10 iterations)
./scripts/ralph/ralph.sh --tool claude

# Using Amp
./scripts/ralph/ralph.sh --tool amp

# With custom iteration limit
./scripts/ralph/ralph.sh --tool claude 5
```

### Windows Git Bash (special instructions)

On Windows, use the wrapper script which ensures correct PATH:

```bash
# Using the wrapper (recommended on Windows)
./scripts/ralph/run-ralph.sh --tool claude 1

# If jq is not found, copy it to ~/bin:
mkdir -p ~/bin
cp "$LOCALAPPDATA/Microsoft/WinGet/Packages/jqlang.jq_"*/jq.exe ~/bin/jq

# Verify setup
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"
jq --version
claude --version
```

### What happens

1. Ralph reads `prd.json` and `progress.txt`
2. Checks out branch specified in `branchName`
3. Picks highest priority story with `passes: false`
4. Implements the story
5. Runs quality checks
6. Commits with message: `feat: [Story ID] - [Story Title]`
7. Updates `prd.json` to mark story as `passes: true`
8. Appends progress entry to `progress.txt`
9. Repeats until all stories pass or max iterations reached

## Fear-of-Falling Integration

When stories involve the FOF subproject, Ralph must follow repo conventions.

### Working directory rule

Stories touching FOF code should be implemented from:

```
Python-R-Scripts/Fear-of-Falling/
```

The `progress.txt` Codebase Patterns section reminds Ralph of this.

### Golden rules (from AGENTS.md / CLAUDE.md)

- Do not edit raw data
- Do not commit data, outputs, or secrets
- Keep changes minimal and reversible
- Kxx scripts require standard intro block
- Outputs go to `R-scripts/<script_label>/outputs/`
- One manifest row per artifact

### PRD example for FOF story

```json
{
  "branchName": "ralph/fof-k18-fix",
  "userStories": [
    {
      "id": "FOF-001",
      "title": "Fix K18 missing column handling",
      "description": "Update K18.R to fail gracefully when expected column is missing. Work in Fear-of-Falling/ directory. Follow Kxx conventions in CLAUDE.md.",
      "priority": 1,
      "passes": false,
      "acceptanceCriteria": [
        "K18.R checks for required columns before processing",
        "Clear error message if column missing",
        "No changes to raw data",
        "Script runs successfully from Fear-of-Falling/"
      ]
    }
  ]
}
```

## Smoke Test

Verify Ralph works with a minimal test:

### 1. Set up test PRD

```bash
cat > prd.json << 'EOF'
{
  "branchName": "ralph/smoke-test",
  "userStories": [
    {
      "id": "SMOKE-001",
      "title": "Verify Ralph bootstrap",
      "description": "Create a test file to confirm Ralph loop works",
      "priority": 1,
      "passes": false,
      "acceptanceCriteria": [
        "File docs/ralph-smoke-test.md exists",
        "File contains timestamp"
      ]
    }
  ]
}
EOF
```

### 2. Run Ralph (single iteration)

```bash
./scripts/ralph/ralph.sh --tool claude 1
```

### 3. Verify results

```bash
# Check branch was created
git branch --show-current
# Expected: ralph/smoke-test

# Check progress was updated
tail -20 progress.txt

# Check PRD was updated
cat prd.json | jq '.userStories[0].passes'
# Expected: true (if story completed)

# Check commit message format
git log -1 --oneline
# Expected: feat: SMOKE-001 - Verify Ralph bootstrap
```

### 4. Cleanup

```bash
git checkout main
git branch -D ralph/smoke-test
# Reset prd.json and progress.txt to desired state
```

## Troubleshooting

### "jq: command not found"

Install jq (see Prerequisites).

### "claude: command not found"

Install Claude Code:

```bash
npm install -g @anthropic-ai/claude-code
```

### Ralph doesn't pick the right story

Check `prd.json`:
- Story must have `"passes": false`
- Lower `priority` number = picked first
- JSON must be valid (use `jq . prd.json` to validate)

### Ralph makes changes in wrong directory

Add explicit working directory instruction to:
1. Story description in `prd.json`
2. Codebase Patterns section in `progress.txt`

### Ralph doesn't follow repo conventions

Ensure `progress.txt` has a populated "Codebase Patterns" section that Ralph reads before each iteration. Critical patterns should be listed there.

## File Reference

| File | Location | Purpose |
|------|----------|---------|
| `ralph.sh` | `scripts/ralph/` | Main entry point |
| `CLAUDE.md` | `scripts/ralph/` | Claude Code agent instructions |
| `prompt.md` | `scripts/ralph/` | Amp agent instructions |
| `prd.json` | repo root | Product requirements / stories |
| `progress.txt` | repo root | Progress log + codebase patterns |
| `.last-branch` | repo root (auto-created) | Tracks current Ralph branch |
| `archive/` | repo root (auto-created) | Archives previous runs |

## References

- [snarktank/ralph](https://github.com/snarktank/ralph) - Ralph source repository
- [Fear-of-Falling/AGENTS.md](../Fear-of-Falling/AGENTS.md) - FOF agent conventions
- [Fear-of-Falling/CLAUDE.md](../Fear-of-Falling/CLAUDE.md) - FOF Kxx script conventions
