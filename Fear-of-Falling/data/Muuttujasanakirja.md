# Muuttujasanakirjan lyhyt selite (data_dictionary.csv)

Tama tiedosto on **metatason** selite muuttujasanakirjalle `data_dictionary.csv`: mita sarakkeet tarkoittavat, miten keskeiset muuttujat on koodattu (0/1), mita aikapisteita kaytetaan (baseline -> 12 kk) ja miten mahdolliset **delta-/muutosmuuttujat** on laskettu. **TAMA EI ole data-aineisto** eika sisalla osallistujatason arvoja.

---

## Mihin tata kaytetaan

* Tukee FOF-alatutkimuksen **FOF x time** -sekamallia (entrypoint `analysis_mixed_workflow()`, lmer, satunnaisintersepti `(1|id)`), jossa paatulos on **`time * FOF_status`** interaktio `Composite_Z`-muutoksessa.
* Mahdollistaa QC-tarkistukset (esim. time-arvojen validointi, FOF-koodaus, puuttuvat, nimeamisvariantit).
* Auttaa refaktoroinnissa: tunnistetaan ja standardoidaan nimivariaatiot (esim. `Age` vs `age`, `Sex` vs `sex`, alkuperaiset projektinimet vs analyysinimet).

---

## Mita data_dictionary.csv sisaltaa

`data_dictionary.csv` on **autoritaerinen codebook-taulukko**: jokainen rivi kuvaa yhden muuttujan (tai johdetun muuttujan) metatiedot.

Koska sarakeotsikot voivat vaihdella projekteittain, varmista tiedoston otsikkorivi ja varmista, etta mukana on ainakin:

* muuttujan **nimi** (tasmalleen kuten datassa)
* lyhyt **selite / label**
* **tyyppi** (numeric/factor/character) tai vastaava
* **koodaus** (erityisesti 0/1 ja faktoritasot)
* **yksikko** (jos soveltuu)
* **aikapiste** (jos muuttuja on aikaspesifi) tai saanto, miten aikamuoto (long) rakentuu
* **johdanto/derivaatio** (jos muuttuja on laskettu: kaava ja lahdesarakkeet)

Jos jokin naista puuttuu, lisaa se sanakirjaan tai merkitse TODO + viite, mista tieto todentuu (protokolla, alkuperainen codebook, mittaridokumentti).

---

## Pakolliset ydinmuuttujat (malliajoa varten)

Naiden merkityksen pitaa olla yksiselitteinen `data_dictionary.csv`:ssa ja datassa:

* `id`

  * Yksiloiva tunniste (ei osallistujatason henkil?tietoja).
  * QC: sama `id` voi esiintya useilla `time`-arvoilla (long data), mutta **ei** useita riveja samalla `id`+`time` yhdistelmalla ilman perustetta.

* `time`

  * Aikaindikaattori baseline -> 12 kk (long format).
  * Sanakirjan on maaritettava: sallitut arvot, referenssitaso ja tulkinta (baseline vs 12 kk).

* `FOF_status`

  * Kaatumispelon (FOF) status, ryhmittelymuuttuja.
  * Kaytannossa esiintyy kahtena yleisena mallina:

    * 0/1-indikaattori (0 = Ei FOF, 1 = FOF), vahvistettu R/functions/io.R
    * tai faktori tasoilla `Ei FOF` ja `FOF` (referenssi `Ei FOF`)
  * Sanakirjan on kerrottava kumpi on "truth" analyysidatassa ja mika on referenssitaso.

* `Composite_Z`

  * Fyysisen toimintakyvyn yhdistelmapistemaara (z-komposiitti), mallin outcome long-formaatissa.
  * Sanakirjan on maaritettava: onko tama aikakohtainen (baseline ja 12 kk rivit) vai vain muutos (delta). Sekamallissa tarvitaan aikakohtainen `Composite_Z`.

Lisaksi kovariaatit (vahintaan): `age`, `sex`, `BMI` (tai nimivariantit, ks. yllapito).

* `age`: yksikko on kommenteissa kuvattu "vuosia" joissakin skripteissa.
* `BMI`: yksikko TODO (vahvista data_dictionary.csv:sta tai mittaridokumentista).
* `sex`: koodaus voi olla 0/1 tai merkkijono; sanakirjan on annettava eksplisiittinen mapping.

---

## Koodaukset ja aikapisteet

**Aika (baseline / 12 kk)**

* Sanakirjan pitaa kertoa tasmalleen:

  * mita `time`-arvot ovat (esim. `baseline`/`m12`, tai 0/1, tai muu)
  * mika arvo vastaa baselinea ja mika 12 kk:ta
