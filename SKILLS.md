# SKILLS.md — Agent Operating Protocol (Single Source of Truth)

## Rule of precedence (MUST)

- SKILLS.md on ylin totuus kaikissa agenttitoiminnoissa.
- Ennen mitään `gh`-komentoja, PR-työtä tai mergeä: lue tämä tiedosto ensin ja noudata kirjaimellisesti.
- Jos tämä tiedosto on ristiriidassa muiden ohjeiden kanssa: SKILLS.md voittaa.

---

## TODO System (Agent-First Task Queue) — MUST

Pakollinen työjono ja toimintalogiikka:

- **Selection rule:** valitse tehtävä vain `tasks/01-ready/`-kansiosta. Jos se on tyhjä: STOP ja pyydä ihmiseltä tehtävää.
- **Transitions:** siirrä tehtävä `01-ready → 02-in-progress → 03-review`. Ihminen siirtää `04-done`.
- **Log:** lisää tehtävätiedostoon aikaleimallinen lokimerkintä (ISO-8601; local time ok) jokaisesta merkittävästä toimesta.
- **DoD gate (analyysirepo):** tee vähintään yksi smoke-run (Rscript/python) aliprojektin ohjeiden mukaan. Aja QC-runner, jos repo tarjoaa sen. Jos `renv/` on käytössä, varmista että `renv::restore()` on mahdollinen ja kirjaa tarvittaessa `sessionInfo()`/`renv::diagnostics()`.
- **Blocker:** jos olet epävarma, luo blocker-merkintä tehtävään tai pyydä ihmiseltä täsmennys ennen jatkoa.

**Steering integration (MUST):** lue `config/steering.md` ennen työn aloitusta ja noudata siinä määriteltyjä rajoitteita, hyväksyntäehtoja ja kielipolitiikkaa.

---

## GitHub Auth (Non-Interactive) — Termux-safe

Supported auth models (automatic, no prompts):

1. Preferred: GitHub CLI is already authenticated on this device.
   - Check: `gh auth status`
   - If not authenticated: STOP and report that device auth is required.

1. Alternative: token via environment variable (non-interactive).
   - Supported env vars (precedence): `GH_TOKEN`, then `GITHUB_TOKEN`
   - Tokens must be provided by the environment (Termux export, CI secrets).
   - Never prompt for tokens; do not assume a TTY exists.

### Important clarification (env empty is OK)

Empty `GH_TOKEN` / `GITHUB_TOKEN` does not mean "no token". The preferred default is
persistent gh login stored locally in Termux under `~/.config/gh/hosts.yml` (or
`hosts.yaml`). Treat gh itself as the source of truth:

```bash
gh auth status -h github.com
gh api user -q .login
```

### Auth modes (priority order)

1. Persistent login: `~/.config/gh/hosts.yml|hosts.yaml`
1. Env override (headless): `GH_TOKEN` (preferred) or `GITHUB_TOKEN`
1. Secrets-file fallback (headless, no persistent env export):
   - Store token locally: `~/.secrets/github_fine_grained_pat` (chmod 600, never commit)
   - Use per-command injection:

```bash
GH_TOKEN="$(cat ~/.secrets/github_fine_grained_pat)" gh api user -q .login
```

### Agent decision rule

- If `gh api user -q .login` succeeds: proceed (even if env vars are empty).
- If it fails AND no env/secrets-file override is available: STOP and request operator re-auth.

### Required reporting

- Include one line in every PR report: `Auth mode: persistent-login | env-token | secrets-file`.

### Authoritative MCP Test Protocol

- Operational note: Codex MCP config should use `bearer_token_env_var = "GH_TOKEN"` (not `GITHUB_PAT_TOKEN`).

Path A (preferred):

- Use persistent gh login in `~/.config/gh/hosts.yml|hosts.yaml`.
- Env tokens may be empty; this is OK.
- Works check: `gh api user -q .login`.
- Do not run curl/SSE by default.

Path B (manual validation only):

- Use per-command token injection from a secrets file (no export, no prompts).
- Example:

```bash
ENDPOINT="https://api.githubcopilot.com/mcp/"
GH_TOKEN="$(cat ~/.secrets/github_fine_grained_pat)" \
curl -sS -D /tmp/mcp_headers_auth.txt -o /dev/null \
  -H "Accept: text/event-stream" \
  -H "Authorization: Bearer ${GH_TOKEN}" \
  "$ENDPOINT"
```

Do NOT:

- Use `read -s` or any prompt-based token entry in automation.
- Persist token exports in shell profiles.
- Write tokens into repo files.

Sanity checks (must be non-interactive):

```bash
gh --version
gh auth status || true
gh repo view --json nameWithOwner -q .nameWithOwner
```

Prohibited (breaks automation):

- Do not use interactive auth (e.g., `gh auth login` prompts).
- Do not read tokens from stdin/TTY.
- Do not use `read -s` or any prompt-based token entry in automation; if env is missing, STOP and request the operator to set it in the shell environment.

---

## PR Protocol / Definition of Done (Mechanical Checklist)

Branch naming:

- Use a deterministic name: `docs/<topic>` or `chore/<topic>`.

Required steps (report each as Done/Not done/Stop reason):

1. Sync & create branch

```bash
git status --porcelain
git switch main
git pull --ff-only
git switch -c docs/<topic>
```

1. Make changes (minimal diffs)

- Avoid reformatting unrelated content.
- Never touch `data/raw/**` or `data/processed/**`.
- Never edit submodule contents under `analysis/modules/**`.

1. Local checks (run what is feasible)

```bash
git submodule update --init --recursive
```

Optional (only if environment supports it):

```bash
proot-distro login debian --termux-home -- bash -lc "cd <ABS_REPO_ROOT> && bash analysis/pipelines/run_all.sh"
proot-distro login debian --termux-home -- bash -lc "cd <ABS_REPO_ROOT> && quarto render"
```

1. Commit (one logical change per commit)

```bash
git add -A
git commit -m "docs: enforce non-interactive gh auth protocol"
```

1. Push and open PR (non-interactive)

```bash
git push -u origin HEAD
gh pr create --fill
```

1. Enable auto-merge only after checks pass

```bash
gh pr merge --auto --squash
```

1. Post-merge cleanup (only after merge is confirmed)

```bash
gh pr view --json merged -q .merged
git switch main
git pull --ff-only
git branch -d docs/<topic> || true
git push origin --delete docs/<topic> || true
```

Required report format:

```text
Auth model used: (gh-authenticated device) OR (GH_TOKEN/GITHUB_TOKEN env)
Checklist:
Sync & branch: Done/Not done/Stop reason
Checks: Done/Not done/Stop reason
PR created: Done/Not done/Stop reason
Auto-merge: Done/Not done/Stop reason
Cleanup: Done/Not done/Stop reason
```

---

## Skills directory index

The skills location has moved to the `skills/` directory:

- Index: `skills/README.md`
- GitHub PAT skill: `skills/github-pat/skill.md`
