import os
import sys
import argparse
import datetime
import csv
from pathlib import Path

from path_resolver import get_data_root, safe_join_path

def log_run(status, message):
    """Append a log entry to manifest/run_log.csv."""
    log_file = Path("manifest/run_log.csv")
    timestamp = datetime.datetime.now().isoformat()
    actor = os.getenv("USERNAME", os.getenv("USER", "unknown_agent"))
    script = os.path.basename(__file__)

    if log_file.exists():
        with open(log_file, "a", newline="") as f:
            writer = csv.writer(f)
            # Schema: timestamp,actor,script,status,message
            writer.writerow([timestamp, actor, script, status, message])

def scan_inventory(data_root, target_dataset):
    """Mock scan function for Option B inventory."""
    if not data_root:
        print("ERROR: DATA_ROOT not set in config/.env")
        log_run("FAILURE", "DATA_ROOT missing")
        return

    try:
        target_path = safe_join_path(Path(data_root), target_dataset)
    except ValueError as e:
        print(f"SECURITY ERROR: {e}")
        log_run("FAILURE", f"Security Violation: {target_dataset}")
        return

    if not target_path.exists():
        print(f"WARNING: Target dataset path not found: {target_path}")
        log_run("WARNING", f"Path not found: {target_dataset}")
        return

    print(f"Scanning {target_path}...")
    try:
        files = list(target_path.glob("*"))
        print(f"Found {len(files)} files/dirs in {target_dataset}")
        log_run("SUCCESS", f"Scanned {target_dataset}, found {len(files)} items")
    except Exception as e:
        print(f"ERROR: {e}")
        log_run("FAILURE", str(e))

def main():
    parser = argparse.ArgumentParser(description="Manage dataset inventory (Option B).")
    parser.add_argument("--scan", help="Scan a dataset folder under DATA_ROOT", type=str)
    args = parser.parse_args()

    data_root = get_data_root()

    if args.scan:
        scan_inventory(data_root, args.scan)
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
