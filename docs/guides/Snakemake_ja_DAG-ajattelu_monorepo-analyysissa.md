# Snakemake ja DAG-ajattelu monorepo-analyysissa

## Mitä DAG tarkoittaa tässä repossa

DAG (directed acyclic graph) tarkoittaa riippuvuusverkkoa, jossa jokainen solmu on laskentavaihe (tai artefakti) ja jokainen nuoli kertoo, että jokin vaihe tarvitsee toisen vaiheen tuottaman tuloksen ennen kuin se voi ajaa. Acyclic tarkoittaa, ettei verkossa ole syklejä: et voi päätyä takaisin samaan solmuun seuraamalla nuolia, ja siksi työ on aina järjestettävissä “ensin nämä, sitten nuo”. citeturn5search0turn2search4

Käytännössä analyysirepossa solmut ovat usein tiedostoja (tai kansioita) ja vaiheet ovat komentoja, jotka muuntavat input-tiedostoja output-tiedostoiksi. Snakemake mallintaa tämän nimenomaan “tuota tämä tiedosto näistä tiedostoista” -sääntöinä, joista se johtaa riippuvuudet automaattisesti tiedostonimien perusteella. citeturn4search9turn9search6turn8search21

image_group{"layout":"carousel","aspect_ratio":"16:9","query":["Snakemake DAG visualization example graphviz","directed acyclic graph workflow dependency example","Snakemake rulegraph example"],"num_per_query":1}

Alla kaksi konkreettista esimerkkipolkua (pipeline) sinun monorepon kontekstissa. Olen tarkoituksella käyttänyt esimerkkitargeteja ja kulmasulkeita siellä, missä en voi tietää oikeita tiedostonimiä.

**Esimerkki A: Quantify-FOF-Utilization-Costs – scripts → intermediates → qc → models → report**

Ajatus on, että sinulla on jo “pipeline-skriptejä” scripts/-hakemistossa ja outputs/-hakemistossa väli- ja lopputuloksia. DAG-mallissa teet näistä stabiileja targetteja (ei timestamp-kansioita joka ajolla), jotta incrementaalisuus toimii.

Yksi tyypillinen polku voisi olla:

```text
DATA_ROOT/<raw_input_dir>/... 
  -> outputs/manifest/inputs_manifest.csv
      (inventory / manifestointi)
  -> outputs/intermediate/analysis_dataset.csv
      (preprocess)
  -> outputs/qc/qc_summary.json
      (qc)
  -> outputs/models/<model_artifact>.rds + outputs/models/<metrics>.csv
      (models)
  -> outputs/reports/aim2_report.md
      (report)
```

**Mitä DAG tuo verrattuna run_all.sh:**
- Kun muutat vain QC-skriptiä tai QC:n parametreja, Snakemake voi ajaa uudelleen vain qc-vaiheen ja siitä downstreamin (mallit + raportti), mutta jättää inventoinnin ja preprocessin väliin jos niiden tuotokset ovat edelleen validit. Tämä perustuu Snakemaken rerun-triggereihin, jotka voivat huomioida muutakin kuin tiedostojen muokkausajat (esimerkiksi koodi, parametrit, input-lista ja ohjelmistoympäristö). citeturn4search0
- Sinulla on eksplisiittinen “mikä tuottaa mitä” -kartta (DAG), joka on sekä debuggaus- että dokumentointityökalu. Snakemake osaa tulostaa DAGin Graphviz DOT -muodossa (`--dag`) ja tuottaa myös yhteenvetoja ja raportteja metadatan pohjalta. citeturn4search1turn5search2turn7search2
- Run_all.sh on yleensä lineaarinen: joko se ajaa kaiken aina, tai sitten se sisältää käsin koodattuja if-ehtoja (“jos tiedosto on olemassa, ohita”), jotka eivät skaalaudu hyvin kun vaiheita ja parametreja kertyy. DAG-työkalu tekee tämän päätöksenteon järjestelmällisesti riippuvuuksien perusteella. citeturn4search0

**Esimerkki B: Electronic-Frailty-Index – external data → notebook-vaiheet → taulukot/kuvat → raportti**

Notebook-painotteisessa projektissa DAG voi olla kahden tasoinen:
1) “materiaalinen DAG” (tiedostot): data → taulukot → kuvat → raportti
2) “executed notebook” osana tuotantoketjua: notebook (input) → executed notebook (output) → exportoidut artefaktit

Esimerkkipolku:

```text
DATA_ROOT/<efi_external_data>/...
  -> <notebook_or_script_step_1>.ipynb tai .py/.R
  -> tables/<table_1>.<ext> + figures/<figure_1>.<ext>
  -> report/<efi_report>.html tai .pdf
```

