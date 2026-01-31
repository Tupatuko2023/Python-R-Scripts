options(repos = c(CRAN = "https://cloud.r-project.org"))
options(renv.config.sysreqs.enabled = FALSE)
Sys.setenv(RENV_CONFIG_SYSREQS_ENABLED = "false")

if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv")

if (!file.exists("renv.lock")) {
  renv::init(bare = TRUE)
} else {
  renv::restore(prompt = FALSE)
}

# Disable sysreqs in settings too
if (file.exists("renv.lock")) {
  renv::settings$sysreqs.enabled(FALSE)
}

# Use utils::install.packages to bypass renv's sysreqs checks on Android/Termux
pkg_list <- c("tidyverse", "readr", "dplyr", "stringr", "MASS", "sandwich", "lmtest", "broom", "here")
utils::install.packages(pkg_list)
renv::snapshot(prompt = FALSE)
