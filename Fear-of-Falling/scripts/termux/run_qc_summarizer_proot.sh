#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
FOF_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)"
QC_SKILL_R="$FOF_ROOT/../.codex/skills/fof-qc-summarizer/scripts/qc_summarize.R"

echo "FOF_ROOT=$FOF_ROOT"

# Host-side path gate (before entering proot).
command -v proot-distro >/dev/null 2>&1 || {
  echo "FATAL: proot-distro missing (pkg install -y proot-distro)"
  exit 1
}
test -f "$QC_SKILL_R" || { echo "FATAL: missing qc_summarize.R at: $QC_SKILL_R"; exit 1; }

# Ensure PRoot Debian exists (install step is safe if already installed).
if ! proot-distro list 2>/dev/null | grep -q '^debian'; then
  echo "INFO: proot debian not found; installing..."
  proot-distro install debian
fi

proot-distro login debian --termux-home -- bash -lc "
set -euo pipefail

cd '$FOF_ROOT' || exit 1

echo '=== RSCRIPT gate ==='
echo \"Rscript=\$(command -v Rscript || true)\"
Rscript --version || { echo 'FATAL: Rscript missing in this environment'; exit 1; }

echo '=== renv restore (policy: project requires renv) ==='
R -q -e 'if (!requireNamespace(\"renv\", quietly=TRUE)) install.packages(\"renv\"); renv::restore(prompt=FALSE)'

echo '=== qc-summarize ==='
test -f '../.codex/skills/fof-qc-summarizer/scripts/qc_summarize.R' || { echo 'FATAL: qc_summarize.R missing under ../.codex/...'; exit 1; }
Rscript ../.codex/skills/fof-qc-summarizer/scripts/qc_summarize.R \
  --qc-dir R-scripts/K18_QC/outputs/K18_QC/qc \
  --out-dir R-scripts/K18_QC/outputs/K18_QC/qc_summary \
  --script-label K18_QC_SUMMARY

echo '=== outputs ==='
ls -la R-scripts/K18_QC/outputs/K18_QC/qc_summary || true

echo '=== manifest tail ==='
tail -n 30 manifest/manifest.csv || true

echo '=== privacy gate (id search) ==='
if command -v rg >/dev/null 2>&1; then
  rg -n '(^|,|[[:space:]])id(,|[[:space:]]|$)' -S R-scripts/K18_QC/outputs/K18_QC/qc_summary || true
else
  echo 'rg missing (install in proot: apt-get update && apt-get install -y ripgrep)'
fi
"
