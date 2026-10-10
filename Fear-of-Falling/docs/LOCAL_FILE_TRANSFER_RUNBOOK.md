# Paikallisen tiedostonsiirron runbook — Windows ↔ Termux

Tämä runbook on yhteinen käyttöohje **kahdelle eri siirtosuunnalle**. Molemmissa
suunnissa **Termux avaa SSH-yhteyden Windowsiin**. Sopimukset ovat erillisiä;
niitä ei sekoiteta.

| Suunta                      | Sopimus                                     | Auktoriteetti                 |
| --------------------------- | ------------------------------------------- | ----------------------------- |
| Termux → Windows (outbound) | `FOF_ARTIFACT_HANDOFF/2` (v2) ja `LEGACY/1` | `docs/ARTIFACT_TRANSFER.md`   |
| Windows → Termux (pull)     | `FOF_KB_PULL/1`                             | `docs/WINDOWS_TERMUX_PULL.md` |

Sijoitus stagingista **valittuun lopulliseen repo-kansioon** on erillinen,
erikseen valtuutettava vaihe (osio 6). Siirron `VERIFIED` ei yksin tarkoita
lopullista sijoitusta.

---

## 1. Yhteinen päivittäinen käyttöpolku

1. **Valinta** — täsmävalinnat (tiedostot ja niiden suhteelliset staging-polut).
2. **Preflight** — verkko, SSH-alias, host-key-luottamus, runtime, yksityiset juuret (ACL/0700, esi-isät, linkit).
3. **Preview** — jokaiselle tiedostolle: lähde, siirron suhteellinen polku ja **lopullinen kohde**.
4. **Digest-hyväksyntä** — ihminen tarkastaa previewn ja hyväksyy `content_digest`in.
5. **Yksi siirto** — yksi ajo, uusi `run_id`.
6. **VERIFIED** — tarkasta kuitti, exact-set, koot ja SHA-256.
7. **Hyväksytty sijoitus** — erillinen valtuutettu vaihe (osio 6).
8. **Raportti** — lopulliset polut, koot, hashit, tiedostokohtainen tila.

## 2. Yhteiset periaatteet

- **Täsmävalinnat**, ei rekursiivisia massavalintoja. `.gitignore` tai Git-tracking **ei** anna siirtolupaa.
- Polut ovat suhteellisia ASCII-täsmäpolkuja; hard-deny (data/participant/salaisuudet/tietokannat/lähdekoodi/CSV) ohittaa valinnan.
- Snapshot-, digest-, exact-set-, koko-, hash- ja kuittitarkastukset säilyvät sellaisinaan.
- **Paikallinen VERIFIED ≠ paluukuitin toimitus.** Paikallinen VERIFIED todistaa teknisen eheyden; paluukuitti Windowsille on eri asia ja tässä kanavassa `NOT_DELIVERED`.
- Kaikki aiot ovat **yksisuuntaisia ja ihmisen käynnistämiä**; ei taustasynkkaa, ei automaattista retryä eikä vanhojen ajojen siivousta.
- `StrictHostKeyChecking=no` on kielletty. Käytä olemassa olevaa luotettua SSH-konfiguraatiota.

## 3. Suunta A: Termux → Windows (outbound)

Toteutus: `scripts/termux/export_artifacts_to_windows.sh` (sender),
`scripts/termux/fof_v2_ssh_adapter.py` (v2 binäärisilta; **ei** valitse tiedostoja),
`scripts/ps7/receive_artifact_bundle.ps1` (Windows-vastaanotin).

