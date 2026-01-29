# Human Steering & Focus

Tämä tiedosto ohjaa agentin yleistä toimintaa ja fokusta. Ihmistutkija päivittää tätä ohjatakseen agentteja kohti ajankohtaisia tavoitteita.

## Current Focus (Nykyinen Fokus)

**Status:** `active`
**Mode:** `literature_review` <!-- vaihtoehdot: writing, experiment, literature_review, maintenance -->

**Viikon tavoitteet:**

- [ ] Määrittele hakustrategia (TASK-101)
- [ ] Tuo alustavat viitteet (TASK-102)

## Global Constraints (Globaalit Rajoitteet)

- **Max changes per run:** 5 files
- **Safe mode:** `true` (Vaatii hyväksynnän tiedostojen poistolle)
- **Language:** Finnish (dokumentaatio), English (koodi/muuttujat)

## Approvals Required

Seuraavat toimenpiteet vaativat aina ihmisen hyväksynnän:

- Tiedostojen poistaminen `docs/` tai `src/` kansioista.
- Uusien Python-pakettien lisääminen riippuvuuksiin.
- `data/` kansion rakenteen muuttaminen.
