# FCOT2 fixed Termux host precision patch

## Tavoite

Toteuta `prompts/6_FCOT2.txt`-paketin minimaalinen precision patch kiinteälle Termux
hostille, delegoiduille suoritusympäristöille ja section-level retrievalille.

## Rajaus

- Sallitut KB-muutokset: `KB_INDEX.md`, `FCOT2_ORCHESTRATION_REFERENCE.md` ja
  `FCOT2_AUDIT_AND_REGRESSION.md`.
- Säilytä vendor-verifiointi, frozen baseline ja neljän aktiivisen tiedoston rakenne.
- Älä muuta FOF-projektitietoja, commitoi tai pushaa.

## Definition of Done

- V01–V19 läpäisevät.
- T01–T15-vaatimukset on katettu ilman päällekkäistä testisarjaa.
- Task-scoped diff on minimaalinen ja tarkastettu.

## Loki

- 2026-08-24T20:00:00+03:00 — Tehtävä luotu käyttäjän eksplisiittisellä valtuutuksella.
- 2026-08-24T20:03:00+03:00 — Preflight valmis; fixed-host, delegated-context ja section-level retrieval -gapit vahvistettu kolmessa sallitussa KB-tiedostossa.
- 2026-08-24T20:07:42+03:00 — Precision patch toteutettu; V01–V19 ja T01–T15 PASS, Markdown-lint 0 havaintoa. Vendor-KB ja frozen baseline hash-varmennettu muuttumattomiksi. Tehtävä valmis katselmointiin.
- 2026-08-24T20:12:59+03:00 — FIX_REQUIRED-kierros: kanoninen XML korjattu esittämään `TERMUX` hostina ja `LOCAL_SHELL` delegoituna kontekstina. Standardiparseri, V01–V19, T01–T15, diff check ja Markdown-lint PASS; re-review-status `PASS / READY_FOR_HUMAN_COMMIT_APPROVAL`.
