# Analyysisuunnitelma (Draft v2): Kaatumisen pelon (FOF) ja frailtyn yhteys tapaturmiin liittyvään palvelukäyttöön ja terveydenhuollon kustannuksiin (Osatyö II / Aim 2)

- **Tila:** `Draft v2` (menetelmäluonnos katselmointiin — ei lopullinen hyväksytty AIM2-SAP)
- **Konteksti:** Osatyö II (Aim 2), `Quantify-FOF-Utilization-Costs`
- **Tietosuoja ja hallinta:** Option B (raakadata ja henkilötason rekisteriaineisto pysyvät repon ulkopuolella `DATA_ROOT`-ympäristössä; pienten solujen suoja `n < 5`; [GEMINI.md](../GEMINI.md), [CLAUDE.md](../CLAUDE.md), [WORKFLOW.md](../WORKFLOW.md))

---

## 1. Dokumentin tarkoitus ja kolmen tason erottelu

Tämä dokumentti jäsentää Osatyön II (Aim 2) analyysisuunnitelman valmistelutilan ja erottaa kolme tasoa, joita ei saa sekoittaa toisiinsa:

1. **Hyväksytyt tutkimus-, hallinta- ja tietosuojarajaukset:** ei-kausaalinen assosiaatiotulkinta, Option B -tietosuoja, `frozen`-tason muuttujamappaus ([DATA_DICTIONARY_WORKFLOW.md](DATA_DICTIONARY_WORKFLOW.md)), aggregaattien kaksiosainen valtuutus ja `n < 5` -suojaus, tapaturmiin liittyvän erikoissairaanhoidon rekisterikehys sekä terveysvajeiden kertymään (_deficit accumulation_) perustuva frailty-malliperhe (Fried-fenotyyppiä ei ole valittu projektin malliksi).
2. **Luonnosasteiset menetelmäehdotukset (`PROPOSED / DRAFT`):** henkilö–jakso-paneeliasetelma (vaihtoehtona koko seurantaikkunan henkilötason analyysille), negatiivinen binomiregressio palvelukäyttölaskureille, positiivisten kustannusten Gamma-GLM, kaksiosainen (_two-part / hurdle_) malli yhtenä nollahavainnot huomioivana mallivaihtoehtona sekä henkilötason klusterirobustit keskivirheet ja klusteri-bootstrap. Nämä ovat ehdotuksia eivätkä lukitse lopullista AIM2-SAPia.
3. **Nykyiset versioidut toteutustiedostot ja avoimet menetelmäpäätökset (`OPEN`):** aliprojektissa versioidut skriptit ovat teknisiä apuvälineitä tai aiempien työvaiheiden luonnoksia eivätkä vahvista AIM2:n lopullista tieteellistä spesifikaatiota. Osatyön I (Aim 1) mittari-, seuranta-, kovariaatti- tai arvotusratkaisuja ei siirretä Osatyöhön II ilman erillistä AIM2-soveltuvuuden arviointia ja hyväksyntää.

---

## 2. Tutkimustavoitteet ja asetelman rajaukset

### 2.1 Tutkimuskysymykset

- **Suorat terveydenhuollon kustannukset (Osatyön II ydinkysymys):** Miten lähtötilanteen kaatumisen pelko (_fear of falling_, `FOF`) ja frailty ovat yhteydessä ikääntyneiden tapaturmiin liittyvien erikoissairaanhoidon avohoitokäyntien ja sairaalahoitojaksojen suoriin kustannuksiin?
- **Palvelukäyttö (rinnakkainen / tukeva tarkastelu — esittämisraja `OPEN`):** Miten lähtötilanteen `FOF` (ja hyväksyttävän spesifikaation mukaisesti frailty) on yhteydessä tapaturmiin liittyvien erikoissairaanhoidon avohoitokäyntien ja sairaalahoitojaksojen määrään? Palvelukäyttö ja kustannukset pidetään käsitteellisesti ja analyyttisesti erillisinä tarkastelukohteina; Osatyön I ja Osatyön II lopullinen keskinäinen esittämisraja vahvistetaan tutkimussuunnitelman päivityksessä.
- **Mahdollinen heterogeenisyystarkastelu (`PROPOSED / OPEN`):** Vaihteleeko `FOF`:n yhteys palvelukäyttöön tai kustannuksiin hyväksyttävän _deficit accumulation_ -frailtymittarin tai seuranta-ajan mukaan (efektimodifikaatio ilman kausaaliväitteitä)? Yhdysvaikutustermit (`FOF × frailty` tai `FOF × period`) eivät ole ennalta lukittuja ja sisällytetään vain, jos lopullinen hyväksytty SAP ne nimenomaisesti määrittelee.

