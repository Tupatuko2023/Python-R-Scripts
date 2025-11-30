# --- Parametrit ---
lower <- as.numeric(Sys.getenv("JN_LOWER", "-0.04"))
upper <- as.numeric(Sys.getenv("JN_UPPER", "0.21"))
obs_min <- as.numeric(Sys.getenv("OBS_MIN", "-1.72"))
obs_max <- as.numeric(Sys.getenv("OBS_MAX", "1.37"))
n_total_reported <- as.integer(Sys.getenv("N_TOTAL", "276"))

# --- Skriptin tunniste ja polut manifestia varten ---
script_label <- "K5.2_JN"  

if (!dir.exists("outputs")) dir.create("outputs", recursive = TRUE)
script_dir <- file.path("outputs", script_label)
if (!dir.exists(script_dir)) dir.create(script_dir, recursive = TRUE)

manifest_path <- file.path("outputs", "manifest.csv")



## --- Aineiston luku / nimeäminen ---
# Tavoite: df on kelvollinen data.frame, jossa on sarakenimet.

pick_data_frame <- function(x) {
  if (!exists(x)) return(NULL)
  obj <- get(x, envir = .GlobalEnv)
  if (is.data.frame(obj)) return(obj)
  if (is.matrix(obj)) return(as.data.frame(obj))
  return(NULL)
}

df <- pick_data_frame("analysis_data")

if (is.null(df)) df <- pick_data_frame("d")
if (is.null(df)) df <- pick_data_frame("raw_data")

if (is.null(df)) {
  stop("En löytänyt kelvollista data.frame-analyysiaineistoa (df, d tai raw_data).")
}

# --- Johda FOF_status kaatumisenpelkoOn-sarakkeesta ---

if (!"kaatumisenpelkoOn" %in% names(df)) {
  stop("kaatumisenpelkoOn -sarake puuttuu df:stä.")
}

x <- df$kaatumisenpelkoOn

# Muunna tarvittaessa tekstiksi
if (is.factor(x)) x <- as.character(x)

true_vals  <- c("1","yes","kylla","kyllä","true","pelko","fear","fof","on")
false_vals <- c("0","no","ei","false","ei pelkoa","no fear","off")

if (is.character(x)) {
  x_clean <- tolower(trimws(x))
  x_num <- ifelse(
    x_clean %in% true_vals, 1L,
    ifelse(x_clean %in% false_vals, 0L, NA_integer_)
  )
} else if (is.logical(x)) {
  x_num <- ifelse(x, 1L, 0L)
} else {
  # oletetaan numeerinen 0/1
  x_num <- as.integer(x)
}

df$FOF_status <- factor(x_num, levels = c(0, 1))
col_fof <- "FOF_status"

cat("FOF_status johdettuna:\n")
print(table(df$FOF_status, useNA = "ifany"))


cat("FOF_status uudelleen johdettuna:\n")
print(table(df$FOF_status, useNA = "ifany"))

col_fof <- "FOF_status"


# Varmuuden vuoksi: data.frameeksi ja printtaa sarakenimet
df <- as.data.frame(df)
cat("Sarakenimet df:ssä:\n")
print(names(df))

cat("\nFOF-avainsanoja sisältävät sarakkeet:\n")
ix_fof <- grepl("fof|pelko|kaatumis", names(df), ignore.case = TRUE)
print(names(df)[ix_fof])


cat("Sarakenimet df:ssä:\n")
print(names(df))

cat("\nFOF-avainsanoja sisältävät sarakkeet:\n")
ix_fof <- grepl("fof|pelko|kaatumis", names(df), ignore.case = TRUE)
print(names(df)[ix_fof])


# --- Apuri: etsi sarake monesta vaihtoehdosta ---
match_col <- function(data, candidates, required = TRUE) {
  cand <- unique(trimws(unlist(strsplit(candidates, ","))))
  cand <- cand[cand != ""]
  # suora osuma
  direct <- intersect(names(data), cand)
  if (length(direct) >= 1) return(direct[1])
  # sumea haku: piste vs alaviiva, isot kirjaimet pois
  simplify <- function(x) tolower(gsub("[^a-z0-9]", "", x))
  snames <- simplify(names(data))
  for (c in cand) {
    idx <- which(snames == simplify(c))
    if (length(idx) == 1) return(names(data)[idx])
  }
  if (required) {
    stop(sprintf("Pakollista saraketta ei löytynyt ehdokkaista: %s",
                 paste(cand, collapse = ", ")))
  }
  return(NA_character_)
}