Runtime-konfiguraatio (Termux, ei Git-tiedostoissa): `FOF_V2_SSH_ALIAS`,
`FOF_V2_RECEIVER_SCRIPT` (Windows-absoluuttipolku `/`-erottimilla, loppuu
`/scripts/ps7/receive_artifact_bundle.ps1`) ja `FOF_V2_STAGING_DIR` (v2:n **oma**
pakollinen absoluuttinen staging-juuri, sama rajattu polkusopimus). Sovitin välittää
stagingin vastaanottimelle eksplisiittisellä `-StagingDir`-argumentilla; puuttuva
tai virheellinen arvo pysähtyy ennen payloadia. **v2 ei käytä LEGACY/1:n
`WINDOWS_*`-muuttujia eikä `WINDOWS_STAGING_DIR`-oletusta (ei fallbackia).**

[TERMUX] (FOF-juuresta)

```bash
python3 scripts/termux/fof_v2_ssh_adapter.py --check          # preflight: SSH + PowerShell + receiver; ei payloadia
bash scripts/termux/export_artifacts_to_windows.sh --profile config/artifact-transfer/a4-general-fi.json   # preview (ei SSH:tä)
# ihminen tarkastaa previewn ja hyväksyy content_digestin
bash scripts/termux/export_artifacts_to_windows.sh \
  --profile config/artifact-transfer/a4-general-fi.json \
  --execute --approved-content-digest "$APPROVED_CONTENT_DIGEST" \
  --local-receiver "$(pwd -P)/scripts/termux/fof_v2_ssh_adapter.py"
```

- Tulkinta: `SUCCESS/0` = korreloitu `VERIFIED`; `FAILED/1` = paikallinen/korreloitu hylkäys; `UNKNOWN_REMOTE_STATE/3` = käsin read-only-tarkastus.
- Vastaanotto Windowsissa: `<FOF_V2_STAGING_DIR>/incoming/<run_id>/` (`files/`,
  `manifest.json`, `VERIFIED.json`). Staging-juuri on v2:n oma, `FOF_V2_STAGING_DIR`-
  arvoon sidottu; se voi olla **repo-ulkoinen yksityinen** hakemisto (esim. paikallinen
  NTFS-runtime-juuri). Aiempi repo-lokaali muoto
  `<receiver-repo>/artifacts/staging/fof-dissertation-local-handoff` on yksi kelvollinen
  valinta, ei pakollinen; ratkaisevat vaatimukset ovat eksplisiittinen `-StagingDir` ja
  paikallinen, reparse-vapaa, ei-jaettu juuri.
- `VERIFIED` todistaa teknisen eheyden, **ei** julkaisu- tai sijoitushyväksyntää.

[TERMUX] (LEGACY/1, säilyvä allow-list-käyttö)

```bash
bash scripts/termux/export_artifacts_to_windows.sh --allowlist config/artifact-transfer.allowlist            # preview
bash scripts/termux/export_artifacts_to_windows.sh --allowlist config/artifact-transfer.allowlist --execute   # SSH sallittu vain --executella
```

## 4. Suunta B: Windows → Termux (pull)

Toteutus: `scripts/termux/fof_kb_pull.py` (`preview`/`approve`/`serve`/`pull`).
Windows valmistaa snapshot-erän; `serve` materialisoi hyväksytyn USTAR-virran
SSH:n kautta; Termux tarkastaa sen ja julkaisee atominisen `VERIFIED.json`in.
Runtime-konfiguraatio (Termux): `FOF_KB_SSH_ALIAS`, `FOF_KB_REMOTE_SCRIPT`
(Windows-forward-slash-polku), `FOF_KB_REMOTE_BATCH_ROOT`.

[WINDOWS:POWERSHELL] (valmistelu; ei verkkoa)

```powershell
python scripts/termux/fof_kb_pull.py preview --source-root $SourceRoot --profile $Profile --batch-root $BatchRoot
# tarkasta manifesti (täsmäpolut, koot, SHA-256, lähde-HEAD, content_digest) -> $BatchId, $Digest
python scripts/termux/fof_kb_pull.py approve --batch "$BatchRoot/$BatchId" --approved-content-digest $Digest
```

[TERMUX] (preflight + nouto)

