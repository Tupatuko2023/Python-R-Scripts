#!/usr/bin/env python3
import pandas as pd
import numpy as np
import os
from pathlib import Path

DATA_ROOT = Path(os.getenv("DATA_ROOT", "/data/data/com.termux/files/home/FOF_LOCAL_DATA"))
DERIVED_DIR = DATA_ROOT / "derived"
DERIVED_DIR.mkdir(parents=True, exist_ok=True)

print("Building real panel (EXPANDED COHORT) from DATA_ROOT...")

# 1. Master Cohort Source: Raw Excel
raw_candidates = [
    DATA_ROOT / "paper_02" / "KAAOS_data.xlsx",
    DATA_ROOT / "paper_02" / "KAAOS_data_sotullinen.xlsx",
]
raw_path = next((p for p in raw_candidates if p.exists()), None)
if raw_path is None:
    raise SystemExit("Raw KAAOS file missing (expected paper_02/KAAOS_data.xlsx or paper_02/KAAOS_data_sotullinen.xlsx).")
# Keep only filename for logs (no absolute paths)
raw_name = raw_path.name

# Header-only scan (header row 2 in the source file)
hdr_df = pd.read_excel(raw_path, nrows=0, header=1)
hdr_cols = list(hdr_df.columns)

def _norm_header(x: str) -> str:
    x = str(x).replace("\u00A0", " ")
    x = x.replace("\n", " ")
    x = " ".join(x.split())
    x = x.strip()
    # Drop numeric prefixes like "2." to stabilize matching
    if x and x[0].isdigit():
        parts = x.split(" ", 1)
        if parts[0].endswith(".") and len(parts) > 1:
            x = parts[1].strip()
    return x.lower()

norm_map = {c: _norm_header(c) for c in hdr_cols}

def pick_col_by_contains(target: str, include, exclude=None):
    exclude = exclude or []
    hits = []
    for col, norm in norm_map.items():
        if all(pat in norm for pat in include) and not any(pat in norm for pat in exclude):
            hits.append(col)
    if len(hits) == 1:
        return hits[0]
    if len(hits) == 0:
        raise SystemExit(f"Missing column for {target} in KAAOS header (file: {raw_name}).")
    raise SystemExit(f"Ambiguous columns for {target} in KAAOS header: {hits}")

def find_candidates(patterns):
    out = []
    for col, norm in norm_map.items():
        if any(pat in norm for pat in patterns):
            out.append(col)
    return out

# Baseline column mapping from KAAOS (header row 2)
col_id_primary = None
try:
    col_id_primary = pick_col_by_contains("id", include=["potilas", "tunnus"])
except SystemExit:
    col_id_primary = None
col_id_fallback = pick_col_by_contains("id_fallback", include=["nro"]) if col_id_primary is None else None

col_age = pick_col_by_contains("age", include=["ikä"])
col_sex = pick_col_by_contains("sex", include=["sukupuoli"])
col_bmi = pick_col_by_contains("bmi", include=["bmi"])
col_fof = pick_col_by_contains("fof", include=["kaatumisen pelko", "ei pelkää"])
col_smoker = pick_col_by_contains("smoker", include=["tupakointi"])
col_alcohol = pick_col_by_contains("alcohol", include=["alkoholi"])
col_dm = pick_col_by_contains("dm", include=["diabetes"])
col_ad = pick_col_by_contains("ad", include=["alzheimer"])
col_cva = pick_col_by_contains("cva", include=["avh"])
col_srh = pick_col_by_contains("srh", include=["koettu", "terveydentila"])
col_fallen = pick_col_by_contains("fallen", include=["kaatuminen"], exclude=["pelko"])
col_balance = pick_col_by_contains("balance", include=["tasapaino", "vaike"])
col_fract = pick_col_by_contains("fractures", include=["murtumia"], exclude=["lonkka", "vanhempien", "sisaruksien"])
col_walk500 = pick_col_by_contains("walk500", include=["500m", "vaikeus", "liikkua"])
col_ftsst = pick_col_by_contains("ftsst", include=["tk", "tuolilta nousu", "5 krt", "sek"], exclude=["1sk", "2sk"])
col_ability = pick_col_by_contains("ability", include=["oma", "arvio", "liikuntakyv"])

# 1b. Baseline dataset (for Table 1)
baseline_cols = [
    col_id_primary or col_id_fallback,
    col_age, col_sex, col_bmi, col_fof, col_smoker, col_alcohol,
    col_dm, col_ad, col_cva, col_srh, col_fallen, col_balance,
    col_fract, col_walk500, col_ability
]
baseline_df = pd.read_excel(raw_path, header=1, usecols=baseline_cols)

