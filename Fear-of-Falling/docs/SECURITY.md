Security notes (Fear-of-Falling)

Secrets and tokens

- Never print `~/.config/gh/hosts.yml` or `~/.config/gh/hosts.yaml`.
- Never echo or log token values (PAT, OAuth, or GitHub App tokens).
- Prefer fine-grained tokens with repo-only scope and minimal permissions.
- Do not store tokens in repo files, shell history, git config, or remote URLs.

Safe authentication (non-interactive)

- Prefer `GH_TOKEN` for GitHub CLI in the current session.
- Authenticate without browser:
  - `printf "%s" "$GH_TOKEN" | gh auth login --with-token`

Verify

- `gh auth status`

Incident response (suspected exposure)

- Revoke or rotate the token immediately.
- Scan repo and common config/history paths for token patterns.
- Confirm PR diffs do not contain secrets.
