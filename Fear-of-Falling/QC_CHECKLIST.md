````markdown

# QC_CHECKLIST.md — FOF_status × time (baseline → 12m) mixed-malliputken pakolliset QC-tarkistukset

**Context:** This checklist supports the Official Analysis Plan: [docs/ANALYSIS_PLAN.md](docs/ANALYSIS_PLAN.md).

Tämä tarkistuslista määrittää pakolliset, auditointikelpoiset QC-askeleet ennen kuin ajetaan FOF_status × time -interaktiota arvioiva mixed model -workflow (lmer; random intercept (1 | id)) Composite_Z-muuttujalle long-muodossa (baseline ja 12m). Tarkistukset on tarkoitettu refaktoroinnin, debuggauksen ja pipeline-kovettamisen hyväksymiskriteereiksi FOF-alatutkimuksessa.



---



## Milloin QC ajetaan



## Ajo yhdell? komennolla (K18_QC)



Aja QC n?in (korvaa data-polku):



```bash

Rscript R-scripts/K18/K18_QC.V1_qc-run.R --data data/processed/analysis_long.csv --shape AUTO

```



QC-artefaktit kirjoitetaan polkuun `R-scripts/K18/outputs/K18_QC/qc/` ja

manifestiin lis?t?n yksi rivi per artefakti.





## Automatisoitu QC-runner (stop-the-line)



Aja skripti: `Rscript R-scripts/K18/K18_QC.V1_qc-run.R --data <path>`

(valinnainen: `--format long|wide|auto`, `--id-col`, `--time-col`).

Artefaktit tallentuvat polkuun `R-scripts/K18/outputs/K18_QC/qc/` ja

manifestiin lisataan rivi per artefakti.







Aja QC aina:

1) **Ennen mallinnusta** (ennen `analysis_mixed_workflow()` / `lmer()`): varmistetaan datan rakenne, koodaukset, puuttuvat ja perusjakaumat.

2) **Ennen raportointia**: varmistetaan, että raportoitavat n:t ja aikatasot vastaavat analyysidataa (ei “silent recoding”/droppeja).

3) **Refaktoroinnin / korjausten jälkeen**: jokaisen koodimuutoksen (data prep, pivot, recode, join) jälkeen QC uudelleen ja artefaktit talteen.



---



## Ydinmuuttujat ja odotettu muoto



### Vaatimus mixed-malliin (long)

Datan tulee olla **long**-muodossa siten, että jokainen rivi on yhden henkilön (`id`) yksi aikapiste (`time`).



**Pakolliset sarakkeet (minimi):**

- `id` (integer/character; yksilötunniste)

- `time` (factor tai numeerinen; **tasot baseline ja 12m** tai koodaus {0,1})

- `FOF_status` (0/1 tai 2-tasoinen factor; **ei hiljaista uudelleenkoodausta**)

- `Composite_Z` (numeric; fyysisen toimintakyvyn yhdistelmä-z)



### Jos data on wide

Jos saatavilla on wide-muotoisia sarakkeita (esim. `Composite_Z0`, `Composite_Z2` tms.), QC:n pitää joko:

- (A) varmistaa, että ne voidaan pivottaa longiksi ilman rivien häviämistä, tai

- (B) estää mallin ajo, kunnes long-data on tuotettu ja validoitu.



### Delta-muuttuja (jos käytössä)

Jos datasetissä on delta-muuttuja (kanoninen nimi tässä checklistissä: `Delta_Composite_Z`), sen tulee vastata **follow-up − baseline** toleranssilla.

**HUOM:** Jos delta on nimetty eri tavalla (esim. `delta_composite_z`), tee eksplisiittinen “mapping” ja dokumentoi se (TODO).



---



## Pakolliset QC-tarkistukset



> **Yleinen ajotapa**: jokainen tarkistus kirjoittaa artefaktin `R-scripts/<K_FOLDER>/outputs/<script_label>/qc/`-hakemistoon (tai `outputs/<script>/` jos ajetaan Kxx-skriptin sisällä). Älä kirjoita raakadatan päälle.

> **Privacy**: QC-artefaktit eivät saa sisältää osallistujatason rivejä (ei listoja id:istä). Tallenna vain aggregaattiyhteenvetoja.



