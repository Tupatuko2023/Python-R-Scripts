#!/usr/bin/env Rscript

###############################################################################
#
# K14: FOF-ryhmittäinen perustaulukko ("Table 1")
# Skripti tuottaa deskriptiivisen taulukon, joka vertaa FOF-ryhmiä
# eri muuttujien suhteen.
# Käytetään ensisijaisesti dataa, joka on ladattu K1-skriptissä nimellä
# 'data_final'; vaihtoehtoisesti käytetään 'analysis_data' tai luetaan
# CSV-tiedosto.
#
# Tuottaa Table 1 -tyyppisen taulukon:
# - Sarakkeet:
#   * "Without FOF\nn=77" (todellinen n laskettu datasta)
#   * "With FOF\nn=199"
#   * "P-value"
# - Rivit (täsmälleen annetussa järjestyksessä):
#   1) Women, n (%)
#   2) Age, mean (SD)
#   3) Diseases, n (%)
#      - Diabetes
#      - Dementia
#      - Parkinson’s
#      - Cerebrovascular Accidents
#   4) Self-rated Health, n (%)
#      - Good
#      - Moderate
#      - Bad
#   5) Mikkeli Osteoporosis Index, mean (SD)
#   6) Body Mass Index, mean (SD)
#   7) Smoked, n (%)
#   8) Alcohol, n (%)
#      - No
#      - Moderate
#      - Large
#   9) Self-Rated Mobility, n (%)
#      - Good
#      - Moderate
#      - Weak
#  10) Walking 500 m, n (%)
#      - No
#      - Difficulties
#      - Cannot
#  11) Balance difficulties, n (%)
#  12) Fallen, n (%)
#  13) Fractures, n (%)
#  14) Pain (Visual Analog Scale), mm, mean (SD)
#
# Huom. Tämä skripti on deskriptiivinen; p-arvot ovat t-/chisq/Fisher-testeistä,
# mutta niitä ei pidä tulkita korjattuina monen testin suhteen.
###############################################################################

# ==============================================================================
# 0. PACKAGES ---------------------------------------------------
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(tibble)
  library(readr)
  library(knitr)
  library(here)
})

set.seed(20251124)

# ==============================================================================
# 1: Load the dataset -------------------------------------------
# ==============================================================================

## Ensisijaisesti käytetään data_final (K1), muuten analysis_data tai CSV

if (!exists("analysis_data")) {
  if (exists("data_final")) {
    analysis_data <- data_final
  } else {
    # Projektipohjainen oletuspolku, sama kuin K11/K13:ssa
    file_path <- here::here("data", "external", "KaatumisenPelko.csv")
    if (!file.exists(file_path)) {
      stop(
        "Objektia 'analysis_data' tai 'data_final' ei löytynyt, ",
        "eikä tiedostoa data/external/KaatumisenPelko.csv löydy.\n",
        "Luo 'analysis_data' tai 'data_final' ennen skriptin ajamista tai tarkista polku."
      )
    }
    raw_data <- readr::read_csv(file_path, show_col_types = FALSE)
    analysis_data <- raw_data
  }
}

## Kevyt tarkistus

if (!is.data.frame(analysis_data)) {
  stop("'analysis_data' ei ole data.frame/tibble – tarkista datan lataus.")
}

# ==============================================================================
# 2: Output-kansio K14:n alle ------------------------------------
# ==============================================================================

## ./Fear-of-Falling/R-scripts/K14/outputs

outputs_dir <- here::here("R-scripts", "K14", "outputs")
if (!dir.exists(outputs_dir)) {
  dir.create(outputs_dir, recursive = TRUE)
}

## Skriptin tunniste

script_label <- "K14"

## Manifest-kansio projektissa: ./manifest

manifest_dir <- here::here("manifest")
if (!dir.exists(manifest_dir)) {
  dir.create(manifest_dir, recursive = TRUE)
}
manifest_path <- file.path(manifest_dir, "manifest.csv")

