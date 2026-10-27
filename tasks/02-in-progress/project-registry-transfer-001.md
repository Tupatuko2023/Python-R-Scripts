# Projektirekisterin siirtopaketti Python-R-Scriptsiin

## State

- State: `02-in-progress`
- Tunniste: `project-registry-transfer-001`
- Omistava repo: `Tupatuko2023/Python-R-Scripts`
- Haara: `chore/project-registry-transfer-001`
- Valmistelun ja myöhemmän työn worktree päächeckoutista: `tmp/project-registry-transfer-001`
- Pohjacommit: `470f9ffe75c7f341abae11b45664976bf197974a` (paikallinen origin/main; ei uutta fetchiä).
- Siirtopaketti ja README:n muotoilukorjaus validoitu Linux-CI:ssä. Kortti review-tilassa ihmisen katselmointia varten.

## Context

Owner pyysi tässä keskustelussa rajattua READY-valmistelua. SKILLS.md:n
orkestroijan ohjaaman tehtävänluonnin poikkeus sallii tämän metadata-only-kortin.
Lue ennen jatkoa AGENTS.md, SKILLS.md, config/agent_policy.md ja
config/steering.md. Älä siirrä lähderepon TASK-luokittelijaa, lifecycle-linteriä
tai hyväksyntämenettelyä kohderepoon.

Ensimmäinen käyttöönotto koskee vain päärepon omia koordinointiprojekteja.
FOF:n ja Quantify-projektin paikalliset tehtäväjonot ja hyväksynnät säilyvät.
Tämä tehtävä asentaa työkalun ja käyttöohjeen; agenttiohje, tyhjä projektipohja
ja yhden aidon projektin pilotti ovat erillisiä jatkovaiheita.

Päächeckoutissa on ennestään seurattuja ja untracked-muutoksia; niihin ei kosketa.
Eristetty worktree perustuu paikallisesti saatavilla olevaan origin/mainiin,
joka oli valmistelussa neljä committia päächeckoutin HEADia edellä. Ohje- ja
porttitiedostoissa ei ollut näiden välillä eroja. Ei synkronointiväitettä etäpalveluun.

## Inputs

- Lähderepo: `Tupatuko2023/FOF-Dissertation-Project`.
- Toimitettu lähdecommit: `a098b62e9cce7079f84ef4cfd0665ddef93ca816`.
- Generaattorin Git-blob: `de92f22219e2abf479bb98eb79896d4d66442865`.
- Testien Git-blob: `2b108e05a1f260395ef62165b0231fe4bbde6f9b`.
- Lähteen käyttöohje: `docs/governance/project_registry/README.md` samasta commitista.
- Kohteen `tasks/_template.md`, `.gitignore`, `tools/run-gates.ps1`,
  `tools/run-gates.sh`, Makefile ja `.github/workflows/python-ci.yml`.
- Aiempi siirrettävyys- ja monirepokartoitus tässä keskustelussa.

Varmenna lähdetiedostot Git-objekteista, älä kopioi lähderepon muuttuvaa työpuuta.
Säilytä generaattori ja testit lähdecommitin mukaisina; jos sovitus vaatii
käyttäytymismuutoksia, raportoi tarve ennen laajennusta. Python 3.11+ kattaa
testien contextlib.chdir-vaatimuksen ja kohderepon nykyisen Python-CI:n.

## Outputs

Tulevan toteutuksen ainoat sisältötiedostot:

1. `tools/project_registry/render_projects_csv.py`
2. `tools/project_registry/tests/test_render_projects_csv.py`
3. `docs/governance/project_registry/README.md`

Näiden lisäksi vain tämän saman kortin hallitut lifecycle-polut. Ei TEMPLATEä,
AGENTS-muutosta, projektirivejä, skeemalaajennusta, ignore-muutosta, riippuvuuksia,
submoduleja, dataa, analyysiä tai muiden agenttien töitä. Ei lähderepon muutoksia.

### Viiden polun raja ja ajot

Kortin siirrossa molemmat polut lasketaan. Älä niputa kaikkia vaiheita samaan ajoon.

- Valmistelu: yksi READY-polku, ei sisältötoteutusta.
- Erillinen admission-ajo: `tasks/01-ready/project-registry-transfer-001.md`
  siirretään `tasks/02-in-progress/project-registry-transfer-001.md`: kaksi polkua,
  ei vielä kolmea sisältötiedostoa. Varmenna ja lokita porttiympäristö ensin.
- Seuraava toteutusajo jatkaa jo admitted-korttia: kolme sisältötiedostoa sekä
  in-progress-lähtöpolku ja `tasks/03-review/project-registry-transfer-001.md`:
  yhteensä viisi polkua. Kortti on valittu READYstä admission-ajossa.
- Mahdollinen ihmishyväksyntään perustuva sulkeminen on erillinen vaihe.
  Agentin oma merkintä ei ole SKILLS.md:n tarkoittama riippumaton hyväksyntänäyttö.

### README-vaatimukset

- Pakettiversio `1.0.0` (paikallinen siirtopakettiversio, ei väite lähteen tagista),
  lähderepo ja yllä oleva toimitettu lähdecommit sekä tiedostojen Git-blobit.
