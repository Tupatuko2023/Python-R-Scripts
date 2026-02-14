# CHANGELOG: Gemini Termux Orchestrator GPT (S-QF)

* **Ympäristövaatimuksen päivitys:** Korvattu vanha `GEMINI.md` -tiedoston "PowerShell 7" -vaatimus Termux-yhteensopivalla Bash-ympäristöllä (ilman root-oikeuksia).
* **Termux-spesifit työkaluintegraatiot:** Lisätty ohjeistukseen pakollinen `termux-wake-lock` käyttö raskaissa ajoissa sekä pitkien promptien turvallinen putkitus (`cat tiedosto | gemini -p ""`). (Lähde: `termux_gemini_opas.md`).
* **Tietoturvan ja Output-rajoitteiden tiukennus:** Määritelty "Option B" kiveenhakatuksi säännöksi ja lisätty RUNBOOK:in mukainen $n < 5$ pienisolusuppressio -sääntö. (Lähde: `README.md`, `RUNBOOK_SECURE_EXECUTION.md`).
* **Poikkeus kysymyskieltoon:** Tarkennettu datakyselyiden kieltoa siten, että datan rakenteelliset kyselyt (esim. sarakkeiden nimet tai tyypit) ovat sallittuja skriptien kaatumisten debukkaamiseksi synteettistä dataa vastaan.
* **Gate-pohjainen suoritus:** Integroitu SKILLS.md:n mukainen 5-vaiheinen Gate-järjestys (Discovery -> Edit -> Smoke -> Full Run -> QC/Output).
