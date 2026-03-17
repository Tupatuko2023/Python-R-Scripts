#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
  library(readxl)
  library(here)
})

script_label <- "K51"
manifest_script <- "K51_three_key_linkage_audit"

source(here::here("R", "functions", "init.R"))
source(here::here("R", "functions", "person_dedup_lookup.R"))

paths <- init_paths(script_label)
outputs_dir <- paths$outputs_dir
manifest_path <- paths$manifest_path

append_manifest_safe <- function(label, kind, path, n = NA_integer_, notes = NA_character_) {
  row <- data.frame(
    timestamp = as.character(Sys.time()),
    script = manifest_script,
    label = label,
    kind = kind,
    path = get_relpath(path),
    n = n,
    notes = notes,
    stringsAsFactors = FALSE
  )
  dir.create(dirname(manifest_path), recursive = TRUE, showWarnings = FALSE)
  if (!file.exists(manifest_path)) {
    utils::write.table(row, manifest_path, sep = ",", row.names = FALSE, col.names = TRUE, qmethod = "double")
  } else {
    utils::write.table(row, manifest_path, sep = ",", row.names = FALSE, col.names = FALSE, append = TRUE, qmethod = "double")
  }
}

normalize_header <- function(x) {
  out <- tolower(trimws(as.character(x)))
  out <- gsub("[\r\n\t]+", " ", out)
  out <- gsub("[[:space:]]+", " ", out)
  out <- gsub("[^[:alnum:]]+", "", out)
  out
}

pick_col_regex_first <- function(df_names, target, patterns) {
  norm_df <- normalize_header(df_names)
  for (pattern in patterns) {
    hits <- grepl(pattern, norm_df, perl = TRUE)
    if (sum(hits) == 1L) return(df_names[which(hits)[1]])
  }
  stop("Audit could not resolve column for ", target, ".", call. = FALSE)
}

pick_col_regex_optional <- function(df_names, patterns) {
  norm_df <- normalize_header(df_names)
  for (pattern in patterns) {
    hits <- grepl(pattern, norm_df, perl = TRUE)
    if (sum(hits) == 1L) return(df_names[which(hits)[1]])
  }
  NA_character_
}

safe_num <- function(x) suppressWarnings(as.numeric(x))

normalize_fof <- function(x) {
  s <- tolower(trimws(as.character(x)))
  out <- rep(NA_integer_, length(s))
  out[s %in% c("0", "nonfof", "ei fof", "no fof", "false")] <- 0L
  out[s %in% c("1", "fof", "true")] <- 1L
  suppressWarnings(num <- as.integer(s))
  use_num <- is.na(out) & !is.na(num) & num %in% c(0L, 1L)
  out[use_num] <- num[use_num]
  out
}

resolve_input_path <- function() {
  data_root <- resolve_data_root()
  if (is.na(data_root)) stop("Audit requires DATA_ROOT.", call. = FALSE)
  path <- file.path(data_root, "paper_01", "analysis", "fof_analysis_k50_long.rds")
  if (!file.exists(path)) stop("Audit could not resolve canonical K50 LONG input.", call. = FALSE)
  normalizePath(path, winslash = "/", mustWork = TRUE)
}

