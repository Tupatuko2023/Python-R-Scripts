# Windows → Termux: varmennettu KB-nouto

## Rajaus ja tila

Toteutus käyttää erillistä `FOF_KB_PULL/1`-sopimusta. Termux avaa nykyisen
SSH-yhteyden Windowsiin. Windows valmistaa täsmävalinnan ja tarjoaa hyväksytyn
snapshot-erän binäärisenä USTAR-virtana; Termux tarkastaa sen uuteen yksityiseen
staging-ajoon. Vastaanotto ei tuo mitään repositoryyn.

Nykyisen LEGACY/1- ja FOF_ARTIFACT_HANDOFF/2-kanavan koodia, A4-profiileja tai
rekistereitä ei muuteta. Niiden hyväksynnät eivät kelpaa tähän kanavaan.
KB tarkoittaa tietopohjatiedostoja, ei tietokantaa.

Tila: **PARTIAL, paikallinen toteutus katselmoitavissa**. Windowsin Python,
Windowsin tiedostolukitushaara, PowerShell-binäärisilta, Termux-laite ja todellinen
SSH-smoke ovat **NOT RUN / UNVERIFIED**. Paikallinen Linux-prosessitesti ei ole
Windows → Termux -verkkotesti. Tuotantoprofiili `docs/transfer-profiles/kb-pull-documents-1.json` on suljettu.

## Riippuvuudet ja toimitus

Sama Git-versionoitu `scripts/termux/fof_kb_pull.py` ajetaan molemmissa päissä
Python-R-Scripts/Fear-of-Falling-juuresta. Se käyttää vain Pythonin standardikirjastoa.
Windowsissa pitää olla olemassa toimiva Python 3.9+ komennolla `python` myös
SSH-palvelimen käyttäjän PATHissa. Windowsin nykyistä PowerShellia käytetään
vain .NET Processin raakaan binäärivirtaan, ei tekstiputkitukseen. Termux käyttää
Python 3.9+:aa, POSIX-tiedostotilaa ja nykyistä OpenSSH-asiakasta.

Python-R-Scriptsin dokumentaatio kuvaa Python-runtimea, mutta se ei todista
Windows-laitteen asennusta. Jos `python` ei toimi Windowsissa, pysähdy. Tässä
tehtävässä ei ole asennuslupaa. FOF-Dissertation-Projectiin ei lisätä koodikopiota
ja sen submodulea ei muokata. Windowsin lähdevalinta voi käyttää erikseen
varmennettua FOF-Dissertation-Project-checkoutia.

Koodi toimitetaan molempiin päihin vasta hyväksytyn Git-kanavan kautta.
Tämä työ ei pushannut, committannut, mergennyt eikä siirtänyt koodia SSH-payloadina.
Git-toimitus on käyttöönoton avoin riippuvuus.

## Sopimus

Portable-profiilin avaimet ovat `protocol`, `profile_id`, `enabled`,
`source_repository_id` ja `files`. Runtime-asetukset eivät kuulu siihen.
Tuotantoidentiteetti on `kb-pull-documents-1`; synteettinen identiteetti on
`kb-pull-synthetic-1` ja tarvitsee `--synthetic-test`-lipun kummassakin preview-
ja pull-kutsussa. Testit eivät aktivoi tuotantoa.

Jokainen files-rivi sisältää `source_path`, `staging_path`,
`classification=DISTRIBUTABLE_AS_IS` ja `approval_reference`.
Kaikki polut ovat suhteellisia ASCII-täsmäpolkuja. Globs, traversal, absoluuttiset
payload-polut, varatut Windows-nimet sekä case- ja hakemistoprefiksitörmäykset
hylätään. Hard deny ohittaa valinnan: data/participants/salaisuudet/avaimet,
tietokannat, lähdekoodi, CSV, taulukkolaskenta-aineistot ja arkistot hylätään.
Tiedostopääte, `.gitignore` ja Git-tracking eivät anna lupaa. Luokitus ja
hyväksyntäviite ovat erikseen valittujen julkaisukelpoisten tavujen lupatietoja,
eivät ohjelmallinen sisältöanalyysi tai osallistujadatan tunnistus.

