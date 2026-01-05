# Python and R Scripts

![python-ci](https://github.com/Tupatuko2023/Python-R-Scripts/actions/workflows/python-ci.yml/badge.svg)
![r-ci](https://github.com/Tupatuko2023/Python-R-Scripts/actions/workflows/r-ci.yml/badge.svg)

This repository contains Python and R projects for data analysis and research
workflows. Each subfolder is a standalone project with its own docs.

## Main project

- [Electronic Frailty Index](Electronic-Frailty-Index/README.md)

## Quick start

```bash
python src/efi/cli.py \
  --input data/external/synthetic_patients.csv \
  --out out/efi_scores.csv \
  --report-md out/report.md
```

## License and citation

- License: [MIT License](LICENSE)
- How to cite: [CITATION.cff](CITATION.cff)

## Disclaimer

See [DISCLAIMER.md](DISCLAIMER.md). No PHI or PII in this repository.

## Developer workflows

### Markdown formatting & linting

All Markdown files are checked for formatting (Prettier) and linting (markdownlint-cli2)
in CI. **CI runs checks only** — it will not auto-fix your files.

**Local setup:**

```bash
# Install dependencies
npm ci

# Format all Markdown files (fixes Prettier issues)
npx prettier --write "**/*.md"

# Auto-fix markdownlint violations
npx markdownlint-cli2 --fix "**/*.md"

# Check without fixing (same as CI)
npx prettier --check "**/*.md"
npx markdownlint-cli2 "**/*.md"
```

**Pre-commit hooks (recommended):**

Install pre-commit to auto-format and auto-fix before each commit:

```bash
# Install pre-commit (requires Python)
pip install pre-commit

# Install hooks
pre-commit install

# Run manually on all files
pre-commit run --all-files
```

**When CI fails:**

If the "Lint Markdown" check fails on your PR:

1. Run locally: `npx prettier --write "**/*.md"`
2. Run locally: `npx markdownlint-cli2 --fix "**/*.md"`
3. Fix any remaining violations manually (check error messages)
4. Verify: `npx prettier --check "**/*.md" && npx markdownlint-cli2 "**/*.md"`
5. Commit and push

**Common violations:**

- **MD040**: Missing language in code blocks → Add language tag (e.g., ` ```bash `)
- **MD013**: Line too long → Break lines or disable for specific sections
- **MD029**: Ordered list numbering → Use sequential numbers or disable

### PowerShell Setup

For convenience, you can configure your PowerShell profile to automatically `cd` into this
repository root when opening a new terminal.

**Auto-cd & Disable Switch:**

If configured, the profile checks for `FOF_SKIP_CD`. To bypass auto-cd for a session:

```powershell
$env:FOF_SKIP_CD='1'
```

To disable permanently (affects new windows):

```powershell
setx FOF_SKIP_CD 1
```

To re-enable: `setx FOF_SKIP_CD 0` or remove the variable.

**Rollback (if needed):**

To revert the profile change, run this one-liner:

```powershell
$dir=Split-Path -LiteralPath $PROFILE; $leaf=Split-Path -Leaf $PROFILE; $latest=Get-ChildItem -LiteralPath $dir -Filter "$leaf.bak-*" | Sort-Object LastWriteTime -Descending | Select-Object -First 1; if($latest){Copy-Item -LiteralPath $latest.FullName -Destination $PROFILE -Force; "Restored from $($latest.Name)"} else {"No backup found."}
```

### CI optimization

CI workflows use path filters to run only when relevant files change:

- **Lint Markdown**: Runs on `.md`, `.prettierrc`, `.markdownlint-cli2.jsonc`, `package.json`
- **Python CI**: Runs on `**/*.py`, `**/requirements*.txt`, `**/pyproject.toml`
- **R CI**: Runs on `**/*.R`, `renv.lock`, `renv/**`
- **Smoke Tests**: Runs on `Fear-of-Falling/**` (except `.md` files)

Docs-only changes skip expensive test runs, saving CI minutes.

## Layout (high level)

```text
├─ Electronic-Frailty-Index/
│  ├─ docs/                   # EFI documentation and reports
│  ├─ env/                    # conda environment
│  ├─ figures/                # images and figures
│  ├─ BMI/                    # BMI features and scripts
│  ├─ CCI/                    # CCI features and scripts
│  ├─ HFRS/                   # HFRS features and scripts
│  └─ logistic_regression/    # logistic regression models and scripts
├─ src/efi/                   # Python CLI
├─ data/external/             # synthetic example data
├─ tests/                     # pytest tests
├─ .github/workflows/         # continuous integration workflows
└─ out/                       # outputs, ignored in VCS
```