### 2.2 Kohortti, palvelualue ja avoin seurantarakenne

- **Kohortti ja rekisterilinkitys:** KAAOS/MFFP-kohortin lähtötilanteen kliiniset ja toiminnalliset havainnot yhdistettynä tapaturmiin liittyviin alueellisen erikoissairaanhoidon avohoidon ja sairaalahoidon rekisteritietoihin kontrolloidussa `DATA_ROOT`-ympäristössä. Aiemman suunnitelmaluonnoksen yleisluontoiset kotihoito- ja kuntoutusesimerkit eivät kuvaa tätä rekisterirajausta.
- **Analyysiasetelma ja jakson pituus (`OPEN`):**
  - _Vaihtoehto A (`PROPOSED` tässä luonnoksessa):_ Epätasapainoinen henkilö–jakso-paneeli (_person–period_), jossa jakson pituus (esim. kalenterivuosi tai muu jakso) päätetään ennen aineiston muodostusta.
  - _Vaihtoehto B (`OPEN` vertailuvaihtoehto):_ Koko seurantaikkunan henkilötason analyysi (jolloin paneelirakenne voi toimia täydentävänä tarkasteluna tai jäädä pois).
- **Seuranta-aika ja päättävät tapahtumat (`OPEN` AIM2-vahvistukselle):** Lähtötilanteen indeksipäivän määrittely, hallinnollinen päättymispäivä, kuoleman käsittely (riskiajan päättyminen vs. kilpaileva tapahtuma sekä kuolinhetken ja mahdollisten kuolemanjälkeisten kirjausten käsittely), poismuutto ja rekisteriaukot lukitaan AIM2:n lopullisessa SAPissa ennen tuotantoajoja. Osatyön I seuranta- tai kuolemansääntöjä ei oleteta automaattisesti voimassa oleviksi AIM2:ssa.
- **Pääaltiste:** Lähtötilanteen `FOF` (`FOF = 1` vs. `FOF = 0`), joka mahdollisessa paneeliasetelmassa kantautuu henkilön seurantajaksoille.

---

## 3. Muuttujastandardointi, käsitteiden erottelu ja avoimet mittariportit

### 3.1 Muuttujastandardointi ja tietosuojasäännöt (voimassa olevat velvoitteet)

- **Ei arvailua (_Adherence / “Do not guess”_):** Kaikki analyysissä käytettävät muuttujat on kartoitettava tiedostoon `data/VARIABLE_STANDARDIZATION.csv` ([VARIABLE_STANDARDIZATION.md](../data/VARIABLE_STANDARDIZATION.md); Option B: repo sisältää vain metatietoa ja synteettisiä esimerkkejä, varsinainen data pysyy `DATA_ROOT`-polussa). Muuttujanimiä, yksiköitä tai koodauksia ei saa keksiä.
- **Mapping governance:** Analyysissä saa käyttää vain `frozen`-tilaan hyväksyttyjä mappauksia ohjeen [DATA_DICTIONARY_WORKFLOW.md](DATA_DICTIONARY_WORKFLOW.md) sääntöjen mukaisesti; `inferred`-, `tbd`- ja `artifact`-tilaiset rivit ovat oletuksena estettyjä.
- **Cleanup deferral:** Mahdolliset `artifact`-, duplikaatti- ja redaktointiriskit ratkaistaan erillisessä metatietojen siivoustehtävässä (`Phase 2`), eivät analyysisuunnitelman oletuspolussa.
- **Tunniste- ja tulostesuoja:** `DIRECT_IDENTIFIER`-merkittyjä kenttiä, yksilötason rivejä tai absoluuttisia polkuja ei saa tallentaa repoon eikä tulostaa loki- tai konsolitulosteisiin ([runbook.md](runbook.md), [RUNBOOK_SECURE_EXECUTION.md](../../docs/guides/RUNBOOK_SECURE_EXECUTION.md)).