# --- Ehdokaslistat: inputs-osan perusteella ---
cand_cZ0   <- "cComposite_Z0, cComposite.Z0, cCompZ0, baseline_z_centered, Z0_centered, Z0_c"
cand_Z0    <- "Composite_Z0, Composite.Z0, ToimintaKykySummary0, baseline_z"
cand_delta <- "Delta_Composite_Z, Delta.Composite.Z, ToimintaKykySummary2_minus_0, delta_z"


cat("FOF-status -yhteenveto:\n")
print(table(df[[col_fof]], useNA = "ifany"))
print(levels(df[[col_fof]]))


# --- Sarakkenimien täsmäytys ---
col_cZ0 <- match_col(df, cand_cZ0, required = FALSE)
col_Z0  <- match_col(df, cand_Z0,  required = FALSE)
col_dlt <- match_col(df, cand_delta, required = FALSE)  # ei pakollinen tähän laskentaan


# --- Luo cComposite_Z0 jos puuttuu ---
if (is.na(col_cZ0) || !(col_cZ0 %in% names(df))) {
  if (is.na(col_Z0) || !(col_Z0 %in% names(df))) {
    stop("Ei löytynyt cComposite_Z0 eikä Composite_Z0 -sarakeperhettä cComposite_Z0:n muodostamiseksi.")
  }
  mu <- mean(df[[col_Z0]], na.rm = TRUE)
  df$cComposite_Z0_tmp <- as.numeric(df[[col_Z0]] - mu)
  col_cZ0 <- "cComposite_Z0_tmp"
}

table(df$FOF_status, useNA = "ifany")


# --- Poista rivit joilta puuttuu moderaattori tai FOF ---
keep <- !is.na(df[[col_cZ0]]) & !is.na(df[[col_fof]])
df_sub <- df[keep, , drop = FALSE]

# --- Tarkista havaittu vaihteluväli ---
rng <- range(df_sub[[col_cZ0]], na.rm = TRUE)
if (lower < rng[1] || upper > rng[2]) {
  message(sprintf(
    "Varoitus: annetut JN-rajat [%0.3f, %0.3f] ylittävät havaittua vaihteluväliä [%0.3f, %0.3f]. Suodatus tehdään silti annetuilla rajoilla.",
    lower, upper, rng[1], rng[2]
  ))
}

# --- Suodatus JN-alueelle (inklusiiviset rajat) ---
in_jn <- df_sub[[col_cZ0]] >= lower & df_sub[[col_cZ0]] <= upper
df_jn <- df_sub[in_jn, , drop = FALSE]

# --- Ristiintaulukointi FOF x JN-alue ---
cat("\nFOF x JN-alue (df_sub):\n")
print(with(df_sub, table(FOF = df_sub[[col_fof]], JN_region = in_jn)))

# --- Summat koko aineistossa ---
N_total_emp <- nrow(df_sub)
N_JN <- nrow(df_jn)
pct_JN <- if (is.finite(n_total_reported) && n_total_reported > 0) {
  100 * N_JN / n_total_reported
} else {
  100 * N_JN / N_total_emp
}

# --- Summat FOF_status 0 ja 1 ---
tab_by_fof <- as.data.frame.matrix(table(in_jn, df_sub[[col_fof]]))
# Varmistetaan, että sarakkeet "0" ja "1" ovat olemassa
for (lvl in c("0", "1")) {
  if (!(lvl %in% names(tab_by_fof))) {
    tab_by_fof[[lvl]] <- 0L
  }
}
N_JN_0 <- if ("TRUE" %in% rownames(tab_by_fof)) tab_by_fof["TRUE", "0"] else 0L
N_JN_1 <- if ("TRUE" %in% rownames(tab_by_fof)) tab_by_fof["TRUE", "1"] else 0L

