# FOF Durable Artifact Handoff Sender

## Context

Valmistele toistuvan artefaktisiirron lähdepuoli hyväksytyn Phase 0:n rajauksessa.
Tila on 03-review; Phases 1–8 PASS. Ihmiskatselmointi ja Git-toimitus odottavat. Vastinpari dissertation-repossa:
`FOF_DURABLE_ARTIFACT_HANDOFF_RECEIVER`.

## Inputs

- `SKILLS.md`, `config/agent_policy.md`, `config/steering.md`
- `Fear-of-Falling/AGENTS.md`
- `Fear-of-Falling/scripts/termux/export_artifacts_to_windows.sh`
- `Fear-of-Falling/config/artifact-transfer.allowlist`
- `Fear-of-Falling/docs/ARTIFACT_TRANSFER.md`
- Phase 0 ja käyttäjän task-admission-paketti samassa governed interactionissa.

## Outputs

- MODIFY `Fear-of-Falling/scripts/termux/export_artifacts_to_windows.sh`
- MODIFY `Fear-of-Falling/docs/ARTIFACT_TRANSFER.md`
- CREATE `Fear-of-Falling/config/artifact-transfer/a4-general-fi.json`
- CREATE `Fear-of-Falling/tests/test_artifact_transfer.py`

## Yhteinen sopimus ja valtuutus

Phase 0: DURABLE_HANDOFF_IMPLEMENTATION_READY. Tämän kortin valmistelun
auktoriteetti on käyttäjän paketti
`fof-durable-handoff-phase1-task-admission` (2026-09-14).
Ihmistutkija hyväksyi tässä samassa keskustelussa: "tämä tehtävä saa edetä
rajattuna poikkeiksena". SINGLE TASK FOCUS -poikkeus koskee vain tätä nimettyä
sender/receiver-tehtäväparia. Se ei muuta muiden tehtävien tilaa, anna yleistä
jononohituslupaa eikä avaa Git-toimitusta, artefaktisiirtoa tai A4-importia.

Historiallinen valmistelutila: kortti jäi 01-ready-tilaan. Tässä valmisteluajossa ei aloiteta toteutusta.
Uusi toteutuspaketti ja erillinen ajo vaaditaan; silloin matching ready -kortti
tarkistetaan uudelleen ja siirretään normaalisti 02-in-progress-tilaan.
Validoitu toteutus etenee 03-review-tilaan; done vaatii repositoryn
task-kohtaisen Owner-menettelyn. Enintään viisi muuttuvaa tiedostoa ajossa,
myös tehtäväkirjaukset huomioiden. Muiden työpuumuutosten säilyminen tarkistetaan.

Normatiivinen wire-protokolla on `FOF_ARTIFACT_HANDOFF/2`.
Sen ainoa normatiivinen omistaja on Python-R-Scripts-repon
`Fear-of-Falling/docs/ARTIFACT_TRANSFER.md`; dissertation-repo toteuttaa ja
viittaa tähän täsmälliseen versioon, eikä määrittele itsenäistä kilpailevaa
protokollaa. Manifesti sisältää run ID:n, lähderepon loogisen identiteetin,
profiilin/version, työvirran, repo-relative lähdepolut, staging-nimet,
tavukoot ja SHA-256:t sekä deterministisen sisältödigestin ja ajoon sidotun
korrelaatiodigestin. Vastaukset sidotaan oikeaan ajoon ja manifestiin.

Nykyinen Fear-of-Falling `--allowlist` / `--execute` -käyttö, preview-oletus,
alkuperäinen wire-muoto ja alkuperäisen receiverin yhteensopivuus säilyvät.
Uusi profiilitila lisätään nykyiseen senderiin; alkuperäistä käyttötapausta
ei poisteta eikä sen turvallisuusrajoja heikennetä.

Sender-profiili valitsee vain hyväksytyt lähdeartefaktit ja loogisen työvirran.
Se ei saa injektoida mielivaltaisia PC-filesystem- tai kanonisia A4-polkuja.
PC-profiilirekisteri omistaa hyväksytyn profile-to-staging-reitityksen.
SSH alias/host/port/user, source-root, receiverin sijainti sekä PC-repon ja
stagingin sidonnat ovat runtime-konfiguraatiota, eivät portable tracked
profiilin konekohtaisia vakioita.

## Turvallisuus ja sisältörajat

Pakollinen ketju:
explicit profile/allow-list → hard deny → preview →
deterministic metadata/digest → explicit execute → tar over SSH →
unique incoming run → exact-set/size/SHA-256 → VERIFIED →
human review → optional separate A4 import/adaptation.

Hard deny ohittaa allow-listan. Vain tavalliset tiedostot; symlinkit,
hardlinkit, reparse/containment-ongelmat ja vaaralliset archive-entryt hylätään.
Raakadata, osallistujatason sisältö, salaisuudet, ympäristötiedostot,
credentials, source datasets, tietokannat, R-serialized data ja muu suojattu
aineisto kielletään myös ignored-tilassa. CSV vaatii eksplisiittisesti
hyväksytyn output-polun; legacy CSV -rajoitusta ei löysennetä.

.gitignore ei koskaan anna siirtolupaa. Kaikkia ignored-tiedostoja ei viedä.
Ignore-sääntöjä ei muuteta kuljetuksen vuoksi. Lähteen
`Fear-of-Falling/config/artifact-transfer/a4-general-fi.json` on nykyisen
config/-säännön vuoksi ignored; myöhempi erikseen hyväksytty Git-toimitus
tarvitsee vain tämän konfiguraatiopolun täsmällisen force-addin, ei artefaktien
force-addia eikä ignore-muutosta.

Jokainen ajo saa uuden run ID:n ja ignored incoming-stagingin, jossa files/
sisältää vain manifestin artefaktit ja metadata/receipt ovat sen ulkopuolella.
Ei aiempien ajojen overwritea, automaattista deleteä, --delete-valintaa,
automaattista Git-toimintaa eikä importia. Ei kirjoituksia analysis-submoduleen.
Vastaanotin antaa durable VERIFIED -kuitin vasta exact-set/size/SHA-256-
varmennuksen jälkeen. Senderin tilat ovat SUCCESS, FAILED ja
UNKNOWN_REMOTE_STATE. Kadonnut loppukuittaus ei ole SUCCESS: yksilöity ajo
tarkistetaan read-only ennen päätöstä, eikä epävarmaa ajoa uusita automaattisesti.

Nykyinen varmennettu 13-file C22 -paketti on immutable staging-evidenssiä:
ei toteutusfixture, tracked deliverable eikä automaattinen A4-import-lähde.
General FI / C22 kuuluu A4-työvirtaan, ei A1/A2:een. Kanonista A4-manuskripti-
tai supplement-polkua ei ole hyväksytty. A4 README saa kuvata vain
omistajuuden/statusrajan. Scoring, tieteelliset väitteet ja käsikirjoitukset
eivät muutu. K18/QC: NOT APPLICABLE — kuljetusinfrastruktuuri, ei analyysimuutos.