## Helper: tallenna taulukko CSV + yksinkertainen HTML

save_table_csv_html <- function(df, basename,
                                out_dir = outputs_dir) {
  if (!dir.exists(out_dir)) {
    dir.create(out_dir, recursive = TRUE)
  }
  
  csv_path  <- file.path(out_dir, paste0(basename, ".csv"))
  html_path <- file.path(out_dir, paste0(basename, ".html"))
  
  # CSV
  readr::write_csv(df, csv_path)
  
  # HTML-taulukko
  html_table <- knitr::kable(
    df, format = "html",
    table.attr = "border='1' style='border-collapse:collapse;'"
  )
  
  html_content <- paste0(
    "<html><head><meta charset='UTF-8'></head><body>",
    "<h3>", basename, "</h3>",
    html_table,
    "</body></html>"
  )
  
  writeLines(html_content, con = html_path)
  
  invisible(list(csv = csv_path, html = html_path))
}

# ==============================================================================
# 3. RECODINGS: FOF-status + muut Table 1 -muuttujat----------------------------
# ==============================================================================

# Tässä käytetty muuttujakartta:
#   - FOF_status           = kaatumisenpelkoOn (0/1; 0 = without FOF, 1 = with FOF)
#   - Women                = sex (0 = female, 1 = male)
#   - Diseases             = diabetes, alzheimer (Dementia), parkinson, AVH
#   - Self-rated Health    = koettuterveydentila (0/1/2; oletus 0 = bad, 1 = moderate, 2 = good)
#   - Mikkeli Index        = MOIindeksiindeksi
#   - BMI                  = BMI
#   - Smoked               = tupakointi (0/1; 1 = smoked)
#   - Alcohol              = alkoholi (0/1/2; oletus 0 = No, 1 = Moderate, 2 = Large)
#   - Self-Rated Mobility  = oma_arvio_liikuntakyky (0/1/2; 0 = weak, 1 = moderate, 2 = good)
#   - Walking 500 m        = vaikeus_liikkua_500m (0/1/2; 0 = No, 1 = Difficulties, 2 = Cannot)
#   - Balance difficulties = tasapainovaikeus (0/1)
#   - Fallen               = kaatuminen (0/1)
#   - Fractures            = murtumia (0/1)
#   - Pain VAS             = PainVAS0 (mm/0–10)

analysis_data_rec <- analysis_data %>%
  mutate(
    # FOF-status: sama määrittely kuin muissa skripteissä (K9/K11/K13)
    FOF_status = factor(
      kaatumisenpelkoOn,
      levels = c(0, 1),
      labels = c("nonFOF", "FOF")
    ),
    
    # Sukupuoli: 0 = female, 1 = male
    sex_factor = factor(
      sex,
      levels = c(0, 1),
      labels = c("female", "male")
    ),
    woman = case_when(
      sex_factor == "female" ~ 1L,
      sex_factor == "male"   ~ 0L,
      TRUE                   ~ NA_integer_
    ),
    
    # Self-rated Health (3-luokkainen taulukkoa varten, Good/Moderate/Bad)
    # Oletus: koettuterveydentila 0 = bad, 1 = moderate, 2 = good
    SRH_3class_table = factor(
      koettuterveydentila,
      levels = c(2, 1, 0),
      labels = c("Good", "Moderate", "Bad"),
      ordered = TRUE
    ),
    
    # Self-Rated Mobility (oma_arvio_liikuntakyky 0–2 -> Good/Moderate/Weak)
    SRM_3class_table = factor(
      oma_arvio_liikuntakyky,
      levels = c(2, 1, 0),
      labels = c("Good", "Moderate", "Weak"),
      ordered = TRUE
    ),
    
    # Walking 500 m: 0 = No difficulties, 1 = Difficulties, 2 = Cannot
    Walk500m_3class_table = factor(
      vaikeus_liikkua_500m,
      levels = c(0, 1, 2),
      labels = c("No", "Difficulties", "Cannot"),
      ordered = TRUE
    ),
    
    # Alkoholinkäyttö: oletus 0 = No, 1 = Moderate, 2 = Large
    alcohol_3class_table = factor(
      alkoholi,
      levels = c(0, 1, 2),
      labels = c("No", "Moderate", "Large"),
      ordered = TRUE
    )
    
    # Muut perusmuuttujat (diabetes, alzheimer, parkinson, AVH, MOIindeksiindeksi,
    # BMI, tupakointi, tasapainovaikeus, kaatuminen, murtumia, PainVAS0)
    # käytetään sellaisenaan.
  )


