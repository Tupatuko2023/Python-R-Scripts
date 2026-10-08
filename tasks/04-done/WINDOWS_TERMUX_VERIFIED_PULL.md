# WINDOWS_TERMUX_VERIFIED_PULL

## Context

Owner valtuutti 2026-10-05 Windows → Termux -noutokanavan toteutuksen.
Orkestroija määräsi metadata-only-tehtävän luomisen työjonoon.

## Inputs

- Nykyinen outbound-koodi ja FOF_ARTIFACT_HANDOFF/2-sopimus.
- Ownerin rajattu XML-toimeksianto ja kaksi historiallista raporttia.

## Outputs

- Erillinen versioitu, oletusarvoisesti suljettu KB-noutosopimus.
- Git-kanavassa toimitettava portable Python-toteutus, testit ja käyttöohje.

## Definition of Done (DoD)

- Digest-hyväksyntä, snapshot, turvalliset polut ja staging-only-vastaanotto.
- Exact-set-, koko- ja SHA-256-tarkistus sekä atominen VERIFIED-kuitti.
- Synteettiset positiiviset ja negatiiviset testit; outbound-regressiot.
- Todellinen SSH-smoke erikseen tai täsmällisesti kirjattu suorittamattomaksi.
- Ei tuotantodataa, uusia runtimeja, avaimia, pushia, mergeä tai importia.

## Log

- 2026-10-05T14:50:00Z Ready-tehtävä luotu orkestroijan käskystä.

## Blockers

- Windowsin Python-runtime ja laitteiden SSH-yhteys eivät ole tässä ympäristössä varmennettuja.
- Yksityisen FOF-repon Git-clone ei ole autentikoitu; connectorin read-only-luku toimii.

## Links

- Fear-of-Falling/docs/WINDOWS_TERMUX_PULL.md

## Toteutuksen evidenssi

- Kokonaisuus PARTIAL; katselmoitava paikallinen diff valmis.
- Branch chore/windows-termux-verified-pull, base a62957e9e77d3eedc33c1d18395be0bc26c017dc.
- FOF-Dissertation-Projectiin ei muutoksia; private Git authentication unavailable.
- Uusi FOF_KB_PULL/1-sopimus, alkuperäistä outboundia ei muutettu.
- Inbound-testit 29 PASS, synthetics/local Python processes only.
- Outbound test_artifact_transfer.py ja test_v2_ssh_adapter.py: NOT RUN,
  import BLOCKED (jsonschema missing). Ei runtime-asennuksia.
- Primary runtime Python tarkastettu: jsonschema puuttuu myös siitä.
- Windows Python / reparse locking / PS binary bridge / real SSH: NOT RUN.
- run-gates --help: CLI smoke PASS, ei policy-validointitodiste.
  Täysi gate ilman project/smoke-valintaa pysähtyi parametrigatessa;
  renv-read SKIP (Rscript unavailable).
- K18/QC: NOT APPLICABLE, synteettinen tiedostokuljetus ei muuta tieteellistä putkea.
- Ei commit/push/merge/import/poisto/retry/autosync/toimitettua paluukuittia.
- Task jää 02-in-progress/PARTIAL, koska regressio-DoD on blocked.
  Katselmointi ei tarkoita taskin valmistumishyväksyntää.

## Muutetut tiedostot

- Fear-of-Falling/scripts/termux/fof_kb_pull.py
- Fear-of-Falling/tests/test_kb_pull.py
- Fear-of-Falling/docs/transfer-profiles/kb-pull-documents-1.json
- Fear-of-Falling/docs/WINDOWS_TERMUX_PULL.md
- tasks/02-in-progress/WINDOWS_TERMUX_VERIFIED_PULL.md

## Seuraava konkreettinen vaihe

Katselmoi diff. Aja regressiot olemassaolevassa ympäristössä, jossa jsonschema
ja receiver-testien PowerShell riippuvuudet ovat valmiina. Toimita hyväksytty
koodi Git-kanavassa Windowsiin ja Termuxiin ilman tätä tehtävää varten tehtyä
SSH-koodipayloadia. Varmenna Windows Python sekä nykyinen tunnettu SSH-alias.
Aja käyttöohjeen synteettinen verkkotesti foreground-Termuxissa ja kirjaa
korreloitu VERIFIED-kuitti. Tuotantoprofiili pysyy suljettuna.

- 2026-10-05T14:53:08.118659+00:00 Paikallinen toteutus ja synteettiset testit viimeistelty, DoD-esteet kirjattu.