### 3.2 Palvelukäytön ja neljän rahallisen käsitteen erottelu

Suunnittelussa, koodissa ja raportoinnissa seuraavia viittä käsitettä ei saa nimetä toisikseen ilman suoraa lähdevarmistusta:

1. **Palvelukäyttö (_service utilization_):** Rekisteristä johdettu tapahtumamäärä tai hoitojaksojen/päivien lukumäärä (esim. avohoidon kirjausrivit tai uniikit käyntipäivät; sairaalahoidon jaksoaloitukset tai päällekkäisyyksistä yhdistetyt päivät).
2. **Laskennallinen rahallinen arvo (_calculated monetary valuation_):** Rekisteristä johdettujen palvelukäyttöyksiköiden määrä kerrottuna yksikköhintataulukolla määritellyssä hintavuodessa.
3. **Toteutunut terveydenhuollon kustannus (_realized production cost_):** Palveluntuottajan kustannuslaskenta- tai rekisterijärjestelmästä yksilö- tai hoitojaksotasolla todennettu suora tuotantokustannus.
4. **Laskutushinta (_billed price / tariff_):** Palveluntuottajan tilaajalta, hyvinvointialueelta, kunnalta tai vakuutusyhtiöltä veloittama sopimus- tai hinnastohinta.
5. **Asiakasmaksu (_patient out-of-pocket fee_):** Potilaalta perittävä lakisääteinen maksu, joka ei kuvaa hoidon kokonaiskustannusta.

AIM2:n arvotusmenetelmä (yksilötason toteutunut kustannus vs. yksikköhintapohjainen rahallinen arvo), hintavuosi ja mahdollinen deflatointi ovat tilassa **`OPEN`**; Osatyön I hintavuosi- tai arvotusratkaisuja ei siirretä AIM2:een ilman erillistä hyväksyntää.

### 3.3 Kolmen tulossuureen erottelu: ehdollinen keskiarvo, koko kohortin odotettu kustannus ja `EUR/PY`

Kustannus- ja arvotusanalyyseissä seuraavat kolme suuretta kuvaavat eri ilmiöitä ja on pidettävä erillään:

1. **Positiivisten kustannusten ehdollinen keskiarvo** ($\mathbb{E}[\text{Cost} \mid \text{Cost} > 0]$): kuvaa keskimääräistä kustannusta ainoastaan niillä henkilöillä tai jaksoilla, joilla syntyi positiivisia kustannuksia ($\text{Cost} > 0$). Se ei sisällä nollahavaintoja eikä yksinään kuvaa koko kohortin kustannuseroa.
2. **Koko kohortin odotettu kustannus** ($\mathbb{E}[\text{Cost}]$, ehdoton / _unconditional_ odotusarvo euroina `€`): kattaa koko analyysikohortin nollahavainnot ($\text{Cost} = 0$) mukaan lukien määritellyssä seurantaikkunassa tai jaksossa.
3. **Henkilöaikaan suhteutettu tulos (`EUR/PY`, `€/henkilövuosi`):** suhteuttaa rahallisen suureen kertyneeseen henkilöaikaan ja riippuu suoraan siitä, miten seuranta-aika, jaksotus ja päättävät tapahtumat määritellään.

### 3.4 Tapaturmavasteiden yksiköt ja sairaalaskeeman tarkistusportti (`OPEN`)

- **Vasteyksiköt (`OPEN`):** Ennen analyysiä lukitaan avohoidon laskentayksikkö (toimitetut lähderivit vs. uniikit käyntipäivät), sairaalahoidon laskentayksikkö (jaksoaloitukset vs. päällekkäisyyksistä yhdistetyt hoito-/kalenteripäivät) sekä tapaturmadiagnoosien rajaussääntö.
- **Sairaalaskeeman tarkistus:** Sisäinen selvitys [2026-02-10_hospital_outcome_reconciliation.md](reports/2026-02-10_hospital_outcome_reconciliation.md) dokumentoi huomattavan eron pelkän episoditaulun ja diagnoositiedostoon yhdistetyn päivämittarin ([table2_technical_reproducibility_note.md](table2_technical_reproducibility_note.md)) välillä. Sairaalamittarin muodostussääntö ja monidiagnoosi-/siirtotilanteiden käsittely vahvistetaan ennen mallinnusta.
- **Nollat vs. puuttuva tieto (`OPEN`):** Rekisteriotteen rivittömyyden tulkinta todelliseksi nollakäytöksi tai nollakustannukseksi edellyttää lähdeaineiston väestö-, alue- ja aikakattavuuden varmistamista.

