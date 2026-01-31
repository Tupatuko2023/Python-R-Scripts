suppressPackageStartupMessages({ library(readr); library(dplyr) })
panel_path <- file.path(Sys.getenv("DATA_ROOT"), "derived", "aim2_panel.csv")
if(!file.exists(panel_path)) stop("Panel missing: ", panel_path)
panel <- read_csv(panel_path, show_col_types = FALSE)

# Check for frailty var
frailty_vars <- intersect(names(panel), c("frailty_cat_3","frailty_fried","frailty_score","frailty"))
if(length(frailty_vars) == 0) {
  print("No frailty variable found yet.")
  print(paste("Available columns:", paste(names(panel), collapse=", ")))
} else {
  fv <- frailty_vars[1]
  out <- panel %>% summarise(
    n_ids = n_distinct(id),
    share_missing_frailty_rows = mean(is.na(.data[[fv]]) | .data[[fv]] == "unknown")
  )
  print(out)
  
  # Dist by ID
  dist <- panel %>% group_by(id) %>% 
    summarise(f = first(na.omit(.data[[fv]])), .groups="drop") %>%
    count(f)
  print(dist)
}
