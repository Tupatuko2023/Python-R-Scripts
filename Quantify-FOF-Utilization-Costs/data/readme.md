# data/ (Quantify-FOF-Utilization-Costs)

Tämä kansio sisältää **metadata-only** -artefaktit, joita käytetään analyysiputken rakentamiseen ja validointiin **Option B** -tietosuojaperiaatteella (ei yksilötason rekisteriotteita Gitissä).

## Mitä tässä kansiossa on

### Metadata-artefaktit (DATA_ROOTista generoitu; turvallinen Gitissä)

- `data_dictionary.csv`
  - Konekielinen skeemakuvaus per lähde: sarakenimet, tyypit ja turvalliset aggregaatit (esim. puuttuvuusprosentti ja otos-uniikit).
  - Sisältää myös englanninkielisen standardoinnin kentät ja redaktoidut lähdepolut.

- `Muuttujasanakirja.md`
  - Ihmislukoinen yhteenveto lähteistä (redaktoituna) ja skannauksesta.
  - Ei raakaarvoja.

- `VARIABLE_STANDARDIZATION.csv`
  - Mapping per `(source_dataset, variable)`:
    - `standard_name_en` ja `variable_en` (sääntö-/sanastopohjainen)
    - `description_en` (selvästi **inferoitu** nimestä/roolista, ei varmistettu)
    - `notes` (mm. suoraan tunnisteeseen viittaavat kentät, joita ei saa käyttää repo-artefakteissa)

- `VARIABLE_STANDARDIZATION.md`
  - Nimeämissäännöt, kattavuusmittarit ja ohjeet turvalliseen käyttöön.

### Synteettinen testidata (CI-safe)

- `sample/`
  - Synteettiset aineistot testejä ja smoke-ajoja varten.
  - Ei vastaa todellisia henkilöitä.

## Data governance (Option B)

**Sallittua repoon:**
- Yllä listatut metadata-artefaktit
- Synteettiset näyteaineistot `data/sample/`

**Ei sallittua repoon:**
- Yksilötason rekisteriotteet
- Toimitetut raakadata-tiedostot
- Mikään tunnisteita sisältävä tai palautettava sisältö

Raaka/suojattu sisältö sijaitsee reposta erillisessä, suojatussa kansiossa, johon viitataan `DATA_ROOT`-ympäristömuuttujalla `config/.env`-tiedostossa (ei koskaan commitoida).

## Rekisteripoiminta (aggregoitu kuvaus)

Tilastokeskus toimitti aineiston myönnetyn luvan perusteella. Poiminta tehtiin yhdistämällä toimitettu **henkilöön viittaava tunnistelista** Tilastokeskuksen sisäiseen henkilöavaimeen, minkä jälkeen tiedot yhdistettiin tietovarastosta. Yhdistäminen onnistui kaikille toimitetuille tunnisteille (aggregaattitaso):

- Toimitettujen tunnisteiden määrä: **2108**
- Yhdistämättä jääneet: **0**

Mukana ovat myös passiiviset/aiemmat tunnisteet sekä henkilöt, jotka ovat muuttaneet ulkomaille tai kuolleet.

Kuolintiedot poimittiin pitkittäistiedostosta tutkimuskäyttöön. Aggregaattitasolla:

- Aikajänne: **2010–2019**
- Poiminnassa kuolleita henkilöitä: **578**

## Miten käyttää metadata-artefakteja

1. Generoi metadata omasta suojatusta DATA_ROOT-ympäristöstä:

   ```bash
   python3 scripts/10_build_data_dictionary_from_dataroot.py
   ```

2. Käytä `VARIABLE_STANDARDIZATION.csv`-tiedostoa englanninkielisen nimeämisen lähtökerroksena.

3. `description_en` on **inferoitu**: se pitää varmistaa erillisessä governance-vaiheessa ilman raakaarvoja.

## Redaktoidut lähdepolut

Jos lähdetiedoston nimi sisältää tunnisteisiin viittaavia osia, generaattori redaktoi ne Git-turvallisissa artefakteissa. Samalla tallennetaan deterministinen tiedostojälki (sha256 prefix), jotta provenanssi on jäljitettävissä ilman riskitekstiä.

## Tunnetut rajoitteet

- Osa "copy"-taulukoista voi olla lukukelvottomia (esim. salasanalla suojattuja). Ne merkitään `FILE_UNREADABLE`-tunnisteella eikä niistä muodosteta skeemaa.
- Suoraan tunnisteeseen viittaavat muuttujat on merkitty `notes`-kenttään, eikä niitä saa käyttää repo-artefakteissa; käytä pseudonymisoituja linkitysavaimia.

## Retentio ja toimitusmuistutukset (ylätaso)

- Aineistoa saa käsitellä vain luvan mukaiset henkilöt.
- Virheet tulee raportoida sovitussa aikataulussa.
- Luvan päättyessä aineisto palautetaan tai sen hävitys vahvistetaan, tai haetaan jatkoa ajoissa.