```bash
ssh -T -o BatchMode=yes -o StrictHostKeyChecking=yes -o ConnectionAttempts=1 -o ConnectTimeout=10 -o ClearAllForwardings=yes -o PermitLocalCommand=no "$FOF_KB_SSH_ALIAS" 'python --version'
RunId="$(date -u +%Y%m%dT%H%M%SZ)-$(python -c 'import uuid; print(uuid.uuid4().hex)')"
python scripts/termux/fof_kb_pull.py pull --profile "$Profile" --batch-id "$BatchId" \
  --approved-content-digest "$Digest" --staging-root "$StagingRoot" --run-id "$RunId"
```

- `StagingRoot` = uusi/olemassa oleva yksityinen 0700-hakemisto `$HOME`:n alla, repositoryjen ulkopuolella.
- Tarkasta `$StagingRoot/$RunId/VERIFIED.json` ja payloadin hashit read-only; vertaa `run_id`/`batch_id`/`content_digest`/`file_count`.
- Vastaanotto ei tuo mitään repositoryyn. `VERIFIED` on **paikallinen** varmennus; paluukuitti Windowsille on `NOT_DELIVERED`.

Synteettinen smoke (vain erikseen valtuutettuna): lisää `--synthetic-test` ja käytä `kb-pull-synthetic-1`-profiilia; tuotantoprofiili `kb-pull-documents-1` pysyy `enabled=false`.

## 5. Previewt: siirto ja sijoitus erikseen

**Kaksi erillistä previewtä, ei sekoiteta:**

1. **Siirto-preview** (osiot 3–4: `export_artifacts_to_windows.sh` /
   `fof_kb_pull.py preview`) näyttää jokaiselle tiedostolle:
   - **lähde** (repo-juuri + lähde-polku),
   - **siirron suhteellinen polku** (`staging_path`),
   - koko ja SHA-256, luokitus ja `approval_reference`.
     Tämä preview **ei näytä lopullista kohdetta** — siirto päättyy stagingiin.

2. **Sijoitus-preview** (osio 6: `place_verified_bundle.py preview`) näyttää
   jokaiselle tiedostolle `staging_path -> target_path` ja tilan
   (`ABSENT`/`ALREADY_PRESENT`/`CONFLICT`) **valitussa kohderepossa**. Vasta tämä
   preview tuntee lopullisen kohteen, ja se riippuu erikseen annetusta
   sijoituskartasta (`--map`).

Valinta ei ole rekursiivinen; jokainen rivi on eksplisiittinen täsmävalinta.
Lopullinen kohde **ei synny siirto-previewn tulosteesta** vaan sijoituskartasta ja
sijoitus-previewstä.

## 6. Sijoitus stagingista lopulliseen repo-kansioon (erillinen valtuutettu vaihe)

**Kaksi eri asiaa, ei sekoiteta:**

- **Käytettävissä nyt:** itse siirto (osiot 3–4) päättyy **stagingiin**; molemmat
  kanavat ovat staging-only eivätkä tuo tiedostoja repositoryyn automaattisesti.
- **Sijoitustyökalu (`PLACE/1`) — toteutettu:** `scripts/termux/place_verified_bundle.py`
  (portable, pelkkä stdlib) sijoittaa **varmennetun vastaanoton** valittuun
  paikalliseen repo-kansioon. `preview` näyttää tilat; `execute` vaatii juuri
  tarkastetun `placement_digest`in. **Tuetut vastaanottomuodot: `FOF_KB_PULL/1`
  ja `FOF_ARTIFACT_HANDOFF/2`.** `LEGACY/1` on hylätty
  (`UNSUPPORTED_RECEPTION_FORM`) eikä kuulu varmennetun sijoituksen pikapolkuun.
  Validointi alustoittain: **Windows** 44 ajettu (36 PASS, 8 SKIP, ei
  FAIL/ERROR); **aiempi Termux-versio** 43 PASS; **synteettinen Linux**
  44 ajettu (43 PASS, 1 Windows-kohtainen SKIP). Uuden toimituscommitin
  Termux-regressio ja GitHub-CI: **PENDING.**

