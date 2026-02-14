import sys
import runpy
import os
import argparse
from pathlib import Path

# Wrapper script to run inventory/manifest generation and create a Snakemake sentinel file.
# Expects to be run from the subproject root (Quantify-FOF-Utilization-Costs/)
# Using runpy to execute the script directly in-process avoids subprocess risks (Sourcery).

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--use-sample", action="store_true", help="Skip external inventory for CI/sample runs")
    args = parser.parse_args()

    script_path = Path("scripts/00_inventory_manifest.py")
    out_root = Path(os.getenv("OUTPUT_DIR")) if os.getenv("OUTPUT_DIR") else Path("outputs")
    output_sentinel = out_root / "manifest" / "inventory.done"

    if args.use_sample:
        output_sentinel.parent.mkdir(parents=True, exist_ok=True)
        output_sentinel.touch()
        print("Sample mode enabled, inventory scan skipped.")
        print(f"Created sentinel: {output_sentinel}")
        return 0

    if not script_path.exists():
        print(f"Error: {script_path} not found. Ensure execution from subproject root.")
        return 1

    print(f"Running {script_path} via runpy...")

    try:
        # Execute the target script in the current process
        runpy.run_path(str(script_path), run_name="__main__")
        print("Inventory script completed successfully.")
    except Exception as e:
        print(f"Inventory script failed with exception: {e}")
        return 1

    output_sentinel.parent.mkdir(parents=True, exist_ok=True)
    output_sentinel.touch()
    print(f"Created sentinel: {output_sentinel}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
