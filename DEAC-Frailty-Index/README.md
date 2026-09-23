# DEAC Frailty Index

Tämä aliprojekti on hyväksytyn 20 komponentin DEAC-haurausindeksin
toistettavaa toteutusta ja validointia varten. DEAC-toteutusta ei ole vielä
olemassa.

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
