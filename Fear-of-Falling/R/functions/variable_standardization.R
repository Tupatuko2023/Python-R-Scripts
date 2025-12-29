# R/functions/variable_standardization.R

#' Read variable standardization specification
#'
#' @param path Path to VARIABLE_STANDARDIZATION.csv
#' @return Data frame with standardization rules
read_standardization_spec <- function(path) {
  if (!file.exists(path)) stop("Standardization spec not found: ", path)
  spec <- utils::read.csv(path, stringsAsFactors = FALSE)
  req <- c("canonical_name", "alias", "priority", "action")
  miss <- setdiff(req, names(spec))
  if (length(miss) > 0) stop("Invalid spec format. Missing columns: ", paste(miss, collapse=", "))
  spec
}

#' Standardize data frame column names based on specification
#'
#' @param df Data frame to standardize
#' @param spec Specification data frame (from read_standardization_spec)
#' @param strict_verify Logical; if TRUE, stops execution on 'verify' hits
#' @return List containing:
#'   - df: Standardized data frame
#'   - renames: Data frame of performed renames
#'   - verify_hits: Data frame of 'verify' aliases found
#'   - conflicts: Data frame of conflicts found (if any)
standardize_names <- function(df, spec, strict_verify = TRUE) {
  
  cols <- names(df) 
  
  # 1. Map existing columns to canonical groups
  # Find which aliases in spec exist in df
  hits <- spec[spec$alias %in% cols, ]
  
  # Also identify if canonical names themselves are already in df (implicit identity)
  # We treat canonical name as an alias of itself with highest priority if not explicitly in spec,
  # but here we focus on detecting conflicts.
  
  # Prepare report structures
  renames_log <- data.frame(original = character(), canonical = character(), stringsAsFactors = FALSE)
  verify_hits <- data.frame(alias = character(), canonical = character(), stringsAsFactors = FALSE)
  conflicts   <- data.frame(canonical = character(), found_cols = character(), stringsAsFactors = FALSE)
  
  if (nrow(hits) == 0) {
    return(list(df = df, renames = renames_log, verify_hits = verify_hits, conflicts = conflicts))
  }
  
  # 2. Check for conflicts: Multiple columns mapping to the SAME canonical name
  # Note: This includes the canonical name itself if it exists in df AND an alias exists.
  # Example: df has "id" AND "ID". spec says ID -> id.
  # We need to consider that "id" maps to "id".
  
  # Build a comprehensive map of present_col -> canonical
  present_map <- hits[, c("alias", "canonical_name")]
  
  # Add implicit canonicals: if 'id' is in df, it maps to 'id'
  canonicals_in_df <- intersect(spec$canonical_name, cols)
  # Avoid duplicating if canonical is listed as an alias (rare but possible)
  canonicals_implicit <- setdiff(canonicals_in_df, present_map$alias)
  
  if (length(canonicals_implicit) > 0) {
    implicit_rows <- data.frame(alias = canonicals_implicit, canonical_name = canonicals_implicit, stringsAsFactors = FALSE)
    present_map <- rbind(present_map, implicit_rows)
  }
  
  # Detect duplicates
  counts <- table(present_map$canonical_name)
  conflict_canons <- names(counts)[counts > 1]
  
  if (length(conflict_canons) > 0) {
    for (cname in conflict_canons) {
      found <- present_map$alias[present_map$canonical_name == cname]
      conflicts <- rbind(conflicts, data.frame(canonical = cname, found_cols = paste(found, collapse = "; ")))
    }
    # STOP immediately on conflict
    stop(paste0(
      "[STANDARDIZATION ERROR] Conflicts detected! Multiple columns map to the same canonical variable.\n",
      paste(apply(conflicts, 1, function(x) paste0(x['canonical'], ": [", x['found_cols'], "]")), collapse = "\n"),
      "\nFix input data or standardization spec."
    ))
  }
  
  # 3. Handle Actions
  # Now we know mapping is 1-to-1 (canonical <-> single present column)
  
  # We only process 'hits' (things defined in spec). Implicit canonicals don't need action.
  
  for (i in seq_len(nrow(hits))) {
    row <- hits[i, ]
    orig <- row$alias
    canon <- row$canonical_name
    act <- row$action
    
    # Skip if column is already canonical (e.g. alias='id', canonical='id')
    if (orig == canon) next
    
    if (act == "verify") {
      verify_hits <- rbind(verify_hits, data.frame(alias = orig, canonical = canon))
      if (strict_verify) {
         stop(paste0(
           "[STANDARDIZATION STOP] Verify hit: Column '", orig, "' found mapping to '", canon, "'.\n",
           "Action is set to 'verify'. Please check data content and update VARIABLE_STANDARDIZATION.csv to 'rename_to_canonical' if valid."
         ))
      }
    } else if (act == "rename_to_canonical") {
      # Rename
      names(df)[names(df) == orig] <- canon
      renames_log <- rbind(renames_log, data.frame(original = orig, canonical = canon))
    }
  }
  
  list(df = df, renames = renames_log, verify_hits = verify_hits, conflicts = conflicts)
}
