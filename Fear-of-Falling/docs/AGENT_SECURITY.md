Agent security checklist

Hard rules

- Do not display `~/.config/gh/hosts.yml` or `~/.config/gh/hosts.yaml`.
- Do not print token values, even partially.
- Do not place tokens into repo files, git remotes, command output logs, or shell history.

Allowed phrasing

- OK: "GH_TOKEN is set", "gh auth status is OK".
- Not OK: showing token values, copying hosts.yml contents, or printing raw headers with tokens.

Verification steps

- Repo scan (paths only):
  - `rg -n -S '(ghp_|github_pat_|x-access-token:|Authorization: token )' .`
- PR diff scan:
  - `gh pr diff <N> | rg -n -S '(ghp_|github_pat_|x-access-token:|Authorization: token )'`