Snakemakessa notebookit voidaan integroida suoraan `notebook:`-direktiivillä, jolloin notebook ajetaan headless-tilassa Papermillin avulla (jos asennettuna) tai nbconvertilla. Tämä mahdollistaa sen, että notebook on osa DAGia eikä vain manuaalinen klikkausvaihe. citeturn0search4turn0search3

Samalla on hyvä tunnistaa notebookien luonne: ne ovat usein hyvä interaktiiviseen eksplorointiin (“viimeisen mailin” analyysi ja kuvat), mutta tuotantoputken rungoksi skriptit ovat yleensä helpompia tehdä deterministisiksi ja parametrisoitaviksi. Snakemaken oma dokumentaatio korostaa notebook- ja skripti-integraatiota nimenomaan interaktiivisen työn ja raportoinnin tukena. citeturn0search2turn7search20

## Missä Snakemake hyödyttää vs missä se on ylikill

Sinun monorepossa on jo useampi “orkestrointitaso” (Makefilet, Docker, renv, scripts/, outputs/). Siksi suositus kannattaa tehdä projektikohtaisesti, ei yhdellä työkalulla kaikkeen.

**Fear-of-Falling**
Tässä projektissa on jo Makefile + Docker + renv ja paljon R-skriptejä sekä outputs/-rakennetta. Jos pipeline on suhteellisen vakio, ja Makefile jo mallintaa keskeiset riippuvuudet, Snakemake voi olla ylikill, koska Make on jo dependency-työkalu: se päättää mitä tehdä tiedostojen muokkausaikojen ja dépendenssien perusteella. citeturn1search4turn6search5

Missä Make usein alkaa tuntua kapealta analyysiprojekteissa:
- Make on perinteisesti “stateless”: se nojaa pääosin tiedostojärjestelmän mtimeen eikä pidä omaa metadatakantaa ajoista. Tämä toimii hyvin, kun dépendenssit on mallinnettu oikein, mutta menee helposti pieleen jos skripteillä on piiloinputteja tai jos unohdat listata skriptit/konfigit riippuvuuksiksi. citeturn6search5turn5search7
- Snakemake taas voi oletuksena huomioida koodin, parametrit ja ohjelmistoympäristön rerun-triggereissä, mikä vähentää “miksi se ei rerunnannut” tai “miksi se rerunnasi kaiken” -yllätyksiä. citeturn4search0turn5search2

Käytännön arvio: jos Fear-of-Fallingissa tavoitteet täyttyvät (yksi komento, vain muuttuneet osat, selkeät riippuvuudet) nykyisellä Makefilellä ja Docker/renv hoitaa ympäristöt, pidä se. Snakemake kannattaa tuoda tähän vain, jos (a) vaiheita on paljon ja haluat enemmän automaattista provenancea/visualisointia, (b) haluat per-rule logit/ympäristöt tai (c) tarvitset laajaa wildcard/parametrisoitua ajamista ja parallelointia ilman Makefile-akrobatiaa. citeturn4search1turn7search2turn8search21

**Electronic-Frailty-Index**
Notebookit ovat tässä iso design-päätös. Vaihtoehtoja on kaksi realistista linjaa:

- Jos tavoite on “yksi komento joka renderöi raportin ja ajaa siihen liittyvät notebookit”, Quarto-projekti on usein vähiten kitkaa: Quarto-projektit tukevat yhden komennon renderöintiä (`quarto render <project>`), yhteistä YAML-konfiguraatiota ja myös “freeze”-ominaisuutta, jolla vältytään uudelleenlaskennalta silloin kun lähde ei ole muuttunut. citeturn9search3turn6search2turn6search4  
- Jos tavoite on “selkeä computational DAG datasta malliin ja raporttiin” ja notebookit ovat tällä hetkellä sekoitus eksplorointia ja tuotantoa, suosittelen jakamaan: pidä notebookit eksplorointiin ja siirrä tuotantoketjun rungon vaiheet skripteiksi (R/Python), ja aja raportti joko Quarto- tai Snakemake-vaiheena. Notebookit voi myös jättää DAGiin, mutta silloin kannattaa hyväksyä, että determinismi ja parametrien eksplisiittisyys vaatii kurinalaisuutta. Snakemake tukee notebookien ajamista `notebook:`-direktiivillä ja käyttää Papermillia tai nbconvertia ajamiseen. citeturn0search4turn0search3

**Quantify-FOF-Utilization-Costs**
Tämä on kuvauksesi perusteella “paras kohde” Snakemakelle: selkeä scripts/-pipeline, outputs/logs ja mahdollisesti manifestit. Snakemake istuu hyvin tilanteeseen, jossa haluat mallintaa “mikä tuottaa mitä” tiedostoina ja saada incrementaalisuuden, DAG-visualisoinnin ja logien hallinnan ilman että kirjoitat kaiken itse. citeturn4search9turn4search1turn7search2