read_kaaos_audit_table <- function(path) {
  tbl <- tibble::as_tibble(readxl::read_excel(path, sheet = "Taul1", skip = 1, n_max = Inf))
  nm <- names(tbl)
  col_nro <- pick_col_regex_first(nm, "NRO", c("^nro$"))
  col_sotu <- pick_col_regex_optional(nm, c("^sotu$"))
  col_id <- pick_col_regex_optional(nm, c("^potilastunnus$", "^id$"))
  col_fof <- pick_col_regex_first(nm, "FOF", c("^kaatumisenpelko0eipelk"))
  col_age <- pick_col_regex_first(nm, "age", c("^ik"))
  col_sex <- pick_col_regex_first(nm, "sex", c("^sukupuoli0nainen1mies$"))
  col_bmi <- pick_col_regex_first(nm, "BMI", c("^bmikgm2e1eitietoa$"))
  col_balance <- pick_col_regex_first(nm, "balance", c("^tasapainovaikeudet0ei1kyll"))
  col_diabetes <- pick_col_regex_first(nm, "diabetes", c("^diabetes0ei1kyll"))
  col_alzheimer <- pick_col_regex_first(nm, "alzheimer", c("^alzheimer0ei1kyll"))
  col_parkinson <- pick_col_regex_first(nm, "parkinson", c("^parkinson0ei1kyll"))
  col_avh <- pick_col_regex_first(nm, "AVH", c("^avh0ei1kyll"))
  col_srh <- pick_col_regex_first(nm, "SRH", c("^koettuterveydentila"))
  col_moi <- pick_col_regex_first(nm, "MOI", c("^moiindeksi"))
  col_smoking <- pick_col_regex_first(nm, "smoking", c("^tupakointi0eipolta1polttaa"))
  col_alcohol <- pick_col_regex_first(nm, "alcohol", c("^alkoholi0ei1maltillinen"))
  col_srm <- pick_col_regex_first(nm, "mobility", c("^omaarvioliikuntakyvyst"))
  col_walk500 <- pick_col_regex_first(nm, "walk500", c("^500mvaikeusliikkua0eivaikeuksia1vaikeuksia"))
  col_falls <- pick_col_regex_first(nm, "falls", c("^kaatuminen0ei1kyll"))
  col_fractures <- pick_col_regex_first(nm, "fractures", c("^murtumia0ei1kyll"))
  col_pain <- pick_col_regex_first(nm, "PainVAS0", c("^tkvas"))

  tbl %>%
    transmute(
      candidate_nro = normalize_id(.data[[col_nro]]),
      candidate_sotu = if (!is.na(col_sotu)) normalize_ssn(.data[[col_sotu]]) else NA_character_,
      candidate_workbook_id = if (!is.na(col_id)) normalize_id(.data[[col_id]]) else NA_character_,
      FOF_status = normalize_fof(.data[[col_fof]]),
      age = safe_num(.data[[col_age]]),
      sex = factor(case_when(
        safe_num(.data[[col_sex]]) == 0 ~ "female",
        safe_num(.data[[col_sex]]) == 1 ~ "male",
        TRUE ~ NA_character_
      ), levels = c("female", "male")),
      BMI = safe_num(.data[[col_bmi]]),
      tasapainovaikeus = safe_num(.data[[col_balance]]),
      diabetes = safe_num(.data[[col_diabetes]]),
      alzheimer = safe_num(.data[[col_alzheimer]]),
      parkinson = safe_num(.data[[col_parkinson]]),
      AVH = safe_num(.data[[col_avh]]),
      koettuterveydentila = safe_num(.data[[col_srh]]),
      MOIindeksiindeksi = safe_num(.data[[col_moi]]),
      tupakointi = safe_num(.data[[col_smoking]]),
      alkoholi = safe_num(.data[[col_alcohol]]),
      oma_arvio_liikuntakyky = safe_num(.data[[col_srm]]),
      vaikeus_liikkua_500m = safe_num(.data[[col_walk500]]),
      kaatuminen = safe_num(.data[[col_falls]]),
      murtumia = safe_num(.data[[col_fractures]]),
      PainVAS0 = safe_num(.data[[col_pain]])
    ) %>%
    filter(!is.na(candidate_nro))
}

input_path <- resolve_input_path()
missing_path <- here::here("R-scripts", "K51", "outputs", "k51_missing_person_keys_baseline_eligible.csv")
if (!file.exists(missing_path)) stop("Missing-key artifact not found: ", missing_path, call. = FALSE)

input_df <- tibble::as_tibble(readRDS(input_path))
dedup_prep <- prepare_k50_person_dedup(input_df, "LONG", "locomotor_capacity")
analysis_person_df <- dedup_prep$analysis_df %>% arrange(person_key, id, time)

