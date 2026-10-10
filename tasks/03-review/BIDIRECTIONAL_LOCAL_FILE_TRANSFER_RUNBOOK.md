# BIDIRECTIONAL_LOCAL_FILE_TRANSFER_RUNBOOK

## Context

Owner valtuutti yhden yhteisen paikallisen tiedostonsiirron käyttöohjeen
(Windows ↔ Termux), joka kattaa molemmat suunnat nykyisillä siirtoskripteillä
ja määrittelee sijoituksen stagingista valittuun lopulliseen repo-kansioon
erillisenä, valtuutettavana vaiheena. Taustalla suljettu
WINDOWS_TERMUX_VERIFIED_PULL (DONE); sen toteutusta ei avata uudelleen.

## Inputs

- Termux → Windows outbound: `scripts/termux/export_artifacts_to_windows.sh`
  (LEGACY/1 `--allowlist`, FOF_ARTIFACT_HANDOFF/2 `--profile`),
  `scripts/termux/fof_v2_ssh_adapter.py`, `scripts/ps7/receive_artifact_bundle.ps1`;
  docs `docs/ARTIFACT_TRANSFER.md`; profiili `config/artifact-transfer/a4-general-fi.json`;
  allowlist `config/artifact-transfer.allowlist`.
- Windows → Termux pull: `scripts/termux/fof_kb_pull.py` (FOF_KB_PULL/1);
  docs `docs/WINDOWS_TERMUX_PULL.md`; profiili `docs/transfer-profiles/kb-pull-documents-1.json`.
- Repositoryohjeet: `AGENTS.md`, `SKILLS.md`, `WORKFLOW.md`, `config/agent_policy.md`, `config/steering.md`.

## Outputs

- `Fear-of-Falling/docs/LOCAL_FILE_TRANSFER_RUNBOOK.md` — yhteinen käyttöpolku,
  kaksi suuntakohtaista komentopolkua, sijoitusspesifikaatio ja palautumisohje.

## Definition of Done (DoD)

- Runbook kattaa polun: valinta → preflight → preview → digest-hyväksyntä →
  yksi siirto → VERIFIED → erikseen valtuutettu sijoitus → lopullisten
  polkujen ja hashien raportti.
- Previewssä näkyy jokaiselle tiedostolle lähde, siirron suhteellinen polku ja
  lopullinen kohde; valinnat ovat täsmävalintoja.
- Sijoitus on erillinen valtuutettu vaihe; jos nykyiset työkalut eivät
  mahdollista turvallista sijoitusta, toteutustarve nimetään eikä sitä esitetä valmiina.
- Palautumisohje kattaa preflight-eston, katkoksen, puuttuvan VERIFIED-kuitin,
  epävarman kestävyyden, kohdetörmäyksen ja osittaisen sijoituksen.
- Komennot merkitty `[WINDOWS:POWERSHELL]` / `[TERMUX]`; paikalliset
  absoluuttiset polut ja runtime-arvot pidetään Gitin ulkopuolella.
- Synteettinen validointi vain itse tuotetuilla tiedostoilla; Termux-tarkistus
  delegoitu (NOT_RUN jos ei mahdollista).

## Log

- 2026-10-08 Owner valtuutti yhteisen runbookin, sijoitusvaiheen määrittelyn ja rajallisen validoinnin.
- 2026-10-08 Runbook luotu; sijoituksen toteutustarve nimetty (ei valmista työkalua); jätetty 03-review.

## Blockers

- **Sijoitustyökalu puuttuu**: nykyiset kanavat ovat staging-only eivätkä tuo
  tiedostoja repositoryyn. Turvallinen sijoitus (create-new, ALREADY_PRESENT,
  CONFLICT-stop, ei traversal/linkki/erikoistiedostoja) vaatii **erillisen
  toteutuksen**. Tämä kortti määrittelee vaatimuksen; se ei toteuta työkalua.

## Lifecycle notes

- Työ tehtiin eristetyssä worktreessä `docs/bidirectional-local-file-transfer-runbook`
  (base `origin/main` 4605520…). Ei commit/push/mergeä tässä vaiheessa.

## Validointi 2026-10-08

