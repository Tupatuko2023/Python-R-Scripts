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
