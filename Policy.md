# Policy.md: Python-R-Scripts Standards

## 1. Coding Standards

- **Python:** Use Snake Case for functions. Follow PEP8. Type hinting required.
- **R:** Use Tidyverse style. Roxygen2 comments required for all functions.
- **Modularity:** No hardcoded paths. Use relative paths or config files.

## 2. Agent Protocols

- **Architect:** Must verify that new scripts do not duplicate existing functionality.
- **Integrator:** Must create a corresponding test file in 'tests/' for every new script.

## 3. Safety Gates (Confidence Score)

- **Score < 0.8:** STOP if dependencies are unclear or if code overwrites existing utils.
- **Gate 3:** All unit tests must pass before marking a task as DONE.
