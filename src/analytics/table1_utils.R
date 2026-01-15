#' Table 1 Generator with SDC (Statistical Disclosure Control)
#'
#' Creates a descriptive table (Mean/SD for numeric, n/% for categorical)
#' and automatically suppresses small cell counts (n < 5).
#'
#' @param data A dataframe or tibble.
#' @param vars Character vector of column names to include.
#' @param strata Character name of the grouping column (optional).
#' @return A tibble with formatted statistics.
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(tidyr))
suppressPackageStartupMessages(library(purrr))

# Ensure dependency is loaded
if (!exists("suppress_small_cells")) {
  # Attempt to locate the utility relative to execution context
  paths <- c("src/analytics/privacy_utils.R", "../src/analytics/privacy_utils.R", "../../src/analytics/privacy_utils.R", "privacy_utils.R")
  loaded <- FALSE
  for (p in paths) {
    if (file.exists(p)) {
      source(p)
      loaded <- TRUE
      break
    }
  }
  if (!loaded) warning("Could not auto-load privacy_utils.R. Ensure it is sourced.")
}

create_table1 <- function(data, vars, strata = NULL) {
  
  analyze_var <- function(d, v) {
    vals <- d[[v]]
    
    if (is.numeric(vals)) {
      # Numeric: Mean (SD)
      # Note: We usually don't suppress Means unless N is small, but let's check N.
      n_total <- sum(!is.na(vals))
      if (n_total < 5 && n_total > 0) {
        return(tibble(Variable = v, Level = "", Stat = "n<5"))
      }
      m <- mean(vals, na.rm = TRUE)
      s <- sd(vals, na.rm = TRUE)
      stat_str <- sprintf("%.1f (%.1f)", m, s)
      return(tibble(Variable = v, Level = "", Stat = stat_str))
      
    } else {
      # Categorical: n (%)
      # Calculate counts
      counts <- d %>%
        count(.data[[v]]) %>%
        mutate(
          total = sum(n),
          pct = (n / total) * 100
        )
      
      # PRIVACY GATE: Apply suppression logic
      # We use our specific logic here: if n < 5, hide both n and %
      counts <- counts %>%
        mutate(
          n_safe = ifelse(n < 5 & n > 0, "n<5", as.character(n)),
          pct_safe = ifelse(n < 5 & n > 0, "-", sprintf("%.1f%%", pct)),
          Stat = ifelse(n_safe == "n<5", "n<5", paste0(n_safe, " (", pct_safe, ")"))
        ) %>%
        select(Level = all_of(v), Stat) %>%
        mutate(Variable = v) %>%
        select(Variable, Level, Stat)
        
      return(counts)
    }
  }

  if (is.null(strata)) {
    # Overall analysis
    map_dfr(vars, ~ analyze_var(data, .x))
  } else {
    # Stratified analysis
    # Split data by strata, apply analysis, then join (simplified for MVP)
    # Ideally use pivot_wider, but loop is safer for complex string formatting
    groups <- unique(na.omit(data[[strata]]))
    results <- list()
    
    for (g in groups) {
      sub_data <- data %>% filter(.data[[strata]] == g)
      res <- map_dfr(vars, ~ analyze_var(sub_data, .x))
      colnames(res)[3] <- as.character(g) # Rename Stat col to Group name
      results[[as.character(g)]] <- res
    }
    
    # Merge lists by Variable and Level
    final_table <- Reduce(function(x, y) full_join(x, y, by = c("Variable", "Level")), results)
    return(final_table)
  }
}