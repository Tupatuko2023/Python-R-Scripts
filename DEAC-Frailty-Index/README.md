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
Mittarin ominaisuuksien ja tutkimusyhteyksien arviointi jatkuu Termuxissa
paikallisen handoverin, päätöslisän, suojatun konfiguraation ja varmennetun
ajomanifestin perusteella. PC-repon synkronointi tehdään myöhemmin; sen
tavoittamattomuus ei estä hyväksytyn version käyttöä tai arviointia. Todellinen
ristiriita hyväksytyissä pisteytyssäännöissä käsitellään erikseen.

## Tieteellinen auktoriteetti

Tieteelliset päätökset hyväksyy väitöskirjan ihmisomistaja. Kanoninen
tieteellinen tila on yksityisen `FOF-Dissertation-Project`-repon
`METHODS_AND_SCORING.md` §3.1. [DEAC-handover](docs/DEAC_HANDOVER.md) on siitä
johdettu, ei-kanoninen tilannekuva. Tämä analyysirepo sisältää hyväksytyn
toteutuksen, sen varmennetun käytön sekä erikseen rajatun mittarin
ominaisuuksien ja tutkimusyhteyksien arvioinnin. PC-repon puuttuminen ei estä
hyväksytyn version käyttöä paikallisten varmennettujen aineistojen perusteella.
Jos hyväksytyissä säännöissä ilmenee todellinen ristiriita, se pysäytetään ja
viedään omistajan tieteelliseen ratkaisuun.

## Seuraava työvaihe

Arvioi DEAC-mittarin jakaumaa, komponenttien puuttuvuutta ja kattavuutta sekä
470 indeksin saaneen ja 57 kattavuusrajan alittaneen vertailua. Arviointi
jatkuu Termuxissa paikallisen handoverin, päätöslisän, suojatun konfiguraation
ja varmennetun manifestin perusteella; PC-repon synkronointi tehdään
myöhemmin. PC-yhteyden puuttuminen ei estä tätä työtä, mutta todellinen
sääntöristiriita käsitellään erikseen. Arviointi ei muuta hyväksyttyjä
pisteytyssääntöjä eikä ratkaise avoimia tutkimuskysymyksiä B1/B2 ilman
erillistä Ownerin päätöstä. Kanoninen tieteellinen tila on yksityisen
`FOF-Dissertation-Project`-repon `METHODS_AND_SCORING.md` §3.1;
[DEAC-handover](docs/DEAC_HANDOVER.md) on johdettu tilannekuva.
