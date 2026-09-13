# Deterministic derived GENERAL_FI candidate-state mappings.
# Source data and canonical ledgers are immutable inputs to these functions.

RAW015_MAPPING_VERSION <- "GENERAL_FI_RAW015_RESEARCHER_OPERATIONALIZATION_1.0.0"
RAW015_SOURCE_FIELD <- "kuulo_0_hyv_kuulo_1_heikentynyt_2_kuulolaite_3_kuuro_4_ei_tietoa"

derive_general_fi_raw015 <- function(source_state) {
  state <- trimws(as.character(source_state))
  allowed <- c("0", "1", "2", "3", "4")
  invalid <- is.na(source_state) | is.na(state) | state == "" | !(state %in% allowed)

  if (any(invalid)) {
    stop(
      sprintf("RAW-015 fail-closed: %d input state(s) outside approved contract", sum(invalid)),
      call. = FALSE
    )
  }

  score <- unname(c("0" = 0, "1" = 0.5, "2" = 0.5, "3" = 1, "4" = NA_real_)[state])
  qc_class <- ifelse(state == "4", "SOURCE_DEFINED_MISSING", "SCORED_VALID")

  out <- data.frame(
    raw015_deficit = as.numeric(score),
    raw015_qc_class = qc_class,
    stringsAsFactors = FALSE
  )
  attr(out, "candidate_id") <- "RAW-015"
  attr(out, "source_field") <- RAW015_SOURCE_FIELD
  attr(out, "mapping_version") <- RAW015_MAPPING_VERSION
  attr(out, "mapping_authority") <- "RESEARCHER_OPERATIONALIZATION_APPROVED_2026-09-03"
  out
}

STEP6B14_POLICY_VERSION <- "GENERAL_FI_STEP6B14_UNRESOLVED_STATE_POLICY_1.0.0"
RAW037_SOURCE_FIELD <- "tk_yhdell_jalalla_seisominen_oikea_sek_e1_ei_tietoa"
RAW042_SOURCE_FIELD <- "tk_10_metrin_k_velynopeus_sek_e_ei_pysty_k_vell_e1_ei_tietoa"

derive_general_fi_step6b14_state <- function(candidate_id, source_state) {
  if (length(candidate_id) != 1L || !(candidate_id %in% c("RAW-037", "RAW-042"))) {
    stop("Step 6B.14 fail-closed: candidate_id must be RAW-037 or RAW-042", call. = FALSE)
  }

  original_state <- as.character(source_state)
  state <- trimws(original_state)
  is_blank <- is.na(source_state) | is.na(state) | state == ""
  numeric_state <- suppressWarnings(as.numeric(state))
  is_numeric <- !is_blank & !is.na(numeric_state)

  if (candidate_id == "RAW-037") {
    is_unresolved <- is_numeric & numeric_state == 43602
    is_missing <- !is_blank & state == "E1"
    is_valid <- is_numeric & !is_unresolved & numeric_state >= 0 & numeric_state <= 60
    is_unapproved <- !(is_unresolved | is_missing | is_valid)
    unresolved_reason <- ifelse(is_unresolved, "ANOMALOUS_43602_NO_AUTHORITATIVE_PHYSIOLOGICAL_OR_SCORING_MEANING", NA_character_)
    source_field <- RAW037_SOURCE_FIELD
  } else {
    is_unresolved <- !is_blank & state == "E"
    is_missing <- !is_blank & state == "E1"
    is_valid <- is_numeric & numeric_state >= 0
    is_unapproved <- !(is_unresolved | is_missing | is_valid)
    unresolved_reason <- ifelse(is_unresolved, "EXACT_UPPERCASE_E_HAS_NO_AUTHORITATIVE_TIME_FIELD_HEALTH_OR_SCORING_MEANING", NA_character_)
    source_field <- RAW042_SOURCE_FIELD
  }

  if (any(is_unapproved)) {
    stop(sprintf("%s Step 6B.14 fail-closed: %d state(s) outside approved policy", candidate_id, sum(is_unapproved)), call. = FALSE)
  }

  qc_class <- ifelse(is_unresolved, "UNRESOLVED_SOURCE_STATE", ifelse(is_missing, "SOURCE_DEFINED_MISSING", "VALID_UNSCORED_PENDING_SCORING"))
  out <- data.frame(
    original_source_state = original_state,
    deficit = NA_real_,
    qc_class = qc_class,
    unresolved_reason = unresolved_reason,
    include_in_available_deficit_denominator = is_valid,
    stringsAsFactors = FALSE
  )
  attr(out, "candidate_id") <- candidate_id
  attr(out, "source_field") <- source_field
  attr(out, "policy_version") <- STEP6B14_POLICY_VERSION
  attr(out, "policy_authority") <- "RESEARCHER_OPERATIONALIZATION_APPROVED_2026-09-04"
  out
}