## Jatkokatselmointi

- Riippumattoman reviewn kaksi medium-havaintoa korjattu: Windows HANDLE/CRT
  ownership failure sekä receipt post-publication fsync uncertainty.
- Windows lifecycle mock-testit Linuxissa, eivät todellinen Windows PASS.
- Synteettiset inbound-testit 34 PASS; kaikki aiemmat 29 mukana.
- SSH-runtime-env, config ja known_hosts puuttuvat tästä suoritusympäristöstä.
  Ei Windows-probea arvatuilla asetuksilla; verkkotesti NOT RUN.
- CSV-metadata täsmäpolut kirjattu käyttöohjeeseen filenames-only-näytöllä;
  koko QFOT2 KB unverified, CSV hard deny säilyy.
- Git-toimituksen tarkastettava exact path map käyttöohjeessa. Ei toimitustoimia.

## Toimitushashit (ei tämän taskin omaa hashia)

| Polku | SHA-256 |
| --- | --- |
| Fear-of-Falling/scripts/termux/fof_kb_pull.py | d0de028036d73640fd3b0e6d1c606fdadef2a13251fd3880589b85de4ba0e6d1 |
| Fear-of-Falling/tests/test_kb_pull.py | 3827e8fa591160a1168ba3ef727123c56361ac19ff394c79a8aa78551a3b390d |
| Fear-of-Falling/docs/transfer-profiles/kb-pull-documents-1.json | 04ab55624a0899e7a9e4679dce14bc1966d19a0f7c065b782ebb957e856e0fef |
| Fear-of-Falling/docs/WINDOWS_TERMUX_PULL.md | 249e325c80d8549b4b4937865554f57ec8aab32ab0b19c0ea16038fddfbae7eb |

- 2026-10-05T16:00:55.971209+00:00 Jatkokatselmoinnin korjaukset ja 34 testin näyttö kirjattu.

## Windows-pään validointi (2026-10-06)

Korjattu toimituspaketti WINDOWS_TERMUX_CORRECTED_DELIVERY_20261006.zip
(SHA-256 2A8BE6B49EE479B803DFCB0CC46CED37446014A29DF06FC162E71B0140F26F48)
purettiin repositoryjen ulkopuolelle ja tarkastettiin MANIFEST.jsonia vasten:
kaikki viisi tiedostoa täsmäsivät (MANIFEST_VERIFY PASS 5/5). Korjatut piirteet
todettu artefakteista: Windows HANDLE/CRT-omistussiirron virhepolku,
LOCAL_VERIFIED_DURABILITY_UNCONFIRMED ja 34 inbound-testiä.

Toimitus rakennettiin eristettyyn worktreehen nykyisen origin/mainin päälle.
Toimituksen base HEAD: 9e65e2cf6f58463c32fb6de335d6682ae4a7afc3.

Windows-validointi (Miniconda Python 3.12.4, jsonschema 4.23.0, git 2.51.1,
pwsh 7, sshd Running):
- Inbound test_kb_pull.py Windows-alustalla: 12/34 läpäisi. Loput 22 ovat
  alustasidonnaisia, ei regressioita: 17 POSIX-receiveriä
  (RECEIVER_REQUIRES_POSIX), 2 symlink-oikeutta (WinError 1314), 2
  Windows-API-mockia (PosixPath, tarkoitettu Linuxille), 1 POSIX-
  poikkeustyyppi. Koko 34-testistö ajetaan Termuxissa.
- Erillinen aito Windows-harness: 10/10 PASS (locked_read tavutarkka;
  write/delete/replace estetty luvun aikana; reparse/junction hylätty;
  PowerShell-binäärisilta 0-255 byte-exact; preview/approve/serve;
  väärä digest hylätty approve- ja serve-vaiheessa; CLI smoke).
- Windows-tuotannon synteettinen content_digest:
  e15e18a8287dabe9dcd2cb910aa7bdad308b6a411ee93d63e17cc7ded667fac7.
- Outbound-testit (test_artifact_transfer.py, test_v2_ssh_adapter.py) ovat
  tässä basessa; Windows-ajo estyi puuttuvasta WSL /bin/bash-sillasta
  (execvpe failed), ei jsonschema eikä koodimuutos. Ajetaan Termuxissa.
- Todellinen SSH-smoke: NOT RUN (koodia ei ole toimitettu molempiin päihin).
- Tuotantoprofiili kb-pull-documents-1 pysyy enabled=false, files=[].

