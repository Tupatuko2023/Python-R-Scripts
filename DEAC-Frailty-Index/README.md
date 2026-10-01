# DEAC Frailty Index

Tämä aliprojekti toteuttaa hyväksytyn 20 komponentin
DEAC-raihnaisuusindeksin laskennan rakennusosia. `src/deac_components.py`
sisältää 19 erillistä pisteytysfunktiota, ja `src/deac_index.py` kokoaa 20
nimettyä, valmiiksi pisteytettyä komponenttia synteettisillä syötteillä.
MOI:n muodostus, suojattujen lähdekenttien sidonta ja tuotantoaineistolla
varmennettu DEAC-laskenta ovat vielä kesken.
Uudet funktiot eivät valitse mittauspuolta tai testiyritystä, ratkaise
suoriutumattomuuden syytä, muunna lähdeyksikköä tai sido suojattuja
lähdekenttiä. Kokoaja käyttää hyväksyttyä havaittujen pisteiden nimittäjää
ja vähintään 80 prosentin kattavuusrajaa. Puuttuva `moi`-paikka on annettava
arvolla `None`, ei poistamalla komponenttia. Vain aidosti ei-sovellettava
komponentti merkitään `ComponentStatus.NOT_APPLICABLE`-arvolla. Kokoaja ei
muodosta 19 komponentin vaihtoehtoindeksiä eikä varmista lähdesidontaa tai
tuotantoaineiston tulosta. Moduulit eivät lue osallistuja-aineistoa.

## Tieteellinen auktoriteetti

Tieteelliset päätökset hyväksyy väitöskirjan ihmisomistaja. Kanoninen
tieteellinen tila on yksityisen `FOF-Dissertation-Project`-repon
`METHODS_AND_SCORING.md` §3.1. [DEAC-handover](docs/DEAC_HANDOVER.md) on siitä
johdettu, ei-kanoninen tilannekuva. Tämä analyysirepo sisältää myöhemmin vain
toteutuksen ja validoinnin. Jos lähteet ovat ristiriidassa, työ pysähtyy
omistajan tieteellistä ratkaisua varten.

## Seuraava työvaihe

FIRA1:n ensimmäinen varsinainen ajo on **HANDOVER REVIEW + IMPLEMENTATION
FEASIBILITY AUDIT**. Se arvioi lähdeskeeman ja toteutettavuuden; tässä
bootstrapissa ei ratkaista B1/B2-rajausta eikä kirjoiteta pisteytyskoodia.
Vanha FI22/KAAOS/EFI-koodi voi olla teknistä vertailuaineistoa, mutta se ei
määrää DEAC:n sääntöjä.

Osallistujatason `DATA_ROOT` on repositorion ulkopuolella. Tätä bootstrapia
varten sitä ei aseteta, lueta eikä kopioida. Paikallisia polkuja ja salaisuuksia
ei tallenneta versionhallintaan.