- Projektitiedosto on ylläpidettävä lähde; CSV on generoitu näkymä.
- Repoidentiteetti + koko repojuureen suhteutettu polku yksilöivät tehtäväviitteen.
  Markdown-taulukko `repo | task | path` riittää. Pelkkä TASK-tunnus ei ole globaali avain.
  Linkit ratkaistaan nimetyn repon juuresta, eivät rekisterihakemistosta.
- Älä kopioi tehtäväkorttia tai sen tilaa toiseksi ylläpidettäväksi totuudeksi.
  Projektin omistaja määrää vastuun; tehtävää tekevä agentti päivittää vain
  kirjoitusrajaukseen kuuluvan projektin aloituksessa, merkkipaalussa,
  keskeytyksessä, toimituksessa ja sulussa paikallisten valtuutusten mukaisesti.
- Projektin tila, toimitus ja worktree-siivous ovat erillisiä; DONE ei todista siivousta.
- Flat frontmatter + merkkijonolistat, ei yleistä YAMLia tai sisäkkäisiä olioita.
  Duplikaatit hylätään. Lähdekuvausmerkinnät, SHA256 ja täsmällinen
  `## Worktree-havainnot` ovat nykyisen skeeman sopimuksia.
- Oletusrekisteri `docs/governance/project_registry`; vain sen suorat PRJ-*.md-tiedostot,
  ei rekursiivista keräilyä. Tässä vaiheessa rekisteriin tulee vain README.
- CSV-polku `outputs/cache/project_registry/projects.csv` on jo ignored.
  `--check` ei korvaa erillistä Git-ignore-tarkistusta.
- Repoidentiteetti tarkistetaan erikseen: generaattori ei sido repo-kenttää kohderepoon.
- `--verify-guard` vaatii jo commitoidun, muuttumattoman lähdetiedoston; dokumentoi
  ensiluonti erikseen. Älä ohita suojaa käyttäjän muutosten vuoksi.
- Ei väitöskirjakohtaista blocker ledger-, orkestroija- tai DONE-hyväksyntäoletusta.

## Definition of Done (DoD)

### Valmistelun näyttö

- Kortti noudattaa paikallista pohjaa ja on Gitille näkyvä erillisessä worktreessä.
- Lähdecommit ja kaksi blobia on varmennettu paikallisesti.
- Täsmälliset tulevat komennot ja porttiympäristön rajat on kirjattu.
- Tässä repossa ei löytynyt tools/hotl/lifecycle_lint.py-työkalua; älä lainaa sitä
  lähdereposta tai väitä sen tarkistuksia paikallisiksi vaatimuksiksi.

### Tulevan toteutuksen validoinnit

Aja worktreen repojuuresta, varmista Get-Location ennen komentoja.
Tarkista jokaisen komennon exit-koodi erikseen; Makefilen test/lint-targetien
virheiden vaimennus ei kelpaa PASS-näytöksi.

```powershell
Get-Location
python --version
python -B -m unittest discover -s tools/project_registry/tests -p test_render_projects_csv.py
python -m pytest -q
git check-ignore -v -- outputs/cache/project_registry/projects.csv
git diff --check
git status -sb
```

Koko generaattorisarjan on sisällettävä toimitetun lähteen duplikaattiregressiot:
skalaari/lista, sama/eri arvo, tiedosto/avain/rivi, puuttuva CSV ja olemassa olevan
CSV:n tavujen säilyminen. Lähteen aiempi 23/23-tulos ei ole kohderepon uusi tulos.
Nykyiset testit kattavat myös determinismin, pitkän lähdekuvauksen, seuraavan
askeleen, esteen, toimituksen/siivouksen eron, --check-moden ja Git-konfliktisuojan.

Aja lisäksi tämä CLI-smoke vain synteettisessä väliaikaisessa Git-repossa.
Se ei luo aitoa projektia kohderepon rekisteriin. PowerShellissä:

```powershell
@'
import contextlib, importlib.util, subprocess, sys, tempfile
from pathlib import Path
spec = importlib.util.spec_from_file_location('registry_tests', Path('tools/project_registry/tests/test_render_projects_csv.py').resolve())
helpers = importlib.util.module_from_spec(spec)
spec.loader.exec_module(helpers)
cli = Path('tools/project_registry/render_projects_csv.py').resolve()
with tempfile.TemporaryDirectory() as temporary:
    root = Path(temporary)
    subprocess.run(['git', 'init', '-q', str(root)], check=True)
    (root / '.gitignore').write_text('outputs/\n', encoding='utf-8')
    (root / 'registry').mkdir()
    (root / 'registry/PRJ-TEST.md').write_text(helpers.project_text(repo='Tupatuko2023/Python-R-Scripts'), encoding='utf-8')
    args = [sys.executable, '-B', str(cli), '--registry', 'registry', '--output', 'outputs/projects.csv']
    subprocess.run(['git', 'check-ignore', '-q', '--', 'outputs/projects.csv'], cwd=root, check=True)
    subprocess.run(args, cwd=root, check=True)
    before = (root / 'outputs/projects.csv').read_bytes()
    subprocess.run(args, cwd=root, check=True)
    assert before == (root / 'outputs/projects.csv').read_bytes()
    subprocess.run(args + ['--check'], cwd=root, check=True)
    print('Synthetic CLI generation, determinism, ignore and --check: PASS')
'@ | python -B -
```

