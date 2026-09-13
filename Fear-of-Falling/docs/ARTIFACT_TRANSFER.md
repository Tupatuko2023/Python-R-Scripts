# FOF-artefaktien siirto Termuxista Windowsiin

Tämä ohje kuvaa vaiheessa 5 paikallisesti validoitua toteutusta. Analyysikoodi
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

## Validoinnin tila

Vaiheen 5 paikallisessa validoinnissa läpäistiin 29 sender-testiä, 24
PowerShell-vastaanotintestiä, 13 SSH-korvikkeella ajettua siirtotestiä sekä
ajotunnisteen törmäystesti. PowerShell 7.4.1 ajettiin Ubuntu-PRootissa.
Myöhäinen paluukatkos ja sitä seuraava uusinta testattiin uuden
SUCCESS/FAILED/UNKNOWN_REMOTE_STATE-sopimuksen mukaisesti.

**Natiivi Windows/OpenSSH/NTFS: NOT RUN.** Paikalliset testit eivät todista
natiivin Windows-ympäristön toimintaa. Vaiheen 6 dokumentaatiotarkistus ei
sisällä oikeaa verkkosiirtoa eikä vaiheen 7 koko regressiomatriisin ajoa.
K18/QC: NOT APPLICABLE — kyseessä on ei-tieteellisen siirtoinfrastruktuurin ohje.