baseline_df = baseline_df.rename(columns={
    (col_id_primary or col_id_fallback): "id",
    col_age: "age",
    col_sex: "sex",
    col_bmi: "bmi",
    col_fof: "kaatumisenpelkoOn",
    col_smoker: "tupakointi",
    col_alcohol: "alkoholi",
    col_dm: "diabetes",
    col_ad: "alzheimer",
    col_cva: "AVH",
    col_srh: "koettuterveydentila",
    col_fallen: "kaatuminen",
    col_balance: "tasapainovaikeus",
    col_fract: "murtumia",
    col_walk500: "vaikeus_liikkua_500m",
    col_ability: "ability_out_of_home",
})

baseline_df["FTSST"] = pd.read_excel(raw_path, header=1, usecols=[col_ftsst])[col_ftsst]

# Map ability codes to Table 1 categories (0=hyvä,1=kohtalainen,2=heikko,3=ei tietoa)
ability_map = {0: "Without difficulties", 1: "With difficulties", 2: "Unable independently", 3: None}
baseline_df["ability_out_of_home"] = baseline_df["ability_out_of_home"].map(ability_map)

# Save baseline CSV for Table 1 (primary input)
baseline_out = DERIVED_DIR / "kaatumisenpelko.csv"
baseline_df.to_csv(baseline_out, index=False)
print("Baseline CSV saved to derived/kaatumisenpelko.csv")
# We'll use the indices verified in forensics
# 0:NRO, 2:Sotu, 4:age, 5:sex, 17:BMI, 26:ActSR, 27:Act500m, 28:Act2km, 34:FOF, 37:MaxWalk, 45:StrengthR, 46:StrengthL, 47:Speed10m
cols_idx = [0, 2, 4, 5, 17, 26, 27, 28, 34, 37, 45, 46, 47]
raw_df = pd.read_excel(raw_path, usecols=cols_idx, skiprows=1)
raw_df.columns = ["NRO", "Sotu", "age", "sex", "bmi", "ActSR", "Act500m", "Act2km", "FOF_raw", "MaxWalk", "StrengthR", "StrengthL", "Speed10m_sec"]

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
df["bmi"] = pd.to_numeric(df["bmi"], errors="coerce")

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
            "bmi": row["bmi"],
            "period": yr,
            "person_time": 1.0,
            "frailty_fried": row["frailty_cat_3"],
            "frailty_binary": row["frailty_binary"]
        })

panel_df = pd.DataFrame(panel_list)

# 6. Aggregate Visits per Person-Year
# A) Outpatient
out_visits = outpatient.groupby(["id", "year"]).size().reset_index(name="util_visits_outpatient")
# B) Inpatient (Placeholder: each row in inpat is a period)
# Loading inpat for building real panel if needed. 
# For now, we'll use the existing logic and expand it.
inpat_path = DATA_ROOT / "paper_02" / "Tutkimusaineisto_osastojakso_diagnoosit (1).xlsx"
inpat = pd.read_excel(inpat_path)
inpat.rename(columns={"Henkilotunnus": "id", "OsastojaksoAlkuPvm": "date_raw"}, inplace=True)

def parse_inpat_date(x):
    try:
        s = str(int(float(x)))
        if len(s) == 8:
            return pd.to_datetime(s, format='%Y%m%d', errors='coerce')
    except:
        pass
    return pd.to_datetime(x, errors='coerce')

inpat["date"] = inpat["date_raw"].apply(parse_inpat_date)
inpat["year"] = inpat["date"].dt.year
in_visits = inpat.groupby(["id", "year"]).size().reset_index(name="util_visits_inpatient")

# Merge visits into panel
panel_df = pd.merge(panel_df, out_visits, left_on=["id", "period"], right_on=["id", "year"], how="left")
panel_df.drop(columns=["year"], inplace=True)
panel_df = pd.merge(panel_df, in_visits, left_on=["id", "period"], right_on=["id", "year"], how="left")
panel_df.drop(columns=["year"], inplace=True)

panel_df["util_visits_outpatient"] = panel_df["util_visits_outpatient"].fillna(0)
panel_df["util_visits_inpatient"] = panel_df["util_visits_inpatient"].fillna(0)
panel_df["util_visits_total"] = panel_df["util_visits_outpatient"] + panel_df["util_visits_inpatient"]

# 7. Calculate Costs (Assumption: 60 EUR per visit)
panel_df["cost_total_eur"] = panel_df["util_visits_total"] * 60.0

# 8. Save
output_path = DERIVED_DIR / "aim2_panel.csv"
panel_df.to_csv(output_path, index=False)
print("Panel successfully saved to derived/aim2_panel.csv")
print(f"Final dataset: {len(df)} persons (Increased from 276!).")
print(f"Panel size: {len(panel_df)} rows.")
