#!/usr/bin/env python3
import pandas as pd
import numpy as np
import os
import subprocess
from pathlib import Path

# --- CONFIG (Populated from REPLICATION_CONFIG.md) ---
CONFIG = {
    "OUTPATIENT_EVENTS_PATH": "paper_02/Tutkimusaineisto_pkl_kaynnit_2010_2019.csv",
    "INPATIENT_EPISODES_PATH": "paper_02/Tutkimusaineisto_osastojakso_diagnoosit (1).xlsx",
    "ID_COL": "Henkilotunnus",
    "OUT_DATE_COL": "Kayntipvm",
    "IN_ADMIT_COL": "OsastojaksoAlkuPvm",
    "OUT_ICD_COL": "Pdgo",
    "IN_ICD_COL": "Pdgo",
    "PANEL_PATH": "derived/aim2_panel.csv"
}

DATA_ROOT = Path(os.getenv("DATA_ROOT", "/data/data/com.termux/files/home/FOF_LOCAL_DATA"))
OUTPUT_DIR = Path("outputs/replication_injury")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

def is_injury(val):
    if pd.isna(val): return False
    s = str(val).strip().upper()
    return s.startswith('S') or s.startswith('T')

def run_replication():
    print(f"Starting Injury-Only Replication from {DATA_ROOT}...")

    # 1. Load Master Panel (for FOF, age, sex, etc.)
    panel_path = DATA_ROOT / CONFIG["PANEL_PATH"]
    if not panel_path.exists():
        print(f"ERROR: Panel missing at {panel_path}")
        return
    
    panel = pd.read_csv(panel_path)
    # We only need one row per person to get baseline covariates, 
    # but the panel is person-period. Let's keep it person-period for modeling.
    
    # 2. Load and Filter Outpatient
    out_path = DATA_ROOT / CONFIG["OUTPATIENT_EVENTS_PATH"]
    print(f"Loading Outpatient: {out_path.name}")
    # Handle pipe sep
    out_df = pd.read_csv(out_path, sep='|', low_memory=False)
    out_df["is_inj"] = out_df[CONFIG["OUT_ICD_COL"]].apply(is_injury)
    
    # Secondary ICD check (Sdg1o - Sdg9o)
    sdg_cols = [f"Sdg{i}o" for i in range(1, 10)]
    for col in sdg_cols:
        if col in out_df.columns:
            out_df["is_inj"] = out_df["is_inj"] | out_df[col].apply(is_injury)
            
    out_inj = out_df[out_df["is_inj"]].copy()
    out_inj["date"] = pd.to_datetime(out_inj[CONFIG["OUT_DATE_COL"]].astype(str), format='%Y%m%d', errors='coerce')
    out_inj["year"] = out_inj["date"].dt.year
    
    # 3. Load and Filter Inpatient
    in_path = DATA_ROOT / CONFIG["INPATIENT_EPISODES_PATH"]
    print(f"Loading Inpatient: {in_path.name}")
    in_df = pd.read_excel(in_path)
    in_df["is_inj"] = in_df[CONFIG["IN_ICD_COL"]].apply(is_injury)
    
    for col in sdg_cols:
        if col in in_df.columns:
            in_df["is_inj"] = in_df["is_inj"] | in_df[col].apply(is_injury)
            
    in_inj = in_df[in_df["is_inj"]].copy()
    
    def parse_inpat_date(x):
        try:
            s = str(int(float(x)))
            if len(s) == 8:
                return pd.to_datetime(s, format='%Y%m%d', errors='coerce')
        except:
            pass
        return pd.to_datetime(x, errors='coerce')

    in_inj["date"] = in_inj[CONFIG["IN_ADMIT_COL"]].apply(parse_inpat_date)
    in_inj["year"] = in_inj["date"].dt.year

    # 4. Clean IDs for linkage
    def clean_id(x):
        return str(x).strip()

    panel["id_clean"] = panel["id"].apply(clean_id)
    out_inj["id_clean"] = out_inj[CONFIG["ID_COL"]].apply(clean_id)
    in_inj["id_clean"] = in_inj[CONFIG["ID_COL"]].apply(clean_id)

    # 5. Aggregate
    out_agg = out_inj.groupby(["id_clean", "year"]).size().reset_index(name="inj_out_count")
    in_agg = in_inj.groupby(["id_clean", "year"]).size().reset_index(name="inj_in_count")

    # 6. Merge into Panel
    final_df = pd.merge(panel, out_agg, left_on=["id_clean", "period"], right_on=["id_clean", "year"], how="left")
    final_df.drop(columns=["year"], inplace=True)
    final_df = pd.merge(final_df, in_agg, left_on=["id_clean", "period"], right_on=["id_clean", "year"], how="left")
    final_df.drop(columns=["year"], inplace=True)
    
    final_df["inj_out_count"] = final_df["inj_out_count"].fillna(0)
    final_df["inj_in_count"] = final_df["inj_in_count"].fillna(0)

    # 7. Save for R modeling
    temp_csv = OUTPUT_DIR / "temp_injury_panel.csv"
    final_df.to_csv(temp_csv, index=False)
    print(f"Aggregated panel saved to {temp_csv}")

    # 8. Run R NB Model via subprocess
    r_code = f"""
    library(MASS)
    library(readr)
    df <- read_csv("{temp_csv}", show_col_types = FALSE)
    df$FOF <- factor(df$FOF_status)
    df$sex_f <- factor(df$sex)
    df$period_f <- factor(df$period)
    
    results <- list()
    outcomes <- c("inj_out_count", "inj_in_count")
    
    for(y in outcomes) {{
        message("Modeling: ", y)
        f <- as.formula(paste(y, "~ FOF + age + sex_f + period_f + offset(log(person_time))"))
        m <- tryCatch(glm.nb(f, data = df), error = function(e) NULL)
        
        if(!is.null(m)) {{
            # Simple recycled prediction for overall IRR
            d0 <- df; d0$FOF <- factor(0, levels=c(0,1))
            d1 <- df; d1$FOF <- factor(1, levels=c(0,1))
            p0 <- tryCatch(mean(predict(m, newdata=d0, type="response")), error = function(e) NA)
            p1 <- tryCatch(mean(predict(m, newdata=d1, type="response")), error = function(e) NA)
            irr_recycled <- p1 / p0
            
            # Get Wald CI and direct exponentiated coefficient
            s <- summary(m)
            est <- s$coefficients["FOF1", "Estimate"]
            se <- s$coefficients["FOF1", "Std. Error"]
            irr_coef <- exp(est)
            
            results[[y]] <- data.frame(
                outcome = y,
                IRR = ifelse(is.na(irr_recycled), irr_coef, irr_recycled),
                wald_L = exp(est - 1.96*se),
                wald_U = exp(est + 1.96*se)
            )
        }}
    }}
    
    final_res <- do.call(rbind, results)
    write.csv(final_res, "{OUTPUT_DIR / 'replication_injury_nb_age_sex.csv'}", row.names=FALSE)
    """
    
    print("Running R models...")
    subprocess.run(["Rscript", "-e", r_code], check=True)
    print(f"Replication complete. Results saved to {OUTPUT_DIR / 'replication_injury_nb_age_sex.csv'}")

if __name__ == "__main__":
    run_replication()