### 6.1 Sijoituksen syötteet (varmennetut vastaanottorakenteet)

- **FOF_KB_PULL/1 (pull):** `$StagingRoot/<run_id>/` sisältää
  `VERIFIED.json` (`status=VERIFIED`, `run_id`, `batch_id`, `content_digest`,
  `file_count`, `verified_at_utc`, `return_receipt_status`), `manifest.json`
  ja `payload/<staging_path>`.
- **FOF_ARTIFACT_HANDOFF/2 (outbound):** `<StagingDir>/incoming/<run_id>/`
  sisältää `VERIFIED.json`, `manifest.json` ja `files/<staging_path>`;
  `run_id` noudattaa `^[0-9]{8}T[0-9]{6}Z-[0-9a-f]{32}$`.
- Työkalu lukee tavut **varmennetusta stagingista** ja sitoo sijoituksen
  siirron `run_id`+`content_digest`iin sekä `VERIFIED.json`iin.

### 6.2 LEGACY/1 rajaus

**LEGACY/1 ei kuulu varmennetun sijoituksen pikapolkuun**, ellei vastaavia
hyväksyntä- ja varmennustakuita (digest-hyväksyntä + korreloitu `VERIFIED`)
osoiteta. LEGACY/1:n allow-list-siirto ei tuota samaa kuittirakennetta.

### 6.3 CLI (toteutettu; portable, molemmat päät: Windows ja Termux)

Työjuuri: `Fear-of-Falling`-juuri. Skripti: `scripts/termux/place_verified_bundle.py`.

[TERMUX / WINDOWS:POWERSHELL]

```bash
# 1) sijoitus-preview: näyttää staging_path -> target_path ja tilan; ei kirjoita
python3 scripts/termux/place_verified_bundle.py preview \
  --staging-run "$StagingRoot/$RunId" \
  --target-root "$TargetRoot" \
  --map "$PlacementMap"

# ihminen tarkastaa previewn ja hyväksyy tulosteen "placement_digest"-kentän
# 2) sijoitus: vaatii juuri tarkastetun placement_digestin; kuitti repositorioiden ulkopuolelle
python3 scripts/termux/place_verified_bundle.py execute \
  --staging-run "$StagingRoot/$RunId" \
  --target-root "$TargetRoot" \
  --map "$PlacementMap" \
  --approved-placement-digest "$APPROVED_PLACEMENT_DIGEST" \
  --receipt "$PlacementReceipt"
```

- `preview` ei kirjoita; se tulostaa jokaiselle tiedostolle `staging_path`,
  `target_path`, koon, SHA-256:n ja tilan sekä `placement_digest`in.
- `execute` edellyttää juuri tarkastetun `--approved-placement-digest`in
  (muuten `APPROVAL_MISMATCH`).
- `--map` on täsmävalintakartta: jokainen `<staging_path> -> <target-relative-path>`
  (kohde on **sijoituskartasta**, ei siirto-previewstä).
- `--receipt` on pakollinen ja **kohderepositorion ulkopuolinen**; kuittipolun on
  oltava repositorion ulkopuolella (muuten `RECEIPT_INSIDE_TARGET`) eikä sen
  esi-isissä saa olla linkkejä (`LINK_REJECTED`/`REPARSE_REJECTED`). POSIXilla
  parentin on oltava suoraan vakaa yksityinen ankkuri (§6.6); tavallinen
  siirrettävä HOME-alihakemisto hylätään ennen payload-kirjoituksia.
- Exit: `0` = tuloste; `1` = `PLACE_REJECTED: <CODE>` (tai `LOCAL_FAILURE`).

### 6.4 `placement_digest` (toteutettu; hyväksyntä sidotaan)