Tila: edelleen PARTIAL, kunnes Termux-regressiot ja todellinen SSH-smoke on
osoitettu. Tämä paikallinen validointi ei väitä päästä päähän varmennettua
kanavaa.


## Android-polkuluvun jatkokorjaus

- 2026-10-06T17:20:56.225785+00:00 Jatketaan samaa 02-in-progress-tehtävää
  eristetyssä chore/termux-private-root-read-20261006-haarassa; base exact commit
  8721c5dd001d7ef8e0c245a625394eda1727392c. Base-taskin SHA-256 on
  dfb68cb69b08f37685ae0fc8806178aecce1ea5b42b605ea934b19987ec2b453.
- Säilytettyjen lokien tarkka syscall: os.open('/', O_RDONLY|O_DIRECTORY|O_NOFOLLOW),
  PermissionError errno 13 EACCES. Alkuperäinen 34-testin ajo: 9 PASS, 25 ERROR.
- Toteutettiin turvallinen järjestelmäesi-isien alle ankkuroitu descriptor-kävely
  käyttäjän hallittavien esi-isien läpi HOMEen ja rajattuun kohteeseen. Ei /-openia,
  plain-open-fallbackia tai turvatarkastusten poistoa. Windows-haara säilyy.
- Riippumaton koodikatselmointi havaitsi HOME-esi-isän TOCTOU-riskin; se korjattiin
  ennen valmistumista ja lisättiin esi-isän linkkivaihdon regressio. Katselmoinnin
  lopputulos: ei avoimia löydöksiä (koskee kahta korjauksen kooditiedostoa).
- Natiivi Termux inbound v4: 40 PASS, 0 FAIL, 0 SKIP, ResourceWarning=error.
  Aiemmat fixture-failure ja effective_ids-API:n failure-ajot säilytetty.
- Preflight PASS. Repository run-gates --mode pre-push --smoke exit 0;
  staged-syntax gates eivät yksin testaa unstaged-korjausta.
- Outbound BLOCKED: jsonschema puuttuu dokumentoidusta natiivista Pythonista;
  valmista checkout-venviä ei ole; dokumentoitu Ubuntu-käynnistin ei käynnisty
  tässä komentoympäristössä. Ei asennuksia tai PRoot-korjauksia.
- Valmisteltiin manuaalinen synteettinen SSH-testiohjain: odotetut nonzero-exitit,
  RunId_POS, törmäyksen kaikki tiedostohashit ennen/jälkeen ja kesken vastaanoton
  havaittu barrier + tuore SSH-live-poll juuri ennen worker-self-SIGINTiä,
  wire-tavumääränäyttö, atomiset markerit ja finally-cleanup. PASS vaatii
  säilyneen UNVERIFIED/partial wire -näytön sekä SSH-prosessin pysäytysnäytön.
  CLI help PASS myös python -O:lla; verkkotestit NOT_RUN. Ohjaimen riippumaton
  read-only-koodikatselmointi PASS, ei avoimia löydöksiä; ei verkkoajon näyttöä.
- SSH-smoke BLOCKED ennen hyväksyttyä Git-toimitusta ja saman version varmentamista
  molemmissa päissä. Uutta previewta ei pyydetty. LOCAL VERIFIED NOT_RUN,
  paluukuitti NOT_DELIVERED. Tuotantoprofiili enabled=false/files=[] ennallaan.
- Ei commitia, pushia, mergeä, SSH-koodipayloadia, CSV-laajennusta tai importia.
  Task jää PARTIAL/02-in-progress, DoD ei täyty ennen regressioita/verkkonäyttöä.


## Rajattu katkostestin buffering-korjaus

- 2026-10-07T16:21:23.771842+00:00 Owner valtuutti harness-only-korjauksen,
  synteettisen regression ja riippumattoman katselmoinnin. Ei uusia commit/push-
  tai verkkotestivaltuuksia. Uusi eristetty branch
  chore/kb-interrupt-buffering-20261007, base830040ad42d9c733ab3ffe8cb0a9a3ccb1128efd.
- Tuotannon fof_kb_pull.py muuttumaton (SHA2567354b6e099da3bc0d5e04b8f1b64204ab1d4fc633b6dd75574a2c34062c30bdc).
- Testiharness flushaa todellisen vastaanottajan wire-streamin ennen havaintoa;
  wirecounter==tiedostokoko ja approved manifestista johdettu osittainen payload
  vaaditaan. flush_performed=true, durability=NOT_PROVEN. Ei arkiston purkua.
