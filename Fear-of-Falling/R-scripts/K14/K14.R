#!/usr/bin/env Rscript
# ==============================================================================
# K14 - Baseline characteristics by FOF status (Table 1)
# ==============================================================================
if (Sys.getenv("RENV_PROJECT") == "") source("renv/activate.R")

suppressPackageStartupMessages({
  library(here)
  library(dplyr)
})

args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)
script_base <- if (length(file_arg) > 0) sub("\\.R$", "", basename(sub("^--file=", "", file_arg[1]))) else "K14"
script_label <- sub("\\.V.*$", "", script_base)
if (is.na(script_label) || script_label == "") script_label <- "K14"

rm(list = ls(pattern = "^(save_|init_paths$|append_manifest$|manifest_row$)"), envir = .GlobalEnv)
source(here("R","functions","io.R"))
source(here("R","functions","checks.R"))
source(here("R","functions","modeling.R"))
source(here("R","functions","reporting.R"))

paths <- init_paths(script_label)
set.seed(20251124)

file_path <- here::here("data", "external", "KaatumisenPelko.csv")
if (!file.exists(file_path)) stop("Tiedostoa data/external/KaatumisenPelko.csv ei loydy.")

raw_data <- readr::read_csv(file_path, show_col_types = FALSE)

# --- FIX: SRH Variable Guard ---
srh_cands <- c("itsearvioitu_terveys", "SRH", "self_rated_health", "terveys", "koettuterveydentila")
srh_found <- intersect(srh_cands, names(raw_data))
if (length(srh_found) > 0) {
  SRH_source_var <- srh_found[1]
  message("Auto-detected SRH variable: ", SRH_source_var)
} else {
  SRH_source_var <- NULL
  message("WARNING: SRH variable not found. Skipping SRH analysis.")
}
# --- End FIX ---

df <- standardize_analysis_vars(raw_data)
qc <- sanity_checks(df)
print(qc)

analysis_data <- raw_data
outputs_dir   <- getOption("fof.outputs_dir")
manifest_path <- getOption("fof.manifest_path")

# 02. Recodings
analysis_data_rec <- analysis_data %>%
  mutate(
    FOF_status = factor(kaatumisenpelkoOn, levels = c(0, 1), labels = c("nonFOF", "FOF")),
    sex_factor = factor(sex, levels = c(0, 1), labels = c("Level 0", "Level 1")),
    woman = case_when(
      sex_factor == "Level 0" ~ 1L,
      sex_factor == "Level 1" ~ 0L,
      TRUE ~ NA_integer_
    ),
    SRM_3class_table = factor(oma_arvio_liikuntakyky, levels = c(2, 1, 0), labels = c("Good", "Moderate", "Weak"), ordered = TRUE),
    Walk500m_3class_table = factor(vaikeus_liikkua_500m, levels = c(0, 1, 2), labels = c("No", "Difficulties", "Cannot"), ordered = TRUE),
    alcohol_3class_table = factor(alkoholi, levels = c(0, 1, 2), labels = c("No", "Moderate", "Large"), ordered = TRUE)
  )

if (!is.null(SRH_source_var)) {
  analysis_data_rec <- analysis_data_rec %>%
    mutate(
      SRH_3class_table = factor(.data[[SRH_source_var]], levels = c(2, 1, 0), labels = c("Good", "Moderate", "Bad"), ordered = TRUE)
    )
}

analysis_data_rec <- analysis_data_rec %>%
  mutate(
    disease_count = rowSums(cbind(diabetes==1, alzheimer==1, parkinson==1, AVH==1), na.rm = TRUE),
    disease_nonmiss = rowSums(cbind(!is.na(diabetes), !is.na(alzheimer), !is.na(parkinson), !is.na(AVH)), na.rm = TRUE),
    comorbidity = dplyr::case_when(disease_nonmiss == 0 ~ NA_integer_, disease_count > 1 ~ 1L, TRUE ~ 0L)
  )

if (!"FOF_status" %in% names(analysis_data_rec)) stop("FOF_status puuttuu.")