canonical_df <- analysis_person_df %>%
  filter(time == 0, id %in% c("18", "100", "102")) %>%
  transmute(
    canonical_id = normalize_id(id),
    person_key = as.character(person_key),
    ssn_key = sub("^ssn:", "", person_key),
    FOF_status = as.integer(as.character(FOF_status)),
    age = safe_num(age),
    sex = as.character(sex),
    BMI = safe_num(BMI),
    locomotor_capacity_baseline = safe_num(outcome_value),
    FI22_nonperformance_KAAOS = safe_num(FI22_nonperformance_KAAOS)
  ) %>%
  distinct(canonical_id, .keep_all = TRUE)

missing_df <- suppressMessages(readr::read_csv(missing_path, show_col_types = FALSE)) %>%
  mutate(canonical_id = normalize_id(id))

data_root <- resolve_data_root()
kaaos_sotullinen <- read_kaaos_audit_table(file.path(data_root, "paper_02", "KAAOS_data_sotullinen.xlsx"))
kaaos_data <- tryCatch(
  read_kaaos_audit_table(file.path(data_root, "paper_02", "KAAOS_data.xlsx")),
  error = function(e) tibble()
)
sotut <- tryCatch({
  sotut_raw <- tibble::as_tibble(readxl::read_excel(file.path(data_root, "paper_02", "sotut.xlsx"), sheet = "Taul1", skip = 0, n_max = Inf))
  sotut_nro_col <- pick_col_regex_first(names(sotut_raw), "NRO", c("^nro$"))
  sotut_sotu_col <- pick_col_regex_first(names(sotut_raw), "Sotu", c("^sotu$"))
  sotut_id_col <- pick_col_regex_first(names(sotut_raw), "id", c("^potilastunnus$"))
  sotut_raw %>%
    transmute(
      bridge_nro = normalize_id(.data[[sotut_nro_col]]),
      bridge_sotu = normalize_ssn(.data[[sotut_sotu_col]]),
      bridge_id = normalize_id(.data[[sotut_id_col]])
    ) %>%
    distinct()
}, error = function(e) tibble(
  bridge_nro = character(),
  bridge_sotu = character(),
  bridge_id = character()
))

claimed_candidates <- c("18" = "314", "100" = "285", "102" = "288")

table1_fields <- c(
  "FOF_status", "age", "sex", "BMI", "tasapainovaikeus", "diabetes", "alzheimer",
  "parkinson", "AVH", "koettuterveydentila", "MOIindeksiindeksi", "tupakointi",
  "alkoholi", "oma_arvio_liikuntakyky", "vaikeus_liikkua_500m", "kaatuminen",
  "murtumia", "PainVAS0"
)

