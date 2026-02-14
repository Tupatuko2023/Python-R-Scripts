import sys
import subprocess
import os
from pathlib import Path

# Wrapper script to run inventory/manifest generation and create a Snakemake sentinel file.
# Expects to be run from the subproject root (Quantify-FOF-Utilization-Costs/)

script_path = Path("scripts/00_inventory_manifest.py")
out_root = Path(os.getenv("OUTPUT_DIR")) if os.getenv("OUTPUT_DIR") else Path("outputs")
output_sentinel = out_root / "manifest" / "inventory.done"

if not script_path.exists():
    print(f"Error: {script_path} not found. Ensure execution from subproject root.")
    sys.exit(1)

print(f"Running {script_path}...")

try:
    # Use check=True to raise CalledProcessError on failure, avoiding manual check logic
    # and ensuring proper error propagation (best practice).
    result = subprocess.run(
        [sys.executable, str(script_path)],
        capture_output=True,
        text=True,
        check=True
    )
    print(result.stdout)
    print("Inventory script completed successfully.")
except subprocess.CalledProcessError as e:
    print("Inventory script failed:")
    print(e.stdout)
    print(e.stderr)
    sys.exit(e.returncode)

# Create sentinel file for Snakemake
output_sentinel.parent.mkdir(parents=True, exist_ok=True)
output_sentinel.touch()
print(f"Created sentinel: {output_sentinel}")
