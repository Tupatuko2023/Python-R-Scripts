#!/usr/bin/env python3
import pandas as pd
import numpy as np
import os
from pathlib import Path

DATA_ROOT = Path(os.getenv("DATA_ROOT", "/data/data/com.termux/files/home/FOF_LOCAL_DATA"))
DERIVED_DIR = DATA_ROOT / "derived"
DERIVED_DIR.mkdir(parents=True, exist_ok=True)

print(f"Building real panel from {DATA_ROOT}...")

# 1. Load KAAOS (Baseline)
kaaos_path = DATA_ROOT / "paper_02" / "KAAOS_data.xlsx"
# We know row 0 has labels, but we'll read from row 1 to get data and use indices
kaaos = pd.read_excel(kaaos_path, header=None, skiprows=1)
kaaos = kaaos[[0, 3, 4, 33]]
kaaos.columns = ["NRO", "age", "sex", "FOF_status"]
# Clean FOF_status: 0=No, 1=Yes, 2=Missing
kaaos["FOF_status"] = pd.to_numeric(kaaos["FOF_status"], errors='coerce')
kaaos = kaaos[kaaos["FOF_status"].isin([0, 1])]

# 2. Load Sotu mapping
sotu_path = DATA_ROOT / "paper_02" / "sotut.xlsx"
sotu = pd.read_excel(sotu_path)
sotu = sotu[["NRO", "Sotu"]]
sotu.columns = ["NRO", "id"]

# Merge KAAOS with IDs
baseline = pd.merge(kaaos, sotu, on="NRO")
baseline = baseline.drop(columns=["NRO"])
print(f"Baseline loaded: {len(baseline)} persons.")

# 3. Load Outpatient Visits
outpatient_path = DATA_ROOT / "paper_02" / "Tutkimusaineisto_pkl_kaynnit_2010_2019.csv"
outpatient = pd.read_csv(outpatient_path, sep="|")
outpatient.rename(columns={"Henkilotunnus": "id", "Kayntipvm": "date"}, inplace=True)
outpatient["date"] = pd.to_datetime(outpatient["date"], format="%Y%m%d", errors='coerce')
outpatient["year"] = outpatient["date"].dt.year

# 4. Create Person-Period Panel (2010-2019)
years = range(2010, 2020)
panel_list = []
for _, row in baseline.iterrows():
    for yr in years:
        panel_list.append({
            "id": row["id"],
            "FOF_status": row["FOF_status"],
            "age": row["age"],
            "sex": row["sex"],
            "period": yr,
            "person_time": 1.0,
            "frailty_fried": 0 # Placeholder
        })

panel_df = pd.DataFrame(panel_list)

# 5. Aggregate Visits per Person-Year
visits_agg = outpatient.groupby(["id", "year"]).size().reset_index(name="util_visits_total")

# Merge visits into panel
panel_df = pd.merge(panel_df, visits_agg, left_on=["id", "period"], right_on=["id", "year"], how="left")
panel_df["util_visits_total"] = panel_df["util_visits_total"].fillna(0)
panel_df.drop(columns=["year"], inplace=True)

# 6. Calculate Costs (Assumption: 60 EUR per visit)
panel_df["cost_total_eur"] = panel_df["util_visits_total"] * 60.0

# 7. Save
output_path = DERIVED_DIR / "aim2_panel.csv"
panel_df.to_csv(output_path, index=False)
print(f"Panel saved to {output_path} with {len(panel_df)} rows.")
