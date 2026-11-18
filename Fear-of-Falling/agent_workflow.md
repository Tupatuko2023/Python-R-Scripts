# Agent Execution Protocol

Tämä protokolla määrittelee `Fear-of-Falling`-aliprojektin tehtäväsuorituksen
yhdessä repojuuren [../SKILLS.md](../SKILLS.md)- ja [WORKFLOW.md](WORKFLOW.md)-ohjeiden
kanssa. Repojuuren `../SKILLS.md` ohjaa tehtäväkohtaista kirjoitus- ja
toimitusrajausta, PR-menettelyä, `main`-toimitusta, teknistä sulkua ja siivousta;
tämän aliprojektin oma tehtäväjono (`Fear-of-Falling/tasks/`) sekä alla oleva
`K18/QC`-portti ja muut tutkimus-/tietosuojarajat säilyvät tiukasti voimassa
(ratkaisematon ristiriita pysäyttää riippuvan toimenpiteen eikä anna lupaa valita
heikompaa sääntöä):

1. **Lähtötila, työpuu ja valtuutus:** Perusta tehtävälle eristetty worktree
   `git fetch origin main` -haun jälkeen varmennetusta täydestä commit-SHA:sta
   koskematta päächeckoutin haaraan tai paikallisiin muutoksiin, ja tarkista
   hyväksytyt kirjoituspolut sekä toimitusraja ([../SKILLS.md](../SKILLS.md)).
2. **QC-soveltuvuus (`K18/QC`):** Päätä alla olevan päätösportin mukaan ennen
   komentojen valintaa tai toteutusta, onko `K18/QC` `REQUIRED` vai
   `NOT APPLICABLE`. Puhdas hallinto- tai dokumentaatiomuutos ei käynnistä
   tutkimusajoa tai suojatun aineiston lukua.
3. **Toteutus (`01-ready -> 02-in-progress`):** Siirrä tehtäväkortti tämän
   aliprojektin omassa jonossa (`Fear-of-Falling/tasks/01-ready/` ->
   `Fear-of-Falling/tasks/02-in-progress/`), päivitä mahdollisen linkitetyn
   `PRJ-*.md`-rekisteritietueen tehtäväpolku samassa muutoksessa ja toteuta vain
   hyväksytty kirjoitusrajaus.
4. **Validointi ja suoritushakemisto:** Aja FOF-analyysit ja tutkimus-QC aina
   `Fear-of-Falling/`-työjuuresta; valtuutetut repojuuren hallintaportit ja
   rekisterikomennot suoritetaan saman eristetyn worktreen repojuuressa rajatussa
   suorituskontekstissa.
5. **Katselmointiin luovutus (`03-review`):** Siirrä kortti samassa jonossa
   polkuun `Fear-of-Falling/tasks/03-review/` (päivittäen mahdollisen linkitetyn
   `PRJ-*.md`-tietueen tehtäväpolun samassa muutoksessa) ja toimita PR
   katselmointiin valtuutetun toimitusrajan puitteissa.
6. **Hyväksyntä, `main`-toimitus ja tekninen sulku (`04-done`):** Agentti ei saa
   hyväksyä omaa työtään eikä puskea suoraan `main`-haaraan. Vasta täsmärevisioon
   kohdistuvan pysyvän riippumattoman ihmishyväksyntänäytön, valtuutetun
   PR-mergen ja `origin/main`-toimitusvarmennuksen jälkeen agentti saa erillisen
   sulkuvaltuutuksen nojalla siirtää kortin teknisesti
   `Fear-of-Falling/tasks/03-review/` -> `Fear-of-Falling/tasks/04-done/`,
   päivittää mahdollisen linkitetyn `PRJ-*.md`-tietueen tehtäväpolun (erottaen
   `TASK`-sulun projektin omista valmistumiskriteereistä) ja avata sulku-PR:n
   ([../SKILLS.md](../SKILLS.md)). Työpuun ja haarojen siivous pidetään tästä
   erillisenä.

## K18/QC Applicability Decision Gate

Before execution, list the changed file classes and inspect task-specific
acceptance criteria.

```text
Does the task modify data, variable coding, ID/time structure, FOF derivation,
baseline/follow-up/delta definitions, missingness rules, inclusion/exclusion
logic, model frames, K18/QC code, QC artifacts, or explicitly require K18/QC?
  yes -> REQUIRED
  no  -> NOT APPLICABLE with documented reason
```

K18/QC REQUIRED triggers include participant-level or observation-level data,
imported or processed data structure, variable names/types/labels/factor levels,
ID uniqueness or ID-time structure, baseline or follow-up outcome definitions,
delta derivation, FOF status derivation or coding, missingness rules or outputs,
inclusion/exclusion logic, model-frame construction, K18 scripts, QC checks,
thresholds, summarizers, runners, QC artifacts, analysis outputs whose
acceptance depends on K18 evidence, and any task acceptance criterion that
explicitly requires K18/QC.

K18/QC is normally NOT APPLICABLE for prose documentation, README restructuring,
task-card documentation, diagram file organization, `git mv` operations with
unchanged scientific content, path-reference maintenance, legacy archiving,
non-scientific manifest path correction, formatting or spelling, repository
metadata that does not change analysis execution, and manuscript handoff
documentation.

Completed task validation must record exactly one of:

```text
K18/QC: PASS
K18/QC: NOT APPLICABLE — <specific reason>
```

`NOT APPLICABLE` is invalid when data, variable coding, inclusion logic, model
frames, K18 code, QC code, or QC artifacts changed. If K18/QC is REQUIRED and
cannot run, the task remains blocked. Task-specific acceptance criteria override
the default classification.