# --- Raporttitaulukko ---
summary_all <- data.frame(
  lower = lower,
  upper = upper,
  observed_min = rng[1],
  observed_max = rng[2],
  N_total_emp = N_total_emp,
  N_total_reported = n_total_reported,
  N_JN = N_JN,
  pct_JN = round(pct_JN, 1),
  N_JN_FOF0 = N_JN_0,
  N_JN_FOF1 = N_JN_1,
  stringsAsFactors = FALSE
)

# --- Vienti ---
if (!dir.exists("outputs")) dir.create("outputs", recursive = TRUE)
write.csv(summary_all, file = "outputs/JN_counts_summary.csv", row.names = FALSE)

html <- paste0(
  "<html><head><meta charset='UTF-8'></head><body>",
  "<h3>JN-alueen määrälaskenta</h3>",
  "<p>Rajaus: [", sprintf("%0.3f", lower), ", ", sprintf("%0.3f", upper), "]",
  " - havaittu moderaattorin vaihteluväli: [", sprintf("%0.3f", rng[1]), ", ", sprintf("%0.3f", rng[2]), "]</p>",
  "<table border='1' style='border-collapse:collapse;'>",
  "<tr><th>N_total_emp</th><th>N_total_reported</th><th>N_JN</th><th>%_JN</th><th>N_JN_FOF0</th><th>N_JN_FOF1</th></tr>",
  sprintf(
    "<tr><td>%d</td><td>%d</td><td>%d</td><td>%0.1f</td><td>%d</td><td>%d</td></tr>",
    N_total_emp, n_total_reported, N_JN, pct_JN, N_JN_0, N_JN_1
  ),
  "</table></body></html>"
)
writeLines(html, "outputs/JN_counts_summary.html")

message("Valmis. Katso outputs/JN_counts_summary.csv ja outputs/JN_counts_summary.html")

## --- Kuvan piirtäminen: FOF-ero ΔComposite_Z:ssa vs cComposite_Z0 ---

# Rakennetaan kuvaa varten oma data: käytä suodatettua df_sub:ia
df_plot <- df_sub

# ΔComposite_Z = ToimintaKykySummary2 - ToimintaKykySummary0
df_plot$Delta_Composite_Z <- df_plot$ToimintaKykySummary2 - df_plot$ToimintaKykySummary0

# Yhtenäiset nimet kovariaateille
df_plot$Sex <- factor(df_plot$Sex)
# Age on jo numeerinen, erillistä riviä ei tarvita
# BMI on jo nimellä BMI

# col_cZ0 on jo asetettu ylempänä:
# col_cZ0 <- "cComposite_Z0_tmp" tms.
print(col_cZ0)
print(col_fof)   # pitäisi olla "FOF_status"


## --- Kuvan piirtäminen: FOF-ero ΔComposite_Z:ssa vs cComposite_Z0 ---

## --- Kuvan piirtäminen: FOF-ero ΔComposite_Z:ssa vs cComposite_Z0 ---

if (!requireNamespace("ggplot2", quietly = TRUE)) {
  install.packages("ggplot2")
}
library(ggplot2)

# 1) Rakenna kuva-data suoraan df:stä

df_plot <- subset(
  df,
  !is.na(ToimintaKykySummary0) &
    !is.na(ToimintaKykySummary2) &
    !is.na(FOF_status)
)

# Moderaattori: keskitetty ToimintaKykySummary0 (sama idea kuin cComposite_Z0_tmp)
df_plot$cComposite_Z0_plot <- df_plot$ToimintaKykySummary0 -
  mean(df_plot$ToimintaKykySummary0, na.rm = TRUE)

# Muutos
df_plot$Delta_Composite_Z <- df_plot$ToimintaKykySummary2 - df_plot$ToimintaKykySummary0

# FOF numerisena 0/1
df_plot$FOF_num <- as.numeric(as.character(df_plot$FOF_status))

cat("FOF_num tarkistus:\n")
print(table(df_plot$FOF_num, useNA = "ifany"))