## Hyväksytyt toteutusvaiheet ja näyttö

Alla olevat tiedostot ovat kunkin repon suhteellisia polkuja. Kukin kortti
valtuuttaa myöhemmässä toteutusajossa vain oman Outputs/output_files-joukkonsa.
Toisen repon vaiheet ovat koordinaatioriippuvuuksia, eivät tämän kortin
kirjoituslupa. Tehtäväkorttiin kirjataan vaiheen näyttö.

1. Source profile and protocol contract: lähteen JSON-profiili,
   ARTIFACT_TRANSFER.md ja Python-testi. Näyttö: schema, hyväksytyt täsmäpolut,
   hard deny ja metadata/digest-determinismi.
2. Sender profile mode and backward compatibility: lähteen sender ja
   Python-testi. Näyttö: legacy preview/execute sekä uusi profiili ja
   korrelaatio säilyttävät turvallisuussopimuksen.
3. Permanent receiver: PC scripts/receive_artifact_bundle.ps1 ja
   tests/artifact_transfer_receiver.Tests.ps1. Näyttö: testattujen
   archive/exact-set/size/hash/receipt-mekaniikkojen säilyminen.
4. PC profile registry: PC config/artifact-transfer-profiles.json sekä
   receiver ja receiver-testi. Näyttö: sallittu reititys, tuntemattoman
   profiilin ja destination-injektion fail-closed-hylkäys.
5. Regressions: molempien repoiden nimetyt testit. Näyttö: koko alla
   määritelty regressioperhe läpäisee; toteutuskorjaukset vain tämän
   hyväksytyn tiedostojoukon sisällä.
6. Actual-Windows synthetic smoke: nimetty testimekanismi ja erikseen
   valtuutetut synteettiset, ignored testiajot. Pysyvä receiver tarvitsee
   uuden actual-Windows-smoken ennen tuotantokäyttöä, vaikka väliaikainen
   receiver läpäisi aiemmin. Ei oikeaa C22-pakettia. Tässä admission-ajossa
   myös synteettinen verkkosiirto on suljettu.
7. Documentation and A4 ownership note: molempien repoiden
   ARTIFACT_TRANSFER.md sekä PC papers/A4_placeholder/README.md.
   Näyttö: yksi normatiivinen sopimus, runtime-konfiguraatio, ei
   kanonisointia eikä automaattista importia.
8. Final compatibility/security/scope review: nimetyt testit ja
   tehtäväkirjaukset. Näyttö: legacy/uusi tila, lint/whitespace,
   classification/security, täsmällinen scope ja ennallaan pysyvä
   ulkopuolinen työpuu. Git-toimitus ei avaudu testien PASSista.

Jokainen vaihe pysähtyy security-, protocol-, backward-compatibility- tai
scope-virheeseen. Vaadittu näyttö on saatava ennen seuraavaan vaiheeseen
etenemistä; suorittamatta jäänyttä testiä ei merkitä PASSiksi.

Minimiregressiot: happy path; secret/raw deny; traversal; absolute path;
extra/missing member; size/hash mismatch; partial tar; symlink/hardlink;
duplicate/case collision; rerun preservation; late acknowledgement loss;
profile validation; destination injection rejection; preview/content-digest
determinism. Kaikki fixtuurit ovat synteettisiä ja ei-sensitiivisiä.

## Definition of Done (DoD)

- [x] Lähdeprofiili ja normatiivinen FOF_ARTIFACT_HANDOFF/2-sopimus toteutettu.
- [x] Senderin legacy-yhteensopivuus ja kaikki lähdepuolen regressiot PASS.
- [x] Yhteentoimivuus pysyvän receiverin kanssa varmennettu synteettisesti.
- [x] Kaikkien soveltuvien vaiheiden näyttö, turvallisuus ja scope tarkistettu.
- [x] Ulkopuolinen työpuu, 13-file staging ja tieteellinen sisältö säilyvät.
- [x] Dokumentaatio vastaa toteutusta; ei automaattista Git-toimitusta/importia.

## Log

- 2026-09-14T12:00:20+03:00 Kortti valmisteltu käyttäjän hyväksymässä task-admission-ajossa
  pohjasta tasks/_template.md ja SKILLS.md:n orkestroijan tehtävänluontipoikkeuksella.
  Rajattu SINGLE TASK FOCUS -poikkeus kirjattu; tila 01-ready.
  Toteutusta, tehtäväsiirtoa, artefaktisiirtoa tai Git-kirjoituksia ei aloitettu.

## Blockers

- Ei avointa teknistä review-estettä. Git-toimitus ja tuotantoaktivointi vaativat erillisen päätöksen.
- Ei avointa SINGLE TASK FOCUS -estettä tälle nimetylle tehtäväparille.

## Links

- `tasks/_template.md`
- `Fear-of-Falling/docs/ARTIFACT_TRANSFER.md`
- Dissertation-repon vastinkortti:
  `FOF_DURABLE_ARTIFACT_HANDOFF_RECEIVER` (sijainti tehtävätyönkulun mukaan)

## Phase 1 admission

- 2026-09-14T12:24:03+03:00 Phase 1 avattu: vain protocol/profile/tests. PC-koodi pending.
  Käyttäjä vahvisti korttikohtaisen SSH-luvan sekä korttisiirron laskemisen
  yhdeksi tiedostoksi. Aiemmat ready-/bootstrap-ohjeet ovat valmisteluhistoriaa.

## Phase 1 evidence — PASS

- 2026-09-14 Phase 1 valmis; kokonaistehtävä jää in-progress-tilaan.
  Vaiheet 2–8 ja PC-toteutus pending. Vaihe 2 vaatii uuden paketin.
- Toteutusrajauksessa vain kolme lähdetiedostoa: ARTIFACT_TRANSFER.md,
  config/artifact-transfer/a4-general-fi.json ja tests/test_artifact_transfer.py
  Fear-of-Falling-aliprojektissa; lisäksi kaksi korttisiirtoa/lokipäivitystä.
  Owner vahvisti tämän viideksi loogiseksi tiedostoksi.
- Normatiivinen FOF_ARTIFACT_HANDOFF/2, dokumentista luettava Draft 2020-12
  -skeema, fail-closed ASCII-polkuvertailu ja stable/run-digestien erottelu.
  Testit ovat sopimuksen referenssiharness, eivät tuotantovalidointia.
- Profiili: EMPTY_NOT_EXECUTABLE; 0 aktiivista mappingia. Legacy-allowlist
  sisältää vain kommentteja; nykyistä hyväksyttyä General FI -source-valintaa
  ei todettu tässä rajauksessa. Historiallista stagingia ei käytetty.
- FOF-juuressa ajettu:
  PYTHONDONTWRITEBYTECODE=1 python -m unittest discover -s tests -p test_artifact_transfer.py -v
  Tulos: 18/18 PASS (sisältäen parametrisoidut adversarial-alitapaukset).
  Erillinen runpy-pohjainen nykyprofiilin schema+semantic-validation PASS;
  jsonschema oli jo asennettu. pytest ei ollut asennettu; käytettiin repon
  olemassa olevaa unittest-käytäntöä, ei asennettu riippuvuuksia.
