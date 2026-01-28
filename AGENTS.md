# AGENTS.md

## Working directory rule

- Always confirm your current working directory before running commands.
- Confirm working directory:
  - Shell (macOS/Linux/WSL/Git Bash): `pwd`
  - Windows PowerShell: `Get-Location`
  - R: `getwd()`
- Run tasks from the smallest relevant subproject root (for example
  `Fear-of-Falling/`), unless the task is explicitly repo-root scoped.
- If a script depends on relative paths, set the working directory to that script's subproject root and keep it stable.

## Command guardrails

- Use only repo-typical commands documented in README/AGENTS (examples: `python`, `py`, `Rscript`,
  `R -e "renv::restore()"`, `pytest`, `make`, `git status -sb`, `rg`).
- Ask for explicit approval before: `git push`, `git reset`, `git clean`,
  `rm -rf` / `del /s` / `rd /s /q` / `rmdir /s /q` / `Remove-Item -Recurse -Force`,
  `curl`, `wget`, `docker`, or any network access.

## Safety notes

- Windows-hosted sandboxing is more limited; prefer WSL or a container when you need stronger isolation. Docs: [codex-security]
- MCP servers (e.g., `MCP_DOCKER`) add power and attack surface; enable and use them intentionally. Docs: [codex-cli-features]

## Project summary

This is a mixed-language (R + Python) research analysis repository with multiple subprojects.
At repo root you have a Python CLI under `src/efi/` plus shared infra (tests, CI workflows, Makefile).
There are at least two major subprojects: `Electronic-Frailty-Index/` and `Fear-of-Falling/`.

Key principle for agents: treat this repo as a monorepo. Work in the smallest
relevant subproject folder and keep changes scoped.

## Directory map

Top level (high-level):

- `Electronic-Frailty-Index/` : EFI-related analysis project (docs, figures, scripts).
- `Fear-of-Falling/` : FOF-related analysis project (R-heavy).
- `src/efi/` : Python CLI implementation (EFI scoring/reporting).
- `tests/` : pytest tests.
- `data/external/` : example external data (synthetic example data is referenced in the README quick start).
- `.github/workflows/` : CI workflows (Python and R CI badges exist in README).
- `.git-crypt/` : encrypted-content workflow present. Do not modify encryption config unless explicitly asked.
- Repo-level configs: `Makefile`, `requirements.txt`, `pytest.ini`, `.editorconfig`, `.gitignore`.

## Setup (Python & R)

### Python (repo root)

Preferred: isolated virtual environment per clone.

- Create and activate venv:
  - macOS/Linux:
    - `python3 -m venv .venv`
    - `source .venv/bin/activate`
  - Windows PowerShell:
    - `py -m venv .venv`
    - `.\.venv\Scripts\Activate.ps1`
- Install dependencies:
  - `python -m pip install -U pip`
  - `python -m pip install -r requirements.txt`

### R (subprojects)

R work is typically per-subproject (for example `Fear-of-Falling/`).

- If the subproject contains `renv.lock` and `renv/`, restore with:
  - `renv::restore()`
- If there is no renv, install required packages per the subproject documentation or scripts.

## How to run

### Python CLI (repo root)

The README quick start runs the EFI CLI directly:

```bash
python src/efi/cli.py \
  --input data/external/synthetic_patients.csv \
  --out out/efi_scores.csv \
  --report-md out/report.md
```

Notes:

- Put generated outputs under `out/` (or the subproject's `outputs/` convention if it exists).
- Do not commit generated outputs unless explicitly requested.

### R scripts

- Prefer `Rscript path/to/script.R` for batch runs.
- If scripts depend on working directory, run them from the subproject root
  (example: `Fear-of-Falling/`) and keep relative paths stable.

## Skill workflow

For Fear-of-Falling refactors or bugfixes: run `fof-preflight` -> run K18 QC ->
run `fof-qc-summarizer` -> then proceed to modeling.

## TODO-järjestelmä (Agent-First Task Queue)

- MUST: varmista, että `tools/run-gates.sh` on ajettu (tai aja se nyt), jotta `SKILLS.md`, `config/agent_policy.md` ja `config/steering.md` ovat ladattu ja rajoitteet voimassa.
- MUST: valitse työ vain `tasks/01-ready/`-kansiosta; siirrä `02-in-progress` ennen työtä, lokita, siirrä `03-review` kun DoD täyttyy; ihminen siirtää `04-done`.
- MUST: noudata `config/steering.md` (max 5 files/run, safe mode, approvals required).
- SHOULD: yksityiskohdat ja DoD: katso `SKILLS.md` (single source of truth).

## Lint/Format

### Python

- If a formatter/linter is configured (common choices: ruff/black), run the repo's documented target first.
- Fallback (if no project tool is configured):
  - `python -m compileall -q .`
  - `python -m pytest -q`

### R

- Use the project's `lintr` config if present (commonly `.lintr` in the subproject root).
- Fallback checks:
  - `lintr::lint_dir("Fear-of-Falling")` (or the specific folder you touched)
  - `R CMD check` only if the folder is an R package (has DESCRIPTION)

## Testing & validation

### Minimal validation for any change

Before you finish a task, do all that apply:

- `git status -sb` is clean except intended edits.
- Re-run the entrypoint or script you changed.
- Re-run unit tests if Python code changed.

### Python tests (repo root)

- Run all tests:
  - `python -m pytest`
- Run a single test file:
  - `python -m pytest tests/test_name.py`

### R checks

- At minimum, rerun the modified script end-to-end.
- If the subproject has a known pipeline runner, prefer that (documented in that subproject).

### Definition of Done

- Relevant script/command runs successfully from the correct subproject root.
- No secrets, no private data, no generated artifacts committed unless explicitly requested.
- Changes are minimal, scoped, and consistent with existing style; docs updated if behavior changed.

## References

- [codex-security]: https://developers.openai.com/codex/security/
- [codex-cli-features]: https://developers.openai.com/codex/cli/features/
