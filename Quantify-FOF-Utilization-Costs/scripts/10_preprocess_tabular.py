import os
import sys
import argparse
import csv
from pathlib import Path

def load_data(use_sample=False):
    if use_sample:
        print("MODE: Using synthetic sample data (CI-safe).")
        p = Path("data/synthetic_sample.csv")
        if not p.exists():
            raise FileNotFoundError(f"Synthetic sample missing at {p}")
        try:
            import pandas as pd
        except ImportError:
            raise SystemExit("Missing dependency for tabular preprocessing.")
        return pd.read_csv(p)
    else:
        root = os.getenv("DATA_ROOT")
        if not root:
            print("ERROR: DATA_ROOT not set and --use-sample not specified.")
            print("Action: Set DATA_ROOT in config/.env or run with --use-sample")
            return None
        # Placeholder for real data loading logic
        print(f"MODE: Loading external data from {root} (Option B)")
        try:
            import pandas as pd
        except ImportError:
            raise SystemExit("Missing dependency for tabular preprocessing.")
        return pd.DataFrame()  # Return empty for now to avoid crash

def write_aggregates_if_allowed(allow_aggregates: bool) -> None:
    if not allow_aggregates:
        return
    if os.getenv("ALLOW_AGGREGATES") != "1":
        return
    out_dir = Path("outputs/aggregates")
    out_dir.mkdir(parents=True, exist_ok=True)
    out_file = out_dir / "aim2_aggregates.csv"
    header = ["group", "count", "suppressed"]
    rows = [["sample", "1", "1"]]
    with out_file.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(header)
        w.writerows(rows)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--use-sample", action="store_true", help="Use internal synthetic data")
    parser.add_argument("--allow-aggregates", action="store_true", help="Allow aggregate output")
    args = parser.parse_args()

    df = load_data(use_sample=args.use_sample)
    if df is not None and not df.empty:
        print(f"SUCCESS: Loaded data with shape {df.shape}")
        print(df.head())
    else:
        print("WARNING: No data loaded.")
    write_aggregates_if_allowed(args.allow_aggregates)

if __name__ == "__main__":
    main()
