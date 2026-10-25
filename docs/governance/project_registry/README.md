# Projektirekisteri: siirtopaketti 1.0.0

Projektitiedosto on ylläpidettävä lähde, josta generaattori muodostaa CSV-näkymän.
CSV:tä ei muokata käsin. Tämä vaihe tuo työkalun ja paikallisen ohjeen;
projektipohja, AGENTS-kytkentä ja yhden aidon koordinointiprojektin pilotti
tehdään erikseen. Tässä hakemistossa ei vielä ole projektitiedostoja, joten
oletusgenerointi ilmoittaa `no PRJ-*.md files` ennen pilotin valmistelua.

## Versio ja alkuperä

| Tieto | Arvo |
|---|---|
| Paikallisen siirtopaketin versio | `1.0.0` (ei lähderepon tagi) |
| Lähderepo | `Tupatuko2023/FOF-Dissertation-Project` |
| Toimitettu lähdecommit | `a098b62e9cce7079f84ef4cfd0665ddef93ca816` |
| Generaattorin Git-blob | `de92f22219e2abf479bb98eb79896d4d66442865` |
| Testien Git-blob | `2b108e05a1f260395ef62165b0231fe4bbde6f9b` |

`tools/project_registry/render_projects_csv.py` ja sen testit on siirretty
lähdecommitin mukaisina. Käyttöohje on sovitettu tähän repoon. Myöhemmät
työkalukorjaukset verrataan kirjattuun lähdeversioon ennen siirtoa.
Python 3.11+ ja paikallinen Git riittävät generaattoritesteihin; uusi
Python-riippuvuus ei kuulu pakettiin. Muun repon testit tarvitsevat omat riippuvuutensa.

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

| repo | task | path |
|---|---|---|
| `Tupatuko2023/Python-R-Scripts` | kortin tunniste tai otsikko | `tasks/<elinkaarikansio>/<kortti>.md` |
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

| Vaihe | Päivitys |
|---|---|
| Aloitus | agentti, aloituspäivä, tilahavainto, tehtäväviitteet ja seuraava askel |
| Merkittävä välivaihe | viimeisin tilanne ja evidenssi sekä seuraava askel |
| Keskeytys | este, keskeytyssyy, päivämäärä ja vastuullinen seuraava toimija |
| Toimitus | toimitustila ja varmennettu commit-/PR-viite |
| Projektin sulku | sulkutila ja päivä vain paikallisten ihmishyväksyntöjen jälkeen |
| Worktree-havainto | erillinen inventaarion kattavuus ja säilytys-/poistoevidenssi |

Yhden kortin DONE ei automaattisesti sulje monitehtäväistä projektia.
Paikallisen tehtävän review -> done noudattaa SKILLS.md:n riippumattoman,
pysyvän ihmishyväksyntänäytön sääntöä. Agentti ei hyväksy omaa työtään.
Lähdekuvaus säilytetään sanatarkkana; sen versiointi vaatii ihmisomistajan päätöksen.
Ristiriita tai epäonnistunut päivitys kirjataan oman tehtävän lokiin syineen;
hyväksyttyä arvoa ei korvata arvauksella eikä osittaista päivitystä jätetä hiljaa.

## Projektitiedoston sopimus

Polku on `docs/governance/project_registry/PRJ-<SLUG>.md`.
Tunniste käyttää isoja kirjaimia, numeroita ja väliviivalla erotettuja osia;
tiedostonimi vastaa pysyvää `id`-arvoa. Jäsennin tukee litteitä `key: value`
-kenttiä ja merkkijonolistoja, ei yleistä YAMLia tai sisäkkäisiä olioita.
Toistuva avain hylätään, vaikka arvot olisivat samat. Virhe kertoo tiedoston,
avaimen ja rivin ennen CSV:n kirjoittamista.

| Kentät | Merkitys |
|---|---|
| `id`, `title`, `short_name` | pysyvä tunniste, nimi ja lyhyt näyttönimi |
| `repo`, `repo_ref` | repoidentiteetti ja kanoninen ref-nimi, esimerkiksi `origin/main` |
| `state`, `delivery` | projektin tila ja erillinen toimitustila |
| `goal`, `done_criterion` | tavoite ja todennettava projektin valmistumiskriteeri |
| `latest_status`, `next_step` | viimeisin havainto ja seuraava konkreettinen toimi |
| `source_description_sha256`, `source_captured_at` | lähdekuvauksen SHA256 ja talteenottopäivä |
| `observed_at`, `observed_commit`, `observed_worktree_label` | havainnon päivä, commit ja lyhyt konelabel |

Yllä olevat kentät ovat pakollisia ja ei-tyhjiä. `PENDING` ei kelpaa ratkaisuksi.
`repo_ref` ei sisällä havaintocommittia; se kuuluu `observed_commit`-kenttään.
Paikallinen vertailu refiin ei itsessään todista etäsynkronointia.

