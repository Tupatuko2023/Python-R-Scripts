Change Log - Gemini Termux Orchestrator (S-QF)
[2026-01-31] - Termux & Option B Enforcement
Changed
 * System Prompt (GEMINI.md context):
   * Replaced PowerShell 7 requirement with Termux Bash policy.
   * Added Termux Wake Lock requirement for long-running R scripts (Ref: Termux Power Management).
   * Hardened Option B rules: Explicitly forbade head()/printing raw data, allowed only schema checks (names()).
   * Updated Operational Commands to use python3 and termux-wake-lock wrappers.
 * Agent Description:
   * Updated to reflect Hybrid R+Python and Termux specialization.
   * Added "Fail-Closed" security posture.
Sources
 * README.md: Option B data policy.
 * RUNBOOK_SECURE_EXECUTION.md: Aggregation & Output safety rules.
 * SKILLS.md: Task workflow & Gate logic.
 * Termux Documentation: termux-wake-lock usage.