RAW039_MAPPING_VERSION <- "GENERAL_FI_RAW039_LUSARDI_CUTPOINT_1.1.0"
RAW039_SOURCE_FIELD <- "tk_tuolilta_nousu_5_krt_sek_e_ei_pysty_nousta_e1_ei_tietoa"

derive_general_fi_raw039 <- function(source_state) {
  original_state <- as.character(source_state)
  state <- trimws(original_state)
  decimal_comma <- !is.na(state) & grepl("^[0-9]+,[0-9]+$", state)
  normalized_numeric_state <- ifelse(decimal_comma, sub(",", ".", state, fixed = TRUE), state)
  numeric_state <- suppressWarnings(as.numeric(normalized_numeric_state))
  is_numeric <- !is.na(source_state) & !is.na(state) & state != "" &
    !is.na(numeric_state) & is.finite(numeric_state) & numeric_state >= 0
  is_unable <- !is.na(state) & state == "E"
  is_missing <- !is.na(state) & state == "E1"
  invalid <- !(is_numeric | is_unable | is_missing)

  if (any(invalid)) {
    stop(sprintf("RAW-039 fail-closed: %d input state(s) outside approved numeric/E/E1 contract", sum(invalid)), call. = FALSE)
  }

  score <- ifelse(is_numeric, ifelse(numeric_state < 12, 0, 1), ifelse(is_unable, 1, NA_real_))
  qc_class <- ifelse(is_missing, "SOURCE_DEFINED_MISSING", "SCORED_VALID")
  out <- data.frame(
    original_source_state = original_state,
    raw039_deficit = as.numeric(score),
    raw039_qc_class = qc_class,
    include_in_available_deficit_denominator = !is_missing,
    stringsAsFactors = FALSE
  )
  attr(out, "candidate_id") <- "RAW-039"
  attr(out, "source_field") <- RAW039_SOURCE_FIELD
  attr(out, "mapping_version") <- RAW039_MAPPING_VERSION
  attr(out, "mapping_authority") <- "RESEARCHER_OPERATIONALIZATION_USING_ESTABLISHED_EXTERNAL_CUTPOINT_APPROVED_2026-09-04"
  attr(out, "representation_authority") <- "SOURCE_OWNER_DATA_STEWARD_CONFIRMED_DECIMAL_COMMA_2026-09-06"
  attr(out, "protocol_comparability") <- "PROTOCOL_COMPARABILITY_PARTIAL_NEEDS_RESEARCHER_JUDGMENT_ACCEPTED_FOR_SCORING"
  out
}


# Approved 2026-09-10: seconds only; this is not a deficit mapping.
CANONICAL_BALANCE_AUTHORITY <- paste0(
  "RESEARCHER_OPERATIONALIZATION_INFORMED_BY_SOURCE_CONSTRUCT_AND_",
  "PROJECT_FIELD_LINEAGE"
)

derive_general_fi_canonical_balance <- function(right, left, right_assessment, left_assessment) {
  n <- length(right)
  if (!n || any(c(length(left), length(right_assessment), length(left_assessment)) != n)) {
    stop("Canonical balance: nonempty equal-length inputs required", call. = FALSE)
  }
  original_right <- as.character(right)
  original_left <- as.character(left)
  classify <- function(x, side) {
    x <- as.character(x)
    number <- suppressWarnings(as.numeric(x))
    # No case folding, whitespace cleanup or decimal-comma normalization.
    numeric <- !is.na(x) & grepl("^[0-9]+([.][0-9]+)?$", x) &
      is.finite(number) & number >= 0 & number <= 60
    state <- rep("OTHER", length(x))
    state[numeric] <- "NUMERIC"
    state[!is.na(x) & x == "E1"] <- "E1"
    state[!is.na(x) & x == "e1"] <- "e1"
    if (side == "left") state[!is.na(x) & x == "E"] <- "E"
    if (side == "right") state[!is.na(x) & x == "43602"] <- "BOUNDED"
    list(state = state, number = number)
  }
  r <- classify(right, "right")
  l <- classify(left, "left")
  same <- !is.na(right_assessment) & !is.na(left_assessment) &
    nzchar(trimws(as.character(right_assessment))) &
    nzchar(trimws(as.character(left_assessment))) & right_assessment == left_assessment
  qc <- rep("OTHER_EXECUTION_CRITICAL", n)
  reason <- rep("UNAPPROVED_SOURCE_COMBINATION", n)
  seconds <- rep(NA_real_, n)
  both <- same & r$state == "NUMERIC" & l$state == "NUMERIC"
  right_only <- same & r$state == "NUMERIC" & l$state == "E1"
  left_only <- same & r$state == "E1" & l$state == "NUMERIC"
  missing <- same & r$state == "E1" & l$state == "E1"
  unresolved <- same & ((r$state == "NUMERIC" & l$state %in% c("E", "e1")) |
    (l$state == "NUMERIC" & r$state %in% c("e1", "BOUNDED")))
  seconds[both] <- pmax(r$number[both], l$number[both])
  seconds[right_only] <- r$number[right_only]
  seconds[left_only] <- l$number[left_only]
  qc[both | right_only | left_only] <- "CANONICAL_NUMERIC"
  qc[missing] <- "SOURCE_DEFINED_MISSING"
  qc[unresolved] <- "UNRESOLVED_SOURCE_STATE"
  reason[both] <- "APPROVED_BETTER_SIDE_MAX"
  reason[right_only | left_only] <- "APPROVED_NUMERIC_OPPOSITE_E1"
  reason[missing] <- "BOTH_SOURCE_DEFINED_MISSING"
  reason[unresolved] <- paste(r$state[unresolved], l$state[unresolved], sep = "__")
  reason[!same] <- "ASSESSMENT_BINDING_INVALID"
  out <- data.frame(original_right, original_left, canonical_seconds = seconds,
    canonical_state = qc, derivation_reason = reason,
    include_in_available_deficit_denominator = rep(FALSE, n), stringsAsFactors = FALSE)
  attr(out, "derivation_authority") <- CANONICAL_BALANCE_AUTHORITY
  attr(out, "derivation_version") <- "CANONICAL_BALANCE_DERIVATION_1.0.0"
  attr(out, "source_lineage_ids") <- c("RAW-037", "RAW-038")
  attr(out, "scoring_approved") <- FALSE
  out
}

