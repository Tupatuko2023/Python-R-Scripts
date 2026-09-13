# FOF-artefaktien siirtokehys Termuxista Windowsiin

## Status

03-review — vaiheet 1–7 PASS; READY_FOR_REVIEW, odottaa ihmisen tarkastusta.

## Context

Käyttäjä valtuutti keskustelussa yhden uuden tehtäväkortin lisäämisen neljän
toteutustiedoston rinnalle sekä saman kortin tilasiirrot ja lokituksen.
Valtuutus toteuttaa SKILLS.md:n kohdan "Orkestroijan ohjaama tehtävän luonti".
Tehtäväjonoa ei ohiteta eikä olemassa olevia ohjetiedostoja muuteta.

Käyttäjä päätti vaiheiden 0b ja 0c read-only-rajaukset ja käski jatkamaan
`prompts/1_rsync.txt`:n toteutusta vaiheesta 1. Tämä käsky on nykyinen
toteutusvaltuutus neljälle toteutustiedostolle ja tälle kortille.
Työpaketti `prompts/5_rsync.txt` korvaa aiemman atomisen ACK-vaatimuksen:
vastaanotin on pysyvän VERIFIED-tilan auktoriteetti, sender vain havaitsemansa
SSH-tuloksen auktoriteetti. Työpaketti `prompts/6_rsync.txt` valtuutti vain
vaiheen 6 käyttöohjeen ja tämän kortin päivityksen. Työpaketti
`prompts/7_rsync.txt` valtuutti regressiot ja kortin siirron tarkastukseen
kaikkien pakollisten paikallisten porttien läpäisyn jälkeen.

## Inputs

- `prompts/1_rsync.txt`: toteutuksen vaiheistus, turvaehdot ja testimatriisi.
- `prompts/2_rsync.txt`: vaiheen 0b työnkulku- ja rajausratkaisu.
- `prompts/4_rsync.txt`: aiempi kuittausvaatimus, jonka atomisuusehto on
  korvattu työpaketilla 5.
- `prompts/5_rsync.txt`: nykyinen valmistumistilan auktoriteetti ja vaiheen 5
  testit; vaiheita 6–7 tai oikeaa verkkosiirtoa ei valtuutettu.
- `prompts/6_rsync.txt`: nykyisen toteutuksen käyttöohje; ei koodimuutoksia,
  vaihetta 7 tai kortin siirtoa tarkastukseen.
- `prompts/7_rsync.txt`: koko regressiomatriisi, lopputarkastus ja ehdollinen
  siirto 03-review-tilaan; ei oikeaa verkkosiirtoa eikä done-siirtoa.
- `GPT/repo_inspection_.md`: hyväksytty siirtoarkkitehtuuri.
- `SKILLS.md`, `AGENTS.md`, `config/agent_policy.md`, `config/steering.md`.
- `Fear-of-Falling/README.md`, `Fear-of-Falling/AGENTS.md` ja
  `Fear-of-Falling/CLAUDE.md`.

## Outputs

Toteutustuote: vain seuraavat neljä uutta tiedostoa, ei olemassa olevien
toteutustiedostojen muutoksia:

- `Fear-of-Falling/config/artifact-transfer.allowlist`
- `Fear-of-Falling/scripts/termux/export_artifacts_to_windows.sh`
- `Fear-of-Falling/scripts/ps7/receive_artifact_bundle.ps1`
- `Fear-of-Falling/docs/ARTIFACT_TRANSFER.md`

Erikseen valtuutettu työnkulkuartefakti: tämä yksi kortti seuraavissa
peräkkäisissä sijainneissa, loki kortin sisällä:

- `tasks/01-ready/FOF_ARTIFACT_TRANSFER.md`
- `tasks/02-in-progress/FOF_ARTIFACT_TRANSFER.md`
- `tasks/03-review/FOF_ARTIFACT_TRANSFER.md`

Siirrä kortti työn alle ennen toteutusta. Siirrä tarkastukseen vasta DoD:n
täytyttyä; keskeneräinen tai estynyt toteutus jää työn alle ja este kirjataan.
Vain ihminen siirtää kortin done-tilaan. Siirrot ja lokitus on jo valtuutettu;
niihin ei tarvita uutta lupapyyntöä hyväksytyn rajauksen sisällä.

