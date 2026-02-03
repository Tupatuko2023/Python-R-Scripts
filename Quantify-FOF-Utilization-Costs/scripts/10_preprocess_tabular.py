import pandas as pd
import numpy as np
import os
import sys
import argparse
import csv
from pathlib import Path

from path_resolver import get_data_root
PROJECT_ROOT = Path(__file__).resolve().parents[1]

def write_aggregates_if_allowed(allow_aggregates: bool) -> None:
    if not allow_aggregates:
        return
    if os.getenv("ALLOW_AGGREGATES") != "1":
        return
    out_dir = PROJECT_ROOT / "outputs" / "aggregates"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_file = out_dir / "aim2_aggregates.csv"
    header = ["group", "count", "suppressed"]
    rows = [["sample", "1", "1"]]
    with out_file.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(header)
        w.writerows(rows)

def load_and_preprocess(data_root: Path | None):
    print("STARTING ETL PIPELINE (REVISION: AGGREGATION AND COSTS)...")

    manifest_path = PROJECT_ROOT / "manifest" / "dataset_manifest.csv"
    std_path = PROJECT_ROOT / "data" / "VARIABLE_STANDARDIZATION.csv"
    output_dir = PROJECT_ROOT / "outputs" / "intermediate"
    output_dir.mkdir(parents=True, exist_ok=True)
    output_path = output_dir / "analysis_ready.csv"

    if not manifest_path.exists():
        print(f"ERROR: Manifest not found at {manifest_path}")
        return False
    if not std_path.exists():
        print(f"ERROR: Standardization rules not found at {std_path}")
        return False
        
    manifest = pd.read_csv(manifest_path)
    try:
        std_rules = pd.read_csv(std_path, encoding='utf-8')
    except UnicodeDecodeError:
        std_rules = pd.read_csv(std_path, encoding='cp1252')

    merged_df = pd.DataFrame()

    dataset_col = "logical_name" if "logical_name" in manifest.columns else "dataset"
    if dataset_col not in manifest.columns:
        print(f"WARNING: '{dataset_col}' column missing in manifest. Available: {manifest.columns}")
        # Fallback to simple filtering if column missing
        data_rows = pd.DataFrame() 
    else:
        data_rows = manifest[~manifest[dataset_col].str.contains("synthetic|manifest|run_log", case=False, na=False)]

    for _, row in data_rows.iterrows():
        dataset_name = row[dataset_col]
        # Handle various path columns from inventory
        filepath_raw = row.get('relative_path') or row.get('filepath') or row.get('path')
        
        if not filepath_raw:
            continue

        # Resolve path relative to DATA_ROOT if it starts with paper_02 or similar
        filepath = Path(filepath_raw)
        if not filepath.is_absolute():
            if data_root:
                filepath = data_root / filepath_raw
            else:
                filepath = PROJECT_ROOT / filepath_raw

        header_row = int(row.get('header_row', 0))
        
        print(f"\nPROCESSING: {dataset_name}")
        
        if not filepath.exists():
            print(f"  SKIP: File not found: {filepath}")
            continue
            
        try:
            if str(filepath).endswith('.xlsx'):
                df = pd.read_excel(filepath, header=header_row)
            else:
                try:
                    df = pd.read_csv(filepath, header=header_row, sep=',', engine='python', encoding='utf-8-sig')
                    if len(df.columns) < 2:
                        df = pd.read_csv(filepath, header=header_row, sep='|', engine='python', encoding='utf-8-sig')
                        if len(df.columns) < 2:
                             df = pd.read_csv(filepath, header=header_row, sep=';', engine='python', encoding='utf-8-sig')
                except:
                    df = pd.read_csv(filepath, header=header_row, sep=None, engine='python', encoding='utf-8-sig')

        except Exception as e:
            print(f"  ERROR reading file: {e}")
            continue
            
        print(f"  Columns found: {len(df.columns)}")

        rules = std_rules[std_rules['source_dataset'] == dataset_name]
        
        rename_map = {}
        for _, r in rules.iterrows():
            orig = r['original_variable']
            std = r['standard_variable']
            clean_orig = str(orig).replace('\ufeff', '')
            
            if orig in df.columns: rename_map[orig] = std
            elif clean_orig in df.columns: rename_map[clean_orig] = std
            else:
                 found = False
                 for df_col in df.columns:
                      if df_col.replace('\ufeff', '') == clean_orig:
                           rename_map[df_col] = std
                           found = True
                           break
                 if not found and orig == "FIXME_FOF_STRING" and dataset_name == "paper_02_kaaos":
                    if len(df.columns) > 33:
                        rename_map[df.columns[33]] = std
                 elif not found and orig == "Unnamed: 1" and dataset_name == "paper_02_kaaos":
                    if len(df.columns) > 1:
                        rename_map[df.columns[1]] = std
        
        # Hard fallback for ID in outpatient
        if dataset_name == "paper_02_outpatient" and "id" not in rename_map.values():
             if len(df.columns) > 0 and "Henkilotunnus" in df.columns[0]: 
                 rename_map[df.columns[0]] = "id"

        df.rename(columns=rename_map, inplace=True)
        
        # SELECT COLS
        keep_cols = [c for c in df.columns if c in rules['standard_variable'].values]
        if 'id' not in keep_cols and 'id' in df.columns: keep_cols.append('id')
            
        df = df[keep_cols].copy()
        
        if 'id' not in df.columns:
            print(f"  SKIP: 'id' missing.")
            continue
            
        # TRANSFORMS
        for _, rule_row in rules.iterrows():
            col = rule_row['standard_variable']
            rule = rule_row['transform_rule']
            if col not in df.columns: continue
                
            if rule == 'recode_01_2na':
                df[col] = pd.to_numeric(df[col], errors='coerce')
                df.loc[df[col] == 2, col] = np.nan
            elif rule == 'as_integer':
                df[col] = pd.to_numeric(df[col], errors='coerce').fillna(0).astype(int)
            elif rule == 'eur_numeric':
                if df[col].dtype == object:
                     df[col] = df[col].astype(str).str.replace(',', '.').str.replace(r'[^\d\.]', '', regex=True)
                df[col] = pd.to_numeric(df[col], errors='coerce').fillna(0.0)
            elif rule == 'date_parse_fi':
                df[col] = pd.to_datetime(df[col], format='%Y%m%d', errors='coerce')

        # AGGREGATION LOGIC (Aim 2 specific)
        if dataset_name == "paper_02_outpatient":
            print(f"  Aggregating outpatient visits for {len(df)} rows...")
            # Each row is a visit
            visits = df.groupby('id').size().reset_index(name='util_visits_total')
            # Get first age/baseline if any
            baseline_cols = [c for c in ['age', 'period_start'] if c in df.columns]
            if baseline_cols:
                aggs = {c: 'first' if c == 'age' else 'min' for c in baseline_cols}
                baseline = df.groupby('id').agg(aggs).reset_index()
                df = pd.merge(visits, baseline, on='id')
            else:
                df = visits
            print(f"  -> {len(df)} unique patients.")

        df['id'] = df['id'].astype(str)
        if merged_df.empty:
            merged_df = df
        else:
            merged_df = pd.merge(merged_df, df, on='id', how='outer')
            
    # CALCULATE COSTS (Placeholder logic since no cost column found)
    if not merged_df.empty and 'util_visits_total' in merged_df.columns:
         print("\nCALCULATING COSTS (Assumption: 60 EUR / visit)...")
         merged_df['cost_total_eur'] = merged_df['util_visits_total'] * 60.0

    print(f"\nSAVING RESULT: {output_path}")
    print(f"Total Rows: {len(merged_df)}")
    print("Columns:", merged_df.columns.tolist())
    merged_df.to_csv(output_path, index=False)
    print("DONE.")
    return True

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--use-sample", action="store_true", help="Use internal synthetic data (Not fully implemented in this script yet)")
    parser.add_argument("--allow-aggregates", action="store_true", help="Allow aggregate output")
    args = parser.parse_args()

    # In this hybrid version, we primarily run the Stashed ETL logic
    # but acknowledge the args.
    
    if args.use_sample:
        print("NOTE: --use-sample requested, but this script is currently hardcoded for manifest-based loading.")
    
    data_root_env = os.getenv("DATA_ROOT")
    data_root = get_data_root()
    if not data_root_env and not args.use_sample:
        print("ERROR: DATA_ROOT not set in config/.env", file=sys.stderr)
        raise SystemExit(0)

    success = load_and_preprocess(data_root)
    
    write_aggregates_if_allowed(args.allow_aggregates)

if __name__ == "__main__":
    main()
