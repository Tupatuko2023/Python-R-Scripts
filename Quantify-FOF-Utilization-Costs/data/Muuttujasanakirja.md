Muuttujasanakirja (human-readable)

Tama dokumentti kuvaa muuttujat metatasolla (ei sisalla osallistujatason arvoja).
Katso koneellinen versio: data/data_dictionary.csv.

Synteettinen esimerkki

- id: synteettinen tunniste
- FOF_status: 0/1
- util_visits_total: kayntien lukumaara (ei negatiivinen)
- cost_total_eur: kustannukset euroina (ei negatiivinen)

Aim 2 (placeholder-muuttujat, paper*02*\*)

- period_start, period_end: havaintojakson aloitus/lopetus (ISO-8601)
- followup_days: seuranta-aika paivina
- util_visits_total/outpatient/inpatient/emergency/primarycare: kayntien lukumaarat
- util_days_inpatient: vuodepaivat
- cost_total_eur + osakomponentit (inpatient/outpatient/medication)
- covariates: age, sex (TBD), BMI (kg/m^2), FOF_status (TBD)

Kaikki Aim 2 -rivit ovat placeholder-tasolla ja tarkennetaan controllerin toimittaman skeeman mukaan.