`digest = SHA-256(canonical_json({PLACE/1-protokolla, siirron run_id,
vastaanottoprotokolla (reception_protocol) ja sen korrelaatio
(reception_correlation = batch_id FOF_KB_PULL/1:lle tai run_correlation_digest
FOF_ARTIFACT_HANDOFF/2:lle), siirron content_digest, kohderepositoryn identiteetti
{origin_url, head}, täsmä-kartta (source->target), kohdetiedostojen odotetut
koot/SHA-256}))`. Hyväksyntä kattaa siis **varmennetut tavut**, **vastaanoton
korrelaation**, **lähde–kohde-kartan** ja **kohderepositoryn identiteetin**.
`content_digest` **lasketaan uudelleen manifestista** kunkin protokollan omilla
kanonisointisäännöillä ja verrataan manifestiin, `VERIFIED.json`iin ja
hyväksyntään (`MANIFEST_DIGEST`, `BATCH_ID_CORRELATION`, `RUN_CORRELATION`).
Työkalu laskee digestin lähettäjän kanssa identtisellä ASCII-kanonisella
JSON-muodolla. Jos jokin ei-polku-kenttä (`profile_id`, `workstream`,
`source_repository_id`) sisältäisi ei-ASCII-merkkejä, työkalun kanonisointi voi
poiketa Windows-vastaanottimen `ConvertTo-Json`-muodosta; poikkeama johtaa aina
**fail-closed**-hylkäykseen (`MANIFEST_DIGEST`/`RUN_CORRELATION`), ei koskaan
virheelliseen hyväksyntään.

### 6.5 Tiedostokohtaiset tilat ja TOCTOU-suojaus

- **Ei pelkkää exists-tarkastusta ennen tavallista kopiointia.**
- Kohdetta ei ole → luo uusi **ilman ylikirjoitusmahdollisuutta**
  (`os.open(..., O_CREAT|O_EXCL)` / Windows `CREATE_NEW`); kirjoita ja `fsync`.
- Kohde on olemassa → lue se lukitusti (no-follow) ja vertaa koko + SHA-256:
  identtinen → **`ALREADY_PRESENT`** (ei kirjoitusta); eri sisältö → **`CONFLICT`**,
  pysähdy (ei overwritea).
- **Polku-/linkkimuutoksia tarkastetaan** descriptor-kävelyllä ja
  `O_NOFOLLOW`-valinnalla POSIXilla sekä ancestor-handleilla ja reparse-
  tarkastuksilla Windowsilla. Kohde avataan `O_EXCL`illä ja esi-isien identiteetti
  tarkastetaan ennen/jälkeen. POSIXin avoin descriptor pinnaa inode-identiteetin,
  mutta ei estä käyttäjän kirjoitettavan esi-isän nimeämistä uudelleen. Kuitille
  tarvitaan siksi erillinen vakaan ankkurin capability-rajaus (§6.6).
- **Android-yhteensopiva ankkuri:** lukija ja kirjoitushakemiston kävely eivät
  avaa juurta (`/`, `/data`, `/data/data`) vaan ensimmäisen käyttäjän
  hallitseman esi-isän (sama katselmoitu ankkuriratkaisu kuin `fof_kb_pull.py`);
  linkki-, traversal-, tyyppi- ja polunvaihtosuojaukset sekä Windows-haara
  säilyvät.
- Epävarma tila (esim. kohde muuttui kesken) → raportoidaan **rehellisesti**
  eikä päätellä onnistuneeksi.
- Osittainen sijoitus (usean tiedoston ajo keskeytyy kesken, esim. I/O-virhe tai
  keskeytys): jo luodut tiedostot jäävät paikalleen **eikä kuittia kirjoiteta** →
  tulos **ei** näytä kokonaan onnistuneelta. `CONFLICT` keskeyttää **ennen**
  kirjoituksia (ei osittaista). Ei rollbackia, poistoa eikä automaattista uusintaa.

