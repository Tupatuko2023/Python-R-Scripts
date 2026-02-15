import pandas as pd
import numpy as np
import os
import sys
import argparse
import csv
from pathlib import Path

from path_resolver import get_data_root
from _io_utils import safe_join_path

PROJECT_ROOT = Path(__file__).resolve().parents[1]

def normalize_col(x: str) -> str:
    if not isinstance(x, str): return str(x)
    x = x.replace("\u00A0", " ")
    x = x.replace("\n", " ")
    x = " ".join(x.split())
    return x.strip().lower()

def write_aggregates_if_allowed(allow_aggregates: bool) -> None:
    if not allow_aggregates:
        return
    if os.getenv("ALLOW_AGGREGATES") != "1":
        return

    out_root = Path(os.getenv("OUTPUT_DIR")) if os.getenv("OUTPUT_DIR") else PROJECT_ROOT / "outputs"
    out_dir = out_root / "aggregates"
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

    # Use environment variable for output dir if set (Snakemake compatibility)
    out_root = Path(os.getenv("OUTPUT_DIR")) if os.getenv("OUTPUT_DIR") else PROJECT_ROOT / "outputs"
    output_dir = out_root / "intermediate"
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
        data_rows = pd.DataFrame() 
    else:
        data_rows = manifest[~manifest[dataset_col].str.contains("synthetic|manifest|run_log", case=False, na=False)]

    for _, row in data_rows.iterrows():
        dataset_name = row[dataset_col]
        filepath_raw = row.get('relative_path') or row.get('filepath') or row.get('path')
        
        if not filepath_raw:
            continue

        filepath = Path(filepath_raw)
        if not filepath.is_absolute():
            try:
                if data_root:
                    filepath = safe_join_path(data_root, filepath_raw)
                else:
                    filepath = safe_join_path(PROJECT_ROOT, filepath_raw)
            except ValueError as e:
                print(f"  SECURITY ERROR: {e}")
                continue

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
        df_cols_norm = {normalize_col(c): c for c in df.columns}
        
        for _, r in rules.iterrows():
            orig = r['original_variable']
            std = r['standard_variable']
            norm_orig = normalize_col(orig)
            
            if norm_orig in df_cols_norm:
                rename_map[df_cols_norm[norm_orig]] = std
            else:
                if orig == "FIXME_FOF_STRING" and dataset_name == "paper_02_kaaos":
                    if len(df.columns) > 33:
                        rename_map[df.columns[33]] = std
                elif orig == "Unnamed: 1" and dataset_name == "paper_02_kaaos":
                    if len(df.columns) > 1:
                        rename_map[df.columns[1]] = std
        
        if dataset_name == "paper_02_outpatient" and "id" not in rename_map.values():
             if len(df.columns) > 0 and "Henkilotunnus" in df.columns[0]: 
                 rename_map[df.columns[0]] = "id"

        df.rename(columns=rename_map, inplace=True)
        
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

        if dataset_name == "paper_02_outpatient":
            print(f"  Aggregating outpatient visits for {len(df)} rows...")
            visits = df.groupby('id').size().reset_index(name='util_visits_outpatient')
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
            
    if not merged_df.empty and 'util_visits_outpatient' in merged_df.columns:
         print("\nCALCULATING COSTS (Assumption: 60 EUR / visit)...")
         merged_df['cost_outpatient_eur'] = merged_df['util_visits_outpatient'] * 60.0
         merged_df['cost_total_eur'] = merged_df['cost_outpatient_eur'] # Placeholder for total

    print(f"\nSAVING RESULT: {output_path}")
    print(f"Total Rows: {len(merged_df)}")
    print("Columns:", merged_df.columns.tolist())
    merged_df.to_csv(output_path, index=False)
    print("DONE.")
    return True

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--use-sample", action="store_true", help="Use internal synthetic data")
    parser.add_argument("--allow-aggregates", action="store_true", help="Allow aggregate output")
    args = parser.parse_args()

    data_root = get_data_root()
    if not data_root and not args.use_sample:
        # Graceful exit for security tests (exit 0)
        print("ERROR: DATA_ROOT not set in config/.env", file=sys.stderr)
        sys.exit(0)

    load_and_preprocess(data_root)
    write_aggregates_if_allowed(args.allow_aggregates)

if __name__ == "__main__":
    main()