Rajana on 100 tiedostoa, 16 MiB/tiedosto, 64 MiB yhteensä ja 66 MiB wire.
Noudon kokonaisaikaraja on 120 sekuntia. Ei retryä tai resumea.

Manifesti sitoo profiilidigestin, lähderepositoryn identiteetin, Git HEADin,
täsmäpolut, hyväksyntäviitteet, snapshotien tavukoot ja SHA-256:t.
`content_digest` lasketaan canonical ASCII JSONista avainjärjestyksellä ja
ilman ajokohtaista batch_id:tä. Samat tavut tuottavat saman sisältödigestin.
Batch_id ja Termuxin run_id ovat erillisiä tunnisteita.

Preview luo Windowsiin uuden paikallisen snapshot-erän eikä avaa verkkoa.
Approve ei snapshottaa uudelleen. Se tarkastaa alkuperäisen lähteen, HEADin,
erän exact-setin, snapshotit ja preview-digestin. Serve tarkastaa ne uudelleen
ja materialisoi rajatun kokonaisen binäärivirran ennen ensimmäistä stdout-tavua.
Lähde- tai snapshot-muutos hylätään. Vastaanotto tarkastaa hyväksytyn digestin,
profiilin, raakatason USTAR-otsakkeet, exact-setin sekä lopulliset tavut.

Windowsin tiedosto- ja ancestor-handlet estävät write/delete-sharingin ja
hylkäävät reparse-pointit. Linuxissa käytetään descriptor-walkia ja O_NOFOLLOWia.
Runtime-juuret ovat luotettuja, vain käyttäjän hallitsemia hakemistoja.
Samalla käyttäjätilillä toimivaa vihamielistä prosessia tai jatkuvaa runtime-juuren
korvaamista ei pidetä tuettuna uhkamallina. Windowsin yksityinen ACL pitää
varmentaa operaattorin toimesta; Termuxissa vastaanottojuuren pitää olla
$HOME:n alla, käyttäjän omistama ja mode 0700. Ei /sdcardia.

## Operaattorin synteettinen testipolku

Ensin hyväksy ja toimita katselmoitu koodi Git-kanavassa. Varmenna työjuuret
molemmissa päissä. Älä käytä tuotantodokumentteja alla olevaan smokeen.

[WINDOWS:POWERSHELL]

```powershell
Get-Location
python --version
git -C $SourceRoot rev-parse --show-toplevel
git -C $SourceRoot rev-parse HEAD
```

Määrittele paikallisesti `$SourceRoot` varmennetuksi lähdecheckoutiksi,
`$BatchRoot` repositoryjen ulkopuoliseksi yksityiseksi, jo olemassa olevaksi
Windows-hakemistoksi ja `$Profile` paikalliseksi testiprofiiliksi. Älä commitoi
niiden absoluuttisia arvoja. Varmenna SourceRootin `origin`-identiteetti.

Luo vain itse tuotetut `docs/KB_PULL_SYNTHETIC/a.md` ja
`docs/KB_PULL_SYNTHETIC/b.bin` lähdecheckoutiin. Teksti sisältää UTF-8-ääkkösiä
ja molempia rivinvaihtoja; binääri kaikki tavuarvot. Jätä ne untracked/local-only.
Esimerkiksi olemassaolevalla Pythonilla:

[WINDOWS:POWERSHELL]

```powershell
@'
import os
from pathlib import Path
root = Path(os.environ['FOF_KB_SYNTHETIC_SOURCE_ROOT'])
p = root / 'docs/KB_PULL_SYNTHETIC'
p.mkdir(exist_ok=False)
(p / 'a.md').write_bytes('Synteettinen: \u00e4\u00f6\r\nLF\n'.encode('utf-8'))
(p / 'b.bin').write_bytes(bytes(range(256)) * 100)
'@ | python -
```

