# FOF-artefaktien siirto Termuxista Windowsiin

Tämä dokumentti omistaa normatiivisen FOF_ARTIFACT_HANDOFF/2-sopimuksen.
Vaiheen 6 pysyvän toteutuksen Windows-SSH-smoke on PASS (2026-09-14).
Tuotannon A4-siirto ei ole aktivoitu. Alla on v2-operaattorin pikapolku;
LEGACY/1 ja normatiivinen v2-sopimus ovat erillisinä lukuina sen jälkeen.

## Operaattorin pikapolku — v2, Termux → Windows

Yksisuuntainen, ihmisen käynnistämä **tar-over-SSH**, ei rsync tai taustasynkka.
[SSH-sovitin](../scripts/termux/fof_v2_ssh_adapter.py) täydentää nykyisen
senderin `--local-receiver`-rajapinnan; se ei ole toinen siirtomoottori.

Kertaluonteiset edellytykset: Termux Bash, Python 3.9+, Git ja OpenSSH-asiakas;
Windows päällä/hereillä, OpenSSH Server saavutettavissa, PowerShell 7.4+ ja
Git-kanavasta asennettu dissertation-receiver sekä sen rekisteri. Receiverin
staging-alueella tarvitaan kirjoitusoikeus ja riittävä levytila; pakettiraja
on 1 GiB. Saman Wi-Fi/LAN-verkon käyttö on tavallisesti helpointa, mutta
vaatimus on luotettu SSH-saavutettavuus, ei sama WLAN. Windows ei tarvitse
rsynciä eikä erillistä tar-ohjelmaa.

1. **Aseta luotettu runtime-konfiguraatio.** `FOF_V2_SSH_ALIAS` nimeää käyttäjän
   ennakkoon määrittelemän SSH-aliasin. Host/user/port/key-valinta jää käyttäjän
   SSH-konfiguraatioon, ei profiiliin tai Git-tiedostoihin.
   `FOF_V2_RECEIVER_SCRIPT` on Windowsin absoluuttinen drive-polku käyttäen `/`
   erottimia, loppuna `/scripts/ps7/receive_artifact_bundle.ps1`. Sallitut segmentit
   sisältävät ASCII-kirjaimia, numeroita, välilyöntejä ja `_.-`; ei UNC-,
   backslash-, traversal-, lainausmerkki-, shell- tai ympäristölaajennuksia.
   Segmentin reunavälilyönnit, loppupiste ja Windowsin laitenimet hylätään.
   SSH-tunnistautumisen tulee olla ei-interaktiivinen ja host key erikseen
   varmennettu etukäteen. Sovitin ei asenna avaimia tai hyväksy uusia host keyitä.
2. **Tarkista yhteys ilman artefakteja.** Aja FOF-juuressa:
   `python3 scripts/termux/fof_v2_ssh_adapter.py --check`.
   Tämä avaa SSH-yhteyden ja tarkistaa PowerShell-version, TarReaderin ja
   receiver-tiedoston olemassaolon; stdin ohjataan tyhjäksi eikä receiveriä ajeta.
   Tarkistus ei aktivoi rekisteriä eikä korvaa siirron hyväksyntää.
3. **Valitse hyväksytty profiili ja preview.** Normaali ensimmäinen komento:

   ```bash
   bash scripts/termux/export_artifacts_to_windows.sh --profile config/artifact-transfer/a4-general-fi.json
   ```

   Nykyinen profiili on **EMPTY_NOT_EXECUTABLE**: files ja Windowsin
   sisältöhyväksynnät ovat tyhjiä. Oikean profiilin aktivointi on erillinen
   hyväksytty tehtävä. Aktiivisen profiilin previewsta tarkastetaan täsmäpolut,
   staging-nimet, koot, SHA-256, lähde-HEAD ja content_digest. `.gitignore` ei
   anna siirtolupaa; hard deny ohittaa hyväksyntälistan. Uusi/muuttunut tiedosto
   tarvitsee hyväksytyn hashin ja approval_reference-viitteen; CSV lisäksi oman
   täsmäpolku/hyväksyntäviitteensä. Rekisterin profiili- ja sisältödigestien
   tulee vastata hyväksyntää. Preview ei käynnistä SSH:ta edes adapteri annettuna.

4. **Execute vain erikseen hyväksytylle sisällölle.** Seuraava on käyttömalli,
   ei lupa nykyisen tyhjän profiilin aktivointiin. `APPROVED_CONTENT_DIGEST`
   tarkoittaa ihmisen tarkastaman previewn digestia:

   ```bash
   bash scripts/termux/export_artifacts_to_windows.sh \
     --profile config/artifact-transfer/a4-general-fi.json \
     --execute --approved-content-digest "$APPROVED_CONTENT_DIGEST" \
     --local-receiver "$(pwd -P)/scripts/termux/fof_v2_ssh_adapter.py"
   ```

   Sovittimen executable-bit pitää säilyttää asennuksessa. V2 ei käytä
   LEGACY/1:n `WINDOWS_*`-muuttujia. Älä käytä smokelippuja tuotannossa.

5. **Tarkista kuitti.** SUCCESS/0 vaatii korreloidun VERIFIED-vastauksen ja
   onnistuneen prosessin. FAILED/1 tarkoittaa paikallista hylkäystä tai
   korreloitua vastaanottimen hylkäystä. UNKNOWN_REMOTE_STATE/3 vaatii käsin
   read-only-tarkastuksen; yhteysvirhettä ei keksitä korreloiduksi FAILEDiksi.
   Receiverin asennusrepon alla on
   `artifacts/staging/fof-dissertation-local-handoff/incoming/<run_id>/`,
   jossa ovat `files/`, `manifest.json` ja kokonaisonnistumisen `VERIFIED.json`.
6. **Tarkasta ja tuo tarvittaessa käsin.** VERIFIED todistaa teknisen eheyden,
   ei julkaisuhyväksyntää. Ei automaattista importia, Git-toimia, poistoja,
   overwritea, retryä tai vanhojen ajojen siivousta.

PC pois päältä / SSH saavuttamattomissa ennen yhteyttä: vastaanottoa ei tapahdu,
lähteet eivät muutu. Tarkista virta, uni, verkon reititys, SSH-palvelu,
tunnistautuminen ja host-key-luottamus muuttamatta turva-asetuksia automaattisesti.
Myöhäinen katkos on eri asia: ajo voi olla osittainen tai jo VERIFIED. Säilytä
paikallinen paketti ja etäajo; tarkista run_id, manifesti, exact-set, koot/hashit
ja kuitti ennen uutta päätöstä. Uusi valtuutettu yritys saa uuden run_id:n.
Väärä receiver-polku/versio korjataan konfiguraatiossa erillisellä luvalla;
virheellinen profiili/hash korjataan hyväksyntäprosessissa, ei ohittamalla porttia.

Sovitin on riittävä lisäkomento; toista convenience-wrapperia ei tarvita.
Se validoi asetukset ennen stdin-lukua, korvaa prosessinsa `ssh`:lla ja säilyttää
binäärisen stdin/stdout-virran sekä exit-koodin. SSH käyttää `-T`, BatchMode=yes,
StrictHostKeyChecking=yes, ConnectionAttempts=1, ConnectTimeout=10,
ClearAllForwardings=yes ja PermitLocalCommand=no. Diagnostiikka on stderrissä;
JSONia, manifestia tai taria ei muokata. Sender omistaa 60 sekunnin kokonaisrajan
ja vastauksen tulkinnan. Sovitinta ei tule kutsua suoraan payloadilla: execute-
ja sisältöhyväksyntäportti on aina senderissä.

