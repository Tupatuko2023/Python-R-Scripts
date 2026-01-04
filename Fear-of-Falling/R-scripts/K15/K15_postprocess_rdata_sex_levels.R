args <- commandArgs(trailingOnly = TRUE)
rdata_path <- args[[1]]
marker_path <- Sys.getenv("K37_MARKER_FILE")
e <- new.env(parent = emptyenv())
load(rdata_path, envir = e)
obj_names <- ls(e)
target_df_name <- NA
for (nm in obj_names) {
  obj <- get(nm, envir = e)
  if (is.data.frame(obj) && ("sex_factor" %in% names(obj))) {
    target_df_name <- nm
    break
  }
}
if (!is.na(target_df_name)) {
  df <- get(target_df_name, envir = e)
  sf <- df[["sex_factor"]]
  if (is.factor(sf) && length(levels(sf)) == 2) {
    old_lv <- levels(sf)
    levels(sf) <- c("Level 0", "Level 1")
    df[["sex_factor"]] <- sf
    assign(target_df_name, df, envir = e)
    if (nzchar(marker_path)) {
      writeLines(c(paste0("BEFORE=", paste(old_lv, collapse=",")), paste0("AFTER=Level 0,Level 1")), marker_path)
    }
  }
}
save(list = ls(e), file = rdata_path, envir = e)
