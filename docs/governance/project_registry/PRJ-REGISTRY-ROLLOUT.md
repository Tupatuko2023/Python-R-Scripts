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
latest_status: "Omistajan hyväksymä AGENTS-kytkentä, pohja ja validoitu pilotti toimitettu PR 219:ssä mainiin f8a660634cafd4e2d0b30ee20516c0cd5c5ad2a1; käyttöönotto valmis, worktree säilytetään."
next_step: "Uusi agentti: lue AGENTS.md ja rekisterin README; valitse tehtävä paikallisen jonon mukaan ja päivitä vain siihen nimenomaisesti kuuluvaa projektitietuetta."
source_description_sha256: "83d725739700bef4dbd47f3bb23777d389cdf7096148d40b0a57301b3af27dd1"
source_captured_at: "2026-11-03"
observed_at: "2026-11-03"
observed_commit: "f8a660634cafd4e2d0b30ee20516c0cd5c5ad2a1"
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
merkitse worktree-poistoa. Omistaja kielsi poistot, ja työpuu säilytetään.

## Worktree-havainnot

| label            | state    | evidence                                                                                        |
| ---------------- | -------- | ----------------------------------------------------------------------------------------------- |
| registry-rollout | retained | Owner kielsi poistot toimitusohjeessa 2026-11-03; tmp/project-registry-rollout-001 säilytetään. |

Inventaario on complete vain tämän projektin yhdelle uudelle käyttöönottotyöpuulle.
Vanhojen siirtotehtävien worktreeitä ei lasketa tämän projektin siivotuiksi työpuiksi.
