# FIRA1 Termux–Windows-päivitys

Status: REVIEW / REPOSITORY_SCOPE_EXTENSION
Owner: repositoryn omistaja
Rajaus: FIRA1-kansion lähdekartoitus, Windowsin nykykansion paikalliset tiedostot ja arkistokopioiden ratkaisu samassa tehtävässä. Ei erillistä local-merge-tehtävää.

## Valtuutus ja rajat

Käyttäjän 2026-10-11 toimeksianto sallii read-only-kartoituksen, tehtäväkortin ja tuetun previewn valmistelun. Ei digest-hyväksyntää, payload-siirtoa, placementia, installia, commitia, pushia tai mergeä. Kaikki lähteet, Windowsin paikalliset muutokset ja arkistot säilytetään. Skill-kehitys siirretään myöhemmäksi.

## Havainnot ja esto

- Molempien checkoutien tausta on main, commit ae84e8eb6f7c6659602b415283e99a14a0f77ba1. Termuxin FIRA1-inventaario: 10 tracked, 243 ignored, ei untracked-tiedostoja tämän kansion sisällä.
- Normaalin SSH-adapterin check PASS exit 0 ja repositoryn smoke-gates PASS exit 0.
- Sender vaatii lähdepolun Fear-of-Falling-juuren alle. GPT-lähde ei kelpaa; lähdekoodin hard-deny säilyy. Ei scopekiertoa, siirtokoodimuutosta tai GPT-kopiointia FOF-kansioon. Preview/content_digest NOT_RUN.
- Arkistossa on kahdeksan yksilöllistä FIRA1-dokumenttia. FI_METHODS_CANONICAL ja FI_REPORTING_SPEC ovat samaa dokumenttitekstiä. Kuudessa muussa (KB_INDEX, FI_R_WORKFLOW, DATA_DICTIONARY, FI_PROJECT_SPEC, FI_SOURCE_STATUS, FI_QC_VALIDATION) ero rajoittuu Markdown-taulukkomuotoiluun ja Source Statusin kursivointimerkkeihin; sisällölliset päätösrajat säilyvät. Arkistot säilytetään historiallisina, ei palauteta automaattisesti aktiiviseksi sisällöksi.
- Raporttiliitteen täsmällinen kuuden tiedoston lista ei ole näkyvissä: Kuuden kohdejoukko määritetään inventaarion täsmälleen kuudesta raw-hashiltaan eroavasta FIRA1-kopiosta; liitettä ei väitetä luetuksi.
- Windowsin FI_CANDIDATE_REGISTRY.csv ja FI_CHANGELOG.md poikkeavat Termuxista: CONFLICT, ei ylikirjoitusta. Ignored-paikallisaineiston luokittelu ja tiedostokohtainen hyväksyntä tarvitaan ennen toimitusvalintaa.

## Ehdotettu tuettu toimitus

Valitse vain erikseen tarkastetut ja luokitellut GPT-dokumentit/koodit rajattuun tulevaan Git-toimitukseen. Tarkasta exact diff ja tiedostohashit; Windowsin nykyisiin konflikteihin tarvitaan ihmisen tarkastama scoped merge. Mahdollinen erillinen versionoitu kohde tarvitsee ensin tuetun toimitusreitin ja käyttäjän hyväksynnän; nykyinen artifact-sender ei tue GPT-lähdettä. Ei payload-kanavan lähdekooditoimitusta.

## DoD ennen toteutusta

- [x] Inventaariosta tunnistetut kuusi raw-hashiltaan eroavaa kopiota nimetty ja sisältövertailtu; kaikki kahdeksan säilyvät.
- [ ] PC:n kaksi paikallista konfliktia ratkaistu sisällöllisesti hyväksytyssä diffissä; kaikki alkuperäiset kopiot säilyvät.
- [ ] Missing/extra/ignored-tiedostot luokiteltu; tarkka valinta ja toimitusreitti hyväksytty.
- [ ] Toimituksen toteutus valtuutettu erikseen.

## Loki

2026-10-11: Read-only-kartoitus ja arkistojen sisältövertailu tehty; scope-esto kirjattu. Tämä on metatietokortti, ei valmis tai hyväksytty toimitus.

