title: "Introspect Raw Headers & Fix Standardization"
status: "todo"
created: "2026-01-29"
priority: "critical"
context: "User rejected previous metadata because it contained placeholder variable names (stubs) instead of real data headers."

Objective
The Agent must "see" the actual raw data headers to create a valid mapping.
Since we cannot ask the user for names, we must read them from the source file listed in the manifest.

Steps

1. **Identify Source File**: Read `manifest/dataset_manifest.csv` to find the path of the raw data file (dataset="paper_02" or similar).
2. **Read Headers**: Use a one-off Python script to read just the first row (columns) of that secure file.
3. **Update VARIABLE_STANDARDIZATION.csv**:
* Clear the `paper_02_raw` placeholder rows.
* Insert rows for the *actual* columns found in the file.
* `source_dataset`: Use the actual filename.
* `original_variable`: Use the actual column header.
* `standard_variable`: Attempt to map to Aim 2 variables (e.g., if header is "kayntimäärä" -> map to "util_visits_total"). If unknown, set to "FIXME".


4. **Verify**: Show the first 5 rows of the new CSV to prove real headers are used.