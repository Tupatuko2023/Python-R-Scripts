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
- **Poikkeus:** `DEAC-Frailty-Index/docs/DEAC_HANDOVER.md` saa säilyä
  englanniksi vain Ownerin hyväksymän tieteellisen lähdehandoverin
  muuttumattomana tavukopiona (SHA-256
  `7E83E4FE34BEF5A4ADC548F6E67663EA343C94E68844739C37E046A4226A2539`).
  Poikkeus ei koske muuta dokumentaatiota; sisältömuutos edellyttää
  tieteellistä hyväksyntää ja uutta hashia.

## Approvals Required

Seuraavat toimenpiteet vaativat aina ihmisen hyväksynnän:

- Tiedostojen poistaminen `docs/` tai `src/` kansioista.
- Uusien Python-pakettien lisääminen riippuvuuksiin.
- `data/` kansion rakenteen muuttaminen.