- Kohdennetut natiivin Termuxin synteettiset testit4 PASS,0 FAIL,0 SKIP.
  Bufferoinnin todellinen mismatch ja localprocess-worker-integraatio mukana;
  flush-failure ja väärän manifestin digest hylätään. ResourceWarning=error.
- Muuttumaton inbound40 PASS,0 FAIL,0 SKIP. Aiemmat paikallisten producer-
  fixtuurien failure-logit säilytetty. Gates exit0; staged syntax gate ei yksin
  testaa unstaged-korjausta. K18/QC NOT APPLICABLE (testiharness-only).
- Riippumaton read-only-katselmointi PASS, ei avoimia löydöksiä.
  Verkkotesti NOT_RUN tämän korjauksen aikana.
  Outbound BLOCKED ennallaan; ei asennuksia tai ympäristökorjauksia.
- Vanha katkosnäyttö pysyy NOT_DEMONSTRATED. Aiemman positiivisen ajon viisi
  hashia tarkastetaan ennen/jälkeen; ei aiempien ajojen muutoksia tai retryä.
- Tulevan testin erikseen hyväksytty Windows-erä ja source provenance830040ad
  säilyvät. Ajokohtainen BatchId ja tarkastettu Digest annetaan paikallisessa
  handoffissa, eikä niitä tallenneta repositoryyn. Uusi harness commit ilmoitetaan
  erikseen vasta hyväksytyn Git-toimituksen jälkeen.
- Kokonaisuus PARTIAL/02-in-progress. Ei commit/push/merge/import/delete
  tai tuotannon avaamista tämän työn perusteella.

## Katselmointi 2026-10-07 (Windows-agentti)

