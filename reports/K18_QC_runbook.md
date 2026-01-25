# K18 QC Runbook

**Purpose:** Stop-the-line QC validation for FOF×time analysis pipeline
**PR #49:** 909f534 (merged 2026-01-05)
**Workflow:** Preflight → K18 QC → QC Summarizer → Evidence Gates → PR

---

## Prerequisites

- R environment with `renv` restored (`Fear-of-Falling/`)
- Git working directory clean or changes staged
- Data file available (location: project-specific, not in repo)
- Data dictionary available (location: `data/` or override in `outputs/`)

---

## Step 1: Discovery

Find K18 QC command syntax and verify output paths:

```bash
# From repo root
cd Fear-of-Falling

# Find QC checklist (if exists)
rg -l "QC_CHECKLIST" -g "*.md" || echo "No checklist found"

# Verify K18 QC runner exists
test -f R-scripts/K18/K18_QC.V1_qc-run.R && echo "✅ Runner found" || echo "❌ Runner missing"

# Verify QC output directories structure
ls -d R-scripts/K18/outputs/K18_QC/qc 2>/dev/null && echo "✅ QC dir exists" || echo "Create on first run"
```

---

## Step 2: Preflight Check (Diff-Aware Guardrails)

**Tool:** `.codex/skills/fof-preflight/scripts/preflight.py`
**Supported flags:** `--verbose`

Run from **repo root** before making changes:

```bash
# From repo root (NOT Fear-of-Falling/)
cd C:/GitWork/Python-R-Scripts

# Basic preflight (checks git diff for blocked changes)
python3 .codex/skills/fof-preflight/scripts/preflight.py

# Verbose (shows per-file details)
python3 .codex/skills/fof-preflight/scripts/preflight.py --verbose
```

**Blocks:**

- Raw data edits (`data/`, `data/external/`)
- Kxx script intro/Required Vars mismatches
- Output discipline violations

---

## Step 3: K18 QC Execution

**Runner:** `Fear-of-Falling/R-scripts/K18/K18_QC.V1_qc-run.R`
**Required flags:** `--data <PATH>`
**Optional flags:** `--dict <PATH>`, `--shape <AUTO|LONG|WIDE>`

```bash
# From Fear-of-Falling/ directory
cd Fear-of-Falling

# Run K18 QC (replace <DATA_PATH> with actual path)
Rscript R-scripts/K18/K18_QC.V1_qc-run.R \
  --data <DATA_PATH> \
  --shape WIDE

# If using override dictionary (for QC validation adjustments)
Rscript R-scripts/K18/K18_QC.V1_qc-run.R \
  --data <DATA_PATH> \
  --dict R-scripts/K18/outputs/K18_QC/references/data_dictionary.override.csv \
  --shape WIDE
```

**Note:** Override dictionary must be in output discipline path (`R-scripts/K18/outputs/K18_QC/references/`), NOT in protected `data/` directory.

**Outputs:** 20+ QC artifacts in `R-scripts/K18/outputs/K18_QC/qc/`
**Manifest entries:** Automatic (appended to `manifest/manifest.csv`)

---

## Step 4: QC Summarizer (Aggregate-Only)

**Tool:** `.codex/skills/fof-qc-summarizer/scripts/qc_summarize.R`
**Supported flags:** `--qc-dir <PATH>`, `--out-dir <PATH>`, `--script-label <LABEL>`

```bash
# From repo root
cd C:/GitWork/Python-R-Scripts

# Run QC summarizer (defaults resolved from project root)
Rscript .codex/skills/fof-qc-summarizer/scripts/qc_summarize.R \
  --qc-dir Fear-of-Falling/R-scripts/K18/outputs/K18_QC/qc \
  --out-dir Fear-of-Falling/R-scripts/K18/outputs/K18_QC/qc_summary \
  --script-label K18_QC_SUMMARY
```

**Outputs:**

- `qc_summary.csv` (15 rows: aggregate checks only)
- `qc_summary.txt` (human-readable)

**Privacy:** Participant-level artifacts (`qc_row_id_watch.csv`, `qc_uniqueness.csv`) are NOT included in summary.

---

## Step 5: Evidence Gates (Before PR)

### a) Files Changed Count

```bash
# From repo root
gh pr view <PR_NUM> --json files --jq '.files | length'

# Expected: 3 files (K18_QC.V1_qc-run.R, manifest.csv, C3fix_acceptance_memo.txt)
```

