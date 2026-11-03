# Projektirekisteri: siirtopaketti 1.0.3

Projektitiedosto on ylläpidettävä lähde, josta generaattori muodostaa CSV-näkymän.
CSV:tä ei muokata käsin. Päärepon käyttöönoton pilotti on
`PRJ-REGISTRY-ROLLOUT.md`. Se kuvaa tämän rekisterin käyttöönottoa ja
jatkamista; aliprojektien projektitietoja ei kerätä automaattisesti mukaan.
Toteutus, hyväksytty main-toimitus ja worktree-siivous kirjataan erikseen.

## Versio ja alkuperä

| Tieto                            | Arvo                                       |
| -------------------------------- | ------------------------------------------ |
| Paikallisen siirtopaketin versio | `1.0.3` (ei lähderepon tagi)               |
| Lähderepo                        | `Tupatuko2023/FOF-Dissertation-Project`    |
| Toimitettu lähdecommit           | `de850e13f2e2165ab01d647c28f40c06f00a1b43` |
| Lähdegeneraattorin Git-blob      | `98d606fc4d057f21c87db76bcd96cf2e853c0b69` |
| Lähdetestien Git-blob            | `b281dd224ed2df64d206a80fc5798ca98f01859d` |

Lähdekorjaus toimitettiin PR #349:ssä yllä nimettyyn main-committiin.
Taulukon blobit ovat tämän toimitetun lähdeversion Git-objekteja.
Paikallinen sovitus perustuu tarkistettuun valmistelucommittiin `d9004251`.

Paikalliset poikkeamat yllä kirjatusta lähteestä:

- generaattorin oletustulospolku ja sitä kuvaava moduuliteksti;
- testit `PythonRScriptsAdaptationTests`: työkalukohtainen oletusvienti ja
  kaava-alkuisen tekstin muuttumaton CSV-vienti;
- tämä kohderepon käyttöohje.

Generaattorin ja testien ei siis väitetä olevan tavuntarkkoja upstream-kopioita.
Upstream-korjaukset sovitetaan ensin kirjattuun lähdeversioon ja nämä rajatut
paikalliset poikkeamat säilytetään erikseen tunnistettavina.
Python 3.11+ ja paikallinen Git riittävät generaattoritesteihin; uusi
Python-riippuvuus ei kuulu pakettiin. Muun repon testit tarvitsevat omat riippuvuutensa.

## Turvallinen vienti

Jokainen projektitiedosto luetaan kerran ajokohtaiseksi tilannekuvaksi. Metadata
ja kuvaus validoidaan ja viedään samasta sisällöstä; kuvausta ei lueta uudelleen.
Lähteeseen viittaava kova tai symbolinen tuloslinkki hylätään. CSV muodostetaan
erilliseen, saman kohdehakemiston väliaikaistiedostoon ja julkaistaan atomisella
vaihdolla. Kirjoitus- tai vaihtovirhe säilyttää lähteet ja aiemman CSV:n.
Generaattori siivoaa vain oman ajonsa väliaikaistiedoston.

Tulospolun hakemistokomponenttien aliasit ratkaistaan ennen Git-porttia.
Ignore-tarkistus ja atominen julkaisu käyttävät samaa todellista
hakemistomerkintää. Kohteen on kuuluttava ajon Git-repoon ja oltava ignoroitu;
indeksissä tai HEADissa seurattu tiedosto hylätään myös aliaspolun ja
staged-poiston kautta. Toiseen tai sisäkkäiseen Git-repoon johtava alias
hylätään. Kohde ja Git-suoja tarkistetaan uudelleen ennen julkaisua, joten
myös kirjoituksen aikainen aliasin tai tracking-/ignore-tilan muutos hylätään.
Viimeinen symbolinen linkki korvataan hakemistomerkintänä; sen kohdetta ei
avata kirjoitukseen. Rekisterilähteeseen viittaava linkki hylätään aina.

## Omistajuus ja rajaus

Ensimmäinen pilotti kuuluu päärepon koordinointiin. Omistava repoidentiteetti on
`Tupatuko2023/Python-R-Scripts`. Projektitiedoston `repo` tarkistetaan erikseen
tätä vasten: generaattori tarkistaa kentän olemassaolon, ei oikeaa repoidentiteettiä.
Lähderepon projekteja ei kopioida mukana.