Repossa dokumentoitu portti ennen sisältötoteutusta ja uudelleen ennen toimitusta:

```powershell
Get-Location
& ./tools/run-gates.ps1 --mode pre-push --smoke
```

Ennen toimitusporttia stageaa vain tarkistetut tehtäväpolut: guardrails sekä
R/Python-syntaksitarkistukset perustuvat indeksiin. Portti myös tarkistaa
Fear-of-Falling/renv.lockin luettavuuden. Älä aja analyysimoodia, asenna paketteja,
muuta R-startupia tai muuta lockfileä tämän tehtävän vuoksi. Jos renv-paketti tai
muu pakollinen ympäristöedellytys puuttuu, raportoi täsmällinen este.
K18/QC ei sovellu tämän ei-tieteellisen työkalun siirtoon; tieteellisiä putkia ei ajeta.

Lint: repon dokumentoidut lint-tarkistukset ovat `ruff check .` ja `black --check .`
(Makefile lint). Käytä jo asennettuja työkaluja; kirjaa puuttuva työkalu ja baseline-
virheet erikseen. Ei massamuotoilua eikä riippuvuusasennuksia. Ennen toimitusta
vaaditaan myös soveltuvat CI-tarkistukset normaalin erikseen valtuutetun menettelyn mukaan.

## Log

- 2026-10-25T15:53:44.667923+02:00: Ownerin rajattu valmistelupyyntö, nykyiset paikallisohjeet,
  lähdecommit ja blobit tarkistettu. Eristetty worktree luotu olemassa olevasta
  paikallisesta origin/mainista. Vain tämä uusi READY-kortti kirjoitettu.
  Kortin Git-näkyvyys ja rakenne varmennetaan valmistelun lopuksi.

- 2026-10-25T15:53:59.010292+02:00: Valmistelutarkistukset PASS: paikallisen pohjan otsikot, READY-tila, suunnitellun smoke-koodin syntaksi, whitespace ja Git-näkyvyys (check-ignore exit 1, status näyttää vain uuden kortin). Porttikäynnistimen --help exit 0 myös tässä worktreessä sallitussa prosessissa; politiikkatiedostot latautuivat. Varsinaiset portit ja toteutustestit suorittamatta.

- 2026-10-25T16:02:06.336259+02:00: Admission-ajo: nykyiset ohjeet, haara ja Git-näkyvä READY-kortti tarkistettu. Varsinainen tools/run-gates.ps1 --mode pre-push --smoke PASS sallitussa sandboxin ulkopuolisessa prosessissa (renv-lock luettu, ei asennuksia). Vain tämän kortin READY- ja in-progress-polut muuttuvat tässä paikallisessa vaiheessa. Ownerin yhtenäinen jatkovaltuutus kattaa seuraavan toteutusvaiheen ilman uutta päätöstä.

## Toteutus ja validointinäyttö

- Admissionin paikallinen commit: `ce44996a4077bb5bc3ec0683d5dce2ff01c1463d`.
- Generaattori ja testit siirretty Git-objekteista lähdecommitista tavuntarkasti;
  blobit vastaavat Inputs-osion arvoja. Paikallinen README kirjoitettu.
- Python 3.12.4; generaattorin koko unittest-sarja: **23/23 PASS**.
- Kortin synteettinen CLI-smoke: generointi kahdesti samoilla tavuilla,
  oikea Git-ignore-portti ja `--check`: **PASS**. Ei aitoja projektirivejä.
- `git check-ignore -v -- outputs/cache/project_registry/projects.csv`: **PASS**,
  `.gitignore:43:**/outputs/`. Lähdevertailu Git-objekteihin: **PASS**.
- `python -m pytest -q`: collection ERROR, EFI-pakettia ei ole editable-asennettu.
  Root pytest.ini osoittaa src-polkuun, mutta paketti on Electronic-Frailty-Index/src.
- Uusinta ilman asennusta: `python -m pytest -q -o pythonpath=Electronic-Frailty-Index/src`:
  **86 failed, 474 passed, 25 skipped, 268 subtests passed** (76.68 s).
  Koko repon vaatimus ei läpäise; tämän paketin unittestit läpäisevät myös osana ajoa.
- Esimerkkejä rajauksen ulkopuolisista virheistä: FOF test_architecture.py:n
  Windows-erottimen vertaaminen kauttaviivapolkuun; test_artifact_transfer.py:n
  WSL-bash ei löydä /bin/bashia; Quantify test_metadata_files.py:n
  case-duplicate-tarkistus sekä DEAC-runnerin testejä. Ei blanket-väitettä,
  että jokaisen 86 virheen juurisyy olisi erikseen selvitetty.
- `python -m ruff --version` ja `python -m black --version`: moduulit puuttuvat.
  Ei asennuksia, massamuotoilua tai aliprojektien korjauksia. Lintille ei PASS-väitettä.