### 3.5 Altiste (`FOF`), frailty ja komponenttien päällekkäisyyskysymys (`OPEN`)

- **Frailtyn malliperhe ja avoin mittarivalinta (`OPEN`):**
  - Projektitasolla frailty-malliperheeksi on valittu **terveysvajeiden kertymä (_deficit accumulation_)**; Fried-fenotyyppiä ei ole valittu projektin malliksi, eikä Fried-proxy saa korvata varsinaista frailty-mittaria automaattisena oletuksena tai fallbackina.
  - Aiemmassa suunnitelmaluonnoksessa ja skriptissä [K40_FI_KAAOS.R](../R/40_FI/K40_FI_KAAOS.R) esiintynyt `FI22_nonperformance_KAAOS` (`frailty_index_fi`) on historiallisen analyysilinjan sopimus eikä ole AIM2:lle lukittu mittari. Vastaavasti [DEAC_HANDOVER.md](../../DEAC-Frailty-Index/docs/DEAC_HANDOVER.md) kuvaa Osatyötä I varten valmistellun 20 komponentin vajeindeksiluonnoksen, jonka suhde aiempiin `FI22`-variantteihin sekä Osatöiden I ja II lopullinen frailty-operationalisointi ovat vielä vahvistamatta.
- **Ratkaistava menetelmäkysymys — `FOF`:n ja muiden kovariaattien sisältyminen vajeindeksiin (`OPEN`):**
  - Jos tarkasteltava vajeindeksi sisältää osatekijöinä kaatumisen pelon (`FOF`), aiemmat kaatumiset tai sairastavuuskomponentin (kuten tiedostossa [DEAC_HANDOVER.md](../../DEAC-Frailty-Index/docs/DEAC_HANDOVER.md) kuvatussa 20 komponentin luonnoksessa), `FOF_status`-pääaltisteen ja tällaisen vajeindeksin sekä erillisten sairastavuus- ja kaatumishistoriakenttien samanaikainen sisällyttäminen samaan malliin aiheuttaa mekaanisen rakennepäällekkäisyyden ja mahdollisen ylivakioinnin.
  - Tätä kysymystä **ei ratkaista tässä luonnoksessa ennakko-oletuksella** (esimerkiksi esittämällä yhden komponentin poistamista tai pelkkää ikä- ja sukupuolivakiointia valmiiksi hyväksyttynä ratkaisuna), vaan AIM2:n frailty-mittari ja kovariaattirakenne päätetään nimenomaisella tieteellisellä SAP-päätöksellä ennen malliajoja.

### 3.6 Käsitteellinen muuttujatarvelista (vaatii `frozen`-standardoinnin ennen ajoa)

Standardoinnista tarkistettavat peruskentät:

- `id` (pseudonymisoitu henkilöavain analyysiympäristössä)
- `FOF_status` (lähtötilanteen binäärinen FOF-altiste)
- `age` (lähtötilanneikä vuosina)
- `sex` (sukupuoli standardoinnin mukaisesti)

Ennen malliajoa täsmennettävät ja `frozen`-tilaan vietävät kentät (`OPEN` lopulliselle SAP-päätökselle):

- `period` (jaksoavain, jos henkilö–jakso-paneeliasetelma valitaan)
- seuranta- / riskiaikakenttä (`person_time`, `PY`) hyväksyttävän seurantasäännön mukaisesti
- hyväksyttävä _deficit accumulation_ -frailtykenttä sekä sen kattavuus- ja kelpoisuuskentät
- mahdolliset muut lähtötilanteen taustamuuttujat (kuten sairastavuus tai aiemmat kaatumiset) vain siltä osin kuin lopullinen SAP sisällyttää ne ilman rakennepäällekkäisyyttä
- tapaturmiin liittyvät erikoissairaanhoidon avo- ja sairaalahoidon määrälaskurit (`Count-outcomes`) ja rahalliset suureet (`Cost-outcomes`)

