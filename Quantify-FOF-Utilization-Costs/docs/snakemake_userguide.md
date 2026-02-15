# Snakemake-kayttoohje - Quantify-FOF-Utilization-Costs

Tama ohje kertoo, miten Snakemake-workflow ajetaan tassa aliprojektissa Option B -governanssia noudattaen.

## Periaatteet (Option B)

- Ala koskaan tuo raakadataa repoihin. Kaikki arkaluonteinen data luetaan repo-ulkoisesta sijainnista `DATA_ROOT`-ymparistomuuttujan kautta.
- `Quantify-FOF-Utilization-Costs/config/.env` on paikallinen (gitignored) ja sisaltaa vain placeholderin.
- Kaikki ajon tuottamat artefaktit (QC, raportit, DAG-kuvat jne.) kirjoitetaan `outputs/`-hakemistoon (gitignored).

## Hakemistorakenne (oleellinen Snakemakelle)

- `workflow/Snakefile`: Snakemake-workflow
- `config/config.yaml`: workflow-konfiguraatio
- `R/`: R-skriptit (tavoiterakenne; uudet R-skriptit tanne)
- `scripts/`: Python-skriptit ja skeleton-vaiheet
- `outputs/`: ajon tuotokset (gitignored)
- `logs/`: ajon lokit (gitignored)

## Ennen ajoa: ymparisto ja DATA_ROOT

### 1) CI-safe / sample-ajo (suositus ensiksi)

Sample-moodi ei tarvitse `DATA_ROOT`:ia, eika se saa tulostaa absoluuttisia polkuja.

Aja repo-juuresta:

```bash
cd Quantify-FOF-Utilization-Costs
snakemake -n --config use_sample=True
snakemake --summary --config use_sample=True
```

DAG-kuva (vaatii Graphviz `dot`):

```bash
mkdir -p outputs
snakemake --dag --config use_sample=True | dot -Tpng > outputs/dag.png
```

### 2) Paikallinen ajo arkaluonteisella datalla (vain luvan mukaisesti)

- Luo `config/.env` tiedostosta `.env.example` ja aseta `DATA_ROOT` repo-ulkoiseen turvalliseen sijaintiin. Ala committaa tiedostoa.
- Suorita tarvittaessa inventory (metadata-only):

```bash
python scripts/00_inventory_manifest.py --scan paper_02
```

> Ala tulosta `DATA_ROOT`-arvoa tai absoluuttisia polkuja lokiin/kommentteihin.

## Snakemake-ajotavat

### Dry-run (turvallinen tarkistus)

```bash
snakemake -n
```

### Varsinainen ajo (yksi core aluksi)

```bash
snakemake --cores 1
```

### Konfiguraatio

- `use_sample` tulkitaan robustisti: `True/False`, `1/0`, `yes/no`.
- `OUTPUT_DIR` voidaan asettaa ymparistomuuttujalla, mutta oletus on projektin `outputs/`.

Esimerkki (ohjaa outputit toiseen hakemistoon repo-sisalla):

```bash
OUTPUT_DIR="outputs" snakemake --cores 1
```

## Polut ja skriptihakemistot (RDIR/PYDIR)

Snakefile maarittaa polut suhteessa workflown sijaintiin (`workflow.basedir`), jotta ajo toimii riippumatta siita mista hakemistosta Snakemake kaynnistetaan:

- `RDIR` viittaa `R/`-hakemistoon
- `PYDIR` viittaa `scripts/`-hakemistoon
- `WFDIR` viittaa `workflow/`-hakemistoon

Ala hardcodea absoluuttisia polkuja.

## Aggregaatit (double gate)

Jos workflow tuottaa aggregaatteja:

- Aggregaatit sallitaan vain jos sinulla on lupa ja portit ovat auki:
  - `ALLOW_AGGREGATES=1` (env)
  - mahdollinen erillinen CLI-flag / config (projektin kaytanto)
- Pienet solut (`n < 5`) pitaa suppressata.

Jos et ole varma, pida aggregaatit pois paalta.

## Vianhaku

- `snakemake -n` kertoo DAGin ja puuttuvat inputit ilman ajoa.
- Jos `dot` puuttuu: asenna Graphviz (tai kayta CI:n tuottamaa DAG artifactia).
- Jos environmentin luonti epaonnistuu Windowsissa: kayta CI-ajoa sample-moodissa todisteeksi, ja aja paikallisesti vain jos ymparisto sallii.

## Yksi komento -muistilista

CI-safe:

```bash
cd Quantify-FOF-Utilization-Costs
snakemake -n --config use_sample=True
snakemake --summary --config use_sample=True
```

Local secure (DATA_ROOT vaaditaan):

```bash
cd Quantify-FOF-Utilization-Costs
snakemake -n
snakemake --cores 1
```