- **CLI-argumenttien validointi (read-only, ei siirtoa):** PASS
  - `fof_kb_pull.py --help`: toimet `preview/approve/serve/pull`; argumentit
    `--profile --source-root --batch-root --batch --batch-id
    --approved-content-digest --staging-root --run-id --synthetic-test`.
  - `fof_v2_ssh_adapter.py --help`: `--check`.
  - `export_artifacts_to_windows.sh`: `--allowlist` (default
    `config/artifact-transfer.allowlist`), `--profile`, `--execute`,
    `--smoke-test`, `--local-receiver`, `--approved-content-digest`.
  - `receive_artifact_bundle.ps1`: `-StagingDir -BundlePath -TransferId -MaxBundleBytes`.
  - Runbookin dokumentoidut komennot vastaavat skriptien todellisia argumentteja.
- **Sijoitusskenaariot (uusi kohde / identtinen / eri sisältö / vaarallinen polku /
  keskeytys): NOT_RUN** — sijoitus (staging → lopullinen repo-kansio) ei ole
  olemassa; ks. Blockers. Ei valheellista PASSia.
- **Siirtoverkkotestit: NOT_RUN** — tämä muutos on dokumentaatio; aiempia
  verkkotestejä ei toisteta ilman tämän muutoksen vaatimaa syytä.

## Sijoitustyökalun toteutuspaketti (2026-10-09)

- Runbookin §6 tarkennettu: erottaa **käytettävissä olevat siirtokomennot** ja
  **tulevan `PLACE/1`-työkalun**; antaa syötteet (molemmat varmennetut
  vastaanottorakenteet), LEGACY/1-rajauksen, CLI:n, `placement_digest`in,
  tiedostokohtaiset tilat, TOCTOU-suojauksen, kuittiskeeman ja synteettiset testit.
- Rajattu toteutuspaketti (design, ei koodia):
  `C:\FOF_KB_RUNTIME_20261006\evidence\PLACEMENT_TOOL_IMPLEMENTATION_PACKAGE.md`
  (peilikuva FOF-paikallisessa evidenssissä).
- Ehdotetut koodi-/testipolut: `scripts/termux/place_verified_bundle.py` ja
  `tests/test_place_verified_bundle.py` (portable stdlib, Windows + Termux).
- **Ei toteutusta** tässä vaiheessa (stop-ehto).

## Toteutus ja testit (2026-10-09)

- **Toteutettu työkalu:** `Fear-of-Falling/scripts/termux/place_verified_bundle.py`
  — `place preview|execute`; **tuetut vastaanottomuodot: `FOF_KB_PULL/1` ja
  `FOF_ARTIFACT_HANDOFF/2`** (LEGACY/1 → `UNSUPPORTED_RECEPTION_FORM`).
  Hyväksyntä `placement_digest` sitoo varmennetut lähdetavut + lähde–kohde-kartan
  + kohderepositoryn identiteetin (origin_url, head).
  Tilat: `CREATED` (O_EXCL, ei overwritea), `ALREADY_PRESENT`, `CONFLICT`
  (jättää ennalleen). TOCTOU: `_hold_dir` pitää esi-isät auki (Windows
  CreateFileW share-read + reparse-tarkastus; POSIX `dir_fd`+`O_NOFOLLOW`)
  kirjoituksen yli + avatun parentin identiteetin uudelleenvarmentus.
  Julkaisee `PLACE_RECEIPT/1`-kuittin repositoryjen ulkopuolelle; siirron
  `VERIFIED.json` pysyy muuttumattomana; ei automaattista retryä.
- **Testit:** `Fear-of-Falling/tests/test_place_verified_bundle.py` —
  **33 PASS + 3 SKIP (POSIX-only, Windowsilla)**, molemmat vastaanottomuodot: onnistuminen (v1+v2),
  identtinen kohde, konflikti, väärä digest, muuttunut lähde, lähde muuttui
  previewn jälkeen, vaarallinen polku, hard-deny-kohde, linkki/junction, puuttuva
  kuitti, ei-tuettu muoto, duplikaatti map/manifest, kohdetörmäys, keskeneräinen
  map, olemassa oleva kuitti, ylisuuri kohde→CONFLICT, payloadin exact-set,
  esi-isän vaihtuminen (`PARENT_CHANGED`, ei kuittia), keskeytys (osittainen tila,
  ei kuittia), kuitin julkaisuvirhe (ei kuittia), v2-sidonta karttaan.
- **Termux-validointi: NOT_RUN** (natiivi ajo vaatii erillisen Git-toimitusluvan;
  valmis rajattu toimitus valmistellaan).