Mahdollisessa henkilö–jakso-paneelissa lähtötilanteen muuttujat liitetään henkilön jaksoriveille henkilötunnisteella (`id`); aikavaihtuvia kovariaatteja ei oleteta käytettäviksi ilman erillistä SAP-päätöstä.

---

## 4. Tilastomallien luonnosehdotukset (`PROPOSED / DRAFT` — ei lukittu AIM2-SAPiksi)

### 4.0 Yleiset mallinnusvaraukset

Alla esitetyt mallit ovat alustavia **menetelmäehdotuksia**. Merkintä $m$ viittaa valittavan asetelman mukaiseen havaintoyksikköön — henkilö–jakso-ehdotuksessa $(i, t)$ ja koko seurantaikkunan henkilötason vaihtoehdossa henkilöön $i$. Vektori $\mathbf{X}_i$ on konseptuaalinen paikkamerkki lopullisessa SAPissa hyväksyttävälle lähtötilanteen kovariaattijoukolle (ei lukittu pelkkään `age + sex` -joukkoon eikä aiemman luonnoksen laajaan kovariaattilistaan). Toistomittausasetelmassa korrelaatiorakenne ehdotetaan huomioitavaksi henkilötason (`id`) klusterirobusteilla keskivirheillä (tai vaihtoehtoisesti GEE-/sekamallirakenteella SAP-päätöksen mukaan).

### 4.1 Palvelukäytön laskurivasteet (`PROPOSED`: negatiivinen binomimalli)

Henkilö–jakso-ehdotuksessa laskurivasteelle $Y_{it}$ ja riskiajalle $\text{person\_time}_{it} > 0$:

$$
Y_{it} \sim \text{NegBin}, \quad
\log\bigl(\mathbb{E}[Y_{it}]\bigr) = \beta_0 + \beta_1\,\text{FOF}_i + \gamma_t + \mathbf{X}_i^{\top}\boldsymbol{\beta} + \log(\text{person\_time}_{it})
$$

- **Konseptuaalinen kaavarunko (ehdotus):**
  `count_it ~ FOF_status + period + X_approved + offset(log(person_time))`
- **Mahdolliset yhdysvaikutukset (`OPEN`):** `FOF_status × frailty` tai `FOF_status × period` vain, jos lopullinen SAP ne hyväksyy.
- **Raportoitavat suureet (ehdotus):** suhteellinen tiheyssuhde $\text{IRR} = \exp(\beta_1)$ (95 % LV) sekä kierrätetyt ennusteet (_recycled predictions_: ennustettu `rate/PY` ryhmille `FOF = 1` vs. `FOF = 0`, suhde ja erotus henkilötason klusteri-bootstrapilla).

### 4.2 Positiivisten kustannusten ehdollinen malli (`PROPOSED`: Gamma-GLM, seuranta-ajan käsittely avoin)

Positiivisten rahallisten arvojen ($\text{Cost}_m > 0$) ehdollinen luonnosmalli ilman ennalta lukittua offset-oletusta:

$$
\text{Cost}_m \mid \text{Cost}_m > 0 \sim \text{Gamma}, \quad
\log\bigl(\mathbb{E}[\text{Cost}_m \mid \text{Cost}_m > 0]\bigr) = \alpha_0 + \alpha_1\,\text{FOF}_m + \mathbf{Z}_m^{\top}\boldsymbol{\alpha} + h(\text{seuranta-aika}_m)
$$

missä $\mathbf{Z}_m$ sisältää hyväksyttävät kovariaatit (ja paneelivaihtoehdossa jaksoefektin $\gamma_t$) ja ehdollinen termi $h(\text{seuranta-aika}_m)$ jätetään **avoimeksi (`OPEN`)**:

- vaihtoehtoina lopullisessa SAPissa ovat esimerkiksi (a) koko seurantaikkunan malli ilman offsetia tai seuranta-aika kovariaattina, tai (b) ehdollinen log-offset `offset(log(person_time))`, jos tavoitteena on suora jakso- tai henkilöaikakohtainen intensiteettisuure.
- **Konseptuaalinen kaavarunko:**
  `cost_m ~ FOF_status + Z_approved [+ ehdollinen seuranta-ajan termi], family = Gamma(link = "log")`
