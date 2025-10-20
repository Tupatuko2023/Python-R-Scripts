<!-- File: docs/PHDSUM_efi_progress_2024_summary.md -->

# Finnish eFI Project — 2024 Research Progress Summary

## August 2024 draft; last updated 2024-12-20

## Background

From March–December 2024, within Tampere University’s Systems Biology of Aging
(BioAge) group, the project advanced a Finnish **electronic Frailty Index
(eFI)** to identify and stratify frailty using **EHR** data, combining
structured elements (e.g., ICD-10, labs) with unstructured clinical narratives
via **NLP**. Frailty reflects reduced physiological reserve and resilience and
is linked to mortality, cardiovascular outcomes, falls, and hospitalizations
([McIsaac, 2020][mcisaac2020]; [Clegg, 2013][clegg2013]; [Fried, 2021][fried2021]). Validated frameworks include the
**Fried Phenotype** ([Fried, 2001][fried2001]) and the **Rockwood Frailty
Index** ([Searle,2008][searle2008]). Evidence suggests early identification and
targeted intervention can mitigate risk ([Fried, 2021][fried2021]; [Kwak &
Thompson, 2021][kwak2021]).

In Finland, assessments often rely on manual checklists prone to variability,
underscoring the need for scalable, standardized tools ([Kerminen,
2016][kerminen2016]; [Kerminen, 2021][kerminen2021]; [Luo, 2022][luo2022]).
Frailty also affects some middle-aged adults ([Bai,2021][bai2021]; [Fan,
2020][fan2020]; [Hanlon, 2018][hanlon2018]). Standard structured-data screens
can miss nuanced indicators captured in free text; hence increased interest in
**AI/NLP** ([Clegg, 2016][clegg2016]; [Lekan, 2017][lekan2017]; [Tayefi,
2021][tayefi2021]; [Berman, 2021][berman2021]; [Chen, 2023][chen2023]; [Irving,
2021][irving2021],[Virtanen,2019][virtanen2019]), supporting an eFI that also
flags key modifiers like mobility limitations and fall risk ([Ambagtsheer,
2020][ambagtsheer2020]; [Mak, 2022][mak2022]; [Mak, 2023][mak2023]; [Remillard,
2019][remillard2019]; [Coventry, 2020][coventry2020]; [Niederstrasser,
2019][niederstrasser2019]; [Paulson & Lichtenberg, 2015][paulson2015]; [Puls,
2014][puls2014]).

## Objectives

**O1 — AI/NLP for frailty signals.** Design and validate methods to extract
frailty-related factors from Finnish EHR free text (NER, assertion/negation,
temporality).
**O2 — Data integration.** Combine structured (ICD-10, labs) and unstructured
signals to compute and validate a Finnish eFI.
**O3 — Longitudinal trajectories.** Analyze 12-year frailty progression and its
relationship to ADLs.
**O4 — ADLs & outcomes.** Quantify ADLs from free text, examine links to
hip-fracture recovery, and evaluate joint/predictive effects of ADLs and eFI on
rehabilitation outcomes over 12 years.

## Materials and Methods

### Data and setting

- **Cohort & period:** 166,147 patients aged 38–96; **2010–2022**.
- **Corpus:** ~**10.6M** free-text EHR entries from Central Finland Wellbeing
  Services County (**HYVÄKS**).
- **Computing:** Secure Azure ML workspace for NLP and modeling.
- **Framework:** Rockwood deficit-accumulation FI principles; continuous eFI
  with cut-offs for states. ([Searle,2008][searle2008]; [Blodgett, 2015][blodgett2015]).

### NLP pipeline and labeling

- **Annotation:** Category-specific text labeling with clinician/nurse input;
  mutually exclusive labeler/approver roles; second-labeler verification;
  Microsoft NER guidelines.
- **Evaluation:** Precision/recall/F1; comparison with ICD-10 signals for select
  deficits (e.g., falls, incontinence); Cox models for mortality (age/sex
  adjusted).

### Structured-data risk scores

- **Hospital Frailty Risk Score (HFRS):**
  - Data merging and ICD-10 processing
    ([`W7.Combine_data.ipynb`](https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/Electronic-Frailty-Index/W7.Combine_data.ipynb)).
  - Score calculation and quality checks
    ([`HFRS.2.Calculate_HFRS_Points.ipynb`](https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/Electronic-Frailty-Index/W8.HFRS.2.Calculate_HFRS_Points.ipynb)).
  - Descriptive stats and visualizations
    ([`HFRS.3…[Histogram-n-Boxplot.ipynb`](https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/Electronic-Frailty-Index/W9.HFRS.3.HFRS_Points_Histogram-n-Boxplot.ipynb)),
    risk classification plots, and unmatched-code audits
    ([`HFRS.4…Risk_Classification.ipynb`](https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/Electronic-Frailty-Index/W10.HFRS.4.HFRS_Scores_Risk_Classification.ipynb)).