Valinnaiset kentät: `blocker`, `orchestrator`, `agent`, `agent_tool`, `environment`,
`started_date`, `paused_date`, `completed_date`, `pause_reason`, `link`, `tasks`
ja `worktree_inventory`. Roolit ovat paikallisesti sovittavia tietoja, eivät
lähderepon orkestroijan nimiä. Tyhjä este tarkoittaa ettei estettä ole kirjattu,
ei varmennettua esteettömyyttä. Puuttuvien roolien viennissä käytetään eksplisiittisiä
`NOT_SET`-, `NOT_ASSIGNED`- ja `NOT_RECORDED`-arvoja.

Päiväkentät käyttävät `YYYY-MM-DD`-muotoa. Frontmatteriin ei kirjoiteta
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

## Komennot ja kirjoitussuoja

Aja komennot tämän worktreen repojuuresta, varmista ensin `Get-Location`.
Esimerkkien `<id>` ja `<luettu-commit>` korvataan todellisilla arvoilla.

```text
python tools/project_registry/render_projects_csv.py --verify-guard docs/governance/project_registry/<id>.md --expect-commit <luettu-commit>
python tools/project_registry/render_projects_csv.py --print-source-hash docs/governance/project_registry/<id>.md
python tools/project_registry/render_projects_csv.py --registry docs/governance/project_registry --output outputs/cache/project_registry/projects.csv
python tools/project_registry/render_projects_csv.py --check
git check-ignore -v -- outputs/cache/project_registry/projects.csv
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
Tämän siirtopaketin tehtävä ei valtuuta projektin ensiluontia.

Generointi kirjoittaa vain yhden nimetyn CSV:n, ei rekisterilähteitä. Virheellinen
rekisteri ei luo CSV:tä eikä muuta vanhaa CSV:tä. Kirjoitustila vaatii Git-ignoroidun
tulospolun; nykyinen `**/outputs/` kattaa oletuspolun. Trackattuun tulospolkuun ei
kirjoiteta. `--skip-ignore-check` kuuluu vain synteettisiin testeihin.

`--check` validoi lähteet ja vertaa CSV:n tavuja kirjoittamatta: exit 0 = sama,
exit 2 = puuttuva tai vanhentunut näkymä; validointivirhe on exit 1.
Se ei tarkista ignore-porttia, joten aja yllä oleva `git check-ignore` erikseen.
Virheelliset komentoriviargumentit palauttavat argparsen exit 2:n; lähdekoodin
vanhaa usage-exit 3 -mainintaa ei käytetä tämän paketin hyväksymiskriteerinä.

## CSV-sarakkeet

UTF-8-vienti käyttää 20 saraketta, LF-rivinvaihtoja ja CSV-quotingia. Järjestys
on pysyvä ja projektit lajitellaan tunnisteella. Vienti ei ole lähteen legacy-taulukon migraatio.

| # | Sarake | Lähde |
|---|---|---|
| 1 | Projekti-ID | id |
| 2 | Projekti | sanatarkka lähdekuvauslohko |
| 3 | Nimi | short_name |
| 4 | Tavoite ja valmistumiskriteeri | goal + done_criterion |
| 5 | Tila | state |
| 6 | Viimeisin tilanne | latest_status |
| 7 | Seuraava toimenpide | next_step |
| 8 | Este | blocker tai none_recorded |
| 9 | Toimituksen tila | delivery |
| 10 | Worktree-siivous | worktree-taulukko ja inventaarion kattavuus |
| 11 | lyhenne | id ilman PRJ-etuliitettä |
| 12 | Orkestroija | orchestrator |
| 13 | Agentinnimi | agent |
| 14 | Agentti | agent_tool |
| 15 | ympäristö | environment |
| 16 | pvm_aloitettu | started_date |
| 17 | pvm_jäi_kesken | paused_date |
| 18 | pvm_valmis | completed_date |
| 19 | Jos, niin miksi projekti on nyt jäissä | pause_reason |
| 20 | Linkki | link |

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
`--check`, ignore-tarkistus ja ennen projektipäivitystä Git-suoja. Tyhjän
rekisterin vuoksi tässä vaiheessa CLI-smoke tehdään synteettisessä väliaikaisessa
repossa, ei luomalla kohderepoon projektirivejä.

Pakollinen portti ajetaan sallitussa ympäristössä; `--help` ei ole PASS-näyttö.
Stageaa ennen toimitusporttia vain tarkistetut tehtäväpolut, koska osa tarkistuksista
lukee indeksiä. Älä asenna riippuvuuksia tai muuta ympäristön oikeuksia hiljaa.
K18/QC ei sovellu tähän päärepon ei-tieteelliseen työkalusiirtoon.

Myöhempi pilotti varmistaa lisäksi oikean repoidentiteetin, samannimisten korttien
erottamisen täydellä polulla ja alihakemistojen jäämisen keräilyn ulkopuolelle.
AGENTS-velvoite ja projektipohja otetaan käyttöön erillisissä rajatuissa tehtävissä.