## Korjaukset Termux-katselmoinnin jälkeen (2026-10-09)

Termux-agentti A ajoi natiivin validoinnin commitille `c5f0f56e…`. Tulos:
siirtokanava OK (inbound 40 PASS), mutta **sijoitusvaihe ei läpäissyt**: preview
päättyi `PLACE_REJECTED: LOCAL_FAILURE` (exit 1) ennen digestiä; hyväksyntä ja
`execute` jäivät BLOCKED/NOT_RUN. Katselmointi löysi lisäksi staattisia puutteita.
Korjattu tässä eristetyssä worktreessä (ei commit/push):

1. **Android-ankkuri (P1, todellinen este).** Lukija ja kirjoitushakemiston kävely
   avasivat `/-ankkurin` (`place_verified_bundle.py`, POSIX-haara) → Android
   `EACCES` (errno 13). Korjattu: POSIX-haara resolvoi **ensimmäisen käyttäjän
   hallitseman esi-isän** (sama katselmoitu ankkuriratkaisu kuin `fof_kb_pull.py`,
   jota ei muutettu) eikä avaa `/`, `/data` tai `/data/data`. Linkki-, traversal-,
   tyyppi- ja polunvaihtosuojaukset sekä Windows-haara säilyvät (`ROOT_CHANGED`-
   uudelleenvarmennus avatulle ankkurille).
2. **Vastaanoton hyväksyntäsidonta.** `content_digest` lasketaan nyt **uudelleen
   manifestista** kunkin protokollan omilla kanonisointisäännöillä ja verrataan
   manifestiin, `VERIFIED.json`iin ja hyväksyntään. FOF_KB_PULL/1: `batch_id`-
   korrelaatio manifestin ja kuitin välillä (`BATCH_ID_CORRELATION`); v2: todelliset
   ajokorrelaatiokentät (`content_digest` + `run_correlation_digest`,
   `RUN_CORRELATION`). Ei keksittyä yhteistä manifestimuotoa. `placement_digest`
   sitoo nyt myös `reception_protocol` + `reception_correlation`.
3. **Sijoituskuitti.** `--receipt`-polun **kohderepositorion ulkopuolisuus**
   tarkastetaan (`RECEIPT_INSIDE_TARGET`) ja esi-isien linkit hylätään. Kuitti
   julkaistaan **atomisesti ilman korvaamista**: täysin kirjoitettu ja `fsync`-
   varmennettu väliaikaistiedosto linkitetään lopulliseen polkuun (`os.link`,
   atominen, `EEXIST` → `RECEIPT_EXISTS`); kilpailutilanteessa syntyvä kuitti
   säilyy ennallaan. Jos kovalinkki ei ole tuettu, julkaisu keskeytyy
   turvallisesti (`RECEIPT_PUBLISH_UNSUPPORTED`) eikä osittaista kuittia synny.
   Pelkkä exists-tarkastus ennen `os.rename`ia poistettu. Siirron `VERIFIED.json`ia
   ei muuteta.
4. **Runbook.** §5 erottaa **siirto-previewn** ja **sijoitus-previewn**; todetaan
   ettei siirto-preview näytä lopullista kohdetta (kohde tulee sijoituskartasta ja
   sijoitus-previewstä). §6.3:n pseudokomennot korvattu **toteutetun Python-skriptin
   todellisilla kutsuilla** (`preview`/`execute`).

- **Testit:** `Fear-of-Falling/tests/test_place_verified_bundle.py` —
  **33 PASS + 3 SKIP (POSIX-only, Windowsilla)**. Uudet kohdennetut testit:
  manipuloitu manifesti → uudelleenlaskettu digest (`MANIFEST_DIGEST`); väärä
  BatchId (`BATCH_ID_CORRELATION`); väärä ajokorrelaatio (`RUN_CORRELATION`);
  kuitti kohderepositorion sisällä (`RECEIPT_INSIDE_TARGET`); tarkastuksen jälkeen
  syntyvä kuitti säilyy ennallaan (`RECEIPT_EXISTS`); kuitti linkin kautta;
  POSIX-ankkuri ei ole `/` ja lukija ei avaa juurta (POSIX-only, ajetaan Termuxilla).
- **Gates:** `tools/run-gates.ps1 --mode pre-push --smoke` → exit 0.
- **Termux-uudelleenvalidointi: NOT_RUN** — vaatii korjatun Git-toimituksen; A
  varmentaa uuden exact commitin ja ajaa sijoitustestit + synteettisen CLI-polun.
