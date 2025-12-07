import os
import pandas as pd

df = pd.read_csv(os.path.join("docs", "SYNTHETIC_DEMO", "demo_synthetic.csv"))

# Varmista numeeriset tyypit ja vaihda desimaalipilkku pisteeksi tarvittaessa
for col in [
    "age",
    "sex",
    "label_falls",
    "label_incont",
    "label_lonely",
    "label_mobility",
    "event_death",
    "followup_years",
]:
    df[col] = pd.to_numeric(df[col].astype(str).str.replace(",", ".", regex=False), errors="coerce")

# Sääntö: predict death=1 jos age>=80 tai label_falls=1
y_true = df["event_death"].astype(int).values
y_pred = ((df["age"] >= 80) | (df["label_falls"] == 1)).astype(int).values

tp = int(((y_true == 1) & (y_pred == 1)).sum())
fp = int(((y_true == 0) & (y_pred == 1)).sum())
fn = int(((y_true == 1) & (y_pred == 0)).sum())
prec = tp / (tp + fp) if (tp + fp) > 0 else 0.0
rec = tp / (tp + fn) if (tp + fn) > 0 else 0.0
f1 = 2 * prec * rec / (prec + rec) if (prec + rec) > 0 else 0.0
print(f"Samples={len(df)} P={prec:.3f} R={rec:.3f} F1={f1:.3f}")

# Cox-smoke
try:
    from lifelines import CoxPHFitter

    cph = CoxPHFitter()
    sdf = df[["followup_years", "event_death", "age", "sex", "label_falls"]].copy()
    sdf.columns = ["T", "E", "age", "sex", "falls"]
    cph.fit(sdf, duration_col="T", event_col="E")
    print(f"Cox smoke OK. HR(age)={float(cph.hazard_ratios_['age']):.3f}")
except Exception as e:
    print("Cox smoke skipped [TODO lifelines or data shape]:", str(e)[:120])