Aseta ympäristöarvo `FOF_KB_SYNTHETIC_SOURCE_ROOT` samaksi varmennetuksi
SourceRootiksi ennen tätä komentoa. Tee `$Profile`:iin seuraava paikallinen
JSON ja toimita sen sama tavukopio Termuxin paikalliseen konfiguraatioon
operaattorin hyväksymällä tavalla ennen payload-noutoa. Tämä on vain
synteettinen testiprofiili, ei tuotantolupa.

```json
{
  "protocol": "FOF_KB_PULL/1",
  "profile_id": "kb-pull-synthetic-1",
  "enabled": true,
  "source_repository_id": "FOF-Dissertation-Project",
  "files": [
    {"source_path": "docs/KB_PULL_SYNTHETIC/a.md", "staging_path": "kb/a.md", "classification": "DISTRIBUTABLE_AS_IS", "approval_reference": "OWNER-synthetic-test-only"},
    {"source_path": "docs/KB_PULL_SYNTHETIC/b.bin", "staging_path": "kb/b.bin", "classification": "DISTRIBUTABLE_AS_IS", "approval_reference": "OWNER-synthetic-test-only"}
  ]
}
```

Jos lähde on Python-R-Scripts, vaihda vain oikea source_repository_id.
Git-remote ja Git-toplevel tarkastetaan koodissa, source-root ei saa olla subfolder.

[WINDOWS:POWERSHELL]

```powershell
python scripts/termux/fof_kb_pull.py preview --synthetic-test --source-root $SourceRoot --profile $Profile --batch-root $BatchRoot
```

Tarkasta preview-manifestin täsmäpolut, luokitus, provenance, tavukoot ja SHA-256.
Ota talteen sen `batch_id` ja `content_digest` paikallisiin `$BatchId` ja `$Digest`
muuttujiin. Hyväksy vain juuri tarkastettu digest:

[WINDOWS:POWERSHELL]

```powershell
python scripts/termux/fof_kb_pull.py approve --batch "$BatchRoot/$BatchId" --approved-content-digest $Digest
```

Termuxissa nykyinen luotettu SSH-alias on runtime-muuttujassa `FOF_KB_SSH_ALIAS`.
`FOF_KB_REMOTE_SCRIPT` on Git-toimitetun scriptin varmennettu Windows-polku
forward-slash-muodossa. `FOF_KB_REMOTE_BATCH_ROOT` on sama BatchRoot.
Polut eivät sisällä shell-metamerkkejä. Ei uusia avaimia tai host keyn hyväksyntää.

Varmenna nykyinen known_hosts ja olemassaoleva konfiguraatio. Seuraava preflight
käyttää samaa aliasia, tarkastaa Windowsin `python`-komennon palvelinkäyttäjälle
eikä lähetä payloadia. Jos host ei ole jo tunnettu, pysähdy.

[TERMUX]

```bash
pwd
ssh -T -o BatchMode=yes -o StrictHostKeyChecking=yes -o ConnectionAttempts=1 -o ConnectTimeout=10 -o ClearAllForwardings=yes -o PermitLocalCommand=no "$FOF_KB_SSH_ALIAS" 'python --version'
```

Ole foreground-Termuxissa. Aseta `$Profile`, `$Digest`, `$BatchId` ja
`$StagingRoot` paikallisesti. StagingRoot on uusi/olemassaoleva yksityinen
0700-hakemisto $HOME:n alla ja repositoryjen ulkopuolella. Valitse uusi RunId:

[TERMUX]

```bash
RunId="$(date -u +%Y%m%dT%H%M%SZ)-$(python -c 'import uuid; print(uuid.uuid4().hex)')"
python scripts/termux/fof_kb_pull.py pull --synthetic-test --profile "$Profile" --batch-id "$BatchId" --approved-content-digest "$Digest" --staging-root "$StagingRoot" --run-id "$RunId"
```

Puuttuva hyväksyntädigest tai suljettu profiili pysäyttää ennen payload-noutoa.
Tarkasta `$StagingRoot/$RunId/VERIFIED.json` ja lopullisten payload-tiedostojen
hashit read-only. Vertaa batch_id, run_id, content_digest ja file_count.
Onnistunut todellinen SSH-smoke kirjataan erikseen vasta tämän jälkeen.
Taustatila/näytön lukitus on eri testi, eikä akkuasetuksia muuteta automaattisesti.