## Constraints

- Enintään neljä toteutustiedostoa ja yksi työnkulkukortti.
- Ei muita raportti-, testi-, loki- tai manifestitiedostoja repositoryyn.
  Synteettinen testimateriaali pidetään väliaikaisena versionhallinnan ulkopuolella.
- Ei raakadataa, osallistujatietoja, salaisuuksia tai yksityisiä yhteysarvoja
  tähän korttiin tai testiaineistoon.
- Ei muutoksia olemassa oleviin ohjeisiin, ignore-sääntöihin tai manifestiin.
- Ei automaattisia Git-kirjoitustoimia, haaranvaihtoa tai tuhoavaa siivousta.
- Olemassa olevat tähän tehtävään kuulumattomat työpuumuutokset säilytetään.
- Todellinen verkkosiirto edellyttää erillistä verkkotoimen valtuutusta,
  käyttäjän antamia ajonaikaisia yhteysarvoja ja eksplisiittistä --execute-ajoa.

## Definition of Done (DoD)

- [x] Vaihe 0: ajantasaiset ohjeet, kohdepolut ja työpuun lähtötila tarkistettu
      ennen toteutuksen aloittamista.
- [x] Vaihe 1: oletusarvoisesti kieltävä allow-list ja sen tarkistukset valmiit.
- [x] Vaihe 2: paikallinen esikatselu ja valinnan turvatestit hyväksytty.
- [x] Vaihe 3: deterministinen koko- ja SHA-256-metatieto testattu.
- [x] Vaihe 4: Windows-vastaanotin toteutettu ja riittävät ajettavat
      vastaanottotestit hyväksytty ennen vaihetta 5.
- [x] Vaihe 5: eksplisiittinen SSH-siirto ja senderin tulostilat validoitu
      paikallisesti työpaketin 5 mukaisesti.
- [x] Vaihe 6: käyttöohje kirjoitettu ja tarkistettu validoitua toteutusta vasten.
- [x] Vaihe 7: alkuperäisen työpaketin regressiomatriisi ajettu; PASS, FAIL ja
      NOT RUN eroteltu ilman puuttuvien testien hyväksymistä.
- [x] Jokaisen vaiheen diff, whitespace-tarkistus ja status tarkastettu
      suhteessa lähtötilaan; näyttö kirjattu tähän korttiin.
- [x] Turvaehdot todistettu: allow-list, hard deny, polkurajaus, vain tavalliset
      tiedostot, ei symlinkkejä, esikatselu oletuksena, yksilöllinen staging,
      tarkka tiedostojoukko/koko/SHA-256 ja VERIFIED vasta täydestä onnistumisesta.
- [x] Ei automaattista väitöskirjarepoon tuontia, poistoja tai Git-kirjoituksia.
- [x] Lopullinen raportti sisältää vaiheiden, tiedostojen, testien, riskien ja
      rajauksen toteutuneen tilan; kortti siirretty tarkastukseen vasta valmiina.

## QC applicability

K18/QC: NOT APPLICABLE — ei-tieteellinen siirtoinfrastruktuuri ja työnkulun
kirjaus; ei data-, muuttuja-, malli-, QC- tai analyysitulosten muutoksia.
Siirtototeutuksen paikalliset turvallisuus- ja regressiotestit ovat pakolliset.

## Log

- 2026-09-12T23:54:22+03:00 Käyttäjän "valtuutan" hyväksyi ehdotetun
  yhden tehtäväkortin rajauslaajennuksen, siirrot ja lokituksen. Kortti luotu
  ready-jonoon juuren tehtäväpohjan mukaisesti. Vaihetta 1 ei aloitettu.
- 2026-09-12T23:54:22+03:00 `bash ../tools/run-gates.sh --read-only`
  onnistui Fear-of-Falling-työjuuresta. Tarkistus koski politiikkatiedostojen
  olemassaoloa, ei toteutuksen testejä tai muuttavan työn hyväksymistä.