* Jos datassa kaytetaan numerokoodia (esim. 0/1 tai 0/2), dokumentoi se. Muussa tapauksessa merkitse TODO (lahde).

**FOF_status (0/1 tai faktori)**

* Useissa pipeline-skripteissa FOF tulee alkuperaisesta indikaattorista (esim. `kaatumisenpelkoOn`) ja muunnetaan `FOF_status`-muuttujaksi (0/1).
* Sanakirjassa pitaa olla:

  * lahdemuuttuja (jos johdettu)
  * koodaus: 0 = Ei FOF, 1 = FOF (vahvistettu R/functions/io.R)
  * jos faktori: tasot ja referenssi

**Sex**

* Joissakin skripteissa `sex` on koodattu 0/1 ja mapataan tasoiksi `female`/`male`.
* Dokumentoi todellinen koodaus ja tasojen nimet `data_dictionary.csv`:ssa. Jos epaselva, merkitse TODO (lahde).

---

## Delta-muuttujat (jos kaytossa)

Sekamalli (long data) ei vaadi deltaa, mutta deltaa voi esiintya kuvailevissa analyyseissa tai vanhemmissa pipeline-osissa.

Tyypilliset (projektiin sidotut) johdokset, joita on kaytetty joissakin skripteissa:

* `Composite_Z0` = baseline-komposiitti (lahde `ToimintaKykySummary0`, vahvistettu R/functions/io.R)
* `Delta_Composite_Z` = follow-up - baseline

  * kaava: `Composite_followup - Composite_baseline`
  * kaytetty esimerkki: `ToimintaKykySummary2 - ToimintaKykySummary0` (vahvistettu R/functions/io.R; TODO: varmista, etta "2" vastaa 12 kk)

Jos deltaa kaytetaan:

* Sanakirjaan on lisattava: delta-muuttujan lahdesarakkeet ja aikapisteiden tulkinta (mika on follow-up).

---

## Yllapito-ohje: paivitys ja nimivariaatioiden valttaminen

**Yksi totuus nimeamiselle**

* Paatta yhdeksi standardiksi analyysissa kaytettavat nimet ja pida ne samoina kaikkialla:

  * `id`, `time`, `FOF_status`, `Composite_Z`, `age`, `sex`, `BMI`
* Jos lahdedatassa on toiset nimet (esim. `Age`/`Sex` tai projektispesifit nimet kuten `kaatumisenpelkoOn`, `ToimintaKykySummary0/2`), dokumentoi ne sanakirjaan "alias/source name" -kenttaan (tai erilliseen sarakkeeseen), mutta **ala vaihda** analyysin standardinimia lennossa ilman dokumentointia.

**TODO-merkinta**

* Jos yksikko, koodaus tai aikapiste on epaselva:

  * merkitse TODO
  * lisaa "todistevaatimus": mihin dokumenttiin/kohtaan tarkistus perustuu (protokolla, alkuperainen codebook, mittarin ohje, data-uuton dokumentti)

---

## Linkitys mallinnukseen (analysis_mixed_workflow)

Sanakirjan tehtava on varmistaa, etta `analysis_mixed_workflow()` saa **oikein koodatun long-datan**:

* `Composite_Z` on aikakohtainen outcome
* `time` erottaa baseline vs 12 kk ja referenssi on yksiselitteinen
* `FOF_status` on 2-tasoinen ja referenssi (0 = Ei FOF) on dokumentoitu
* Mallitaulukoiden tulkinnassa (konservatiivisesti) painopiste on **efektikoko + 95% LV**; p-arvo on toissijainen. Automaattinen tulkintateksti (4-haarainen logiikka) pitaa aina perustaa **interaktiotermin estimaattiin ja 95% LV:hen** (ei pelkkaan p-arvoon).

---

## Internal consistency check

* Nimivariaatiot ovat todennakoisia (`age` vs `Age`, `sex` vs `Sex`, `Composite_Z` vs `Composite_Z0`/`Delta_Composite_Z`): varmista etta `data_dictionary.csv` kayttaa tasmalleen samoja nimia kuin analyysidatan sarakkeet, tai dokumentoi alias-mapping yksiselitteisesti.
* `time`-koodaus ja se, mita "follow-up" tarkoittaa (12 kk vs jokin muu), pitaa loytya sanakirjasta; muuten merkitse TODO ja lisaa viite lahteeseen.
* `FOF_status`-koodaus (0/1 tai faktori) pitaa olla yksiselitteinen ja dokumentoitu sanakirjassa.
* Johdetut muuttujat (esim. delta) pitaa olla dokumentoitu kaavoin ja lahdesarakkein.
