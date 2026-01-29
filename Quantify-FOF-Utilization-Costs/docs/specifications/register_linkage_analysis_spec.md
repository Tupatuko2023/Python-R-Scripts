# Register Linkage and Analysis Specification (Quantify-FOF-Utilization-Costs)

**Status**: Draft (Option B, metadata-only)
**Dictionary**: `data/data_dictionary.csv` (generated from DATA_ROOT; includes `FILE_UNREADABLE` markers when applicable)
**QC outputs**: `outputs/qc/*` (gitignored)

## A. Kohdejoukko (Cohort)

- Määrittele tutkimusjoukko inkluusio-/ekskluusio-kriteereillä.
- Määrittele baseline/index-date sekä mahdollinen verrokkijoukon muodostus.
- Viittaa analyysissä käytettäviin avainkenttiin `data_dictionary.csv`-tiedoston perusteella:
  - tunniste (pseudonymisoitu): `role_guess=identifier`
  - ajankohta/päivämäärä: `role_guess=date`

## B. Rekisterilähteet ja linkitysavaimet

- Lähdedatasetit: `data/Muuttujasanakirja.md` listaa DATA_ROOT relpathit ja metadatan.
- Linkitysavain: pseudonymisoitu tunniste (ei henkilötunnusta).
- Linkityslogiikka:
  - deterministinen yhdistäminen tunnisteella
  - jos useita lähteitä, dokumentoi join-järjestys ja 1:n-moneen -tilanteiden käsittely
  - aggregaattitason raportit vain erillisellä luvalla

## C. Seuranta-aika (Time window)

- Index date: baseline/mittauspäivä.
- Seuranta: määrittele pituus (esim. 12/24 kk) ja sensurointi (rekisterin loppu, kuolema tms. jos saatavilla).
- Person-time: dokumentoi laskentasääntö (pseudokoodi).

## D. Utilisaatio-outcomet

- Määrittele palvelunkäytön mittarit (käynnit/hoitopäivät/episodit) ja luokittelut.
- Mapppaa `data_dictionary.csv`-kenttiin (tyypillisesti `role_guess=utilization`).
- Dokumentoi aikarajaukset (esim. baseline → seurannan loppu).

## E. Kustannus-outcomet

- Määrittele kustannusmuuttujat (EUR) ja aggregointi seurantajaksolle.
- Mapppaa `data_dictionary.csv`-kenttiin (tyypillisesti `role_guess=cost`).
- Dokumentoi NA vs 0 -säännöt.

## F. Altisteet ja kovariaatit

- Altiste: FOF-mittari (koodaus ja baseline-ajankohta).
- Kovariaatit: demografia (`role_guess=demographic`), komorbiditeetit/diagnoosit, aiemmat tapahtumat (jos saatavilla).
- Koodistot kuvataan metadata-only tasolla; mappingit erillisinä tauluina (ei yksilötaso).

## G. QC ja tietosuoja (Option B)

- Skeema/QC: varmista kenttien olemassaolo `data_dictionary.csv`-tiedoston avulla.
- Puuttuvuus: `missing_rate_sample` on laskettu otoksesta (metadata-only).
- Linkityksen kattavuus: raportoidaan vain aggregaattitasolla; n<5 suppressio raporteissa.
- Regressiot: unittest + QC smoke (`--use-sample`).

## Lukukelvottomat / salasanasuojatut kopiot

Kaksi DATA_ROOTissa ollutta “kopio.xlsx” -tiedostoa on salasanasuojattuja kopioita alkuperäisistä, eikä niitä tarvita analyysiin.

Pipeline **ei muokkaa eikä poista** DATA_ROOTin sisältöä (ulkoinen suojattu alue). Nämä lähteet on merkitty muuttujasanakirjaan `FILE_UNREADABLE` / `UNREADABLE/COPY/PASSWORD-PROTECTED` -metadatalla, ja analyysi perustuu luettavissa oleviin lähteisiin.