- **Charlson Comorbidity Index (CCI):**
  - ICD-10 expansion & Charlson weights (per Kang et al., 2021)
    ([`W15.CCI.2.mo_CCI_weights.ipynb`](https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/Electronic-Frailty-Index/CCI/W15.CCI.2.mo_CCI_weights.ipynb)).
  - Standardization & cleaning
    ([`W16.CCI.3.procc_mo_CCI_weights.ipynb`](https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/Electronic-Frailty-Index/CCI/W16.CCI.3.procc_mo_CCI_weights.ipynb)),
    ([`W17.CCI.4.procc_CCI_data.ipynb`](https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/Electronic-Frailty-Index/CCI/W17.CCI.4.procc_CCI_data.ipynb)).
  - Score computation & longitudinal export
    ([`W18.CCI.5.calculates_moCCI_scores.ipynb`](https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/Electronic-Frailty-Index/CCI/W18.CCI.5.calculates_moCCI_scores.ipynb)).

### Data engineering and analyses

- **Overlap analysis:** Patient-ID Venn analysis across three datasets
  ([`Vennd_Overlap.ipynb`](https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/Electronic-Frailty-Index/W6.Vennd_Overlap.ipynb)).
- **Wide→Long transformations & longitudinal HFRS:**
  - ICD-10 truncation, pivoting, and summaries
    ([`W12.HFRS.6.Pivot_HFRS.ipynb`](https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/Electronic-Frailty-Index/W12.HFRS.6.Pivot_HFRS.ipynb)).
  - Patient-level HFRS reference column computation
    ([`W13.HFRS.7.Calculate_Pivot_HFRS.ipynb`](https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/Electronic-Frailty-Index/W13.HFRS.7.Calculate_Pivot_HFRS.ipynb)).
  - Distribution plots for HFRS and classifications
    ([`W14.HFRS.8.Plot_Pivot_HFRS.ipynb`](https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/Electronic-Frailty-Index/W14.HFRS.8.Plot_Pivot_HFRS.ipynb)).

- **Correlation (CCI↔HFRS):**
  - Overall and sex-stratified Pearson correlations; heatmaps, scatterplots;
    linear regression
    (([`W19.Correlation_Analysis_CCI_HFRS.R`](https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/Electronic-Frailty-Index/W19.Correlation_Analysis_CCI_HFRS.R))
    ,
    ([`W20.Correlation_Analysis_CCI_HFRS_Men_Women.R`](https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/Electronic-Frailty-Index/W20.Correlation_Analysis_CCI_HFRS_Men_Women.R))
    ,
    ([`W21.Pearson_Correlation_Coefficient.R`](https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/Electronic-Frailty-Index/W21.Pearson_Correlation_Coefficient.R))).
- **BMI pipeline (text + structured):**
  - Retrieval of BMI mentions (Finnish/English terms), computation from
    height/weight, value filtering, and cohort summaries; dataset merges and
    recomputation functions
     (([`W22.BMI.1.All_Records_BMI.ipynb`](https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/Electronic-Frailty-Index/BMI/W22.BMI.1.All_Records_BMI.ipynb))
     to
     ([`W27.BMI.6.Function_2Compute_Combine_BMI_Sum.ipynb`](https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/Electronic-Frailty-Index/BMI/W27.BMI.6.Function_2Compute_Combine_BMI_Sum.ipynb))).

## Results (2024 Progress)

- **Pipelines implemented.** End-to-end **HFRS** and **CCI**
  computation/visualization pipelines built and validated on integrated ICD-10
  datasets; longitudinal transformations support trajectory analyses.
- **Descriptive dashboards and figures prepared.**
  - Progress Gantt (project phases), dataset overlaps, and multiple baseline
    distributions (age groups, status, living vs. deceased, year of death).
  - Dental-care record counts per patient and other exploratory plots to guide
    variable selection for modeling.
- **NLP/NER labeling.** Targeted labeling sprints covered **mobility
  (04–06/2024)** and **bathing/dressing (09–10/2024)** domains for ADL
  extraction, supporting subsequent model fine-tuning.