Vain erikseen hyväksytyssä synteettisessä smokessa `FOF_V2_SMOKE_SESSION`
asetetaan uudeksi 32-merkkiseksi lowercase hex -tunnisteeksi. Se lisää receiverin
`-SmokeTest -SmokeSession`-argumentit; sender tarvitsee erikseen `--smoke-test`
ja testi-identiteetin. Testirekisteri sidotaan sessioon ja synteettiseen digestiin;
tuotantorekisteriä ei muuteta. Tuotantokutsussa poista `FOF_V2_SMOKE_SESSION` ympäristöstä; tyhjä muuttuja
käyttää normaalia receiver-kutsua.

## LEGACY/1 — säilyvä allow-list-käyttö

Tämä osuus kuvaa alkuperäistä versionumeroimatonta siirtototeutusta. Analyysikoodi
kulkee nykyisessä Git-/submodule-kanavassa. Erikseen hyväksytyt käsikirjoitus-
ja tulosartefaktit kulkevat allow-listan, paikallisten tarkistusten ja
USTAR-over-SSH-siirron kautta Windowsin ajokohtaiseen staging-hakemistoon.
Väitöskirjaan tuonti tehdään myöhemmin käsin.

Toteutustiedostot:

- [Allow-list](../config/artifact-transfer.allowlist)
- [Termux-lähettäjä](../scripts/termux/export_artifacts_to_windows.sh)
- [PowerShell-vastaanotin](../scripts/ps7/receive_artifact_bundle.ps1)

## Edellytykset ja ajonaikaiset asetukset

Termuxissa tarvitaan Bash, `python3` (Python 3.9 tai uudempi, vakiokirjasto)
ja execute-ajoon OpenSSH-asiakas `ssh`. Lähettäjä käyttää POSIX-tiedostokahvoja
ja `O_NOFOLLOW`-tarkistuksia. Se on tarkoitettu Termux-/Linux-ympäristöön.
Esikatselu ei tarvitse Windows-yhteysasetuksia.

Windowsissa tarvitaan toimiva OpenSSH Server, PowerShell 7.4 tai uudempi
(`pwsh` etäkomennon komentopolussa) sekä saman toteutusversion
`receive_artifact_bundle.ps1` Windows-checkoutissa. Vastaanotinskripti
hankitaan nykyisen Git-kanavan kautta; artefaktilähettäjä ei asenna sitä.
Arkisto muodostetaan Pythonin vakiokirjastolla ja luetaan vastaanottoskriptissä.
Erillistä tar-ohjelmaa tai Windowsin rsynciä ei tarvita.

Aseta seuraavat muuttujat Termux-prosessin ympäristöön ennen execute-ajoa.
Taulukko ei sisällä todellisia yhteysarvoja; niitä ei tallenneta repositoryyn.

| Muuttuja                  | Merkitys ja nykyinen rajaus                                                                                                                 |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| `WINDOWS_HOST`            | Käyttäjän antama DNS-nimi tai IPv4-osoite; nykyinen nimivalidointi ei tue IPv6-literaaleja.                                                 |
| `WINDOWS_USER`            | Käyttäjän antama yksinkertainen SSH-tilin nimi: kirjaimet, numerot, alaviiva, piste ja yhdysmerkki; alussa kirjain, numero tai alaviiva.    |
| `WINDOWS_STAGING_DIR`     | Vastaanottokoneen olemassa oleva, absoluuttinen staging-juuri, johon tilillä on kirjoitusoikeus.                                            |
| `WINDOWS_RECEIVER_SCRIPT` | Vastaanottokoneen polku saman version `receive_artifact_bundle.ps1`-tiedostoon; käytä absoluuttista polkua. Myös tämä asetus on pakollinen. |

SSH käyttää `BatchMode=yes`- ja `StrictHostKeyChecking=yes`-asetuksia.
Toimivan ei-interaktiivisen tunnistautumisen ja hyväksytyn palvelintunnisteen
pitää olla valmiina. Skripti ei kysy salasanaa tai hyväksy tuntematonta
palvelintunnistetta automaattisesti. Verkkotoimi edellyttää repositoryn
lupakäytäntöjen mukaista valtuutusta; tämä käyttöohje ei itsessään anna sitä.

Vastaanotinskriptin, staging-juuren ja niiden ylähakemistojen tulee olla
luotettuja ja suojattuja muiden toimijoiden samanaikaisilta kirjoituksilta.
Vastaanotin hylkää havaitut reparse point -polut. Staging-juuri valmistellaan
ennen ajoa; vastaanotin luo sen alle `incoming`-hakemiston.

Lähettäjä säilyttää execute-ajon paikallisen paketin ja snapshotit Pythonin
väliaikaishakemistossa, jonka on oltava FOF-juuren ulkopuolella. Varaa levytilaa
sekä lähdekopioille että tar-paketille. Nykyinen lähettäjä hylkää yli 1 GiB:n
paketin ennen SSH:ta. Vastaanottimen oletusraja on myös 1 GiB ja metatiedoston
raja 16 MiB. Suurempien pakettien käsittely ei kuulu tähän ajopolkuun.

## 1. Hyväksy siirrettävä sisältö allow-listaan

Oletustiedosto on `config/artifact-transfer.allowlist`. Se sisältää aluksi
vain kommentteja: **default deny**, ei siirrettäviä tiedostoja. Lisää sääntö
vasta paikallisen inventaarion ja sisällön hyväksynnän jälkeen. Tiedostopääte
tai output-hakemisto ei todista, että sisältö on turvallista aggregaattitulosta.
Osallistujatietoja tai raakadataa ei hyväksytä siirtoon.

Allow-list on UTF-8-tekstiä, yksi sääntö rivillä:

| Syntaksi                         | Toiminta                                                                                                 |
| -------------------------------- | -------------------------------------------------------------------------------------------------------- |
| `file POLKU`                     | Täsmällinen FOF-juureen suhteellinen tiedostopolku.                                                      |
| `glob HAKEMISTO/KUVIO`           | Hakemistopolku on kirjaimellinen; vain viimeisessä polkuosassa sallitaan `*`, `?` ja `[abc]` / `[!abc]`. |
| Tyhjä rivi tai `#`-alkuinen rivi | Ohitetaan.                                                                                               |

Rekursiivista `**`-kuviota, shell-laajennuksia, lainausmerkkisyntaksia tai
rivin sisäisiä kommentteja ei tueta. Polun sisäiset välilyönnit säilyvät;
alussa tai lopussa olevat välilyönnit hylätään. Duplikaatit yhdistetään ja
valinta lajitellaan deterministisesti. Osumaton glob, puuttuva tiedosto tai
yksikin turvaton osuma keskeyttää koko valinnan.

Seuraavat ovat vain kommentoituja syntaksiesimerkkejä. Paikkamerkit eivät ole
inventaarion todentamia käsikirjoitus- tai tulospolkuja:

```text
# file <hyvaksytty-hakemisto>/Figure 1 final.png
# glob <hyvaksytty-hakemisto>/*.pdf
# file R-scripts/<K_FOLDER>/outputs/<script_label>/<hyvaksytty-taulukko>.csv
```

**CSV ei ole globaalisti turvallinen.** Lähettäjä hyväksyy CSV:n vain
`file`-säännöllä nimetystä täsmällisestä polusta, jonka hakemisto-osissa on
kirjaimellinen `outputs`. CSV:n glob-valinta hylätään myös output-hakemistossa.
Hyväksyjä tarkistaa itse sisällön; ohjelma ei tee osallistujatietojen
sisältöluokittelua.

**`.gitignore` ei koskaan anna siirtolupaa.** Ignore-status ei ole valinnan
peruste, eikä lähettäjä kerää automaattisesti ignored-tiedostoja. Nykyinen
FOF:n `config/`-ignore-sääntö kattaa myös allow-listan. Paikallinen tiedosto
luetaan silti; sen versiohallintakäsittely on erillinen ihmisen toimi.
Siirtoskriptit eivät muuta ignore-sääntöjä tai Git-indeksiä.

## 2. Turvatarkistukset ennen siirtoa

Hard deny ohittaa aina allow-listan. Hylättyjä luokkia ovat esimerkiksi:

- `data`, `dataset`, `raw_data` ja `external_data` missä tahansa polun osassa;
  myös `.git`, `.ssh`, `.aws` ja `.azure` on suljettu pois.
- `.env`, `.env.*`, `.Renviron`, `.netrc`, `.npmrc`, avaintiedostot sekä
  `secret`- tai `credential`-tekstin sisältävät nimet.
- Esimerkiksi `.pem`, `.key`, `.secret`, `.p12`, `.pfx`, `.kdbx`, `.RData`,
  `.rda`, `.rds`, `.sqlite`, `.sqlite3`, `.db`, `.sav`, `.dta`, `.xls` ja `.xlsx`.
- Koodikanavaan kuuluvat `.R`, `.py`, `.sh` ja `.ps1`.

Nimi- ja päätekiellot tarkistetaan kirjainkoosta riippumatta. Vain tavalliset
tiedostot hyväksytään: ei hakemistoja, FIFOja tai muita erikoistiedostoja eikä
symbolisia linkkejä tiedostossa tai missään sen hakemisto-osassa.

Polut pysyvät FOF-juuren sisällä. Absoluuttiset polut, tyhjät polkuosat,
`.`- ja `..`-osat, kenoviivat, kaksoispisteet, ohjausmerkit, Windowsin varatut
nimet ja muut toteutuksen kieltämät merkit hylätään. Nimet vaaditaan Unicode
NFC -muodossa. Windowsissa kirjainkoon vuoksi törmäävät tiedostopolut hylätään.

## 3. Esikatsele paikallisesti

Aja komennot `Python-R-Scripts/Fear-of-Falling/`-hakemistosta. Lähettäjä
ratkaisee FOF-juuren oman `scripts/termux/`-sijaintinsa perusteella; kiinteää
Termux-polkuasetusta ei tarvita. Tarkista työjuuri:

```bash
pwd
bash scripts/termux/export_artifacts_to_windows.sh
```

Oletusajo vain validoi, laskee metatiedot ja näyttää valinnan. Se ei avaa
SSH-yhteyttä, tee verkkosiirtoa tai luo siirtopakettia. Tyhjä lista palauttaa
koodin 0 eikä siirrä mitään. Myös `--execute` tyhjällä valinnalla on tyhjä ajo,
ei vahvistettu siirto.

Vaihtoehtoinen allow-list annetaan FOF-juureen suhteellisena polkuna:

```bash
bash scripts/termux/export_artifacts_to_windows.sh --allowlist config/artifact-transfer.allowlist
```

Stdout sisältää yhden JSONL-rivin per valittu tiedosto. Kentät ovat:

| Kenttä   | Sisältö                                                                                      |
| -------- | -------------------------------------------------------------------------------------------- |
| `path`   | FOF-suhteellinen polku JSON-merkkijonona; Unicode ja erikoismerkit escapetaan turvallisesti. |
| `size`   | Tavukoko kokonaislukuna.                                                                     |
| `sha256` | Sisällöstä laskettu SHA-256, 64 pientä heksadesimaalimerkkiä.                                |

Samoista muuttumattomista syötteistä syntyy sama JSONL-sisältö. Nimiä ei parsita
välilyönneillä. Esikatselun yhteenveto ja virheilmoitukset tulevat stderr-virtaan.
Kesken tarkistuksen havaittu tiedostomuutos keskeyttää ajon.

## 4. Suorita erikseen valtuutettu siirto

Kun valinta on tarkastettu ja neljä ympäristöasetusta annettu, execute-komento on:

```bash
pwd
bash scripts/termux/export_artifacts_to_windows.sh --execute
```

`--execute` on ainoa lähettäjän verkkosiirron käynnistävä lippu. Lähettäjä
validoi ja laskee metatiedot uudelleen, ottaa valituista tiedostoista
snapshotit ja tarkistaa niiden koon ja tiivisteen ennen SSH:ta. Muutos
saman execute-ajon metatietolaskennan ja snapshotin välillä keskeyttää siirron.

Paikallinen `bundle.tar` sisältää vain `transfer-manifest.jsonl`-metatiedoston
ja `payload/`-etuliitteellä nimetyt hyväksytyt tiedostot. Muoto on POSIX USTAR,
ei pakattu tar eikä PAX/GNU-laajennuksia käyttävä arkisto. USTAR-muotoon
sopimaton pitkä polku voi keskeyttää paketoinnin ennen verkkoa.

Stderr näyttää `LOCAL BUNDLE`-polun ja ennen SSH:ta `TRANSFER_RUN_ID`-tunnisteen.
Paikalliset paketit ja snapshotit säilyvät myös virheessä. Lähettäjä välittää
paketin binäärisenä SSH:n stdin-virtana; vastaanottimen toteutus on erillisessä
PowerShell-tiedostossa. Yhteysasetukset ja ajotunniste välitetään koodattuina,
eivät etäkomennon shell-syntaksiksi tulkittavina polkukatkelmina.

## 5. Windowsin staging ja vastaanottotarkistus

Onnistuneen ajon rakenne on seuraava. `<run_id>` on lähettäjän luoma
UTC-aikaleiman ja satunnaisen UUID-osan yhdistelmä:

```text
WINDOWS_STAGING_DIR/
  incoming/
    <run_id>.claim
    <run_id>/
      bundle.tar
      transfer-manifest.jsonl
      payload/
        <FOF-suhteelliset tiedostopolut>
      VERIFIED.json
```

Vastaanotin varaa tunnisteen uuden tiedoston luontia edellyttävällä
claim-tiedostolla. Olemassa olevaa tunnistetta tai ajohakemistoa ei käytetä
uudelleen. Aiemmat ajot ja claim-tiedostot säilyvät. Epäonnistunut ajo voi
sisältää vain osan yllä olevasta rakenteesta; `receipt.pending` ei ole
onnistumiskuittaus.