## Kuitti ja palautuminen

Vasta tiedostojen sulkemisen, fsyncin ja kaikkien tarkastusten jälkeen julkaistaan
atominen `VERIFIED.json`. Se sisältää run_id:n, batch_id:n, sisältödigestin,
tiedostomäärän ja UTC-ajan. Se on paikallinen Termux-varmennus.
`return_receipt_status=NOT_DELIVERED` tarkoittaa, ettei paluukuittia ole toimitettu
Windowsille. Kanava ei väitä Windows-kuittausta onnistuneeksi eikä toimita sitä
automaattisesti. Puuttuva paluukuitti ei käynnistä uutta noutoa.

Katkos, aikaraja tai hylkäys säilyttää ajon, wire.tar:n ja UNVERIFIED.jsonin.
SSH:n raakadiagnostiikka hylätään; kuittiin ei tallenneta payloadia tai salaisuuksia.
Ennen kuitin julkaisua tapahtuva virhe ei tuota VERIFIED-kuittia. Jos rename
onnistui mutta sen jälkeinen directory-fsync epäonnistui, sisältö on paikallisesti
varmennettu mutta julkaisun crash-durability jää epävarmaksi. Komento päättyy
nonzero-tilaan `LOCAL_VERIFIED_DURABILITY_UNCONFIRMED`. Näkyvää VERIFIED.jsonia
ei poisteta eikä sen rinnalle luoda ristiriitaista UNVERIFIED-kuittia.
Best-effort `PUBLICATION_UNCERTAIN.json` kertoo epävarmuudesta; myös sen tallennus
voi epäonnistua vioittuneessa tiedostojärjestelmässä. Pelkkä näkyvä VERIFIED-kuitti
ei tässä virhetilanteessa todista onnistunutta kestävää julkaisua. Ei retryä. Tarkasta yksilöity ajo read-only ennen ihmisen
jatkopäätöstä. Uusi yritys tarvitsee uuden run_id:n; ei overwritea, vanhan ajon
uudelleenkäyttöä, automaattista poistoa tai retryä. Tuonti on erillinen valtuutus.

## Paikallinen testinäyttö

Aja Fear-of-Falling-juuresta:

```bash
PYTHONDONTWRITEBYTECODE=1 python -W error::ResourceWarning -m unittest discover -s tests -p test_kb_pull.py -v
PYTHONDONTWRITEBYTECODE=1 python -m unittest discover -s tests -p test_artifact_transfer.py -v
PYTHONDONTWRITEBYTECODE=1 python -m unittest discover -s tests -p test_v2_ssh_adapter.py -v
```

Inbound-testit käyttävät itse tuotettuja tiedostoja ja paikallisia Python-prosesseja.
Source Git-provenance on fixtureissä mockattu; erillinen testi tarkastaa oikean
public-checkoutin HEAD/remote-identiteetin ja väärän identiteetin hylkäyksen.
Ne eivät testaa Windowsin ctypes-reparse-lukitusta tai oikeaa SSH-palvelinta.
Outbound-regressiot tarvitsevat ennestään asennetun `jsonschema`-riippuvuuden;
receiver-integraatiot tarvitsevat olemassaolevan PowerShellin ja provenancen sitoman
vastaanotinsnapshotin. Puuttuvia riippuvuuksia ei asenneta tämän tehtävän aikana.
K18/QC: NOT APPLICABLE, muutos koskee vain synteettistä tiedostokuljetusta.

## Jatkokatselmoinnin näyttö ja Git-toimituspaketti

Jatkokatselmoinnin jälkeen paikallisia inbound-testejä on 34 PASS. Windowsin
open_osfhandle- ja fdopen-virhepolut testattiin Linuxissa mockatuilla API:lla;
tämä todistaa handle-omistuksen virhepolun, ei todellista Windows-lukitusta.
Fsync failure injection testaa ennen ja jälkeen kuitin julkaisun syntyvät tilat.
Outbound-regressiot ovat edelleen NOT RUN, koska valmiista Python-runtimesta
puuttuu jsonschema. Ei asennuksia tai regressiopassin väitettä.