- **Correlation analyses.** Initial **CCI–HFRS** associations computed overall
  and by sex; artifacts used to refine feature engineering and risk-group
  definitions for the integrated eFI.
- **BMI signal integration.** Consolidated BMI from text and structured fields,
  produced cohort-level summaries (min/max/mean/SD), and harmonized sources for
  downstream regression.

> Note: Formal eFI performance metrics (e.g., discrimination, calibration) are
> planned after finalizing ADL features and temporal splits; current 2024
> outputs emphasize data readiness, feature pipelines, and exploratory
> validations.

## Academic & Project Activities (2024)

- **Presentations:** Summary Toothdata (29 May), Labeling pipeline (19 Jun),
  Summer Workshop summary (6 Aug), Look-Back Windows (18 Nov), Longitudinal
  windows (20 Nov).
- **Grant applications:** Tampere University, Faculty of Social Sciences (EN);
  **Suomen kulttuurirahasto** (FI).

## Challenges and Lessons Learned

- Onboarding to new cloud tooling (Azure) without prior hands-on support,
  handling large/complex EHR datasets, and ensuring clear communication across
  mixed Finnish/English guidance were recurrent themes. (Context reflected in
  progress notes and pipeline iterations.)

### Abbreviations

ADL — Activities of Daily Living; CCI — Charlson Comorbidity Index; eFI —
electronic Frailty Index; EHR — Electronic Health Record; HFRS — Hospital
Frailty Risk Score; ICD-10 — International Classification of Diseases, 10th
Revision; NLP — Natural Language Processing; NER — Named Entity Recognition.

<!-- markdownlint-disable MD013 -->
## References

Ambagtsheer, R. C., Shafiabady, N., Dent, E., Seiboth, C., & Beilby, J. (2020).
The application of artificial intelligence (AI) techniques to identify frailty
within a residential aged care administrative data set. International Journal of
Medical Informatics, 136, 104094. [Ambagtsheer 2020][ambagtsheer2020]

Bai, G., Szwajda, A., Wang, Y., Li, X., Bower, H., Karlsson, I. K., Johansson,
B., Dahl Aslan, A. K., Pedersen, N. L., Hägg, S., & Jylhävä, J. (2021). Frailty
trajectories in three longitudinal studies of aging: Is the level or the rate of
change more predictive of mortality? Age and Ageing, 50(6), 2174–2182. [Bai
2021][bai2021]

Berman, A. N., Biery, D. W., Ginder, C., Hulme, O. L., Marcusa, D., Leiva, O.,
Wu, W. Y., Cardin, N., Hainer, J., Bhatt, D. L., Di Carli, M. F., Turchin, A., &
Blankstein, R. (2021). Natural language processing for the assessment of
cardiovascular disease comorbidities: The cardio-Canary comorbidity project.
Clinical Cardiology, 44(9), 1296–1304. [Berman 2021][berman2021]

Blodgett, J., Theou, O., Kirkland, S., Andreou, P., & Rockwood, K. (2015).
Frailty in NHANES: Comparing the frailty index and phenotype. Archives of
Gerontology and Geriatrics, 60(3), 464–470. [Blodgett 2015][blodgett2015]

Chen, J., Li, X., Aguilar, B. J., Shishova, E., Morin, P. J., Berlowitz, D.,
Miller, D. R., O’Connor, M. K., Nguyen, A. H., Zhang, R., Monfared, A. A. T.,
Zhang, Q., & Xia, W. (2023). Development and validation of a natural language
processing system that extracts cognitive test results from clinical notes.
Alzheimer’s & Dementia, 19(S18), e075381. [Chen 2023][chen2023]

Clegg, A., Bates, C., Young, J., Ryan, R., Nichols, L., Ann Teale, E., Mohammed,
M. A., Parry, J., & Marshall, T. (2016). Development and validation of an
electronic frailty index using routine primary care electronic health record
data. Age and Ageing, 45(3), 353–360. [Clegg 2016][clegg2016]

Clegg, A., Young, J., Iliffe, S., Rikkert, M. O., & Rockwood, K. (2013). Frailty
in elderly people. The Lancet, 381(9868), 752–762. [Clegg 2013][clegg2013]

Coventry, P. A., McMillan, D., Clegg, A., Brown, L., van der Feltz-Cornelis, C.,
Gilbody, S., & Ali, S. (2020). Frailty and depression predict instrumental
activities of daily living in older adults: A population-based longitudinal
study using the CARE75+ cohort. PLOS ONE, 15(12), e0243972. [Coventry
2020][coventry2020]