- **Tulkintaraja:** Kerroin $\exp(\alpha_1)$ ja tästä osasta lasketut ennusteet kuvaavat **vain positiivisten kustannusten ehdollista keskiarvoa** ($\mathbb{E}[\text{Cost}_m \mid \text{Cost}_m > 0]$), eivät koko kohortin odotettua kustannusta tai koko kohortin `EUR/PY`-eroa (ks. luku 3.3).

### 4.3 Koko kohortin nollat huomioivat kustannusmallit (`PROPOSED`: kaksiosainen malli yhtenä vaihtoehtona)

Koska palvelukäyttöön liittyvissä kustannusaineistoissa esiintyy tyypillisesti nollahavaintoja ($\text{Cost}_m = 0$) ja voimakasta oikeaa vinoutta, koko kohortin odotetun kustannuksen ($\mathbb{E}[\text{Cost}_m]$) arviointiin tarvitaan nollahavainnot huomioiva lähestymistapa.

- **Ehdotus A — Kaksiosainen (_two-part / hurdle_) malli (`PROPOSED`, ei ainoa vaihtoehto):**
  1. _Osa 1 (positiivisen kustannuksen todennäköisyys):_ logistinen regressio $\Pr(\text{Cost}_m > 0 \mid \text{FOF}_m, \mathbf{Z}_m, \dots)$.
  2. _Osa 2 (positiivisen kustannuksen ehdollinen taso):_ $\mathbb{E}[\text{Cost}_m \mid \text{Cost}_m > 0]$ esim. `Gamma(link = "log")` -mallilla (seuranta-ajan käsittely $h(\cdot)$ päätetään yhtenäisesti SAPissa).
  3. _Koko kohortin odotettu kustannus:_ $\mathbb{E}[\text{Cost}_m] = \Pr(\text{Cost}_m > 0) \times \mathbb{E}[\text{Cost}_m \mid \text{Cost}_m > 0]$, josta voidaan muodostaa kierrätetyt ennusteet ja henkilötason klusteri-bootstrapin luottamusvälit.
- **Muut SAP-vaiheessa arvioitavat vaihtoehdot (`OPEN`):** Kaksiosainen malli ei ole ainoa mahdollinen nollat huomioiva ratkaisu. Aineiston nollaosuuden, jakaumamuodon ja pienempien alaryhmien koon perusteella lopullisessa SAPissa voidaan arvioida vaihtoehtoina tai herkkyysanalyyseinä myös esimerkiksi yksiosaista yleistettyä lineaarista mallia koko otoksessa (kuten Tweedie- tai Poisson/Quasi-GLM log-linkillä) tai ei-parametrisia bootstrap-pohjaisia odotusarvovertailuja.

---

## 5. Laadunvarmistus-, valtuutus- ja tietosuojaportit (QC & Security Gates)

Kaikki myöhemmät aineisto- ja malliajot ovat alisteisia aliprojektin voimassa oleville valtuutus- ja tietosuojaporteille ([GEMINI.md](../GEMINI.md), [CLAUDE.md](../CLAUDE.md), [WORKFLOW.md](../WORKFLOW.md), [runbook.md](runbook.md), [RUNBOOK_SECURE_EXECUTION.md](../../docs/guides/RUNBOOK_SECURE_EXECUTION.md)). **Tässä dokumenttipäivityksessä (`Draft v2`) tuotantoaineiston QC- tai analyysiajoja ei suoriteta eikä `DATA_ROOT`-aineistoa lueta.**

