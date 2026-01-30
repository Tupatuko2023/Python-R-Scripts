if (!require("renv", quietly = TRUE)) install.packages("renv")
if (!file.exists("renv.lock")) {
  renv::init(bare = TRUE)
} else {
  renv::restore(prompt = FALSE)
}

pkg_list <- c("tidyverse", "readr", "dplyr", "stringr", "MASS", "sandwich", "lmtest", "broom", "here")
renv::install(pkg_list, prompt = FALSE)

# renv::snapshot(prompt = FALSE) # Uncomment to lock after install