Fear-of-Falling ja Quantify-FOF-Utilization-Costs ovat tässä repossa hakemistoja,
joilla on omat tehtäväjononsa ja ohjeensa. Niiden tehtäviä ei nosteta automaattisesti
päärepon projekteiksi. Projektin koontitieto ei korvaa tehtäväkortin elinkaarta,
valtuutusta, evidenssiä tai ihmishyväksyntää. Paikalliset AGENTS.md-, SKILLS.md-,
agent_policy- ja steering-säännöt säilyvät voimassa kaikissa työvaiheissa.

Generaattori lukee vain nimetyn rekisterihakemiston suorat `PRJ-*.md`-tiedostot.
Se ei lue tehtäväjonoja eikä käy rekursiivisesti aliprojekteissa, worktreeissä
tai arkistoissa. Päärepon ensimmäinen rekisteri pidetään vain päärepon omille
koordinointiprojekteille; muiden rekisterien koonti on erillinen tuleva työ.

## Tehtäväviitteet

Tehtävän yksilöi **repoidentiteetti ja koko repojuureen suhteutettu polku**.
Pelkkä TASK-tunnus tai tiedostonimi ei ole globaalisti yksilöllinen.
Projektitiedoston rungossa voi käyttää taulukkoa:

| repo                            | task                                     | path                                                  |
| ------------------------------- | ---------------------------------------- | ----------------------------------------------------- |
| `Tupatuko2023/Python-R-Scripts` | kortin tunniste tai otsikko              | `tasks/<elinkaarikansio>/<kortti>.md`                 |
| `Tupatuko2023/Python-R-Scripts` | aliprojektin kortin tunniste tai otsikko | `Fear-of-Falling/tasks/<elinkaarikansio>/<kortti>.md` |

Taulukko on viitekäytäntö, ei generaattorin validoima sisäkkäinen skeema.
Toiseen repoon viitattaessa käytetään sen pysyvää repoidentiteettiä ja sen juureen
suhteutettua polkua, ei tämän koneen checkout-polkua tai `../`-navigointia.
Repojuureen suhteutettu polku on looginen viite: rekisteritiedoston sijainnista
avattava Markdown-linkki on tarvittaessa muodostettava erikseen.

Kortteja tai niiden tiloja ei kopioida rinnakkaisiksi ylläpidettäviksi tiedoiksi.
Projektin yhteenveto kertoo nykytilanteen, seuraavan askeleen ja esteen
evidenssiviitteineen. Historiallinen tilahavainto merkitään päivättynä havaintona.
Frontmatterin `tasks`-lista voi sisältää paikallisia tunnisteita, mutta lista
ei yksin riitä monirepoviitteeksi. Viitetaulukkoa ei viedä nykyiseen CSV:hen.

## Päivitysvastuut ja työvaiheet

Projektin ihmisomistaja vahvistaa repo-kohdistuksen, tavoitteen ja hyväksynnät.
Tehtävää tekevä agentti saa päivittää vain projektitiedostoa, joka kuuluu
tehtävän sallittuihin kirjoituspolkuihin. Tämä ohje ei laajenna kirjoitusvaltuutta.

| Vaihe                | Päivitys                                                               |
| -------------------- | ---------------------------------------------------------------------- |
| Aloitus              | agentti, aloituspäivä, tilahavainto, tehtäväviitteet ja seuraava askel |
| Merkittävä välivaihe | viimeisin tilanne ja evidenssi sekä seuraava askel                     |
| Keskeytys            | este, keskeytyssyy, päivämäärä ja vastuullinen seuraava toimija        |
| Toimitus             | toimitustila ja varmennettu commit-/PR-viite                           |
| Projektin sulku      | sulkutila ja päivä vain paikallisten ihmishyväksyntöjen jälkeen        |
| Worktree-havainto    | erillinen inventaarion kattavuus ja säilytys-/poistoevidenssi          |

Yhden kortin DONE ei automaattisesti sulje monitehtäväistä projektia.
Paikallisen tehtävän review -> done noudattaa SKILLS.md:n riippumattoman,
pysyvän ihmishyväksyntänäytön sääntöä. Agentti ei hyväksy omaa työtään.
Lähdekuvaus säilytetään sanatarkkana; sen versiointi vaatii ihmisomistajan päätöksen.
Ristiriita tai epäonnistunut päivitys kirjataan oman tehtävän lokiin syineen;
hyväksyttyä arvoa ei korvata arvauksella eikä osittaista päivitystä jätetä hiljaa.