Fan, J., Yu, C., Guo, Y., Bian, Z., Sun, Z., Yang, L., Chen, Y., Du, H., Li, Z.,
Lei, Y., Sun, D., Clarke, R., Chen, J., Chen, Z., Lv, J., Li, L., & China
Kadoorie Biobank Collaborative Group. (2020). Frailty index and all-cause and
cause-specific mortality in Chinese adults: A prospective cohort study. The
Lancet Public Health, 5(12), e650–e660. [Fan 2020][fan2020]

Fried, L. P., Cohen, A. A., Xue, Q.-L., Walston, J., Bandeen-Roche, K., &
Varadhan, R. (2021). The physical frailty syndrome as a transition from
homeostatic symphony to cacophony. Nature Aging, 1(1), 36–46. [Fried
2021][fried2021]

Fried, L. P., Tangen, C. M., Walston, J., Newman, A. B., Hirsch, C., Gottdiener,
J., Seeman, T., Tracy, R., Kop, W. J., Burke, G., McBurnie, M. A., &
Cardiovascular Health Study Collaborative Research Group. (2001). Frailty in
older adults: Evidence for a phenotype. The Journals of Gerontology Series A,
56(3), M146–M156. [Fried 2001][fried2001]

Gilbert, T., Neuburger, J., Kraindler, J., Keeble, E., Smith, P., Ariti, C.,
Arora, S., Street, A., Parker, S., Roberts, H. C., Bardsley, M., & Conroy, S.
(2018). Development and validation of a Hospital Frailty Risk Score focusing on
older people in acute care settings using electronic hospital records: An
observational study. The Lancet, 391(10132), 1775–1782. [Gilbert
2018][gilbert2018]

Hanlon, P., Nicholl, B. I., Jani, B. D., Lee, D., McQueenie, R., & Mair, F. S.
(2018). Frailty and pre-frailty in middle-aged and older adults and its
association with multimorbidity and mortality: A prospective analysis of 493,737
UK Biobank participants. The Lancet Public Health, 3(7), e323–e332. [Hanlon
2018][hanlon2018]

Irving, J., Patel, R., Oliver, D., Colling, C., Pritchard, M., Broadbent, M.,
Baldwin, H., Stahl, D., Stewart, R., & Fusar-Poli, P. (2021). Using natural
language processing on electronic health records to enhance detection and
prediction of psychosis risk. Schizophrenia Bulletin, 47(2), 405–414. [Irving
2021][irving2021]

Kang, Y., Choi, H. Y., Kwon, Y. E., Shin, J. H., Won, E. M., Yang, K. H., Oh, H.
J., & Ryu, D.-R. (2021). Clinical outcomes among hemodialysis patients with
atrial fibrillation: A Korean nationwide population-based study. Kidney Research
and Clinical Practice, 40(1), 99–108. [Kang 2021][kang2021]

Kerminen, H. (2021). Geriatric Assessment in Clinical Practice: Current
Situation and Challenges in Implementation. Tampere University. [Kerminen 2021
thesis][kerminen2021]

Kerminen, H., Jämsen, E., Jäntti, P., Huhtala, H., Strandberg, T., & Valvanne,
J. (2016). How Finnish geriatricians perform comprehensive geriatric assessment
in clinical practice? European Geriatric Medicine, 7(5), 454–458. [Kerminen
2016][kerminen2016]

