# Projektirekisterihankkeen rajattu siivouskirjaus

## Tila

- State: `03-review`
- Tunniste: `project-registry-cleanup-001`
- Repo: Tupatuko2023/Python-R-Scripts
- Haara: chore/project-registry-cleanup-001
- Säilyvä toimitusworktree: tmp/project-registry-transfer-001.
- Pohja: c6b4953bdfe41aa85e07f667b2280d215f85c789.

## Tausta

Owner valtuutti tässä keskustelussa vain tämän hankkeen varmennettujen,
puhtaiden ja kokonaan toimitettujen worktreeiden ja paikallisten tehtävähaarojen
poistot ilman pakotusta sekä pilotin totuudenmukaisen siivouskirjauksen
commitit, pushin, PR:n ja toimituksen. Epäselvät kohteet säilytetään.
Päächeckouteja, muiden töitä tai etähaaroja ei muuteta. #12/#14–16 pysyvät avoimina.

## Lähtötiedot

AGENTS, SKILLS, steering, kontribuutioskill, molempien repoiden worktree-
ja haara-inventaariot, Git-tilat (myös ignored), DONE-kortit, PR:n HEAD/merge-
provenance sekä mainin Git-puu-/blob-vertailut squash-toimituksia varten.

## Tuotokset

- docs/governance/project_registry/PRJ-REGISTRY-ROLLOUT.md: vain toteutuneisiin
  poistoihin perustuva siivoushavainto ja säilytettyjen kohteiden syyt.
- Tämä uusi kortti; vanhoja DONE-tehtäviä ei avata uudelleen.

Viiden polun raja: valmistelu yksi polku, admission kaksi; toteutus pilotin
päivitys ja in-progress/review-korttipolut kolme. Poistot rajataan varmennettuun
Git-worktree-rekisteriin; ei manuaalisia hakemistopoistoja tai force-lippuja.

## Valmistumiskriteerit (DoD)

- Omistajuus osoitettu tehtävillä ja toimituksilla, ei hakemistonimellä.
- Aiemmat tuotokset ja DONE-kortit mainissa, squash huomioitu puu-/blob-näytöllä.
- Ennen poistoa puhdas index/työpuu, ei säilytettäviä untracked/ignored-artefakteja,
  eikä muuta aktiivista tehtävää/agenttia. Epäselvät kohteet säilytetään syineen.
- Vain git worktree remove ja git branch -d, ei forcea tai etähaarojen poistoja.
- Pilotin CSV validoitu, main-toimitus erillään todellisesta worktree-tilasta.
- Soveltuvat portit ja CI läpäisevät; siivouskirjaus toimitettu valtuutuksen mukaan.
- Tämä kirjaustehtävä pysyy review-tilassa erillistä ihmisen sulkemishyväksyntää
  varten; sen toimitus ei väitä Ownerin antaneen taskin DONE-hyväksyntää.

## Loki

- 2026-11-03: Inventaariot ja toimitukset tarkistettu. SKR1-maintenance on eri
  keskeneräinen tehtävä, se säilytetään. Baseline- ja transfer-worktreissä
  ignored Quantify-artefakteja/CI-näyttöä: säilytetään. Paikallisen sovituksen
  d9004251 on PR #216:n commit-listassa; pycache on uudelleen muodostettava.

## Esteet

Säilytettävät ignored-artefaktit estävät vain kyseisten worktreeiden poiston.

## Viitteet

- Pilotti: docs/governance/project_registry/PRJ-REGISTRY-ROLLOUT.md
- Käyttöönotto: tasks/04-done/project-registry-rollout-001.md

- 2026-11-03: READY löydetty ja Git-näkyvyys varmennettu erillisessä admission-työosuudessa; in-progress ennen siivouskirjausta.

## Toteutuneet siivoustoimet 2026-11-03

Poistettu tavallisella git worktree remove -komennolla, ei forcea:
- FOF: duplicate-keys, safe-export, directory-alias ja validation -worktreet
  Tupatuko2023/FOF-Dissertation-Project-repossa; täsmäpolut ja DONE-kortit
  on yksilöity pilotin worktree-taulukossa.