- 2026-09-12T23:56:08+03:00 Kortin rakenne- ja rajausvalidointi: PASS.
  Statusvertailussa vain tämä uusi kortti; ei poistuneita statusrivejä.
  Uuden tiedoston diff-tarkistus ei ilmoittanut whitespace-virheitä.
  Neljä toteutustiedostoa ovat edelleen luomatta. Ei verkkotoimia.

- 2026-09-13T00:07:09+03:00 Kortti siirretty 01-ready → 02-in-progress ennen toteutusta.
  Käyttäjän jatkokäsky kirjattu. Lähtötila talteen vertailua varten; ei
  arkkitehtuuriristiriitaa. Read-only-politiikkaportti PASS.

- 2026-09-13T00:08:19+03:00 Vaihe 1 PASS: kommentoitu default-deny-lista,
  ei aktiivisia absoluuttisia tai traversal-sääntöjä. Koko sisältö ja diff
  tarkastettu; whitespace-virheitä ei ollut. Status vain kortin siirto.
  Allow-list jää config-hakemiston ignore-säännön alle; tiedosto tarkistettiin
  erikseen git diff --no-index -komennolla. Ei ignore- tai indeksimuutoksia.

- 2026-09-13T00:10:07+03:00 Vaihe 2 PASS: bash -n, oletusajo 0 valintaa,
  29 synteettistä tapausta (kukin kahdesti). Turvaton polku, data, salaisuus,
  koodi, symlinkki, FIFO, hakemisto, osumaton glob ja CSV-glob hylättiin.
  Välilyönnit, Unicode, täsmällinen output-CSV, lajittelu ja duplikaatit PASS.
  Lähdetiivisteet säilyivät; verkkotyökalujen/Gitin stubbeja ei kutsuttu.
  Koko uusi diff ja whitespace tarkastettu. Status lisäsi vain senderin.
  Testimateriaali väliaikaisessa hakemistossa repositoryn ulkopuolella.

- 2026-09-13T00:11:28+03:00 Vaihe 3 PASS: samat 29 tapausta kahdesti,
  JSONL-metatiedon tavukoko ja SHA-256 verrattu synteettiseen lähteeseen.
  Samoilla syötteillä tavuntarkasti sama stdout. bash -n, whitespace- ja
  vaihediff-tarkastus PASS; git-status ennallaan.

- 2026-09-13T00:18:15+03:00 Vaihe 4 PASS: PowerShell 7.4.1 ajettu Ubuntu-PRootissa
  olemassa olevasta asennuksesta (vain ajonaikainen bind ja
  DOTNET_GCHeapHardLimit=0x10000000). Alkuperäinen käynnistys epäonnistui
  polun näkyvyyteen ja CoreCLR-muistivaraukseen; rajattu ajo onnistui.
  PowerShell-parseri PASS. 24 vastaanotintestiä PASS: happy path, Unicode,
  välilyönnit, output-CSV, uusinta, tiiviste/koko/joukkovirheet, katkennut tar,
  traversal, absoluuttiset polut, secrets/data, symlink/hardlink, duplikaatit.
  Aiemmat ajot säilyivät; virheissä ei VERIFIED-kuittausta.
  Koko uusi diff ja whitespace tarkastettu; status lisäsi vain vastaanottimen.
  Natiivi Windows/OpenSSH/NTFS: NOT RUN; paikallinen PowerShell-ajopinta
  täyttää vaiheen 4 synteettisen vastaanotintestauksen portin.

- 2026-09-13T00:21:36+03:00 Vaihe 5: SSH-kytkentäluonnos toteutettu vasta vaiheen 4 portin
  jälkeen. Paikallinen SSH-korvike välitti oikean senderin USTAR-stdin-virran
  oikeaan PowerShell-vastaanottimeen. 5 tarkistusta PASS: preview ei kutsu
  SSH:ta, happy path, uusinta säilyttää aiemmat ajot, yhteyden alun virhe ja
  osittainen stdin-siirto. Molemmissa varhaisissa virheissä ei VERIFIED-kuittausta.
  Ei oikeaa verkkoyhteyttä eikä lähdemuutoksia.
