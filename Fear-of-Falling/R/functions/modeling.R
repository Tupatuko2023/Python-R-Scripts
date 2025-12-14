
# Primary: ANCOVA follow-up
fit_primary_ancova <- function(df) {
  stats::lm(Composite_Z2 ~ FOF_status_f + Composite_Z0 + Age + Sex_f + BMI, data = df)
}

# Secondary: delta-malli baseline-kontrollilla
fit_secondary_delta <- function(df) {
  stats::lm(Delta_Composite_Z ~ FOF_status_f + Composite_Z0 + Age + Sex_f + BMI, data = df)
}


# Raportointi (95% CI)
tidy_lm_ci <- function(mod) {
  broom::tidy(mod, conf.int = TRUE, conf.level = 0.95)
}

# Raportointi (p-arvot) 
tidy_lm_p <- function(mod) {
  broom::tidy(mod) %>%
    dplyr::select(term, p.value)
}