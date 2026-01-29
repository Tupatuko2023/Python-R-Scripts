import os
import argparse
import pandas as pd
from pathlib import Path

def load_data(use_sample=False):
    if use_sample:
        print("MODE: Using synthetic sample data (CI-safe).")
        p = Path("data/synthetic_sample.csv")
        if not p.exists():
            raise FileNotFoundError(f"Synthetic sample missing at {p}")
        return pd.read_csv(p)
    else:
        root = os.getenv("DATA_ROOT")
        if not root:
            print("ERROR: DATA_ROOT not set and --use-sample not specified.")
            print("Action: Set DATA_ROOT in config/.env or run with --use-sample")
            return None
        # Placeholder for real data loading logic
        print(f"MODE: Loading external data from {root} (Option B)")
        return pd.DataFrame() # Return empty for now to avoid crash

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--use-sample", action="store_true", help="Use internal synthetic data")
    args = parser.parse_args()

    df = load_data(use_sample=args.use_sample)
    if df is not None and not df.empty:
        print(f"SUCCESS: Loaded data with shape {df.shape}")
        print(df.head())
    else:
        print("WARNING: No data loaded.")

if __name__ == "__main__":
    main()