### 1) Saraketyypit (types)



- **Check name:** Saraketyypit

- **What it verifies:** `id`, `time`, `FOF_status`, `Composite_Z` löytyvät ja ovat odotettua tyyppiä (ei list/complex; Composite_Z numeric).

- **How to run (base R):**

  ```r

  # Input (TODO polku / objekti)

  df <- read.csv("data/processed/analysis_long.csv")

  dir.create("R-scripts/<K_FOLDER>/outputs/<script_label>/qc", recursive = TRUE, showWarnings = FALSE)



  req <- c("id", "time", "FOF_status", "Composite_Z")

  missing_cols <- setdiff(req, names(df))



  types_df <- data.frame(

    variable = intersect(req, names(df)),

    class = sapply(df[intersect(req, names(df))], function(x) paste(class(x), collapse = "|")),

    stringsAsFactors = FALSE

  )



  status <- data.frame(

    check = "types",

    ok = (length(missing_cols) == 0),

    missing_cols = paste(missing_cols, collapse = ";"),

    stringsAsFactors = FALSE

  )



  write.csv(status,   "R-scripts/<K_FOLDER>/outputs/<script_label>/qc/qc_types_status.csv", row.names = FALSE)

  write.csv(types_df, "R-scripts/<K_FOLDER>/outputs/<script_label>/qc/qc_types.csv", row.names = FALSE)

````



* **Pass criteria:**



  * `qc_types_status.csv: ok == TRUE`

  * `Composite_Z` on numeric/integer (ei character)

  * `FOF_status` on integer/numeric tai 2-tasoinen factor (mapping dokumentoitu)

* **Fail action:** Korjaa rename/mapping ja/tai tyypitys (`as.numeric()`,

  `as.factor()`), älä arvaa koodauksia.

* **Artifact to save:**



  * `R-scripts/<K_FOLDER>/outputs/<script_label>/qc/qc_types_status.csv`

  * `R-scripts/<K_FOLDER>/outputs/<script_label>/qc/qc_types.csv`



---



### 2) ID-rakenne: (id, time) uniikkius + aikapeitto (ei osallistujatason listoja)



* **Check name:** ID-rakenne

* **What it verifies:** Long-datassa `(id, time)` on uniikki; id:llä on baseline

  ja 12m “ideaalisti”; duplikaatit ja epätäydet aikaparit raportoidaan

  aggregaattina.

* **How to run (base R):**



  ```r

  df <- read.csv("data/processed/analysis_long.csv")

  dir.create("R-scripts/<K_FOLDER>/outputs/<script_label>/qc", recursive = TRUE, showWarnings = FALSE)



  # Uniqueness of (id,time)

  key <- paste(df$id, df$time, sep="__")

  n_dup_keys <- sum(duplicated(key))



  # Coverage per id (distribution only; no id list)

  tab <- with(df, table(id, time))

  n_timepoints <- rowSums(tab > 0)

  coverage_dist <- as.data.frame(table(n_timepoints), stringsAsFactors = FALSE)

  names(coverage_dist) <- c("n_timepoints", "n_ids")

  coverage_dist$n_timepoints <- as.integer(as.character(coverage_dist$n_timepoints))



  out <- data.frame(

    check = "id_integrity",

    n_rows = nrow(df),

    n_unique_id = length(unique(df$id)),

    n_dup_(id_time) = n_dup_keys,

    stringsAsFactors = FALSE

  )



  write.csv(out,           "R-scripts/<K_FOLDER>/outputs/<script_label>/qc/qc_id_integrity_summary.csv", row.names = FALSE)

  write.csv(coverage_dist, "R-scripts/<K_FOLDER>/outputs/<script_label>/qc/qc_id_timepoint_coverage_dist.csv", row.names = FALSE)

  ```

* **Pass criteria:**



  * `n_dup_(id_time) == 0` (tai duplikaatit on korjattu deterministisesti ennen

    mallia)

  * `qc_id_timepoint_coverage_dist.csv`: valtaosalla id:istä `n_timepoints == 2`

    (baseline + 12m); jos ei, attritio dokumentoidaan (ei “hiljaista” droppeja).

* **Fail action:** Korjaa join/pivot niin, että yksi rivi per `(id, time)`;

  dokumentoi attritio ja varmista, ettei 12m katoa yhdistelyssä.

* **Artifact to save:**



  * `R-scripts/<K_FOLDER>/outputs/<script_label>/qc/qc_id_integrity_summary.csv`

  * `R-scripts/<K_FOLDER>/outputs/<script_label>/qc/qc_id_timepoint_coverage_dist.csv`



---



### 3) Puuttuvat tiedot: overall + FOF_status × time (pakollinen stratifiointi)



* **Check name:** Puuttuvat tiedot

* **What it verifies:** Puuttuvuus raportoidaan (a) ydinmuuttujissa overall ja

  (b) `Composite_Z` puuttuvuus `FOF_status × time` -tasolla, jotta

  systemaattinen puuttuvuus näkyy.

* **How to run (base R):**



  ```r

  df <- read.csv("data/processed/analysis_long.csv")

  dir.create("R-scripts/<K_FOLDER>/outputs/<script_label>/qc", recursive = TRUE, showWarnings = FALSE)



  req <- c("id", "time", "FOF_status", "Composite_Z")



  missing_overall <- data.frame(

    variable = req,

    n = sapply(df[req], length),

    n_missing = sapply(df[req], function(x) sum(is.na(x))),

    pct_missing = round(100 * sapply(df[req], function(x) sum(is.na(x))) / sapply(df[req], length), 1),

    stringsAsFactors = FALSE

  )



  # Stratified: Composite_Z missingness by FOF_status and time (aggregate only)

  # Use xtabs to avoid packages

  n_rows <- as.data.frame(with(df, table(FOF_status, time)), stringsAsFactors = FALSE)

  names(n_rows) <- c("FOF_status","time","n_rows")



  n_miss <- as.data.frame(with(df, table(FOF_status, time, is.na(Composite_Z))), stringsAsFactors = FALSE)

  names(n_miss) <- c("FOF_status","time","is_na_Composite_Z","n")

  n_miss <- n_miss[n_miss$is_na_Composite_Z == "TRUE", c("FOF_status","time","n_missing_Composite_Z")]



  merged <- merge(n_rows, n_miss, by=c("FOF_status","time"), all.x=TRUE)

  merged$n_missing_Composite_Z[is.na(merged$n_missing_Composite_Z)] <- 0

  merged$pct_missing_Composite_Z <- round(100 * merged$n_missing_Composite_Z / merged$n_rows, 1)



  write.csv(missing_overall, "R-scripts/<K_FOLDER>/outputs/<script_label>/qc/qc_missingness_overall.csv", row.names = FALSE)

  write.csv(merged,          "R-scripts/<K_FOLDER>/outputs/<script_label>/qc/qc_missingness_by_group_time.csv", row.names = FALSE)

  ```

* **Pass criteria:**



  * Artefaktit tuotettu; puuttuvuus ei ole “yllätys” (esim. 12m lähes tyhjä)

    ilman dokumentoitua syytä.

  * Jos 12m puuttuvuus eroaa selvästi FOF-ryhmien välillä: lisää

    analyysimuistiinpano mahdollisesta selection biasista (TODO).

* **Fail action:** Jäljitä puuttuvuus join/pivot -vaiheista; dokumentoi

  attritio; älä tee imputointia ilman erillistä päätöstä.

* **Artifact to save:**



  * `R-scripts/<K_FOLDER>/outputs/<script_label>/qc/qc_missingness_overall.csv`

  * `R-scripts/<K_FOLDER>/outputs/<script_label>/qc/qc_missingness_by_group_time.csv`



---



### 4) FOF_status koodaus + eksplisiittinen factor-labelointi



* **Check name:** FOF_status koodaus

* **What it verifies:** `FOF_status` sisältää vain {0,1} tai on 2-tasoinen

  factor; tasot raportoidaan; ei ylimääräisiä arvoja.

* **How to run (base R):**



  ```r

  df <- read.csv("data/processed/analysis_long.csv")

  dir.create("R-scripts/<K_FOLDER>/outputs/<script_label>/qc", recursive = TRUE, showWarnings = FALSE)



  # Levels/unique values

  vals <- sort(unique(df$FOF_status))

  out <- data.frame(

    check = "fof_status",

    observed_levels = paste(vals, collapse=";"),

    n_levels = length(vals),

    stringsAsFactors = FALSE

  )



  # Optional: strict {0,1} check (TODO jos factor/character käytössä)

  ok_strict <- all(vals %in% c(0,1,"0","1")) && length(vals) == 2

  out$ok_strict_0_1 <- ok_strict



  write.csv(out, "R-scripts/<K_FOLDER>/outputs/<script_label>/qc/qc_fof_status.csv", row.names = FALSE)

  ```

* **Pass criteria:** `n_levels == 2` ja (jos käytetään 0/1) `ok_strict_0_1 ==

  TRUE`, tai vaihtoehtoinen 2-tasoinen mapping on dokumentoitu eksplisiittisesti

  (TODO).

* **Fail action:** Korjaa recode eksplisiittisesti (ei “silent”); varmista, että

  analyysissa käytetty reference-taso on dokumentoitu.

* **Artifact to save:** `R-scripts/<K_FOLDER>/outputs/<script_label>/qc/qc_fof_status.csv`



---



### 5) Aikapisteet (time levels): baseline ja 12m



* **Check name:** Aikatasot

* **What it verifies:** `time` sisältää vain odotetut tasot (baseline ja 12m)

  tai koodaus {0,1}; ylimääräiset tasot flagataan.

* **How to run (base R):**



  ```r

  df <- read.csv("data/processed/analysis_long.csv")

  dir.create("R-scripts/<K_FOLDER>/outputs/<script_label>/qc", recursive = TRUE, showWarnings = FALSE)



  time_levels <- sort(unique(df$time))

  expected_time <- c("baseline", "12m")  # TODO: jos käytössä 0/1, muuta tähän



  status <- data.frame(

    check = "time_levels",

    observed = paste(time_levels, collapse=";"),

    expected = paste(expected_time, collapse=";"),

    ok = all(time_levels %in% expected_time) && all(expected_time %in% time_levels),

    stringsAsFactors = FALSE

  )



  write.csv(data.frame(time_level=time_levels), "R-scripts/<K_FOLDER>/outputs/<script_label>/qc/qc_time_levels.csv", row.names = FALSE)

  write.csv(status, "R-scripts/<K_FOLDER>/outputs/<script_label>/qc/qc_time_levels_status.csv", row.names = FALSE)

  ```

* **Pass criteria:** `qc_time_levels_status.csv: ok == TRUE` tai vaihtoehtoinen

  mapping baseline/12m ↔ {0,1} on dokumentoitu ja validoitu.

* **Fail action:** Korjaa `time` koodaus/pivot; estä mallin ajo kunnes

  time-tasot ovat oikein.

* **Artifact to save:**



  * `R-scripts/<K_FOLDER>/outputs/<script_label>/qc/qc_time_levels.csv`

  * `R-scripts/<K_FOLDER>/outputs/<script_label>/qc/qc_time_levels_status.csv`



---



### 6) Delta-tarkistus (jos Delta_Composite_Z käytössä)



* **Check name:** Delta-tarkistus (follow-up − baseline)

* **What it verifies:** Jos `Delta_Composite_Z` löytyy, se vastaa

  `Composite_Z(12m) − Composite_Z(baseline)` toleranssilla; tallennetaan vain

  aggregaattitulokset.

* **How to run (base R; aggregate only):**



  ```r

  df <- read.csv("data/processed/analysis_long.csv")

  dir.create("R-scripts/<K_FOLDER>/outputs/<script_label>/qc", recursive = TRUE, showWarnings = FALSE)



  delta_name <- "Delta_Composite_Z"

  baseline_label <- "baseline"  # TODO: tarkista data_dictionary.csv

  follow_label   <- "12m"       # TODO: tarkista data_dictionary.csv

  tol <- 1e-8



  if (!(delta_name %in% names(df))) {

    out <- data.frame(

      check="delta",

      applicable=FALSE,

      reason="Delta_Composite_Z not found",

      stringsAsFactors = FALSE

    )

    write.csv(out, "R-scripts/<K_FOLDER>/outputs/<script_label>/qc/qc_delta_check.csv", row.names = FALSE)

  } else {

    base <- df[df$time == baseline_label, c("id","Composite_Z")]

    foll <- df[df$time == follow_label,   c("id","Composite_Z")]

    names(base)[2] <- "Composite_Z_baseline"

    names(foll)[2] <- "Composite_Z_12m"



    w <- merge(base, foll, by="id", all=FALSE)

    delta_calc <- w$Composite_Z_12m - w$Composite_Z_baseline



    # reported delta aggregated per id internally, but output remains aggregate

    d <- aggregate(df[[delta_name]], by=list(id=df$id), FUN=function(x) x[which(!is.na(x))[1]])

    names(d)[2] <- "delta_reported"

    w2 <- merge(w, d, by="id", all.x=TRUE)



    diff <- w2$delta_reported - delta_calc

    ok_vec <- is.na(diff) | abs(diff) <= tol



    out <- data.frame(

      check="delta",

      applicable=TRUE,

      n_ids=nrow(w2),

      n_missing_delta_reported=sum(is.na(w2$delta_reported)),

      n_mismatch=sum(!ok_vec, na.rm=TRUE),

      max_abs_diff=max(abs(diff), na.rm=TRUE),

      tolerance=tol,

      stringsAsFactors = FALSE

    )



    write.csv(out, "R-scripts/<K_FOLDER>/outputs/<script_label>/qc/qc_delta_check.csv", row.names = FALSE)

  }

  ```

* **Pass criteria:** Jos applicable=TRUE, `n_mismatch == 0` (tai poikkeamien syy

  korjataan ennen mallia).

* **Fail action:** Korjaa delta-laskenta tai baseline/12m mapping; älä jatka

  ennen kuin mismatch=0.

* **Artifact to save:** `R-scripts/<K_FOLDER>/outputs/<script_label>/qc/qc_delta_check.csv`



---



### 7) Composite_Z jakauma ja arvojen järkevyys (range sanity)



* **Check name:** Composite_Z jakauma

* **What it verifies:** `Composite_Z` on finite; jakaumasta ja yhteenvedoista ei

  näy selviä koodausvirheitä; tuotetaan histogrammi + summary CSV.

* **How to run (base R):**



  ```r

  df <- read.csv("data/processed/analysis_long.csv")

  dir.create("R-scripts/<K_FOLDER>/outputs/<script_label>/qc", recursive = TRUE, showWarnings = FALSE)



  x <- df$Composite_Z



  summary_df <- data.frame(

    n = length(x),

    n_missing = sum(is.na(x)),

    n_nonfinite = sum(!is.finite(x), na.rm = TRUE),

    mean = mean(x, na.rm=TRUE),

    sd = sd(x, na.rm=TRUE),

    q01 = as.numeric(quantile(x, 0.01, na.rm=TRUE)),

    q05 = as.numeric(quantile(x, 0.05, na.rm=TRUE)),

    q50 = as.numeric(quantile(x, 0.50, na.rm=TRUE)),

    q95 = as.numeric(quantile(x, 0.95, na.rm=TRUE)),

    q99 = as.numeric(quantile(x, 0.99, na.rm=TRUE)),

    stringsAsFactors = FALSE

  )



  write.csv(summary_df, "R-scripts/<K_FOLDER>/outputs/<script_label>/qc/qc_composite_z_summary.csv", row.names = FALSE)



  png("R-scripts/<K_FOLDER>/outputs/<script_label>/qc/qc_composite_z_distribution.png", width=1200, height=900)

  hist(x, main="Composite_Z Distribution", xlab="Composite_Z")

  dev.off()

  ```

* **Pass criteria:** `n_nonfinite == 0`; histogrammi ja kvantiilit eivät viittaa

  selkeään väärään skaalaan (TODO tarvittaessa äärikynnykset).

* **Fail action:** Tarkista standardointi, yksikkövirheet ja laskennan

  välivaiheet (ei yksilötason listoja QC-outputtiin).

* **Artifact to save:**



  * `R-scripts/<K_FOLDER>/outputs/<script_label>/qc/qc_composite_z_summary.csv`

  * `R-scripts/<K_FOLDER>/outputs/<script_label>/qc/qc_composite_z_distribution.png`



---



### 8) “Silent filtering” -vahti (rivi- ja id-määrät per pipeline-vaihe)



* **Check name:** Rivimäärä & id-vahti

* **What it verifies:** Data prep -vaiheet eivät pudota havaintoja/id:itä

  huomaamatta; kirjataan aggregaattina n_rows ja n_unique_id per vaihe.

* **How to run (base R; lisää pipelineen jokaisen päävaiheen jälkeen):**



  ```r

  dir.create("R-scripts/<K_FOLDER>/outputs/<script_label>/qc", recursive = TRUE, showWarnings = FALSE)



  qc_stamp <- function(df, step_name, out_path="R-scripts/<K_FOLDER>/outputs/<script_label>/qc/qc_row_id_watch.csv") {

    row <- data.frame(

      step = step_name,

      n_rows = nrow(df),

      n_unique_id = length(unique(df$id)),

      n_missing_Composite_Z = sum(is.na(df$Composite_Z)),

      stringsAsFactors = FALSE

    )

    if (!file.exists(out_path)) write.csv(row, out_path, row.names = FALSE)

    else write.table(row, out_path, sep=",", col.names=FALSE, row.names=FALSE, append=TRUE)

  }



  # Example usage:

  # qc_stamp(df_raw,  "01_raw_loaded")

  # qc_stamp(df_long, "02_long_created")

  # qc_stamp(df_final,"03_analysis_ready")

  ```

* **Pass criteria:** Ei selittämättömiä suuria hyppyjä `n_rows` / `n_unique_id`

  -arvoissa.

* **Fail action:** Jäljitä suodatus/join/pivot ja tee eksplisiittinen

  dokumentaatio (miksi rivejä putosi).

* **Artifact to save:** `R-scripts/<K_FOLDER>/outputs/<script_label>/qc/qc_row_id_watch.csv`



---



## Pakolliset QC-artifactit



Oletuspolku: `R-scripts/<K_FOLDER>/outputs/<script_label>/qc/` (jos QC ajetaan Kxx-skriptin sisällä, käytä

ensisijaisesti `outputs/<Kxx>/qc_*.csv` ja peilaa tarvittaessa `R-scripts/<K_FOLDER>/outputs/<script_label>/qc/`).



**Pakolliset (minimi):**



* `R-scripts/<K_FOLDER>/outputs/<script_label>/qc/qc_types_status.csv`

* `R-scripts/<K_FOLDER>/outputs/<script_label>/qc/qc_types.csv`

* `R-scripts/<K_FOLDER>/outputs/<script_label>/qc/qc_id_integrity_summary.csv`

* `R-scripts/<K_FOLDER>/outputs/<script_label>/qc/qc_id_timepoint_coverage_dist.csv`

* `R-scripts/<K_FOLDER>/outputs/<script_label>/qc/qc_missingness_overall.csv`

* `R-scripts/<K_FOLDER>/outputs/<script_label>/qc/qc_missingness_by_group_time.csv`

* `R-scripts/<K_FOLDER>/outputs/<script_label>/qc/qc_fof_status.csv`

* `R-scripts/<K_FOLDER>/outputs/<script_label>/qc/qc_time_levels.csv`

* `R-scripts/<K_FOLDER>/outputs/<script_label>/qc/qc_time_levels_status.csv`

* `R-scripts/<K_FOLDER>/outputs/<script_label>/qc/qc_composite_z_summary.csv`

* `R-scripts/<K_FOLDER>/outputs/<script_label>/qc/qc_composite_z_distribution.png`

* `R-scripts/<K_FOLDER>/outputs/<script_label>/qc/qc_delta_check.csv` *(vain jos `Delta_Composite_Z` on olemassa)*

* `R-scripts/<K_FOLDER>/outputs/<script_label>/qc/qc_row_id_watch.csv` *(jos pipeline tukee vaihelogia)*



**Manifest (jos putki vaatii):**



* `manifest/manifest.csv` päivitetään projektisäännön mukaan (TODO): lisää

  rivi per QC-ajokerta (script, timestamp, artefaktit).



---



## Failure handling



Kun mikä tahansa pakollinen check failaa:



1. **Stop-the-line:** älä aja `analysis_mixed_workflow()` / `lmer()` ennen

   korjausta.

2. **Nimeä vika:** viittaa suoraan failanneeseen artefaktiin (esim.

   `qc_time_levels_status.csv: ok=FALSE`).

3. **Korjaa deterministisesti:** tee eksplisiittinen mapping/rename/pivot/recode

   (ei “guessing”, ei automaattista factor reorderia).

4. **Aja QC uudelleen:** varmista, että fail→pass ja että `qc_row_id_watch.csv`

   ei osoita selittämättömiä pudotuksia.

5. **Kirjaa muutos:** dokumentoi tehdyt päätökset (commit/manifest/muistio) ja

   linkitä QC-artefakteihin.



---

## Yleiset QC-periaatteet

1. Always verify data before analysis:

   - Check variable types, missingness, distributions.

   - Validate key assumptions (e.g., coding, ranges).

2. Do not guess variable meanings or units.

   If unclear: ask for (a) data_dictionary.csv or (b) `names(df)` + `glimpse(df)` + a 10-row sample.

3. Every code change must be:

   - Minimal and reversible

   - Logged (what/why)

   - Proposed as a diff-style patch when possible

4. Reproducibility is mandatory:

5. - Use `renv` (lock package versions)

   - Use `set.seed(20251124)` where randomness exists (bootstrap, MI, resampling)

   - Save `sessionInfo()` (or `renv::diagnostics()`) into `manifest/`

   - 5. Output discipline:

   - All tables/figures go to `outputs/<script>/...`

   - Always write one `manifest/manifest.csv` row per output artifact

     (file, date, script, git hash if available)

## PROJECT GOAL

Refactor and stabilize R scripts K11.R–K16.R and run a reproducible analysis to identify which factors

(FOF / age / FOF_status, etc.) are associated with 12-month change in physical performance.

- Primary outcome: `Delta_Composite_Z` (12 months intervention change)

- Alternative outcome (long format): `Composite_Z` with `time` factor/continuous

## DATA ASSUMPTIONS (MUST VERIFY)

We may have either:

A) Wide (baseline + 12 months)

- Composite_Z0, Composite_Z2 (or similar)

- Delta_Composite_Z = Composite_Z2 - Composite_Z0

B) Long (repeated measures)

- id

- time (baseline/12m tai 0/1, ks. data_dictionary.csv)

- Composite_Z

FOF variables:

- `FOF` and/or `FOF_status` (0/1)

- `FOF_status_f = factor(FOF_status, levels = c(0, 1), labels = c("Ei FOF", "FOF"))`

Minimal required columns to proceed (pick A or B):

- ID, age, sex, BMI (if used), FOF_status (0/1), baseline composite, follow-up composite

  OR time + Composite_Z.

## REPO STRUCTURE (RECOMMENDED)

- data/

  - raw/ (immutable)

  - processed/ (derived)

- R/

  - functions/ (helpers; e.g., io, checks, modeling)

  - pipeline/ (import -> clean -> model -> report)

- R-scripts/

  - K11/ K12/ ... K16/

    - script.R

    - outputs/

      - qc/ (QC artifacts)

      - figures/

      - tables/

    - manifest/ (sessionInfo, manifest.csv)

    - logs/ (script logs)

    - README.md (script purpose, inputs, outputs)

    - run_analysis.R (main script to run)

    - requirements.R (package setup)

    - data_inputs.R (data loading and preprocessing)

    - analysis_mixed_workflow.R (modeling functions)

    - report_generation.R (reporting functions)

    - tests/ (unit tests for functions)

    - docs/ (additional documentation)

    - utils/ (utility scripts)

    - config/ (configuration files)

    - references/ (reference materials)

    - templates/ (report templates)

- reports/

  - paper/ (Rmd / Quarto)

- tests/ (integration tests, end-to-end tests)

- manifest/

  - manifest.csv

```  - sessionInfo.txt

  - renv.lock