Korpi, T. (2025a). W1: Bar Plot Analysis of Case Distribution Per Patient.
GitHub. [Korpi 2025a][korpi2025a]
Korpi, T. (2025b). W2: Age Distribution Analysis by Group. GitHub. [Korpi
2025b][korpi2025b]
Korpi, T. (2025c). W3: Distribution of Patients’ Status by Group. GitHub. [Korpi
2025c][korpi2025c]
Korpi, T. (2025d). W4: Demographic Distribution of Living and Deceased. GitHub.
[Korpi 2025d][korpi2025d]
Korpi, T. (2025e). W5: Yearly Mortality Trends. GitHub. [Korpi
2025e][korpi2025e]
Korpi, T. (2025f). W6: Patient_ID Overlap Analysis (Venn). GitHub. [Korpi
2025f][korpi2025f]
Korpi, T. (2025g). W7: Combining and Reshaping Health Diagnoses Data. GitHub.
[Korpi 2025g][korpi2025g]
Korpi, T. (2025h). W8: HFRS Scoring in Python. GitHub. [Korpi 2025h][korpi2025h]
Korpi, T. (2025i). W9: Histogram and Boxplot of HFRS Scores. GitHub. [Korpi
2025i][korpi2025i]
Korpi, T. (2025j). W10: ICD-10–Based HFRS Score Calculation. GitHub. [Korpi
2025j][korpi2025j]
Korpi, T. (2025k). W12: Pivoting and Summarizing ICD-10 Diagnoses. GitHub.
[Korpi 2025k][korpi2025k]
Korpi, T. (2025l). W13: Calculating HFRS from ICD-10 Codes. GitHub. [Korpi
2025l][korpi2025l]
Korpi, T. (2025m). W14: Histogram of HFRS Scores per Patient. GitHub. [Korpi
2025m][korpi2025m]
Korpi, T. (2025n). W15: Modified Charlson Comorbidity Index Calculation. GitHub.
[Korpi 2025n][korpi2025n]
Korpi, T. (2025o). W16: Standardizing ICD-10 Codes in moCCI. GitHub. [Korpi
2025o][korpi2025o]
Korpi, T. (2025p). W17: Preprocessing and Truncating ICD-10 Codes. GitHub.
[Korpi 2025p][korpi2025p]
Korpi, T. (2025q). W18: moCCI Scores Using ICD-10 Codes. GitHub. [Korpi
2025q][korpi2025q]
Korpi, T. (2025r). W19: Correlation Analysis of CCI and HFRS (R). GitHub. [Korpi
2025r][korpi2025r]
Korpi, T. (2025s). W20: Correlation Analysis by Gender (R). GitHub. [Korpi
2025s][korpi2025s]
Korpi, T. (2025t). W21: Pearson Correlation CCI vs HFRS (R). GitHub. [Korpi
2025t][korpi2025t]
Korpi, T. (2025u). W22: Case-Insensitive Search for BMI. GitHub. [Korpi
2025u][korpi2025u]
Korpi, T. (2025v). W23: BMI Calculation from Height and Weight. GitHub. [Korpi
2025v][korpi2025v]
Korpi, T. (2025w). W24: Compute Cohort Summaries of BMI. GitHub. [Korpi
2025w][korpi2025w]
Korpi, T. (2025). W25: Extracting and Summarizing BMI Values from Text Data.
GitHub. [Korpi 2025][korpi2025]
Korpi, T. (2025x). W26: BMI Data Fusion and Cleanup. GitHub. [Korpi
2025x][korpi2025x]
Korpi, T. (2025y). W27: Cohort Summaries of Combined BMI Data. GitHub. [Korpi
2025y][korpi2025y]
Korpi, T. (2025z). W28: Logistic Regression on Mortality (BMI, CCI, HFRS).
GitHub. [Korpi 2025z][korpi2025z]
Korpi, T. (2025aa). W29: Logistic Regression on Mortality Using CCI and HFRS.
GitHub. [Korpi 2025aa][korpi2025aa]
Korpi, T. (2025ab). W30: Logistic Regression on Mortality Using CCI and HFRS
(R). GitHub. [Korpi 2025ab][korpi2025ab]
Korpi, T. (2025ac). W31: Logistic Regression for Mortality; Visualizations (R).
GitHub. [Korpi 2025ac][korpi2025ac]

Kwak, D., & Thompson, L. V. (2021). Frailty: Past, present, and future? Sports
Medicine and Health Science, 3(1), 1–10. [Kwak 2021][kwak2021]

Lekan, D. A., Wallace, D. C., McCoy, T. P., Hu, J., Silva, S. G., & Whitson, H.
E. (2017). Frailty assessment in hospitalized older adults using the electronic
health record. Biological Research for Nursing, 19(2), 213–228. [Lekan
2017][lekan2017]

Lin, J., Korpi, T., Kuukka, A., Tirkkonen, A., Kariluoto, A., Kaijansinkko, J.,
Satamo, M., Pajulammi, H., Haapanen, M. J., Häyrynen, S., Pursiainen, E.,
Ciovica, D., Bonsdorff, M. B. von, & Jylhävä, J. (2024). Identification of
health conditions in unstructured health records with deep learning-based NLP
(preprint). medRxiv. [Lin 2024][lin2024]

Luo, J., Liao, X., Zou, C., Zhao, Q., Yao, Y., Fang, X., & Spicer, J. (2022).
Identifying frail patients using EHRs in primary care: Current status and future
directions. Frontiers in Public Health, 10, 901068. [Luo 2022][luo2022]