analysis_data_rec <- analysis_data_rec %>%
  mutate(
    # Comorbidity = >1 listed disease (diabetes, alzheimer, parkinson, AVH)
    disease_count = rowSums(cbind(
      diabetes  == 1,
      alzheimer == 1,
      parkinson == 1,
      AVH       == 1
    ), na.rm = TRUE),
    disease_nonmiss = rowSums(cbind(
      !is.na(diabetes),
      !is.na(alzheimer),
      !is.na(parkinson),
      !is.na(AVH)
    ), na.rm = TRUE),
    comorbidity = dplyr::case_when(
      disease_nonmiss == 0 ~ NA_integer_,  # kaikki neljä puuttuvat
      disease_count   > 1 ~ 1L,            # >1 sairaus
      TRUE                 ~ 0L            # 0–1 sairaus
    )
  )

## FOF-ryhmäkoot (käytetään sarakeotsikoissa)

if (!"FOF_status" %in% names(analysis_data_rec)) {
  stop("FOF_status puuttuu recodetusta datasta – tarkista kaatumisenpelkoOn-muuttuja.")
}

fof_counts <- analysis_data_rec %>%
  filter(!is.na(FOF_status)) %>%
  count(FOF_status)

if (nrow(fof_counts) != 2L) {
  warning("FOF_status-tasoja ei ole täsmälleen kaksi; taulukko voi olla epätäydellinen.")
}

## Oletetaan järjestys: 1 = nonFOF (Without FOF), 2 = FOF (With FOF)

fof_levels <- levels(analysis_data_rec$FOF_status)
group0_lvl <- fof_levels[1] # "nonFOF"
group1_lvl <- fof_levels[2] # "FOF"

N_group0 <- fof_counts$n[fof_counts$FOF_status == group0_lvl]
N_group1 <- fof_counts$n[fof_counts$FOF_status == group1_lvl]

# ==============================================================================
# 4. Apufunktiot: mean(SD), n(%), p-arvot, p-arvon formatointi---------
# ==============================================================================

## 4.1 P-arvon muotoilu

format_pvalue <- function(p) {
  if (is.null(p) || is.na(p)) {
    return("")
  }
  if (p < 0.001) {
    "<0.001"
  } else {
    sprintf("%.3f", p)
  }
}

## 4.2 mean(SD) ryhmittäin

format_mean_sd <- function(x, group, digits = 1) {
  idx <- !is.na(x) & !is.na(group)
  x_use <- x[idx]
  g_use <- droplevels(group[idx])
  
  if (length(x_use) == 0L) {
    return(setNames(c("", ""), levels(group)))
  }
  
  out <- setNames(character(length(levels(g_use))), levels(g_use))
  for (lvl in levels(g_use)) {
    x_g <- x_use[g_use == lvl]
    if (length(x_g) == 0L) {
      out[lvl] <- ""
    } else {
      m <- mean(x_g)
      s <- stats::sd(x_g)
      out[lvl] <- paste0(
        round(m, digits = digits),
        "(",
        round(s, digits = digits),
        ")"
      )
    }
  }
  out
}

## 4.3 n(%) dikotomiselle muuttujalle (event = 1)