- Vakaa profile_sha256:
  7a82ab250177961c3e61d653d96b7441f8c92ed4a5f87f7db9c20a9b7be0182c
  Profiilitiedoston raakatavujen SHA-256:
  71d91b6bf69b25f2c7115ecbbc153f87ee09605314fb2f119c1ee05996a7f46a
- ARTIFACT_TRANSFER.md SHA-256:
  033ff79e74c3ab2f0d3bf6f2ca8e03901851e65654c977c37821ed9e1af329a8
  test_artifact_transfer.py SHA-256:
  d46957132a9f79c1179d4ff3fc28b7ca5e1cd14a6a667a4c48b22d468e34609c
- Legacy-dokumentin alkuperäinen tavuprefix ja sender-runtime ovat muuttumattomat.
  Ei sender-kutsua. Ei PC-implementation-tiedostoja.
- git diff --check lähdedokumentille PASS. Uusi testi, ignored JSON ja
  kortit tarkistetaan täysistä tavuista erikseen; ei trailing whitespacea.
  config/-ignore säilyy, ei force-addia. Untracked/ignored-tiedostojen
  kattavuutta ei päätellä tavallisesta git diffistä.
- fof-preflight ennen ja jälkeen: exit 0 / sama K40 WARN:
  dynamic K40 raw-sheet contract declared; skipped fixed req_cols check.
  Ei uutta FAILia. Preflight ei kata untracked/ignored-tiedostoja;
  niiden näyttö on yllä oleva exact-file schema/security/content-tarkistus.
- K18/QC NOT APPLICABLE: ei tiedettä tai analyysimuutosta.
  Ei verkkoartefaktisiirtoa, Windows-smokea, A4-importia, Git-kirjoituksia
  tai ignore-muutoksia. SSH: vain valtuutettu PC-kortin lifecycle/loki.


## Phase 2 evidence — PASS

- 2026-09-14T12:52:57+03:00 Phase 2 toteutettu paikallisesti. Kortti jää 02-in-progress-tilaan;
  koko DoD ei ole valmis. Vaiheet 3–8 suljettu ilman uusia paketteja.
- Muutetut tiedostot: sender, test_artifact_transfer.py, ARTIFACT_TRANSFER.md
  sekä tämä kortti (4 loogista tiedostoa). Ei PC-kirjoituksia tai PC-lokipäivitystä:
  tämän vaiheen suoritus on LOCAL_SHELL-only eikä remote-lokia vaadittu.
- Uusi --profile-valinta; mutually exclusive eksplisiittisen --allowlist-valinnan
  kanssa. Oletusajo ja vanha --allowlist/--execute säilyvät.
- Closed-schema v2 validation, source repository identity/HEAD, exact-path
  hard deny, approved hash, safe-open/regular-file/containment, toinen hash-luku,
  profile/HEAD-drift check ja deterministinen manifesti. Stable content_digest
  ei riipu run_id:stä, run_correlation_digest riippuu. ASCII-politiikka Phase 1:n
  mukaisesti. Ei testimoduuli-/jsonschema-riippuvuutta runtime-senderissä.
- EMPTY_NOT_EXECUTABLE preview raportoi vain tilan; execute FAILED/1 ennen verkkoa.
  Aktiivisen profiilin execute: local preparation -> FAILED/1
  RECEIVER_NOT_AVAILABLE_FOR_PROTOCOL_V2. Ei pakettia/snapshotteja/SSH:ta.
  Production wiring vaatii myöhemmin receiverin, preview approval digest
  -sidonnan ja verkkoa edeltävän snapshot-pariteetin; tätä sulkua ei ohitettu.
- FOF-juuressa:
  bash -n scripts/termux/export_artifacts_to_windows.sh — PASS.
  PYTHONDONTWRITEBYTECODE=1 python -m unittest discover -s tests -p test_artifact_transfer.py -v
  — 31/31 PASS (18 Phase 1 + 13 runtime-regressiota, useita subtestejä).
- Historiallinen paikallinen check_sender.py-regressiosarja — 29/29 PASS.
  Tarkistetut synteettiset fixtuurit, network/Git-korvikkeet; ei oikeaa
  verkkoyhteyttä. Temp-testiharness ei ole tuotantoriippuvuus tai tracked deliverable.
- Runtime-testit vertaavat manifestia Phase 1 -referenssiin ja kattavat
  tyhjän/aktiivisen profiilin, identity, injection, duplicate/case, hard deny,
  CSV, symlink/parent-symlink/FIFO/directory, invalid JSON, changed source,
  determinismin, execute dependency stopin sekä legacy preview/execute-gaten.
  Legacy SUCCESS/FAILED/UNKNOWN_REMOTE_STATE testattiin paikallisella
  subprocess-korvikkeella, joka kulutti oikean paikallisen tarin ilman verkkoa.
- Alkuajossa Python-pohjainen Git-testikorvike tuotti Termuxissa signal 6:n
  onnistuneen preview-tulosteen jälkeen. Oikean Gitin live empty preview ja
  shell-pohjainen testikorvike onnistuvat; lopullinen sarja käyttää rajattua
  shell-korviketta. Tuotantokoodiin ei lisätty virheen ohittamista.
- Legacy-koodi todettiin tavutasolla samaksi, kun vain uusi profiililohko ja
  CLI-haaran lisäys poistetaan vertailussa. Vanha execute_transfer pysyi samana.
- fof-preflight exit 0: sama aiempi K40 WARN (dynamic raw-sheet contract,
  skipped fixed req_cols check), ei uutta FAILia. Preflight ei kata
  untracked-testiä eikä ignored-profiilia; ne tarkistettiin erikseen.
- Task-scoped git diff --check ja kokonaisten lähdetiedostojen whitespace PASS.
  HEAD/index, ulkopuolinen tracked diff ja ulkopuolinen status muuttumattomat.
- a4-general-fi.json SHA-256 ennallaan:
  71d91b6bf69b25f2c7115ecbbc153f87ee09605314fb2f119c1ee05996a7f46a
  Tila EMPTY_NOT_EXECUTABLE, 0 mappings; ei profile activationia tai force-addia.
- Sender SHA-256:
  e2d811ce61a68787d5ec26b076549e6ef162ac07bf1caf38fc6d55ed14529a9b
  Testit SHA-256:
  16723dd43285c4532299f3d6a509fbefffb165ad60303870c9d8f09616d5c73d
  Dokumentti SHA-256:
  a7cdeb66962dd0af2decfec32ef2c87409ace706825b546f5d74d48f85a9b1b8
- Ei oikeaa SSH/network-siirtoa, Windows-smokea, PC-implementationia,
  staging-/manuskriptimuutoksia, A4-importia, ignore-muutoksia tai Git-kirjoituksia.
  K18/QC NOT APPLICABLE — vain transport infrastructure.


## Phase 5b evidence - RECEIVER_REPAIR_REQUIRED

