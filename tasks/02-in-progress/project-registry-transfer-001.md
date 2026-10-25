# Projektirekisterin siirtopaketti Python-R-Scriptsiin

## State

- State: `02-in-progress`
- Tunniste: `project-registry-transfer-001`
- Omistava repo: `Tupatuko2023/Python-R-Scripts`
- Haara: `chore/project-registry-transfer-001`
- Valmistelun ja myöhemmän työn worktree päächeckoutista: `tmp/project-registry-transfer-001`
- Pohjacommit: `470f9ffe75c7f341abae11b45664976bf197974a` (paikallinen origin/main; ei uutta fetchiä).
- Admission ja kolmen sisältötiedoston toteutus tehty; review-siirto odottaa pakollisen koko repon testiajotuloksen korjaantumista.

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
