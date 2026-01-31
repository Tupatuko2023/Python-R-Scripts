title: "Security Audit & Path Sanitization"
status: "todo"
created: "2026-01-29"
priority: "critical"
tags: ["security", "hygiene"]

Objective
Ensure no absolute paths to sensitive data are committed to git or displayed in verbose logs.
Address User concern about terminal output leakage.

Checks

1. **Manifest Safety**:

* Check \manifest/dataset_manifest.csv\. If it contains absolute paths (e.g., "C:/Users/..."), ensure \manifest/\ is added to \.gitignore\.
* If manifest must be shared, convert paths to relative or use a hash.
* Recommended action: Add \manifest/dataset_manifest.csv\ to \.gitignore\ immediately if not present.

1. **Git History Check**:

* Run \git status\ and ensure no secrets or external data files are staged.

1. **Output Hygiene**:

* When reporting file locations, replace the absolute prefix with \{DATA_ROOT}\.
* Example: instead of \Z:\Secure\Data\file.csv\, output \{DATA_ROOT}/file.csv\.

Next Steps after Audit

* Once hygiene is secured, return to the FOF variable investigation (KAAOS_data.xlsx).
