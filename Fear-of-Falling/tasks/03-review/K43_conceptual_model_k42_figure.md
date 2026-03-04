# K43 Conceptual Model Figure for K42

## Context

This K43 is an analysis-repo figure production task in `Fear-of-Falling`.
It is not a dissertation-repo writing task.

K42 established a deterministic head-to-head framework (capacity vs FI) with common samples and no high-collinearity flag. K43 packages that interpretation as a reusable conceptual framework figure.

Task-gate status: review (`tasks/03-review/`).

## Objective

Generate publication-ready vector figures (SVG + PDF) and a concise caption for the K42 conceptual framework, with no patient-level data.

## Inputs

- Mermaid source structure (conceptual model):
  `Deficit accumulation (FI) -> baseline risk context -> 12-month performance trajectory`,
  `Locomotor capacity -> 12-month performance trajectory`,
  and dashed bidirectional relation `FI <-> capacity` labeled `related (r = -0.51)`.
- Repo references: `manifest/manifest.csv`.

## Outputs (Repo, Aggregate-Only)

- `docs/figures/conceptual_model_k42.svg`
- `docs/figures/conceptual_model_k42.pdf`
- `docs/figures/conceptual_model_k42_caption.txt`

## Governance

- No DATA_ROOT reads/writes required.
- No patient-level exports.
- Only figure files + caption + manifest rows are produced.

## Reproduction Commands

`[TERMUX / PROOT]`

```sh
cd Python-R-Scripts/Fear-of-Falling
# if mmdc missing, install mermaid-cli in project scope
npm i -D @mermaid-js/mermaid-cli

# render from deterministic Mermaid source
npx mmdc -i /tmp/conceptual_model_k42.mmd -o docs/figures/conceptual_model_k42.svg
npx mmdc -i /tmp/conceptual_model_k42.mmd -o docs/figures/conceptual_model_k42.pdf
```

## Acceptance Criteria

- SVG and PDF both render successfully and preserve arrow semantics and the dashed `related (r = -0.51)` edge.
- Caption file exists and matches the agreed non-causal interpretation language.
- Outputs are vector format (SVG, PDF), no PNG fallback.
- `run-gates --mode analysis --project Fear-of-Falling` passes.
- Leak-check passes (no patient-level outputs created).

## Definition of Done (Implementation Stage)

- Figure files and caption exist at documented paths.
- Manifest contains rows for SVG/PDF/caption artifacts.
- Task moved to `tasks/03-review/` after PASS evidence.

## Log

- 2026-03-02 21:33:04 created K43 backlog card for K42 conceptual framework figure generation.
- 2026-03-03 07:08 rendered figure artifacts from deterministic Mermaid source in Debian proot with Mermaid CLI:
  - `docs/figures/conceptual_model_k42.svg`
  - `docs/figures/conceptual_model_k42.pdf`
  - `docs/figures/conceptual_model_k42_caption.txt`
- 2026-03-03 07:08 appended manifest rows for K43 artifacts:
  - `conceptual_model_k42_svg`
  - `conceptual_model_k42_pdf`
  - `conceptual_model_k42_caption`
- 2026-03-03 07:09 validation:
  - `file docs/figures/conceptual_model_k42.svg docs/figures/conceptual_model_k42.pdf` confirms vector outputs (SVG + 1-page PDF)
  - `bash ../tools/run-gates.sh --mode analysis --project Fear-of-Falling` exit `0`
  - `rg` leak-check patterns on K43 outputs returned no hits
- 2026-03-03 07:10 moved task card to `tasks/03-review/` for human approval.

## Blockers

- None at backlog stage.

## Links

- [K42_capacity_vs_fi_head_to_head.md](/data/data/com.termux/files/home/Python-R-Scripts/Fear-of-Falling/tasks/04-done/K42_capacity_vs_fi_head_to_head.md)