# 2) Yksinkertainen moderointimalli ilman kovariaatteja (visualisointia varten)
fit <- lm(Delta_Composite_Z ~ FOF_num * cComposite_Z0_plot, data = df_plot)

# 3) Hilapisteet moderaattorille
range_x <- range(df_plot$cComposite_Z0_plot, na.rm = TRUE)
grid_x  <- seq(range_x[1], range_x[2], length.out = 200)

new0 <- data.frame(
  FOF_num = 0,
  cComposite_Z0_plot = grid_x
)

new1 <- data.frame(
  FOF_num = 1,
  cComposite_Z0_plot = grid_x
)

pred0 <- predict(fit, newdata = new0)
pred1 <- predict(fit, newdata = new1)

plot_dat <- data.frame(
  x    = grid_x,
  diff = pred1 - pred0
)

# 4) JN-alueen havaintopisteet
points_dat <- subset(
  df_plot,
  cComposite_Z0_plot >= lower & cComposite_Z0_plot <= upper
)[, c("cComposite_Z0_plot", "FOF_status")]

names(points_dat) <- c("x", "FOF_status")

# 5) Piirto
JN_plot <- ggplot() +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_rect(
    aes(xmin = lower, xmax = upper, ymin = -Inf, ymax = Inf),
    alpha = 0.1
  ) +
  geom_line(data = plot_dat, aes(x = x, y = diff)) +
  geom_vline(xintercept = lower, linetype = "dotted") +
  geom_vline(xintercept = upper, linetype = "dotted") +
  geom_point(
    data = points_dat,
    aes(x = x, y = 0, color = FOF_status),
    position = position_jitter(height = 0.02),
    alpha = 0.8
  ) +
  labs(
    x = "cComposite_Z0 (keskitetty lähtötaso)",
    y = "Arvioitu ero ΔComposite_Z (FOF=1 vs FOF=0)",
    color = "FOF-status"
  ) +
  theme_minimal()

# 2) Varmista hakemisto ja tallenna
if (!dir.exists("outputs")) dir.create("outputs", recursive = TRUE)

ggplot2::ggsave(
  filename = file.path(script_dir, "jn_obs_plot.png"),
  plot = JN_plot,
  width = 7, height = 5, dpi = 300
)

message("JN-kuva tallennettu: ", file.path(script_dir, "jn_obs_plot.png"))



# --- Päämallin tulosten vienti manifestiin ---

# --- Päämallin tulostaulukko (fit) ---
if (!requireNamespace("broom", quietly = TRUE)) {
  install.packages("broom")
}
library(broom)

main_results <- broom::tidy(fit)

main_results_path <- file.path(
  script_dir,
  paste0(script_label, "_main_results.csv")
)

write.csv(main_results, main_results_path, row.names = FALSE)
message("Päämallin tulokset tallennettu: ", main_results_path)



# --- Manifest-rivit tälle skriptille ---
manifest_rows <- data.frame(
  script      = script_label,
  type        = c("table",                 "table",                  "plot"),
  filename    = c(
    file.path(script_label, paste0(script_label, "_main_results.csv")),
    "JN_counts_summary.csv",
    file.path(script_label, "jn_obs_plot.png")
  ),
  description = c(
    "Päämoderointimallin regressiokertoimet (lm: Delta_Composite_Z ~ FOF_num * cComposite_Z0_plot)",
    "JN-alueen määrälaskennan yhteenvetotaulukko",
    "JN-alueen ero ΔComposite_Z:ssa (FOF 1 vs 0) moderaattorin funktiona"
  ),
  stringsAsFactors = FALSE
)

# Kirjoita/päivitä manifest.csv
if (!file.exists(manifest_path)) {
  write.table(
    manifest_rows,
    file      = manifest_path,
    sep       = ",",
    row.names = FALSE,
    col.names = TRUE,
    append    = FALSE,
    qmethod   = "double"
  )
} else {
  write.table(
    manifest_rows,
    file      = manifest_path,
    sep       = ",",
    row.names = FALSE,
    col.names = FALSE,
    append    = TRUE,
    qmethod   = "double"
  )
}
message("Manifest päivitetty: ", manifest_path)

