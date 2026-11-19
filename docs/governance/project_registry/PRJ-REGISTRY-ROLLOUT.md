---
id: "PRJ-REGISTRY-ROLLOUT"
title: "Projektirekisterin käyttöönotto analyysirepossa"
short_name: "Rekisterin käyttöönotto"
repo: "Tupatuko2023/Python-R-Scripts"
repo_ref: "origin/main"
state: "closed"
delivery: "delivered"
goal: "Agentti löytää, päivittää ja jatkaa päärepon ja aliprojektien nimettyjä projekteja yhteisen projektirekisterin ja tehtäväviitteiden avulla ilman rinnakkaista tehtäväjonoa."
done_criterion: "Yleisen käytön ohjeet (README, AGENTS.md, SKILLS.md, GEMINI.md, Fear-of-Falling/GEMINI.md) ja tämän projektitietueen jatkovaihe on validoitu, ihmisen hyväksymä ja varmennettu mainista; pilotin toimitus- ja siivoushistoria sekä alkuperäinen lähdekuvaus säilyvät."
latest_status: "2026-11-19: Jatkovaiheen työpuu tmp/project-registry-general-adoption-001 sekä paikalliset haarat poistettu valtuutetussa siivouksessa (worktree-cleanup-001) PR #225/#226:n toimitusnäytöllä; baseline- ja transfer-työpuut sekä etähaarat säilytetään."
next_step: "Rekisteri on koko repon normaalissa käytössä. Luo tai päivitä projektitietueita vain tehtäväkortin valtuuttamilla kirjoituspoluilla README-ohjeen mukaan; älä avaa valmiita käyttöönottokortteja uudelleen."
source_description_sha256: "83d725739700bef4dbd47f3bb23777d389cdf7096148d40b0a57301b3af27dd1"
source_captured_at: "2026-11-03"
observed_at: "2026-11-19"
observed_commit: "b12155dd760e86bc0077d0ad966fc5ee08c0c135"
observed_worktree_label: "registry-general-adoption"
blocker: ""
orchestrator: "FCPO2"
agent: "Antigravity"
agent_tool: "Antigravity"
environment: "Windows PowerShell; GitHub Ubuntu CI"
started_date: "2026-11-03"
paused_date: ""
completed_date: "2026-11-17"
pause_reason: ""
link: "https://github.com/Tupatuko2023/Python-R-Scripts/pull/225"
worktree_inventory: "unknown"
tasks:
  - "project-registry-rollout-001"
  - "project-registry-transfer-001"
  - "project-registry-cleanup-001"
  - "project-registry-general-adoption-001"
---

## Projektirekisterin käyttöönotto

## Lähdekuvaus

<!-- source-description:begin -->

Otetaan projektirekisteri käyttöön Python-R-Scriptsin päärepossa rajattuna koordinointityökaluna. Projektitiedosto on ylläpidettävä lähde, agentti päivittää tehtävään nimenomaisesti kuuluvaa tietuetta sallituilla kirjoituspoluilla ja generaattori muodostaa siitä CSV-näkymän.

Käyttöönotto lisää lyhyen AGENTS-ohjekytkennän, nykyistä skeemaa vastaavan tyhjän TEMPLATE-pohjan ja tämän yhden koordinointiprojektin pilotin. Pilotin pitää osoittaa pitkän kuvauksen säilyminen, nykytilan ja seuraavan askeleen löytyminen ilman chattia, hallittu tilapäivitys, deterministinen CSV ja --check sekä mallin ja alihakemistojen projektien jääminen keräilyn ulkopuolelle.

Tämä projekti ei muuta Fear-of-Fallingin tai Quantifyn tehtäväjonoja, hyväksyntöjä tai tutkimuksen tiloja. Toteutuksen valmistuminen, hyväksytty main-toimitus ja worktree-siivous ovat eri havaintoja. Likaiset päächeckoutit ja aiemmat worktreet säilytetään. Generaattorin avoimet jatkoehdotukset #12 ja #14–16 jäävät dokumentoiduiksi eikä niitä korjata tässä käyttöönotossa.
<!-- source-description:end -->

