# Handover — markdownlint CI (chore/paper02-assemble-qc)

## Summary (Done)
- PR created: #70 (base: main, head: chore/paper02-assemble-qc).
- CI lint workflow updated to lint only changed Markdown files and ignore noisy paths.
- Local validation: `npx prettier --check` + `npx markdownlint-cli2` on changed MD passed; `python -m unittest discover -s Quantify-FOF-Utilization-Costs/tests` passed; `python Quantify-FOF-Utilization-Costs/scripts/30_qc_summary.py --use-sample` passed.

## Current CI Status
- PR_NUM: 70
- HEAD_OID: b4fb14798c1fa31099b83a6faee3f7a065bec539
- RUN_ID (latest for HEAD): 21470587495 (Lint Markdown) — **failed**

### Failure summary (from `gh run view --log-failed`)
- Job: `Lint Markdown` → step `Collect Markdown files`
- Error: `fatal: bad revision ''`
- Context: workflow_dispatch event has empty `github.event.before`; PR/base ref not set for workflow_dispatch.

## What changed (files & why)
- `.github/workflows/markdownlint.yml`: added changed-file collection and filtered lint/prettier to those files; filtered out `tasks/`, `docs/guides/*.docx.md`, and `config/` to avoid churn from non-PR docs; added `fetch-depth: 0` for diffing; added `--diff-filter=ACMRT` to ignore deletions.
- `WORKFLOW.md`: autoformatted by Prettier (indentation only).

## Remaining work
- Fix workflow_dispatch handling in `.github/workflows/markdownlint.yml` so diff uses a valid base when `github.event.before` is empty.
  - Suggested: if `github.event.before` is empty, use `git diff --name-only -z --diff-filter=ACMRT HEAD~1 HEAD -- "*.md"` or use `origin/${{ github.ref_name }}`.
- Re-run Lint Markdown workflow and confirm green.

## Next steps (commands)
```bash
# refresh PR / head
PR_NUM="$(gh pr list --state open --head chore/paper02-assemble-qc --json number -q '.[0].number')"
HEAD_OID="$(gh pr view "$PR_NUM" --json headRefOid -q .headRefOid)"

gh run list --limit 30 --json databaseId,headSha,headBranch,name,status,conclusion,createdAt \
  -q '.[] | select(.headSha=="'"$HEAD_OID"'") | "\(.databaseId) \(.name) \(.status) \(.conclusion // "null") \(.headBranch) \(.createdAt)"'

RUN_ID="$(gh run list --limit 30 --json databaseId,headSha,status,conclusion -q '[.[] | select(.headSha=="'"$HEAD_OID"'")][0].databaseId')"
gh run view "$RUN_ID" --log-failed

# local lint on changed markdown
npm ci
xargs -0 npx prettier --check < /data/data/com.termux/files/usr/tmp/md_files.txt
xargs -0 npx markdownlint-cli2 < /data/data/com.termux/files/usr/tmp/md_files.txt
```

## Notes
- Do not commit outputs under `Quantify-FOF-Utilization-Costs/outputs/`.
- If you change the workflow, commit only those changes and re-run Lint Markdown.
