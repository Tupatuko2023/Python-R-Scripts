import pandas as pd
import os
from pathlib import Path

DATA_ROOT = Path("/data/data/com.termux/files/home/FOF_LOCAL_DATA")

raw_files = {
    "Outpatient": "paper_02/Tutkimusaineisto_pkl_kaynnit_2010_2019.csv",
    "Inpatient": "paper_02/Tutkimusaineisto_osastojakso_diagnoosit (1).xlsx"
}

print("--- RAW FILE HEADERS ---")
for label, rel_path in raw_files.items():
    path = DATA_ROOT / rel_path
    if not path.exists():
        print(f"File not found: {path}")
        continue
    
    print(f"\n[{label}] {path.name}")
    if path.suffix == ".csv":
        # Peek first few lines to get headers if separator is unknown
        # But we know it's often '|' from previous script
        try:
            df = pd.read_csv(path, sep='|', nrows=0)
            print(df.columns.tolist())
        except:
            # Try default sep
            df = pd.read_csv(path, nrows=0)
            print(df.columns.tolist())
    else:
        df = pd.read_excel(path, nrows=0)
        print(df.columns.tolist())

panel_path = DATA_ROOT / "derived/aim2_panel.csv"
if panel_path.exists():
    print(f"\n[Panel] {panel_path.name}")
    df_panel = pd.read_csv(panel_path, nrows=0)
    print(df_panel.columns.tolist())