- 2026-09-14: read-only PC snapshot captured with byte hashes and identical
  before/after HEAD, index and status; SSH disconnected before local testing.
  PC HEAD: 2f430c26b532f0becc03a1e86dfaabca08724d6c.
  Receiver SHA-256:
  1f3754e1bde12617ef663e9fa3730ade5522891230cdc2c2da7ab5b8d153f30e.
- Local synthetic probe used the real sender profile preview, unchanged manifest
  bytes in a USTAR harness, and a byte-identical copy of the permanent receiver.
  Fixture registry/profile approvals existed only in separate temporary space;
  captured real registry and all four snapshot files remained byte-identical.
  Runtime: local PRoot PowerShell 7.4.1; no Windows transport/smoke.
- Valid case: receiver exit 0, correlated VERIFIED, synthetic file hashes PASS.
  Hash-mismatch case: receiver exit 1, no VERIFIED (safe rejection PASS), but
  stdout empty instead of the required correlated FAILED JSON.
  CLI catch emits only FAILED: RECEIVER_REJECTED to stderr even after validated
  manifest/registry correlation. This violates the normative completion contract
  in source ARTIFACT_TRANSFER.md. An observing sender must classify the missing
  response as UNKNOWN_REMOTE_STATE, not a confirmed correlated FAILED.
- Required later PC repair: retain trustworthy validated run correlation across
  rejection and emit exactly one correlated FAILED response with error_code;
  do not fabricate correlation for unreadable/untrusted early input. Add CLI-level
  regression for valid manifest plus rejected content. No normative schema change.
- Stopped on receiver defect as authorized: no receiver/snapshot patch, sender
  integration change, source test edit, registry/profile activation or Git writes.
  Only this source task log changed. State remains in_progress. Complete Phase 5
  matrix, 29 Pester tests and sender SUCCESS path are NOT claimed PASS; sender
  execute dependency stop remains. Receiver repair needs its separate PC phase.


## Phase 5d evidence - DURABLE_HANDOFF_PHASE5_PASS

- 2026-09-14: fresh read-only post-repair PC snapshot captured at
  2026-09-14T12:35:10.3690100Z; PC main HEAD
  2f430c26b532f0becc03a1e86dfaabca08724d6c, origin/main.
  PC HEAD/index/status before and after capture identical. SSH disconnected
  before local edits/tests; no subsequent PC connection or Windows writes.
- Snapshot outside repositories:
  /data/data/com.termux/files/usr/tmp/fof-phase5d-snapshot-ze_nrctw
  baseline.json binds all four files to PC metadata and capture time.
  Receiver SHA-256:
  1a3defba254bdb0d0b331cc974a1f4bfb06e680b8e7f2e4331240518c39beec2
  Receiver tests SHA-256:
  1c1a4a25bb7183b5254f2ca4aaf02198154965ec8cd1fe0f226e577209f9066c
  Registry SHA-256 (unchanged Phase 4, production approvals empty):
  65c2d6fcf451862653dd818085c7314170e3c240fec62c7bdce79ffc86d09fbc
  Receiver card SHA-256:
  fcbaacdb96d768d6933a0527ea2feeb4d007ffe664546bdf9cf0fc99e3d68400
  Repaired receiver supersedes pre-repair 1f3754e1... baseline. All four
  captured files remained byte-identical after local tests.
- Sender adds explicit --local-receiver plus --approved-content-digest for
  --profile --execute only. Executable path is trusted local CLI configuration,
  never a profile field. Preview performs no subprocess/network action.
  Normal profile execution retains RECEIVER_NOT_AVAILABLE_FOR_PROTOCOL_V2;
  no real SSH profile execution was opened. Legacy implementation unchanged.
- Local execution builds a uniquely retained USTAR bundle after safe-open,
  size/hash/stat and final source/profile/HEAD parity checks. It validates one
  bounded, correlated terminal JSON response and never retries automatically.
  Correlated rejection plus exit 1 is FAILED. Missing/invalid acknowledgement
  is UNKNOWN_REMOTE_STATE/non-zero, including acknowledgement loss after VERIFIED.
- Full source unittest discovery: 40/40 PASS, zero skips, 86.964 seconds.
  Includes all prior 31 tests plus 9 cross-end tests with multiple fault cases.
  Real sender and byte-identical repaired receiver executed using local PRoot
  PowerShell 7.4.1. Synthetic profiles/registry/content were separate temporary
  fixtures; no production registry or immutable snapshot file was patched.
- Cross-end cases PASS: success/rerun preservation; hash/size/exact-set/profile
  hash rejection; identity/version/workstream/unknown profile/content digest;
  destination injection; malformed/unsupported metadata; traversal/absolute,
  links, duplicate/case collision, partial tar; existing-run rejection;
  wrong-run/correlation/invalid/multiple acknowledgements; early failure;
  late acknowledgement loss; explicit digest approval; zero-network preview.
  Sender safety/deny/CSV/symlink/non-regular/determinism cases remain covered
  by the original source suite. Early uncorrelated receiver rejection correctly
  remains UNKNOWN_REMOTE_STATE, rather than fabricating a correlated FAILED.
- Historical check_sender.py legacy suite: 29/29 PASS; no network/Git calls.
  bash -n PASS. Immutable receiver and test PowerShell parser checks PASS.
  Pester 33-test suite NOT RUN locally: Pester unavailable (Windows-specific
  CLI/junction cases also present). Prior Windows 33/33 is provenance only;
  this run independently exercised the unchanged receiver CLI through the
  cross-end tests. PSScriptAnalyzer NOT RUN: unavailable.
- fof-preflight exit 0, WARN only for the known K40 dynamic raw-sheet contract;
  no new failure. Untracked test content and ignored profile checked separately.
  Task-scoped diff/whitespace checks PASS. Complete before/after sender diff
  reviewed; original test prefix and legacy code retained unchanged.
- Source baseline comparison covers 1687 tracked/untracked paths plus the
  protected ignored profile. Only sender, source tests and this task log change;
  HEAD/index/status and unrelated baseline file contents/modes remain unchanged.
  a4-general-fi SHA-256 remains
  71d91b6bf69b25f2c7115ecbbc153f87ee09605314fb2f119c1ee05996a7f46a;
  EMPTY_NOT_EXECUTABLE with zero mappings. Protocol documentation unchanged.
- Final sender SHA-256:
  7e809660fdb20296df8320dbaa69793b7adfdd6a6be025c95b048e6c6131f553
  Final source tests SHA-256:
  00a00ccfb64bfff41e80e19261b675656b2bd9f212f2677c4be6597b46e1c017
- No historical staging access/change, real artifact transfer, A4 import,
  receiver repair, profile activation, ignore-rule edit or Git write.
  Task remains in_progress: phases 6-8 are pending. Phase 6 actual-Windows
  smoke requires a subsequent authorization; this run stops after Phase 5.


## Phase 6b - SENDER_SMOKE_PROFILE_REPAIR_PASS