- Varsinainen repoportti ennen admissionia: **PASS**, myös renv-lockin luku.
  Staged-sisältöportti myös PASS: guardrails, renv-lockin luku ja molempien
  siirrettyjen .py-tiedostojen syntaksikäännös; ei staged R-tiedostoja. R:n
  LC_*-locale-varoitukset eivät estäneet tarkistusta (exit 0).
- `git diff --check`: PASS. K18/QC: NOT APPLICABLE — päärepon ei-tieteellinen
  työkalusiirto, ei tutkimusdataa, derivointeja tai analyysimuutoksia.
- Tässä toteutusvaiheessa kolme uutta sisältötiedostoa ja nykyinen kortti:
  neljä muutospolkua. Review-siirtoa ei tehdä puuttuvan DoD:n vuoksi.
- Ei AGENTS-, TEMPLATE-, ignore- tai projektitietomuutoksia, etätoimia tai worktree-poistoa.

- 2026-10-25T16:06:52.833322+02:00: Toteutus ja ajettu testinäyttö kirjattu. Pakollisen pytest-epäonnistumisen vuoksi ei review-siirtoa; rajauksen ulkopuolisia tiedostoja ei korjata.

- 2026-10-25T16:07:24.080766+02:00: Staged repoportti PASS (exit 0); koko repon pytest ja lint-ympäristö ovat edelleen este. Toteutus tallennetaan paikalliseen committiin, jonka SHA raportoidaan vastauksessa.

## Ajantasainen validointipäätös: baseline-vertailu

### Todelliset porttivaatimukset

- AGENTS.md:n Python-ohje käskee ajamaan unit-testit Python-muutoksessa ja
  dokumentoi koko pytest-ajon. SKILLS.md vaatii vähintään yhden smoke-ajon.
  Paikallinen tools/run-gates.ps1 --mode pre-push --smoke on jo PASS myös staged-koodilla.
- .github/workflows/python-ci.yml käynnistyy näistä .py-polkujen muutoksista:
  Ubuntu, Python 3.11, riippuvuudet requirements.txt:stä (tai konfiguroidun paketin
  kautta), Fear-of-Falling/pyproject.toml:n dev-ryhmä sekä EFI editable-asennuksena.
  Testivaihe EI hyväksy epäonnistumista: se säilyttää raportin mutta palauttaa rc:n.
  POSIX-placement ajetaan erikseen omistajan hallitsemassa yksityisessä HOMEssa.
- Makefile kuvaa Ruffin ja Blackin valinnaisiksi "if installed" -työkaluiksi.
  make lint ajettiin: molemmat puuttuvat, virheet vaimennetaan targetissa.
  Exit 0 EI ole lint-PASS. Näistä ei löytynyt erillistä pakollista CI-lint-jobia;
  aiempi oletus että molempien puuttuminen yksin estäisi review'n oli liian vahva.
- Uusi README kuuluu .github/workflows/markdownlint.yml:n soveltuviin
  Prettier --check- ja markdownlint-cli2-tarkistuksiin. Task-kortit suodatetaan pois.
  CI käyttää Node 20:tä ja package-lockiin sidottua npm ci:tä. Paikalliset
  node_modules-työkalut puuttuvat; tarkistukset ovat SUORITTAMATTA, eivät PASS.
- FOF:n R-CI, raskas K-smoke ja Quantify-Snakemake eivät aktivoidu tämän
  siirtopaketin sisältöpoluista. PR:n yleiset polkusuodatin- ja CodeQL-jobit
  kuuluvat myöhempään toimitukseen; etä-branch-protectionia ei haettu ilman verkkovaltuutta.
- Ei löytynyt sääntöä, joka hyväksyisi baseline-virheet automaattiseksi poikkeukseksi.

### Saman ympäristön vertailu

Verrattiin c62d7abd64e3b1269cad2e2e6e0c91c6bb4585a5-revisiota sitä edeltävään
sisältöversioon ce44996a4077bb5bc3ec0683d5dce2ff01c1463d. Baseline materialisoitiin
omaan detached-worktreehen päächeckoutin tmp/project-registry-baseline-001-polkuun.
Muiden checkoutien HEADia, työpuuta tai indeksiä ei vaihdettu. Ei tutkimusdatan
siirtoa: baseline muodostettiin vain Gitin commitoiduista tiedostoista.

Molemmissa sama Windows AMD64, Python 3.12.4, pytest 9.0.2, pandas 2.3.3,
numpy 2.4.1, openpyxl 3.1.5 ja jsonschema 4.23.0, sama PATH ja samat asetukset:
`python -m pytest -q --tb=no -o pythonpath=Electronic-Frailty-Index/src`.
Vain havaintoja keräävä pytest-plugin lisättiin; testejä tai tuloksia ei ohitettu.

| Revisio | failed | passed | skipped | subtests passed |
|---|---|---|---|---|
| Baseline ce44996 | 85 | 452 | 25 | 247 |
| Toteutus c62d7ab | 85 | 475 | 25 | 268 |