- 2026-09-13T00:21:36+03:00 Vaiheen 5 vaatimustesti FAIL: SSH-korvike antoi vastaanottimen
  valmistua, pudotti paluukuittauksen ja palautti 255. Sender palautti virheen
  eikä tulostanut onnistumiskuittausta, mutta vastaanottimessa oli yksi uusi
  VERIFIED.json. Alkuperäinen vaatimus "SSH failure leaves no VERIFIED receipt"
  ei toteudu myöhäisessä paluuyhteyden katkoksessa. Kuittauksen poistaminen
  olisi vastoin no-delete-sääntöä eikä yhteyden yli varmasti mahdollista.
- 2026-09-13T00:21:36+03:00 --execute suljettu eksplisiittisellä virheellä ennen paketointia
  tai SSH:ta päätöstä odotettaessa. Esikatselun 29 tapausta uudelleen PASS.
  Vaiheen 5 diff, whitespace ja status tarkastettu; ei uusia ulkopuolisia
  muutoksia. Vaiheisiin 6–7 ei edetä epäonnistuneen portin yli. Käyttöohjetta
  ei luotu. Korttia ei siirretä tarkastukseen ennen DoD:n täyttymistä.


- 2026-09-13T00:39:00+03:00 Työpaketti 4_rsync käsitelty. Aiempi lievennysehdotus hylätty;
  VERIFIED ei saa tarkoittaa pelkkää vastaanottimen sisällöntarkistusta.
  Säilytetty sulkemista edeltävä sender-fixture ajettu uusissa väliaikaisissa
  hakemistoissa muuttamatta live-senderin suljettua --execute-porttia.
  5 normaalia siirtotarkistusta PASS. Myöhäisen katkon vaatimus FAIL toistui:
  korvike pudotti vastaanottimen paluuviestin ja palautti 255, sender palautti
  virheen, stagingiin jäi yksi uusi VERIFIED.json. Ei oikeaa verkkoyhteyttä.
- 2026-09-13T00:39:00+03:00 Nykyinen sender-suite 29/29 PASS ja receiver-suite 24/24 PASS
  uudelleen. Lähdetiedostot ja aiemmat staging-ajot säilyivät tavuntarkasti.
  bash -n ja PowerShell 7.4.1 parseri PASS; live --execute exit 2 ilman SSH:ta
  tai onnistumiskuittausta. Natiivi Windows/OpenSSH edelleen NOT RUN.
- 2026-09-13T00:39:00+03:00 Kaksivaiheisen protokollan tilat analysoitu erikseen:
  RECEIVING → CONTENT_VALIDATED (ei import-lupaa) → FINALIZE_REQUESTED
  → VERIFIED. Lähettäjällä WAITING → PREPARED_SEEN → SUCCESS tai FAILED/UNKNOWN.
  Tämä on suunnitteluanalyysi, ei toteutettu korjaus eikä korjaustestin PASS.
  Synteettinen tilajälki: vastaanotin julkaisee VERIFIEDin, lopullinen ACK
  katoaa, sender ei voi todeta onnistumista. Ylimääräinen ACK siirtää saman
  epävarmuuden uuteen viimeiseen viestiin. Jos sender toteaa SUCCESSin ennen
  julkaisua, julkaisun epäonnistuminen puolestaan jää sen havaintojen ulkopuolelle.
- 2026-09-13T00:39:00+03:00 Arkkitehtuurinen este: vastaanottimen pysyvää markeria ja senderin
  havaittua onnistumista ei voida sitoa atomisesti tällä katkeavalla SSH-kanavalla.
  Nykyinen sopimus vaatii samanaikaisesti kestävän etämarkerin, varman
  sender-näkyvän onnistumisen ja markerin puuttumisen kaikissa epävarmoissa
  epäonnistumisissa. Pelkkä prepare/finalize ei toteuta kaikkia ehtoja.
  Ohjeen pysäytysehtoa sovellettu; toteutuskoodia ja allow-listaa ei muutettu.
  Ei poistamista, merkintöjen uudelleennimeämistä tai uutta vastakanavaa.
  --execute säilyy suljettuna. Vaihe 5 ei ole korjattu; vaiheet 6–7 tekemättä.