## Tehtäväviitteet

| repo                          | task                                  | path                                                   |
| ----------------------------- | ------------------------------------- | ------------------------------------------------------ |
| Tupatuko2023/Python-R-Scripts | project-registry-rollout-001          | tasks/04-done/project-registry-rollout-001.md          |
| Tupatuko2023/Python-R-Scripts | project-registry-transfer-001         | tasks/04-done/project-registry-transfer-001.md         |
| Tupatuko2023/Python-R-Scripts | project-registry-cleanup-001          | tasks/03-review/project-registry-cleanup-001.md        |
| Tupatuko2023/Python-R-Scripts | project-registry-general-adoption-001 | tasks/04-done/project-registry-general-adoption-001.md |

Polut ratkaistaan nimetyn repon juuresta. Lue kortti omasta polustaan; tämä
taulukko ei ylläpidä sen lifecycle-tilaa toisena totuutena. Erillinen
`project-registry-cleanup-001` on mukana vain viitteenä eikä sen sulkeminen
kuulu yleisen käyttöönoton tehtävään.

## Jatkamismuistio

Lue AGENTS.md ja tämän hakemiston README ennen rekisterityötä.
Käyttöönotto hyväksyttiin revision 5066579dfa2ef113e4b950b8280cff52e24d9fbf
perusteella ja toimitettiin [PR 219:ssä](https://github.com/Tupatuko2023/Python-R-Scripts/pull/219)
main-committiin f8a660634cafd4e2d0b30ee20516c0cd5c5ad2a1.
Omistajan pysyvä [hyväksyntä](https://github.com/Tupatuko2023/Python-R-Scripts/pull/219#issuecomment-6611936077)
on ajalta 2026-11-03T18:17:05Z. Käyttöönottotehtävän sulkeminen ja tämä
projektin toimitushavainto toimitetaan yhdessä; tehtäväviite on DONE-polkuun.

Uuden agentin seuraava toimi on paikallisen tehtäväjonon lukeminen, ei tämän
valmiin käyttöönottotehtävän avaaminen uudelleen. Generoi CSV nykyisellä
README-komennolla ja käytä Git-suojaa ennen vain tehtävään kuuluvan tietueen
päivitystä. Uuden projektin luonti vaatii sen kattavan tehtävävaltuutuksen.

Tämä käyttöönotto on valmis. Avoimet #12 ja #14–16 ovat READMEssä kuvattuja
erillisiä jatkoehdotuksia; niiden toteutusta ei aloitettu. Main-toimitus ei
merkitse worktree-poistoa. Owner valtuutti myöhemmin rajatun siivouksen. Toteutuneet poistot ja
säilytettyjen kohteiden syyt ovat alla erillään main-toimituksesta.

### Jatkopäätös 2026-11-17: yleinen käyttöönotto koko analyysirepossa

Owner ja orkestroija (`FCPO2`) avasivat tälle samalle `PRJ-REGISTRY-ROLLOUT`-tunnukselle
jatkovaiheen tehtävässä `project-registry-general-adoption-001`. Tavoitteena on
ottaa olemassa oleva projektirekisteri koko `Tupatuko2023/Python-R-Scripts`-repon
normaaliin käyttöön mukaan lukien aliprojektien (`Fear-of-Falling`,
`Quantify-FOF-Utilization-Costs`, `DEAC-Frailty-Index`,
`Electronic-Frailty-Index`) erikseen nimetyt monitehtäväiset projektit ilman
rinnakkaista tehtäväjonoa tai rekursiivista keräilyä.

Päätöksen mukaisesti yllä oleva pilottivaiheen lähdekuvauslohko ja sen SHA256
(`83d725739700bef4dbd47f3bb23777d389cdf7096148d40b0a57301b3af27dd1`) säilytetään
muuttumattomina ilman uudelleenmuotoilua, ja pilottivaiheen toimitus- (PR #219/#220)
sekä siivoushistoria (PR #221) pidetään osana tämän tietueen historiaa.
Yleinen käyttöönotto hyväksyttiin revision
`8bd959eae643e41c7d4aceb96076dd8eda1ac157` perusteella omistajan pysyvällä
[hyväksynnällä](https://github.com/Tupatuko2023/Python-R-Scripts/pull/225#issuecomment-6956840532)
(`2026-11-17T18:15:41Z`) ja toimitettiin
[PR 225:ssä](https://github.com/Tupatuko2023/Python-R-Scripts/pull/225)
`origin/main`-committiin `e603111a946b3b54cada7e87a7e1cc0b58feff9f`.
Tehtävän tekninen `04-done`-siirto ja tämän jatkovaiheen `closed` / `delivered`
-sulku toimitetaan yhdessä; erillinen
`tasks/03-review/project-registry-cleanup-001.md` säilyy omassa
`03-review`-tilassaan vain viitteenä.

## Worktree-havainnot

| label                       | state    | evidence                                                                                                                                                                             |
| --------------------------- | -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| registry-rollout            | removed  | tmp/project-registry-rollout-001 poistettu 2026-11-03; PR #219/#220, kokonainen squash-puu sama, DONE mainissa; vain uudelleen muodostettava CSV.                                    |
| registry-local-adaptation   | removed  | tmp/project-registry-local-adaptation-001 poistettu; d9004251 on PR #216:n commit-listassa; työpuu puhdas, vain pycache.                                                             |
| registry-source-duplicate   | removed  | Tupatuko2023/FOF-Dissertation-Project; tasks/04-done/TASK-PROJECT-REGISTRY-DUPLICATE-KEYS-001.md; worktree duplicate-keys poistettu, HEAD mainin esi-isä ja sama DONE-blobi.         |
| registry-source-safe-export | removed  | Tupatuko2023/FOF-Dissertation-Project; tasks/04-done/TASK-PROJECT-REGISTRY-SAFE-EXPORT-001.md; worktree safe-export poistettu, HEAD mainin esi-isä ja sama DONE-blobi.               |
| registry-source-alias       | removed  | Tupatuko2023/FOF-Dissertation-Project; tasks/04-done/TASK-PROJECT-REGISTRY-DIRECTORY-ALIAS-001.md; worktree directory-alias poistettu, HEAD mainin esi-isä ja sama DONE-blobi.       |
| registry-source-validation  | removed  | Tupatuko2023/FOF-Dissertation-Project; tasks/04-done/TASK-PROJECT-REGISTRY-VALIDATION-001.md; worktree validation poistettu, PR #349/#350/#351:n puut täsmäävät squash-toimituksiin. |
| registry-baseline           | retained | tmp/project-registry-baseline-001 säilytetty: 21 ignored-tiedostoa, myös Quantifyn paikalliset tulokset/manifesti; säilytystarvetta ei oleteta ratkaistuksi.                         |
| registry-transfer           | retained | tmp/project-registry-transfer-001 säilytetty: paikallisia CI-raportteja, Markdown-riippuvuuksia sekä Quantifyn tuloksia/manifesti; myös tämän kirjauksen toimitusworktree.           |
| registry-general-adoption   | removed  | tmp/project-registry-general-adoption-001 poistettu 2026-11-19 ilman forcea (worktree-cleanup-001); PR #225/#226 (b0499e2de4) sama squash-puu mainissa, vain regeneroitava CSV.      |

Inventaario kattaa aiemman siirto-/käyttöönottohankkeen tunnistetut kahdeksan
worktreetä molemmissa repoissa (2026-11-03) sekä jatkovaiheen nyt poistetun
worktreen `registry-general-adoption` (2026-11-19). Koska koko monorepossa on
edelleen säilytettyjä työpuita ja siivoustehtävän oma väliaikainen työpuu oli
aktiivinen kirjaushetkellä, `worktree_inventory` pidetään arvossa `unknown`.
CSV:n `Worktree-siivous` on `retained`, koska kaksi tämän projektin aiempaa
worktreetä (`registry-baseline`, `registry-transfer`) säilytetään edelleen.
Erillinen FOF-repon SKR1-maintenance-002-worktree on eri keskeneräinen tehtävä,
eikä sitä lasketa tähän inventaarioon tai muuteta.

### Paikalliset haarat ja säilytyssyyt

Poistettu normaalilla git branch -d -komennolla kahdeksan toimitettua haaraa:

- Tupatuko2023/FOF-Dissertation-Project: chore/project-registry-duplicate-keys-001,
  fix/project-registry-validation-001,
  chore/project-registry-validation-closeout-001,
  chore/project-registry-validation-done-001.
- Tupatuko2023/Python-R-Scripts: chore/project-registry-rollout-001,
  chore/project-registry-rollout-closeout-001,
  chore/project-registry-transfer-001,
  chore/project-registry-transfer-closeout-001.

Säilytetään ilman worktreetä kolme vanhaa paikallista haaraa:

- Tupatuko2023/FOF-Dissertation-Project: chore/project-registry-safe-export-001 ja
  fix/project-registry-directory-alias-001: tavallinen branch -d kieltäytyi,
  koska upstream-tehtävähaara ei sisällä paikallista merge-HEADia, vaikka
  canonical main sisältää sen. Upstreamia ei vaihdeta poistamisen kiertämiseksi.
- Python-R-Scripts prepare/project-registry-local-adaptation-001: commitit
  ovat toimitetun PR #216:n historiassa, mutta branch -d ei hyväksy squash-
  historiaa mainiin eikä haaralla ole upstreamia. Ei force-poistoa.

Nykyinen chore/project-registry-cleanup-001-haara on siivouskirjauksen
säilyvä toimitushaara. Etähaaroja ei poistettu tai muutettu siivouksen vuoksi.
Kirjaustehtävä ja sen tarkempi näyttö löytyvät repoidentiteetillä
Tupatuko2023/Python-R-Scripts, polusta tasks/03-review/project-registry-cleanup-001.md.
Jatkovaiheen työpuu `tmp/project-registry-general-adoption-001` sekä paikalliset
haarat `docs/project-registry-general-adoption-001` (`8bd959ea`, PR #225) ja
`chore/project-registry-general-adoption-closeout-001` (`627a2470`, PR #226)
poistettiin 2026-11-19 Ownerin valtuuttamassa siivoustehtävässä
`worktree-cleanup-001` tavallisilla `git worktree remove`- ja `git branch -d`
-komennoilla `origin/main`-toimitusvarmennuksen jälkeen; etähaarat säilytettiin.

### Siivousnäytön raja

Kohteet olivat tehtävä-/toimitusnäytön mukaan vain tämän hankkeen valmiita
worktreitä. Puhtaus ja havaitut kohdepolkuihin viittaavat prosessit tarkistettiin
ennen poistoja. Kirjoittajia poissulkevaa lukkoa ei kuitenkaan käytetty; tämä
havaintoperusteinen tarkistus ei todista atomista yksinomaista käyttöä koko
poistovälin ajan. Aikavälin ulkopuolista tai prosessilistassa näkymätöntä
kirjoittajaa ei voida tällä näytöllä sulkea pois. Tietojen häviämistä ei havaittu,
mutta tämä ei ole yleinen kilpailutilanteettoman siivouksen takuu.
Jo toteutuneita poistoja ei väitetä jälkikäteen lukituiksi. Uusia poistoja ei
tehdä tämän kirjauksen katselmointihuomion ratkaisemiseksi. PR:n katselmoinnissa
arvioidaan tämä historiallinen näyttöraja ennen siivouskirjauksen toimitusta.