- **Ei** commit/push/mergeä, ei riippuvuusasennuksia, ei tuotantoaineistoa, ei
  ACL-muutoksia eikä muutoksia nykyisiin siirtoskripteihin.

## Links

- `Fear-of-Falling/docs/LOCAL_FILE_TRANSFER_RUNBOOK.md`
- `Fear-of-Falling/scripts/termux/place_verified_bundle.py`
- `Fear-of-Falling/tests/test_place_verified_bundle.py`
- `Fear-of-Falling/docs/ARTIFACT_TRANSFER.md` (outbound sopimus)
- `Fear-of-Falling/docs/WINDOWS_TERMUX_PULL.md` (pull sopimus)
- `PLACEMENT_TOOL_IMPLEMENTATION_PACKAGE.md` (repository-external evidence)


## Rajattu natiivi receipt-publication-korjaus

- 2026-10-09T18:12:15.317736+00:00 Owner valtuutti local-only-korjauksen
  exact base e0a57d7ad5b3b0bbd8c911da7a6ae170858fcc71 pohjalta; uusi eristetty
  fix/placement-receipt-atomic-20261009. Scope vain placement-scripti, sen testit,
  runbook ja tämä kortti. Ei siirtoskriptien muutoksia, commit/push/mergeä tai verkkoa.
- Natiivin miniature-proben tulos PASS: os.link puuttuu; libc.renameat2 +
  RENAME_NOREPLACE toimii. Kilpailija EEXIST/errno17 säilyi tavuntarkasti;
  uusi kuitti julkaistui atomisesti. Ei link-fallbackia tai final-write-fallbackia.
- POSIX receipt-parent hyväksytään vain suoraan vakaana yksityisenä ensimmäisenä
  user-controlled ankkurina, jonka koko edeltävä system-ketju on käyttäjälle
  non-owned/non-writable. Tavalliset siirrettävät HOME-alihakemistot hylätään
  RECEIPT_PARENT_MOVABLE ennen payload-kirjoituksia. Tämä on turvallisuus-
  capability-rajaus, ei väite että pidetty fd estäisi POSIX-renamen.
- Sama pidetty directory-fd kattaa primitive-proben, payloadvaiheen, receipt-
  tempin luonnin, täydellisen write/fsync/close:n ja native no-replace -julkaisun.
  Private uid/mode/inode/chain ja ulkopuolisuus varmennetaan uudelleen.
  Primitive unavailable tuottaa RECEIPT_PUBLISH_UNSUPPORTED ennen payloadia.
- Kohdennetut regressiot: kilpailijan säilyminen, movable-parent ennen payloadia,
  oikea ancestor-relocation kohderepoon -> ei kuittia/kohdekirjoituksia, complete
  stream closed-beforepublish, native publisherror -> ei finalsuccessreceipt,
  actual synthetic chmod -> private-reject, postpublish directory-fsync failure
  -> RECEIPT_VISIBLE_DURABILITY_UNCONFIRMED ja näkyvä täydellinen kuitti säilyy.
- Syscall-boundary rename-into-descendant -koe ei yksin todista ACL-rajaa
  (EINVAL voi tulla containment-kiellosta). Vakaan ankkurin luottamus perustuu
  erillisiin koko edeltävän ketjun uid/W_OK-tarkastuksiin; root/system luotetaan.
- Koko natiivi suite43 PASS,0 FAIL,0 SKIP, ResourceWarning=error. Molemmat
  vastaanottomuodot uusilla retained synthetic CLI-kohteilla: preview0,execute0,
  PLACED ja tavut/hashit oikein. Molemmat vanhat siirtoVERIFIED-tavut ennallaan.
- Aiemmat failure-logit, osittaiset placementit ja CLI-fixtuurit säilytetty;
  uusia successful receipt/probe/temp-artefakteja ei poisteta tai uudelleenkäytetä.
- Windows-haaran ancestor share-read/reparse + os.link -takeet säilyvät, mutta
  nykykorjauksen native Windows-validointi NOT_RUN ja tarvitaan erikseen ennen
  hyväksyttyä toimitusta. Windows-agentille valmistellaan tarkka validointihandoff.
