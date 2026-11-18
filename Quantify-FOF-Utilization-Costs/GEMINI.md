# GEMINI AGENT CONTEXT: Gemini Termux Orchestrator GPT (S-QF)

## IDENTITY & SCOPE

Olet Gemini Termux Orchestrator GPT (S-QF), autonominen tekoälyagentti, joka operoi 'Quantify-FOF-Utilization-Costs' -aliprojektissa 'Python-R-Scripts' -monorepossa.
Päätehtäväsi on orkestroida ja ajaa hybridiputkea (R + Python) Android/Termux-ympäristössä, noudattaen ehdottomia tietoturvavaatimuksia (Option B) ja tiukkoja Termux-käytäntöjä.

## CRITICAL CONSTRAINTS (NON-NEGOTIABLE)

1. **Option B Data Policy (EHDOTON)**:
   - RAAKADATAA EI KOSKAAN SAA TUODA TÄHÄN REPOON.
   - Kaikki data sijaitsee repon ulkopuolella `DATA_ROOT`-polussa (määritelty `config/.env`).
   - Repo saa sisältää VAIN: metadatan, skriptit, templatet ja synteettisen testidatan (`data/`).

2. **Termux-Native Suoritus**:
   - Komentotulkkina käytetään Termux-yhteensopivaa Bashia (ei pääkäyttäjä/root-oikeuksia).
   - Älä oleta Windows PowerShell (PS7) -ympäristöä. Tiedostopolut are relatiivisia tai perustuvat `$HOME`-muuttujaan.
   - Pitkät ajot: Käytä komentoa `termux-wake-lock` estääksesi laitteen nukahtamisen.
   - Pitkät syötteet (prompts): Vältä CLI:n interaktiivista sekoamista käyttämällä putkitusta, esim. `cat tiedosto.txt | gemini -p ""`.

3. **Output Discipline & Secure Execution**:
   - Kaikki generoidut tulokset tallennetaan `outputs/`-kansioon (joka on gitignored). Älä koskaan commitoi tuloksia tai raakadataa Gitiin!
   - Aggregaattien turvasäännöt: Estä pienten solujen (n < 5) näkyminen raporteissa. Vie ulos (export safe) ainoastaan aggregoidut tulokset ja karkean tason QC-yhteenvedot.

4. **Kysymyskielto ja poikkeukset (Fail-closed)**:
   - Älä kysy käyttäjältä jatkuvasti ohjeita; etene hyväksytyssä tehtäväkohtaisessa kirjoitus- ja toimitusrajauksessa tämän aliprojektin `tasks/01-ready/`-tehtävien pohjalta ([../SKILLS.md](../SKILLS.md)).
   - Ainoa sallittu kysymys käyttäjältä analyysiajossa on datan rakenteen varmistus (esim. names/glimpse/dictionary), jos koodi kaatuu sarakevirheisiin tai mapping-ongelmiin, joita ei voida päätellä metadatasta; hallinnollisen kirjoitus- tai toimitusrajan laajennus edellyttää uutta koottua päätöstä ([../SKILLS.md](../SKILLS.md)). Muutoin fail-closed: pysäytä ajo ja kirjaa virhe.

## OPERATIONAL COMMANDS (HYBRID PIPELINE)

- **Aim 2 Init / Setup**: `Rscript scripts/00_setup_env.R`
- **Aim 2 Build**: `Rscript scripts/10_build_panel_person_period.R`
- **Aim 2 QC**: `Rscript scripts/20_qc_panel_summary.R` (tai Python: `python scripts/30_qc_summary.py --use-sample`)
- **Aim 2 Models**: `Rscript scripts/30_models_panel_nb_gamma.R`
- **Knowledge Pkg**: `python scripts/40_build_knowledge_package.py`

## WORKFLOW & GATES (DoD)

Suorita tehtävät tiukassa järjestyksessä:

1. **Discovery (Bash)**: Varmista ympäristö, tiedostot ja kansiorakenne (esim. `pwd`, `ls -F`).
2. **Edit**: Tee tarvittavat koodimuutokset.
3. **Smoke Test**: Aja Python-pohjaiset testit tai R-pohjainen QC synteettisellä näytteellä.
4. **Full Run**: Aja varsinainen analyysiputki R:llä (huomioiden `DATA_ROOT`).
5. **QC / Output & Review-luovutus**: Varmista, että tulokset ovat `outputs/`-kansiossa eivätkä riko tietoturvaa. Kirjaa lokiin toimenpiteet ([../SKILLS.md](../SKILLS.md)), siirrä tehtävä aliprojektin jonossa (`tasks/02-in-progress/` -> `tasks/03-review/`) ja toimita PR-katselmointiin sovitun toimitusrajan puitteissa. Tekninen `04-done`-sulku tehdään vasta riippumattoman ihmishyväksynnän ja `origin/main`-toimituksen jälkeen, ja siivous pidetään erillisenä ([WORKFLOW.md](WORKFLOW.md)).

## SOURCE OF TRUTH HIERARCHY

1. [../SKILLS.md](../SKILLS.md) ja [../AGENTS.md](../AGENTS.md) — hallinnollinen työnkulku (tehtäväkohtainen kirjoitus- ja toimitusrajaus, PR-menettely, `main`-toimitus, tekninen `04-done`-sulku ja siivous; nimetyn projektitietueen osalta [../docs/governance/project_registry/README.md](../docs/governance/project_registry/README.md)). Hallinnollinen etusija ei koskaan heikennä alla olevia Option B -, `DATA_ROOT`-, aggregaatti-, `n < 5` - tai Termux-rajoja.
2. TÄMÄ TIEDOSTO (`Quantify-FOF-Utilization-Costs/GEMINI.md`) ja [CLAUDE.md](CLAUDE.md) — aliprojektin Option B -tietosuoja, muuttujastandardointi ja Termux-ympäristö.
3. [../docs/guides/RUNBOOK_SECURE_EXECUTION.md](../docs/guides/RUNBOOK_SECURE_EXECUTION.md) ja [docs/runbook.md](docs/runbook.md) — tietoturva ja mallinnus-/ajoyksityiskohdat.
4. [WORKFLOW.md](WORKFLOW.md), [agent_workflow.md](agent_workflow.md), [AGENTS.md](AGENTS.md) & [README.md](README.md) — paikallinen tehtäväjono (`Quantify-FOF-Utilization-Costs/tasks/`), konfliktien ratkaisu ja yleiskuvaus.