## Uusi projektitietue pohjasta

`TEMPLATE.md` on tyhjä täyttöpohja: se ei ole validoitu projektitietue eikä
sen nimi täsmää `PRJ-*.md`-keräilyyn. Kopioi se vain tehtävän sallimaan uuteen
`PRJ-<SLUG>.md`-polkuun, täytä kaikki pakolliset kentät ja säilytä hyväksytty
lähdekuvaus lohkomerkkien välissä. Tyhjät päivät/commit/hash eivät kelpaa
valmiissa projektitiedostossa. `tasks` on merkkijonolista; poista pohjan
esimerkkialkio tai korvaa se oikealla tunnisteella. Päivitä viitetaulukkoon
repoidentiteetti ja koko repojuureen suhteutettu tehtäväpolku.

Laske täytetyn lähdelohkon hash `--print-source-hash`-komennolla ja kirjaa se
`source_description_sha256`-kenttään. `observed_commit` on havaintohetkellä
luettu täysi Git-commit, ei myöhemmin automaattisesti aina HEADiin täsmäävä
synkronointiväite. Varmista repoidentiteetti erikseen ja validoi ennen commitia.
Guard vaatii ensimmäisen commitin; myöhemmissä päivityksissä käytä alla kuvattua
suojaa. Älä päivitä lähdekuvausta ilman ihmisomistajan päätöstä.

## Projektitiedoston sopimus

Polku on `docs/governance/project_registry/PRJ-<SLUG>.md`.
Tunniste käyttää isoja kirjaimia, numeroita ja väliviivalla erotettuja osia;
tiedostonimi vastaa pysyvää `id`-arvoa. Jäsennin tukee litteitä `key: value`
-kenttiä ja merkkijonolistoja, ei yleistä YAMLia tai sisäkkäisiä olioita.
Toistuva avain hylätään, vaikka arvot olisivat samat. Virhe kertoo tiedoston,
avaimen ja rivin ennen CSV:n kirjoittamista.

| Kentät                                                      | Merkitys                                                          |
| ----------------------------------------------------------- | ----------------------------------------------------------------- |
| `id`, `title`, `short_name`                                 | pysyvä tunniste, nimi ja lyhyt näyttönimi                         |
| `repo`, `repo_ref`                                          | repoidentiteetti ja kanoninen ref-nimi, esimerkiksi `origin/main` |
| `state`, `delivery`                                         | projektin tila ja erillinen toimitustila                          |
| `goal`, `done_criterion`                                    | tavoite ja todennettava projektin valmistumiskriteeri             |
| `latest_status`, `next_step`                                | viimeisin havainto ja seuraava konkreettinen toimi                |
| `source_description_sha256`, `source_captured_at`           | lähdekuvauksen SHA256 ja talteenottopäivä                         |
| `observed_at`, `observed_commit`, `observed_worktree_label` | havainnon päivä, commit ja lyhyt konelabel                        |

Yllä olevat kentät ovat pakollisia ja ei-tyhjiä. `PENDING` ei kelpaa ratkaisuksi.
`repo_ref` ei sisällä havaintocommittia; se kuuluu `observed_commit`-kenttään.
Paikallinen vertailu refiin ei itsessään todista etäsynkronointia.

Valinnaiset kentät: `blocker`, `orchestrator`, `agent`, `agent_tool`, `environment`,
`started_date`, `paused_date`, `completed_date`, `pause_reason`, `link`, `tasks`
ja `worktree_inventory`. Roolit ovat paikallisesti sovittavia tietoja, eivät
lähderepon orkestroijan nimiä. Tyhjä este tarkoittaa ettei estettä ole kirjattu,
ei varmennettua esteettömyyttä. Puuttuvien roolien viennissä käytetään eksplisiittisiä
`NOT_SET`-, `NOT_ASSIGNED`- ja `NOT_RECORDED`-arvoja.

Päiväkentät käyttävät todellista kalenteripäivää muodossa `YYYY-MM-DD`, myös
karkauspäivät tarkistetaan. Frontmatteriin ei kirjoiteta
absoluuttisia konepolkuja tai Gitin sisäisiä polkuja. Validointi ei ole yleinen
salaisuus- tai polkuskanneri; sisällön tarkastus kuuluu kirjoittajalle.

