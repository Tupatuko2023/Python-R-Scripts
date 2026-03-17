# KB_NOTES

Tämä dokumentti kuvaa tiivistetysti, miten agentin omaa tietopankkia (Knowledge Base, KB) hyödynnetään ja miten sen mahdolliset yliajolyönnit torjutaan `SYSTEM_PROMPT_UPDATE.md` -tasolla.

**Mitä KB:stä hyödynnettiin:**

- **Termux & PRoot -mekaniikat:** KB:n syvempää tietämystä turvallisesta komentoriviputkistuksesta (`cat file.md | gemini`), `proot-distro`-loginien ketjuttamisesta kerta-ajoiksi sekä `termux-wake-lock`-mekanismeista on hyödynnetty täyttämään repositorion SOT-dokumentaation jättämiä toiminnallisia aukkoja.
- **Fail-fast -ohjelmointi:** Bashin `&&`- ja `|| true` -rakenteiden oletuskäyttö luotettavuuden varmistamiseksi.

**Guardrailit / Rajoitteet:**

- Kaikki KB-ohjeet kumoutuvat välittömästi (SOT voittaa), jos ne ovat ristiriidassa repon pääasiallisten konventioiden (`CLAUDE.md`, `AGENTS.md`, `README.md`, `PROJECT_FILE_MAP.md`) kanssa.
- Jos ilmenee tarve olettaa tekninen asetus, joka ei lue repo-ohjeissa, agentti loggaa sen poikkeuksetta näkyväksi oletukseksi, jotta inhimillinen auditointi ja korjaaminen on mahdollista.

**Esimerkkejä sallituista KB-oletuksista (loggausvaatimus):**

- `Assumption: termux-wake-lock pitää ajaa virheohjauksella dev/nulliin 2>/dev/null, jos sitä ei ole aktivoitavissa. (KB)`
- `Assumption: Käytetään na.rm=TRUE -parametria R-laskennassa QC-delta-arvoille, jos tietoja puuttuu satunnaisesti. (KB)`
- `Assumption: proot-distron oletuskotihakemisto välitetään lipukkeella --termux-home ympäristömuuttujien ehjyyden varmistamiseksi. (KB)`