- 2026-09-14T17:43:07.343969+00:00: sender-only smoke-admission repair
  hyväksytyn in_progress-taskin sisällä; ei uutta tehtävää tai lifecycle-siirtoa.
- Ennen muutosta tavutarkka sender-kopio ja synteettinen profiili toistivat
  fof-synthetic-smoke/0.0.0 -> exit 1, PROFILE_SCHEMA_MISMATCH, zero network.
- Uusi --smoke-test vaatii --profile-valinnan ja hyväksyy vain
  fof-synthetic-smoke / 0.0.0. Ilman lippua smoke-identiteetti hylätään.
  Smoke-lippu ei hyväksy tuotannon a4-general-fi/1.0.0-identiteettiä.
  Tuotannon V2_CONSTANTS ja normatiivinen tuotantoprofiiliskeema ennallaan;
  testitilan erillinen identiteettivalinta ei muuta wire/digest-semanttiikkaa.
- Sama v2_load/path/deny/regular-file/symlink/containment/snapshot-parity-
  validointiketju toimii molemmissa tiloissa, myös profiilin uudelleenluvussa
  juuri ennen suoritusta. Source identity pysyy Python-R-Scripts ja workstream A4.
  Tuntemattomat endpoint/registry/staging/destination-kentät hylätään.
- Smoke execute läpäisee valmistelun olemassa olevaan --local-receiver-
  kutsusovittimeen vain --execute- ja --approved-content-digest-valinnoilla.
  Tuleva erikseen valtuutettu verkkoharness voi käyttää tätä reittiä; tässä
  testissä paikallinen synteettinen kuittaussovitin todensi SUCCESS-polun.
  Ilman kutsusovitinta RECEIVER_NOT_AVAILABLE_FOR_PROTOCOL_V2 säilyy.
  Yhtään SSH-kutsua tai Windows-yhteyttä ei tehty.
- Paikallinen koko unittest-sarja 48/48 PASS, 0 skips, 92.401 s:
  PYTHONDONTWRITEBYTECODE=1 python -m unittest discover -s tests -p test_artifact_transfer.py -v
  FOF_TEST_RECEIVER_SNAPSHOT ja FOF_TEST_RECEIVER_COMMAND sitoivat aiemmat
  yhdeksän integraatiotestiä säilytettyyn Phase 5d:n hash-varmennettuun
  vastaanotinsnapshotiin ja paikalliseen PRoot PowerShell 7.4.1 -ajoon.
  Kaikki aiemmat 40 testiä sekä kahdeksan smoke-admission-testiä läpäisivät.
  Snapshotin neljä tiedostohashia pysyivät samoina. PC-tiedostoja ei luettu
  verkosta eikä muutettu; snapshot on paikallista aiempaa todistusaineistoa.
- Uudet testit: explicit flag/exact identity, wrong ID/version/source/workstream,
  production isolation/empty state, endpoint/destination injection, hard deny,
  unsafe CSV, traversal/absolute/empty segments, duplicate/case, symlink/FIFO/
  directory, deterministic profile/content digests, changing run correlation,
  zero-network preview sekä explicit local execute/digest gate.
  Ensimmäisen testiajon paikallisen kuittaussovittimen tar-streamin käsittely
  korjattiin testifixtuuriin; tuotantovalidointia ei heikennetty.
- Historiallinen check_sender.py: 29/29 legacy PASS, zero network/Git calls.
  bash -n PASS; fof-preflight exit 0, vain tunnettu K40 dynamic contract WARN.
  K18/QC: NOT APPLICABLE - ei tieteellistä sisältöä, vain transport admission.
  Koko korjausdiff ja whitespace tarkistettu; ei legacy-koodin muutoksia.
- Source sender SHA-256:
  a8e9cdf0528e052e2e82a915903686e2d992a434a4fb75dfbbd30b226fa22261
  Source tests SHA-256:
  41b99b5b28ec638af25a0a134cc021974f021e339247bde43ab3d2c2ae66ec66
  Tuotantoprofiilin SHA-256 ennallaan:
  71d91b6bf69b25f2c7115ecbbc153f87ee09605314fb2f119c1ee05996a7f46a
  EMPTY_NOT_EXECUTABLE, zero files; ei force-addia tai ignore-muutoksia.
- Lähtötilan hash/status-vertailussa vain sender, testit ja tämä tehtäväloki
  muuttuvat. HEAD/index/status ja muut lähderepositorion tiedostot ennallaan.
  Ei PC-muutoksia, staging-pakettien käsittelyä, Git-kirjoituksia, tuotanto-
  siirtoa tai A4-importia. Varsinainen Phase 6 SSH-smoke jää seuraavaan pakettiin.


## Phase 6d - DURABLE_HANDOFF_PHASE6_WINDOWS_SMOKE_FAIL

- 2026-09-14: actual Termux -> Windows SSH synthetic smoke executed after
  Windows Pester 43/43 PASS and parser PASS. No production artifact transferred.
- Sender --smoke-test used byte-identical permanent source implementation in
  isolated synthetic fixture checkout; source SHA-256:
  a8e9cdf0528e052e2e82a915903686e2d992a434a4fb75dfbbd30b226fa22261
  Receiver directly executed installed scripts/receive_artifact_bundle.ps1
  -SmokeTest -SmokeSession; no temporary receiver code. Receiver SHA-256:
  73f179e8b3f3fe53ba518c3805c87e9ab9d0d7db3682911180b071d46ecbc7a8
- Two previews: same profile/content digest, zero network calls. Explicit
  execution used real SSH, permanent Windows PowerShell 7.6.6 and the receiver.
  Earlier EncodedCommand attempts returned access denied; ordinary PowerShell
  command input and direct -File receiver invocation worked. No security or
  endpoint configuration was changed.
- SmokeSession aae9c89eebcc4400955f5bed09d03610
  run_id 20260914T174953Z-53ee27424aff4d0ab866295c1a238dff
  Receiver exit 0, correlated VERIFIED, exact 2 synthetic files and SHA-256
  parity 2/2. Durable receipt retained in receiver-owned ignored smoke subtree.
- HAPPY PATH FAILED at sender terminal acceptance: receiver emits
  verified_at="2026-09-14T17.49.55Z". Sender requires HH:mm:ss and safely returns
  UNKNOWN_REMOTE_STATE / exit 3, never SUCCESS. The receiver uses culture-
  sensitive UtcNow.ToString("yyyy-MM-dd'T'HH:mm:ss'Z'"); Windows time separator
  is reflected in output. Repair owner: permanent receiver timestamp formatting,
  plus a culture-sensitive CLI regression. Do not loosen sender validation.
- Stopped on this implementation defect; hash/exact-set/adversarial/partial/
  late-ack/rerun/collision network cases NOT RUN. No automatic retry, cleanup,
  production-code repair or Phase 7 work. Synthetic verified run is preserved.
- Post-run file hashes: permanent sender/receiver, production profile/registry,
  historical C22 package/receipt and pre-existing PC files unchanged. Only
  seven new files under this unique smoke session before task-log updates.
  Production source profile remains EMPTY_NOT_EXECUTABLE; registry approvals
  remain empty. Source HEAD/index/status unchanged before logging.
