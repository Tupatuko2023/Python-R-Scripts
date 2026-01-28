Allowed aggregate outputs (Aim 2) — Spec

Purpose: enable analysis-ready non-sensitive summaries without writing participant-level rows into the repository.

Guardrails (non-negotiable)

- Aggregates MUST NOT include participant identifiers (e.g., id) or any row-level quasi-identifiers.
- Aggregates are written only under Quantify-FOF-Utilization-Costs/outputs/aggregates/ (gitignored).
- Aggregates are disabled by default and require a double opt-in:
  1. ALLOW_AGGREGATES=1 in local config/.env (never committed), AND
  2. Script flag --allow-aggregates.

Output file

- outputs/aggregates/aim2_aggregates.csv

Grouping keys (default)

- FOF_status (0/1)
- Optional future keys (only if permitted and non-sensitive): sex (coding TBD), age_band (bands TBD)

Metrics (default)

- n (group size)
- util_visits_total_sum
- util_visits_total_mean
- cost_total_eur_sum
- cost_total_eur_mean

Small-cell suppression

- Suppress groups with n < 5:
  - keep n as-is
  - set metric fields to empty
  - set suppressed=1
- Non-suppressed groups: suppressed=0

Rounding

- EUR metrics: 2 decimals
- Counts: integer

Notes
This spec is metadata-only and designed to be safe-by-default. Any expansion of grouping keys or metrics must preserve the guardrails above.
