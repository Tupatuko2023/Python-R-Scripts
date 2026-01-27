data/

Allowed in-repo contents:
- Metadata (data_dictionary.csv, VARIABLE_STANDARDIZATION.csv)
- Synthetic sample data for tests: data/sample/

Not allowed:
- Raw participant-level data
- Decrypted register extracts
- Any sensitive controller-delivered files

Raw data location:
- Repo-external directory referenced by DATA_ROOT in config/.env (not committed)