- `state`: `planned | active | paused | closed | unknown`.
- `delivery`: `not_delivered | delivered | unknown`.
- `worktree_inventory`: `unknown | complete`, oletus `unknown`.

Rungossa alkuperäinen yksityiskohtainen kuvaus säilytetään merkkien
`<!-- source-description:begin -->` ja `<!-- source-description:end -->` välissä.
SHA256 lasketaan tallennetusta lohkosta UTF-8-muodossa LF-normalisoinnin jälkeen.
Lohkon sanat, pilkut, lainaukset ja rivinvaihdot säilyvät CSV:n `Projekti`-solussa.

Täsmällisen `## Worktree-havainnot`-otsikon alla taulukon sarakkeet ovat
`label | state | evidence`; rivitilat `active | retained | removed | unknown`.
CSV:n `removed` vaatii vähintään yhden poistetun worktreen ja `complete`-inventaarion.
Tyhjä tai kattavuudeltaan tuntematon inventaario antaa `unknown`; aktiivinen tai
säilytetty työpuu antaa `retained`. Toimitus ja projektin sulku eivät todista siivousta.

## Kenttävalidoinnin rajattu sopimus

`repo_ref` tarkistetaan Gitin `check-ref-format --allow-onelevel` -syntaksilla.
Refin ei tarvitse olla paikallisessa repossa olemassa; esimerkiksi `main`,
`origin/main` ja `refs/heads/main` ovat sallittuja nimiä. Optioksi tulkittava
alkuväliviiva ja NUL-merkki hylätään ennen Git-prosessia.

Tunnetut pakolliset ja valinnaiset skalaarikentät vaativat merkkijonon.
`tasks` on merkkijonolista. Sisäkkäiset mapping-rakenteet ja inline-kokoelmat
hylätään hallitusti; lainattu vapaa teksti voi sisältää esimerkiksi kaksoispisteen ja välilyönnin.
Yleistä YAML-tulkintaa tai escape-sekvenssien dekoodausta ei lisätä.

Kanonisten tunniste-, repo-, ref-, tila-, päivämäärä-, hash-, havaintocommit-
ja worktree-label-/inventory-kenttien reunavälilyönnit hylätään. Vapaata tekstiä
ja kaava-alkuisia soluja ei trimmata tai kirjoiteta uudelleen.

Puuttuvat tai väärässä järjestyksessä olevat lähdekuvausmerkit sekä lähteen
luku-, UTF-8-, listaus- ja stat-virheet palauttavat hallitun, tiedoston
nimeävän validointivirheen. Virheellinen lähde ei luo CSV:tä eikä muuta vanhaa.
Myös lähdehashin tulostus käyttää hallittua virhesopimusta.

## Komennot ja kirjoitussuoja

Aja komennot tämän worktreen repojuuresta, varmista ensin `Get-Location`.
Esimerkkien `<id>` ja `<luettu-commit>` korvataan todellisilla arvoilla.

```text
python tools/project_registry/render_projects_csv.py --verify-guard docs/governance/project_registry/<id>.md --expect-commit <luettu-commit>
python tools/project_registry/render_projects_csv.py --print-source-hash docs/governance/project_registry/<id>.md
python tools/project_registry/render_projects_csv.py --registry docs/governance/project_registry --output tools/project_registry/outputs/projects.csv
python tools/project_registry/render_projects_csv.py --check
git check-ignore -v -- tools/project_registry/outputs/projects.csv
```

`--verify-guard`: exit 0 tarkoittaa muuttumatonta HEAD/index/työpuu-versiota;
exit 1 ilmoittaa esimerkiksi käyttäjän muutoksen tai commitoimattoman tiedoston;
exit 2 kertoo vanhasta tai vieraasta havaintocommitista. Lue lähde uudelleen tai
raportoi ristiriita. Älä käytä stashia, resetiä tai restorea suojan kiertämiseen.
Tämä on erillinen ennen kirjoitusta ajettava tarkistus, ei automaattinen lukko.

