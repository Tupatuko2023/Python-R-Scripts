# DEAC Frailty Index

Tämä aliprojekti toteuttaa hyväksytyn 20 komponentin
DEAC-raihnaisuusindeksin laskennan rakennusosia. `src/deac_components.py`
sisältää 19 erillistä pisteytysfunktiota, ja `src/deac_index.py` kokoaa 20
nimettyä, valmiiksi pisteytettyä komponenttia synteettisillä syötteillä.
MOI:n ikäpisteiden poisto ja kohorttikohtainen kvintiilipisteytys ovat
synteettisesti toteutettuja rakennusosia. MOI:n lähtötilanteen ikäpisteet
vähennetään kerran. Waris 2011 §4.1:n viimeisen ikämerkinnän sanamuoto on
"75 years"; sen soveltaminen kaikkiin vähintään 75-vuotiaisiin (6 ikäpistettä)
on Ownerin 2026-10-01 vahvistama tulkinta, ei artikkelin eksplisiittisesti
määrittelemä ikäraja. Lähdesidonta ja tuotantoaineistolla varmennettu
DEAC-laskenta ovat vielä kesken.
`src/deac_source_adapter.py` tarjoaa konfiguroitavan, synteettisesti
testattavan rajapinnan semanttisten lähdekenttien normalisointiin, nykyisiin
pisteytysfunktioihin ja 20-paikkaiseen kokoajaan. Todellisia lähdeheadereita,
erityiskoodeja tai osallistujarivejä ei sisällytetä repoon. Suojattu
kenttäkartta, mittausvalinnat ja testikohtaiset koodit on annettava erikseen;
niiden puuttuessa adapteri pysähtyy fail-closed. Adapteri ei valitse
mittauspuolta tai testiyritystä eikä tulkitse tuntematonta E/E1-merkintää.
Se muuntaa kipuarvon vain jo cm-yksikköön normalisoituna ja kävelyajan vain
jo valitusta 10 m ajasta; se ei päätä lähteen yksikköä, paremman jalan/käden
valintaa tai testikohtaista koodimerkitystä. Kokoaja käyttää hyväksyttyä
havaittujen pisteiden nimittäjää
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

Synteettinen adapterirajapinta on toteutettu, mutta tuotantokenttien
sidonta odottaa suojatun skeeman ja käytetyn KAAOS-/TOIMIVA-protokollan
varmennusta. Seuraava vaihe on vahvistaa MOI:n lähdekentät, VAS-yksikkö,
paremman jalan ja käden muodostus, valittu 10 m mittaus sekä testikohtaisten
erityiskoodien merkitykset. Legacy-koodi auttaa paikantamaan ehdokkaita mutta
ei yksin määrää DEAC:n sääntöjä. B1/B2 pysyvät avoimina, eikä niitä ratkaista
adapterissa.

Osallistujatason `DATA_ROOT` on repositorion ulkopuolella. Synteettinen
adapterivaihe ei aseta, lue eikä kopioi sitä. Paikallisia polkuja ja salaisuuksia
ei tallenneta versionhallintaan.
