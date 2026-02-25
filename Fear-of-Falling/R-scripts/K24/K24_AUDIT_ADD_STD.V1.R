#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)

get_arg <- function(name, default) {
  key <- paste0("--", name, "=")
  hit <- args[startsWith(args, key)]
  if (length(hit) == 0) return(default)
  sub(key, "", hit[[1]], fixed = TRUE)
}

input_path <- get_arg("input", "R-scripts/K24/outputs/K24_TABLE2A/table2A_audit_canonical_v2.csv")
output_path <- get_arg("output", "R-scripts/K24/outputs/K24_TABLE2A/table2A_audit_canonical_v3_with_std.csv")

if (!file.exists(input_path)) {
  stop(sprintf("Input file not found: %s", input_path))
}

df <- read.csv(input_path, stringsAsFactors = FALSE, check.names = FALSE)

required <- c(
  "N_without", "N_with", "Without_FOF_Baseline", "With_FOF_Baseline",
  "FOF_Beta_CI", "Frailty_Score_Beta_CI", "Frailty_Contrasts"
)
missing_cols <- setdiff(required, names(df))
if (length(missing_cols) > 0) {
  stop(sprintf("Missing required columns: %s", paste(missing_cols, collapse = ", ")))
}

extract_sd <- function(x) {
  # Expected shape: "N=72, 1.31 (0.49)"
  m <- regexec("\\(([+-]?[0-9]*\\.?[0-9]+)\\)", x)
  reg <- regmatches(x, m)
  out <- rep(NA_real_, length(x))
  for (i in seq_along(reg)) {
    if (length(reg[[i]]) >= 2) out[i] <- as.numeric(reg[[i]][2])
  }
  out
}

extract_beta_ci <- function(x) {
  # Supports: "-0.028 [-0.119, 0.063]", "-0.028 (-0.119, 0.063)", "-0.028 (-0.119 to 0.063)"
  out <- data.frame(
    beta = rep(NA_real_, length(x)),
    lcl = rep(NA_real_, length(x)),
    ucl = rep(NA_real_, length(x))
  )
  if (length(x) == 0) return(out)
  x <- trimws(x)
  for (i in seq_along(x)) {
    xi <- x[[i]]
    if (is.na(xi) || xi == "" || xi == "NA") next

    # Parse beta as first numeric token
    beta_m <- regexec("^\\s*([+-]?[0-9]*\\.?[0-9]+)", xi)
    beta_r <- regmatches(xi, beta_m)[[1]]
    if (length(beta_r) >= 2) out$beta[i] <- as.numeric(beta_r[2])

    # Parse CI bounds
    ci_m <- regexec("([+-]?[0-9]*\\.?[0-9]+)\\s*(?:,|to)\\s*([+-]?[0-9]*\\.?[0-9]+)", xi)
    ci_r <- regmatches(xi, ci_m)[[1]]
    if (length(ci_r) >= 3) {
      out$lcl[i] <- as.numeric(ci_r[2])
      out$ucl[i] <- as.numeric(ci_r[3])
    }
  }
  out
}

format_beta_ci <- function(beta, lcl, ucl, digits = 3) {
  out <- rep(NA_character_, length(beta))
  ok <- is.finite(beta) & is.finite(lcl) & is.finite(ucl)
  out[ok] <- sprintf(
    paste0("%.", digits, "f [%.", digits, "f, %.", digits, "f]"),
    beta[ok], lcl[ok], ucl[ok]
  )
  out
}

extract_frail_beta <- function(x) {
  # Expected segment: "frailty_cat_3frail: b=-0.204, p=0.004"
  out <- rep(NA_real_, length(x))
  for (i in seq_along(x)) {
    xi <- x[[i]]
    if (is.na(xi) || xi == "" || xi == "NA") next
    m <- regexec("frailty_cat_3frail:\\s*b=([+-]?[0-9]*\\.?[0-9]+)", xi)
    r <- regmatches(xi, m)[[1]]
    if (length(r) >= 2) out[i] <- as.numeric(r[2])
  }
  out
}

n_without <- suppressWarnings(as.numeric(df$N_without))
n_with <- suppressWarnings(as.numeric(df$N_with))
sd_without <- extract_sd(df$Without_FOF_Baseline)
sd_with <- extract_sd(df$With_FOF_Baseline)

pooled_denom <- (n_without + n_with - 2)
num <- ((n_without - 1) * sd_without^2) + ((n_with - 1) * sd_with^2)
base_sd_pooled <- sqrt(num / pooled_denom)
base_sd_pooled[!is.finite(base_sd_pooled)] <- NA_real_

fof <- extract_beta_ci(df$FOF_Beta_CI)
fof_std_beta <- fof$beta / base_sd_pooled
fof_std_lcl <- fof$lcl / base_sd_pooled
fof_std_ucl <- fof$ucl / base_sd_pooled

frailty_score <- extract_beta_ci(df$Frailty_Score_Beta_CI)
frailty_score_std_beta <- frailty_score$beta / base_sd_pooled
frailty_score_std_lcl <- frailty_score$lcl / base_sd_pooled
frailty_score_std_ucl <- frailty_score$ucl / base_sd_pooled

frail_beta <- extract_frail_beta(df$Frailty_Contrasts)
frail_beta_std <- frail_beta / base_sd_pooled

# Add requested columns
# 1) Baseline_SD_pooled
# 2) FOF_Beta_CI_std
# 3) Frailty_Score_Beta_CI_std
# 4) Frail_vs_Robust_beta_std

df$Baseline_SD_pooled <- round(base_sd_pooled, 6)
df$FOF_Beta_CI_std <- format_beta_ci(fof_std_beta, fof_std_lcl, fof_std_ucl, digits = 3)
df$Frailty_Score_Beta_CI_std <- format_beta_ci(frailty_score_std_beta, frailty_score_std_lcl, frailty_score_std_ucl, digits = 3)
df$Frail_vs_Robust_beta_std <- round(frail_beta_std, 6)

dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
write.csv(df, output_path, row.names = FALSE, na = "NA")

message("Wrote: ", output_path)