- Concurrent PC Git state change detected (not made by these commands):
  HEAD 105b83458fa027d77733ebde581c3477b2b2ff56 -> 631876203bfd17ab383f856bfb4011ffea74485c.
  Index changed; seven ORCID metadata/sync tracked modification markers cleared,
  while those file contents stayed byte-identical. PC HEAD/index/status parity
  therefore NOT PASS. No attempt to reset, restore or otherwise undo this state.
- Scope of this run: synthetic temporary fixture/harness, ignored smoke session,
  sender/receiver task logs only. No Git write commands, A4 import, manuscript
  edit, production registry change or production artifact transfer.


## Phase 6e - DURABLE_HANDOFF_PHASE6_WINDOWS_SMOKE_FAIL

- 2026-09-14: explicitly authorized actual SSH rerun performed with a NEW
  synthetic session after Windows Pester 43/43 PASS, zero skips, parser PASS.
  Production registry content approvals 0; source production profile remains
  EMPTY_NOT_EXECUTABLE. Two smoke previews produced identical content/profile
  digests and no network call.
- Source sender SHA-256:
  a8e9cdf0528e052e2e82a915903686e2d992a434a4fb75dfbbd30b226fa22261
  Permanent Windows receiver SHA-256, unchanged before/after:
  73f179e8b3f3fe53ba518c3805c87e9ab9d0d7db3682911180b071d46ecbc7a8
  Byte-identical sender ran in synthetic fixture checkout with --smoke-test;
  SSH invoked the installed receiver directly with -SmokeTest/-SmokeSession.
  No temporary receiver implementation or production artifact was used.
- SmokeSession e7e2ace759334f589e4eb460f9da9f5c
  run_id 20260914T180036Z-366097b834614a0190c5b6ad7453dcf2
  Receiver: exit 0, VERIFIED, exact 2 synthetic files, size/hash parity 2/2.
  Sender: exit 3, UNKNOWN_REMOTE_STATE, never SUCCESS.
- First mandatory happy-path defect reproduced: receiver verified_at is
  2026-09-14T18.00.39Z instead of protocol HH:mm:ss separators. Culture-sensitive
  receiver timestamp serialization remains unchanged since Phase 6d. Repair
  owner RECEIVER: invariant timestamp formatting plus culture-specific CLI
  regression; do not relax sender parsing. Production code not patched here.
- Matrix stopped at this first defect as instructed. Remaining hash/size/set,
  unsafe paths/links/collisions, partial/late-ack and rerun network cases NOT RUN.
  No automatic retries or deletion. New durable synthetic evidence preserved.
- PC HEAD 78faa8a4977dcaf123f0b5a6eab610df33d2c199 and index/status matched immediately
  before and after smoke and again in the full post-run inventory. Unlike
  Phase 6d, no concurrent Git-state mutation was observed in this run.
  Full file-hash comparison: only six NEW ignored evidence files under this
  smoke session before logging. Historical C22 package/receipt, earlier smoke
  sessions, production registry/receiver/tests and unrelated PC files unchanged.
- Source file-hash inventory, HEAD/index/status unchanged before this log.
  Only the two authorized task logs added afterward; no production code,
  profile, registry, protocol, ignore, A4 or manuscript change. No Git writes.
  No Phase 7 work. Task remains in_progress pending receiver timestamp repair.


## Phase 6g - DURABLE_HANDOFF_PHASE6_WINDOWS_SMOKE_PASS

- 2026-09-14: full actual Termux -> Windows SSH synthetic matrix completed.
  Protocol FOF_ARTIFACT_HANDOFF/2. No production payload or production-code edit.
- Windows Pester 47/47 PASS, parser PASS, production registry approvals empty.
  Source post-smoke tests 48/48 PASS (0 skips, 109.077s); legacy 29/29 PASS;
  bash syntax PASS. Local source integration used retained immutable Phase 5d
  receiver evidence; actual-network cases used the repaired live PC receiver.
- Sender --smoke-test: byte-identical permanent implementation in isolated
  harmless fixture checkout. Real SSH bridge executes installed permanent
  scripts/receive_artifact_bundle.ps1 -SmokeTest -SmokeSession directly.
  No temporary executable receiver. Hash checked before/after every network case.
  Sender SHA256 a8e9cdf0528e052e2e82a915903686e2d992a434a4fb75dfbbd30b226fa22261
  Receiver SHA256 0670147b40662a5cfbd84336da9beb4a830f1f63524f508cbc51a4a1424c9ec0
- Two deterministic zero-network previews PASS. Happy receipt timestamp:
  2026-09-14T18:25:53Z (literal colons, UTC Z), accepted as SUCCESS/exit 0.
  Content digest ed27c46526e5b16e1a46175839525788bb73af514d44bd6c9530843a57b34f8b
- All 23 sessions passed their acceptance checks: 2 SUCCESS, 9 correlated
  FAILED, 12 UNKNOWN_REMOTE_STATE. Known payload hash/size/set failures emit
  FAILED. Early untrusted metadata/link/truncated-envelope rejections produce
  no trusted terminal response and therefore UNKNOWN_REMOTE_STATE, not SUCCESS.
  Late acknowledgement loss retains durable VERIFIED with sender exit 3.
  Collision retains the original receipt/files unchanged and rejects reuse.
- One harness oracle expected FAILED for a modified manifest profile hash;
  modification also invalidated the content digest, so UNKNOWN_REMOTE_STATE was
  correctly observed before correlation. Classified this negative case correctly;
  added a separate NEW-session registry-profile-hash mismatch with a valid
  manifest, which produced correlated FAILED. No production behavior patched.
- Initial management-command startup sometimes returned access denied; ordinary
  quoted -Command management calls and direct -File receiver calls worked.
  No endpoint/security configuration was changed; no uncertain payload retried.
- Before/after HEAD/index/status match on both endpoints. All prior production,
  historical C22/VERIFIED and earlier smoke hashes unchanged. Exactly 43 new
  ignored files match the 23 session evidence maps. Source profile remains
  EMPTY_NOT_EXECUTABLE; production registry unchanged and approvals empty.
- Separate inventory observation: initial PC inventory contained
  tasks/02-in-progress/TASK-ORCID-009-hus-physiotherapist-start-date-2009-02-03.md,
  final inventory did not. This unrelated path was never targeted by any command
  in this task; aggregate Git state stayed equal. Inventory is not atomic across
  other activity. Smoke attribution remains exact: all task writes map to the
  new sessions below and these two task logs. No cleanup/revert was attempted.
- No automatic smoke cleanup, Git writes, A4 import, manuscript edits or Phase 7
  work. Durable-handoff task remains in_progress for phases 7-8.

