import pandas as pd
import os
import sys

# Load manifest to find the file

try:
    m = pd.read_csv("manifest/dataset_manifest.csv")
    # Handle logical_name column
    col = "logical_name" if "logical_name" in m.columns else "dataset"
    path_col = "relative_path" if "relative_path" in m.columns else "filepath"
    
    row = m[m[col] == 'paper_02_outpatient'].iloc[0]
    fpath = row[path_col]

    print(f"DEBUGGING FILE: {os.path.basename(fpath)}")

    # Read with PIPE separator
    df = pd.read_csv(fpath, sep='|', nrows=0, engine='python')
    print("\n--- ACTUAL HEADERS (Pipe Separated) ---")
    for col in df.columns:
        print(col)
    print("---------------------------------------")

except Exception as e:
    print(f"ERROR: {e}")
