Post-merge verification & paper_02 delivery lock

Orchestration packet (qfta2)

Agent: qfta2

Default gate sequence (reminder): docs → tests → sample QC → inventory manifest → (assembly/QC as needed) → report → knowledge package

Option B red lines:

No absolute paths anywhere.

Logs must say only “--input provided locally”.

No raw values in logs or artifacts.

Outputs only under outputs/ (gitignored).

Manifests are metadata-only.

Never commit outputs/ or docs/derived_text/.


Context

PR #70 (paper_02 integration map + assembly + QC hardening) is merged. This task confirms main is stable, and then locks paper_02 as a delivered unit (metadata-only).

Objective

1. Post-merge CI-safe verification on main (sample-only):


unittest discover

qc_summary --use-sample

end_to_end_smoke

build_report

build_knowledge_package


2. paper_02 delivery lock (metadata-only):


Update manifest metadata to mark paper_02 as “FROZEN/DELIVERED” (no data, no paths).

Ensure any suppression rule reminders remain documented (n<5 suppressed) when aggregates are later explicitly enabled.


3. Task tracking:


Do NOT move paper_02 task to tasks/04-done without explicit human instruction.

Record only safe log lines.


Commands (CI-safe)

python -m unittest discover -s Quantify-FOF-Utilization-Costs/tests

python Quantify-FOF-Utilization-Costs/scripts/30_qc_summary.py --use-sample

python -m unittest Quantify-FOF-Utilization-Costs.tests.test_end_to_end_smoke

python Quantify-FOF-Utilization-Costs/scripts/50_build_report.py

python Quantify-FOF-Utilization-Costs/scripts/40_build_knowledge_package.py


Acceptance criteria

All CI-safe validations succeed on main.

paper_02 marked frozen/delivered in metadata-only manifest without leaking paths.

No outputs/ or derived_text/ are staged or committed.

No move to tasks/04-done.


Log (safe only)

--input provided locally

POST_MERGE_VERIFY_SUCCESS or POST_MERGE_VERIFY_FAILURE

1–3 bullets: what was checked/enforced (no paths, no raw values)