fof_counts <- analysis_data_rec %>% filter(!is.na(FOF_status)) %>% count(FOF_status)
if (nrow(fof_counts) > 0) {
    fof_levels <- levels(analysis_data_rec$FOF_status)
    group0_lvl <- fof_levels[1]; group1_lvl <- fof_levels[2]
    N_group0 <- fof_counts$n[fof_counts$FOF_status == group0_lvl]; if(length(N_group0)==0) N_group0 <- 0
    N_group1 <- fof_counts$n[fof_counts$FOF_status == group1_lvl]; if(length(N_group1)==0) N_group1 <- 0
} else { N_group0 <- 0; N_group1 <- 0 }

# 03. Helpers
format_pvalue <- function(p) { if (is.null(p) || is.na(p)) return("") else if (p < 0.001) "<0.001" else sprintf("%.3f", p) }
format_mean_sd <- function(x, group, digits = 1) {
  idx <- !is.na(x) & !is.na(group); x_use <- x[idx]; g_use <- droplevels(group[idx])
  if (length(x_use) == 0L) return(setNames(c("", ""), levels(group)))
  out <- setNames(character(length(levels(g_use))), levels(g_use))
  for (lvl in levels(g_use)) {
    x_g <- x_use[g_use == lvl]
    if (length(x_g) == 0L) out[lvl] <- "" else { m <- mean(x_g); s <- stats::sd(x_g); out[lvl] <- paste0(round(m, digits), "(", round(s, digits), ")") }
  }
  out
}
format_n_pct <- function(x, group, event = 1L) {
  idx <- !is.na(x) & !is.na(group); x_use <- x[idx]; g_use <- droplevels(group[idx])
  out <- setNames(character(length(levels(g_use))), levels(g_use))
  for (lvl in levels(g_use)) {
    mask <- g_use == lvl; denom <- sum(mask)
    if (denom == 0L) out[lvl] <- "" else { n_event <- sum(x_use[mask] == event, na.rm = TRUE); pct <- round(100 * n_event / denom); out[lvl] <- paste0(n_event, "(", pct, ")") }
  }
  out
}
fun_pvalue_cont <- function(x, group) {
  idx <- !is.na(x) & !is.na(group); x_use <- x[idx]; g_use <- droplevels(group[idx])
  if (length(unique(g_use)) < 2L) return(NA_real_)
  tryCatch({ stats::t.test(x_use ~ g_use)$p.value }, error = function(e) NA_real_)
}
fun_pvalue_cat <- function(x, group) {
  idx <- !is.na(x) & !is.na(group); x_use <- x[idx]; g_use <- droplevels(group[idx])
  if (length(unique(g_use)) < 2L || length(unique(x_use)) < 2L) return(NA_real_)
  tab <- table(g_use, x_use)
  chi_res <- tryCatch(suppressWarnings(stats::chisq.test(tab, correct = FALSE)), error = function(e) NULL)
  if (!is.null(chi_res)) { if (any(chi_res$expected < 5)) stats::fisher.test(tab)$p.value else chi_res$p.value } else { stats::fisher.test(tab)$p.value }
}
make_binary_row <- function(data, var_name, row_label, event = 1L, group0 = group0_lvl, group1 = group1_lvl) {
  x <- data[[var_name]]; vals <- format_n_pct(x, data$FOF_status, event = event); p <- fun_pvalue_cat(x, data$FOF_status)
  tibble(Variable=paste0("  ", row_label), Without_FOF=vals[group0], With_FOF=vals[group1], P_value=format_pvalue(p))
}
make_multicat_rows_with_level_p <- function(data, var_name, header_label, group0 = group0_lvl, group1 = group1_lvl) {
  f <- data[[var_name]]; g <- data$FOF_status; idx <- !is.na(f) & !is.na(g); f_use <- droplevels(f[idx]); g_use <- droplevels(g[idx])
  if (length(f_use) == 0L) return(tibble(Variable=header_label, Without_FOF="", With_FOF="", P_value=""))
  levels_f <- levels(f_use)
  tab <- as.data.frame(table(g_use, f_use), stringsAsFactors = FALSE); colnames(tab) <- c("FOF_status", "level", "n")
  tab <- tab %>% group_by(FOF_status) %>% mutate(denom=sum(n), pct=ifelse(denom>0, round(100*n/denom), NA_real_)) %>% ungroup()
  get_cell <- function(lvl, fof) { row <- tab %>% filter(level == lvl, FOF_status == fof); if(nrow(row)==0L || row$denom[1]==0L) "0(0)" else paste0(row$n[1], "(", row$pct[1], ")") }
  header_sums <- tab %>% group_by(FOF_status) %>% summarise(n_total=sum(n), .groups="drop")
  get_hdr <- function(fof) { row <- header_sums %>% filter(FOF_status == fof); if(nrow(row)==0L || is.na(row$n_total[1]) || row$n_total[1]==0L) "" else paste0(row$n_total[1], "(100)") }
  p_overall <- fun_pvalue_cat(f, g)
  rows <- list(tibble(Variable=header_label, Without_FOF=get_hdr(group0), With_FOF=get_hdr(group1), P_value=format_pvalue(p_overall)))
  for (lvl in levels_f) {
    tbl <- table(g_use, f_use == lvl); p_lvl <- tryCatch(stats::fisher.test(tbl)$p.value, error=function(e) NA)
    rows[[length(rows)+1]] <- tibble(Variable=paste0("  ", lvl), Without_FOF=get_cell(lvl, group0), With_FOF=get_cell(lvl, group1), P_value=format_pvalue(p_lvl))
  }
  bind_rows(rows)
}

