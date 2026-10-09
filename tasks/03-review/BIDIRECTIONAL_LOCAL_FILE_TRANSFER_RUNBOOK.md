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
  **23/23 PASS (Windows)**, molemmat vastaanottomuodot: onnistuminen (v1+v2),
  identtinen kohde, konflikti, väärä digest, muuttunut lähde, lähde muuttui
  previewn jälkeen, vaarallinen polku, hard-deny-kohde, linkki/junction, puuttuva
  kuitti, ei-tuettu muoto, duplikaatti map/manifest, kohdetörmäys, keskeneräinen
  map, olemassa oleva kuitti, ylisuuri kohde→CONFLICT, payloadin exact-set,
  esi-isän vaihtuminen (`PARENT_CHANGED`, ei kuittia), keskeytys (osittainen tila,
  ei kuittia), kuitin julkaisuvirhe (ei kuittia), v2-sidonta karttaan.
- **Termux-validointi: NOT_RUN** (natiivi ajo vaatii erillisen Git-toimitusluvan;
  valmis rajattu toimitus valmistellaan).

## Links

- `Fear-of-Falling/docs/LOCAL_FILE_TRANSFER_RUNBOOK.md`
- `Fear-of-Falling/scripts/termux/place_verified_bundle.py`
- `Fear-of-Falling/tests/test_place_verified_bundle.py`
- `Fear-of-Falling/docs/ARTIFACT_TRANSFER.md` (outbound sopimus)
- `Fear-of-Falling/docs/WINDOWS_TERMUX_PULL.md` (pull sopimus)
- `PLACEMENT_TOOL_IMPLEMENTATION_PACKAGE.md` (repository-external evidence)
