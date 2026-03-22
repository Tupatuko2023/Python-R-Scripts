#!/usr/bin/env Rscript

stop(
  paste(
    "Deprecated Figure 2 entrypoint: R-scripts/K50/make_fig2_trajectory.R no longer reconstructs",
    "predictions from *_model_terms_primary.csv.",
    "Run R-scripts/K50/K50.V2_make-fig2-trajectory-exact.R after generating",
    "the saved primary LONG model object with R-scripts/K50/K50.r.",
    sep = " "
  ),
  call. = FALSE
)