Lisäksi Snakemake integroi sekä Python- että R-skriptit suoraan: `script:`-direktiivillä Snakemake välittää input/output/params-objektin skriptiin, ja R-puolella vastaava `snakemake`-S4-objekti on käytettävissä. citeturn7search4turn7search0

## Monorepo-arkkitehtuurivaihtoehdot

Tavoitteesi “yksi komento koko monorepolle” on täysin yhteensopiva sen kanssa, että sisällä käytetään eri projektien tarpeisiin sopivia työkaluja. Tässä kaksi arkkitehtuuria.

**Vaihtoehto A: yksi top-level Snakefile, joka tuo aliprojektien workflowt moduuleina**
Snakemakessa on `module`-mekanismi, jolla voit tuoda toisen workflow-kansion Snakefilen ja käyttää sen sääntöjä (ja siten sen outputteja) osana top-level DAGia. Tämä on “yhden ison DAGin” lähestymistapa. citeturn0search1turn0search12

Huomio: vanhempi `subworkflow`-idea on käytännössä korvattu moduuleilla ja sitä on poistettu/ajettu alas uusissa versioissa, joten moduulit ovat se mihin kannattaa nojata. citeturn0search19

Tradeoffit:
- Selkeys: saat yhden DAGin, yhden `snakemake --dag` näkymän ja yhden `rule all` -targetin koko monorepolle. citeturn4search1turn4search9
- Ylläpito: riski kasvaa, että top-level workflow alkaa sisältää projektikohtaista erityislogiikkaa (eri data rootit, eri env-mallit, eri raportointiputket). Tämä voi tehdä pienistä muutoksista hitaita ja rikkoa projektiomistajuuden.
- Ympäristöt: jos projektit käyttävät renv + omia Python-env/conda/ Docker -ratkaisuja, yhden top-level Snakemaken läpi ajaminen voi olla ympäristöjen kannalta hankalampaa kuin “projektit ajavat itseään”. Snakemake tukee conda- ja container-deploymenteja, mutta niiden sovittaminen renv-maailmaan vaatii tietoisen valinnan. citeturn0search17turn1search19

**Vaihtoehto B: jokaiselle aliprojektille oma orkestrointi, ja yhteinen wrapper monorepolla**
Tässä malli on: jokaisella aliprojektilla on “oma paras työkalu” (Make, Snakemake, Quarto) ja monorepon rootissa on ohut wrapper (Makefile- tai bash-target), joka tekee yhden komennon ajon. Wrapper voi olla täysin tyhmä: se vain kutsuu aliprojektien komennot järjestyksessä. Incrementaalisuus tapahtuu aliprojektien sisällä.

Tradeoffit:
- Selkeys: jokainen projekti pysyy itsenäisenä, ja tiimin on helpompi ymmärtää projektin “local rules”. Quarto renderöi Quarto-projektin, Make ajaa Makefile-targetit, Snakemake ajaa DAGin. citeturn9search3turn1search4turn4search9
- Ylläpito: pienempi coupling. Monorepo-wrapper pysyy pienenä, eikä sinun tarvitse “kääntää kaikkea” samaan orkestrointikieleen.
- CI: wrapperiin on helppo rakentaa “dry-run + lint + smoke” jokaiselle projektille erikseen.
- Miinus: et saa yhtä globaalia DAGia. Jos projektien välillä on oikeita riippuvuuksia (esim. A tuottaa datan B:lle), tämä malli vaatii eksplisiittisen sopimuksen tiedostorajapinnasta ja siitä, missä artefaktit asuvat.

Käytännön suositus sinun kuvaamallesi monorepolle: vaihtoehto B on useimmiten parempi aloituspiste, koska projektit vaikuttavat melko itsenäisiltä ja niillä on jo omat ympäristö- ja ajokäytännöt. Top-level “yksi komento” saadaan wrapperilla ilman että yritetään pakottaa kaikkea yhteen DAGiin.

## Minimi Snakemake Quantify-FOF-Utilization-Costs -projektiin

Tässä kopioitava minimi, joka on tarkoituksella “skeleton”: se ei oleta oikeita tiedostonimiä. Sinun tehtävä on korvata configin input-polku sekä halutessasi korvata inline-komennot omilla scripts/-vaiheillasi.

Rakennetaan tämä rakenne projektin sisään:

```text
Quantify-FOF-Utilization-Costs/
  config/
    config.yaml
  workflow/
    Snakefile
  outputs/
    (Snakemake luo alihakemistot)
  logs/
    (Snakemake luo alihakemistot)
```

**config/config.yaml**