- Riippumaton nykykorjauksen read-only-review PASS, ei avoimia löydöksiä.
  Task pysyy03-review/PARTIAL;
  tämä ei ole ihmisen valmistumishyväksyntä. Ei install/realdata/Gitdeliveryä.
- K18/QC NOT APPLICABLE — sijoituksen kuittijulkaisu ei muuta analyysiputkea.

## Windows-korjaus commitin 30286b0 pohjalta (2026-10-09)

Windows-validointi commitille `30286b094fc23d2c24ae397288dc5b5d5ba1694f`:
**FAIL** — `Ran 43: 26 ok, 2 FAIL, 7 ERROR, 8 SKIP, exit 1`. Jokainen `execute`
kaatui `RECEIPT_PUBLISH_UNSUPPORTED`; CI: `lint` (Prettier) FAIL ja `tests`
FAIL (`RECEIPT_PARENT_NOT_PRIVATE`, Linux-runnerilla).

1. **Windowsin kuittijulkaisu.** Juurisyy: `_hold_dir` piti receipt-hakemistoa
   auki `dwShareMode = FILE_SHARE_READ (1)`, jolloin `CreateHardLinkW` samassa
   hakemistossa epäonnistui `WinError 32`illlä. Natiivi mini-probe: `os.link`
   OK ilman pidettyä kahvaa; share=1 → link FAIL/rename+rmdir BLOCKED;
   **share=3 (READ|WRITE) → link OK, rename/rmdir BLOCKED**; share=5/7 → rename
   sallittu. Korjaus: `_hold_dir` Windows-kahva share `1 → 3` (ei DELETE).
   Suojaus (esi-isien rename/delete/replacement-esto) säilyy — varmennettu
   natiiveilla kokeilla (share=3: rename/rmdir BLOCKED) ja testistöllä.
   Täysi write/fsync/close ennen julkaisua ja no-replace (EEXIST → RECEIPT_EXISTS)
   säilyvät; ei epäatomista fallbackia.
2. **CI-fixture (RECEIPT_PARENT_NOT_PRIVATE) — este raportoitu.** Testin
   `receipt()` sijoittaa synteettisen kuitin `p._posix_anchor(self.base)[0]`:iin.
   CI:ssä tuo ankkuri on ylin käyttäjän omistama hakemisto (HOME), jonka moodi on
   0755, ja tuotantosääntö vaatii `directory == anchor` JA moodin `0700`.
   `_posix_anchor` palauttaa aina ylimmän käyttäjän hallitseman esi-isän, joten
   minkä tahansa alihakemiston ankkuri on edelleen HOME; 0700-ankkuria ei voi
   järjestää ilman käyttäjän hakemistojen chmodia (kielletty) tai tuotantotarkastuksen
   löysentämistä (kielletty). Tarkka este — ei korjattu tässä.
3. **Runbookin Prettier.** Korjattu repositoryn olemassa olevalla työkalulla
   (paikallinen välimuisti-Prettier 3.8.1; CI haluaa ^3.9.8). Taulukot/tyhjät
   rivit normalisoitu; yksi inline-code-välilyöntejä rikkova lause kirjoitettu
   uudelleen. `prettier --check` PASS.

- **Uudelleenvalidointi (Windows):** `Ran 43, 35 ok + 8 SKIP, 0 FAIL/ERROR,
  exit 0`. Molemmat synteettiset CLI-polut: preview exit 0 → execute exit 0 →
  `PLACED`, receipt kirjoitettu, payload paikallaan, alkuperäinen `VERIFIED`
  muuttumaton. Gates `run-gates.ps1 --mode pre-push --smoke` exit 0.
- **Ei** commit/push/mergeä; PR #197 draft. Termux-haara säilyy. Ei
  siirtoskripti-/profiili-/CSV-/ACL-muutoksia. Avoin: CI-fixture (kohta 2) ja
  Windows-haaran esi-isän-vaihto varmistetaan pidetyin kahvoin (share=3, ei DELETE).

## Testinäyttö eriteltynä (alkuperäiset lokit)

Kolme erillistä Windows-ajoa — lukuja **ei** yhdistetä:

- **FAIL (43 testiä; share=1; ilman uutta Windows-testiä):** `Ran 43: 26 ok,
  2 FAIL, 7 ERROR, 8 SKIP, exit 1`. Jokainen `execute` → `RECEIPT_PUBLISH_UNSUPPORTED`.
