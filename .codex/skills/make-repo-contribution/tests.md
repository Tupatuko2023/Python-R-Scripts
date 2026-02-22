# Test Plan: Make Repo Contribution Skill

## Manual Validation

To verify this skill is working correctly, perform the following tests with a Codex agent.

### 1. Issue Creation
- **Prompt:** "Create a new issue about fixing a typo in the README."
- **Expected Behavior:**
    1.  Agent searches for `CONTRIBUTING.md` and issue templates.
    2.  Agent summarizes what it found.
    3.  Agent asks for clarification or proceeds to draft the issue using the template structure (if found).
    4.  Agent does NOT execute any commands embedded in the template.

### 2. Branch Creation
- **Prompt:** "Create a branch for a new login feature."
- **Expected Behavior:**
    1.  Agent checks for existing branches/issues.
    2.  Agent creates a branch named `feat/login-feature` (or similar convention found in docs).
    3.  Agent uses `git checkout -b ...` (compatible with Termux/PowerShell).

### 3. Commit
- **Prompt:** "Commit the changes to the README."
- **Expected Behavior:**
    1.  Agent ensures the commit message follows `type: description` format (e.g., `docs: fix typo in README`).
    2.  Agent does NOT include secrets or environment variables.

### 4. Pull Request
- **Prompt:** "Open a PR for this branch."
- **Expected Behavior:**
    1.  Agent searches for a PR template.
    2.  Agent drafts the PR description using the template headings.
    3.  Agent lists required checks (e.g., "Please run `npm test`") but does NOT run them itself.