# P1 approved 2026-09-10. Item scoring only; no participant FI.
BALANCE_P1_AUTHORITY <- paste0("RESEARCHER_OPERATIONALIZATION_INFORMED_BY_TOIMIVA_",
  "CRITERION_ANALYSIS_AND_GENERAL_FI_ORDINAL_SCORING_GUIDANCE")
score_general_fi_balance_p1 <- function(seconds, state) {
  if (!is.numeric(seconds) || !length(seconds) || length(seconds)!=length(state) || anyNA(state))
    stop("Balance P1 invalid input contract",call.=FALSE)
  allowed <- c("CANONICAL_NUMERIC","SOURCE_DEFINED_MISSING","UNRESOLVED_SOURCE_STATE")
  numeric <- state=="CANONICAL_NUMERIC"
  if (any(!state %in% allowed) || any(!is.finite(seconds[numeric])) ||
      any(seconds[numeric]<0 | seconds[numeric]>60) || any(!is.na(seconds[!numeric])) ||
      any(is.nan(seconds))) stop("Balance P1 fail-closed state/value mismatch",call.=FALSE)
  score <- rep(NA_real_,length(seconds))
  score[numeric & seconds==0] <- 1
  score[numeric & seconds>0 & seconds<=5] <- .67
  score[numeric & seconds>5 & seconds<=10] <- .33
  score[numeric & seconds>10] <- 0
  out <- data.frame(balance_deficit=score,canonical_state=state,
    include_in_available_deficit_denominator=numeric,stringsAsFactors=FALSE)
  attr(out,"scoring_authority")<-BALANCE_P1_AUTHORITY
  attr(out,"scoring_version")<-"CANONICAL_BALANCE_P1_1.0.0"
  out
}

# K18 post-scoring extension. Pre-scoring assertions remain unchanged.
qc_balance_p1 <- function(view, scored) {
  required <- c("balance_deficit","canonical_state","include_in_available_deficit_denominator")
  if (!identical(names(scored),required) || nrow(scored)!=nrow(view))
    stop("Balance post-scoring schema/conservation failed",call.=FALSE)
  t<-view$canonical_seconds;s<-view$canonical_state
  if (anyNA(s) || any(!s %in% c("CANONICAL_NUMERIC","SOURCE_DEFINED_MISSING","UNRESOLVED_SOURCE_STATE")))
    stop("Balance post-scoring unexpected state",call.=FALSE)
  numeric<-s=="CANONICAL_NUMERIC"
  if (any(!is.finite(t[numeric])) || any(t[numeric]<0 | t[numeric]>60) ||
      any(!is.na(t[!numeric])) || any(is.nan(t))) stop("Balance post-scoring invalid seconds",call.=FALSE)
  expected<-rep(NA_real_,length(t))
  for(i in which(numeric)) expected[i]<-if(t[i]==0) 1 else if(t[i]<=5) .67 else if(t[i]<=10) .33 else 0
  pass<-c(identical(scored$canonical_state,s),identical(scored$balance_deficit,expected),
    identical(scored$include_in_available_deficit_denominator,numeric),
    identical(attr(scored,"scoring_authority"),BALANCE_P1_AUTHORITY),
    identical(attr(scored,"scoring_version"),"CANONICAL_BALANCE_P1_1.0.0"))
  status<-data.frame(assertion=c("state_preservation","exact_mapping","denominator","authority","version"),pass=pass)
  if(nrow(status)!=5L || anyNA(pass) || !all(pass)) stop("Balance post-scoring QC failed",call.=FALSE)
  status
}