1. **Tehtäväkohtainen ajovaltuutusportti:** Tuotantoaineiston esikäsittely-, QC- tai malliajoja (`Full Run`) saa käynnistää vain nimenomaisesti valtuutetussa analyysitehtävässä, kun vaaditut SAP- ja mappausportit on hyväksytty. Puhtaat dokumentaatio- ja hallintotehtävät eivät koskaan käynnistä `DATA_ROOT`-ajoja.
2. **Option B -polku- ja tunnistepolitiikka:** Aineisto luetaan vain ulkoisesta `DATA_ROOT`-sijainnista (paikallinen `config/.env`). Tulosteet ohjataan gitignoroituun `outputs/`-kansioon ilman yksilörivejä, suoria tunnisteita (`DIRECT_IDENTIFIER`) tai absoluuttisia polkuja (`qc_no_abs_paths_check` pysäyttää ajon virheeseen polkuvuodosta).
3. **Aggregaattien kaksiosainen valtuutusportti (_double-gated aggregates_) ja `n < 5` -pienisolusuojaus:** Aggregaattitulosteiden muodostaminen ja vienti vaativat samanaikaisesti (i) ihmisomistajan nimenomaisen tehtäväkohtaisen valtuutuksen ja (ii) eksplisiittisen ympäristö-/ajokytkimen (`ALLOW_AGGREGATES=1` sekä soveltuvissa komentorivityökaluissa `--allow-aggregates`, ks. [runbook.md](runbook.md)). Pienten solujen (`n < 5`) osalta suojattavat lukumäärät ja tunnusluvut jätetään tulosteissa tyhjiksi, rivi merkitään lipulla `suppressed=1` ([runbook.md](runbook.md)), ja ennen raportointia tai ulosvientiä tehdään täydentävän tiedon vuotoriskin tarkistus (_complementary / secondary disclosure_: suojattuja arvoja ei saa voida päätellä takaisin reunayhteissummista, osaryhmien erotuksista tai rinnakkaistaulukoista, tarvittaessa täydentävää peittoa tai luokkien yhdistämistä käyttäen; ks. [RUNBOOK_SECURE_EXECUTION.md](../../docs/guides/RUNBOOK_SECURE_EXECUTION.md)).
4. **Aineiston tekniset QC-tarkistukset ennen mallinnusta (kun ajo on erikseen valtuutettu):**
   - `frozen`-mappausten täydellisyys (`data/VARIABLE_STANDARDIZATION.csv`) ja sairaalahoidon lähdeskeeman (`episodefile` vs. diagnoosiyhdiste) varmistus;
   - looginen eheys (`counts >= 0`, `costs >= 0`, hyväksytty seuranta-aika `> 0`, päivämäärien järjestys ja mahdollisten kuolemanjälkeisten kirjausten tarkistus);
   - `FOF_status`-altisteen, hyväksyttävän frailty-mittarin ja kovariaattien puuttuvuus ja kattavuus;
   - nollahavaintojen osuus, jakauman oikea vinous ja yksittäisten suurten kustannushavaintojen vaikutus ennen kustannusmallin lopullista valintaa.

---

## 6. Aliprojektissa versioidut toteutustiedostot ja toistettavuusrajat

Tässä aliprojektihakemistossa ovat tällä hetkellä versioituina mm. seuraavat skriptit:

- **Metatieto-, esikäsittely- ja synteettiset apuskriptit (`scripts/`):** [00_inventory_manifest.py](../scripts/00_inventory_manifest.py), [10_preprocess_tabular.py](../scripts/10_preprocess_tabular.py), [30_qc_summary.py](../scripts/30_qc_summary.py), [40_build_knowledge_package.py](../scripts/40_build_knowledge_package.py), [50_build_report.py](../scripts/50_build_report.py), [01_generate_synthetic_panel.py](../scripts/01_generate_synthetic_panel.py) ja [10_build_panel_person_period.R](../scripts/10_build_panel_person_period.R).
- **R-analyysi- ja taulukkoluonnokset (`R/`):** [20_qc_panel_summary.R](../R/20_qc_panel_summary.R), [30_models_panel_nb_gamma.R](../R/30_models_panel_nb_gamma.R), [40_run_secure_panel_analysis.R](../R/40_run_secure_panel_analysis.R) sekä aiempien työvaiheiden skriptit kansioissa `R/10_table1/`, `R/15_table2/`, `R/20_table3/`, [K40_FI_KAAOS.R](../R/40_FI/K40_FI_KAAOS.R) ja [K41_FI22_FOF_models.R](../R/41_models/K41_FI22_FOF_models.R).

**Sitovat tulkinta- ja toistettavuusrajat:**

- Yllä oleva luettelo kuvaa vain tässä hakemistossa tällä hetkellä versioidut tiedostot; muiden työtilojen, aiempien analyysiajojen tai `DATA_ROOT`-ympäristön mahdollisten toteutusten olemassaoloa ei ole tässä dokumenttipäivityksessä tarkastettu, eikä niiden olemassaolosta tehdä poissulkevia väitteitä.
- Olemassa olevien luonnosskriptien sisäiset oletukset (kuten kiinteä paneelioffset kustannusmallissa tai aiemmat `K40`-/Fried-proxy-viittaukset) **eivät** lukitse AIM2:n lopullista SAPia, vaan skriptit mukautetaan myöhemmin vastaamaan hyväksyttyjä päätöksiä.
- Erikseen valtuutetuissa satunnaisuutta sisältävissä ajoissa (esim. bootstrap) käytetään kiinteää siemenlukua (`set.seed(20251124)`), `renv.lock`-ympäristöä ja manifestikirjausta.

