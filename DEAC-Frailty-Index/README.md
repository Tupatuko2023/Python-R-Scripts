# DEAC Frailty Index

Tämä aliprojekti sisältää hyväksytyn 20-komponenttisen DEAC-indeksin
lähdesovittimen, komponenttipisteyttäjät, kohorttivalitsimen ja suojatun
ajurin. PR #184:n toteutus yhdistettiin `main`-haaraan 2026-10-05.
Varmennettu Termux-ajo tuotti 527 ensimmäisen käynnin kohortin jäsenelle
470 indeksiä; 57 jäi 80 prosentin kattavuusrajan alle. Suojattu ajomanifesti
lukitsee lähdesnapshotin, asetukset ja kooditiedostojen tiivisteet.

Ajokomento, riippuvuudet, suojattujen asetusten sijainnit ja rekisteriviitteet
on kuvattu [Termux-ajo-ohjeessa](docs/DEAC_TERMUX_RUNBOOK.md). Todelliset
otsakkeet, lähdekoodit ja osallistujatulokset pysyvät repo-ulkopuolella.
Tutkimuksellinen mittarin validointi on erillinen, vielä aloittamaton vaihe.

## Tieteellinen auktoriteetti

Tieteelliset päätökset hyväksyy väitöskirjan ihmisomistaja. Kanoninen
tieteellinen tila on yksityisen `FOF-Dissertation-Project`-repon
`METHODS_AND_SCORING.md` §3.1. [DEAC-handover](docs/DEAC_HANDOVER.md) on siitä
johdettu, ei-kanoninen tilannekuva. Tämä analyysirepo sisältää myöhemmin vain
toteutuksen ja validoinnin. Jos lähteet ovat ristiriidassa, työ pysähtyy
omistajan tieteellistä ratkaisua varten.

## Seuraava työvaihe

Arvioi erikseen DEAC-mittarin jakaumaa, kattavuutta ja herkkyyttä sekä ennalta
määriteltyjä yhteyksiä ulkoisiin tai kliinisiin mittareihin. Tämä arviointi ei
muuta pisteytyssääntöjä eikä ratkaise avoimia tutkimuskysymyksiä B1/B2 ilman
erillistä Ownerin päätöstä. Kanoninen tieteellinen tila on yksityisen
`FOF-Dissertation-Project`-repon `METHODS_AND_SCORING.md` §3.1;
[DEAC-handover](docs/DEAC_HANDOVER.md) on johdettu tilannekuva.