format_n_pct <- function(x, group, event = 1L) {
  idx <- !is.na(x) & !is.na(group)
  x_use <- x[idx]
  g_use <- droplevels(group[idx])
  
  out <- setNames(character(length(levels(g_use))), levels(g_use))
  
  for (lvl in levels(g_use)) {
    mask <- g_use == lvl
    denom <- sum(mask)
    if (denom == 0L) {
      out[lvl] <- ""
    } else {
      n_event <- sum(x_use[mask] == event, na.rm = TRUE)
      pct <- round(100 * n_event / denom)
      out[lvl] <- paste0(n_event, "(", pct, ")")
    }
  }
  out
}

## 4.4 P-arvo jatkuville (t-testi)

fun_pvalue_cont <- function(x, group) {
  idx <- !is.na(x) & !is.na(group)
  x_use <- x[idx]
  g_use <- droplevels(group[idx])
  
  if (length(unique(g_use)) < 2L) {
    return(NA_real_)
  }
  
  p <- tryCatch(
    {
      stats::t.test(x_use ~ g_use)$p.value
    },
    error = function(e) NA_real_
  )
  p
}

## 4.5 P-arvo kategorisille (chi-square / Fisher)

fun_pvalue_cat <- function(x, group) {
  idx <- !is.na(x) & !is.na(group)
  x_use <- x[idx]
  g_use <- droplevels(group[idx])
  
  if (length(unique(g_use)) < 2L || length(unique(x_use)) < 2L) {
    return(NA_real_)
  }
  
  tab <- table(g_use, x_use)
  
  chi_res <- tryCatch(
    suppressWarnings(stats::chisq.test(tab, correct = FALSE)),
    error = function(e) NULL
  )
  
  if (!is.null(chi_res)) {
    # Jos odotetuissa frekvensseissä pieniä soluarvoja, käytä Fisheriä
    if (any(chi_res$expected < 5)) {
      p <- stats::fisher.test(tab)$p.value
    } else {
      p <- chi_res$p.value
    }
  } else {
    p <- stats::fisher.test(tab)$p.value
  }
  
  p
}

## 4.6 Helper: dikotominen rivi (n(%) + p-arvo)

make_binary_row <- function(data, var_name, row_label, event = 1L,
                            group0 = group0_lvl, group1 = group1_lvl) {
  x <- data[[var_name]]
  vals <- format_n_pct(x, data$FOF_status, event = event)
  p <- fun_pvalue_cat(x, data$FOF_status)
  
  tibble(
    Variable    = paste0("  ", row_label),
    Without_FOF = vals[group0],
    With_FOF    = vals[group1],
    P_value     = format_pvalue(p)
  )
}

## 4.7 Helper: moniluokkainen muuttuja (header + luokkakohtaiset rivit)

make_multicat_rows <- function(data, var_name, header_label,
                               group0 = group0_lvl, group1 = group1_lvl) {
  f <- data[[var_name]]
  g <- data$FOF_status
  
  idx <- !is.na(f) & !is.na(g)
  f_use <- droplevels(f[idx])
  g_use <- droplevels(g[idx])
  
  levels_f <- levels(f_use)
  
  # Ristiintaulukko prosentteja varten
  tab <- as.data.frame(table(g_use, f_use), stringsAsFactors = FALSE)
  colnames(tab) <- c("FOF_status", "level", "n")
  
  if (nrow(tab) == 0L) {
    # Palauta vain tyhjä header, jos data puuttuu
    return(
      tibble(
        Variable    = header_label,
        Without_FOF = "",
        With_FOF    = "",
        P_value     = ""
      )
    )
  }
  
  tab <- tab %>%
    group_by(FOF_status) %>%
    mutate(
      denom = sum(n),
      pct   = ifelse(denom > 0, round(100 * n / denom), NA_real_)
    ) %>%
    ungroup()
  
  get_cell <- function(level_value, fof_value) {
    row <- tab %>%
      filter(level == level_value, FOF_status == fof_value)
    if (nrow(row) == 0L || row$denom[1] == 0L) {
      "0(0)"
    } else {
      paste0(row$n[1], "(", row$pct[1], ")")
    }
  }
  
  # Header-rivi + luokat
  p_overall <- fun_pvalue_cat(f, g)
  
  rows_list <- list(
    tibble(
      Variable    = header_label,
      Without_FOF = "",
      With_FOF    = "",
      P_value     = format_pvalue(p_overall)
    )
  )
  
  for (lvl in levels_f) {
    rows_list[[length(rows_list) + 1L]] <- tibble(
      Variable    = paste0("  ", lvl),
      Without_FOF = get_cell(lvl, group0),
      With_FOF    = get_cell(lvl, group1),
      P_value     = ""
    )
  }
  
  bind_rows(rows_list)
}