Harness-versio vs. runtime-versio:
- PR-haaran head 0a8e5990c3bf57bb9a9d399a33e56b1b09737060 ("test: flush KB
  interruption wire before observation") = harness-commit. Se lisää testimoduulin
  (CI-korjauksessa nimetty uudelleen tests/test_kb_pull_ssh_smoke_harness.py:ksi) ja
  muuttaa scripts/termux/test_kb_pull_ssh_smoke.py, WINDOWS_TERMUX_PULL.md ja
  tämän kortin; se ei muuta tuotannon fof_kb_pull.py:tä.
- Testattu Windows-runtime ja batch-provenance = 830040ad42d9c733ab3ffe8cb0a9a3ccb1128efd
  (harness-commitin parent), fof_kb_pull.py SHA256
  7354b6e099da3bc0d5e04b8f1b64204ab1d4fc633b6dd75574a2c34062c30bdc.
- Windows-validointi ajettiin runtime-commitilla 830040ad; harness-commit 0a8e5990 ei
  muuta Windows-lukitushaaraa eikä validoitua runtime-tavua.

Windows-näyttö (10 testiä): tiedostonluku tavutarkasti, kahvan vapautus,
write/delete/replace-esto luvun aikana, reparse/junction-hylkäys,
PowerShell-binäärisilta 0-255 byte-exact (102400 B), preview->approve->serve,
väärän digestin hylkäys (approve+serve), CLI smoke. Harness-ajo 10/10 PASS;
evidenssi docs/guides/windows-termux/windows-validation-830040ad/.

Termux (A:n koneellinen tulosmanifesti saatu ja tarkastettu):
- manifest_kind WINDOWS_TERMUX_VERIFIED_PULL_TEST_RESULTS; harness_commit 0a8e5990,
  harness_sha256 2ab7a47acd04ce4c4117e5e5ec43b48c779f6279df7b8cad4c39cca71ca4e97f
  (tarkistettu repo-tiedostoa vasten).
- paikalliset testit: inbound 40 PASS / 0 FAIL / 0 SKIP; harness 4 PASS / 0 FAIL / 0 SKIP.
- 4 SSH-testiä PASS: positiivinen; väärä digest (exit 1, ei VERIFIED); run_id-törmäys
  (exit 1, aiemmat viisi hashia muuttumattomat); katkos (client_exit -2, ssh_exit -9,
  proven_in_progress=true, flush_performed=true, durability=NOT_PROVEN, ei VERIFIED,
  UNVERIFIED säilytetty, automatic_retry=false, aiemmat hashit muuttumattomat).
- local_VERIFIED=PASS; return_receipt_status=NOT_DELIVERED; outbound_regressions=BLOCKED;
  foreground_visibility=NOT_OBSERVABLE; new_tests_run=false.
- A:n manifestin VERIFIED-kuitti-tavut (343 B, sha256 8abf2f0b...) tarkistettu.
- Ajokohtaiset runtime-arvot (run_id, BatchId, content_digest, aikaleimat) ja paikalliset
  polut säilytetään Gitin ulkopuolella (paikallinen evidenssi).

Avoimet regressiot ja validoinnin rajat:
- CI python-ci (tests) FAIL PR-headilla 0a8e5990: pytest "import file mismatch"
  kahdesta samannimisestä moduulista
  (scripts/termux/test_kb_pull_ssh_smoke.py ja tests/test_kb_pull_ssh_smoke.py).
  Korjaus valmisteltu CI-korjauksessa: tests-tiedosto nimetty uudelleen
  tests/test_kb_pull_ssh_smoke_harness.py:ksi. CI varmistaa vasta pushin jälkeen.
- CI lint (Prettier) FAIL: Fear-of-Falling/docs/WINDOWS_TERMUX_PULL.md.
  Korjaus valmisteltu CI-korjauksessa (Prettier-muotoilu). CI varmistaa pushin jälkeen.
- Outbound-regressiot (test_artifact_transfer.py, test_v2_ssh_adapter.py) eivät ole
  ajettavissa Windowsilla: sulautettu Python vaatii POSIXin (os.O_DIRECTORY,
  symlinkit). Windows Miniconda 3.12.4 ei tue; WSL-relay ei toimi; Git bash tarjoaa
  kuoren mutta ei POSIX-Pythonia. Sopiva ympäristö = CI ubuntu+Python 3.11
  (pip install --group ./Fear-of-Falling/pyproject.toml:dev), joka estyy yllä
  olevasta keräilyvirheestä. Paikallinen Windows-ajo: 24/48 ok (POSIX-riippuvat
  eivät). Ei valheellista PASSia. Outbound BLOCKED ennallaan.

VERIFIED vs. paluukuitti:
- Paikallinen VERIFIED = varmennettu onnistuneessa vastaanotossa (mahdollinen vain
  POSIX-vastaanottimella). Paluukuitti Windowsille = NOT_DELIVERED (kanava ei
  toimita paluukuittia). Raportin kopiointi ei ole protokollan paluukuitti.

Tila: PARTIAL / 02-in-progress. Avoimet hyväksymiskriteerit:
(1) CI:n keräilyvirhe -> korjaus valmisteltu (rename); odottaa CI-varmennusta;
(2) Prettier-muotoilu -> korjaus valmisteltu; odottaa CI-varmennusta;
(3) aja outbound-regressiot vihreällä CI:llä tai POSIX-ympäristössä;
(4) A:n verkkotestien manifesti + hashit -> saatu ja tarkastettu; paluukuitti yhä
    NOT_DELIVERED (protokollan mukaan).
Ei uusia payload-siirtoja, runtime-päivityksiä, mergeä, pushia tai siivousta.
Tuotantoprofiili enabled=false. PR #194 pysyy draftina.

## CI-korjaus 2026-10-07 (Windows-agentti, paikallinen valmistelu)

- Testimoduulin törmäys poistettu nimeämällä tests/test_kb_pull_ssh_smoke.py
  uudelleen tests/test_kb_pull_ssh_smoke_harness.py:ksi (R100, sisältö muuttumaton,
  4 testiä säilytetty). Harnessin nimi scripts/termux/test_kb_pull_ssh_smoke.py
  säilytetty; ainoa viittaus siihen (moduulin lataus) säilyy ennallaan. Ei
  pytest-excludeja eikä testien ohitusta.
- WINDOWS_TERMUX_PULL.md muotoiltu repositoryn olemassa olevalla Prettierillä
  (npx-cache 3.8.1; lukko 3.9.6). Ei asennuksia. Muutokset: upotetun JSON-lohkon
  jäsennys, taulukon sarakekohdistus, ylimääräiset tyhjät rivit.
- Keräys varmennettu paikallisesti (112 testiä, 0 virhettä); 4 harness-testistä 2
  ajettavissa Windowsilla, 2 vaatii POSIXin. CI varmistaa 4/4 vasta pushin jälkeen.
- Runtime fof_kb_pull.py, tuotantoprofiili kb-pull-documents-1.json ja harness
  test_kb_pull_ssh_smoke.py eivät muutu.
- Paikalliset absoluuttiset polut ja ajokohtaiset runtime-arvot (BatchId/Digest,
  Windows-juuri) pidetään Gitin ulkopuolella.
- Tämä CI-korjaus toimitetaan yhdellä commitilla haaraan
  chore/windows-termux-verified-pull-20261006-main; PR #194 pysyy draftina, ei mergeä.

## Viimeistely REVIEW-tilaan (2026-10-08)

- Toimitettu commit: 22933265e89ec0b9d00295f6a6f7b6da2b5d73fb
  (test: isolate KB smoke tests under a private 0700 HOME; parent c8da1e9).
  Muutos lisää vain Fear-of-Falling/tests/conftest.py: per-testti-hook rajaa
  käyttäjän omistaman 0700-HOMEn kahdelle KB-testimoduulille ja palauttaa
  alkuperäiset arvot myös setup- ja testivirheissä. Runtime-, harness-,
  turvarajat- ja tuotantoprofiilitiedostot eivät muutu.
- Vihreät CI-ajot (commit 2293326):
  - python-ci (pull_request): actions/runs/37789612933
  - python-ci (push): actions/runs/37789605683
  - Lint Markdown: actions/runs/37789612945
  - CodeQL: actions/runs/37789612888
  - K Scripts Smoke Tests: actions/runs/37789612845
- Testitulokset (CI, JUnit):
  - inbound test_kb_pull.py: 40 PASS, 0 FAIL, 0 SKIP.
  - harness test_kb_pull_ssh_smoke_harness.py: 4 PASS, 0 FAIL, 0 SKIP.
  - outbound #1 test_artifact_transfer.py: 39 PASS, 0 FAIL, 9 SKIP (48 total).
    Skip-syy (aiempi, tahallinen): "provenance-bound snapshot and local PowerShell
    launcher required" (CrossEndReceiverTests).
  - outbound #2 test_v2_ssh_adapter.py: 11 PASS, 0 FAIL, 0 SKIP.
  - Yhteensä 0 FAIL, 9 SKIP.
- Aiempi näyttö (säilyy voimassa):
  - Windows-runtime 830040ad: erillinen aito Windows-harness 10/10 PASS.
  - Oikea SSH-smoke (A, natiivi Termux): positiivinen + väärä digest + run_id-
    törmäys + katkos = 4 PASS; local_VERIFIED=PASS. A:n koneellinen tulosmanifesti
    säilytetty Gitin ulkopuolella.
- Versioero: testattu Windows-runtime ja batch-provenance = 830040ad; myöhemmät
  testikorjaukset = harness-commit 0a8e5990 (flush), c8da1e9 (rename + Prettier)
  ja 2293326 (yksityinen testi-HOME). Yksikään ei muuta tuotannon fof_kb_pull.py:tä
  (7354b6e0...) eikä tuotantoprofiilia.
- Validoinnin rajat (säilyvät näkyvinä):
  - Tuotantoprofiili kb-pull-documents-1: enabled=false, files=[].
  - Paikallinen VERIFIED varmennettu (A:n positiivinen ajo).
  - Paluukuitti Windowsille: NOT_DELIVERED (protokollan mukaan; raportin
    kopiointi ei ole paluukuitti).
  - Termuxin foreground-näkyvyys: NOT_OBSERVABLE.
  - CSV-tuki ja oikeiden KB-/tuotantoaineistojen siirto: erillisiä tehtäviä.
- Tila: 03-review (siirretty 04-done-tilaan 2026-10-08; ks. alla).

## DONE-sulkeminen (2026-10-08)

- Hyväksymiskatselmointi: ACCEPT, ei estäviä löydöksiä (riippumaton, vain luku -katselmointi).
- PR #194 mergetty mainiin; merge-commit ac265f075a1d1f5fdb4be5fb9cd2c9204ab42fb0
  (base main; hyväksytty head 8f676ac9f3336523ddf8cfa1f7ffcab390cacd63).
- Verkkotestattu runtime = 830040ad (fof_kb_pull.py 7354b6e0...); myöhemmät
  harness-/testi-/dokumentaatiocommitit eivät muuta sitä.
- Validoinnin rajat säilyvät näkyvinä:
  - Tuotantoprofiili kb-pull-documents-1: enabled=false, files=[].
  - Paikallinen VERIFIED varmennettu; paluukuitti Windowsille NOT_DELIVERED;
    Termuxin foreground-näkyvyys NOT_OBSERVABLE.
  - Outbound: 39 PASS / 9 SKIP ja 11 PASS (SKIP ei ole PASS).
  - CSV-tuki ja oikeiden KB-/tuotantoaineistojen siirto: erillisiä tehtäviä.
- Tila: 04-done.
