# AIM1 WP1: toimitettujen PRS-työpuiden siivous

## Valtuutus ja rajaus

Käyttäjä valtuutti 20.11.2026 erikseen työpuiden `aim1-wp1-20261119` ja
`aim1-wp1-lifecycle-20261119` sekä niiden paikallisten ja origin-haarojen
`docs/aim1-wp1-review` ja `docs/aim1-wp1-closure-20261119` siivouksen.
Valmistunutta WP1-korttia ei avata uudelleen. AIM1-kohderepo, jaettu PRS-checkout,
muut työpuut ja yksityiset säilytysaineistot säilytetään.

## Sallitut kirjoituspolut

- Tämän kortin polut `tasks/01-ready/`, `tasks/02-in-progress/` ja
  `tasks/03-review/`-jonoissa. Myöhempi
  `tasks/04-done/AIM1_WP1_CLEANUP_20261120.md` sallitaan vain tämän tehtävän
  pysyvän ihmisomistajahyväksynnän jälkeen repon elinkaariohjeen mukaisesti.
- `docs/governance/project_registry/PRJ-AIM1-REPO.md`.
- Ignoroitu `tools/project_registry/outputs/projects.csv`.
- Yksityinen uusi PRS-bundle ja sen palautustarkistus erillisissä,
  käyttäjän valtuuttamissa paikallisissa säilytys- ja tarkistushakemistoissa.
- Vain nimetyt kaksi työpuuta, niiden uudelleen muodostettavat CSV:t ja
  nimetyt paikalliset sekä origin-haarat.

## Valmistumiskriteerit

- PR #233 ja #234 sekä kummankin haaran lopullinen kärki on varmennettu
  `origin/main`-tilaa vasten; uutta työtä ei ole.
- Molemmat kärjet kattava yksityinen bundle on palautettu erilliseen
  tarkistushakemistoon; SHA-256 kirjattu.
- Nimettyjen työpuiden tracked-, staged-, untracked- ja ignored-sisältö sekä
  aktiivinen käyttö on tarkistettu. Vain sallitut kohteet poistetaan normaalilla
  Git-menettelyllä ilman pakotusta.
- Toteutunut tila kirjataan projektirekisteriin, CSV generoidaan ja
  rekisteritarkistukset ajetaan. Siivouskirjauksen PR valmistellaan katselmuun;
  sitä ei yhdistetä ilman tämän revision ihmisomistajahyväksyntää.
- AIM1-projekti jää aktiiviseksi; julkaisuoikeus ja omistava §3.1 pysyvät avoimina.

## Loki

- 2026-11-20: Kortti luotu käyttäjän nimetyn siivousvaltuutuksen perusteella.
  `origin/main` noudettu ja PR #233 sekä #234 vahvistettu yhdistetyiksi.
- 2026-11-20: PR #233:n hyväksytty HEAD oli
  `f16380a66b511bf83116a9817abda4d46e08a65a` ja mainin squash-commit
  `1c90b7ed8ab1cc4a977acee2ebcf9e1ec83b615c`. PR #234:n HEAD oli
  `fc106d4eab10c2d9c50caafed3745a2699941b98` ja mainin squash-commit
  `02fbcd96303d2c9e9b4e5441176af00d20e5a5f9`. Molemmat PR:t olivat
  `MERGED`, kohde `main`, ja main-commitit löytyivät `origin/main`-historiasta.
- 2026-11-20: Lähdecheckout oli matala, minkä vuoksi kaksi alustavaa bundlea
  eivät palautuneet tyhjään tarkistusrepoon. Git-historia täydennettiin
  `git fetch --unshallow origin` -komennolla. Uusi yksityinen
  `prs-wp1-both-heads-20261120-restorable.bundle` palautui erilliseen
  tarkistusrepoon: molemmat haarakärjet täsmäsivät, `git fsck
--no-reflogs --connectivity-only` läpäisi ja bundlen SHA-256 oli
  `f1061ec84e476557f0ca46c5250ff32abac552cc4327c256fbeb93980fdb0004`.
  Alustavat bundlet ja aiemmat säilytystiedostot säilytettiin.
