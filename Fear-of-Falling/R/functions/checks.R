sanity_checks <- function(df) {
  stopifnot("id" %in% names(df))
  if (anyDuplicated(df$id) > 0) stop("Duplikaatti-id:t löytyivät (wide-datassa pitäisi olla 1 rivi/henkilö).")
  
  req <- c("Composite_Z0", "Composite_Z2", "Delta_Composite_Z", "FOF_status", "Age", "Sex")
  miss <- setdiff(req, names(df))
  if (length(miss) > 0) stop("Puuttuvat pakolliset sarakkeet: ", paste(miss, collapse = ", "))
  
  # FOF-status allowed values
  bad_fof <- df$FOF_status[!is.na(df$FOF_status) & !df$FOF_status %in% c(0, 1)]
  if (length(bad_fof) > 0) stop("FOF_status sisältää muita arvoja kuin 0/1/NA.")
  
  # Delta consistency (tolerance for floating point)
  delta_check <- df$Composite_Z2 - df$Composite_Z0
  if (any(abs(df$Delta_Composite_Z - delta_check) > 1e-8, na.rm = TRUE)) {
    stop("Delta_Composite_Z ei vastaa Composite_Z2 - Composite_Z0.")
  }
  
  # Quick missingness summary (returns a tibble)
  tibble::tibble(
    n = nrow(df),
    n_complete_primary = sum(stats::complete.cases(df[, c("Composite_Z0","Composite_Z2","FOF_status","Age","Sex")]))
  )
}
