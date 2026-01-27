Operational checklist

Before running with real data
[ ] DATA_ROOT is absolute and points to a secure repo-external location
[ ] config/.env exists locally and is NOT staged/committed
[ ] Run inventory after receiving new paper_02 batch: python scripts/00_inventory_manifest.py --scan paper_02
[ ] Confirm whether aggregates are permitted (ALLOW_AGGREGATES remains 0 unless explicitly approved)

After running
[ ] git status -sb shows no tracked raw data or secrets
[ ] Any outputs are under gitignored paths (outputs/, docs/derived_text/)
[ ] If sharing results internally:
    - Share only suppressed aggregates, non-sensitive reports, and/or knowledge package zip/index
    - Never share config/.env or any repo-external raw data files