- Python-R-Scripts: tmp/project-registry-local-adaptation-001 ja
  tmp/project-registry-rollout-001.

Kaikista ennen poistoa status/index/untracked puhdas. Lähderepon neljässä ei
ignored-tiedostoja. Paikallissovituksessa vain kaksi uudelleen muodostettavaa
pyc-tiedostoa; rolloutissa vain validoitu/regeneroitava projects.csv (--check PASS).
Worktree-rekisteristä ja levyltä poissaolo tarkistetaan lopuksi. Kohteisiin
viittaavia erillisiä Python/Codex/Node/Bash/Git-prosesseja ei löydetty.

Source duplicate/safe/alias: HEAD mainin esi-isä ja DONE-kortti identtinen.
Source validation PR #349/#350/#351 sekä target rollout #219/#220: kokonaiset
Git-puut identtiset squash-mergeihin, jotka sisältyvät origin/mainiin.
Target transfer #216:n koko puu eroaa unrelated-main-pohjamuutoksista, mutta
kaikki neljä taskin tuoteblobia täsmäävät. #218 DONE-blobi täsmää mainiin.
Paikallissovituksen d9004251 ja baseline ce44996 ovat toimitetun PR #216:n
commit-listassa. Pelkkää commit-lukumäärää tai hakemistonimeä ei käytetty näyttönä.

Poistettu git branch -d:llä 8 haaraa (neljä per repo), nimet pilotin taulukon
jälkeisessä luettelossa. 3 vanhaa haaraa säilytetty normaalin -d:n kieltäydyttyä;
upstreamia, reflog-evidenssiä tai force-lippuja ei käytetty suojan ohittamiseen.

Säilytetty baseline (21 ignored-tiedostoa) ja transfer (1606 ignored-tiedostoa):
Quantifyn paikalliset tulokset ja manifesti, transferissa lisäksi CI-näyttö ja
Markdown-riippuvuudet. Ei niiden sisällön siirtoa, julkaisua tai poistoa.
FOF SKR1-maintenance-002 on eri, aktiivinen/likainen tehtävä; ei scopea.

Tämä task pysyy review-tilassa, kun kirjauksen portit/CI täyttyvät. Sen
DONE-siirrolle ei ole erillistä pysyvää ihmisomistajan hyväksyntää. Valtuutettu
siivouskirjaus voidaan toimittaa mainiin; main-toimitus ei ole taskin hyväksyntä.

- 2026-11-03: Kuuden poiston levy-/rekisterivarmennus PASS. CSV toimitus=delivered,
  siivous=retained, lähdekuvaus ennallaan. Markdown ja --check PASS. Kirjaus reviewiin;
  lopullisen HEADin CI ja julkaisu seurataan samalla Owner-valtuutuksella.

## Katselmointihuomioiden täsmennys 2026-11-03

Sourcery #2: lähdetehtävien repoidentiteetti ja täydet repojuureen suhteutetut
DONE-polut kirjattu pilottiin. Konekohtainen polkuesimerkki poistettu tästä lokista.
#3: otsikot suomennettu; sisällön merkitys ja lifecycle-tila ennallaan.

#1 koskee jo tapahtuneen poiston kirjoittajakilpailua, ei generaattorin koodia.
Käytettiin task-/toimitus-/puhtaus-/prosessinäyttöä, ei poissulkevaa lukkoa.
Tämä ei todista yksinomaista käyttöä inventaarion ja poiston koko aikavälillä.
Aiempi ilmaisu prosessien puuttumisesta tarkoittaa vain ettei niitä havaittu
tehdyssä tarkistuksessa. Yhtään menetettyä artefaktia ei havaittu, mutta
menetysten ehdotonta mahdottomuutta ei väitetä. Jälkikäteistä lukitusnäyttöä
ei voida tuottaa totuudenmukaisesti. Ei uusia poistoja tai toteutuksen laajennusta.
Siivouskirjauksen main-toimitus odottaa tämän historiallisen rajan katselmointia.