## 4.8 P-arvo yhdelle kategoriatasolle (esim. "Good" vs ei-Good)

fun_pvalue_cat_level <- function(factor_var, group, level_value) {
  idx <- !is.na(factor_var) & !is.na(group)
  f_use <- droplevels(factor_var[idx])
  g_use <- droplevels(group[idx])
  
  if (length(unique(g_use)) < 2L) {
    return(NA_real_)
  }
  
  # 2x2-taulukko: FOF_status x (tasolla / ei tasolla)
  tab <- table(g_use, f_use == level_value)
  
  chi_res <- tryCatch(
    suppressWarnings(stats::chisq.test(tab, correct = FALSE)),
    error = function(e) NULL
  )
  
  if (!is.null(chi_res)) {
    if (any(chi_res$expected < 5)) {
      p <- stats::fisher.test(tab)$p.value
    } else {
      p <- chi_res$p.value
    }
  } else {
    p <- stats::fisher.test(tab)$p.value
  }
  
  p
}

## 4.9 Yleinen helper moniluokkaisille (SRH, Alcohol, SRM, Walk500):
## header: n(100) / n(100) + kokonais-p
## alarivit: tason n(%) + oma p-arvo (tasolla vs ei tasolla, EXPLORATORY)

make_multicat_rows_with_level_p <- function(data, var_name, header_label,
                                            group0 = group0_lvl, group1 = group1_lvl) {
  f <- data[[var_name]]
  g <- data$FOF_status
  
  idx <- !is.na(f) & !is.na(g)
  f_use <- droplevels(f[idx])
  g_use <- droplevels(g[idx])
  
  if (length(f_use) == 0L) {
    return(
      tibble(
        Variable    = header_label,
        Without_FOF = "",
        With_FOF    = "",
        P_value     = ""
      )
    )
  }
  
  levels_f <- levels(f_use)
  
  # Ristiintaulukko prosentteja varten
  tab <- as.data.frame(table(g_use, f_use), stringsAsFactors = FALSE)
  colnames(tab) <- c("FOF_status", "level", "n")
  
  tab <- tab %>%
    group_by(FOF_status) %>%
    mutate(
      denom = sum(n),
      pct   = ifelse(denom > 0, round(100 * n / denom), NA_real_)
    ) %>%
    ungroup()
  
  # Helper solujen lukemiseen
  get_cell <- function(level_value, fof_value) {
    row <- tab %>%
      filter(level == level_value, FOF_status == fof_value)
    if (nrow(row) == 0L || row$denom[1] == 0L) {
      "0(0)"
    } else {
      paste0(row$n[1], "(", row$pct[1], ")")
    }
  }
  
  # Header-rivin n(%) = mittauksen saaneet per FOF-ryhmä; prosentti = 100
  header_sums <- tab %>%
    group_by(FOF_status) %>%
    summarise(
      n_total = sum(n),
      .groups = "drop"
    )
  
  get_header_cell <- function(fof_value) {
    row <- header_sums %>% filter(FOF_status == fof_value)
    if (nrow(row) == 0L || is.na(row$n_total[1]) || row$n_total[1] == 0L) {
      ""
    } else {
      paste0(row$n_total[1], "(100)")
    }
  }
  
  header_without <- get_header_cell(group0)
  header_with    <- get_header_cell(group1)
  
  # Kokonais-p-arvo (koko jakaumalle)
  p_overall <- fun_pvalue_cat(f, g)
  
  rows_list <- list(
    tibble(
      Variable    = header_label,
      Without_FOF = header_without,
      With_FOF    = header_with,
      P_value     = format_pvalue(p_overall)
    )
  )
  
  # Tasokohtaiset rivit + oma p-arvo tasolle (esim. Good vs ei-Good)
  for (lvl in levels_f) {
    p_lvl <- fun_pvalue_cat_level(f, g, level_value = lvl)
    
    rows_list[[length(rows_list) + 1L]] <- tibble(
      Variable    = paste0("  ", lvl),
      Without_FOF = get_cell(lvl, group0),
      With_FOF    = get_cell(lvl, group1),
      P_value     = format_pvalue(p_lvl)
    )
  }
  
  bind_rows(rows_list)
}

