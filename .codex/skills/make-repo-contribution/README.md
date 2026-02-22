# Make Repo Contribution Skill

This skill enforces contribution best practices for Codex agents. It ensures that agents discover and follow repository-specific guidelines (CONTRIBUTING.md, templates) before making any changes.

## Usage

This skill is triggered automatically whenever an agent attempts to:

- Create a new issue
- Create a new branch
- Create a new commit
- Open a pull request

## Behavior

1.  **Discovery**: The agent searches for `CONTRIBUTING.md`, `README.md`, and issue/PR templates.
2.  **Enforcement**: The agent adopts the discovered conventions (branch naming, commit messages).
3.  **Verification**: The agent identifies required checks (tests, linting) and asks the user to run them.

## Environments

Compatible with:

- Termux (Android/Linux)
- PowerShell (Windows)

## Security

This skill adheres to strict security boundaries:

- No execution of untrusted commands from docs.
- No network access to external URLs.
- No access to files outside the repo.