Vastaanotin tallentaa tar-virran uuteen ajohakemistoon ja tarkistaa koko
arkiston otsakkeet, jäsenpolut, tyypit ja lopetuslohkot ennen purkua.
Vain tavalliset POSIX USTAR -tiedostojäsenet hyväksytään; symlinkit,
hardlinkit, hakemistojäsenet, duplikaatit ja vaaralliset polut hylätään.
Metatiedoston ja arkiston tiedostojoukon sekä kokojen on vastattava toisiaan.
Purku ei ylikirjoita olemassa olevia tiedostoja.

Purkamisen jälkeen vastaanotin vertaa `payload/`-hakemiston **täsmällistä
tiedostojoukkoa, tavukokoja ja SHA-256-tiivisteitä** metatietoon. Vasta kaikkien
tarkistusten onnistuttua se julkaisee `VERIFIED.json`-kuittauksen. Kuittaus
sisältää `status`, `run_id`, `files` ja `verified_at` -kentät.

`VERIFIED` on vastaanottimen pysyvä todiste onnistuneesta sisällöntarkistuksesta.
Osittainen tar, vaarallinen arkisto, purkuvirhe, puuttuva/ylimääräinen tiedosto,
kokovirhe tai tiivistevirhe ei tuota VERIFIED-kuittausta. Vastaanotin ei siirrä
ajoa erilliseen `verified/`-hakemistoon eikä tuo sisältöä väitöskirjarepoon.

## 6. Lähettäjän lopputulos ja palautuminen

Vastaanottimen pysyvä tila ja lähettäjän havainto ovat eri asioita:

| Lähettäjän tulos       | Paluukoodi | Merkitys                                                                                                                                                                                                 |
| ---------------------- | ---------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `SUCCESS`              | 0          | SSH-prosessi onnistui ja sender sai saman `run_id`:n odotetun VERIFIED-vastauksen oikealla tiedostomäärällä. Stdoutin viimeinen JSON-olio sisältää `outcome: SUCCESS` ja vastaanottimen `receipt`-olion. |
| `FAILED`               | 1          | Paikallinen validointi/valmistelu epäonnistui tai vastaanotin vahvisti kyseisen ajon hylkäyksen.                                                                                                         |
| `UNKNOWN_REMOTE_STATE` | 3          | Sender ei pysty vahvistamaan etätilaa. SSH epäonnistui tai vastaus puuttui, oli virheellinen tai ristiriidassa prosessin tuloksen kanssa. Tarkista staging käsin.                                        |

Paluukoodi 0 voi tarkoittaa myös onnistunutta esikatselua tai tyhjää valintaa;
se ei yksin todista siirtoa. Virheelliset komentoriviparametrit voivat palauttaa
parserin koodin 2. `FAILED` ja `UNKNOWN_REMOTE_STATE` ilmoitetaan stderrissä;
niissä sender ei tulosta vahvistettua onnistumista. `VALIDATED`-esikatselurivit
eivät ole onnistumiskuittaus.

SSH:n koodi 255 luokitellaan konservatiivisesti `UNKNOWN_REMOTE_STATE`-tilaksi:
pelkkä koodi ei kerro, ehtikö vastaanotin valmistua. Vastaanottimen oma
vahvistettu hylkäys voidaan luokitella `FAILED`-tilaksi. Yhteyden katketessa
myös tällaisen hylkäysvastauksen katoaminen voi johtaa UNKNOWN-tulokseen.

| Tilanne                                    | Ihmisen seuraava toimi                                                                                                                               |
| ------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| Paikallinen asetusten tai valinnan hylkäys | Korjaa asetukset tai hyväksytty valinta. Esikatsele uudelleen ennen erikseen valtuutettua uutta ajoa.                                                |
| Varhainen SSH-virhe                        | Tarkista yhteyden edellytykset. UNKNOWN-tulos ei todista stagingin tilaa; tarkista ilmoitettu ajotunniste.                                           |
| Osittainen tar tai vastaanottimen hylkäys  | Ajo jää ilman VERIFIEDiä. Säilytä epäonnistunut ajo ja selvitä katkos tai hylkäys ennen uutta ajoa.                                                  |
| SHA-256-, koko- tai tiedostojoukkovirhe    | Älä tuo tiedostoja väitöskirjaan. Tarkista lähde, säilynyt paketti ja vastaanotto; uusi siirto tehdään uudella tunnisteella.                         |
| Myöhäinen paluuyhteyden katkos             | UNKNOWN voi esiintyä yhdessä jo valmiin VERIFIED-kuittauksen kanssa. Tarkista juuri kyseinen staging-ajo; älä tulkitse senderin tulosta SUCCESSiksi. |

UNKNOWN-tilanteessa noudata tätä järjestystä:

1. Ota senderin tulosteesta `TRANSFER_RUN_ID` tai virheilmoituksen `run_id`.
   Avaa vastaanottimella `WINDOWS_STAGING_DIR/incoming/<run_id>/`.
2. Tarkista, onko ajo olemassa ja sisältääkö se kelvollisen `VERIFIED.json`-
   kuittauksen. Varmista, että kuittauksen tunniste vastaa ajohakemistoa ja
   tarkasteltavaa siirtoa. Hakemiston tai kuittauksen puuttuminen ei anna
   import-lupaa. Älä luo VERIFIED-merkintää käsin.
3. Jos kuittaus on olemassa, tarkasta myös metatieto ja payload ihmisenä ennen
   tuontipäätöstä. UNKNOWN jää senderin historialliseksi havainnoksi;
   vastaanottimen kuittaus osoittaa sen oman tarkistuksen valmistuneen.
4. Päätä vasta tarkastuksen jälkeen, tarvitaanko uusi siirto. Käynnistä se
   uutena erikseen valtuutettuna ajona; sender luo uuden tunnisteen.

Ohjelma ei retryä automaattisesti, poista tai alenna etäkuittausta eikä
nimeä epävarmaa ajoa uudelleen. Uusinta säilyttää myös edellisen UNKNOWN-ajon.

## 7. Ihmisen tarkastus ja manuaalinen tuonti

VERIFIED vahvistaa vastaanoton teknisen eheyden. Ihminen tarkistaa lisäksi,
että sisältö on oikea, julkaistavaksi hyväksytty ja tarkoitettu kyseiseen
käsikirjoitukseen. Tarkista tiedostovalinta, metatieto ja tarvittavat
kuvat/taulukot. Stagingin kirjoitussuojaus on säilytettävä myös vastaanoton
jälkeen; kuittaus ei ole mielivaltaisten myöhempien muutosten valvontapalvelu.

Kopioi vasta tarkastuksen jälkeen käsin valitut tiedostot omaan väitöskirjan
työpuuhun. Tee sen muutosten tarkastus ja mahdolliset Git-toimet erikseen
ihmisenä. Siirtokehys ei tunne väitöskirjarepon URL:ia tai tunnistetietoja,
eikä niitä tarvita tähän ohjeeseen tai siirtoasetuksiin.

Lähettäjä ei muuta lähdeartefakteja onnistumisessa, virheessä tai UNKNOWN-
tilanteessa. Kumpikaan skripti ei poista aiempia ajoja tai siivoa automaattisesti
paikallisia paketteja, snapshotteja tai stagingia. Skriptit eivät suorita
`git add`, `commit`, `reset`, `clean`, haaratoimia tai muita Git-kirjoituksia.
Automaattista väitöskirjatuontia ei ole.

## LEGACY/1:n historiallinen validointinäyttö