- 2026-09-13T04:15:49+03:00 Työpaketti 5 ratkaisi valmistumistilan auktoriteetin. Aiemmat
  FAIL/atomisuushavainnot säilytetään historiallisina; niitä ei tulkita uuden
  sopimuksen esteeksi. Vaiheen 5 korjaus tehty senderiin ja vastaanottimeen.
  Allow-lista, valinta-, metadata- ja arkistotarkistuslogiikka säilytettiin.
- 2026-09-13T04:15:49+03:00 Senderin tilat: SUCCESS/exit 0 vain SSH-exit 0 ja saman run_id:n
  odotettu VERIFIED-vastaus; FAILED/exit 1 paikallisesta valmisteluvirheestä
  tai vastaanottimen vahvistetusta hylkäyksestä; UNKNOWN_REMOTE_STATE/exit 3
  epävarmasta SSH-tuloksesta, puuttuvasta/virheellisestä vastauksesta tai
  ristiriitaisesta exit-koodista. SSH 255 luokitellaan konservatiivisesti
  UNKNOWNiksi, koska se ei yksin todista vastaanottimen tilaa.
- 2026-09-13T04:15:49+03:00 Sender luo yksilöllisen run_id:n ennen SSH-kutsua ja välittää sen
  vastaanottimen TransferId-parametrille turvallisesti koodattuna. Epävarma
  tulos näyttää täsmällisen incoming/run_id-polun tarkistusta varten eikä
  tulosta onnistumista. Vastaanotin varaa uuden ajon CreateNew-claimilla,
  hylkää olemassa olevan tunnisteen ja säilyttää kaikki aiemmat ajot.
  Julkaistua VERIFIED-kuittausta ei poisteta tai alenneta paluuvirheen vuoksi.
- 2026-09-13T04:15:49+03:00 Validointi PASS: sender-suite 29/29, receiver-suite 24/24,
  päivitetty transport-suite 13/13 ja erillinen TransferId-törmäystesti.
  Transportissa testattiin preview, paikallinen asetushylkäys, happy path,
  uusinta, varhainen SSH 255, partial tar, hash, missing/extra set,
  late-disconnect, uusinta UNKNOWN-ajon jälkeen, virheellinen paluusanoma
  ja VERIFIED-vastaus yhdistettynä SSH:n nonzero-tulokseen.
  Late-disconnect: sender UNKNOWN/exit 3, ei onnistumisväitettä, yksi täysin
  validoitu vastaanottimen VERIFIED säilyi. Tämä on uuden sopimuksen PASS.
  Partial/hash/joukkovirheet: FAILED/exit 1, ei VERIFIED-kuittausta.
  Lähteet ja kaikki aiemmat staging-ajot säilyivät; yksi SSH-korvikekutsu per
  execute-ajo, ei automaattista retryä eikä oikeita verkkoyhteyksiä.
- 2026-09-13T04:15:49+03:00 bash -n ja PowerShell 7.4.1 parseri PASS. Koko koodimuutosdiff
  ja whitespace-tarkistukset hyväksytty. --execute avattu uuden sopimuksen
  mukaisesti; normaali ajo on edelleen vain paikallinen preview. Native
  Windows/OpenSSH/NTFS NOT RUN. K18/QC NOT APPLICABLE: vain siirtomekaniikka.
  Vaiheet 6–7 tekemättä käyttäjän rajauksen mukaisesti, ei docs-tiedostoa.
  Kortti säilyy 02-in-progress-tilassa eikä siirry vielä tarkastukseen.

- 2026-09-13T04:27:44+03:00 Vaihe 6 PASS: luotu vain
  Fear-of-Falling/docs/ARTIFACT_TRANSFER.md toteutustuotteena. Ohje kattaa
  riippuvuudet, neljä ajonaikaista WINDOWS-asetusta, preview/execute-ajot,
  allow-listan syntaksin ja default denyn, hard denyn etusijan, CSV-rajauksen,
  polku-/tiedostotyyppitarkistukset, deterministisen JSONL:n ja USTAR-paketin.
  Dokumentoitu ajokohtainen staging, exact set/size/SHA-256, VERIFIED sekä
  SUCCESS/FAILED/UNKNOWN_REMOTE_STATE, UNKNOWN-ajon käsitarkastus ja uusi
  ajotunniste uusinnassa. Ohje kattaa manuaalisen tuonnin ja no-delete/no-Git-
  takuut; natiivi Windows/OpenSSH/NTFS on merkitty NOT RUN.