Ensiluonnissa tiedostolla ei vielä ole HEAD-blobia, joten guard ei voi hyväksyä sitä.
Luo uusi projekti vain erikseen rajatussa tehtävässä: tarkista tunniste ja polun
puuttuminen, säilytä mahdolliset olemassa olevat tiedostot, validoi uusi tiedosto
ja toimita se paikallisen käytännön mukaan. Myöhemmät päivitykset käyttävät guardia.
Uuden projektin ensiluonti vaatii aina sen nimen ja kirjoituspolun kattavan
tehtävän; pelkkä työkalun käyttöönotto ei valtuuta muiden projektien luontia.

Generointi julkaisee yhden nimetyn CSV:n erillisen väliaikaistiedoston kautta;
rekisterilähteitä ei kirjoiteta. Virheellinen
rekisteri ei luo CSV:tä eikä muuta vanhaa CSV:tä. Kirjoitustila vaatii Git-ignoroidun
tulospolun. Oletus on työkalun oma `tools/project_registry/outputs/`, ei yhteinen
päärepon `outputs/`. Valinta perustuu AGENTS.md:n aliprojektin tuloskäytäntöön
ja SKILLS.md:n skriptikohtaisiin tuloksiin; nykyinen `**/outputs/` kattaa
sekä CSV:n että saman hakemiston väliaikaistiedostot. Ignore-varmennus tehdään
sääntöjenmukaisuuden lisäksi erikseen. Trackattuun tulospolkuun ei
kirjoiteta. `--skip-ignore-check` kuuluu vain synteettisiin testeihin.

`--check` validoi lähteet ja vertaa CSV:n tavuja kirjoittamatta: exit 0 = sama,
exit 2 = puuttuva tai vanhentunut näkymä; validointivirhe on exit 1.
Se ei tarkista ignore-porttia, joten aja yllä oleva `git check-ignore` erikseen.
`--check`, `--verify-guard` ja `--print-source-hash` ovat toisensa poissulkevia.
`--expect-commit` kuuluu vain guard-moodiin. Ristiriitaiset moodit, tyhjät
FILE-/expect-arvot ja muut virheelliset komentoriviargumentit palauttavat
argparsen exit 2:n ennen lähdelukua tai CSV:n kirjoittamista.

## CSV taulukkolaskennassa: tuo kaikki sarakkeet tekstinä

CSV säilyttää alkuperäisen solutekstin sanatarkkana. Myös esimerkiksi
`=1+1` tai `=SUM(1,1)` voi olla tarkoituksellista tekstiä. Generaattori ei
lisää apostrofia, muuta sisältöä kaavaksi eikä poista kaavamerkkejä.
CSV:n lainausmerkit suojaavat CSV-rakennetta, eivät määrää solun tyyppiä.

Älä avaa CSV:tä kaksoisnapsautuksella tai oletusarvoisella automaattituonnilla.
Tuo se erikseen ja aseta **kaikki sarakkeet tekstiksi**:

- **LibreOffice Calc:** avaa tekstin tuonti, valitse kaikki sarakkeet ja
  saraketyypiksi **Teksti**. Poista **Evaluate formulas / Arvioi kaavat**
  käytöstä ennen tuontia. Pelkkä CSV-quoting ei korvaa tätä asetusta.
- **Excel:** käytä **Tiedot → Tekstistä/CSV:stä → Muunna tiedot**. Poista
  automaattinen tyyppitunnistus ja mahdollinen automaattinen tyypinmuutosvaihe;
  aseta kaikki sarakkeet tyypiksi **Teksti** ennen lataamista. Käytä tekstin
  tuontia, älä CSV:n suoraa avaamista kaavoja arvioivalla oletustulkinnalla.

Valitse UTF-8 ja pilkku erottimeksi. Tarkista tuonnin jälkeen, että testiteksti
`=1+1` näkyy sellaisenaan, ei laskettuna arvona `2`. Käyttöohjeen asetukset
estävät kaavojen arvioinnin; CSV-tiedosto ei itsessään sisällä tyyppisuojausta.

