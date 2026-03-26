# K50 FIG2 label and caption finalization

## Context

The contrast-focused Figure 2 is analytically complete, but one semantic detail
still risks reader confusion: the baseline contrast label can be misread as a
mixed-model main effect unless it is explicitly marked as a model-estimated
baseline contrast or adjusted level difference. The caption also needs one
final inferential sentence clarifying that Panel B carries the primary
inference.

## Inputs

- `R-scripts/K50/K50.V3_make-fig2-contrast-focused.R`
- `R-scripts/K50/outputs/FIG2_contrast_focused/`
- `manifest/manifest.csv`
- `prompts/2_10cafofv2.txt`
- `prompts/15_Locomotor_Capacity_Modeling_Copilot.txt`

## Outputs

- updated `R-scripts/K50/K50.V3_make-fig2-contrast-focused.R`
- rebuilt `R-scripts/K50/outputs/FIG2_contrast_focused/` artifacts with
  consistent terminology
- manifest kept free of duplicate rows for the unchanged FIG2 artifact filenames

## Definition of Done (DoD)

- Baseline contrast label is no longer methodologically ambiguous.
- The same label appears consistently in the figure, Panel B CSV, and technical
  note.
- The caption ends with: `The primary inference is based on the contrast estimates in Panel B.`
- No model, data, or contrast estimates change.
- The V3 script rebuild succeeds from the Fear-of-Falling root.

## Log

- 2026-03-26T00:00:00+02:00 Task created for the final semantic Figure 2 fix
  covering only label clarity, caption inference text, and duplicate-safe
  rebuild discipline.
- 2026-03-26T18:16:30+02:00 Reviewed `prompts/2_10cafofv2.txt` and `prompts/15_Locomotor_Capacity_Modeling_Copilot.txt`, confirmed the change scope is limited to label semantics, caption wording, and duplicate-safe rebuild handling.
- 2026-03-26T18:20:55+02:00 Updated `R-scripts/K50/K50.V3_make-fig2-contrast-focused.R` so the baseline contrast label reads `FOF - No FOF at baseline (model-estimated)` and propagated the same terminology into the generated caption, technical note, and results text.
- 2026-03-26T18:21:14+02:00 Rebuilt the FIG2 contrast-focused artifacts successfully with Debian PRoot R; no contrast estimates changed.
- 2026-03-26T18:21:40+02:00 Verified caption now ends with `The primary inference is based on the contrast estimates in Panel B.` and confirmed Panel B CSV retained the same estimates, confidence intervals, and p-values as before the label fix.
- 2026-03-26T18:22:05+02:00 Deduplicated FIG2 manifest rows by artifact path so unchanged filenames retain exactly one manifest entry each after rebuild.