---

## 7. Tulkinta, raportointi ja viisi avointa AIM2-päätöstä

### 7.1 Tulkinta- ja raportointiperiaatteet

- **Suureiden erillisyys raportoinnissa:** Palvelukäytön tiheydet (`rate/PY`) ja tapahtumamäärät pidetään erillään rahallisista suureista, ja rahallisissa tuloksissa yksilöidään aina: (i) käytetty rahakäsite (laskennallinen rahallinen arvo vs. toteutunut kustannus) ja hintavuosi, sekä (ii) onko kyse positiivisten kustannusten ehdollisesta keskiarvosta ($\mathbb{E}[\text{Cost} \mid \text{Cost} > 0]$), koko kohortin odotetusta kustannuksesta (`€`) vai henkilöaikaan suhteutetusta suureesta (`EUR/PY`).
- **Konservatiivinen assosiaatiokieli:** Tulokset esitetään havaittuina tai mallinnettuina yhteyksinä ilman kausaaliväitteitä. Jos luottamusväli kattaa nollavaikutuksen, tulosta kuvataan epätarkaksi väittämättä yhteyttä osoitetuksi tai poissuljetuksi.
- **Taulukko–teksti-ristiintarkistus:** Raportoitavat luvut ja yksiköt varmistetaan suoraan `n < 5` -suojatuista tulostaulukoista.

### 7.2 Viisi avointa AIM2-menetelmäpäätöstä ennen lopullista SAP-hyväksyntää (`OPEN`)

Ennen kuin tätä suunnitelmaa voidaan pitää hyväksyttynä toteutus-SAPina tai käynnistää lopullisia AIM2-malliajoja, seuraavat viisi menetelmäpäätöstä on ratkaistava ja dokumentoitava:

1. **Tutkimusasetelma ja seurantasäännöt (`OPEN`):** Valitaanko AIM2:n pääasetelmaksi henkilö–jakso-paneeli (ja mikä jakson pituus) vai koko seurantaikkunan henkilötason analyysi, sekä mitkä ovat AIM2:lle hyväksytyt indeksipäivä-, päättymispäivä-, kuolema-, poismuutto-, rekisteriaukko- ja seuranta-ajan mallinnussäännöt?
2. **Palvelukäytön ja kustannusten esittämisraja Osatyö I vs. Osatyö II (`OPEN`):** Miten tapaturmiin liittyvän palvelukäytön ja suorien kustannusten analyysit rajataan Osatöiden I ja II kesken päivitetyn tutkimussuunnitelman mukaisesti?
3. **AIM2:n frailty-spesifikaatio ja rakennepäällekkäisyyden ratkaisu (`OPEN`):** Mikä _deficit accumulation_ -mittari hyväksytään AIM2:een, ja miten ratkaistaan `FOF`:n (sekä mahdollisten aiempien kaatumisten ja sairastavuuden) mahdollinen sisältyminen vajeindeksin komponentteihin silloin, kun `FOF` on pääaltiste?
4. **Lopullinen kovariaattijoukko ja yhdysvaikutukset (`OPEN`):** Mitkä muuttujat kuuluvat hyväksyttyyn kovariaattivektoriin, ja sisällytetäänkö `FOF × frailty` (tai `FOF × period`) osaksi esispesifioitua analyysia?
5. **Vasteyksiköt, arvotusmenetelmä, hintavuosi ja nollakustannusmalli (`OPEN`):** Lukitaanko avohoidossa lähderivit vai uniikit käyntipäivät ja sairaalahoidossa jaksoaloitukset vai diagnoosiyhdistetyt päivät, perustuuko rahasuure toteutuneisiin yksilökustannuksiin vai yksikköhintapohjaiseen laskennalliseen arvoon (ja mihin hintavuoteen), ja mikä nollahavainnot huomioiva kustannusmalli valitaan päämalliksi?