# ==============================================================================
# 5. Taulukon yksittäiset lohkot --------------------------------------
# ==============================================================================

## 5.1 Women, n (%)

vals_women <- format_n_pct(analysis_data_rec$woman,
                           analysis_data_rec$FOF_status, event = 1L)
p_women <- fun_pvalue_cat(analysis_data_rec$woman,
                          analysis_data_rec$FOF_status)

tab_women <- tibble(
  Variable    = "Women, n (%)",
  Without_FOF = vals_women[group0_lvl],
  With_FOF    = vals_women[group1_lvl],
  P_value     = format_pvalue(p_women)
)

## 5.2 Age, mean (SD) – ikä kokonaislukuina

vals_age <- format_mean_sd(analysis_data_rec$age,
                           analysis_data_rec$FOF_status, digits = 0)
p_age <- fun_pvalue_cont(analysis_data_rec$age,
                         analysis_data_rec$FOF_status)

tab_age <- tibble(
  Variable    = "Age, mean (SD)",
  Without_FOF = vals_age[group0_lvl],
  With_FOF    = vals_age[group1_lvl],
  P_value     = format_pvalue(p_age)
)

## 5.3 Diseases, n (%): header + diagnoosikohtaiset rivit

# "Any disease" = vähintään yksi: diabetes / alzheimer / parkinson / AVH
any_disease <- with(
  analysis_data_rec,
  (diabetes == 1) | (alzheimer == 1) | (parkinson == 1) | (AVH == 1)
)

vals_any_disease <- format_n_pct(as.integer(any_disease),
                                 analysis_data_rec$FOF_status,
                                 event = 1L)
p_any_disease    <- fun_pvalue_cat(as.integer(any_disease),
                                   analysis_data_rec$FOF_status)

tab_diseases_header <- tibble(
  Variable    = "Diseases, n (%)",
  Without_FOF = vals_any_disease[group0_lvl],
  With_FOF    = vals_any_disease[group1_lvl],
  P_value     = format_pvalue(p_any_disease)
)

tab_diabetes <- make_binary_row(analysis_data_rec, "diabetes",    "Diabetes")
tab_dementia <- make_binary_row(analysis_data_rec, "alzheimer",   "Dementia")
tab_parkin   <- make_binary_row(analysis_data_rec, "parkinson",   "Parkinson's")
tab_cva      <- make_binary_row(analysis_data_rec, "AVH",         "Cerebrovascular Accidents")
tab_comorb   <- make_binary_row(analysis_data_rec, "comorbidity", "Comorbidity (>1 disease)")

tab_diseases <- bind_rows(
  tab_diseases_header,
  tab_diabetes,
  tab_dementia,
  tab_parkin,
  tab_cva,
  tab_comorb
)

## 5.4 Self-rated Health, n (%)
## Header: n(100) per FOF-ryhmä (vain ei-NA SRH)
## Alarivit: Good / Moderate / Bad, jokaiselle oma p-arvo (tasolla vs ei tasolla)

tab_SRH <- make_multicat_rows_with_level_p(
  data         = analysis_data_rec,
  var_name     = "SRH_3class_table",
  header_label = "Self-rated Health, n (%)"
)