Mak, J. K. L., Eriksdotter, M., Annetorp, M., Kuja-Halkola, R., Kananen, L.,
Boström, A.-M., Kivipelto, M., Metzner, C., Bäck Jerlardtz, V., Engström, M.,
Johnson, P., Lundberg, L. G., Åkesson, E., Sühl Öberg, C., Olsson, M.,
Cederholm, T., Hägg, S., Religa, D., & Jylhävä, J. (2023). Two years with
COVID-19: The eFI identifies high-risk patients in the Stockholm GeroCovid
Study. Gerontology, 69(4), 396–405. [Mak 2023][mak2023]

Mak, J. K. L., Hägg, S., Eriksdotter, M., Annetorp, M., Kuja-Halkola, R.,
Kananen, L., Boström, A.-M., Kivipelto, M., Metzner, C., Bäck Jerlardtz, V.,
Engström, M., Johnson, P., Lundberg, L. G., Åkesson, E., Sühl Öberg, C., Olsson,
M., Cederholm, T., Jylhävä, J., & Religa, D. (2022). Development of an
electronic frailty index for hospitalized older adults in Sweden. The Journals
of Gerontology Series A, 77(11), 2311–2319. [Mak 2022][mak2022]

McIsaac, D. I., MacDonald, D. B., & Aucoin, S. D. (2020). Frailty for
perioperative clinicians: A narrative review. Anesthesia and Analgesia, 130(6),
1450–1460. [McIsaac 2020][mcisaac2020]

Microsoft. (2023, December 19). How to label your data for Custom Named Entity
Recognition (NER). Microsoft Learn. [Microsoft Learn][microsoft2023]

Niederstrasser, N. G., Rogers, N. T., & Bandelow, S. (2019). Determinants of
frailty development and progression using a multidimensional frailty index:
Evidence from ELSA. PLOS ONE, 14(10), e0223799. [Niederstrasser
2019][niederstrasser2019]

Paulson, D., & Lichtenberg, P. A. (2015). The Paulson-Lichtenberg Frailty Index:
Evidence for a self-report measure of frailty. Aging & Mental Health, 19(10),
892–901. [Paulson 2015][paulson2015]

Puls, M., Sobisiak, B., Bleckmann, A., Jacobshagen, C., Danner, B. C., Hünlich,
M., Beißbarth, T., Schöndube, F., Hasenfuß, G., Seipelt, R., & Schillinger, W.
(2014). Impact of frailty on outcomes after TAVI: Risk assessment by Katz ADL.
EuroIntervention, 10(5), 609–619. [Puls 2014][puls2014]

Quan, H., Sundararajan, V., Halfon, P., Fong, A., Burnand, B., Luthi, J.-C.,
Saunders, L. D., Beck, C. A., Feasby, T. E., & Ghali, W. A. (2005). Coding
algorithms for defining comorbidities in ICD-9-CM and ICD-10 administrative
data. Medical Care, 43(11), 1130–1139. [Quan 2005][quan2005]

Remillard, E. T., Fausset, C. B., & Fain, W. B. (2019). Aging with long-term
mobility impairment: Maintaining ADLs via selection, optimization, and
compensation. The Gerontologist, 59(3), 559–569. [Remillard 2019][remillard2019]

Searle, S. D., Mitnitski, A., Gahbauer, E. A., Gill, T. M., & Rockwood, K.
(2008). A standard procedure for creating a frailty index. BMC Geriatrics, 8,
24. [Searle 2008][searle2008]

Tayefi, M., Ngo, P., Chomutare, T., Dalianis, H., Salvi, E., Budrionis, A., &
Godtliebsen, F. (2021). Challenges and opportunities beyond structured data in
analysis of electronic health records. WIREs Computational Statistics, 13(6),
e1549. [Tayefi 2021][tayefi2021]

Virtanen, A., Kanerva, J., Ilo, R., Luoma, J., Luotolahti, J., Salakoski, T.,
Ginter, F., & Pyysalo, S. (2019). Multilingual is not enough: BERT for Finnish.
arXiv. [Virtanen 2019][virtanen2019]