Vertailu perustui nodeid-, vaihe- ja virhesyytietoihin, ei vain lukumäärään.
85 virheraportissa oli kummassakin 79 erillistä nodeidia (osa subtest-raporteista
käyttää samaa nodeidia). Näistä 78 oli yhteisiä. Näistä 77:n virhesyyt olivat samat
kun WSL:n prosessitunnukset ja satunnaiset synteettiset temp-polut normalisoitiin.
Yhdessä workbook-testissä toinen ajo epäonnistui suoraan snapshot-guardissa ja
toinen saman guardin virhetekstin regex-vertailussa. Molemmat virhetekstit säilytettiin.

Kokonaisten ajojen kaksi eriävää tunnistetta olivat:

- tests/test_deac_cohort_runner.py::test_xlsx_metadata_validation_and_first_visit_selection
- tests/test_deac_cohort_runner.py::test_xlsx_reader_rejects_source_change_after_metadata_validation

Nämä ajettiin erikseen kolmesti kummassakin revisiossa: molemmat virheet toistuivat
myös baselinessa. Ensimmäinen testi sekä läpäisi että epäonnistui kummassakin
revisiossa; toinen epäonnistui kohdennetuissa ajoissa kummassakin. Sama
"Source workbook changed while its snapshot was read" -virhe toistui.
Näiden testien ja DEAC-lukijan Git-diffi oli tyhjä revisioiden välillä.

Tässä vertailussa ei löytynyt siirtopaketin aiheuttamaa uutta testivirhettä.
Tämä ei todista kaikkien mahdollisten regressioiden puuttumista eikä hyväksy
baseline-virheitä. Aiempi 86 failed -ajo vaihteli tässä 85:een; ainakin workbook-
testien ajokohtainen vaihtelu on nyt erikseen osoitettu.

### Virheiden luokittelu ja evidenssi

- Ympäristösidonnaisia näyttöjä molemmissa revisioissa: WSL/Bash-käynnistys
  (25 raporttia), Windowsin symlink-etuoikeus WinError 1314 (10), skriptin
  käynnistys WinError 193 (8), puuttuva os.O_DIRECTORY (6), RECEIVER_REQUIRES_POSIX,
  PosixPathin mahdottomuus Windowsissa ja POSIX-julkaisuoperaatioiden rajoitteet.
- Baselinessa toistuvia muita virheitä: esimerkiksi kymmenen kb_pull-testin
  TypeError ('method' / 'str') ja Quantify-metadatan case-duplicate-assertio.
  Näille ei päätelty pelkän vertailun perusteella tarkkaa ympäristöjuurisyytä.
- Workbookin snapshot-virheiden ajokohtainen vaihtelu on osoitettu; sen
  syvempää korjausta tai tieteellisen lukijan muuttamista ei tehty.
- EFI:n alkuperäinen collection-este johtui editable-asennuksen puuttumisesta;
  pelkkä src-polun asetus mahdollisti koko vertailun ilman asennuksia.
- Lähdetoteutuksen 23 uutta testiä näkyvät passed-erotuksena; aiempi
  generaattorin 23/23- ja CLI-smoke-näyttö koskee muuttumatonta koodia.

Täydet failed-nodeid:t, virhetekstit, kohdennetut ajot ja lokit säilytettiin
paikallisessa väliaikaisessa evidenssikansiossa nimeltä
prs-registry-validation-o1imlbqc. Sen sha256.json yksilöi artefaktit.
Baseline JSON SHA256: 83c3583315b8ee62bb189f240a6410f77a2de52e34018f8d9ca1902e39314b06.
Toteutus JSON SHA256: d18c1dab06fbee026f2484392330a1482cd35f60af0cf363df3188d4d3c14eb0.
Evidenssi on paikallinen, ei julkaistu CI-tulos tai pysyvä hyväksyntä.

### Pienin jäljellä oleva toimi

Ei review-siirtoa: koko testisarjan hyväksyttyä PASS-tulosta eikä README:n
Markdown-porttien tulosta ole. Ei aliprojektien korjauksia, asennuksia tai porttiohitusta.
Termux ei ole välttämätön; ensisijainen dokumentoitu täysi testireferenssi on Linux-CI.

Aja sama toteutus c62d7abd64e3b1269cad2e2e6e0c91c6bb4585a5 puhtaassa,
valmiiksi varustetussa repo-worktreessä, jonka rootissa on AGENTS.md. Ei likaisen
checkoutin kopiointia tai tutkimusdataa. Tarvitaan CI:n Python 3.11 -ympäristö,
requirements-/EFI-paketin riippuvuudet, FOF dev-ryhmä ja EFI editable-asennuksena,
paikallinen Git ja POSIX Bash sekä Node 20 ja lockfilen mukaiset Markdown-työkalut.
Nämä ovat ympäristön ennakkoehtoja, eivät tämän ohjeen asennusvaltuutus.

Tarkistuskomennot valmiissa Linux-ympäristössä repojuuresta:

```sh
pwd
python -B -m unittest discover -s tools/project_registry/tests -p test_render_projects_csv.py
python -m pytest -q --maxfail=1 --disable-warnings --ignore=Fear-of-Falling/tests/test_place_verified_bundle.py
```