Asetusten lähteet: [Calcin tekstin tuonti](https://help.libreoffice.org/latest/fi/text/shared/00/00000208.html)
ja [Microsoftin Text/CSV-tuonti](https://learn.microsoft.com/en-us/power-query/connectors/text-csv).

## CSV-sarakkeet

UTF-8-vienti käyttää 20 saraketta, LF-rivinvaihtoja ja CSV-quotingia. Järjestys
on pysyvä ja projektit lajitellaan tunnisteella. Vienti ei ole lähteen legacy-taulukon migraatio.

| #   | Sarake                                 | Lähde                                       |
| --- | -------------------------------------- | ------------------------------------------- |
| 1   | Projekti-ID                            | id                                          |
| 2   | Projekti                               | sanatarkka lähdekuvauslohko                 |
| 3   | Nimi                                   | short_name                                  |
| 4   | Tavoite ja valmistumiskriteeri         | goal + done_criterion                       |
| 5   | Tila                                   | state                                       |
| 6   | Viimeisin tilanne                      | latest_status                               |
| 7   | Seuraava toimenpide                    | next_step                                   |
| 8   | Este                                   | blocker tai none_recorded                   |
| 9   | Toimituksen tila                       | delivery                                    |
| 10  | Worktree-siivous                       | worktree-taulukko ja inventaarion kattavuus |
| 11  | lyhenne                                | id ilman PRJ-etuliitettä                    |
| 12  | Orkestroija                            | orchestrator                                |
| 13  | Agentinnimi                            | agent                                       |
| 14  | Agentti                                | agent_tool                                  |
| 15  | ympäristö                              | environment                                 |
| 16  | pvm_aloitettu                          | started_date                                |
| 17  | pvm_jäi_kesken                         | paused_date                                 |
| 18  | pvm_valmis                             | completed_date                              |
| 19  | Jos, niin miksi projekti on nyt jäissä | pause_reason                                |
| 20  | Linkki                                 | link                                        |

Repoidentiteetti, koko viitetaulukko, lähdehash ja havaintoprovenance ovat
projektitiedostossa; CSV on rajallinen näkymä, ei täydellinen rekisterivarmistus.

## Validointi ja jatkovaiheet

```powershell
Get-Location
python -B -m unittest discover -s tools/project_registry/tests -p test_render_projects_csv.py
python -m pytest -q
& ./tools/run-gates.ps1 --mode pre-push --smoke
git diff --check
```

Testit käyttävät synteettistä väliaikaista aineistoa ja Git-repoja. Rekisterin
normaalissa käytössä vaaditaan myös generointi kahdesti, tavujen vertailu,
`--check`, ignore-tarkistus ja ennen projektipäivitystä Git-suoja. Päärepon pilotti käyttää yhtä nimettyä koordinointiprojektia.
Keräilyraja ja virhetilanteet kokeillaan synteettisessä väliaikaisessa repossa,
ei aliprojektien kortteja tai tiloja muuttamalla.

Pakollinen portti ajetaan sallitussa ympäristössä; `--help` ei ole PASS-näyttö.
Stageaa ennen toimitusporttia vain tarkistetut tehtäväpolut, koska osa tarkistuksista
lukee indeksiä. Älä asenna riippuvuuksia tai muuta ympäristön oikeuksia hiljaa.
K18/QC ei sovellu tähän päärepon ei-tieteelliseen työkalusiirtoon.

Pilotti varmistaa lisäksi oikean repoidentiteetin, täydet tehtäväpolut,
mallin ja alihakemistojen jäämisen keräilyn ulkopuolelle sekä jatkamisen
projektitiedon perusteella ilman chattia. Tehtäväkortti sisältää testinäytön;
pilotin löytyminen työhaarasta ei vielä todista hyväksyttyä main-toimitusta.

## Avoimet jatkoehdotukset

Sourcery-kommentit #12 ja #14–16 eivät kuulu tähän korjauserään eikä niitä
esitetä ratkaistuiksi: fyysisen lähdehakemistorajan ja symlinkkien sopimus,
tuntemattomien avainten diagnostiikka, escape-merkkien täsmällinen tulkinta
sekä rinnakkaisten vientien julkaisu-/järjestystakuu. Ne arvioidaan erikseen;
nykyinen vienti takaa validoidun tilannekuvan, ei uusimman rinnakkaisajon voittoa.
Niitä ei ole tutkittu loppuun. Rajattu toimitus edellyttää luotettua,
katselmoitua rekisterisyötettä ja kenttien manuaalista tarkastusta; työkalu
ei ole epäluotettavan syötteen palvelu. Omistaja arvioi rajoitteiden sopivuuden
ennen uuden revision hyväksyntää. CSV:n kaavatekstin säilyminen
ei tarkoita turvallista avaamista taulukkolaskennan oletusasetuksilla.
