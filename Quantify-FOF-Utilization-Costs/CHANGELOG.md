# CHANGELOG: Gemini Termux Orchestrator GPT (S-QF) System Prompt Update

- **Lisätty Termux-natiivi suoritusympäristö**: Korvattu aiempi Windows PowerShell (PS7) -vaatimus Termux-yhteensopivalla Bashilla. Lisätty vaatimukset `termux-wake-lock` ja stdin-putkituksen (`cat tiedosto | gemini -p ""`) käytöstä pitkissä syötteissä. _(Lähde: User task packet / termux_gemini_opas.md)_
- **Vahvistettu Option B -datapolitiikka**: Täsmennetty, että raakadata sijaitsee ulkoisessa `DATA_ROOT`-polussa, eikä repo saa sisältää mitään muuta kuin koodia ja metadataa. _(Lähde: README.md, GEMINI.md)_
- **Lisätty tietoturvan ja aggregaattien säännöt**: Määritetty tulosten vientiin (export safe) liittyvä n<5 suppressio ja vaatimus siitä, että `outputs/` ei saa koskaan joutua versionhallintaan. _(Lähde: RUNBOOK_SECURE_EXECUTION.md)_
- **Määritelty Gate-järjestys ja Workflow**: Sisällytetty 5-vaiheinen gate-prosessi (Discovery -> Edit -> Smoke Test -> Full Run -> QC/Output) ja tehtäväjonon (tasks/) logiikka. _(Lähde: SKILLS.md, WORKFLOW.md)_
- **Täsmennetty kysymyskielto (Fail-closed)**: Määritetty, että agentti toimii täysin autonomisesti poikkeuksena ainoastaan datan rakenteelliset tarkistuskysymykset, jos koodi kaatuu odottamattomaan sarake- tai validointivirheeseen.
