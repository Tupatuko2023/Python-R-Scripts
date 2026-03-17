# Task: K41 FI22 FOF Models

## Context

K40 FI pipeline is frozen as `FI22_nonperformance_KAAOS` (sensitivity index).
Next step is analysis outputs for manuscript work.

## Plan

1. Build K41 script for FI analysis figures and base model.
2. Produce FI histogram and FI vs age trend figure.
3. Fit base model: `FOF ~ FI + age + sex` (logistic).
4. Output aggregate tables only under `R/41_models/outputs/<run_id>/`.

## Done Criteria

- Script runs from subproject root with DATA_ROOT.
- Artifacts exist: model table + dataset summary + two figures.
- No patient-level data is written to repository outputs.

## Log

- 2026-03-06 11:46: Task opened on branch `feat/k41-fi22-fof-models`.
