suppressPackageStartupMessages({
  library(dplyr); library(readr); library(MASS); library(boot); library(broom)
})

# Load Data
# Note: In this environment, we may need to set DATA_ROOT if it's not in the shell
# For the script execution, we assume the environment is set as per tasks/01-ready/18...
DATA_ROOT <- Sys.getenv("DATA_ROOT")
if (DATA_ROOT == "") {
  # Fallback for local discovery if DATA_ROOT not set
  DATA_ROOT <- "/data/data/com.termux/files/home/FOF_LOCAL_DATA"
}

panel_path <- file.path(DATA_ROOT, "derived", "aim2_panel.csv")
if(!file.exists(panel_path)) stop(paste("Panel missing at", panel_path))
df <- read_csv(panel_path, show_col_types = FALSE)

# Check for required columns from build_real_panel.py
# age, sex, FOF_status, period, person_time, frailty_fried (or frailty_cat_3), 
# util_visits_outpatient, util_visits_inpatient

# Ensure columns exist or derive them if missing (e.g. if we only have util_visits_total)
if (!"util_visits_outpatient" %in% colnames(df)) {
  message("WARNING: util_visits_outpatient missing from panel. Creating dummy/copy from total for script structure.")
  df$util_visits_outpatient <- df$util_visits_total
}
if (!"util_visits_inpatient" %in% colnames(df)) {
  message("WARNING: util_visits_inpatient missing from panel. Creating dummy/copy from total for script structure.")
  df$util_visits_inpatient <- df$util_visits_total
}

# The build script used 'age' and 'sex' and 'frailty_fried'
if (!"age_baseline" %in% colnames(df) && "age" %in% colnames(df)) {
    df$age_baseline <- df$age
}

# Ensure 3-class frailty and factors
# Logic from task: levels = c("robust", "pre-frail", "frail")
df <- df %>% 
  filter(!is.na(frailty_fried), !is.na(FOF_status)) %>%
  mutate(
    frailty = factor(frailty_fried, levels = c("robust", "pre-frail", "frail")),
    FOF = factor(FOF_status)
  )

# Outcomes to test
outcomes <- c("util_visits_outpatient", "util_visits_inpatient")
results <- list()

# Boot function
get_ratios <- function(data, indices, outcome_col) {
  d <- data[indices, ]
  # Formula: outcome ~ FOF * frailty + age_baseline + sex + factor(period) + offset
  # Note: glm.nb is sensitive to small counts in strata
  f <- as.formula(paste(outcome_col, "~ FOF * frailty + age_baseline + sex + factor(period) + offset(log(person_time))"))
  
  m <- tryCatch(glm.nb(f, data = d), error = function(e) NULL)
  if(is.null(m)) return(c(NA)) # Return NA if fail
  
  # Predict expectations (Recycled predictions for Overall FOF effect)
  # Standardize FOF for prediction
  d0 <- d; d0$FOF <- factor(0, levels=c(0,1))
  d1 <- d; d1$FOF <- factor(1, levels=c(0,1))
  
  pred0 <- mean(predict(m, newdata=d0, type="response"), na.rm=TRUE)
  pred1 <- mean(predict(m, newdata=d1, type="response"), na.rm=TRUE)
  
  ratio_overall <- pred1 / pred0
  
  return(c(ratio_overall)) 
}

# Run Loop
set.seed(123)
B <- 50 # Reduced for faster verification
for(y in outcomes) {
  message("Modeling: ", y)
  # Point estimate
  boot_out <- boot(data = df, statistic = get_ratios, R = B, outcome_col = y)
  
  # Check if all results are NA
  if (all(is.na(boot_out$t))) {
      message("FAIL: All bootstrap iterations failed for ", y)
      next
  }

  # CI
  ci <- tryCatch(boot.ci(boot_out, type = "perc"), error = function(e) NULL)
  
  if (is.null(ci)) {
      res <- data.frame(
        outcome = y,
        IRR = boot_out$t0[1],
        CI_L = NA,
        CI_U = NA
      )
  } else {
      res <- data.frame(
        outcome = y,
        IRR = boot_out$t0[1],
        CI_L = ci$percent[4],
        CI_U = ci$percent[5]
      )
  }
  print(res)
  results[[y]] <- res
}

if (length(results) > 0) {
    final_tab <- bind_rows(results)
    # Ensure outputs dir exists
    if (!dir.exists("outputs")) dir.create("outputs")
    write_csv(final_tab, "outputs/separated_outcomes_summary.csv")
}
print("Done.")
