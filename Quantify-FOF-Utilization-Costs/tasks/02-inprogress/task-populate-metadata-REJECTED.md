---
title: Populate Data Dictionary and Standardization Rules (Aim 2)
status: ready
assignee: gpa4qf
priority: high
---

# Context

The current files in data/ are structural stubs. We need to populate them with the actual research variables defined in Aim 2 (Utilization & Costs).

# Inputs

* Muuttujasanakirja.md (uploaded logic)
* methodology.md (metrics definitions)

# Requirements

1. **Update data/data_dictionary.csv**:
    * Replace stubs with full variable list.
    * **Key Variables**:
        * Identifiers: id (pseudonymized string)
        * Time: period_start, period_end (ISO-8601), ollowup_days (integer)
        * FOF: FOF_status (0=No, 1=Yes)
        * Utilization (counts): util_visits_total, util_visits_outpatient, util_visits_inpatient, util_visits_emergency, util_visits_primarycare.
        * Burden: util_days_inpatient.
        * Costs (EUR): cost_total_eur, cost_inpatient_eur, cost_outpatient_eur, cost_medication_eur.
        * Demographics: ge (integer), sex (coding TBD), mi (float).
    * Ensure 'type', 'unit', and 'coding' columns are filled accurately.

2. **Update data/VARIABLE_STANDARDIZATION.csv**:
    * Define mapping rules from hypothetical register dump ('paper_02_raw') to standardized schema.
    * Examples:
        * isits_all -> util_visits_total (rule: as_integer)
        * cost_sum -> cost_total_eur (rule: eur_numeric)
        * dob -> ge (rule: calculate_age_at_period_start)

3. **Validation**:
    * Ensure all variables in Standardization target exist in Dictionary.