### b) Scope Check (K18 Only)

```bash
# Ensure no K11-K16 or other scope creep
gh pr view <PR_NUM> --json files --jq '.files[].path' | grep -v "K18\|reports/C3fix" && echo "❌ SCOPE CREEP" || echo "✅ CLEAN"
```

### c) Manifest Wrong-Path Grep

```bash
# From Fear-of-Falling/
grep "K18_QC/outputs" manifest/manifest.csv && echo "❌ FAIL: wrong paths" || echo "✅ PASS"

# Correct pattern: R-scripts/K18/outputs/K18_QC/qc/...
grep "R-scripts/K18/outputs/K18_QC" manifest/manifest.csv | wc -l
```

### d) Verify Merge Commit Scope

```bash
# Get merge SHA from PR
gh pr view <PR_NUM> --json mergeCommit --jq '.mergeCommit.oid'

# Verify actual changes in merge commit
git show --stat <MERGE_SHA>

# Expected: 3 files changed, +271/-59 (approx)
```

---

## Step 6: Commit & PR Strategy

### What to Commit

✅ **Commit:**

- `R-scripts/K18/K18_QC.V1_qc-run.R` (runner fixes)
- `manifest/manifest.csv` (K18_QC artifact rows)
- `R-scripts/K18/outputs/K18_QC/qc_summary/*` (aggregate-only)
- `R-scripts/K18/outputs/K18_QC/references/data_dictionary.override.csv` (if created)
- `reports/C3fix_acceptance_memo.txt` (acceptance criteria)

❌ **DO NOT Commit:**

- `R-scripts/K18/outputs/K18_QC/qc/qc_row_id_watch.csv` (contains participant IDs)
- `R-scripts/K18/outputs/K18_QC/qc/qc_uniqueness.csv` (contains participant IDs)
- Raw data files (`data/`, `data/external/`)

### PR Strategy

```bash
# Create clean branch from main
git checkout main
git pull
git checkout -b chore/fof-k18-qc-only

# Make changes, then commit
git add <FILES>
git commit -m "fix(K18): QC guardrail violations and acceptance memo"

# Push and create PR
git push -u origin chore/fof-k18-qc-only
gh pr create --title "fix(K18): QC guardrail violations + acceptance memo" \
  --body "Resolves K18 QC blockers with output discipline fixes"

# Before merge: run evidence gates (Steps 5a-5d)

# Merge with squash strategy
gh pr merge <PR_NUM> --squash --delete-branch
```

---

## Post-Merge Verification

```bash
# Verify merge scope from main
git checkout main
git pull
git log --oneline -3

# Verify merge commit matches PR scope
git show --stat <MERGE_SHA>

# Expected: 3 files changed, no scope creep
```

---

## Troubleshooting

### Preflight Fails on Data Changes

**Error:** `Raw data paths changed (blocked)`
**Fix:** Do not modify `data/` or `data/external/`. Create override dictionaries in output discipline path.

### K18 QC Fails with Empty Data Frames

**Error:** `QC FAIL: time_out$status is empty; cannot construct time_details.`
**Cause:** Defensive guards added in PR #49 (fail-closed pattern)
**Fix:** Check data dictionary `allowed_values_or_coding` for `time` and `FOF_status` variables match actual data encoding.

### Wrong Manifest Paths

**Error:** Manifest contains `R-scripts/K18_QC/outputs/...`
**Expected:** `R-scripts/K18/outputs/K18_QC/...`
**Fix:** Verify `manifest_script_label <- "K18_QC"` and `qc_dir <- file.path(outputs_dir, manifest_script_label, "qc")` in runner (line 81-83).

---

## References

- **PR #49:** https://github.com/Tupatuko2023/Python-R-Scripts/pull/49
- **Merge commit:** 909f534
- **Acceptance memo:** `reports/C3fix_acceptance_memo.txt`
- **Preflight skill:** `.codex/skills/fof-preflight/SKILL.md`
- **QC summarizer skill:** `.codex/skills/fof-qc-summarizer/SKILL.md`
- **Project conventions:** `Fear-of-Falling/CLAUDE.md` (Kxx standard intro, output discipline)

---

**Last updated:** 2026-01-05
**Author:** Claude Sonnet 4.5 (PR #49 cleanup)