| Case | SmokeSession | Run ID | Sender exit | VERIFIED retained |
| --- | --- | --- | --- | --- |
| absolute | 0cf4c2b92bc645b78fd3e1711c2ad050 | 20260914T182652Z-603c9c1e045a4cc6945fffb836ff30d6 | 1 | False |
| case | de4c6ef4b4e54ab792c99445e01e0774 | 20260914T182713Z-ff93ea83a30247cd928cc7cec9c72d6f | 1 | False |
| collision | a80f6d893b894db3852bdea912daaddb | 20260914T182736Z-2f15b586e69e4a83b5a9fd1bd5c4a340 | 1 | True |
| destination | 4c217ddc5788458d9dbd03bbc1f62f6d | 20260914T182755Z-bc372293d75a4c248da25585eb3f3991 | 3 | False |
| duplicate | eeee35969abb4549801bfd4ac45af047 | 20260914T182708Z-d92c4ba41a7e442abe3c69717b00429a | 1 | False |
| hardlink | 4224b544a46143e7830cf2cea81b7798 | 20260914T182703Z-38e4288a71914383adf45e797e2a4b4e | 3 | False |
| hash | 707a3b13d885415db34f7329727ba6f6 | 20260914T182630Z-8dd4aafb27f2445987913e2b773dc3f5 | 1 | False |
| late_ack | 5f8bb123c31a44629f1b993430ed911d | 20260914T182725Z-ef715c614c044dbc89a54fd3b3d0c095 | 3 | True |
| missing | 6109c9dbcdd349568f5c72d90b9ed92c | 20260914T182641Z-f520cb81577843998dc7ba3b90bae46a | 1 | False |
| ok | 23985683898b40229c5f22528de9fe86 | 20260914T182730Z-47e15fc4d13e4405a57e6152bd445b23 | 0 | True |
| ok | 5f4cacab4d3f4de6be140d490df2dbac | 20260914T182551Z-06658923358c40b4a12f3b88be83512b | 0 | True |
| partial | a85cdc62c8cd42a0a73b3f5e0210ad58 | 20260914T182719Z-fa0260ace77146f2b29151b62e3f2caf | 3 | False |
| production_identity | ba706f601e0148b98be3f6fb95e7d22a | 20260914T182749Z-29d4a5cc1c6a4de9a4d698bc393ac773 | 3 | False |
| production_route | 3a5c28ffbd47419090ab335e8336676c | 20260914T182744Z-54007aff91f54484b0d8de37c52d8097 | 3 | False |
| profile_id | d53da33e4b5048959662703bfb5a12d3 | 20260914T182800Z-ca76e20388e5453194d8cefb81c86f30 | 3 | False |
| profile_sha256 | da57544152b64d8e869af69d58da9ac3 | 20260914T182823Z-fad9ffceb23d4cfbabe04ae9f4667cf8 | 3 | False |
| profile_version | 04b77799de53469db02eced527d080bc | 20260914T182806Z-d7d9378a84b7489894f7d16c061582b1 | 3 | False |
| registry_profile_hash | 66847787571c47049f989c7a1f1eb4be | 20260914T182914Z-98f83a0993eb423bad62d2d5f5d27452 | 1 | False |
| size | 82e2f66675be4f3a9c029bfe975674bc | 20260914T182636Z-d0e1bf7334d34f6383e7f5f9d3db96b6 | 1 | False |
| source_repository_id | 68586a504e5f4df2bb1a35db47876332 | 20260914T182817Z-23b8b1ea82f64cdd937033fae08ce24e | 3 | False |
| symlink | 1209ebc5b6cf4b959c35e2ff260183f9 | 20260914T182657Z-c8b5e86021534d509f548b85822d95f5 | 3 | False |
| traversal | 01966cbf63f64d4f8fe739b54324ca89 | 20260914T182646Z-bf36ca5d5cdb46e5910702d15fd009bb | 1 | False |
| workstream | fb7f5bbeb81c4ebfa40c4d3b8a9928f7 | 20260914T182811Z-a9c52024c04045b8bd241d3182568426 | 3 | False |


## Phase 7 — dokumentaatio ja A4-omistajuus

- 2026-09-15T05:13:16.532005+00:00: käyttäjä vahvisti muiden PC-kirjoittajien pysäytyksen. Uusi lähtötila otettu valmistuneen ORCID-työn jälkeen; ORCID-009 done-kortti kuuluu lähtötilaan, ei tämän tehtävän muutoksiin. Yksinomainen kirjoitusikkuna jatkuu lopputarkistukseen asti.
- Luettu aiemman ajon ohjeet ja nykyinen toteutus; luonnoksia verrattu live-source-dokumenttiin, sender/receiver-hasheihin, CLI-rajoihin, rekisteriin ja Phase 6g -näyttöön. SKILLS/AGENTS/WORKFLOW, steering, CONTEXT/CONTEXT-MAP, HARD_RULES, ARTIFACT_TOPOLOGY, FILE_MAP_AND_CONTRACTS, artifacts_policy ja grill-with-docs-dokumenttivertailu huomioitu. Hyväksytty SINGLE TASK FOCUS -poikkeus säilyy rajattuna tähän tehtäväpariin.
- Rajaus täsmälleen viisi polkua: lähteen Fear-of-Falling/docs/ARTIFACT_TRANSFER.md; PC docs/ARTIFACT_TRANSFER.md; PC papers/A4_placeholder/README.md; molempien in-progress-tehtäväkorttien lokit. PC:n siirtodokumentti puuttui lähtötilasta ja luotiin hyväksyttyyn polkuun. Ei lifecycle-siirtoja.
- Ohjeet erottavat Git/submodule-koodikanavan, hyväksytyn exact-manifest/tar-over-SSH-stagingin ja erillisen ihmisen hyväksymän A4-import/adaptation-kanavan. Normatiivinen lähdeomistaja ja tuotantoprofiiliskeema säilyvät. Legacy-käyttö erotettu v2:sta; vanhentuneet vaiheiden 1–2 nykytilaväitteet korvattu.
- Nykyinen --local-receiver/--approved-content-digest/--execute-rajapinta sekä --smoke-test ja receiverin -SmokeTest/-SmokeSession kuvattu rehellisesti: ilman sovitinta v2:n verkkosulku säilyy. Ei tilapäisen harnessin nimeämistä kanoniseksi riippuvuudeksi. Invariantti UTC verified_at, FAILED/UNKNOWN_REMOTE_STATE/VERIFIED, recovery/uudet ajot ja tuotannon aktivointiraja dokumentoitu.
- A4 README määrittää vain General FI / deficit-accumulation -työvirran erillään A1/A2:sta. Ei kanonista manuscript/abstract/supplement/results-valintaa eikä C22-tuontia.
- Dokumenttien suhteelliset linkit/polut, Markdown-aitaukset, whitespace ja täydet tehtäväkohtaiset diffit tarkistetaan; lähteen upotettu JSON Schema pysyy tavutarkasti samana ja tyhjä tuotantoprofiili validoidaan sitä vasten. Markdownlint CLI ei saatavilla paikallisesti; ei riippuvuusasennusta.
- Phase 6g:n 23 verkkotapausta, Pester 47/47, source 48/48 ja legacy 29/29 ovat aiemman vaiheen näyttöä, eivät tässä ajettuja testejä. K18/QC: NOT APPLICABLE — vain dokumentaatio, ei tiedemuutosta. Phase 8:n regressio, verkkosmoke, artefaktisiirrot, tuotantoaktivointi, Git-toimitus ja A4-import eivät kuulu tähän ajoon.