- 2026-11-20: Kummassakaan nimetyssä työpuussa ei ollut seurattuja, staged-
  eikä seuraamattomia muutoksia. Ainoa ignoroitu tiedosto oli generoitu
  `tools/project_registry/outputs/projects.csv`. Prosessien näkyvissä
  työskentelyhakemistoissa ei ollut kumpaakaan kohdepolkua. Tarkistettu CSV
  poistettiin kummastakin; työpuut poistettiin `git worktree remove` -komennolla,
  paikalliset haarat `git branch -d` -komennolla ja etähaarat
  `git push origin --delete` -komennolla. Etähaarojen kärjet tarkistettiin
  uudelleen juuri ennen poistoa. Muita työpuita tai haaroja ei poistettu.
- 2026-11-20: Projektirekisteri päivitettiin toteutuneen siivouksen mukaiseksi.
  Kortti siirretään `03-review`-jonoon ja siivouskirjauksen PR avataan erikseen;
  tämän uuden revision ihmisomistajahyväksyntää ei ole vielä annettu.
- 2026-11-20: Projektirekisterin lähdekuvauksen SHA-256 säilyi ennallaan.
  CSV:n muodostus kahdesti antoi saman tiivisteen, `--check` ja Git-ignore-
  tarkistus läpäisivät. Rekisterin 62 yksikkötestiä läpäisivät Debian-Pythonilla.
  Termux-Pythonilla neljä testiä ei voinut käyttää puuttuvaa `os.link`-funktiota;
  kyse on ympäristön rajoituksesta, ei muuttuneesta rekisterikoodista.
- 2026-11-20: Projektirekisterin `--verify-guard` läpäisi ennen ensimmäistä
  muutosta `origin/main`-revisiolla `02fbcd96303d2c9e9b4e5441176af00d20e5a5f9`
  ja uudelleen ennen katselmointikorjausta tämän haaran revisiolla
  `54d06e9f48a893e9d96b9fae2aeea9991650e6b4`. Repojuuren
  `tools/run-gates.sh --mode pre-push --smoke` läpäisi. Analyysi- ja QC-ajot:
  `NOT APPLICABLE`, koska muutos koskee vain siivouksen hallinnollista kirjausta
  eikä analyysikoodia, aineistoa tai tutkimusajoa.
- 2026-11-20: Etähaarojen kärjet tarkistettiin juuri ennen normaaleja
  `git push origin --delete` -poistoja. Poistokomento ei kuitenkaan ollut
  kärjen OID:hen sidottu, joten tarkistuksen ja poiston välistä mahdollista
  rinnakkaista päivitystä ei voi sulkea pois jälkikäteen. Palautuskelpoinen
  yksityinen bundle kattaa tarkistetut kaksi kärki-HEADia. Yksityinen
  säilytysmanifesti nimeää tämän palautuskopioksi ja kaksi alustavaa bundlea
  palautukseen kelpaamattomiksi; kaikkien kolmen hashit tarkistettiin.
- 2026-11-20T03:27:38Z: Ihmisomistaja `Tupatuko2023` hyväksyi tämän
  siivoustehtävän teknisen valmistumisen ja [PR #235:n täsmärevision
  `82fd14e69ea6ca0e2755bbf14ee5b2ebecbf3333`](https://github.com/Tupatuko2023/Python-R-Scripts/pull/235#issuecomment-7029426709).
  Kommentti valtuutti PR:n main-yhdistämisen ja sulkukirjauksen valmistelun.
  Tämä pysyvä kommentti on tehtävälokista riippumaton hyväksyntänäyttö.
- 2026-11-20: PR #235 yhdistettiin hyväksytystä HEADista mainiin squash-
  commitilla `7c87864a0aacb65b6ba976295d604b5aa42035ed`; `MERGED`-tila,
  kohde `main` ja commitin esiintyminen noudetussa `origin/main`-haarassa
  varmennettiin. Kortti siirrettiin teknisesti `04-done`-jonoon erillisessä
  elinkaarityöpuussa. Tämän sulkukirjauksen oma PR ja sen ihmishyväksyntä
  ovat vielä avoimia. Siivouskirjauksen työpuu ja haara säilyvät, kunnes
  niiden erikseen valtuutetun loppusiivouksen ehdot täyttyvät.