Tämän suoritusympäristön ssh executable löytyy, mutta FOF_KB- ja FOF_V2-runtime-
asetukset eivät ole asetettuja eikä SSH configia tai known_hostsia ole.
Siksi Windows-yhteyttä ei kokeilla muistissa olevan isäntänimen perusteella.
Seuraava verkkotesti kuuluu käyttäjän olemassaolevaan Termux-ympäristöön.

Toimituksen base HEAD on `a62957e9e77d3eedc33c1d18395be0bc26c017dc`.
Toimituksen täsmäpolut ovat:

| Liitteen polku | Kohde Python-R-Scripts-repositoryssa |
| --- | --- |
| Fear-of-Falling/scripts/termux/fof_kb_pull.py | sama suhteellinen polku |
| Fear-of-Falling/tests/test_kb_pull.py | sama suhteellinen polku |
| Fear-of-Falling/docs/transfer-profiles/kb-pull-documents-1.json | sama suhteellinen polku |
| Fear-of-Falling/docs/WINDOWS_TERMUX_PULL.md | sama suhteellinen polku |
| tasks/02-in-progress/WINDOWS_TERMUX_VERIFIED_PULL.md | sama suhteellinen polku |

Windowsin paikallinen agentti lukee liitteet ensin erilliseen tarkastushakemistoon
ja vertaa SHA-256:t toimituksen manifestiin. Se tarkastaa nykyisen checkoutin
AGENTS-, SKILLS- ja steering-ohjeet, HEADin, branchin ja koko Git-tilan.
Jos base HEAD eroaa tai jokin kohdepolku on jo olemassa/muuttunut, agentti
katselmoi eron ja pysähtyy ennen kirjoituksia. Ei automaattista overwritea.
Taskin SHA-256 ei sisälly omaan tekstiinsä; kaikkien viiden tiedoston lopulliset
hashit toimitetaan erillisessä raportissa. Tämä ohje valmistelee toimituksen,
ei suorita git apply-, commit-, push- tai merge-toimia.

[WINDOWS:POWERSHELL]

```powershell
Get-Location
git rev-parse --show-toplevel
git rev-parse HEAD
git status --short --untracked-files=all
Get-FileHash -LiteralPath $AttachmentFile -Algorithm SHA256
```

Käyttöönotossa toimitus kuuluu hyväksyttyyn Git-kanavaan. SSH-payload ei kuljeta
versionoitua toteutuskoodia. Task pysyy PARTIAL / 02-in-progress, kunnes
regressio-DoD ja operaattorin todellinen synteettinen verkkotesti on varmennettu.

## QFOT2:n CSV-metadata: erillinen soveltuvuusraja

Python-R-Scriptsin tarkastetusta checkoutista löytyvät täsmänimet
`Quantify-FOF-Utilization-Costs/metadata/VARIABLE_STANDARDIZATION.csv` ja
`Quantify-FOF-Utilization-Costs/metadata/data_dictionary.csv`. Tässä jatkotyössä
niistä tarkastettiin vain sijainti, ei sisältöä tai siirtokelpoisuutta.
Ne voivat olla koko KB:n siirtotarpeen kannalta relevantteja, mutta nykyinen
kanava hylkää kaikki CSV:t hard-deny-säännöllä. Tämä työ ei avaa CSV-poikkeusta.

FOF-Dissertation-Projectin current main-tree tarkastettiin read-only connectorista
(sha `7e868e6f6b8403df968a0118a17eafd84aa905b4`, recursive truncated=false).
Siinä ei löytynyt QF-agents-termux-/QFOT2-polkuja tai näitä CSV-tiedostonimiä.
Koko QFOT2:n KB-kokonaisuutta ei näin varmennettu. Tarkastetut main-snapshotit
eivät todista paikallisen Windows-worktreen tai lisäosapaketin nykyistä sisältöä.
Täsmäpolkujen/sisältöluokitusten erillinen inventointi tarvitaan ennen koko KB:n
siirron valtuutusta. `.csv`-kielto säilyy.