audit_rows <- lapply(names(claimed_candidates), function(cid) {
  candidate_nro <- claimed_candidates[[cid]]
  canon <- canonical_df %>% filter(canonical_id == cid)
  miss <- missing_df %>% filter(canonical_id == cid)
  cand_sotullinen <- kaaos_sotullinen %>% filter(candidate_nro == !!candidate_nro)
  cand_kaaos_data <- kaaos_data %>% filter(candidate_nro == !!candidate_nro)
  bridge_row <- sotut %>% filter(bridge_nro == !!candidate_nro)

  if (nrow(canon) != 1L || nrow(cand_sotullinen) != 1L) {
    return(tibble(
      canonical_id = cid,
      candidate_nro = candidate_nro,
      candidate_source = "KAAOS_data_sotullinen.xlsx",
      bridge_sources = paste(c(
        if (nrow(bridge_row) > 0L) "sotut.xlsx" else NA_character_,
        if (nrow(cand_kaaos_data) > 0L) "KAAOS_data.xlsx" else NA_character_
      ), collapse = " | "),
      core_match_fof = FALSE,
      core_match_sex = FALSE,
      core_match_bmi = FALSE,
      full_compare_diff_cols = "candidate_missing_or_ambiguous",
      table1_relevant_diff_cols = "candidate_missing_or_ambiguous",
      safe_override_for_table1 = FALSE,
      override_rule_notes = "Candidate row missing or ambiguous in audit sources."
    ))
  }

  cand <- cand_sotullinen
  core_match_fof <- identical(canon$FOF_status[[1]], cand$FOF_status[[1]])
  core_match_sex <- identical(canon$sex[[1]], as.character(cand$sex[[1]]))
  core_match_bmi <- isTRUE(all.equal(unname(canon$BMI[[1]]), unname(cand$BMI[[1]]), tolerance = 1e-8))

  full_compare_fields <- c("FOF_status", "age", "sex", "BMI")
  full_diff <- full_compare_fields[vapply(full_compare_fields, function(col) {
    left <- canon[[col]][[1]]
    right <- cand[[col]][[1]]
    if (is.numeric(left) || is.numeric(right)) {
      !isTRUE(all.equal(unname(left), unname(right), tolerance = 1e-8))
    } else {
      !identical(as.character(left), as.character(right))
    }
  }, logical(1))]

  table1_relevant_diffs <- intersect(full_diff, table1_fields)
  safe_override <- core_match_fof && core_match_sex && core_match_bmi && length(table1_relevant_diffs) == 0L

  bridge_sources <- c()
  if (nrow(bridge_row) > 0L) bridge_sources <- c(bridge_sources, "sotut.xlsx")
  if (nrow(cand_kaaos_data) > 0L) bridge_sources <- c(bridge_sources, "KAAOS_data.xlsx")
  if (nrow(cand_sotullinen) > 0L) bridge_sources <- c(bridge_sources, "KAAOS_data_sotullinen.xlsx")

  tibble(
    canonical_id = cid,
    candidate_nro = candidate_nro,
    candidate_source = "KAAOS_data_sotullinen.xlsx",
    bridge_sources = paste(unique(bridge_sources), collapse = " | "),
    canonical_ssn = canon$ssn_key[[1]],
    candidate_ssn = cand$candidate_sotu[[1]],
    core_match_fof = core_match_fof,
    core_match_sex = core_match_sex,
    core_match_bmi = core_match_bmi,
    full_compare_diff_cols = if (length(full_diff) > 0L) paste(full_diff, collapse = " | ") else "",
    table1_relevant_diff_cols = if (length(table1_relevant_diffs) > 0L) paste(table1_relevant_diffs, collapse = " | ") else "",
    safe_override_for_table1 = safe_override,
    override_rule_notes = if (safe_override) {
      "Exact SSN candidate found in KAAOS_data_sotullinen.xlsx and core Table 1 fields FOF/sex/BMI match canonical baseline row."
    } else {
      "One or more core or Table 1-relevant fields differ; keep fail-closed."
    }
  )
})

audit_tbl <- bind_rows(audit_rows)

audit_csv <- file.path(outputs_dir, "k51_three_key_linkage_audit.csv")
readr::write_csv(audit_tbl, audit_csv, na = "")
append_manifest_safe(
  "k51_three_key_linkage_audit",
  "table_csv",
  audit_csv,
  n = nrow(audit_tbl),
  notes = "Three-key linkage audit for canonical ids 18, 100, 102"
)

audit_txt <- file.path(outputs_dir, "k51_three_key_linkage_audit.txt")
lines <- c(
  "K51 three-key linkage audit",
  paste0("input_path=", input_path),
  paste0("missing_keys_path=", missing_path),
  paste0("cases=", nrow(audit_tbl)),
  paste0("safe_override_count=", sum(audit_tbl$safe_override_for_table1, na.rm = TRUE)),
  paste0("unsafe_count=", sum(!audit_tbl$safe_override_for_table1, na.rm = TRUE)),
  paste0("safe_override_ids=", paste(audit_tbl$canonical_id[audit_tbl$safe_override_for_table1], collapse = " | "))
)
writeLines(lines, con = audit_txt)
append_manifest_safe(
  "k51_three_key_linkage_audit",
  "text",
  audit_txt,
  n = nrow(audit_tbl),
  notes = "Three-key linkage audit summary for canonical ids 18, 100, 102"
)
