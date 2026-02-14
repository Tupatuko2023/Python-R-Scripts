import sys
import subprocess
from pathlib import Path

# Wrapper script to run inventory/manifest generation and create a Snakemake sentinel file.
# Expects to be run from the subproject root (Quantify-FOF-Utilization-Costs/)
import os

script_path = Path("scripts/00_inventory_manifest.py")
out_root = Path(os.getenv("OUTPUT_DIR")) if os.getenv("OUTPUT_DIR") else Path("outputs")
output_sentinel = out_root / "manifest" / "inventory.done"

if not script_path.exists():
    print(f"Error: {script_path} not found. Ensure execution from subproject root.")
    sys.exit(1)

print(f"Running {script_path}...")
# Pass along any arguments if needed, but for now we run default
result = subprocess.run([sys.executable, str(script_path)], capture_output=True, text=True)

if result.returncode != 0:
    print("Inventory script failed:")
    print(result.stdout)
    print(result.stderr)
    sys.exit(result.returncode)
else:
    print(result.stdout)
    print("Inventory script completed successfully.")

# Create sentinel file for Snakemake
output_sentinel.parent.mkdir(parents=True, exist_ok=True)
output_sentinel.touch()
print(f"Created sentinel: {output_sentinel}")