<!-- Link definitions -->
[ambagtsheer2020]: https://doi.org/10.1016/j.ijmedinf.2020.104094
[bai2021]: https://doi.org/10.1093/ageing/afab106
[berman2021]: https://doi.org/10.1002/clc.23687
[blodgett2015]: https://doi.org/10.1016/j.archger.2015.01.016
[chen2023]: https://doi.org/10.1002/alz.075381
[clegg2016]: https://doi.org/10.1093/ageing/afw039
[clegg2013]: https://doi.org/10.1016/S0140-6736(12)62167-9
[coventry2020]: https://doi.org/10.1371/journal.pone.0243972
[fan2020]: https://doi.org/10.1016/S2468-2667(20)30113-4
[fried2021]: https://doi.org/10.1038/s43587-020-00017-z
[fried2001]: https://doi.org/10.1093/gerona/56.3.m146
[gilbert2018]: https://doi.org/10.1016/S0140-6736(18)30668-8
[hanlon2018]: https://doi.org/10.1016/S2468-2667(18)30091-4
[irving2021]: https://doi.org/10.1093/schbul/sbaa126
[kang2021]: https://doi.org/10.23876/j.krcp.20.022
[kerminen2021]: https://trepo.tuni.fi/handle/10024/124920
[kerminen2016]: https://doi.org/10.1016/j.eurger.2016.06.006
[korpi2025a]:
    https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/[W1.Cases_per_Patient_Bar_Plot.R](https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/Electronic-Frailty-Index/W1.Cases_per_Patient_Bar_Plot.R)
[korpi2025b]:
    https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/[W2.Age_Distribution_by_Group_Plot.R](https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/Electronic-Frailty-Index/W2.Age_Distribution_by_Group_Plot.R)
[korpi2025c]:
    https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/W3.Distribution_of_Patients'[_Status.R](https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/Electronic-Frailty-Index/W3.Distribution_of_Patients'_Status.R)
[korpi2025d]:
    https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/demographics/[W4.Living_Deceased_Distribution.R](https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/Electronic-Frailty-Index/W4.Living_Deceased_Distribution.R)
[korpi2025e]:
    https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/demographics/[W5.Death_Year_Distribution.R](https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/Electronic-Frailty-Index/W5.Death_Year_Distribution.R)
[korpi2025f]:
    https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/[W6.Vennd_Overlap.ipynb](https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/Electronic-Frailty-Index/W6.Vennd_Overlap.ipynb)
[korpi2025g]:
    https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/[W7.Combine_data.ipynb](https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/Electronic-Frailty-Index/W7.Combine_data.ipynb)
[korpi2025h]:
    https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/HFRS/[W8.HFRS.2.Calculate_HFRS_Points.ipynb](https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/Electronic-Frailty-Index/W8.HFRS.2.Calculate_HFRS_Points.ipynb)
[korpi2025i]:
    https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/HFRS/[W9.HFRS.3.HFRS_Points_Histogram-n-Boxplot.ipynb](https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/Electronic-Frailty-Index/W9.HFRS.3.HFRS_Points_Histogram-n-Boxplot.ipynb)
[korpi2025j]:
    https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/HFRS/[W10.HFRS.4.HFRS_Scores_Risk_Classification.ipynb](https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/Electronic-Frailty-Index/W10.HFRS.4.HFRS_Scores_Risk_Classification.ipynb)
[korpi2025k]:
    https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/HFRS/[W12.HFRS.6.Pivot_HFRS.ipynb](https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/Electronic-Frailty-Index/W12.HFRS.6.Pivot_HFRS.ipynb)
[korpi2025l]:
    https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/HFRS/[W13.HFRS.7.Calculate_Pivot_HFRS.ipynb](https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/Electronic-Frailty-Index/W13.HFRS.7.Calculate_Pivot_HFRS.ipynb)
[korpi2025m]:
    https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/HFRS/[W14.HFRS.8.Plot_Pivot_HFRS.ipynb](https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/Electronic-Frailty-Index/W14.HFRS.8.Plot_Pivot_HFRS.ipynb)
[korpi2025n]:
    https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/CCI/[W15.CCI.2.mo_CCI_weights.ipynb](https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/Electronic-Frailty-Index/CCI/W15.CCI.2.mo_CCI_weights.ipynb)
[korpi2025o]:
    https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/CCI/[W16.CCI.3.procc_mo_CCI_weights.ipynb](https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/Electronic-Frailty-Index/CCI/W16.CCI.3.procc_mo_CCI_weights.ipynb)
[korpi2025p]:
    https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/CCI/[W17.CCI.4.procc_CCI_data.ipynb](https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/Electronic-Frailty-Index/CCI/W17.CCI.4.procc_CCI_data.ipynb)
[korpi2025q]:
    https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/CCI/[W18.CCI.5.Pivot_CCI_data.ipynb](https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/Electronic-Frailty-Index/CCI/W18.CCI.5.calculates_moCCI_scores.ipynb)
