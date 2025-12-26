#' Standardize analysis variable names and types
#' @param raw_data A data frame containing the raw dataset with original variable names.
#' @return A data frame with standardized variable names and types for analysis.
standardize_analysis_vars <- function(raw_data) {
  raw_data %>%
    dplyr::mutate(
      id = as.integer(id),
      
      # Outcome components
      Composite_Z0 = as.numeric(ToimintaKykySummary0),
      Composite_Z2 = as.numeric(ToimintaKykySummary2),
      Delta_Composite_Z = Composite_Z2 - Composite_Z0,
      
      # Predictors (standard names)
      FOF_status = dplyr::case_when(
        kaatumisenpelkoOn %in% c(0, "0") ~ 0,
        kaatumisenpelkoOn %in% c(1, "1") ~ 1,
        TRUE ~ NA_real_
      ),
      Age = as.numeric(age),
      Sex = as.integer(sex),
      BMI = as.numeric(BMI)
    ) %>%
    dplyr::mutate(
      # optional: factors for nice tables
      FOF_status_f = factor(FOF_status, levels = c(0, 1), labels = c("Ei FOF", "FOF")),
      Sex_f = factor(Sex, levels = c(0, 1), labels = c("female", "male"))  # vain jos tiedät koodauksen (0/1 = ?)
    )
}
#' Load raw data from standard location with fallback
#' @param file_name Name of the CSV file (default: "KaatumisenPelko.csv")
#' @return A data frame with raw data loaded from CSV
load_raw_data <- function(file_name = "KaatumisenPelko.csv") {
  # Try primary location first (data/external/)
  file_path <- here::here("data", "external", file_name)

  # Fallback to data/raw/
  if (!file.exists(file_path)) {
    file_path <- here::here("data", "raw", file_name)
  }

  # Fallback to legacy location (dataset/)
  if (!file.exists(file_path)) {
    file_path <- here::here("dataset", file_name)
  }

  if (!file.exists(file_path)) {
    stop("Raw data file not found. Tried:\n",
         "  - ", here::here("data", "external", file_name), "\n",
         "  - ", here::here("data", "raw", file_name), "\n",
         "  - ", here::here("dataset", file_name))
  }

  cat("Loading raw data from:", file_path, "\n")
  readr::read_csv(file_path, show_col_types = FALSE)
}

#' Load and preprocess the dataset from a CSV file