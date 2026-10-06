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