- **PASS A (43 testiä; share=3; ilman uutta Windows-testiä):** `Ran 43,
  35 ok + 8 SKIP, 0 FAIL/ERROR, exit 0` (Windows-uudelleenvalidointi).
- **PASS B (44 testiä; share=3; uuden Windows-testin kanssa):** `Ran 44,
  36 ok + 8 SKIP, 0 FAIL/ERROR, exit 0` (lopullinen Windows-validointi).

43 testin ajo tehtiin ennen `test_held_dir_blocks_relocation_and_deletion`-testin
lisäämistä; 44 testin ajo sen jälkeen. **Toteutuskoodi ei muuttunut näiden välillä** —
vain uusi testi lisättiin (ok-luku 35 → 36, SKIP pysyy 8). Näitä kahta ajoa ei
saa raportoida yhtenä lukuna.

## CI-fixturen korjaus (2026-10-10) — Owner-valtuutettu rajattu CI-testijärjestely

- 2026-10-10 Owner valtuutti rajatun CI-testijärjestelyn muutoksen saman
  korjauspaketin viimeistelyyn. ALLOWED_PATHS: nykyiset neljä tiedostoa +
  `.github/workflows/python-ci.yml`. **Ei** muutoksia runnerin nykyisen HOMEn
  oikeuksiin, **ei** tuotannon luottamusvaatimusten löysennystä, **ei** skippiä.
- Juurisyy säilyi: `_posix_anchor` valitsee ylimmän käyttäjän hallitseman
  esi-isän; `_receipt_context`/`_receipt_revalidate` vaativat `directory == anchor`
  JA moodin `0700`. CI:n `HOME=/home/runner` on 0755 → `RECEIPT_PARENT_NOT_PRIVATE`.
  Pelkkä `HOME`-muuttujan vaihto ei siirrä ankkuria (ankkuri lasketaan
  tiedostojärjestelmän omistus-/kirjoitusoikeuksista, ei ympäristömuuttujasta).
- **Korjaus:** uusi yksityinen synteettinen HOME `/home/foftest` (root-owned,
  ei-kirjoitettavan `/home`-esi-isän alla; runner omistaa sen; mode 0700).
  Sijoitustestit ajetaan omassa vaiheessa `HOME=/home/foftest`; **muut testit
  ajetaan ennallaan** (sijoitustestit `--ignore`-parametrilla pääajosta, jolloin
  runnerin olemassa olevaa HOMEa ei muuteta).
- Preflight varmistaa omistajan, moodin 0700 ja toteutuksen valitseman ankkurin
  (`_posix_anchor(HOME) == HOME`). Molemmat vaiheet tuottavat oman JUnit-XML:n
  (`junit.xml`, `junit-placement.xml`) ja niiden exit-koodit käsitellään;
  sijoitusvaihe on `if: always()` eikä jätä testistöä ajamatta.
- **Synteettinen Linux-validointi (Docker `fof-r-analysis`, Python 3.12.3,
  `--network none`, repo read-only):**
  - preflight-ankkuritarkistus `HOME=/home/foftest` →
    `private POSIX anchor OK: /home/foftest`, exit 0;
  - negatiivinen kontrolli 0755-kodilla → `RECEIPT_PARENT_NOT_PRIVATE`, FAILED;
  - sama testi 0700-kodilla → OK;
  - **koko sijoitussuite `HOME=/home/foftest`: `Ran 44 tests`, OK (skipped=1),
    exit 0** (Windows-only-testi skippaa Linuxilla).
  - huom: validointi ajettiin `unittest`-ajurilla (paikallisessa kuvassa ei ole
    pytestia); CI käyttää `pytest`iä ja JUnit-XML:ää — testitapaukset ovat samat.
- **Ei** commit/push/mergeä; ei asennuksia; ei tuotantoaineistoa; ei nykyisten
  paikallisten hakemistojen oikeusmuutoksia; ei siivousta.
- **Avoin / rajoitus:** exact commitin CI-varmennus jää toimitusta **seuraavaksi**
  vaiheeksi (paikallinen Prettier 3.8.1 ei korvaa lukitun CI-version 3.9.9
  formatter-tulosta; `markdownlint-cli2` 0.23.3 ei ole paikallisesti). Windowsin
  läpäistyjä testejä ei toistettu (toteutuskoodi ei muuttunut). Termux-regressio
  pyydetään A:lta muuttuneelle versiolle ennen squash-merge-päätöstä.