# 04. Table Generation
vals_women <- format_n_pct(analysis_data_rec$woman, analysis_data_rec$FOF_status, event=1L)
p_women <- fun_pvalue_cat(analysis_data_rec$woman, analysis_data_rec$FOF_status)
tab_women <- tibble(Variable="Sex (Level 1), n (%)", Without_FOF=vals_women[group0_lvl], With_FOF=vals_women[group1_lvl], P_value=format_pvalue(p_women))

vals_age <- format_mean_sd(analysis_data_rec$age, analysis_data_rec$FOF_status, digits=0)
p_age <- fun_pvalue_cont(analysis_data_rec$age, analysis_data_rec$FOF_status)
tab_age <- tibble(Variable="Age, mean (SD)", Without_FOF=vals_age[group0_lvl], With_FOF=vals_age[group1_lvl], P_value=format_pvalue(p_age))

any_dis <- with(analysis_data_rec, (diabetes==1)|(alzheimer==1)|(parkinson==1)|(AVH==1))
vals_any <- format_n_pct(as.integer(any_dis), analysis_data_rec$FOF_status, event=1L)
p_any <- fun_pvalue_cat(as.integer(any_dis), analysis_data_rec$FOF_status)
tab_dis_head <- tibble(Variable="Diseases, n (%)", Without_FOF=vals_any[group0_lvl], With_FOF=vals_any[group1_lvl], P_value=format_pvalue(p_any))
tab_dis <- bind_rows(tab_dis_head, 
                     make_binary_row(analysis_data_rec, "diabetes", "Diabetes"),
                     make_binary_row(analysis_data_rec, "alzheimer", "Dementia"),
                     make_binary_row(analysis_data_rec, "parkinson", "Parkinson's"),
                     make_binary_row(analysis_data_rec, "AVH", "CVA"),
                     make_binary_row(analysis_data_rec, "comorbidity", "Comorbidity (>1)"))

if (!is.null(SRH_source_var)) {
  tab_SRH <- make_multicat_rows_with_level_p(analysis_data_rec, "SRH_3class_table", "Self-rated Health, n (%)")
} else {
  tab_SRH <- tibble(Variable="Self-rated Health", Without_FOF="N/A", With_FOF="N/A", P_value="")
}

vals_MOI <- format_mean_sd(analysis_data_rec$MOIindeksiindeksi, analysis_data_rec$FOF_status, digits=1)
p_MOI <- fun_pvalue_cont(analysis_data_rec$MOIindeksiindeksi, analysis_data_rec$FOF_status)
tab_MOI <- tibble(Variable="Mikkeli Index, mean (SD)", Without_FOF=vals_MOI[group0_lvl], With_FOF=vals_MOI[group1_lvl], P_value=format_pvalue(p_MOI))