Placement-testit lisäksi CI:n dokumentoidussa yksityisessä /home/foftest-HOMEssa,
jonka omistus, moodi 0700 ja _posix_anchor on jo varmennettu CI-ohjeen mukaan:

```sh
env HOME=/home/foftest python -m pytest -q --disable-warnings Fear-of-Falling/tests/test_place_verified_bundle.py
./node_modules/.bin/prettier --check docs/governance/project_registry/README.md
./node_modules/.bin/markdownlint-cli2 docs/governance/project_registry/README.md
```

Jos samat baseline-virheet jäävät myös valmiissa CI-ympäristössä, tarvitaan
nimetty repon käytäntöjen mukainen poikkeuspäätös tai erilliset baseline-korjaukset;
ei automaattista vihreää hyväksyntää. Tässä sessiossa ei ole varmennettua valmiiksi
varustettua POSIX-testisessiota. Sallitun Windows-prosessin Bash-portti on PASS,
mutta se ei muuta Windows-Pythonia Linux-Pythoniksi. Ei uusia asennuksia tehty.

- 2026-10-25T16:25:58.512606+02:00: Baseline-vertailu ja porttivaatimukset kirjattu. Generaattori, testit ja README muuttumattomina; vain tämä lokikortti päivitetty. Ei review-siirtoa ilman pakollista näyttöä.

## Blockers

**Aktiivinen este:** koko repon Python-testit eivät läpäise tässä Windows-
ympäristössä. Tehtävä pysyy 02-in-progress-tilassa, ei review-valmiusväitettä.
Jatko samalla valtuutuksella: suorita yllä oleva koko testisarja repon hyväksymässä
valmiiksi varustetussa ympäristössä (CI käyttää Linuxia ja EFI:n editable-asennusta)
sekä vaaditut lint-tarkistukset jo asennetuilla työkaluilla. Tämän toimeksiannon
asennus-, verkko- ja sisältörajat säilyvät. Ympäristön valmistelu tai baseline-
korjaus, joka edellyttää niiden laajentamista, raportoidaan erikseen.

Bashin alkuperäinen sandbox-este ratkesi käyttämällä normaalisti sallittua
ulkopuolista prosessia; varsinainen portti läpäisi ennen admissionia. Alla olevat
valmistelun havainnot ovat historiallisia, eivät nykyinen väite portin ajamattomuudesta.


- Sandboxissa `Git Bash --noprofile --norc -c` kaatuu ennen skriptiä:
  couldn't create signal pipe, Win32 error 5; exit -1073741502.
- Saman binäärin minimaalinen käynnistys ja tools/run-gates.ps1 --help toimivat
  sallitussa sandboxin ulkopuolisessa agenttiprosessissa (exit 0). Tämä on näyttöä
  agentin sandbox-rajoitteesta, ei käyttäjän terminaalissa toistetusta viasta.
- Käyttäjän oman terminaalin ajoa ei ole havaittu. Tarvittaessa hän voi ajaa
  yllä olevan normaalin PowerShell-porttikomennon samasta worktreestä.
- Varsinaista --mode pre-push --smoke -porttia ei ajettu valmistelussa.
  --help ei ole toimitusportin PASS. Sisältötoteutus odottaa toimivaa sallittua
  porttiympäristöä ja onnistunutta oikeaa porttia. Sandboxin ulkopuolinen ajo
  vaatii ympäristön normaalin oikeuden; porttia tai hyväksyntää ei saa ohittaa.
- Ei asennuksia, oikeusmuutoksia, porttiskriptien muutoksia tai verkko-operaatioita.

## Links

- AGENTS.md; SKILLS.md; config/agent_policy.md; config/steering.md.
- Lähteen toimitus-PR:t: FOF-Dissertation-Project #339 ja #340.
- Repojuuren tasks/-jono omistaa tämän koordinointitehtävän.
  Aliprojektien kortteja ei siirretä eikä niiden tiloja kopioida.

## Linux-validoinnin seuraava toimitustoimi (ei vielä suoritettu)

Toteutussisältö c62d7abd64e3b1269cad2e2e6e0c91c6bb4585a5 on edelleen
muuttumaton; nykyinen jatko lisää vain validointikirjauksen. Työpuu oli puhdas.

Rajattu Linux-diagnoosi sallitussa prosessissa: `wsl --list --quiet` näyttää vain
Docker Desktopin sisäisen jakelun. `wsl --exec /bin/sh -c` tulosti Linuxin,
mutta `command -v python3` ja `command -v node` eivät löytäneet tulkkeja (exit 127).
Tätä sisäistä jakelua ei muuteta dokumentoimattomaksi kehitysympäristöksi.
Ei WSL-asennuksia, kontteja, järjestelmämuutoksia tai riippuvuusasennuksia tehty.
Tässä sessiossa ei ole käytettävissä varmennettua repon CI:tä vastaavaa paikallista
Linux/Python 3.11/Node 20 -ympäristöä. Git Bash ei ole Linux-Python-ympäristö.

Valmisteltu yksi hyväksyttävä etätoimierä:

1. Varmenna originin main ja mahdolliset saman haaran PR:t lukutoimilla.
   Varmista rajattu neljän tiedoston diff sekä muuttumaton generaattori ja testit.
   Ei pullia tai muiden checkoutien päivitystä.
2. Pushaa nykyinen chore/project-registry-transfer-001-haara tavallisena
   fast-forward-pushina Tupatuko2023/Python-R-Scripts-originille.
3. Avaa draft-PR tästä haarasta mainiin, otsikolla
   "feat: transfer project registry tooling (CI validation)".
4. Lue ja odota nykyisten workflowien tulokset ja raportoi Linux-testit ja
   README:n Markdown-tarkistukset. Jos virheitä jää, rajaa vain tarpeelliset
   baseline-tarkistukset; ei yleistä korjausta.

Tämä ei ole nykyisen toimeksiannon antama push- tai PR-valtuutus. Etätoimet
odottavat yhtä konkreettista hyväksyntää make-repo-contribution-skillin mukaisesti.
Ei mergeä, auto-mergeä, DONE-siirtoa, review-valmiusväitettä tai worktree-poistoa.
Päärepon ohjeista ei löytynyt in-progress-kortin työhaara/draft-PR-julkaisukieltoa;
SKILLS.md/config/agent_policy.md vaativat DoD:n ennen review-siirtoa. Kortti
säilytetään siksi in-progressissa draftissa; sitä ei siirretä valmiiksi CI:n saamiseksi.
Aliprojektien main/lifecycle-säännöistä ei tehdä päärepon uusia sääntöjä.

PR:n nykyiset triggerit käynnistävät python-ci:n Ubuntu/Python 3.11 -testit
ja EFI editable-asennuksen sekä FOF dev-ryhmän. README aktivoi
markdownlint-workflowin Node 20:n, npm ci:n, Prettierin ja markdownlint-cli2:n.
Myös soveltuvat PR:n polkusuodatin- ja CodeQL-workflowit voivat käynnistyä.
CI-sääntöjä tai in-progress-tilan rajoja ei muuteta. K-smoke jää nykyisten
polkusuodattimien mukaan pois; ei uusia tutkimusanalyysiajoja.

- 2026-10-25T17:26:59.368680+02:00: Linux-ympäristön rajattu tarkistus valmis; push/draft-PR-erä ja PR-kuvaus valmisteltu hyväksyttäväksi. Vain kortin paikallinen kirjaus, ei etätoimia.

## GitHub CI -näyttö: PR 216

- Draft-PR: https://github.com/Tupatuko2023/Python-R-Scripts/pull/216
- Puskettiin täsmälleen hyväksytty HEAD 250211d2168070c046b573d2c2876bf560e5b318
  tavallisena pushina haaraan chore/project-registry-transfer-001. Työpuu oli
  puhdas, PR-diffissä vain neljä sovittua polkua. Ei forcea, mergeä tai DONE-siirtoa.
- Origin/main oli edennyt d4e03c4bbb223f9c3f273f52f20ec242e0f3e888-versioon;
  PR oli mergeable, eikä mainia yhdistetty paikalliseen haaraan tai muihin checkoutteihin.
- Generaattori, testit ja README ovat edelleen c62d7ab-toteutuksen mukaisia.
- Linux/Python 3.11 PR-ajossa 40213483193 riippuvuuksien asennus ja EFI editable
  PASS. Run tests (pytest -> JUnit XML) suoritettiin: **515 passed, 17 skipped,
  290 subtests passed** (79.82 s). Ei epäonnistumisia, vaihe ei skipped.
- Samassa ajossa yksityisen POSIX-HOMEn omistus/anchor varmennettiin ja
  placement-vaihe suoritettiin: **43 passed, 1 skipped** (0.90 s).
- Python-CI:n push-ajo 40213467990 myös success. CodeQL Python/JavaScript PASS;
  K-smoken polkusuodatin PASS ja raskas K-ajo ei sovellu (skipped, ei testien PASS-väite).
- Python PR-ajo: https://github.com/Tupatuko2023/Python-R-Scripts/actions/runs/40213483193
- Markdown-ajo: https://github.com/Tupatuko2023/Python-R-Scripts/actions/runs/40213483134

**Jäljellä oleva este:** Markdown-jobin Check Prettier formatting epäonnistui
ainoaan mukana tarkistettuun README-polkuun
`docs/governance/project_registry/README.md`: "Code style issues found in the
above file. Run Prettier with --write to fix." Exit 123 on xargs-vaiheen tulos.
Run markdownlint jäi tämän vuoksi skipped: ei PASS-näyttöä.

Pienin korjaus on repon lukitun Prettierin `--write` vain tähän READMEhen ja
sen jälkeen samalle tiedostolle `--check` sekä markdownlint-cli2. Generaattoriin,
testeihin tai CI-sääntöihin ei tarvitse tehdä muutoksia tämän löydöksen vuoksi.
Tässä hyväksytyssä CI-erässä löydös raportoidaan; READMEä ei vielä muutettu.
Kortti jää in-progressiin ja PR draftiksi. Tämä CI-kirjaus tallennetaan vain
paikallisesti; tarkistetun PR-HEADin tuloksia ei esitetä uuden revision ajoina.

