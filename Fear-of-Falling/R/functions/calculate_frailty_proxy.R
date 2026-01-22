#' Calculate Modified Fried Frailty Proxy Scores
#'
#' This function calculates three variations of the Fried Frailty Phenotype:
#' 1. Option A: Categorical (Classic 0-5 scale)
#' 2. Option B: Continuous (Z-score based)
#' 3. Option C: Modified (PCA or 4-item proxy)
#'
#' @param data A data frame containing the raw variables.
#' @param mapping A named list mapping abstract components to column names.
#'   Defaults: list(
#'     id = "id",
#'     grip = "handgrip_strength",
#'     gait = "gait_speed",
#'     cesd = "cesd_total",
#'     activity = "physical_activity",
#'     weight_loss = "weight_loss",
#'     sex = "sex",
#'     height = "height",
#'     test_reason_grip = "reason_grip", # Optional column for "unable to test"
#'     test_reason_gait = "reason_gait"  # Optional column for "unable to test"
#'   )
#' @return A data frame with added frailty score columns.
#' @importFrom dplyr mutate case_when across select everything
#' @importFrom stats prcomp predict sd quantile
#' @export
calculate_frailty_scores <- function(data, mapping = list()) {

  # Default mapping
  default_mapping <- list(
    id = "id",
    grip = "handgrip_strength",
    gait = "gait_speed",
    cesd = "cesd_total",
    activity = "physical_activity",
    weight_loss = "weight_loss",
    sex = "sex",
    height = "height", # Used for BMI adjustment logic if needed, or simple standardization
    test_reason_grip = "reason_grip",
    test_reason_gait = "reason_gait"
  )

  # Merge provided mapping with defaults
  map <- utils::modifyList(default_mapping, mapping)

  # Check if required columns exist (soft check)
  req_vars <- c(map$grip, map$gait, map$cesd, map$activity, map$weight_loss)
  missing_vars <- setdiff(req_vars, names(data))

  if (length(missing_vars) > 0) {
    warning("Missing columns for frailty calculation: ", paste(missing_vars, collapse = ", "),
            ". Calculation may be incomplete.")
  }

  # --- Helper: Apply 'Unable to Test' Logic ---
  # If a reason column exists and indicates inability, impute worst score (0)

  df <- data

  # Grip Imputation
  if (map$test_reason_grip %in% names(df) && map$grip %in% names(df)) {
    df[[map$grip]] <- ifelse(
      is.na(df[[map$grip]]) &
        (grepl("unable", df[[map$test_reason_grip]], ignore.case = TRUE) |
         grepl("estetta", df[[map$test_reason_grip]], ignore.case = TRUE)),
      0,
      df[[map$grip]]
    )
  }

  # Gait Imputation
  if (map$test_reason_gait %in% names(df) && map$gait %in% names(df)) {
    df[[map$gait]] <- ifelse(
      is.na(df[[map$gait]]) &
        (grepl("unable", df[[map$test_reason_gait]], ignore.case = TRUE) |
         grepl("estetta", df[[map$test_reason_gait]], ignore.case = TRUE)),
      0,
      df[[map$gait]]
    )
  }

  # --- Option A: Categorical Fried (0-5) ---
  # Using classic cut-offs or lowest 20% rule approximation
  # Directionality:
  # Grip: LOW is bad (<20kg F, <30kg M)
  # Gait: LOW is bad (<0.8 m/s)
  # CESD: HIGH is bad (Exhaustion)
  # Activity: LOW is bad
  # Weight Loss: HIGH is bad (>4.5kg) or binary YES

  # We assume 'sex' is coded 0=Female, 1=Male or similar.
  # Let's try to detect or use robust logic.
  # If sex is missing, use general cutoffs.

  df <- df %>%
    dplyr::mutate(
      # 1. Weakness (Grip)
      score_weakness = dplyr::case_when(
        is.na(.data[[map$grip]]) ~ NA_real_,
        !is.null(df[[map$sex]]) & df[[map$sex]] %in% c("Female", "female", "F", 0) & .data[[map$grip]] < 20 ~ 1,
        !is.null(df[[map$sex]]) & df[[map$sex]] %in% c("Male", "male", "M", 1) & .data[[map$grip]] < 30 ~ 1,
        .data[[map$grip]] < 26 ~ 1, # General cutoff if sex unknown
        TRUE ~ 0
      ),

      # 2. Slowness (Gait)
      score_slowness = dplyr::case_when(
        is.na(.data[[map$gait]]) ~ NA_real_,
        .data[[map$gait]] < 0.8 ~ 1,
        TRUE ~ 0
      ),

      # 3. Exhaustion (CES-D)
      # Assuming CES-D total score. Cutoff > 16 often used for depression,
      # but for frailty often 2 specific questions.
      # Here we assume the input is the component score or total.
      score_exhaustion = dplyr::case_when(
        is.na(.data[[map$cesd]]) ~ NA_real_,
        .data[[map$cesd]] >= 16 ~ 1, # Common clinical cutoff
        TRUE ~ 0
      ),

      # 4. Low Activity
      # If numeric (kcal/steps), lowest 20% or fixed.
      # Placeholder logic: Lowest quintile in sample
      score_activity = dplyr::case_when(
        is.na(.data[[map$activity]]) ~ NA_real_,
        .data[[map$activity]] <= stats::quantile(.data[[map$activity]], 0.2, na.rm=TRUE) ~ 1,
        TRUE ~ 0
      ),

      # 5. Shrinking (Weight Loss)
      # If binary (0/1), use as is. If kg, > 4.5
      score_shrinking = dplyr::case_when(
        is.na(.data[[map$weight_loss]]) ~ NA_real_,
        .data[[map$weight_loss]] >= 4.5 ~ 1,
        TRUE ~ 0
      )
    )

  # Sum for Categorical
  # Note: rowSums with na.rm=TRUE would count missing as 0 (robust).
  # Standard Fried requires all 5 or imputation.
  # Here we propagate NA if any is missing, unless handled by MICE beforehand.
  # However, common modification is: if >=3 present, impute.
  # We stick to Strict or NA propagation here as per user request for MICE handling separately.

  df$fried_score_cat <- rowSums(df[, c("score_weakness", "score_slowness", "score_exhaustion", "score_activity", "score_shrinking")], na.rm = FALSE)

  df <- df %>%
    dplyr::mutate(
      fried_class = dplyr::case_when(
        is.na(fried_score_cat) ~ NA_character_,
        fried_score_cat == 0 ~ "Robust",
        fried_score_cat >= 1 & fried_score_cat <= 2 ~ "Pre-frail",
        fried_score_cat >= 3 ~ "Frail",
        TRUE ~ NA_character_
      )
    )

  # --- Option B: Continuous Frailty Score (Z-score based) ---
  # Standardize each component. Direction: Higher = Frailer.

  calc_z <- function(x, invert = FALSE) {
    if (all(is.na(x))) return(rep(NA, length(x)))
    z <- (x - mean(x, na.rm = TRUE)) / stats::sd(x, na.rm = TRUE)
    if (invert) return(-z) else return(z)
  }

  df$z_grip <- calc_z(df[[map$grip]], invert = TRUE)
  df$z_gait <- calc_z(df[[map$gait]], invert = TRUE)
  df$z_cesd <- calc_z(df[[map$cesd]], invert = FALSE) # High CESD is bad/frail
  df$z_activity <- calc_z(df[[map$activity]], invert = TRUE) # High Activity is good -> invert
  df$z_weight <- calc_z(df[[map$weight_loss]], invert = FALSE) # High weight loss is bad

  # Mean of available Z-scores (require at least 3)
  z_cols <- c("z_grip", "z_gait", "z_cesd", "z_activity", "z_weight")

  df$fried_z_score <- apply(df[, z_cols], 1, function(x) {
    if (sum(!is.na(x)) >= 3) return(mean(x, na.rm = TRUE)) else return(NA)
  })

  # --- Option C: Modified Physical Proxy (PCA) ---
  # Use primary physical measures: Grip, Gait, Activity.

  pca_vars <- c(map$grip, map$gait, map$activity)

  # Only attempt PCA if columns exist
  if (all(pca_vars %in% names(df))) {
      pca_data <- df[, pca_vars]

      # Only complete cases for PCA training
      complete_pca <- stats::complete.cases(pca_data)

      if (sum(complete_pca) > 10) {
        # PCA: We expect the first component to represent "physical capacity"
        pca_res <- stats::prcomp(pca_data[complete_pca, ], scale. = TRUE, center = TRUE)

        # Check direction: Does PC1 correlate positively or negatively with Grip?
        # We want the output 'fried_pca' to be High = Frail (Bad).

        loading_grip <- pca_res$rotation[map$grip, 1]

        # Predict for all
        pc1_scores <- rep(NA, nrow(df))
        pc1_scores[complete_pca] <- pca_res$x[, 1]

        if (loading_grip > 0) {
          # High score = High Grip = Good. Invert to get Frailty.
          df$fried_pca <- -pc1_scores
        } else {
          # High score = Low Grip = Bad (already Frailty direction).
          df$fried_pca <- pc1_scores
        }
      } else {
        df$fried_pca <- NA_real_
        warning("Not enough complete cases for PCA option.")
      }
  } else {
      df$fried_pca <- NA_real_
      warning("Columns for PCA missing: ", paste(setdiff(pca_vars, names(df)), collapse=", "))
  }

  return(df)
}