```yaml
# Korvaa nämä omiin polkuihisi.
# data_root voi olla suojatun datan mount, NAS-polku tai paikallinen kansio.
data_root: "/ABS/PATH/TO/DATA_ROOT"

# Minimitaso: yksi "raaka input" jonka olemassaolo käynnistää putken.
# Tämä voi olla myös kansio; silloin vaihda Snakefilessa input: directory("...").
inputs:
  raw_input: "REPLACE_ME/raw_input.csv"

# Stabiilit output-kohteet (tärkeää incrementaalisuudelle).
targets:
  manifest: "outputs/manifest/inputs_manifest.csv"
  dataset: "outputs/intermediate/analysis_dataset.csv"
  qc: "outputs/qc/qc_summary.json"
  model: "outputs/models/model.rds"
  report: "outputs/reports/aim2_report.md"

# Esimerkki parametreista, joita haluat näkyviin rerun-logiikassa.
params:
  cohort: "REPLACE_ME_cohort_id"
  aim: "aim2"
```

**workflow/Snakefile**

```python
import os
import json
from pathlib import Path

configfile: "config/config.yaml"

DATA_ROOT = Path(os.environ.get("DATA_ROOT", config["data_root"]))

def p(rel):
    # Resolvaa data_rootin alle; configissa pidetään lyhyet polut.
    return str(DATA_ROOT / rel)

TARGETS = config["targets"]
PARAMS = config.get("params", {})

rule all:
    input:
        TARGETS["report"]

rule inventory_manifest:
    """
    Inventory/manifest: tee eksplisiittinen lista siitä, mitä raaka-inputteja ajetaan.
    Korvaa tämä tarvittaessa omalla scripts/* manifest -ajolla.
    """
    input:
        raw=p(config["inputs"]["raw_input"])
    output:
        manifest=TARGETS["manifest"]
    log:
        "logs/manifest/inventory_manifest.log"
    params:
        cohort=PARAMS.get("cohort", "NA"),
        aim=PARAMS.get("aim", "NA"),
    shell:
        r"""
        set -euo pipefail
        python - <<'PY' > {output.manifest} 2> {log}
        import csv
        from datetime import datetime
        raw = {input.raw!r}
        cohort = {params.cohort!r}
        aim = {params.aim!r}

        with open(raw, "r", encoding="utf-8") as f:
            pass

        rows = [
            ["raw_input", "cohort", "aim", "observed_at_utc"],
            [raw, cohort, aim, datetime.utcnow().isoformat() + "Z"],
        ]
        w = csv.writer(__import__("sys").stdout)
        w.writerows(rows)
        PY
        """

rule preprocess:
    """
    Preprocess: tyypillisesti R-vaihe, joka tuottaa analyysidatan stabiiliin tiedostoon.
    Tämä esimerkki kirjoittaa vain pienen CSV:n malliksi.
    Korvaa shell-lohko omalla Rscript-ajolla (esim. scripts/<preprocess>.R).
    """
    input:
        manifest=TARGETS["manifest"]
    output:
        dataset=TARGETS["dataset"]
    log:
        "logs/preprocess/preprocess.log"
    params:
        cohort=PARAMS.get("cohort", "NA"),
    shell:
        r"""
        set -euo pipefail
        Rscript - <<'RS' > {log} 2>&1
        args <- list(
          manifest = "{input.manifest}",
          out = "{output.dataset}",
          cohort = "{params.cohort}"
        )

        dir.create(dirname(args$out), recursive = TRUE, showWarnings = FALSE)

        # MINIMI: kirjoita esimerkkidata; korvaa omalla preprocessilla.
        df <- data.frame(
          id = 1:3,
          cohort = args$cohort,
          value = c(10, 20, 30)
        )
        write.csv(df, args$out, row.names = FALSE)
        cat("Wrote:", args$out, "\n")
        RS
        """

rule qc:
    """
    QC: Python-vaihe, joka tuottaa esim. JSON-yhteenvedon.
    """
    input:
        dataset=TARGETS["dataset"]
    output:
        qc=TARGETS["qc"]
    log:
        "logs/qc/qc.log"
    shell:
        r"""
        set -euo pipefail
        python - <<'PY' > {output.qc} 2> {log}
        import csv, json
        inp = {input.dataset!r}

        with open(inp, newline="", encoding="utf-8") as f:
            rows = list(csv.DictReader(f))

        summary = {
            "n_rows": len(rows),
            "columns": list(rows[0].keys()) if rows else [],
        }
        print(json.dumps(summary, indent=2))
        PY
        """

rule models:
    """
    Models: R-vaihe; tässä vain placeholder joka kirjoittaa RDS:n.
    """
    input:
        dataset=TARGETS["dataset"],
        qc=TARGETS["qc"]
    output:
        model=TARGETS["model"]
    log:
        "logs/models/models.log"
    params:
        aim=PARAMS.get("aim", "NA"),
    shell:
        r"""
        set -euo pipefail
        Rscript - <<'RS' > {log} 2>&1
        inp <- "{input.dataset}"
        qc  <- "{input.qc}"
        out <- "{output.model}"
        aim <- "{params.aim}"

        dir.create(dirname(out), recursive = TRUE, showWarnings = FALSE)

        # MINIMI: lue dataset ja tallenna "malli" listana.
        df <- read.csv(inp)
        model <- list(
          aim = aim,
          n = nrow(df),
          qc_json_path = qc
        )
        saveRDS(model, out)
        cat("Saved model:", out, "\n")
        RS
        """

rule report:
    """
    Report: tuota lopputarget. Tässä Markdown, jonka sisältö yhdistää qc:n ja mallin metat.
    Voit myöhemmin korvata tämän esim. Quarto-renderillä tai Rmd:llä.
    """
    input:
        qc=TARGETS["qc"],
        model=TARGETS["model"]
    output:
        report=TARGETS["report"]
    log:
        "logs/report/report.log"
    params:
        cohort=PARAMS.get("cohort", "NA"),
        aim=PARAMS.get("aim", "NA"),
    shell:
        r"""
        set -euo pipefail
        python - <<'PY' > {output.report} 2> {log}
        import json
        qc_path = {input.qc!r}
        cohort = {params.cohort!r}
        aim = {params.aim!r}

        qc = json.load(open(qc_path, "r", encoding="utf-8"))

        md = []
        md.append(f"# {aim} report")
        md.append("")
        md.append(f"- cohort: {cohort}")
        md.append(f"- rows: {qc.get('n_rows')}")
        md.append(f"- columns: {', '.join(qc.get('columns', []))}")
        md.append("")
        md.append("Artifacts:")
        md.append(f"- QC: `{qc_path}`")
        md.append(f"- Model: `{ {input.model!r} }`")  # placeholder string
        print("\n".join(md))
        PY
        """
```