- 2026-09-15T05:16:07.107732+00:00: DURABLE_HANDOFF_PHASE7_PASS — dokumenttien linkki/polku-, JSON Schema-, whitespace/diff- ja sisältövertailut PASS. Lähteen ainoa muutos dokumentti + sender-loki; PC:n ainoa muutos siirtodokumentti + A4 README + receiver-loki. HEAD/index ennallaan; ORCID-009 ja kaikki muu lähtötilan sisältö, tuotantokoodi/testit/profiilit/rekisteri sekä historiallinen C22/staging/smoke-evidenssi ennallaan. Tuotantoprofiili EMPTY_NOT_EXECUTABLE, tuotannon sisältöhyväksyntä tyhjä. Molemmat tehtävät jäävät 02-in-progress-tilaan. Kirjoitusikkuna vapautetaan viimeisen lokin jälkeisen vertailun valmistuttua; Phase 8 ja Git-toimitus odottavat erillistä pakettia.


## Phase 8a — tehtäväviittauksen korjaus

- 2026-09-15T05:33:50.505082+00:00: korvattu ARTIFACT_TRANSFER.md:n tilakansioon sidottu tehtäväkorttilinkki pysyvällä tehtävätunnisteella. Kortin nykyinen sijainti määräytyy tehtäväworkflown mukaan. Käytäntö vastaa korttien nykyisiä ID-/vastinkorttiviittauksia; ei uutta resolveria, alias-korttia tai symlinkkiä.
- Viittaus toimii kortin ollessa 02-in-progress ja säilyy totena myöhemmässä 03-review/04-done-siirrossa. Korttia ei siirretty. Vain kaksi dokumenttiviittausta ja pakolliset kaksi korjauslokia muuttuvat; protokolla, tuotantotila, toteutus/testit, A4 ja staging säilyvät.
- Linkki/polku-, whitespace/diff- ja lähtötilavertailun tulos kirjataan lopputarkistuksessa. Phase 8:n regressiota tai review-siirtoa ei tehty.

- DURABLE_HANDOFF_TASK_LINK_REPAIR_PASS: linkki/polku-, whitespace- ja täydet korjausdiffit PASS; tuleva lifecycle-siirto ei muuta ID-viittausta. Lähtötilavertailussa vain kaksi dokumenttia ja kaksi korjauslokia muuttuvat; HEAD/index ja suojatut/ulkopuoliset tiedostot ennallaan. K18/QC NOT APPLICABLE. Phase 8 odottaa erillistä ajoa.


## Phase 8b — SOURCE_DOC_CONTRACT_REPAIR_PASS

- 2026-09-15T05:48:34.597675+00:00: tarkistettu test_a4_and_legacy_contract_boundaries sekä referenssitestien ja pysyvän sender-CLI:n erillisyys. Lisätty lähdedokumenttiin kolme riviä: referenssi-/testiharness on validointiväline, ei tuotanto-API; pysyvän senderin CLI on toteutuksen käyttörajapinta. Ei testin tai toteutuksen muutosta.
- Yksittäinen sopimustesti PASS (unittest discover -k test_a4_and_legacy_contract_boundaries). Koko unittest discover -s tests -p test_artifact_transfer.py -v: 48/48 PASS, 0 skips, 97.614 s. Paikallinen PowerShell 7.4.1 käytti edellisen Phase 8 -ajon hash-varmennettua receiver-snapshotia; snapshot ennallaan. Legacy check_sender.py 29/29 PASS; Bash syntax PASS.
- Linkki/polku-, muuttumattoman upotetun JSON Scheman/profiilin ja whitespace/diff-tarkistukset PASS. fof-preflight: vain tunnettu K40 dynamic contract WARN, ei FAIL. K18/QC NOT APPLICABLE — dokumenttikorjaus.
- Hash/status-vertailussa vain lähdedokumentti ja tämä loki muuttuvat; sender, testit, ignored EMPTY_NOT_EXECUTABLE-profiili, HEAD/index ja muu lähdetyöpuu ennallaan. Windowsiin ei otettu yhteyttä eikä PC-repositoryyn, C22-pakettiin tai stagingiin kohdistettu operaatioita; niiden live-tilaa ei uudelleeninventoitu tässä paikallisessa korjauksessa.
- Kortti jää 02-in-progress-tilaan. Ei Phase 8 -kokonaiskatselmointia, review-siirtoa, Git-kirjoituksia, tuotantoaktivointia tai artefaktisiirtoa.


## Phase 8 final review — 2026-09-15

DURABLE_HANDOFF_PHASE8_READY_FOR_HUMAN_REVIEW. Phases 1–8 complete;
status is review, not done. Earlier phase entries below/above are historical.
The user confirmed other writers paused. Fresh source/PC baselines and full
pre-transition comparison matched; only these two task-card transitions are authorized.

- Source protocol/runtime 48/48 PASS (101.702 s); legacy 29/29 PASS.
- Authoritative Windows Pester 47/47 PASS; Bash and PowerShell parsers PASS.
- fof-preflight: known K40 WARN only, no FAIL. PSScriptAnalyzer NOT RUN (unavailable).
- Documentation links/paths, lifecycle-stable task identifiers, JSON/schema,
  whitespace and intended delivery content/security review PASS.
- Phase 6 evidence: 23 actual-network synthetic cases PASS using permanent code;
  SUCCESS, correlated FAILED, UNKNOWN_REMOTE_STATE and invariant UTC verified_at verified.
  No new smoke or production transfer in Phase 8.
- Historical C22 exact 13-file size/SHA-256 verification PASS; all 69 prior
  handoff evidence hashes unchanged. A4 README establishes ownership only.
- Hard deny, containment, regular files, archive exact-set/size/hash, collision,
  trusted routing, isolated smoke identity and receipt correlation reviewed PASS.
  No-delete, preserved reruns, no-auto-Git and no-auto-import remain intact.
- Production a4-general-fi remains EMPTY_NOT_EXECUTABLE; receiver content approvals empty.
- Intended delivery: source sender/document/profile/tests/card; destination
  receiver/registry/tests/document/A4 ownership README/card. No runtime payloads or secrets.
- Tracking: source profile remains ignored and needs later explicit path-scoped
  force-add; PC review card is affected by local exclude. Ignore rules unchanged.
  Source branch has no upstream. Resolve delivery separately with human authorization.
- No technical review blocker remains. Human review, Git delivery, production
  activation and canonical A4 import remain separate decisions; no done transition.

Sender SHA-256: `a8e9cdf0528e052e2e82a915903686e2d992a434a4fb75dfbbd30b226fa22261`.
Receiver SHA-256: `0670147b40662a5cfbd84336da9beb4a830f1f63524f508cbc51a4a1424c9ec0`.