2026-10-11: Häviötön vertailu: 214 SAME, 37 MISSING_PC, 2 CONFLICT; PC-only FI_score/RAW-037.zip. Registryltä puuttuvat Termuxin kolme DEAC-riviä (variant summary, MOI, Pain VAS), Changelogista 2026-09-18 ja 2026-09-21 päätösmerkinnät. Näitä ei aktivoida tai siirretä tieteellisenä hyväksyntänä. Tiedostokohtainen käyttöauktoriteetti, suojatut viitteet ja plugin-projektioiden ero on tarkastettava ennen luokittelua/toimitusta.

2026-10-11: Käyttäjä valtuutti repositorytason ensimmäisen FIRA1-laajennuksen, rajatun exact-commit-toimituksen ja draft-PR:n. Eristetty työhaara origin/main-pohjasta; lähdekartoitus ja kuuden arkistokopion ratkaisu pysyvät tässä samassa tehtävässä. Toteutuserät enintään viisi tiedostoa. Batch1: senderin eksplisiittinen scope, adapteri ja receiver; Batch2: synteettiset testit ja runbook. Riippumaton early-review havaitsi repo-descriptorin sidonnan, receiverin capability-checkin ja smoke/FIRA-yhdistelmän puutteet; ne korjataan erillisessä rajatussa erässä ennen final-reviewta ja toimitusta. Oikea FIRA-payload, digest-hyväksyntä, PC-kirjoitus, merge ja skill-kehitys eivät kuulu tähän valtuutukseen. K18/QC NOT_APPLICABLE: tekniikan trust-scope-laajennus, ei tieteellistä laskentaa tai aineistomuutoksia.


## 2026-10-11 tarkastettava tekninen toimitus

- Fixed trusted aliases: fof oletus, fira1 exact GPT-prefix; FIRA1-profiili-identiteetti erillinen A4:stä. Wire-protokolla/digestkentät muuttumattomat. Lähdejuuri on senderin Git-toplevel ja descriptor sidottu dev/inodeen; profiili ei valitse runtime-juurta. FIRA1-scope välitetään adapterille explicit CLI-argumenttina, receiver-valinta ei tule manifestista.
- Riippumattoman early-reviewn repo-binding, receiver-capability-check ja smoke/FIRA-ristiriita korjattu. Native fake-SSH end-to-end FIRA1-testi onnistui; oikeaa FIRA-aineistoa ei siirretty. Windowsin oikea receiver-validointi NOT_RUN (PowerShell 7 puuttuu Termuxista).
- Kuusi raw-diff-kopiota: KB_INDEX, FI_R_WORKFLOW, DATA_DICTIONARY, FI_PROJECT_SPEC, FI_SOURCE_STATUS, FI_QC_VALIDATION. Erot rajautuvat taulukoiden whitespace/separator-muotoiluun; Source Statusissa myös italic-merkit. Ei havaittuja lisättyjä komentoja, päätösrajoja tai status-/auktoriteettimuutoksia. FI_METHODS_CANONICAL ja FI_REPORTING_SPEC vastaavat dokumenttitekstiä. Historialliset kopiot säilytetään; automaattista palautusta ei tehdä.
- Registry-ehdotus: säilytä PC:n nykyiset rivit ja ehdota vain kolmea Termuxin puuttuvaa DEAC-riviä union-muutoksena, ehdollisena viite-/hyväksyntävarmennukselle. Changelog-ehdotus: säilytä nykyinen historia ja ehdota puuttuvien syyskuun 18./21. päivän tapahtumien kronologista lisäystä ilman vanhojen merkintöjen poistoa. Tämä PR ei tee kumpaakaan sisältömuutosta eikä myönnä tieteellistä hyväksyntää.
- Kahdeksan ydin-KB-dokumentin tarkka koko/SHA-ehdokaslista on paikallisessa repository-external evidenssissä; profiili EMPTY_NOT_EXECUTABLE/files[] ja kaikki käyttö-/jakelu-/classifications-hyväksynnät PENDING. Registry/Changelog, koodi ja muu luokittelematon ignored-aineisto eivät kuulu ehdokasvalintaan. Ei kaikkien 253 tiedoston allowlistia.
- Cleanup-suunnitelma: worktree, synteettinen staging ja evidenssi säilytetään erillisissä repository-external private-juurissa. Poisto tai vanhojen stagingien siivous vaatii myöhemmän hyväksynnän; ei automaattista cleanupia/retryä. Nykyinen PC-runtime ja sourcecheckout säilyvät.
- PR toimitetaan draftina vasta riippumattoman final-reviewn jälkeen käyttäjän valtuuttamassa Git-kanavassa. Ei mergeä, oikeaa payloadia/digest-hyväksyntää, PC-sijoitusta tai skill-kehitystä.