Miksi tämä on “minimi toimiva”
- Saat yhden komennon ajon, joka tuottaa stabiilin lopputargetin `outputs/reports/aim2_report.md`.
- Saat vähintään viisi vaihetta, joilla on selkeät input/output/log -rajapinnat.
- Saat sekä Rscript- että Python-ajot samassa DAGissa.
- Voit nyt korvata jokaisen inline-blockin omalla olemassa olevalla scripts/* -komennolla, ilman että DAG-rakenne muuttuu. Snakemake on nimenomaan “rules: input -> output” -malli, jonka sisällä komento voi olla mikä tahansa. citeturn4search9turn3search9turn7search4

## Komennot + DAG-visualisointi + rerun-logiikka

Aja projektin kansiossa (oleta että olet `Quantify-FOF-Utilization-Costs/` sisällä):

**Dry-run (mitä ajaisi, ei aja mitään):**

```bash
snakemake \
  --snakefile workflow/Snakefile \
  --configfile config/config.yaml \
  -n
```

Dry-run on tärkein “nopea tarkistus” CI:ssä ja paikallisesti, koska se rakentaa DAGin ja kertoo, löytyykö kaikki riippuvuudet ja targetit. citeturn4search3turn7search3

**DAG PDF:ksi Graphvizilla**

```bash
snakemake \
  --snakefile workflow/Snakefile \
  --configfile config/config.yaml \
  --dag \
| dot -Tpdf > dag.pdf
```

Snakemaken `--dag` tulostaa Graphviz DOT -kuvauksen, jonka `dot` sitten renderöi. citeturn4search1turn5search5turn5search1

**Yhteenveto mitä on tehty / mikä on up-to-date**

```bash
snakemake \
  --snakefile workflow/Snakefile \
  --configfile config/config.yaml \
  --summary
```

Snakemake säilyttää metatietoa `.snakemake`-hakemistossa ja hyödyntää sitä yhteenvetoihin ja raportointiin. citeturn5search2turn7search2

**Miten Snakemake päättää mitä ajaa uudelleen**
Snakemaken keskeinen ero “perinteiseen make-tyyliin” on se, että se voi oletuksena käyttää useita rerun-triggereitä. CLI-dokumentaation mukaan `--rerun-triggers` voi sisältää mm. mtime, params, input, software-env ja code, ja oletuksena kaikki triggerit ovat käytössä, jotta tulokset pysyvät konsistentteina workflow-koodin ja konfigin kanssa. citeturn4search0turn4search4

Vastaavasti Make on perinteisesti mtime-pohjainen ja “stateless” invokaatiosta toiseen: se vertaa tiedostojen muokkausaikoja eikä pidä omaa “ajo-metatietokantaa”. citeturn6search5turn1search4

Käytännön vaikutus sinulle:
- Jos muutat `config.yaml`:n parametreja (esim. cohort, aim), downstream-artefaktit rerunnataan, vaikka input-datan mtime ei muuttuisi. citeturn4search0
- Jos muutat sääntöjen koodia (Snakefile tai kutsuttu skripti), rerun voi triggaantua metadataan perustuen. citeturn4search0turn5search2
- Jos haluat tietoisesti “vain mtime”, voit pakottaa sen `--rerun-triggers mtime`, mutta silloin otat takaisin Make-tyyppisen riskin: koodimuutokset eivät välttämättä näy build-logiikassa. citeturn4search0turn6search5

## Sudenkuopat ja ratkaisut

**Notebookit vs skriptit**
- Sudenkuoppa: notebookit sisältävät helposti piilotilaa (cellien ajojärjestys, kernelin state), jolloin “toistettavuus” heikkenee ja DAGin lupaus determinismistä alkaa rakoilla.
- Ratkaisu A: pidä notebookit eksplorointiin ja tee tuotantovaiheet skripteinä (R/Python), jotka lukevat ja kirjoittavat stabiileja tiedostoja.
- Ratkaisu B: jos haluat notebookin osaksi putkea, käytä Snakemaken notebook-integraatiota: notebook ajetaan headless-tilassa Papermillilla (jos asennettuna) tai nbconvertilla, ja ympäristössä pitää olla Jupyter. citeturn0search4turn0search3turn0search2
- Vaihtoehto käytännössä: Quarto-projekti notebook-raportointiin, koska Quarto tukee yhden komennon renderöintiä ja “freeze” voi estää turhan uudelleenajon dokumenttitasolla. citeturn9search3turn6search2

**renv ja Python-ympäristöt yhdessä**
- Sudenkuoppa: renv (R) ja conda/venv (Python) elävät eri logiikoilla. Jos yrität tehdä “yksi orkestroija hoitaa kaiken ympäristön”, voit päätyä kahteen osittain päällekkäiseen dependency-malliin.
- Renvin mallissa riippuvuudet lukitaan `renv.lock`-tiedostoon ja palautetaan `renv::restore()`-toiminnolla. citeturn1search2turn1search19
- Snakemake osaa hoitaa ohjelmistoriippuvuuksia conda- ja container-mekanismeilla, ja dokumentaatio kuvaa myös tilanteita, joissa conda-env luodaan containerin sisältä (hashiin vaikuttaa myös container image). citeturn0search17turn0search3

Käytännön suositus monorepossa:
- Jos projektissa on jo renv ja se toimii, älä kiirehdi siirtämään R-riippuvuuksia condaan vain Snakemaken takia. Käsittele renv “projektin sisäisenä sopimuksena” ja aja R-vaiheet projektin työhakemistossa niin, että renv aktivoituu normaalisti.
- Python-puolelle valitse yksi: joko Snakemaken conda per rule, tai yksi projektikohtainen venv/conda env, jota käytät kaikissa Python-vaiheissa. Snakemake tukee molempia suoraan komentotasolla, mutta conda per rule on yleensä vahvin reproducibilityn kannalta. citeturn0search3turn4search0

**outputs/-hakemistossa timestamp-kansiot**
- Sudenkuoppa: jos jokainen ajo tuottaa uuden `outputs/<timestamp>/...` polun, DAG-orkestroija näkee aina “uudet outputit puuttuvat” ja ajaa kaiken, jolloin incrementaalisuus katoaa.
- Ratkaisu: erottele “stabiilit targetit” ja “snapshotit”.
  - Stabiili: `outputs/models/model.rds`, `outputs/reports/aim2_report.md`
  - Snapshot: `outputs/snapshots/<run_id>/models/model.rds` jne.
- Käytännön pattern: tee DAG niin, että `rule all` osoittaa stabiileihin targetteihin. Lisää erillinen “snapshot/copy” -vaihe, joka on opt-in (ajetaan vain release-tilanteessa) ja joka kopioi stabiilit artefaktit run_id-kansion alle. Tämä vähentää turhaa compute-kuormaa ja säilyttää kuitenkin audit trailin.

**Windows/PowerShell vs Linux**
- Snakemake käyttää bashia shell-komentojen ajamiseen (dokumentaatiossa mainitaan bash strict mode oletuksena), ja Windowsin shell-ympäristö eroaa niin paljon, että Snakemaken oma tutorial ohjaa Windows-käyttäjät yleensä WSL:ään Linux-ympäristön saamiseksi. citeturn10search6turn10search0turn10search20
- Käytännön suositus: jos tiimissä on Windows-koneita, standardoi Snakemake-ajot WSL:ään (tai vaihtoehtoisesti aja kaikki konteissa Linuxina). Pidä PowerShell-ajo erillisenä vain, jos projektit ovat jo vahvasti Windows-sidonnaisia.

## Vaihtoehtojen vertailu + päätöspuu-suositus

**Makefile top-level targeteilla**
Make on dependency-työkalu, ja se on erittäin hyvä silloin kun:
- sinulla on selkeitä tiedostotargetteja
- riippuvuudet ovat yksinkertaisia
- ympäristö on “valmiiksi ratkaistu” (Docker/renv) ja Make vain kutsuu komentoja

GNU Make -manuaali kuvaa Makea työkaluna, joka päättää automaattisesti mitä osia pitää rakentaa uudelleen, ja käytännössä päätös perustuu muutoksiin ja muokkausaikoihin. citeturn1search4turn6search5

Riski: jos et mallinna kaikkia inputteja, Make ei tiedä että jokin muuttui. Tämä näkyy usein analyysiputkissa, joissa on paljon konfigeja, datafiltrejä ja skriptejä, joita ei ole listattu riippuvuuksiksi. citeturn6search5

**Pelkkä bash-runner**
Bash-runner (yksi komento joka ajaa kaiken) toimii, jos:
- putki on lyhyt
- compute on halpaa
- incremental-run ei ole oikeasti vaatimus (tai sen voi tehdä käsityönä)

Mutta jos vaadit incrementaalisuutta ja “mikä tuottaa mitä” -läpinäkyvyyttä, bash-runner vie sinut nopeasti itse rakennettuun DAGiin (if-ehdot, touch-filet, checksumit), eli käytännössä rakennat workflow manageria itse.

**Snakemake**
Snakemake tuo analyysiprojekteihin Make-henkisen file-based DAGin, mutta tarjoaa enemmän työkaluja reproducibilityyn, visualisointiin ja rerun-logiikkaan. Se on inspiroitunut Makesta ja johtaa riippuvuudet input/output-sääntöjen kautta. citeturn9search6turn8search21

Konkreettiset plussat sinun tavoitteisiisi:
- DAG-visualisointi (`--dag`) ja summaryt, metatieto `.snakemake`-hakemistossa. citeturn4search1turn5search2
- Rerun-triggereissä voi olla mukana params, code ja software-env, ei vain mtime. citeturn4search0
- R- ja Python-skriptien natiivi integraatio. citeturn7search4turn7search0
- Modulaarisuus monorepohun moduuleilla. citeturn0search1turn0search12turn0search19

**Airflow ja Prefect**
Nämä ovat “orkestrointialustoja”, eivät ensisijaisesti paikallisen analyysirepon build-työkaluja. Ne loistavat, kun tarvitset:
- ajastusta (schedule), jatkuvaa ajoa, eventeihin reagoivia sensoreita
- retries/observability “palveluna”
- useita ajoympäristöjä, worker-poolit, keskitetty UI ja metadata DB

Airflowssa workflow mallinnetaan DAGina ja järjestelmässä on selkeä scheduler- ja metadata DB -arkkitehtuuri. citeturn2search4turn9search0turn3search14  
Prefect painottaa Python-funktioihin perustuvaa orkestrointia sekä taskien retry- ja caching-ominaisuuksia, ja tarjoaa server-mallin jossa ajometadataa säilytetään tietokannassa. citeturn2search1turn2search8turn9search1turn9search5

Repo-kontekstissa realistinen raja:
- Jos ajo on pääosin paikallista ja CI:ssä, ja pipeline on file-based analyysiputki, Airflow/Prefect on yleensä liikaa “ops surface area” suhteessa hyötyyn.
- Jos taas haluat ajastaa putken tuotantoon, monitoroida sitä UI:ssa ja tehdä retry/pause/resume operaatioita tiiminä, Prefect tai Airflow alkaa olla perusteltu.

**Nextflow**
Nextflow on erityisen vahva HPC/container-keskeisessä mallissa ja tarjoaa caching/resume -ominaisuuden (`-resume`). citeturn2search2turn3search5  
Se tukee myös conda-ympäristöjä per process ja modulaarisuutta DSL2 modules -mallilla. citeturn3search1turn3search0

Sinun monorepossa Nextflow olisi perusteltu lähinnä, jos:
- sinulla on selvästi prosessipohjainen pipeline, joka halutaan viedä HPC/cluster-kontekstiin laajasti
- haluat “process sandbox” -tyyppisen eristyksen ja jobien workdir-cache-mallin
Muuten Snakemake tai DVC on lähempänä nykyistä scripts/ + outputs -tyyliä.

**DVC**
DVC on “data + pipeline + cache” -työkalu: se mallintaa pipeline-vaiheet `dvc.yaml`-tiedostossa DAGina ja `dvc repro` päättää mitkä vaiheet pitää ajaa ja hyödyntää cachea. citeturn6search0turn6search1  
DVC osaa myös näyttää pipeline-DAGin `dvc dag` -komennolla. citeturn6search6  
Jos sinulla on isoja datasettejä ja haluat data lineage + versionointi (erityisesti jos data voidaan tallentaa DVC remoteen), DVC voi olla oikea valinta. Toisaalta suojatun datan tapauksessa remote- ja cache-käytännöt on mietittävä tarkasti, ja DVC olettaa usein datan saatavuuden paikallisesti tai erikseen pullattuna. citeturn6search10

**Päätöspuu**
- Valitse Quarto, jos projektin pääartefakti on raportti(t) ja notebookit/Rmd/Qmd ovat keskiössä, ja “incrementaalisuus dokumenttitasolla” riittää. citeturn9search3turn6search2
- Valitse Make (pidä nykyinen), jos projektissa on jo toimiva Makefile, riippuvuudet ovat hallittavissa ja ympäristö ratkaistaan Dockerilla tai renvillä ilman tarvetta hienojakoiselle DAG-debuggaukselle. citeturn1search4turn6search5
- Valitse Snakemake, jos haluat eksplisiittisen file-based DAGin, vain muuttuneiden osien ajon sekä paremman rerun-logiikan (parametrit/koodi/env) ja sekoitat R ja Python -vaiheita samassa putkessa. citeturn4search0turn7search4turn4search1
- Valitse DVC, jos data versionointi ja cache/run lineage on keskeinen vaatimus ja olet valmis elämään DVC:n data- ja cache-mallin kanssa. citeturn6search0turn6search1
- Valitse Prefect tai Airflow, jos ajastaminen, jatkuva orkestrointi, UI-observability ja tuotantomainen operointi ovat ensisijainen tarve, ei pelkkä paikallinen analyysibuild. citeturn2search4turn9search0turn9search5turn9search1

## Next actions

Tavoite tässä on saada 1-2 tunnissa ensimmäinen onnistunut DAG-ajo Quantify-FOF-Utilization-Costs -projektiin, ja samalla luoda monorepon “yksi komento” -kokemus ilman että pakotat Snakemakea kaikkialle.

**Lisättävät tiedostot ja sijainnit**
1) `Quantify-FOF-Utilization-Costs/config/config.yaml` (yllä)  
2) `Quantify-FOF-Utilization-Costs/workflow/Snakefile` (yllä)  
3) Päivitä `.gitignore` projektissa (tai monorepon juuressa), jotta et vahingossa committaa ajometadataa ja logeja:
   - `Quantify-FOF-Utilization-Costs/.snakemake/`
   - `Quantify-FOF-Utilization-Costs/logs/`
   - tarvittaessa `Quantify-FOF-Utilization-Costs/outputs/` jos outputs ei kuulu Git-historiaan

`.snakemake`-hakemisto on osa Snakemaken metadatamekanismia (summary/report). citeturn5search2

**Ensimmäinen onnistunut ajo**
- Täytä `data_root` ja `inputs.raw_input` oikeiksi (mieluiten pienellä smoke-datalla, joka ei ole suojattua).
- Aja ensin dry-run ja vasta sitten oikea ajo:

```bash
cd Quantify-FOF-Utilization-Costs

snakemake --snakefile workflow/Snakefile --configfile config/config.yaml -n
snakemake --snakefile workflow/Snakefile --configfile config/config.yaml --cores 1
```

Dry-run rakentaa DAGin ja kertoo heti, jos input-polut tai targetit eivät täsmää. citeturn4search3turn4search9

**Miten lisäät uuden vaiheen**
- Tee uusi `rule new_step:` jonka `input:` on jonkin olemassa olevan säännön `output:`.
- Ohjaa se tuottamaan yksi stabiili tiedosto `outputs/<stage>/...`.
- Lisää uusi output `rule all` -input-listaan, jotta se tulee “oletustargetiksi”.

Tämä on Snakemaken perusmalli: sääntö määrittelee inputin ja outputin, ja riippuvuus syntyy siitä että jonkun toisen output vastaa toisen inputia. citeturn4search9turn8search21

**CI dry-run + smoke**
- Lisää CI:hin (esim. entity["company","GitHub","code hosting company"] Actions) kaksi tasoa:
  1) `snakemake -n` ja `snakemake --lint` ilman dataa (rakentaa DAGin ja tarkistaa laatua). citeturn4search3turn8search1
  2) Smoke-run pienellä testidatalla (jos mahdollista), jolloin ajetaan `--cores 1` ja varmistetaan että report-target syntyy.

`--lint` on Snakemaken oma linteri ja se on nimenomaan best practices -työkalu workflow-koodin ylläpitoon. citeturn8search1