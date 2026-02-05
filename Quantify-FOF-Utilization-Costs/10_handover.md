Handover to agent 3caqf — Table 1 (FOF) continuation

Context

This handover documents the current, canonical state of the Table 1 (baseline characteristics by Fear of Falling) work, and defines exact next steps for the next agent.

The work is in the Quantify-FOF-Utilization-Costs subproject.
Do not touch the Fear-of-Falling subrepo baseline scripts (e.g. K14 / K14_MAIN). Those are validated and out of scope.

---

Canonical locations (IMPORTANT)

Table 1 script (single source of truth, current on origin/main)

Quantify-FOF-Utilization-Costs/
└── R/
    └── 10_table1/
        └── 12_table1_patient_characteristics_by_fof_wfrailty.R

Output/logs location (workflow target, via PR #82)

Quantify-FOF-Utilization-Costs/
└── R/
    └── 10_table1/
        ├── .gitignore
        ├── outputs/   (gitignored)
        └── logs/      (gitignored)

Rules:

Only the canonical script generates Table 1.
No copies under scripts/.
All outputs/logs must stay inside R/10_table1/.

Note: The canonical script now lives under R/10_table1/. The legacy path is a wrapper and not a generator.

---

Current status (verified)

Analysis population

Explicit age >= 65 filter is implemented in the canonical script.
FOF missing values are excluded.
analysis_set is created once and used for all rows.

Variables already aligned

Sex, Age, BMI, Smoking, Alcohol, DM, AD, CVA

SRH (Good/Excellent – Moderate – Bad), with correct recoding

Ability to transact out of home (ATOH), 3-level

FTSST (Five times sit-to-stand), not TUG

Per-row denominators [N] = non-missing in group

Level-specific p-values for multicategory variables are implemented
(level vs. other levels, 2×2 test) via PR #81.

Output policy

CSV is written to:
R/10_table1/outputs/table1_patient_characteristics_by_fof.csv

Outputs and logs are never committed.
.gitignore in R/10_table1/ ignores outputs/** and logs/** (PR #82).

---

Outstanding work: Frailty (NEW TASK)

Goal

Add Frailty (Fried), 3-class to Table 1:

robust
pre-frail
frail

Grouped by FOF (No / Yes), consistent with the manuscript.

Ground truth

Frailty definition already exists in project analyses (e.g. frailty_fried in 70_separated_outcomes_analysis.R)

Levels are conceptually locked:

robust → pre-frail → frail

Required implementation (summary)

Fail-closed column pick (no guessing)

Robust recoding helper supporting:

numeric codings (0/1/2 or 1/2/3)

string variants

Factor with ordered levels

Add as summ_multicat("Frailty (Fried), n (%)", ...)

Level-specific p-values should work automatically

⚠️ Do not modify other variables or output paths.

---

TASK MANAGEMENT (MANDATORY)

Before implementing frailty:

1. Create a new task from the template

Copy tasks/_template.md

Name it something like:

tasks/01-ready/table1_add_frailty.md


2. Fill it according to WORKFLOW.md

Problem statement

Assumptions

Planned steps


3. Move it to 02-in-progress/ when starting work.


4. Log decisions and checks in the task file.


5. Move to 04-done/ only when finished and reviewed.


No work should start without a task file.

---

Explicit non-goals (do NOT do)

❌ Do not edit Fear-of-Falling/K14 scripts

❌ Do not change analysis population definitions

❌ Do not write outputs to shared outputs/ or outputs/tables

❌ Do not commit CSVs or logs

❌ Do not refactor unrelated code

---

Definition of Done (Frailty task)

Table 1 includes a new block:

Frailty (Fried), n (%)
  robust
  pre-frail
  frail

Correct denominators per row

Header-level and level-specific p-values present

Script still runs fail-closed

Only .R file + task markdown committed

Outputs remain local only

---

If anything is unclear

Stop and ask before coding.
Assumptions must be written to the task file.

---

End of handover.