### 6.6 Kuittiskeema (`PLACE_RECEIPT/1`) ja kuitin julkaisu

Kohderepositorion **ulkopuolinen** sijoitushuitti (JSON): `protocol`,
`run_id`, `reception_protocol`, `reception_correlation`, `transfer_content_digest`,
`target_repository` (`origin_url`,`head`), `placement_digest`, `files[]`
(`source_path`, `target_path`, `size`, `sha256`, `state` ∈
{`CREATED`,`ALREADY_PRESENT`}), `status` (`PLACED`), `placed_at_utc`.
Kuitti julkaistaan vain, kun kaikki kohteet on varmennettu. `CONFLICT`,
`RECEIPT_INSIDE_TARGET`, `RECEIPT_EXISTS` tai `UNSUPPORTED_RECEPTION_FORM`
keskeyttää eikä tuota kuittia; keskeytynyt ajo ei tuota onnistumiskuittia eikä
automaattista uusintaa. **Siirron `VERIFIED.json`ia ei muuteta.**
Kuitti julkaistaan **atomisesti ilman korvaamista** vasta kokonaan kirjoitetun,
`fsync`-varmennetun väliaikaistiedoston sulkemisen jälkeen. POSIXilla käytetään
natiivia `renameat2(..., RENAME_NOREPLACE)`-operaatiota samalla pidetyllä
hakemisto-descriptorilla, jolla väliaikaistiedosto luotiin. Windowsilla säilyy
`os.link`-julkaisu pidettyjen share-read-esi-isähandlejen suojaamana. Kilpaileva
lopullinen kuitti tuottaa `RECEIPT_EXISTS`; olemassa olevia tavuja ei korvata.
Tavallista renamea, lopulliseen tiedostoon kirjoittamista tai heikompaa fallbackia
ei käytetä. Primitive testataan pienillä synteettisillä tiedostoilla juuri
kuittihakemistossa **ennen payload-kirjoituksia**; puute tuottaa
`RECEIPT_PUBLISH_UNSUPPORTED`. Probe- ja epäonnistuneet väliaikaistiedostot säilyvät.

POSIX hyväksyy kuitin parentiksi vain suoraan ensimmäisen käyttäjän hallitseman
ankkurin, jonka koko edeltävä järjestelmäesi-isäketju ei ole käyttäjän omistama
eikä kirjoitettavissa. Parent on käyttäjän omistama yksityinen hakemisto
(group/other-oikeudet 0); uid, mode ja inode-identiteetti varmennetaan pidetystä
fd:stä uudelleen jokaisessa havaintopisteessä. Tämä on **capability-rajaus**:
siirrettävät HOME-alihakemistot tuottavat `RECEIPT_PARENT_MOVABLE` ennen kohteiden
kirjoituksia. Pelkkä descriptor + viimeinen exists/identity-tarkastus ei poistaisi
rename/check-välin kilpailua. Luottamusraja olettaa käyttöjärjestelmän sekä root/
system-hallinnan luotetuiksi; näiden tahojen muutoksille ei luvata suojaa.

Natiivissa Termux-kokeessa app-root oli vakaa/private ja sen edeltävä ketju
system-owned/non-writable käyttäjälle. Positiiviset kuittipolut olivat suoraan
siinä; paikalliset täsmäpolut ovat vain yksityisessä evidenssissä. Kokeen yritys
siirtää ankkuri oman jälkeläisensä sisään saattoi epäonnistua EINVALillä:
tämä osoittaa containment-kiellon, **ei yksin ACL-rajauksen todistusta**.
Luottamusraja varmennetaan erillisillä ketjun ownership/write-tarkastuksilla.
Windowsin handle-lukitus ja sen erillinen native-validointi säilyvät vaatimuksina.

