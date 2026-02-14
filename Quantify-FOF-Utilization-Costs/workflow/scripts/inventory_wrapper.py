import sys
import runpy
import os
from pathlib import Path

# Wrapper script to run inventory/manifest generation and create a Snakemake sentinel file.
# Expects to be run from the subproject root (Quantify-FOF-Utilization-Costs/)
# Using runpy to execute the script directly in-process avoids subprocess risks (Sourcery).

script_path = Path("scripts/00_inventory_manifest.py")
out_root = Path(os.getenv("OUTPUT_DIR")) if os.getenv("OUTPUT_DIR") else Path("outputs")
output_sentinel = out_root / "manifest" / "inventory.done"

if not script_path.exists():
    print(f"Error: {script_path} not found. Ensure execution from subproject root.")
    sys.exit(1)

print(f"Running {script_path} via runpy...")

try:
    # Execute the target script in the current process
    runpy.run_path(str(script_path), run_name="__main__")
    print("Inventory script completed successfully.")
except Exception as e:
    print(f"Inventory script failed with exception: {e}")
    sys.exit(1)

# Create sentinel file for Snakemake
output_sentinel.parent.mkdir(parents=True, exist_ok=True)
output_sentinel.touch()
print(f"Created sentinel: {output_sentinel}")
