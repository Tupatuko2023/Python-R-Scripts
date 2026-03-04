# Figure Package Checklist

## Scope

Submission-ready figure package for conceptual and trajectory figures tied to K43/K44 outputs.

## Included Artifacts

- Conceptual framework (vector):
  - `docs/figures/conceptual_model_k42.svg`
  - `docs/figures/conceptual_model_k42.pdf`
  - `docs/figures/conceptual_model_k42_caption.txt`
- Trajectory gradients (model-based):
  - `R-scripts/K44/outputs/k44_both_gradients.png`
  - `R-scripts/K44/outputs/k44_extreme_profiles.png`
  - `R-scripts/K44/outputs/k44_figure_caption.txt`

## Technical Checks

- `conceptual_model_k42.svg` opens correctly and text is readable.
- `conceptual_model_k42.pdf` opens correctly and remains vector format.
- `k44_both_gradients.png` and `k44_extreme_profiles.png` are legible at manuscript target width.
- Captions explicitly state:
  - model-based predictions from fixed effects;
  - no model refit for visualization;
  - descriptive/non-causal interpretation.

## Consistency Checks for Manuscript Text

- Figure references in manuscript use consistent naming (`Figure 1`, `Figure 2`, `Supplementary Figure S1`).
- Results text for trajectory gradients aligns with:
  - `time×capacity` estimate/p-value;
  - `time×FI` estimate/p-value;
  - `time×FOF` adjusted result.
- Correlation statement consistent across sections (`r≈-0.51`).

## Journal Submission Packaging

- Prepare high-resolution files per target journal instructions (if PNG minimum DPI required, verify current exports).
- Keep conceptual figure as vector (`.svg`/`.pdf`) whenever accepted.
- If journal requires TIFF/EPS conversion:
  - convert from source vector where possible;
  - do not rasterize conceptual figure unnecessarily.

## Governance and Reproducibility Check

- No patient-level data appears in figure files or captions.
- Figure files are derived from aggregate/model coefficients only.
- Supporting logs available:
  - `R-scripts/K44/outputs/k44_decision_log.txt`
  - `R-scripts/K44/outputs/k44_external_input_receipt.txt`

