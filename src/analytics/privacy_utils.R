#' Suppress Small Cell Counts
#'
#' Replaces numeric values strictly less than a threshold with a placeholder string.
#' Used for Statistical Disclosure Control (SDC).
#'
#' @param data A data frame or tibble.
#' @param ... Columns to apply suppression to (tidy-select supported).
#' @param min_n Numeric. Threshold for suppression (default: 5).
#' @param placeholder Character. Replacement string (default: "n<5").
#'
#' @return A modified tibble with selected columns converted to character.
#' @import dplyr
#' @export
suppress_small_cells <- function(data, ..., min_n = 5, placeholder = "n<5") {
  
  if (!requireNamespace("dplyr", quietly = TRUE)) {
    stop("Package 'dplyr' is required.")
  }
  
  data %>%
    dplyr::mutate(dplyr::across(c(...), function(x) {
      # Only apply to numeric vectors
      if (is.numeric(x)) {
        # Identify values to suppress (handling NAs)
        to_suppress <- !is.na(x) & x < min_n
        
        # Convert to character
        x_char <- as.character(x)
        
        # Apply placeholder
        x_char[to_suppress] <- placeholder
        
        return(x_char)
      } else {
        # If not numeric, return as is
        return(x)
      }
    }))
}