- 2026-09-13T04:27:44+03:00 Dokumentaation koko uusi diff tarkastettu nykyistä senderiä,
  receiveriä ja allow-listaa vasten; vanhaa atomisen ACK:n ehtoa ei siirretty
  ohjeeseen. Suhteelliset toteutuslinkit ja komento-/asetusviittaukset tarkistettu.
  git diff --check sekä untracked-dokumentin git diff --no-index --check PASS.
  Senderin, receiverin ja allow-listan SHA-256 säilyivät samoina kuin alussa.
  Vaiheen 7 regressiota, siirtoskriptejä tai verkkotoimia ei ajettu. Kortti
  säilyy 02-in-progress-kansiossa; valtuutettu muutosrajaus on käyttöohje ja kortti.

- 2026-09-13T04:36:56+03:00 Vaihe 7 PASS työpaketin 7 mukaisesti. Politiikkatiedostot ja
  FOF-ohjeet luettu; read-only-politiikkaportti PASS. Olemassa olevan,
  hyväksytyn kortin jatkovaltuutus tuli käyttäjän työpaketista. Neljän tuotteen
  koko sisältö tarkastettu arkkitehtuuria ja nykyistä valmistumissopimusta
  vasten. Regressiokorjauksia ei tarvittu: kaikki neljä tuotetta säilyivät
  SHA-256-tiivisteiltään ennallaan tämän vaiheen aikana.
- 2026-09-13T04:36:56+03:00 Paikalliset regressiot yhteensä 72/72 PASS:
  `python check_sender.py scripts/termux/export_artifacts_to_windows.sh`
  29 tapausta (kukin kahdesti), `python check_receiver.py` 24 tapausta,
  `python check_transport_v2.py` 13 tapausta, `python extra_receiver.py`
  4 lisätapausta ja `python extra_transport.py` 2 lisätapausta.
  Harnessit ja uudet synteettiset fixturet säilytettiin väliaikaishakemistoissa
  repositoryn ulkopuolella; työjuuri Fear-of-Falling. Käytettiin live-senderin
  tavuntarkkaa kopiota ja live-vastaanotinta PowerShell 7.4.1 / Ubuntu-PRootissa.
  SSH oli paikallinen korvike, ei verkkoyhteys. Aiemmat fixturet säilytettiin.
- 2026-09-13T04:36:56+03:00 Valinta/metatieto PASS: happy path, ignored-outputin eksplisiittinen
  lupa, .env- ja data/raw_data-kiellot, hard deny ennen lupaa, välilyönnit ja
  Unicode, duplikaattien yhdistäminen, tavuntarkasti deterministinen JSONL,
  koko/SHA-256, CSV vain täsmällisellä outputs-polulla, osumattoman globin
  keskeytys, traversal/absoluuttiset POSIX- ja Windows-polut, symlinkit ja
  niiden hakemisto-osat, FIFO/hakemistot, case collision ja containment.
  Git check-ignore --no-index vahvisti synteettisen output-polun sekä .env:n
  nykyisten ignore-sääntöjen piiriin. Ignore ei anna siirtolupaa.
- 2026-09-13T04:36:56+03:00 Vastaanotto/siirto PASS: tar -> vastaanotin -> exact set/size/SHA-256
  -> VERIFIED ja sender SUCCESS; partial tar, hash/size, missing/extra,
  puuttuva lopetus, vaaralliset jäsenet, linkkijäsenet, duplikaattiarkisto,
  metatietorivien duplikaatit, JSON-avaimen duplikaatti sekä purkupoikkeus
  jäivät ilman VERIFIEDiä. Pakotettu sama TransferId hylättiin ja koko
  olemassa oleva staging säilyi tavuntarkasti.
