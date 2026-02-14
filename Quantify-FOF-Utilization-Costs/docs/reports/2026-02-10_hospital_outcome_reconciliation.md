# METADATA RECONCILIATION REPORT: Hospital Outcome Definition

**Type:** Architecture Incident Report
**Status:** OPEN
**Priority:** BLOCKER
**Reference:** `docs/guides/R-analyysirepon Data-arkkitehtuuri.md` (Section: Reproducibility)

## 1. Incident Summary (Schema Mismatch)

Analyysiarkkitehtuurin käyttöönotto (Option B) ja datan eriyttäminen koodista paljasti kriittisen poikkeaman `ingest_config.yaml`:n määrittelemän skeeman ja käsikirjoituksen historiallisten lukujen välillä.

| Metric | Manuscript (Ground Truth) | Current Schema (episodefile) | Delta |
| :--- | :--- | :--- | :--- |
| **Hospital Episodes / 1000 PY** | **378.2** (FOF-) / **539.3** (FOF+) | **62.1** (FOF-) / **70.7** (FOF+) | **-84%** (Missing Data) |

**Architecture Diagnosis:** Nykyinen `hospital_episodes` -määrittely (`episodefile` ilman diagnoosimergeä) on **virheellinen**. Se ei edusta sitä semanttista käsitettä, jota käsikirjoitus käyttää. Emme voi edetä mallinnukseen (Aim 2) ennen kuin skeema on korjattu vastaamaan Ground Truthia.

## 2. Remediation Plan (Path A: Strict Replication)

Päätös on tehty: Emme muuta lukuja, vaan etsimme kadonneen määritelmän. Tämä vaatii **Data-Code Decoupling** -periaatteen mukaista "Schema Discovery" -prosessia.

### Hypoteesit (Testattava järjestyksessä)

1.  **Hypoteesi 1: Puuttuva Merge (Join Failure)**
    * *Teoria:* Käsikirjoituksen "Episodes" ei ole hallinnollinen jakso, vaan "Hoitojakso, johon liittyy diagnoosi".
    * *Testi:* Onnistuuko `episodefile` + `dxfile` yhdistäminen (Left Join on `visit_id`/`patient_id` + `date`)?
    * *Indikaattori:* Nouseeko episodimäärä tasolle ~300-500 kun kaikki diagnoosirivit lasketaan?

2.  **Hypoteesi 2: Väärä Lähdetiedosto (Source Mismatch)**
    * *Teoria:* `DATA_ROOT`:ssa on toinen tiedosto (esim. `hospital_comprehensive.csv` tai `hilmo_raw`), jota ei ole vielä kartoitettu `data_dictionary.csv`:hen.
    * *Testi:* Turvallinen `list.files(DATA_ROOT)` -kartoitus ja sarakkeiden vertailu.

3.  **Hypoteesi 3: Aggregointilogiikka (Calculation Mismatch)**
    * *Teoria:* Käsikirjoitus laskee "päiviä" tai "käyntejä" eri tavalla (esim. limittäiset jaksot yhdistetty).

## 3. Instructions for Data Agent (Codex)

Seuraavan agentin tehtävä on suorittaa **Schema Discovery** rikkomatta tietoturvaa.

**Säännöt:**
1.  **Read-Only DATA_ROOT:** Älä kirjoita data-kansioon.
2.  **No Magic Numbers:** Älä kovakoodaa lukuja skripteihin. Kun löydät oikean logiikan, se on päivitettävä `ingest_config.yaml` -tiedostoon.
3.  **Verification:** Oikea ratkaisu on se, joka tuottaa luvun **378 ± 10%** synteettisellä tai oikealla datalla (riippuen siitä, millä testaat).

## 4. Definition of Done

Ongelma on ratkaistu, kun:
1.  `ingest_config.yaml` on päivitetty vastaamaan "oikeaa" rakennetta (esim. uusi merge-sääntö tai uusi tiedosto).
2.  QC-ajo (`scripts/30_qc_summary.py`) tuottaa Hospital-riville luvun, joka on linjassa käsikirjoituksen kanssa.