Vaiheen 5 paikallisessa validoinnissa läpäistiin 29 sender-testiä, 24
PowerShell-vastaanotintestiä, 13 SSH-korvikkeella ajettua siirtotestiä sekä
ajotunnisteen törmäystesti. PowerShell 7.4.1 ajettiin Ubuntu-PRootissa.
Myöhäinen paluukatkos ja sitä seuraava uusinta testattiin uuden
SUCCESS/FAILED/UNKNOWN_REMOTE_STATE-sopimuksen mukaisesti.

Yllä olevat luvut ovat alkuperäisen legacy-vaiheen historiallista näyttöä.
Pysyvän v2-toteutuksen actual-Windows-näyttö kuvataan tämän dokumentin lopussa.
K18/QC: NOT APPLICABLE — siirtoinfrastruktuurin dokumentaatio, ei tiedemuutosta.

## FOF_ARTIFACT_HANDOFF/2 — normatiivinen sopimus

Tämä osio on ainoa normatiivinen v2-sopimus. Edeltävä ohje on **LEGACY/1**:
se nimeää versionumeroimattoman toteutuksen muuttamatta sen wireä,
`--allowlist`/`--execute`-käyttöä tai vanhaa vastaanotinta. V2-profiilia ei
anneta legacy-allowlist-parserille. Dissertation-repon dokumentaatio ja
pysyvä vastaanotin viittaavat tähän versioon eivätkä määrittele omaa wireä.
Alla oleva tuotantoprofiiliskeema säilyy ennallaan; eksplisiittisen smoketilan
rajattu testi-identiteetti kuvataan erikseen nykykäytön yhteydessä.

### Profiiliskeema ja tyhjä hyväksyntätila

Seuraava JSON Schema (Draft 2020-12) on portable source -profiilin
rakenteellinen skeema. Semanttiset polku-, hard-deny- ja digest-säännöt alla
ovat lisäksi pakollisia. Tuntemattomat kentät hylätään kaikilla tasoilla;
sama koskee JSONin duplikaattiavaimia, NaN/Infinity-arvoja ja BOMia.
Kokonaisluvut eivät saa olla liukulukuja tai totuusarvoja.

