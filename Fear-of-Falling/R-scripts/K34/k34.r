#!/usr/bin/env Rscript
# K34 - DEPRECATED
#
# This script is intentionally disabled to prevent duplicate primary-model
# execution paths. Statistical specification remains in docs/ANALYSIS_PLAN.md,
# and the canonical executable implementation is:
#   R-scripts/K26/K26_LMM_MOD.V1_time-frailty-CompositeZ0-moderation.R
#
# Governance note:
# - No outputs are produced by this deprecated script.
# - Existing historical K34 artifacts in manifest are retained for audit trail.

stop(
  paste(
    "K34 is deprecated due to duplicate primary-model implementation scope.",
    "Use canonical script:",
    "R-scripts/K26/K26_LMM_MOD.V1_time-frailty-CompositeZ0-moderation.R",
    "Model specification remains authoritative in docs/ANALYSIS_PLAN.md.",
    sep = "\n"
  ),
  call. = FALSE
)
