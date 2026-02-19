# CHANGELOG: Agentin järjestelmäohjeen päivitys

**Päivämäärä:** 2026-02-19
**Kohde:** "Gemini Termux Orchestrator GPT (S-QF)" -konfiguraatio

### Muutokset ja perustelut:

- **Ympäristön vaihdos (PS7 -> Termux Bash):** Alkuperäinen `GEMINI.md` vaati PowerShell 7 -yhteensopivuutta. Tämä on korvattu Termux-yhteensopivalla Bashilla (relatiiviset polut, &&-ketjutus, ei rootia).
  - _Lähde:_ Käyttäjän `termux_execution_plan` ja `termux_gemini_opas.md`.
- **Termux-spesifit optimoinnit:** Lisätty vaatimus stdin-putkituksen (`cat file | gemini -p ""`) ja `termux-wake-lock`-komennon käytöstä estämään pitkien ajojen katkeaminen ja pitkien syötteiden leikkautuminen.
  - _Lähde:_ `termux_gemini_opas.md` ja `Termux AI Agenttien Käyttöopas.md`.
- **Tietoturva- ja datapolitiikan (Option B) kiristäminen:** Sisällytetty eksplisiittiset säännöt "Option B" -datakäytännöistä (`DATA_ROOT` ulkoinen) sekä tulosten aggregointisäännöt (`n < 5` suppressio).
  - _Lähde:_ `README.md`, `GEMINI.md`, ja `RUNBOOK_SECURE_EXECUTION.md`.
- **Gate-työnkulun standardisointi:** Määritelty selkeä 5-vaiheinen suoritusputki (Discovery -> Edit -> Smoke -> Full Run -> QC/Output), joka integroituu synteettisen testidatan (`python -m unittest`) ja R-ajojen (`40_run_secure_panel_analysis.R`) väliin.
  - _Lähde:_ `SKILLS.md` ja `README.md`.
- **Kysymyskielto ja poikkeukset:** Tarkennettu "fail-closed" -periaatetta. Agentti ei saa oletuksena pysähtyä kysymään ohjeita, mutta sille myönnettiin poikkeuslupa tarkistaa datan rakenne (esim. `glimpse()`), jos se törmää schema/sarakevirheisiin.

Huomiona liittyen agentti gqf19:n raporttiin: Työtila on vahvistetusti puhdas ja aiempi siivoustehtävä (task_sync_cleanup.md) on oikeaoppisesti tilassa 03-review. Seuraava askel orkestroinnissa on tämän päivitetyn system promptin injektointi S-QF-agentin konfiguraatioon.
