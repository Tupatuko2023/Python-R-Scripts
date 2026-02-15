# GEMINI.md — Python-R-Scripts (Global Repository Guide)

Tämä tiedosto määrittelee yleiset säännöt ja kontekstin Gemini CLI -agentille koko repositorion (`Python-R-Scripts`) tasolla.

**Agenttikuvaus:** Agentti, joka suorittaa R/Python-hybridiputken tiukasti PowerShell 7.0 -ympäristössä ja noudattaa ehdottomia monorepo- ja tietoturvaohjeita (Option B, ei raakadataa).

## 1) Repositorion rakenne ja skooppi

Tämä repo koostuu useista itsenäisistä tutkimusprojekteista. Agentin on tunnistettava, missä projektissa se kulloinkin työskentelee discovery-komennolla (`Get-ChildItem -Path . -Directory`).

- **Fear-of-Falling (FOF)**: `/Fear-of-Falling/` — R-analyysiputki (sisältää oman `GEMINI.md` -ohjeensa).
- **Electronic-Frailty-Index (EFI)**: `/Electronic-Frailty-Index/` — Python- ja R-koodia EFI-laskentaan.
- **Quantify-FOF-Utilization-Costs**: `/Quantify-FOF-Utilization-Costs/` — Aim 2 analyysi (R/Python hybridi).
- **Juuri (Root)**: Yleiset CI/CD-konfiguraatiot, globaalit README-tiedostot ja riippuvuudet.

## 2) Etusijajärjestys (Precedence)

1. `SKILLS.md` (Ylin totuus kaikissa toiminnoissa)
2. `WORKFLOW.md` (Branch isolation ja Remote sync -säännöt)
3. `CLAUDE.md` / `README.md` (Projektikohtaiset konfiguraatiot, koodistandardit)
4. `GEMINI.md` (Tämä tiedosto - yleinen käyttäytyminen)

## 3) Yleiset säännöt (Global Rules)

1. **Tietoturva ja Data Governance (Option B) - EHDOTON**:
   - Raakadata tai henkilötason rekisteridata on ankarasti kielletty repositoriossa.
   - Kaikki datan luku on tapahduttava `DATA_ROOT` -ympäristömuuttujan tai polun kautta.
   - Tulosteet ovat vain aggregoituja yhteenvetoja. Pienisolusuppressio (n<5) on pakollinen.
2. **Path Awareness**: Käytä aina suhteellisia polkuja.
   - R-koodissa suosi `here::here()`.
   - Pythonissa suosi `pathlib.Path`.
3. **No Guessing**: Jos muuttujan merkitys tai datan rakenne on epäselvä, pyydä codebookia tai data-otetta.
4. **Secrets**: Älä ikinä commitoi tai näytä CLI-tulosteissa API-avaimia, salasanoja tai henkilötietoja.

## 4) Työkalut ja ympäristöt

- **PowerShell 7.0**: Pakollinen suoritusympäristö kaikille komennoille.
- **R**: Käytä projektikohtaisia `renv`-ympäristöjä. Muista `renv::restore()` ennen ajoa.
- **Python**: Seuraa kunkin projektin `requirements.txt` tai `pyproject.toml` -määrityksiä.
- **Git**: Käytä selkeitä, "miksi"-perusteltuja commit-viestejä. Tarkista `git status` ja `git diff` ennen commitia. Noudata "Remote Sync Rule" -ohjetta.

## 5) Agentin toimintatapa

- **Discovery**: Suorita repojuuresta `Get-ChildItem -Directory` tunnistaaksesi aliprojektit.
- **Analyysi ennen toimintaa**: Käytä `codebase_investigator` -sub-agenttia, jos tehtävä vaatii useiden tiedostojen välisen logiikan ymmärtämistä.
- **Ytimekkyys**: CLI-agenttina vältä turhaa puhetta. Keskity koodiin ja selkeisiin suunnitelmiin.
- **Verifiointi**: Aja aina projektin omat testit tai smoke-testit (`npm test`, `pytest`, `Rscript run_smoke_test.R`) muutosten jälkeen.

---

## Viimeksi päivitetty

2026-02-14
