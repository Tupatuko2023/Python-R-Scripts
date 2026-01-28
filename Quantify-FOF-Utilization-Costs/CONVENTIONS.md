Conventions (Quantify FOF)

Non-negotiables

- Do not commit raw or decrypted data, secrets, or machine-specific paths.
- Option B: raw data is repo-external; repo contains metadata + scripts + synthetic test data only.

Output discipline

- All generated artifacts go under Quantify-FOF-Utilization-Costs/outputs/ (gitignored).
- Scripts must be safe-by-default: if DATA_ROOT is unset or inputs are missing, they exit with clear instructions.

Manifest discipline

- manifest/dataset_manifest.csv: describes repo-external datasets by logical name, glob, checksum, schema ref, etc.
- manifest/run_log.csv: records pipeline runs at metadata-level (no sensitive rows).

Testing

- CI-safe: tests must pass with only synthetic sample data under data/sample/.
