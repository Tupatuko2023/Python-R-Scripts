#!/usr/bin/env sh
set -eu

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
  echo "Usage: bash diagram/render_paper_01_cohort_flow.sh <LONG|WIDE> <outcome> [placeholders_csv]" >&2
  exit 1
fi

shape_upper=$1
outcome=$2
shape_lower=$(printf '%s' "$shape_upper" | tr '[:upper:]' '[:lower:]')

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
project_root=$(CDPATH= cd -- "$script_dir/.." && pwd)
template_path="$project_root/diagram/paper_01_cohort_flow.dot"
placeholders_path=${3:-"$project_root/R-scripts/K50/outputs/k50_${shape_lower}_${outcome}_cohort_flow_placeholders.csv"}
resolved_path="$project_root/diagram/paper_01_cohort_flow.${shape_lower}.${outcome}.resolved.dot"
svg_path="$project_root/diagram/paper_01_cohort_flow.${shape_lower}.${outcome}.svg"
png_path="$project_root/diagram/paper_01_cohort_flow.${shape_lower}.${outcome}.png"

if [ ! -f "$template_path" ]; then
  echo "Template not found: $template_path" >&2
  exit 1
fi

if [ ! -f "$placeholders_path" ]; then
  echo "Placeholder CSV not found: $placeholders_path" >&2
  exit 1
fi

python - "$template_path" "$placeholders_path" "$resolved_path" <<'PY'
import csv
import sys

template_path, placeholders_path, resolved_path = sys.argv[1:]
with open(template_path, "r", encoding="utf-8") as fh:
    text = fh.read()

with open(placeholders_path, "r", encoding="utf-8", newline="") as fh:
    reader = csv.DictReader(fh)
    for row in reader:
        text = text.replace(f"__{row['placeholder']}__", str(row["value"]))

with open(resolved_path, "w", encoding="utf-8") as fh:
    fh.write(text)
PY

dot -Tsvg "$resolved_path" -o "$svg_path"
dot -Tpng "$resolved_path" -o "$png_path"

python - "$project_root" "$resolved_path" "$svg_path" "$png_path" "$shape_lower" "$outcome" <<'PY'
import csv
import os
import sys
from datetime import datetime

project_root, resolved_path, svg_path, png_path, shape_lower, outcome = sys.argv[1:]
manifest_path = os.path.join(project_root, "manifest", "manifest.csv")
os.makedirs(os.path.dirname(manifest_path), exist_ok=True)

def relpath(path):
    abs_root = os.path.abspath(project_root)
    abs_path = os.path.abspath(path)
    if abs_path.startswith(abs_root + os.sep):
        return abs_path[len(abs_root) + 1 :]
    return path

rows = []
prefix = f"k50_{shape_lower}_{outcome}_cohort_flow"
for label, kind, path, notes in (
    (f"{prefix}_resolved_dot", "text", resolved_path, "Resolved DOT source for paper_01 cohort flow render"),
    (f"{prefix}_svg", "figure_svg", svg_path, "Rendered SVG for paper_01 cohort flow"),
    (f"{prefix}_png", "figure_png", png_path, "Rendered PNG for paper_01 cohort flow"),
):
    rows.append({
        "timestamp": datetime.now().isoformat(sep=" ", timespec="seconds"),
        "script": "K50.1_COHORT_FLOW",
        "label": label,
        "kind": kind,
        "path": relpath(path),
        "n": "",
        "notes": notes,
    })

header = ["timestamp", "script", "label", "kind", "path", "n", "notes"]
write_header = not os.path.exists(manifest_path)
with open(manifest_path, "a", encoding="utf-8", newline="") as fh:
    writer = csv.DictWriter(fh, fieldnames=header)
    if write_header:
        writer.writeheader()
    writer.writerows(rows)
PY

echo "Rendered cohort flow:"
echo "  $resolved_path"
echo "  $svg_path"
echo "  $png_path"
