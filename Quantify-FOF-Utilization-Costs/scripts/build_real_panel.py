#!/usr/bin/env python3
import pandas as pd
import numpy as np
import os
from pathlib import Path

DATA_ROOT = Path(os.getenv("DATA_ROOT", "/data/data/com.termux/files/home/FOF_LOCAL_DATA"))
DERIVED_DIR = DATA_ROOT / "derived"
DERIVED_DIR.mkdir(parents=True, exist_ok=True)

print(f"Building real panel (EXPANDED COHORT) from {DATA_ROOT}...")

# 1. Master Cohort Source: Raw Excel
raw_path = DATA_ROOT / "paper_02" / "KAAOS_data_sotullinen.xlsx"
# We'll use the indices verified in forensics
# 0:NRO, 2:Sotu, 4:age, 5:sex, 17:BMI, 26:ActSR, 27:Act500m, 28:Act2km, 34:FOF, 37:MaxWalk, 45:StrengthR, 46:StrengthL, 47:Speed10m
cols_idx = [0, 2, 4, 5, 17, 26, 27, 28, 34, 37, 45, 46, 47]
raw_df = pd.read_excel(raw_path, usecols=cols_idx, skiprows=1)
raw_df.columns = ["NRO", "Sotu", "age", "sex", "BMI", "ActSR", "Act500m", "Act2km", "FOF_raw", "MaxWalk", "StrengthR", "StrengthL", "Speed10m_sec"]

print(f"Loaded raw cohort: {len(raw_df)} rows.")

# 2. ID Linkage & Fallback
verrokit_path = DATA_ROOT / "paper_02" / "verrokitjatutkimushenkilöt.xlsx"
verrokit = pd.read_excel(verrokit_path)
pid_to_sotu = verrokit.set_index("Tutkimus-henkilön numero")["Tutkimus-henkilön henkilötunnus"].to_dict()

def resolve_id(row):
    # Primary: Col 2 (Sotu)
    if pd.notna(row["Sotu"]):
        return str(row["Sotu"]).strip()
    # Fallback: NRO -> verrokit
    nro = row["NRO"]
    if nro in pid_to_sotu:
        return str(pid_to_sotu[nro]).strip()
    return None

raw_df["id"] = raw_df.apply(resolve_id, axis=1)
print(f"Linkage success: {raw_df['id'].notna().sum()} / {len(raw_df)} with Sotu.")

# Filter to those with IDs
df = raw_df[raw_df["id"].notna()].copy()

# 3. Methodology Enforcement

# 3.1 FOF Binary (strictly 0/1)
# 0=ei pelkää, 1=pelkää, 2=ei tietoa
df["FOF_status"] = pd.to_numeric(df["FOF_raw"], errors="coerce")
df = df[df["FOF_status"].isin([0, 1])].copy()
df["FOF_status"] = df["FOF_status"].astype(int)

# 3.2 Frailty Components

# A) Strength (Weakness)
# Logic: Women (sex=0) Weak if Class <= 1. Men (sex=1) Weak if Class <= 2.
# (Based on forensic mapping where Class 1 is ~10kg, Class 2 is ~17kg)
df["SR_val"] = pd.to_numeric(df["StrengthR"], errors="coerce")
df["SL_val"] = pd.to_numeric(df["StrengthL"], errors="coerce")
df["StrengthClass"] = df[["SR_val", "SL_val"]].max(axis=1)

def is_weak(row):
    c = row["StrengthClass"]
    if pd.isna(c): return np.nan
    if row["sex"] == 0: # Female
        return 1 if c <= 1 else 0
    else: # Male
        return 1 if c <= 2 else 0

df["frailty_weakness"] = df.apply(is_weak, axis=1)

# B) Speed (Slowness)
# Logic: 10 / time < 0.8 m/s => time > 12.5 sec
df["time_val"] = pd.to_numeric(df["Speed10m_sec"], errors="coerce")
df["frailty_slowness"] = np.where(
    df["time_val"].isna(), np.nan,
    np.where(df["time_val"] > 12.5, 1, 0)
)

# C) Activity (Low Activity)
# Logic: ActSR=2 (heikko), Act500m=1/2, Act2km=1/2, MaxWalk<400
df["flag_sr"] = df["ActSR"] == 2
df["flag_500"] = df["Act500m"].isin([1, 2])
df["flag_2k"] = df["Act2km"].isin([1, 2])
# MaxWalk can have 'E1'
df["maxw_val"] = pd.to_numeric(df["MaxWalk"], errors="coerce")
df["flag_maxw"] = df["maxw_val"] < 400

act_cols = ["flag_sr", "flag_500", "flag_2k", "flag_maxw"]
df["frailty_low_activity"] = df[act_cols].any(axis=1).astype(float)
df.loc[df[act_cols].isna().all(axis=1), "frailty_low_activity"] = np.nan

# 3.3 Calculate Frailty Score (Sum 0-3)
df["frailty_count_3"] = df["frailty_weakness"] + df["frailty_slowness"] + df["frailty_low_activity"]

# Categories
def get_frailty_cat(count):
    if pd.isna(count): return "unknown"
    if count == 0: return "robust"
    if count == 1: return "pre-frail"
    return "frail"

df["frailty_cat_3"] = df["frailty_count_3"].apply(get_frailty_cat)
df["frailty_binary"] = np.where(df["frailty_cat_3"].isin(["robust", "pre-frail"]), "non-frail", 
                               np.where(df["frailty_cat_3"] == "frail", "frail", "unknown"))

print(f"Frailty distribution: {df['frailty_cat_3'].value_counts().to_dict()}")

# 4. Load Outpatient Visits
outpatient_path = DATA_ROOT / "paper_02" / "Tutkimusaineisto_pkl_kaynnit_2010_2019.csv"
outpatient = pd.read_csv(outpatient_path, sep="|")
outpatient.rename(columns={"Henkilotunnus": "id", "Kayntipvm": "date"}, inplace=True)
outpatient["date"] = pd.to_datetime(outpatient["date"], format="%Y%m%d", errors='coerce')
outpatient["year"] = outpatient["date"].dt.year

# 5. Create Person-Period Panel (2010-2019)
years = range(2010, 2020)
panel_list = []
for _, row in df.iterrows():
    for yr in years:
        panel_list.append({
            "id": row["id"],
            "FOF_status": row["FOF_status"],
            "age": row["age"],
            "sex": row["sex"],
            "period": yr,
            "person_time": 1.0,
            "frailty_fried": row["frailty_cat_3"],
            "frailty_binary": row["frailty_binary"]
        })

panel_df = pd.DataFrame(panel_list)

# 6. Aggregate Visits per Person-Year
visits_agg = outpatient.groupby(["id", "year"]).size().reset_index(name="util_visits_total")

# Merge visits into panel
panel_df = pd.merge(panel_df, visits_agg, left_on=["id", "period"], right_on=["id", "year"], how="left")
panel_df["util_visits_total"] = panel_df["util_visits_total"].fillna(0)
panel_df.drop(columns=["year"], inplace=True)

# 7. Calculate Costs (Assumption: 60 EUR per visit)
panel_df["cost_total_eur"] = panel_df["util_visits_total"] * 60.0

# 8. Save
output_path = DERIVED_DIR / "aim2_panel.csv"
panel_df.to_csv(output_path, index=False)
print(f"Panel successfully saved to {output_path}")
print(f"Final dataset: {len(df)} persons (Increased from 276!).")
print(f"Panel size: {len(panel_df)} rows.")