<!-- FOF_PROFILE_SCHEMA_BEGIN -->

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "additionalProperties": false,
  "required": [
    "protocol_version",
    "profile_id",
    "profile_version",
    "source_repository_id",
    "workstream",
    "state",
    "classification_policy",
    "files"
  ],
  "properties": {
    "protocol_version": { "const": "FOF_ARTIFACT_HANDOFF/2" },
    "profile_id": { "const": "a4-general-fi" },
    "profile_version": { "const": "1.0.0" },
    "source_repository_id": { "const": "Python-R-Scripts" },
    "workstream": { "const": "A4" },
    "state": { "enum": ["EMPTY_NOT_EXECUTABLE", "APPROVED"] },
    "classification_policy": {
      "const": "EXPLICIT_APPROVAL_HARD_DENY_PRECEDENCE"
    },
    "files": {
      "type": "array",
      "maxItems": 1000,
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "source_path",
          "staging_path",
          "classification",
          "approval_reference",
          "csv_approval_reference",
          "expected_sha256"
        ],
        "properties": {
          "source_path": {
            "type": "string",
            "minLength": 1,
            "maxLength": 1024
          },
          "staging_path": {
            "type": "string",
            "minLength": 1,
            "maxLength": 100
          },
          "classification": { "const": "DISTRIBUTABLE_AS_IS" },
          "approval_reference": {
            "type": "string",
            "pattern": "^[a-zA-Z0-9][a-zA-Z0-9._-]{0,127}$"
          },
          "csv_approval_reference": { "type": ["string", "null"] },
          "expected_sha256": { "type": "string", "pattern": "^[0-9a-f]{64}$" }
        }
      }
    }
  },
  "allOf": [
    {
      "if": { "properties": { "state": { "const": "EMPTY_NOT_EXECUTABLE" } } },
      "then": { "properties": { "files": { "maxItems": 0 } } },
      "else": { "properties": { "files": { "minItems": 1 } } }
    }
  ]
}
```

<!-- FOF_PROFILE_SCHEMA_END -->

Nykyinen `config/artifact-transfer/a4-general-fi.json` on
`EMPTY_NOT_EXECUTABLE`, files on tyhjä. Nykyinen legacy-allowlist sisältää
vain kommentteja; tässä rajatussa inventaariossa ei todettu uutta hyväksyttyä
live-source-valintaa. Historiallista 13-file-pakettia ei käytetä valinnan
korvikkeena. Tyhjä profiili kelpaa paikalliseen skeema-/preview-tarkistukseen,
mutta v2 execute MUST palauttaa paikallinen FAILED ennen verkkoa.

Aktivointi vaatii nykyisen täsmäpolun, sisällön luokituksen ja jakeluluvan
tarkistuksen. Jokaisen rivin approval_reference on tarkistettavan Owner-
päätöksen ei-sensitiivinen tunniste, ei itsessään lupa. expected_sha256 sitoo
rivin hyväksyttyihin tavuihin; muuttunut tiedosto pysäyttää ajon. Uusi hyväksytty
profiilirevisio ja sen versio on päätettävä erikseen. Tämä skeema kuvaa vain
nimettyä alkuperäistä profiilia, ei lupaa keksiä muita profiileja.

Git-tracking tai .gitignore ei myönnä siirtolupaa. Hard deny ohittaa myös
DISTRIBUTABLE_AS_IS-merkinnän; ohjelma ei voi todistaa sisällön ihmisluokitusta.
Aktiivisissa riveissä ei hyväksytä PROTECTED-, DENY_UNCLASSIFIED- eikä
selvittämättömiä luokkia. CSV-rivi vaatii kirjaimellisen outputs-hakemisto-osan
lähdepolkuun ja erillisen täsmäpolkuun/hashiin sidotun
csv_approval_reference-tunnisteen (sama tunnistesyntaksi kuin approval_reference).
Muille tiedostoille csv_approval_reference on null. CSV:n tunnistukseen riittää
.csv-pääte joko lähde- tai staging-nimessä; uudelleennimeäminen ei ohita sääntöä.

### Lähdesidonta, polut ja kieltojen etusija

source_repository_id on looginen identiteetti, ei URL eikä tiedostopolku.
Source-root ratkaistaan runtime-konfiguraatiosta ja varmennetaan repositoryn
identiteettiä vasten. Tässä profiilissa source_path alkaa täsmälleen
Fear-of-Falling/ ja on Python-R-Scripts-repon juureen suhteellinen.
staging_path on yksi tiedostonimi; hakemistoja tai papers/A4_placeholder-
polkua ei hyväksytä. PC:n erikseen hyväksytty profiilirekisteri ratkaisee
workstream=A4:n ignored staging/review -reitityksen. Se ei nimeä kanonista
A4-manuskriptia eikä avaa importia. Host/user/port/credentials, source-root,
Windows root, receiver-polku ja repository/staging-root pysyvät runtime-
konfiguraatiossa. Niitä ei hyväksytä portable-profiilin lisäkentiksi.

V2:n alkuperäinen profiili käyttää tarkoituksella vain tulostettavia
ASCII-polkuja (U+0020–U+007E). Unicode/non-ASCII, myös NFC-muodossa, hylätään;
mitään nimeä ei hiljaisesti translitteroida tai normalisoida. Näin Windowsin
Unicode-versioiden case-vertailu ei aiheuta epäselvää aliasointia. Legacy
säilyttää oman NFC-politiikkansa. ASCII-polkujen collision key on lowercase.
Sekä source_path- että staging_path-joukon kaikki duplikaatit ja
case-collisionit hylätään, ei yhdistetä kuten legacyssä.

Polku ei saa olla tyhjä, absolute/UNC/drive-relative, sisältää tyhjiä,
piste- tai vanhempiosia, kenoviivaa, kaksoispistettä, ohjausmerkkejä,
wildcardeja (* ? [ ]), merkkejä < > " | tai whitespace-reunaisia osia.
Pisteeseen loppuva osa ja Windowsin CON/PRN/AUX/NUL/COM0–9/LPT0–9-nimet
(myös päätteelliset) hylätään. Source-polku enintään 1024 ASCII-tavua,
yksittäinen osa enintään 255 tavua; staging-nimi enintään 100 tavua.
Containment ja regular-file-only tarkistetaan lisäksi tiedostojärjestelmästä
runtime-vaiheessa: ei symlinkkejä/reparse pointteja missään komponentissa,
ei FIFOja tai laitteita. Profiilin hyväksyntä ei korvaa näitä tarkistuksia.

Hard deny tarkistetaan source- ja staging-polun jokaiselle osalle case-
insensitiivisesti. V2 sisältää kaikki legacy-kiellot ja seuraavat täsmäluokat:

- Osat: data, dataset, datasets, raw, raw_data, external_data, participant,
  participants, participant-level, provenance, .git, .ssh, .aws, .azure,
  secrets, credentials.
- Nimet: .env, .env.*, .Renviron, .netrc, .npmrc; id_rsa/id_ed25519/id_ecdsa/
  id_dsa-alkuiset nimet; secret- tai credential-tekstin sisältävät nimet.
- Päätteet: .rdata, .rda, .rds, .sqlite, .sqlite3, .db, .sav, .dta, .xlsx,
  .xls, .pem, .key, .secret, .p12, .pfx, .kdbx sekä koodikanavan .r, .py,
  .sh ja .ps1.
- FI_CANDIDATE_REGISTRY.csv ja FI_CHANGELOG.md pysyvät DENY-tilassa.

Lista ei salli muun nimistä osallistuja-/suojattua sisältöä. Auktoritatiivinen
sisältöluokitus voi kieltää minkä tahansa polun; uusi epäselvyys = fail closed.
V2-lisäkiellot eivät muuta legacy-ajokoodia.

### Deterministinen metadata ja tiivisteet

C(x) tarkoittaa tarkistetun JSON-arvon kanonisia tavuja: rekursiivisesti
ASCII-avaimittain lajitellut objektit, ei whitespacea eikä loppurivinvaihtoa,
UTF-8 ilman BOMia, JSON-string escaping, ensure_ascii=true, vain tavalliset
JSON-tyypit ja täsmälliset kokonaisluvut. Hyväksytyt tekstiarvot ovat ASCIIa,
joten Unicode-escape- ja sort-version eroja ei synny. Float/NaN/Infinity ja
duplikaattiavaimet hylätään ennen kanonisointia. Array-järjestys säilyy,
paitsi files lajitellaan ensin tuplella (source_path, staging_path) ASCII-
järjestyksessä. SHA-256 esitetään 64 lowercase-hex-merkillä.

profile_sha256 = SHA256(C(koko validoitu profiili, files lajiteltuna)).
Tämä on semanttinen profiilidigest, ei JSON-tiedoston raakatavujen hash.
Avainjärjestys, sisennys ja files-rivijärjestys eivät muuta digestia;
yksikin lupa-/polku-/hash-kentän muutos muuttaa sitä.

Manifestissa on täsmälleen nämä kentät:

| Kenttä                      | Sopimus                                                                                                          |
| --------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| protocol_version            | FOF_ARTIFACT_HANDOFF/2                                                                                           |
| run_id                      | kelvollinen UTC YYYYMMDDTHHMMSSZ + yhdysmerkki + 32 lowercase hex; uusi satunnainen tunniste joka execute-ajolle |
| source_repository_id        | profiilin tarkistettu identiteetti                                                                               |
| source_head                 | runtime Git HEAD, 40 tai 64 lowercase hex; ei todista untracked-sisältöä                                         |
| profile_id, profile_version | validoidusta profiilista                                                                                         |
| profile_sha256              | yllä määritelty semanttinen digest                                                                               |
| workstream                  | A4                                                                                                               |
| files                       | täsmälleen hyväksytyt rivit                                                                                      |
| content_digest              | alla määritelty vakaa digest                                                                                     |
| run_correlation_digest      | alla määritelty ajosidonta                                                                                       |

Kukin manifestin files-rivi sisältää täsmälleen source_path, staging_path,
size_bytes (int, ei bool, 0–1073741824) ja sha256. Polut vastaavat profiilia
täsmälleen, sha256 = expected_sha256, ei puuttuvia/ylimääräisiä rivejä.
Summa size_bytes enintään 1073741824. Runtime mittaa koot ja hashit
turvallisista avoimista tiedostokahvoista, ja snapshot-pariteetti tarkistetaan
uudelleen ennen verkkoa. Tiedostomuutos missä tahansa vaiheessa pysäyttää.

Vakaa content_digest = SHA256(C(B)), missä B sisältää täsmälleen
protocol_version, source_repository_id, source_head, profile_id,
profile_version, profile_sha256, workstream ja lajitellut files.
run_id ei kuulu B:hen. Myöskään content_digest, run_correlation_digest,
kellonaika, endpoint tai staging-root eivät kuulu B:hen.
Samat sisällöt samalla source_head/profiililla antavat saman digestin;
HEAD-muutos tarkoituksellisesti muuttaa provenance-digestia.

run_correlation_digest = SHA256(C({
"protocol_version": "FOF_ARTIFACT_HANDOFF/2",
"run_id": run_id, "content_digest": content_digest
})). Molemmat osapuolet laskevat digestit itse. Pelkkä saadun hashin
kopioiminen kuittiin ei riitä. Preview ei tee verkkotoimia tai pakettia;
execute vaatii erillisen luvan ja tarkistaa esikatselussa hyväksytyn
content_digestin uudelleen. Hash ei itsessään ole käyttäjän lupa.

### Wire ja vastaanoton completion

V2 kulkee yhden binäärisen POSIX USTAR -virran mukana. Ensimmäinen jäsen on
manifest.json, jonka sisältö on koko kanoninen manifesti C(M); tämän jälkeen
tulevat täsmälleen files/<staging_path>-jäsenet manifestin files-järjestyksessä.
Sender luo run_id:n ja sovitin välittää saman tunnisteen receiverin TransferId-
argumentiksi. Receiver vaatii TransferId:n, tarkistaa sen yhtäläisyyden manifestin
run_id-kenttään ja käyttää sitä muuttamattomana ajohakemiston nimenä.
Metadata ei ole neljästoista sisältöartefakti. Ei hakemistojäseniä, executable
receiver-koodia, PAX/GNU-laajennuksia, linkkejä tai pakkausta. Vain tavalliset
typeflag 0 / V7 regular -jäsenet; tarkistetut otsakechecksumit, jäsenpituudet
ja vähintään kaksi nollalopetuslohkoa, ei ei-nollallista jälkidataa.
Manifesti enintään 16 MiB; tar kokonaisuudessaan enintään 1 GiB.
Pysyvä toteutus tarkistaa nämä rajat ennen vastaanoton hyväksymistä.

PC: incoming/<run_id>/files/ sisältää vain hyväksytyt artefaktit.
manifest.json ja VERIFIED.json ovat files/-hakemiston ulkopuolella.
Rekisteri hyväksyy profiilin/identiteetin/version/digestin ennen reititystä;
muu tai muuttunut profiili tarvitsee uuden hyväksynnän. Vastaanotin varaa
uuden ajon yksinoikeudella, ei ylikirjoita eikä poista aiempaa ajoa.
Exact-set/size/SHA-256 tarkistetaan vastaanotetuista tavuista ja lopullisista
tiedostoista. Kuitti julkaistaan vasta flush/close-varmennuksen jälkeen
atomisesti pending-kuitista; ristiriita tai keskeytys ei saa tuottaa VERIFIEDiä.

Durable VERIFIED-kuitti sekä yksi JSON-stdout-vastaus sisältävät
protocol_version, status, run_id, content_digest, run_correlation_digest,
file_count ja verified_at (UTC). Receiver laskee ja tarkistaa content_digest-
ja run_correlation_digest-arvot manifestin kanonisoiduista kentistä; se ei
kopioi niitä kuittiin ilman omaa validointia. verified_at on täsmälleen
`yyyy-MM-ddTHH:mm:ssZ`: kirjaimelliset kaksoispisteet, sekuntitarkkuus ja UTC Z.
Esimerkiksi `2026-09-14T18:25:53Z` on kelvollinen;
`2026-09-14T18.00.39Z` ei ole. Serialisointi käyttää invarianttia kulttuuria,
eikä Windowsin aikaerotin saa korvata kaksoispisteitä.
Onnistumisessa status=VERIFIED,
prosessi exit 0. Vahvistetussa hylkäyksessä status=FAILED, error_code ja
samat korrelaatiokentät, verified_at puuttuu, exit 1; VERIFIED-kuittia ei ole.
Jos ajokorrelaatiota ei pystytä luotettavasti lukemaan, vastaanotin ei keksi
sitä. Diagnostiikka menee stderriin ilman suojattua payloadia.

Sender SUCCESS/exit 0 vaatii yhden odotetun korreloidun VERIFIED-vastauksen,
oikean file_countin ja SSH exit 0:n. FAILED/exit 1 tarkoittaa paikallista
hylkäystä tai korreloitua receiver FAILED -vastausta ja exit 1:tä.
SSH exit 255, puuttuva/multiple/malformed/mismatched vastaus tai ristiriitainen
exit-status tarkoittaa UNKNOWN_REMOTE_STATE/exit 3, vaikka receiver VERIFIED
olisi jo pysyvä. Tällöin yksilöity ajo tarkistetaan read-only ennen uutta
päätöstä; ei automaattista retryä, cleanupia tai UNKNOWNin muuttamista SUCCESSiksi.

VERIFIED → human review → erikseen hyväksytty A4 import/adaptation.
Git/submodule kuljettaa koodin; tämä kanava hyväksytyt artefaktit ignored
stagingiin; kanoninen julkaiseminen kuuluu erilliseen dissertation-workflowhun.
Ei --deleteä, automaattista Gitiä, importia tai vanhan ajon overwritea.

### Nykyinen v2-käyttö ja kolme erillistä kanavaa

1. Versionoitu analyysikoodi kulkee Git-/submodule-kanavassa.
2. Erikseen hyväksytyt generoidut artefaktit kulkevat exact-manifest
   USTAR-over-SSH-kanavassa ignored dissertation stagingiin. Tekninen
   vastaanottotarkistus päättyy VERIFIED-kuittiin.
3. Julkaisumateriaali käy ihmisen tarkastuksen ja erikseen hyväksytyn
   A4 import/adaptation -vaiheen; vasta sitten sovelletaan väitöskirjarepon
   normaalia Git-workflowta. Kuljetus ei tee tätä päätöstä.

Versionoitavaksi tarkoitettu toteutus ja ignored runtime-artefaktit ovat
siis eri asioita. General FI / C22 kuuluu A4-työvirtaan, ei A1/A2:een.
Kanonista A4-käsikirjoitusta tai supplementtia ei ole nimetty. Historiallinen
varmennettu 13-tiedoston C22-paketti säilyy stagingissa muuttumattomana:
ei testifixture, automaattinen profiilivalinta eikä kanoninen julkaisu.

Lähettäjä ratkaisee FOF-juuren omasta `scripts/termux/`-sijainnistaan.
Git top-levelin pitää olla FOF-juuren välitön parent ja originin
repository-nimen Python-R-Scripts (.git-pääte sallitaan). Tämä on checkoutin
identiteettitarkistus, ei kryptografinen jakelulupa. source_head luetaan Gitistä.
Profiili ei voi vaihtaa lähdejuurta. Runtime ei lue tätä Markdown-skeemaa
vaan käyttää Pythonin vakiokirjaston suljettua validointia.

Aja FOF-juuresta paikallinen esikatselu:

```bash
pwd
bash scripts/termux/export_artifacts_to_windows.sh --profile config/artifact-transfer/a4-general-fi.json
```

`--profile` ja eksplisiittinen `--allowlist` ovat toisensa poissulkevia.
Profiilitiedoston polku on FOF-juureen suhteellinen. Oletus on preview;
se ei käynnistä SSH:ta tai kutsusovitinta. Tyhjä tuotantoprofiili ilmoittaa
`EMPTY_NOT_EXECUTABLE` ja tyhjän files-listan ilman siirtomanifestia tai
digestia. Sen `--execute` palauttaa FAILED/exit 1 ennen verkkoa.
Hyväksytyn aktiivisen testiprofiilin preview tuottaa kanonisen manifestin.
Jokainen preview saa uuden run_id:n; profile_sha256 ja content_digest
säilyvät samoilla profiili-, HEAD- ja sisältösyötteillä.

Nykyinen v2 execute -rajapinta tarvitsee eksplisiittiset `--execute`,
`--approved-content-digest` ja `--local-receiver` -valinnat. Viimeinen nimeää
luotetun paikallisen suoritettavan kutsusovittimen absoluuttisen polun;
se ei ole Windows-kohde, profiilikenttä eikä vastaanottimen toinen toteutus.
Sender antaa sovittimelle vain binäärisen tar-stdin-virran ja tarkistaa
sen yhden JSON-stdout-vastauksen sekä exit-koodin. Sovitin vastaa paikallisesti
valtuutetusta SSH-kutsusta pysyvään receiveriin ja säilyttää protokollakanavat.
Tämä käyttöohje ei nimeä tilapäistä smoke-sovitinta pysyväksi riippuvuudeksi.
Toimitettu v2-sovitin ja runtime-asetukset kuvataan operaattorin pikapolussa.

V2:n `FOF_V2_SSH_ALIAS` ja `FOF_V2_RECEIVER_SCRIPT` ovat erillinen
luotettu runtime-binding. Receiver-polun on oltava absoluuttinen
Windows-polku, jonka canonical-suffiksi on
`/scripts/ps7/receive_artifact_bundle.ps1`; vanhaa
`/scripts/receive_artifact_bundle.ps1`-suffiksia ei hyväksytä.
Host-, käyttäjä- ja avaintiedot jäävät SSH-konfiguraatioon eivätkä
kuulu profiiliin tai repositoryyn.

Ilman `--local-receiver`-valintaa aktiivinenkin profiili pysähtyy edelleen
`RECEIVER_NOT_AVAILABLE_FOR_PROTOCOL_V2`-tilaan ennen verkkoa. Legacy-
ympäristömuuttujat eivät avaa v2-reittiä. Phase 6:n todellinen SSH-smoke
käytti tätä eksplisiittistä sovitinrajapintaa; pelkkää
`--profile --execute`-komentoa ei pidä kuvata valmiiksi tuotantoverkkopoluksi.
Sovittimen käynnistys vaatii hyväksytyn preview-content_digestin. Sender
varmistaa tiedostojen koon/hashit, snapshot-pariteetin ja lopuksi profiilin
sekä HEADin muuttumattomuuden. Paikallinen yksilöllinen paketti säilytetään
FOF-juuren ulkopuolisessa väliaikaistilassa; automaattista uusintaa ei tehdä.

### Synteettinen smoke on erillinen testitila

Senderin `--smoke-test` vaatii `--profile`-valinnan ja hyväksyy vain
`fof-synthetic-smoke/0.0.0`-identiteetin. Source identity pysyy
Python-R-Scripts ja workstream A4; ne eivät tarkoita tuotantoartefakteja.
Ilman smokelippua testi-identiteetti hylätään. Smokelippu hylkää puolestaan
`a4-general-fi/1.0.0`-identiteetin eikä tee tyhjästä tuotantoprofiilista ajettavaa.
Muut skeema-, exact mapping-, hard-deny-, CSV-, polku-, containment-,
regular-file-, symlink-, case-collision- ja digest-tarkistukset ovat samat.

Vastaanottimen luotettu paikallinen kutsu käyttää `-SmokeTest -SmokeSession`:
sessio on uusi 32-merkkinen lowercase hex -tunniste, ei polku. Vastaanotin
ratkaisee itse session testirekisterin ja ignored smoke-stagingin.
Smoke-identiteetti ei reitity tuotannon incomingiin eikä tuotantoidentiteetti
smokeen. Manifesti/profiili ei saa valita registryä, staging-rootia,
Windows-polkuja, SSH host/user/credentials-arvoja tai kanonista A4-kohdetta.
Testitila ja sen tilapäiset synteettiset hyväksynnät eivät anna tuotantolupaa.

### Palautuminen ja tuotannon aktivointiraja

Korreloitu receiver-hylkäys ja exit 1 tarkoittavat FAILEDia. Puuttuva,
virheellinen tai väärään ajoon kuuluva loppuvastaus tarkoittaa
UNKNOWN_REMOTE_STATEa, ei automaattista FAILEDia. Esimerkiksi ennen
luotettavaa manifestikorrelaatiota tapahtuva hylkäys voi jäädä UNKNOWNiksi.
Kesken jäänyt ajo ei saa VERIFIED-kuittia. Myöhäinen kuittauskatkos voi
jättää vastaanottimen VERIFIED-tilaan mutta senderin UNKNOWN_REMOTE_STATEen.

Tarkista yksilöidyn ajon manifesti, kuitti ja sisältö read-only ennen
jatkopäätöstä. Säilytä myös epäonnistuneet ja epävarmat ajot. Jokainen
uudelleenyritys saa uuden run_id:n, smokessa myös uuden session; aiempaa
ajoa ei käytetä uudelleen, poisteta, nimetä uudelleen tai siivota automaattisesti.
VERIFIED todistaa teknisen eheyden, ei sisällön tieteellistä/julkaisullista
hyväksyntää. Ihmisen tarkastus on pakollinen ennen erillistä A4-tuontipäätöstä.

Tuotannon a4-general-fi on edelleen EMPTY_NOT_EXECUTABLE ja PC-rekisterin
approved_content_digests on tyhjä. Aktivointi vaatii erillisen toteutus- ja
review-päätöksen: auktoritatiivisesti valitut live-output-täsmäpolut,
sisältöluokitukset, hyväksytyt tavut/profiilirevisio sekä vastaanottimen
profiili- ja sisältödigestien hyväksyntä. Historiallinen C22-valinta ei
korvaa tätä. `.gitignore` ei anna siirtolupaa eikä sitä muuteta kuljetuksen
vuoksi. Lähdeprofiili on nykyisen config/-säännön vuoksi ignored; myöhempi
Git-toimitus tarvitsee nimenomaisen path-scoped force-add-käsittelyn vain
profiilipolulle, ei ignore-muutosta eikä artefaktien lisäämistä Git-kanavaan.

### Validoitu näyttö ja seuraava tarkastus

Phase 6g (2026-09-14): pysyvä sender ja pysyvä Windows-receiver läpäisivät
23 synteettistä verkkotestitapausta. Windows Pester 47/47, lähdetestit 48/48
ja legacy-regressiot 29/29 PASS. Sender ajettiin tavutarkkana kopiona
synteettisessä checkoutissa; SSH suoritti asennetun pysyvän receiverin,
ei väliaikaista vastaanotinkoodia. Happy path hyväksyi invariantin
`2026-09-14T18:25:53Z`-kuitin SUCCESSiksi. Tunnetut hash/size/set-hylkäykset,
vaaralliset jäsenet, reitityseristys, profiilisidonnat, osittainen payload,
ajotörmäys, uusinta ja myöhäinen kuittauskatkos tarkistettiin.

Tämä näyttö koskee vain synteettisiä tiedostoja, ei tuotannon A4-profiilin
ajoa oikeilla artefakteilla. Tarkat session/run-tunnisteet, toteutushashit ja
rajauksen tarkistukset ovat sender-tehtäväkortissa `FOF_DURABLE_ARTIFACT_HANDOFF_SENDER`
(nykyinen sijainti määräytyy tehtäväworkflown mukaan)
ja dissertation-repon receiver-vastinkortissa. Phase 8:n lopullinen
regressio/turvallisuus/rajauksen katselmointi sekä Git-toimitus ovat erillisiä.

Sopimuksen referenssivektorit ja runtime-regressiot ovat
[Python-testeissä](../tests/test_artifact_transfer.py). Dokumentin tuotantoskeema
luetaan referenssitesteissä; sender-runtime ei riipu testimoduulista.
Referenssi-/testiharness on validointiväline, ei tuotanto-API. Tuettu
toteutuksen käyttörajapinta on pysyvän senderin CLI, mukaan lukien edellä
kuvattu profiilitila; testiharness ei korvaa sitä.
FOF-juuren testikomento on:

```bash
PYTHONDONTWRITEBYTECODE=1 python -m unittest discover -s tests -p test_artifact_transfer.py -v
```

Integraatio-osuus tarvitsee testien määrittelemän vastaanotinsnapshotin ja
paikallisen PowerShell-kutsun. Komennon listaaminen ei tarkoita, että Phase 7
ajaisi Phase 8:n regressiota tai avaisi verkko-/tuotantosiirtolupaa.
