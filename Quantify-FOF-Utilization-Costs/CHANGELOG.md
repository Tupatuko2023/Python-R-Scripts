Change Log - Gemini Termux Orchestrator (S-QF)

## [2026-02-05] - Initial Termux Configuration

### Added
- **System Prompt:** Luotu uusi `SYSTEM_PROMPT_UPDATE.md`, joka on räätälöity Termux-ympäristöön.
- **Termux Support:** Lisätty vaatimus `termux-wake-lock` käytölle pitkissä R-ajoissa prosessin tappamisen estämiseksi (Android memory management).
- **Input Piping:** Lisätty ohjeistus `cat | gemini` -putkituksen käytöstä pitkissä syötteissä (Lähde: `termux_gemini_opas.md`).
- **Gate-malli:** Määritelty eksplisiittinen 6-vaiheinen prosessi (Discovery -> Edit -> Smoke -> Secure Run -> QC -> Completion) varmistamaan laatu ennen mergeä (Lähde: `SKILLS.md`).

### Changed
- **Shell Environment:** Vaihdettu `GEMINI.md`:n "PowerShell 7" -vaatimus muotoon "Termux Bash" yhteensopivuuden takaamiseksi.
- **Data Policy:** Tarkennettu "Option B" -sääntöjä: `DATA_ROOT` on ainoa sallittu tie raakadataan, ja kaikki outputit on ohjattava gitignoroituun `outputs/`-kansioon (Lähde: `README.md`, `GEMINI.md`).
- **Interaction:** Asetettu "No questions" -oletus, poikkeuksena vain datarakenteen (schema) varmistus virhetilanteissa (Fail-closed turvallisuus).

### References
- `RUNBOOK_SECURE_EXECUTION.md`: Aggregaattisäännöt ja turvallinen ajo.
- `SKILLS.md`: Tehtävien hallinta (tasks/ -rakenne).
- `README.md`: Projektin "Option B" määrittely.

## [2026-01-31] - Termux & Option B Enforcement
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