## 5.5 Mikkeli Osteoporosis Index, mean (SD)

vals_MOI <- format_mean_sd(analysis_data_rec$MOIindeksiindeksi,
                           analysis_data_rec$FOF_status, digits = 1)
p_MOI <- fun_pvalue_cont(analysis_data_rec$MOIindeksiindeksi,
                         analysis_data_rec$FOF_status)

tab_MOI <- tibble(
  Variable    = "Mikkeli Osteoporosis Index, mean (SD)",
  Without_FOF = vals_MOI[group0_lvl],
  With_FOF    = vals_MOI[group1_lvl],
  P_value     = format_pvalue(p_MOI)
)

## 5.6 Body Mass Index, mean (SD)

vals_BMI <- format_mean_sd(analysis_data_rec$BMI,
                           analysis_data_rec$FOF_status, digits = 1)
p_BMI <- fun_pvalue_cont(analysis_data_rec$BMI,
                         analysis_data_rec$FOF_status)

tab_BMI <- tibble(
  Variable    = "Body Mass Index, mean (SD)",
  Without_FOF = vals_BMI[group0_lvl],
  With_FOF    = vals_BMI[group1_lvl],
  P_value     = format_pvalue(p_BMI)
)

## 5.7 Smoked, n (%)

vals_smoked <- format_n_pct(analysis_data_rec$tupakointi,
                            analysis_data_rec$FOF_status, event = 1L)
p_smoked <- fun_pvalue_cat(analysis_data_rec$tupakointi,
                           analysis_data_rec$FOF_status)

tab_smoked <- tibble(
  Variable    = "Smoked, n (%)",
  Without_FOF = vals_smoked[group0_lvl],
  With_FOF    = vals_smoked[group1_lvl],
  P_value     = format_pvalue(p_smoked)
)

## 5.8 Alcohol, n (%)
## Header: n(100) per FOF-ryhmä (alkoholi-mittauksen saaneet)
## Alarivit: No / Moderate / Large, jokaiselle oma p-arvo (tasolla vs ei tasolla)

tab_alcohol <- make_multicat_rows_with_level_p(
  data         = analysis_data_rec,
  var_name     = "alcohol_3class_table",
  header_label = "Alcohol, n (%)"
)

## 5.9 Self-Rated Mobility, n (%)

tab_SRM <- make_multicat_rows_with_level_p(
  data         = analysis_data_rec,
  var_name     = "SRM_3class_table",
  header_label = "Self-Rated Mobility, n (%)"
)

## 5.10 Walking 500 m, n (%)

tab_Walk500 <- make_multicat_rows_with_level_p(
  data         = analysis_data_rec,
  var_name     = "Walk500m_3class_table",
  header_label = "Walking 500 m, n (%)"
)

## 5.11 Balance difficulties, n (%)

vals_balance <- format_n_pct(analysis_data_rec$tasapainovaikeus,
                             analysis_data_rec$FOF_status, event = 1L)
p_balance <- fun_pvalue_cat(analysis_data_rec$tasapainovaikeus,
                            analysis_data_rec$FOF_status)

tab_balance <- tibble(
  Variable    = "Balance difficulties, n (%)",
  Without_FOF = vals_balance[group0_lvl],
  With_FOF    = vals_balance[group1_lvl],
  P_value     = format_pvalue(p_balance)
)

## 5.12 Fallen, n (%)

vals_fallen <- format_n_pct(analysis_data_rec$kaatuminen,
                            analysis_data_rec$FOF_status, event = 1L)
p_fallen <- fun_pvalue_cat(analysis_data_rec$kaatuminen,
                           analysis_data_rec$FOF_status)

tab_fallen <- tibble(
  Variable    = "Fallen, n (%)",
  Without_FOF = vals_fallen[group0_lvl],
  With_FOF    = vals_fallen[group1_lvl],
  P_value     = format_pvalue(p_fallen)
)