Ennen julkaisua epäonnistuva kirjoitus/publish ei luo lopullista onnistumiskuittia.
Jos atominen julkaisu onnistuu mutta jälkeinen directory-fsync epäonnistuu,
`RECEIPT_VISIBLE_DURABILITY_UNCONFIRMED` päättää ajon nonzero-tilaan: täydellinen
PLACED-kuitti on jo näkyvissä, eikä sitä poisteta tai korvata. Näkyvyys ei silloin
todista crash-kestävyyttä. Tarkasta kuitti ja kohteet read-only; ei automaattista
retryä, rollbackia, poistoa tai importia.

### 6.7 Koodi-/testipolut ja synteettiset testit

- Koodi: `Fear-of-Falling/scripts/termux/place_verified_bundle.py` (toteutettu; portable, pelkkä stdlib, molemmilla päillä).
- Testit: `Fear-of-Falling/tests/test_place_verified_bundle.py` — aiemman version natiivi Termux **43 PASS, 0 FAIL, 0 SKIP**, molemmat vastaanottomuodot:
  onnistuminen (`CREATED`, FOF_KB_PULL/1 ja FOF_ARTIFACT_HANDOFF/2), identtinen
  kohde (`ALREADY_PRESENT`), konflikti (`CONFLICT`, ei overwritea), muuttunut
  lähde (`PAYLOAD_MISMATCH`), lähde muuttui previewn jälkeen, väärä digest
  (`APPROVAL_MISMATCH`), **manipuloitu manifesti → uudelleenlaskettu digest
  (`MANIFEST_DIGEST`)**, **väärä BatchId (`BATCH_ID_CORRELATION`)**, **väärä
  ajokorrelaatio (`RUN_CORRELATION`)**, vaarallinen polku, hard-deny-kohde,
  linkki/junction, puuttuva kuitti, ei-tuettu muoto (LEGACY), duplikaatti
  map-lähde, duplikaatti manifest-rivi, kohdetörmäys, keskeneräinen map,
  olemassa oleva kuitti (`RECEIPT_EXISTS`), **kuitti kohderepositorion sisällä
  (`RECEIPT_INSIDE_TARGET`)**, **tarkastuksen jälkeen syntyvä kuitti säilyy
  ennallaan (`RECEIPT_EXISTS`)**, **kuitti linkin kautta (`LINK_REJECTED`/
  `REPARSE_REJECTED`/`RECEIPT_INSIDE_TARGET`)**, ylisuuri olemassa oleva kohde
  (`CONFLICT`), payloadin exact-set, esi-isän vaihtuminen (`PARENT_CHANGED`, ei
  kuittia), keskeytys (osittainen tila, ei kuittia), kuitin julkaisuvirhe (ei
  kuittia), v2-digestin sidonta karttaan, **POSIX-ankkuri (ei `/`) ja lukija joka
  ei avaa juurta (POSIX-only; ajetaan Termuxilla)**. **Siirron `VERIFIED`-kuitti
  pysyy muuttumattomana.**

**Tila (eritelty alustoittain ja versioittain):**

- **Windows (korjattu versio):** 44 ajettu, **36 PASS, 8 SKIP, ei FAIL/ERROR**.
- **Termux (aiempi versio):** 43 PASS, 0 FAIL, 0 SKIP.
- **Synteettinen Linux:** 44 ajettu, **43 PASS, 1 Windows-kohtainen SKIP**.
- **Uuden toimituscommitin Termux-regressio ja GitHub-CI: PENDING.**

Riippumaton katselmointi (SOUND) on tehty nykykorjaukselle. Oikean aineiston
sijoitusta ei ole valtuutettu.

## 7. Palautumisohje