vals_BMI <- format_mean_sd(analysis_data_rec$BMI, analysis_data_rec$FOF_status, digits=1)
p_BMI <- fun_pvalue_cont(analysis_data_rec$BMI, analysis_data_rec$FOF_status)
tab_BMI <- tibble(Variable="BMI, mean (SD)", Without_FOF=vals_BMI[group0_lvl], With_FOF=vals_BMI[group1_lvl], P_value=format_pvalue(p_BMI))

vals_smk <- format_n_pct(analysis_data_rec$tupakointi, analysis_data_rec$FOF_status, event=1L)
p_smk <- fun_pvalue_cat(analysis_data_rec$tupakointi, analysis_data_rec$FOF_status)
tab_smk <- tibble(Variable="Smoked, n (%)", Without_FOF=vals_smk[group0_lvl], With_FOF=vals_smk[group1_lvl], P_value=format_pvalue(p_smk))

tab_alc <- make_multicat_rows_with_level_p(analysis_data_rec, "alcohol_3class_table", "Alcohol, n (%)")
tab_SRM <- make_multicat_rows_with_level_p(analysis_data_rec, "SRM_3class_table", "Self-Rated Mobility, n (%)")
tab_W500 <- make_multicat_rows_with_level_p(analysis_data_rec, "Walk500m_3class_table", "Walking 500m, n (%)")

vals_bal <- format_n_pct(analysis_data_rec$tasapainovaikeus, analysis_data_rec$FOF_status, event=1L)
p_bal <- fun_pvalue_cat(analysis_data_rec$tasapainovaikeus, analysis_data_rec$FOF_status)
tab_bal <- tibble(Variable="Balance difficulties, n (%)", Without_FOF=vals_bal[group0_lvl], With_FOF=vals_bal[group1_lvl], P_value=format_pvalue(p_bal))

vals_fal <- format_n_pct(analysis_data_rec$kaatuminen, analysis_data_rec$FOF_status, event=1L)
p_fal <- fun_pvalue_cat(analysis_data_rec$kaatuminen, analysis_data_rec$FOF_status)
tab_fal <- tibble(Variable="Fallen, n (%)", Without_FOF=vals_fal[group0_lvl], With_FOF=vals_fal[group1_lvl], P_value=format_pvalue(p_fal))

vals_frc <- format_n_pct(analysis_data_rec$murtumia, analysis_data_rec$FOF_status, event=1L)
p_frc <- fun_pvalue_cat(analysis_data_rec$murtumia, analysis_data_rec$FOF_status)
tab_frc <- tibble(Variable="Fractures, n (%)", Without_FOF=vals_frc[group0_lvl], With_FOF=vals_frc[group1_lvl], P_value=format_pvalue(p_frc))

vals_pain <- format_mean_sd(analysis_data_rec$PainVAS0, analysis_data_rec$FOF_status, digits=1)
p_pain <- fun_pvalue_cont(analysis_data_rec$PainVAS0, analysis_data_rec$FOF_status)
tab_pain <- tibble(Variable="Pain VAS, mean (SD)", Without_FOF=vals_pain[group0_lvl], With_FOF=vals_pain[group1_lvl], P_value=format_pvalue(p_pain))

# Combine
final_tab <- bind_rows(tab_women, tab_age, tab_dis, tab_SRH, tab_MOI, tab_BMI, tab_smk, tab_alc, tab_SRM, tab_W500, tab_bal, tab_fal, tab_frc, tab_pain)

# Column names
col_w <- paste0("Without FOF\nn=", N_group0)
col_f <- paste0("With FOF\nn=", N_group1)
final_tab <- final_tab %>% rename(" " = Variable, !!col_w := Without_FOF, !!col_f := With_FOF, "P-value" := P_value)

print(final_tab)

# Save
save_table_csv_html(final_tab, "K14_baseline_by_FOF")

# Manifest
manifest_rows <- tibble(
  script      = script_label,
  type        = "table",
  filename    = file.path(script_label, "K14_baseline_by_FOF.csv"),
  description = "Baseline characteristics by FOF-status (Table 1)"
)
append_manifest(manifest_rows, manifest_path)

message("K14 completed.")
save_sessioninfo_manifest()