## 5.13 Fractures, n (%)

vals_fract <- format_n_pct(analysis_data_rec$murtumia,
                           analysis_data_rec$FOF_status, event = 1L)
p_fract <- fun_pvalue_cat(analysis_data_rec$murtumia,
                          analysis_data_rec$FOF_status)

tab_fractures <- tibble(
  Variable    = "Fractures, n (%)",
  Without_FOF = vals_fract[group0_lvl],
  With_FOF    = vals_fract[group1_lvl],
  P_value     = format_pvalue(p_fract)
)

## 5.14 Pain VAS, mean (SD)

vals_pain <- format_mean_sd(analysis_data_rec$PainVAS0,
                            analysis_data_rec$FOF_status, digits = 1)
p_pain <- fun_pvalue_cont(analysis_data_rec$PainVAS0,
                          analysis_data_rec$FOF_status)

tab_pain <- tibble(
  Variable    = "Pain (Visual Analog Scale), mm, mean (SD)",
  Without_FOF = vals_pain[group0_lvl],
  With_FOF    = vals_pain[group1_lvl],
  P_value     = format_pvalue(p_pain)
)

# ==============================================================================
# 6. Bind rows & nimeä sarakkeet Table 1 -muotoon -----------------------
# ==============================================================================

baseline_table_raw <- bind_rows(
  tab_women,    # 1
  tab_age,      # 2
  tab_diseases, # 3) header + 4 diagnoosiriviä
  tab_SRH,      # 4) Self-rated Health (header + 3 riviä)
  tab_MOI,      # 5
  tab_BMI,      # 6
  tab_smoked,   # 7
  tab_alcohol,  # 8) header + 3 riviä
  tab_SRM,      # 9) header + 3 riviä
  tab_Walk500,  # 10) header + 3 riviä
  tab_balance,  # 11
  tab_fallen,   # 12
  tab_fractures,# 13
  tab_pain      # 14
)

## Lopulliset sarakenimet

col_without <- paste0("Without FOF\nn=", N_group0)
col_with    <- paste0("With FOF\nn=", N_group1)

baseline_table <- baseline_table_raw %>%
  rename(
    " "               = Variable,
    !!col_without     := Without_FOF,
    !!col_with        := With_FOF,
    "P-value"         := P_value
  )

## Alaviite attribuuttina (manuaalista raportointia varten)

table_footnote <- paste(
  "Abbreviations: FOF = Fear of Falling; BMI = Body Mass Index;",
  "SD = Standard Deviation; VAS = Visual Analog Scale.",
  "P-values calculated using t-tests for continuous variables",
  "and chi-square tests for categorical variables.",
  sep = " "
)
attr(baseline_table, "footnote") <- table_footnote

# ==============================================================================
# 7. Tulostus, tallennus ja manifestin päivitys -----------------------------
# ==============================================================================

## Konsolitulostus (valinnainen)

print(baseline_table)

## Tallennus CSV + HTML (K14/outputs)

basename_out <- "K14_baseline_by_FOF"
save_table_csv_html(baseline_table, basename_out, out_dir = outputs_dir)

## Manifest: lisätään rivi Table 1 -taulukosta

manifest_rows <- tibble(
  script      = script_label,
  type        = "table",
  filename    = file.path(script_label, paste0(basename_out, ".csv")),
  description = "Baseline characteristics by FOF-status (Table 1; unadjusted)."
)

if (!file.exists(manifest_path)) {
  utils::write.table(
    manifest_rows,
    file      = manifest_path,
    sep       = ",",
    row.names = FALSE,
    col.names = TRUE,
    append    = FALSE,
    qmethod   = "double"
  )
} else {
  utils::write.table(
    manifest_rows,
    file      = manifest_path,
    sep       = ",",
    row.names = FALSE,
    col.names = FALSE,
    append    = TRUE,
    qmethod   = "double"
  )
}

message("K14: baseline table by FOF-status tallennettu ja manifest päivitetty.")

# End of K14.R