| Tilanne                 | Tunniste                                | Toimenpide                                                                                                                                                                  |
| ----------------------- | --------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Preflight-esto          | SSH/host-key/runtime ei täsmää          | Älä käynnistä siirtoa. Tarkista virta, uni, verkko, SSH-palvelu, tunnistautuminen ja host-key **muuttamatta** turva-asetuksia automaattisesti.                              |
| Katkos ennen yhteyttä   | Yhteyttä ei muodostu                    | Vastaanottoa ei tapahdu; lähteet eivät muutu. Yritä uudelleen uudella `run_id`:llä valtuutuksen jälkeen.                                                                    |
| Katkos kesken siirtoa   | Osittainen ajo / ei `VERIFIED`          | Säilytä ajo, `wire.tar`/staging ja `UNVERIFIED.json`. Ei automaattista retryä tai poistoa. Uusi yritys = uusi `run_id`.                                                     |
| Puuttuva `VERIFIED`     | Kuittia ei synny                        | Hylätty/keskeytynyt ajo. Tarkasta ajo read-only ennen ihmisen päätöstä.                                                                                                     |
| Epävarma kestävyys      | `LOCAL_VERIFIED_DURABILITY_UNCONFIRMED` | Sisältö on paikallisesti varmennettu mutta julkaisun crash-durability epävarma. Näkyvää `VERIFIED.json`ia ei poisteta; best-effort `PUBLICATION_UNCERTAIN.json`. Ei retryä. |
| Kohdetörmäys (sijoitus) | `CONFLICT`                              | Pysähdy. Eri sisältöä ei ylikirjoiteta.                                                                                                                                     |
| Osittainen sijoitus     | osa kohteista luotu                     | Raportoi osittaisena; ei rollbackia, poistoa eikä automaattista uusintaa.                                                                                                   |

Säilytä kaikki epäonnistuneet ajot ja evidenssi.

## 8. Paikkamerkit ja työjuuret

Portable-ohje käyttää nimettyjä paikkamerkkejä. **Paikalliset absoluuttiset polut
ja runtime-arvot pidetään Gitin ulkopuolisessa konfiguraatiossa.**

| Paikkamerkki                                                           | Merkitys                                                             |
| ---------------------------------------------------------------------- | -------------------------------------------------------------------- |
| `$SourceRoot`                                                          | Varmennettu lähdecheckout (git-toplevel, origin-identiteetti täsmää) |
| `$BatchRoot`                                                           | Yksityinen batch-juuri (repositoryjen ulkopuolella)                  |
| `$Profile`                                                             | Paikallinen profiili (täsmävalinnat)                                 |
| `$StagingRoot`                                                         | Yksityinen 0700 staging `$HOME`:n alla (pull)                        |
| `$BatchId`, `$Digest`, `$RunId`                                        | Ajokohtaiset tunnisteet                                              |
| `FOF_V2_SSH_ALIAS`, `FOF_V2_RECEIVER_SCRIPT`                           | outbound v2 runtime                                                  |
| `FOF_KB_SSH_ALIAS`, `FOF_KB_REMOTE_SCRIPT`, `FOF_KB_REMOTE_BATCH_ROOT` | pull runtime                                                         |

Työjuuri: komennot ajetaan `Fear-of-Falling`-juuresta, ellei toisin mainita.

## 9. Validoinnin tila

- Tämä runbook on **katselmoitavissa**; se ei aktivoi tuotantoa eikä siirrä oikeaa aineistoa.
- Sijoitus (osio 6) on **toteutettu** (`scripts/termux/place_verified_bundle.py`,
  molemmat vastaanottomuodot). Validointi alustoittain: Windows 44 ajettu
  (36 PASS, 8 SKIP, ei FAIL/ERROR); aiempi Termux-versio 43 PASS; synteettinen
  Linux 44 ajettu (43 PASS, 1 Windows-kohtainen SKIP). Uuden toimituscommitin
  Termux-regressio ja GitHub-CI: **PENDING**; ei Git-toimitusta tai oikeaa
  aineistoa ennen näitä.
- Synteettinen validointi ja Termux-tarkistus: ks. tehtäväkortti
  `tasks/03-review/BIDIRECTIONAL_LOCAL_FILE_TRANSFER_RUNBOOK.md`.
