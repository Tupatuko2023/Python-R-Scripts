df <- read.csv("docs/SYNTHETIC_DEMO/demo_synthetic.csv", stringsAsFactors = FALSE)

# Pakota numeeriset sarakkeet, vaihda pilkku pisteeksi
num_cols <- c("age","sex","label_falls","label_incont","label_lonely",
              "label_mobility","event_death","followup_years")
for (nm in num_cols) {
  df[[nm]] <- as.numeric(gsub(",", ".", as.character(df[[nm]]), fixed = TRUE))
}

# Sääntöbaselinen metriikat
pred <- ifelse(df$age >= 80 | df$label_falls == 1, 1, 0)
tp <- sum(df$event_death==1 & pred==1); fp <- sum(df$event_death==0 & pred==1); fn <- sum(df$event_death==1 & pred==0)
prec <- ifelse(tp+fp>0, tp/(tp+fp), 0); rec <- ifelse(tp+fn>0, tp/(tp+fn), 0); f1 <- ifelse(prec+rec>0, 2*prec*rec/(prec+rec), 0)
cat(sprintf("Samples=%d P=%.3f R=%.3f F1=%.3f\n", nrow(df), prec, rec, f1))

# Cox “smoke”
if (requireNamespace("survival", quietly = TRUE)) {
  library(survival)
  fit <- coxph(Surv(followup_years, event_death) ~ age + sex + label_falls, data=df)
  cat(sprintf("Cox smoke OK. HR(age)=%.3f\n", exp(coef(fit)["age"])))
} else {
  cat("Cox smoke skipped [TODO install.packages('survival')]\n")
}