# DEAC-päätöslisä: kolme lähdenormalisoinnin soveltamissääntöä

## Tila ja provenienssi

Tämä on Python-R-Scripts-repoon paikallisesti kirjattu, johdettu
soveltamislisä. Se ei korvaa yksityisen väitöskirjarepon kanonista
päätösrekisteriä tai `METHODS_AND_SCORING.md`-tiedostoa. Omistajan
vahvistuksen mukaan päätös tehtiin 2026-10-02; vahvistusviesti toimitettiin
Termux-agentille 2026-10-03 tässä keskustelussa. Viestille ei ole annettu
pysyvää tunnistetta eikä uutta DMA1-päätöstunnusta ole oletettu.

Yksityisen DMA1-päätösrekisterin ja METHODS-omistajan synkronointi on
myöhempi, vielä tekemätön työ. Siihen asti tämä lisä dokumentoi vain tässä
vahvistetut kolme soveltamissääntöä.

## Hyväksytyt soveltamissäännöt

1. **Käden/jalan kahden puolen tulokset:** jos vain toiselta puolelta on
   numeerinen mitattu tulos, käytetään sitä. Jos molemmilta puolilta on
   numeerinen mitattu tulos, valitaan parempi mitattu tulos.
2. **Fyysisen testin E ja E1:** E ilman varmennettua syytä on puuttuva.
   Jos kirjattu syy varmentaa fyysisen tai toiminnallisen kyvyttömyyden,
   testivaje on 1. E1 on puuttuva. Mitattu puristusluokka 0 ei ole
   suoriutumattomuuskoodi; sen hyväksytty komponenttivaje on 1.
3. **10 metrin kävelyaika ja apuvälineluokka:** puuttuva 10 metrin aika on
   puuttuva kävelynopeuskomponentti, vaikka apuvälineluokka olisi kirjattu.
   Apuvälineluokka yksin ei osoita kyvyttömyyttä. Erillisesti varmennettu
   fyysinen/toiminnallinen kyvyttömyys saa vajeen 1.

Puuttuvat komponentit eivät sisälly havaittujen pisteiden nimittäjään.
Handover 1.2.0:n 80 prosentin kattavuussääntö säilyy. Muut komponentit ja
B1/B2 eivät muutu.

## Käyttöraja

Sääntöjen soveltaminen lähdekoodeihin edellyttää testikohtaista,
repo-ulkopuolista runtime-sidontaa. Tuntematonta E-koodia tai syytä ei saa
luokitella kyvyttömyydeksi oletuksena. Tämä lisä ei itsessään vahvista
yksityisen METHODS-tiedoston päivitystä eikä valtuuta muuta kuin siihen
liittyvässä tehtävässä erikseen rajattua aineiston käsittelyä.

## Ownerin lähdesidonnan täsmennys — 2026-10-03

Owner vahvisti DEAC v2:n AUTH_SOURCE-lähtötilanteen oikean ja vasemman käden
puristusvoimasyötteiden olevan valmiita kuntoluokkia, eivät kilogrammoina
tallennettuja raakavoimamittauksia. Kilogrammamuunnosta tai K53:n jatkuvan
HGS-mittauksen käsittelyä ei sovelleta näihin syötteisiin.

Validi lähdeluokka 0 säilyy kelvollisena havaintona ja saa hyväksytyn DEAC-
vajepisteen 1. Ownerin ja senioribiostatistikon aiemmin tunnistamat
tulkintakelvottomat lähdekoodit ovat puuttuvia (`NA`); niille ei päätellä
mittayksikköä, kuntoluokkaa eikä vajepistettä. Niiden tarkkaa koodiluetteloa
ei löytynyt tarkastetuista suojatuista skeemakartoista. Siksi ajoa ei saa
konfiguroida arvaamalla: vain vahvistettujen koodien kenttäkohtainen
normalisointi saa muuttaa arvon puuttuvaksi.

Toteutuskohtainen rajaus: lähdeluku ei vielä normalisoi näitä numeerisia
poikkeuskoodeja. Ne tulee muuntaa puuttuviksi tasan yhdessä, suojatussa
adapterivaiheessa ennen paremman käden valintaa. Jo `None`-arvoksi
normalisoitua syötettä ei käsitellä uudelleen. Täsmällinen koodiluettelo ja
DMA1-muistion pysyvä viite täydennetään suojattuun lähdesidontaan myöhemmin;
raakoja koodeja ei tallenneta tähän tiedostoon.