- 2026-09-13T04:36:56+03:00 Valmistumissopimus PASS: varhainen SSH 255 antoi nonzero UNKNOWNin
  ilman valmistunutta vastaanottoa; myöhäinen paluukatkos antoi exit 3
  UNKNOWN_REMOTE_STATE, ei SUCCESSia, säilytti valmiin VERIFIEDin ja näytti
  yksilöidyn incoming/run_id-tarkastuspolun. Virheellinen paluusanoma sekä
  VERIFIED-vastaus + nonzero olivat UNKNOWN. Vastaanottimen vahvistetut
  hylkäykset olivat FAILED/exit 1. Uusinnat loivat uudet tunnisteet ja
  säilyttivät onnistuneet, epäonnistuneet ja UNKNOWN-ajot. Lähteet säilyivät.
  Ei automaattista retryä. Preview ja tyhjä --execute eivät kutsuneet SSH:ta
  eivätkä keksineet siirron onnistumista. Asetusten hylkäys ennen SSH:ta PASS.
- 2026-09-13T04:36:56+03:00 Lopputarkastus PASS: bash -n, PowerShell-parseri, dokumentaation
  suhteelliset linkit ja vastaavuus live-koodiin. Koko neljän uuden tuotteen
  sisältö tarkastettu; git diff --check ja myös ignored/untracked-tuotteiden
  git diff --no-index --check ilman whitespace-virheitä. Ei automaattista
  importia, poistoa, aiempien ajojen ylikirjoitusta tai Git-kirjoitustoimintoa.
  Koko git-status säilyi lähtötilan mukaisena ennen kortin päivitystä.
  Tämän vaiheen ainoa repositorymuutos on kortin päivitys ja valtuutettu
  02-in-progress -> 03-review -siirto. Tuote on neljä uutta tiedostoa;
  allow-list on yhä config/-ignore-säännön alla, ei indeksitoimia.
- 2026-09-13T04:36:56+03:00 READY_FOR_REVIEW: kaikki pakolliset paikalliset portit PASS.
  Native Windows/OpenSSH/NTFS: NOT RUN (ei valtuutettua verkkosiirtoa eikä
  natiivia Windows-ajopintaa). Tämä jää ihmisen tarkastuksen avoimeksi
  validointirajoitteeksi, ei työpaketin 7 mukaiseksi review-esteeksi.
  K18/QC: NOT APPLICABLE, ei-tieteellinen siirtoinfrastruktuuri; ei analyysiajoa,
  raakadataa, osallistujatietoja tai manifestimuutoksia. Kortti siirretty
  03-review-tilaan; ihminen päättää myöhemmin hyväksynnästä ja done-siirrosta.

## Blockers

- Vaiheen 5 atomisuuseste RESOLVED työpaketin 5 auktoriteettipäätöksellä.
  Vaihe 5 korjattu ja paikallisesti validoitu: PASS.
- Vaiheet 6–7 PASS; ei pakollisten paikallisten porttien avoimia esteitä.
  Toteutus on valmis ihmisen tarkastukseen. Oikeaa Windows-siirtoa ei ole
  valtuutettu; natiivi Windows/OpenSSH/NTFS jää NOT RUN -rajoitteeksi.
- Allow-list on nykyisen config/-ignore-säännön alla. Sen versiohallintaan
  ottaminen jää erilliseksi ihmisen toimeksi; ignore-sääntöjä ei muutettu.
- Työnkulku-/neljän tiedoston rajausristiriita: RESOLVED käyttäjän
  valtuuttamalla erillisellä tehtäväkortilla.
- Vaiheiden 0b/0c aloitusrajaus: RESOLVED käyttäjän jatkokäskyllä.
- Vaiheen 4 paikallinen PowerShell-ajopinta: VERIFIED (7.4.1, Ubuntu-PRoot).
  Natiivi Windows/OpenSSH/NTFS on edelleen testaamatta.

## Links

- `SKILLS.md`: TODO System, Read-only-tarkastelu, Orchestration exceptions.
- `tools/run-gates.sh`: juuren tehtäväjonon portti ja read-only-tarkistus.
