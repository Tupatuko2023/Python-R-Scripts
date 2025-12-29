# GEMINI.md — Python-R-Scripts (Global Repository Guide)

Tämä tiedosto määrittelee yleiset säännöt ja kontekstin Gemini CLI -agentille koko repositorion (`Python-R-Scripts`) tasolla.

## 1) Repositorion rakenne ja skooppi

Tämä repo koostuu useista itsenäisistä tutkimusprojekteista. Agentin on tunnistettava, missä projektissa se kulloinkin työskentelee:

* **Fear-of-Falling (FOF)**: `/Fear-of-Falling/` — R-analyysiputki (sisältää oman `GEMINI.md` -ohjeensa).
* **Electronic-Frailty-Index (EFI)**: `/Electronic-Frailty-Index/` — Python- ja R-koodia EFI-laskentaan.
* **Juuri (Root)**: Yleiset CI/CD-konfiguraatiot, globaalit README-tiedostot ja riippuvuudet.

## 2) Etusijajärjestys (Precedence)

1. **Projektikohtainen ohje**: Jos olet tekemässä muutoksia alikansioon (esim. `Fear-of-Falling/`),
   noudata kyseisen kansion `GEMINI.md` tai `AGENTS.md` -tiedostoa.
2. **Globaali ohje**: Tämä tiedosto (`/GEMINI.md`) ohjaa yleistä käyttäytymistä ja globaaleja työkaluja.

## 3) Yleiset säännöt (Global Rules)

1. **Data Safety**: Raakadata on muuttumatonta (immutable). Älä koskaan muokkaa `data/`-kansioiden alkuperäisiä tiedostoja.
2. **Path Awareness**: Käytä aina suhteellisia polkuja.
    * R-koodissa suosi `here::here()`.
    * Pythonissa suosi `pathlib.Path`.
3. **No Guessing**: Jos muuttujan merkitys tai datan rakenne on epäselvä, pyydä codebookia tai data-otetta.
4. **Secrets**: Älä ikinä commitoi tai näytä CLI-tulosteissa API-avaimia, salasanoja tai henkilötietoja.

## 4) Työkalut ja ympäristöt

* **R**: Käytä projektikohtaisia `renv`-ympäristöjä. Muista `renv::restore()` ennen ajoa.
* **Python**: Seuraa kunkin projektin `requirements.txt` tai `pyproject.toml` -määrityksiä.
* **Git**: Käytä selkeitä, "miksi"-perusteltuja commit-viestejä. Tarkista `git status` ja `git diff` ennen commitia.

## 5) Agentin toimintatapa

* **Analyysi ennen toimintaa**: Käytä `codebase_investigator` -sub-agenttia, jos tehtävä vaatii
  useiden tiedostojen välisen logiikan ymmärtämistä.
* **Ytimekkyys**: CLI-agenttina vältä turhaa puhetta. Keskity koodiin ja selkeisiin suunnitelmiin.
* **Verifiointi**: Aja aina projektin omat testit tai smoke-testit
  (`npm test`, `pytest`, `Rscript run_smoke_test.R`) muutosten jälkeen.

---

## Viimeksi päivitetty

2025-12-29