- 2026-10-25T18:52:45.733300+02:00: Hyväksytty push/draft-PR ja CI-seuranta valmis. Python-portit PASS; README Prettier FAIL ja markdownlint suorittamatta. Ei review-siirtoa.

## README:n rajattu muotoilukorjaus

- Owner valtuutti README:n muotoilun, kortin ylläpidon, commitin ja pushin
  samaan PR:ään #216 sekä review-siirron onnistuneiden CI-porttien jälkeen.
- Tarkistettu 20f3498 on vain edellisen CI-ajon kirjaus; sisältyy tulevaan pushiin.
- Worktreen npm ci --no-audit --no-fund asensi lukitut kehitystyökalut;
  package.json ja package-lock.json muuttumattomia. Työkalut säilytetään
  ignored tmp/markdown-tools/node_modules-hakemistossa, ei commitissa.
- Prettier 3.9.9 --write ja --check vain README-polulle: PASS.
- markdownlint-cli2 0.23.3 / markdownlint 0.41.1: yksi tiedosto lintattu,
  nolla virhettä, exit 0. Summaryn 0 files tarkoittaa virheitä sisältävien
  tiedostojen määrää, ei lintattujen tiedostojen määrää (Linting: 1 file).
- README:n kaikki sisältö säilyi: vertailu normalisoi whitespace-merkit ja
  taulukoiden separator-viivojen pituudet. Vain taulukoiden muotoilu muuttui.
- Generaattorin/testien diffi c62d7ab-versioon tyhjä; CI-sääntöjä ei muutettu.
- Korjauksen jälkeiset CI-portit odotetaan ennen review-siirtoa.

- 2026-10-25T20:01:54.367521+02:00: README:n rajattu korjaus ja paikalliset Markdown-portit PASS; sisältövertailu PASS. Korjaus pusketaan samaan draft-PR:ään ja CI seurataan.

## Katselmointivalmius

- Katselmoitava paketti: kaksi tavuntarkkaa lähdetiedostoa, paikallinen README
  ja tämän tehtävän review-kortti. Generaattorin/testien diffi c62d7ab-versioon tyhjä.
- PR: https://github.com/Tupatuko2023/Python-R-Scripts/pull/216 (draft säilytetään).
- Korjaus-HEAD eb4c26f005e6e3e8793643260c1f8fb96fddb16b: kaikki soveltuvat CI-jobit PASS.
- Python-ajon 40219306327 päätestit ja erillinen POSIX-placement todella suoritettiin.
  - 515 passed, 17 skipped, 290 subtests passed in 89.13s (0:01:29)
  - 43 passed, 1 skipped in 1.01s
- Markdown-ajon 40219306309 Prettier ja markdownlint molemmat completed/success;
  lokissa Linting: 1 file ja 0 issues. Ei enää ohitettua README-porttia.
- CodeQL Python ja JavaScript PASS. K-polkujen tunnistus PASS, raskas K-smoke
  ei sovellu muutospolkuihin, eikä skipped-ajoa lasketa testien PASSiksi.
- Tästä review-siirrosta tulevan lopullisen HEADin CI seurataan vielä ennen
  loppuraporttia. Vain kortin polku/tila ja tämä kirjaus muuttuvat.
- Aiemmat Blockers- ja in-progress-kirjaukset ovat vaihehistoriaa: Python- ja
  Markdown-porttien esteet on nyt ratkaistu. Ei avoimia toteutusesteitä.
- Tämä on agentin DoD-handoff, ei ihmisomistajan hyväksyntä eikä DONE-valtuutus.
- Ei mergeä, DONE-siirtoa tai worktree-poistoa. AGENTS/TEMPLATE/projektipilotti
  pysyvät seuraavina erillisinä käyttöönottovaiheina.

- 2026-10-25T20:05:22.065995+02:00: Pakolliset korjaus-HEADin portit PASS; kortti siirretty 03-review-tilaan. Lopullinen CI tarkistetaan pushin jälkeen.

## Ownerin valtuuttama P1/P2-rework 2026-10-27

- Sama tehtävä palautetaan in-progressiin Ownerin nykyisellä rajatulla valtuutuksella. Ei uutta tehtävää.
- Lähde-PR #341 on mergattu mainiin: f29dd518f6b697102406e543c472c1315d198050.
- Korjataan vain generaattori, testit ja README:n provenance/turvallisuuskuvaus; lähteen workflowta ei kopioida.
- Viisi yksilöllistä muutospolkua: kolme sisältötiedostoa sekä kortin in-progress- ja review-polut, myös palautus huomioiden.
- Lähdetehtävän DONE odottaa erillisen säilytysreceiptin kuudennen artefaktin valtuutusta; korjauskoodi on origin/mainissa.
- PR #216:n vanhan revision hyväksyntää ei käytetä uuden revision hyväksyntänä. Ei mergeä tai DONE-siirtoa.
- 2026-10-27: Rework-admission, ohjeet ja puhdas eristetty työpuu varmennettu; päächeckoutiin ei kosketa.
