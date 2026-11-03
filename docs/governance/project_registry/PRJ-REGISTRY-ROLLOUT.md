---
id: "PRJ-REGISTRY-ROLLOUT"
title: "Projektirekisterin käyttöönotto päärepossa"
short_name: "Rekisterin käyttöönotto"
repo: "Tupatuko2023/Python-R-Scripts"
repo_ref: "origin/main"
state: "active"
delivery: "not_delivered"
goal: "Agentti löytää, päivittää ja jatkaa päärepon koordinointiprojektia rekisteritiedoston ja tehtäväviitteiden avulla."
done_criterion: "AGENTS-kytkentä, pohja ja yhden projektin pilotti on validoitu, ihmisen hyväksymä ja varmennettu mainista; worktree-siivous raportoidaan erikseen."
latest_status: "Ohjekytkentä, täyttöpohja ja pilottitietue toteutettu paikallisesti; käytännön validointi on seuraava työvaihe."
next_step: "Suorita tasks/02-in-progress/project-registry-rollout-001.md:n pilottitarkistukset ja palauta sama tehtävä review-tilaan."
source_description_sha256: "83d725739700bef4dbd47f3bb23777d389cdf7096148d40b0a57301b3af27dd1"
source_captured_at: "2026-11-03"
observed_at: "2026-11-03"
observed_commit: "d0ad7a0afc11a2f9e2c40af71e1b058fc8245889"
observed_worktree_label: "registry-rollout"
blocker: "Main-toimitus odottaa tämän uuden käyttöönottorevision ihmiskatselmointia ja erillistä toimitusvaltuutusta."
orchestrator: ""
agent: "Codex"
agent_tool: "Codex"
environment: "Windows PowerShell; GitHub Ubuntu CI"
started_date: "2026-11-03"
paused_date: ""
completed_date: ""
pause_reason: ""
link: ""
worktree_inventory: "complete"
tasks:
  - "project-registry-rollout-001"
  - "project-registry-transfer-001"
---

# Projektirekisterin käyttöönotto

## Lähdekuvaus

<!-- source-description:begin -->

Otetaan projektirekisteri käyttöön Python-R-Scriptsin päärepossa rajattuna koordinointityökaluna. Projektitiedosto on ylläpidettävä lähde, agentti päivittää tehtävään nimenomaisesti kuuluvaa tietuetta sallituilla kirjoituspoluilla ja generaattori muodostaa siitä CSV-näkymän.

Käyttöönotto lisää lyhyen AGENTS-ohjekytkennän, nykyistä skeemaa vastaavan tyhjän TEMPLATE-pohjan ja tämän yhden koordinointiprojektin pilotin. Pilotin pitää osoittaa pitkän kuvauksen säilyminen, nykytilan ja seuraavan askeleen löytyminen ilman chattia, hallittu tilapäivitys, deterministinen CSV ja --check sekä mallin ja alihakemistojen projektien jääminen keräilyn ulkopuolelle.

Tämä projekti ei muuta Fear-of-Fallingin tai Quantifyn tehtäväjonoja, hyväksyntöjä tai tutkimuksen tiloja. Toteutuksen valmistuminen, hyväksytty main-toimitus ja worktree-siivous ovat eri havaintoja. Likaiset päächeckoutit ja aiemmat worktreet säilytetään. Generaattorin avoimet jatkoehdotukset #12 ja #14–16 jäävät dokumentoiduiksi eikä niitä korjata tässä käyttöönotossa.
<!-- source-description:end -->

## Tehtäväviitteet

| repo                          | task                          | path                                                 |
| ----------------------------- | ----------------------------- | ---------------------------------------------------- |
| Tupatuko2023/Python-R-Scripts | project-registry-rollout-001  | tasks/02-in-progress/project-registry-rollout-001.md |
| Tupatuko2023/Python-R-Scripts | project-registry-transfer-001 | tasks/04-done/project-registry-transfer-001.md       |

Polut ratkaistaan nimetyn repon juuresta. Lue kortti omasta polustaan; tämä
taulukko ei ylläpidä sen lifecycle-tilaa toisena totuutena.

## Jatkamismuistio

Lue ensin yllä olevan käyttöönottotehtävän kortti ja tämän hakemiston README.
Siirtopaketti on jo mainissa commitissa f3da52a4d86de7aa3a2aa7ff951405568000f8a2
(PR #216 ja sulkeminen #218); tämän uuden pilotin toimitus on vielä erillinen asia.
Seuraava toimija on tehtävää jatkava agentti: suorita kortin pilottivalidoinnit.
Omistaja arvioi uuden revision ennen toimitusta. Pelkkä CSV tai valmis toteutus
ei osoita main-toimitusta eikä taskin DONE worktreen poistamista.

## Worktree-havainnot

| label            | state  | evidence                                                                            |
| ---------------- | ------ | ----------------------------------------------------------------------------------- |
| registry-rollout | active | Käyttöönottotehtävän worktree tmp/project-registry-rollout-001; ei poistovaltuutta. |

Inventaario on complete vain tämän projektin yhdelle uudelle käyttöönottotyöpuulle.
Vanhojen siirtotehtävien worktreeitä ei lasketa tämän projektin siivotuiksi työpuiksi.
