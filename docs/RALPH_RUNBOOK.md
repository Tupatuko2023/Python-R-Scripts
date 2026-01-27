# Ralph Agent Runbook

Ralph is an autonomous coding agent loop that iterates through user stories in a PRD, implementing one story per iteration until all pass.

## Quickstart

### macOS / Linux

```bash
# 1. Install prerequisites
brew install jq                              # macOS
# sudo apt-get install jq                    # Ubuntu/Debian

npm install -g @anthropic-ai/claude-code     # Claude Code CLI

# 2. Verify setup
jq --version && claude --version

# 3. Run Ralph (from repo root)
./scripts/ralph/ralph.sh --tool claude 5
```

### Windows (Git Bash)

```bash
# 1. Install prerequisites (run in PowerShell as Admin first)
#    winget install jqlang.jq
#    npm install -g @anthropic-ai/claude-code

# 2. Copy jq to ~/bin (one-time setup in Git Bash)
mkdir -p ~/bin
cp "$LOCALAPPDATA/Microsoft/WinGet/Packages/jqlang.jq_"*/jq.exe ~/bin/jq

# 3. Run Ralph using the wrapper (from repo root)
./scripts/ralph/run-ralph.sh --tool claude 5
```

The wrapper script (`run-ralph.sh`) automatically:
- Adds `~/bin` and `~/.local/bin` to PATH
- Auto-detects WinGet jq location
- Verifies prerequisites before starting
- Shows PRD status (stories done/remaining)

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

| Tool | Purpose | Install |
|------|---------|---------|
| `jq` | JSON processor (parses prd.json) | `brew install jq` / `apt install jq` / `winget install jqlang.jq` |
| `claude` | Claude Code CLI (AI agent) | `npm install -g @anthropic-ai/claude-code` |
| `amp` | Alternative: Amp CLI | See Amp documentation |

## Repository Setup

### 1. Verify Ralph is vendored

```bash
ls scripts/ralph/
# Expected: ralph.sh, run-ralph.sh, CLAUDE.md, prompt.md
```

### 2. Create prd.json (repo root)

```json
{
  "branchName": "ralph/feature-name",
  "userStories": [
    {
      "id": "STORY-001",
      "title": "Short descriptive title",
      "description": "What needs to be done. Include working directory if relevant.",
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

### 3. Create progress.txt (repo root)

```markdown
# Ralph Progress Log

## Codebase Patterns

- Pattern 1 discovered during work
- Pattern 2 discovered during work

---
Started: YYYY-MM-DD
---
```

The "Codebase Patterns" section is read by Ralph before each iteration.

## Running Ralph

### Standard usage

```bash
# Claude Code (recommended)
./scripts/ralph/run-ralph.sh --tool claude 10

# Amp
./scripts/ralph/run-ralph.sh --tool amp 10

# Direct (skip wrapper checks)
./scripts/ralph/ralph.sh --tool claude 10
```

### What happens

1. Ralph reads `prd.json` and `progress.txt`
2. Checks out branch specified in `branchName`
3. Picks highest priority story with `passes: false`
4. Implements the story
5. Runs quality checks
6. Commits: `feat: [Story ID] - [Story Title]`
7. Updates `prd.json` → `passes: true`
8. Appends progress entry to `progress.txt`
9. Repeats until all stories pass or max iterations reached

## Fear-of-Falling Integration

### Working directory rule

FOF stories must be implemented from:

```
Python-R-Scripts/Fear-of-Falling/
```

Include this in story descriptions or the Codebase Patterns section.

### Golden rules (from AGENTS.md / CLAUDE.md)

- Do not edit raw data
- Do not commit data, outputs, or secrets
- Keep changes minimal and reversible
- Kxx scripts require standard intro block
- Outputs go to `R-scripts/<script_label>/outputs/`
- One manifest row per artifact

### Example FOF story

```json
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
```

## Troubleshooting

### "jq: command not found"

**macOS:** `brew install jq`

**Linux:** `sudo apt-get install jq`

**Windows:**
```bash
# Install via winget (PowerShell)
winget install jqlang.jq

# Then copy to ~/bin (Git Bash)
mkdir -p ~/bin
cp "$LOCALAPPDATA/Microsoft/WinGet/Packages/jqlang.jq_"*/jq.exe ~/bin/jq
```

### "claude: command not found"

```bash
npm install -g @anthropic-ai/claude-code
```

### Ralph doesn't pick the right story

- Story must have `"passes": false`
- Lower `priority` number = picked first
- Validate JSON: `jq . prd.json`

### Ralph makes changes in wrong directory

Add working directory to:
1. Story description in `prd.json`
2. Codebase Patterns in `progress.txt`

### Wrapper shows "No stories with passes:false"

All stories are complete. To re-run:
- Edit `prd.json` → set `passes: false` on desired stories
- Or add new stories

## File Reference

| File | Location | Purpose |
|------|----------|---------|
| `ralph.sh` | `scripts/ralph/` | Core agent loop |
| `run-ralph.sh` | `scripts/ralph/` | Cross-platform wrapper with prereq checks |
| `CLAUDE.md` | `scripts/ralph/` | Claude Code agent instructions |
| `prompt.md` | `scripts/ralph/` | Amp agent instructions |
| `prd.json` | repo root | Product requirements / stories |
| `progress.txt` | repo root | Progress log + codebase patterns |
| `.last-branch` | repo root (auto) | Tracks current Ralph branch |
| `archive/` | repo root (auto) | Archives previous runs |

## References

- [snarktank/ralph](https://github.com/snarktank/ralph) - Ralph source repository
- [Fear-of-Falling/AGENTS.md](../Fear-of-Falling/AGENTS.md) - FOF agent conventions
- [Fear-of-Falling/CLAUDE.md](../Fear-of-Falling/CLAUDE.md) - FOF Kxx script conventions
