
# KAAOS 10: Visualization of Longitudinal Analysis Results for Fear of Falling & Functional Performance
# [K10.R]

# Paketit
library(dplyr)
library(ggplot2)
library(emmeans)   # LS-keskiarvot / emmeans :contentReference[oaicite:0]{index=0}


# --- K10: oma outputs-kansio ---
script_label <- "K10"

outputs_dir <- file.path(
  "R-scripts", "K10", "outputs"
)

if (!dir.exists(outputs_dir)) {
  dir.create(outputs_dir, recursive = TRUE)
}

script_dir <- file.path(outputs_dir, script_label)
if (!dir.exists(script_dir)) {
  dir.create(script_dir, recursive = TRUE)
}

# ========================================================================================================
#  Kuvioiden piirto: Muutos fyysisessä toimintakyvyssä (Delta Composite Z) FOF-ryhmittäin
# ========================================================================================================
## 1.1 Emmeans FOF-ryhmille
## - cComposite_Z0 = 0 (keskitetty lähtötaso)
## - muut kovariaatit (Age, BMI) oletuksena keskiarvassa,
##   Sex tasapainotettuna ellei muuta määritetä

emm_fof <- emmeans(
  model_jn_c,
  specs = "FOF_status",
  at = list(cComposite_Z0 = 0)
) %>%
  as.data.frame() %>%
  dplyr::mutate(
    FOF_label = dplyr::recode_factor(
      as.character(FOF_status),
      `0` = "Ei kaatumisen pelkoa",
      `1` = "Kaatumisen pelko"
    )
  )


## 1.2 Y-akselin rajat: riittävän laaja skaala, nollaviiva mukaan

y_range <- range(c(emm_fof$lower.CL, emm_fof$upper.CL, 0), na.rm = TRUE)
y_pad   <- 0.1 * diff(y_range)  # hieman tilaa ylä- ja alapuolelle
y_limits <- c(y_range[1] - y_pad, y_range[2] + y_pad)

## 1.3 Kuvan piirto

p_adj <- ggplot(emm_fof, aes(x = FOF_label, y = emmean)) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_point(size = 3) +
  geom_errorbar(
    aes(ymin = lower.CL, ymax = upper.CL),
    width = 0.15
  ) +
  coord_cartesian(ylim = y_limits) +
  theme_minimal(base_size = 13) +
  labs(
    x = "FOF-ryhmä",
    y = "Ennustettu muutos fyysisessä toimintakyvyssä (Δ Composite Z)",
    title    = "Vakioidut keskiarvot Δ Composite Z -muutokselle",
    subtitle = "FOF 0 vs 1, vakioitu iän, sukupuolen, BMI:n ja lähtötason (cComposite_Z0 = 0) mukaan"
  )

p_adj

# 1) Vakioidut keskiarvot (p_adj)
ggplot2::ggsave(
  filename = file.path(script_dir,
                       paste0(script_label, "_fof_delta_composite_adj_means.png")),
  plot    = p_adj,
  width   = 6,
  height  = 4,
  dpi     = 300
)

# ========================================================================================================
#  Kuvioiden piirto: Raakadatan perusteella lasketut ryhmäkeskiarvot ja 95 % CI
# ========================================================================================================

## 2. Raakadatan perusteella lasketut ryhmäkeskiarvot ja 95 % CI
library(dplyr)
library(ggplot2)

## 2.1 Ryhmäkeskiarvot ja 95 % CI raakadatan perusteella
raw_summary <- analysis_data_cc %>%
  dplyr::mutate(
    FOF_label = dplyr::recode_factor(
      as.character(FOF_status),
      `0` = "Ei kaatumisen pelkoa",
      `1` = "Kaatumisen pelko"
    )
  ) %>%
  dplyr::group_by(FOF_label) %>%
  dplyr::summarise(
    mean_delta = mean(Delta_Composite_Z, na.rm = TRUE),
    sd_delta   = sd(Delta_Composite_Z, na.rm = TRUE),
    n          = sum(!is.na(Delta_Composite_Z)),
    se_delta   = sd_delta / sqrt(n),
    lower      = mean_delta - qt(0.975, df = n - 1) * se_delta,
    upper      = mean_delta + qt(0.975, df = n - 1) * se_delta,
    .groups    = "drop"
  )

## 2.2 Hedges g -arvo kuvatekstiin
## HUOM: tarkista sarakkeen nimi str(g_df): usein se on esim. "Hedges_g" tai "SMD".
g_hat <- g_df$Hedges_g[1]

y_range2 <- range(c(raw_summary$lower, raw_summary$upper, 0), na.rm = TRUE)
y_pad2   <- 0.1 * diff(y_range2)
y_limits2 <- c(y_range2[1] - y_pad2, y_range2[2] + y_pad2)

p_raw <- ggplot(raw_summary, aes(x = FOF_label, y = mean_delta)) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_point(size = 3) +
  geom_errorbar(
    aes(ymin = lower, ymax = upper),
    width = 0.15
  ) +
  coord_cartesian(ylim = y_limits2) +
  theme_minimal(base_size = 13) +
  labs(
    x = "FOF-ryhmä",
    y = "Keskimääräinen muutos fyysisessä toimintakyvyssä (Δ Composite Z)",
    title = "Raakakeskiarvot Δ Composite Z -muutokselle FOF-ryhmittäin",
    subtitle = paste0("Hedges g (FOF 1 vs 0) ≈ ", round(g_hat, 2),
                      " → pieni efektikoko")
  )

p_raw

# 2) Raakakeskiarvot + Hedges g (p_raw)
ggplot2::ggsave(
  filename = file.path(script_dir,
                       paste0(script_label, "_fof_delta_composite_raw_means.png")),
  plot    = p_raw,
  width   = 6,
  height  = 4,
  dpi     = 300
)
# # KAAOS 1.4: Effect Size Calculations for Fear of Falling & Functional Performance
# # [K1.4.effect_sizes.R]
#       sum(!is.na(Follow_up[kaatumisenpelkoOn == 0])),
#       mean(Follow_up[kaatumisenpelkoOn == 1], na.rm = TRUE),
#       sd(Follow_up[kaatumisenpelkoOn == 1], na.rm = TRUE),
#       sum(!is.na(Follow_up[kaatumisenpelkoOn == 1]))
#     ),
#     .groups = "drop"
#   ) %>%
#   rename(Follow_up_d = d)
# 
# # 7: Combine All Effect Size Results
# effect_sizes <- baseline_effect %>%
#   left_join(change_effect, by = c("Test", "kaatumisenpelkoOn")) %>%
#   left_join(change_between_effect, by = "Test") %>%
#   left_join(follow_up_effect, by = "Test")
# 
# # 8: Label Effect Sizes
# effect_sizes <- effect_sizes %>%
#   rowwise() %>%
#   mutate(
#     Baseline_d_label = effect_size_label(Baseline_d),
#     Change_d_label = effect_size_label(Change_d),
#     Change_d_between_label = effect_size_label(Change_d_between),
#     Follow_up_d_label = effect_size_label(Follow_up_d)
#   ) %>%
#   ungroup() %>%
#   select(
#     kaatumisenpelkoOn, Test,
#     Baseline_d, Baseline_d_label,
#     Change_d, Change_d_label,
#     Change_d_between, Change_d_between_label,
#     Follow_up_d, Follow_up_d_label
#   )     

message("Kuvat tallentuvat kansioon: ", normalizePath(script_dir))
# End of K10.R