[korpi2025r]:
    https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/correlation_analysis/[W19.Correlation_Analysis_CCI_HFRS.R](https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/Electronic-Frailty-Index/W19.Correlation_Analysis_CCI_HFRS.R)
[korpi2025s]:
    https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/correlation_analysis/[W20.Correlation_Analysis_CCI_HFRS_Men_Women.R](https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/Electronic-Frailty-Index/W20.Correlation_Analysis_CCI_HFRS_Men_Women.R)
[korpi2025t]:
    https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/correlation_analysis/[W21.Pearson_Correlation_Coefficient.R](https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/Electronic-Frailty-Index/W21.Pearson_Correlation_Coefficient.R)
[korpi2025u]:
    https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/BMI/[W22.BMI.1.All_Records_BMI.ipynb](https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/Electronic-Frailty-Index/BMI/W22.BMI.1.All_Records_BMI.ipynb)
[korpi2025v]:
    https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/BMI/[W23.BMI.2.Calculate_BMI_Height_Weight.ipynb](https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/Electronic-Frailty-Index/BMI/W23.BMI.2.Calculate_BMI_Height_Weight.ipynb)
[korpi2025w]:
    https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/BMI/[W24.BMI.3.Function_2Compute_BMI_summaries.ipynb](https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/Electronic-Frailty-Index/BMI/W24.BMI.3.Function_2Compute_BMI_summaries.ipynb)
[korpi2025]:
    https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/BMI/[W25.BMI.4.Create_BMI_column.ipynb](https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/Electronic-Frailty-Index/BMI/W25.BMI.4.Create_BMI_column.ipynb)
[korpi2025x]:
    https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/BMI/[W26.BMI.5.Combine_BMI.ipynb](https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/Electronic-Frailty-Index/BMI/W26.BMI.5.Combine_BMI.ipynb)
[korpi2025y]:
    https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/BMI/[W27.BMI.6.Function_2Compute_Combine_BMI_Sum.ipynb](https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/Electronic-Frailty-Index/BMI/W27.BMI.6.Function_2Compute_Combine_BMI_Sum.ipynb)
[korpi2025z]:
    https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/logistic_regression/[W28.LRM.1.Mortality.BMI.CCI.HFRS.Adjusted.V1.ipynb](https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/Electronic-Frailty-Index/logistic_regression/W28.LRM.1.Mortality.BMI.CCI.HFRS.Adjusted.V1.ipynb)
[korpi2025aa]:
    https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/logistic_regression/[W29.LRM.2.Mortality.CCI.HFRS.Adjusted.V2.ipynb](https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/Electronic-Frailty-Index/logistic_regression/W29.LRM.2.Mortality.CCI.HFRS.Adjusted.V2.ipynb)
[korpi2025ab]:
    https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/logistic_regression/[W30.LRM.3.Mortality.CCI.HFRS.Adjusted.R](https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/Electronic-Frailty-Index/logistic_regression/W30.LRM.3.Mortality.CCI.HFRS.Adjusted.R)
[korpi2025ac]:
    https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/logistic_regression/[W31.LRM.4.Visualize.Model.R](https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/Electronic-Frailty-Index/logistic_regression/W31.LRM.4.Visualize.Model.R)
[kwak2021]: https://doi.org/10.1016/j.smhs.2020.11.005
[lekan2017]: https://doi.org/10.1177/1099800416679730
[lin2024]: https://doi.org/10.1101/2024.10.08.24315141
[luo2022]: https://doi.org/10.3389/fpubh.2022.901068
[mak2023]: https://doi.org/10.1159/000527206
[mak2022]: https://doi.org/10.1093/gerona/glac069
[mcisaac2020]: https://doi.org/10.1213/ANE.0000000000004602
[microsoft2023]:
    https://learn.microsoft.com/en-us/azure/ai-services/language-service/custom-named-entity-recognition/how-to/tag-data
[niederstrasser2019]: https://doi.org/10.1371/journal.pone.0223799
[paulson2015]: https://doi.org/10.1080/13607863.2014.986645
[puls2014]: https://doi.org/10.4244/EIJY14M08_03
[quan2005]: https://doi.org/10.1097/01.mlr.0000182534.19832.83
[remillard2019]: https://doi.org/10.1093/geront/gnx186
[searle2008]: https://doi.org/10.1186/1471-2318-8-24
[tayefi2021]: https://doi.org/10.1002/wics.1549
[virtanen2019]: https://doi.org/10.48550/arXiv.1912.07076
<!-- markdownlint-enable MD013 -->
