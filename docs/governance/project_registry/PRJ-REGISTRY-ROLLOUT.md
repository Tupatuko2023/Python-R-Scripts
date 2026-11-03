---
id: "PRJ-REGISTRY-ROLLOUT"
title: "Projektirekisterin käyttöönotto päärepossa"
short_name: "Rekisterin käyttöönotto"
repo: "Tupatuko2023/Python-R-Scripts"
repo_ref: "origin/main"
state: "closed"
delivery: "delivered"
goal: "Agentti löytää, päivittää ja jatkaa päärepon koordinointiprojektia rekisteritiedoston ja tehtäväviitteiden avulla."
done_criterion: "AGENTS-kytkentä, pohja ja yhden projektin pilotti on validoitu, ihmisen hyväksymä ja varmennettu mainista; worktree-siivous raportoidaan erikseen."
latest_status: "Käyttöönotto toimitettu ja suljettu. Hankkeen 6 varmennettua worktreetä ja 8 paikallista tehtävähaaraa poistettu; 2 worktreetä ja 3 vanhaa haaraa säilytetään dokumentoiduista syistä."
next_step: "Säilytä baseline- ja transfer-worktreeiden paikalliset artefaktit. Lue siivouskortti ennen mahdollista jatkosiivousta; poistoja ei pakoteta eikä etähaaroja muuteta."
source_description_sha256: "83d725739700bef4dbd47f3bb23777d389cdf7096148d40b0a57301b3af27dd1"
source_captured_at: "2026-11-03"
observed_at: "2026-11-03"
observed_commit: "dc655d39ba9e1662aaa4d09b5e6e3e5a683f2526"
observed_worktree_label: "registry-rollout"
blocker: ""
orchestrator: ""
agent: "Codex"
agent_tool: "Codex"
environment: "Windows PowerShell; GitHub Ubuntu CI"
started_date: "2026-11-03"
paused_date: ""
completed_date: "2026-11-03"
pause_reason: ""
link: "https://github.com/Tupatuko2023/Python-R-Scripts/pull/219"
worktree_inventory: "complete"
tasks:
  - "project-registry-rollout-001"
  - "project-registry-transfer-001"
  - "project-registry-cleanup-001"
---

## Projektirekisterin käyttöönotto

## Lähdekuvaus

<!-- source-description:begin -->

Otetaan projektirekisteri käyttöön Python-R-Scriptsin päärepossa rajattuna koordinointityökaluna. Projektitiedosto on ylläpidettävä lähde, agentti päivittää tehtävään nimenomaisesti kuuluvaa tietuetta sallituilla kirjoituspoluilla ja generaattori muodostaa siitä CSV-näkymän.

Käyttöönotto lisää lyhyen AGENTS-ohjekytkennän, nykyistä skeemaa vastaavan tyhjän TEMPLATE-pohjan ja tämän yhden koordinointiprojektin pilotin. Pilotin pitää osoittaa pitkän kuvauksen säilyminen, nykytilan ja seuraavan askeleen löytyminen ilman chattia, hallittu tilapäivitys, deterministinen CSV ja --check sekä mallin ja alihakemistojen projektien jääminen keräilyn ulkopuolelle.

Tämä projekti ei muuta Fear-of-Fallingin tai Quantifyn tehtäväjonoja, hyväksyntöjä tai tutkimuksen tiloja. Toteutuksen valmistuminen, hyväksytty main-toimitus ja worktree-siivous ovat eri havaintoja. Likaiset päächeckoutit ja aiemmat worktreet säilytetään. Generaattorin avoimet jatkoehdotukset #12 ja #14–16 jäävät dokumentoiduiksi eikä niitä korjata tässä käyttöönotossa.
<!-- source-description:end -->

## Tehtäväviitteet

| repo                          | task                          | path                                           |
| ----------------------------- | ----------------------------- | ---------------------------------------------- |
| Tupatuko2023/Python-R-Scripts | project-registry-rollout-001  | tasks/04-done/project-registry-rollout-001.md  |
| Tupatuko2023/Python-R-Scripts | project-registry-transfer-001 | tasks/04-done/project-registry-transfer-001.md |

Polut ratkaistaan nimetyn repon juuresta. Lue kortti omasta polustaan; tämä
taulukko ei ylläpidä sen lifecycle-tilaa toisena totuutena.

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

## Worktree-havainnot

| label                       | state    | evidence                                                                                                                                                                   |
| --------------------------- | -------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| registry-rollout            | removed  | tmp/project-registry-rollout-001 poistettu 2026-11-03; PR #219/#220, kokonainen squash-puu sama, DONE mainissa; vain uudelleen muodostettava CSV.                          |
| registry-local-adaptation   | removed  | tmp/project-registry-local-adaptation-001 poistettu; d9004251 on PR #216:n commit-listassa; työpuu puhdas, vain pycache.                                                   |
| registry-source-duplicate   | removed  | FOF-Dissertation-Project: fof-project-registry-duplicate-keys-001 poistettu; HEAD mainin esi-isä, sama DONE-kortti.                                                        |
| registry-source-safe-export | removed  | FOF-Dissertation-Project: fof-project-registry-safe-export-001 poistettu; HEAD mainin esi-isä, sama DONE-kortti.                                                           |
| registry-source-alias       | removed  | FOF-Dissertation-Project: fof-project-registry-directory-alias-001 poistettu; HEAD mainin esi-isä, sama DONE-kortti.                                                       |
| registry-source-validation  | removed  | FOF-Dissertation-Project: fof-project-registry-validation-001 poistettu; PR #349/#350/#351:n puut täsmäävät squash-toimituksiin, DONE mainissa.                            |
| registry-baseline           | retained | tmp/project-registry-baseline-001 säilytetty: 21 ignored-tiedostoa, myös Quantifyn paikalliset tulokset/manifesti; säilytystarvetta ei oleteta ratkaistuksi.               |
| registry-transfer           | retained | tmp/project-registry-transfer-001 säilytetty: paikallisia CI-raportteja, Markdown-riippuvuuksia sekä Quantifyn tuloksia/manifesti; myös tämän kirjauksen toimitusworktree. |

Inventaario kattaa tämän siirtäminen/käyttöönottohankkeen tunnistetut kahdeksan
worktreetä molemmissa repoissa. Kokonaissiivous on retained, koska kaksi
worktreetä säilytetään; kuusi onnistunutta poistoa ei tarkoita kaiken poistamista.
Erillinen FOF-repon SKR1-maintenance-002-worktree on eri keskeneräinen tehtävä,
eikä sitä lasketa tähän inventaarioon tai muuteta.

### Paikalliset haarat ja säilytyssyyt

Poistettu normaalilla git branch -d -komennolla kahdeksan toimitettua haaraa:

- FOF: chore/project-registry-duplicate-keys-001,
  fix/project-registry-validation-001,
  chore/project-registry-validation-closeout-001,
  chore/project-registry-validation-done-001.
- Python-R-Scripts: chore/project-registry-rollout-001,
  chore/project-registry-rollout-closeout-001,
  chore/project-registry-transfer-001,
  chore/project-registry-transfer-closeout-001.

Säilytetään ilman worktreetä kolme vanhaa paikallista haaraa:

- FOF chore/project-registry-safe-export-001 ja
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
