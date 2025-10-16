<!-- File: docs/PHDSUM_efi_progress_2024_summary.md -->

# Finnish eFI Project — 2024 Research Progress Summary

_August 2024 draft; last updated 2024-12-20_

## Background

From March–December 2024, within Tampere University’s Systems Biology of Aging (BioAge) group, the project advanced a Finnish **electronic Frailty Index (eFI)** to identify and stratify frailty using **EHR** data, combining structured elements (e.g., ICD-10, labs) with unstructured clinical narratives via **NLP**. Frailty reflects reduced physiological reserve and resilience and is linked to mortality, cardiovascular outcomes, falls, and hospitalizations (McIsaac, 2020; Clegg, 2013; Fried, 2021). Validated frameworks include the **Fried Phenotype** (Fried, 2001) and the **Rockwood Frailty Index** (Searle, 2008). Evidence suggests early identification and targeted intervention can mitigate risk (Fried, 2021; Kwak & Thompson, 2021).

In Finland, assessments often rely on manual checklists prone to variability, underscoring the need for scalable, standardized tools (Kerminen, 2016; Kerminen, 2021; Luo, 2022). Frailty also affects some middle-aged adults (Bai, 2021; Fan, 2020; Hanlon, 2018). Standard structured-data screens can miss nuanced indicators captured in free text; hence increased interest in **AI/NLP** (Clegg, 2016; Lekan, 2017; Tayefi, 2021; Berman, 2021; Chen, 2023; Irving, 2021). Finnish **FinBERT** enables high-quality text processing (Virtanen, 2019), supporting an eFI that also flags key modifiers like mobility limitations and fall risk (Ambagtsheer, 2020; Mak, 2022; Mak, 2023; Remillard, 2019; Coventry, 2020; Niederstrasser, 2019; Paulson & Lichtenberg, 2015; Puls, 2014). 

## Objectives

**O1 — AI/NLP for frailty signals.** Design and validate methods to extract frailty-related factors from Finnish EHR free text (NER, assertion/negation, temporality).  
**O2 — Data integration.** Combine structured (ICD-10, labs) and unstructured signals to compute and validate a Finnish eFI.  
**O3 — Longitudinal trajectories.** Analyze 12-year frailty progression and its relationship to ADLs.  
**O4 — ADLs & outcomes.** Quantify ADLs from free text, examine links to hip-fracture recovery, and evaluate joint/predictive effects of ADLs and eFI on rehabilitation outcomes over 12 years. 

## Materials and Methods

### Data and setting

- **Cohort & period:** 166,147 patients aged 38–96; **2010–2022**.  
- **Corpus:** ~**10.6M** free-text EHR entries from Central Finland Wellbeing Services County (**HYVÄKS**).  
- **Computing:** Secure Azure ML workspace for NLP and modeling.  
- **Framework:** Rockwood deficit-accumulation FI principles; continuous eFI with cut-offs for states. (Searle, 2008; Blodgett, 2015). 
  
### NLP pipeline and labeling

- **Annotation:** Category-specific text labeling with clinician/nurse input; mutually exclusive labeler/approver roles; second-labeler verification; Microsoft NER guidelines.  
- **Evaluation:** Precision/recall/F1; comparison with ICD-10 signals for select deficits (e.g., falls, incontinence); Cox models for mortality (age/sex adjusted). 

### Structured-data risk scores

- **Hospital Frailty Risk Score (HFRS):**  
  - Data merging and ICD-10 processing (`W7.Combine_data.ipynb`).  
  - Score calculation and quality checks (`HFRS.2.Calculate_HFRS_Points.ipynb`).  
  - Descriptive stats and visualizations (`HFRS.3…Histogram-n-Boxplot.ipynb`), risk classification plots, and unmatched-code audits (`HFRS.4…Risk_Classification.ipynb`). 
  
- **Charlson Comorbidity Index (CCI):**  
  - ICD-10 expansion & Charlson weights (per Kang et al., 2021) (`W15.CCI.2.mo_CCI_weights.ipynb`).  
  - Standardization & cleaning (`W16…procc_mo_CCI_weights.ipynb`, `W17…procc_CCI_data.ipynb`).  
  - Score computation & longitudinal export (`W18…calculates_moCCI_scores.ipynb`). 

### Data engineering and analyses

- **Overlap analysis:** Patient-ID Venn analysis across three datasets (`Vennd_Overlap.ipynb`). 
- **Wide→Long transformations & longitudinal HFRS:**  
  - ICD-10 truncation, pivoting, and summaries (`W12.HFRS.6.Pivot_HFRS.ipynb`).  
  - Patient-level HFRS reference column computation (`W13.HFRS.7.Calculate_Pivot_HFRS.ipynb`).  
  - Distribution plots for HFRS and classifications (`W14.HFRS.8.Plot_Pivot_HFRS.ipynb`). 
  
- **Correlation (CCI↔HFRS):**  
  - Overall and sex-stratified Pearson correlations; heatmaps, scatterplots; linear regression (`W19…`, `W20…`, `W21…`). 
- **BMI pipeline (text + structured):**  
  - Retrieval of BMI mentions (Finnish/English terms), computation from height/weight, value filtering, and cohort summaries; dataset merges and recomputation functions (`W22…` to `W27…`). 

## Results (2024 Progress)

- **Pipelines implemented.** End-to-end **HFRS** and **CCI** computation/visualization pipelines built and validated on integrated ICD-10 datasets; longitudinal transformations support trajectory analyses. 
- **Descriptive dashboards and figures prepared.**  
  - Progress Gantt (project phases), dataset overlaps, and multiple baseline distributions (age groups, status, living vs. deceased, year of death).  
  - Dental-care record counts per patient and other exploratory plots to guide variable selection for modeling. 
- **NLP/NER labeling.** Targeted labeling sprints covered **mobility (04–06/2024)** and **bathing/dressing (09–10/2024)** domains for ADL extraction, supporting subsequent model fine-tuning. 
- **Correlation analyses.** Initial **CCI–HFRS** associations computed overall and by sex; artifacts used to refine feature engineering and risk-group definitions for the integrated eFI. 
- **BMI signal integration.** Consolidated BMI from text and structured fields, produced cohort-level summaries (min/max/mean/SD), and harmonized sources for downstream regression. 

> Note: Formal eFI performance metrics (e.g., discrimination, calibration) are planned after finalizing ADL features and temporal splits; current 2024 outputs emphasize data readiness, feature pipelines, and exploratory validations. 

## Academic & Project Activities (2024)

- **Presentations:** Summary Toothdata (29 May), Labeling pipeline (19 Jun), Summer Workshop summary (6 Aug), Look-Back Windows (18 Nov), Longitudinal windows (20 Nov). 
-   
- **Grant applications:** Tampere University, Faculty of Social Sciences (EN); **Suomen kulttuurirahasto** (FI). 

## Challenges and Lessons Learned

- Onboarding to new cloud tooling (Azure) without prior hands-on support, handling large/complex EHR datasets, and ensuring clear communication across mixed Finnish/English guidance were recurrent themes. (Context reflected in progress notes and pipeline iterations.) 

### Abbreviations

ADL — Activities of Daily Living; CCI — Charlson Comorbidity Index; eFI — electronic Frailty Index; EHR — Electronic Health Record; HFRS — Hospital Frailty Risk Score; ICD-10 — International Classification of Diseases, 10th Revision; NLP — Natural Language Processing; NER — Named Entity Recognition.

## References

Ambagtsheer, R. C., Shafiabady, N., Dent, E., Seiboth, C., & Beilby, J. (2020). The application of artificial intelligence (AI) techniques to identify frailty within a residential aged care administrative data set. International Journal of Medical Informatics, 136, 104094. https://doi.org/10.1016/j.ijmedinf.2020.104094
Bai, G., Szwajda, A., Wang, Y., Li, X., Bower, H., Karlsson, I. K., Johansson, B., Dahl Aslan, A. K., Pedersen, N. L., Hägg, S., & Jylhävä, J. (2021). Frailty trajectories in three longitudinal studies of aging: Is the level or the rate of change more predictive of mortality? Age and Ageing, 50(6), 2174–2182. https://doi.org/10.1093/ageing/afab106
Berman, A. N., Biery, D. W., Ginder, C., Hulme, O. L., Marcusa, D., Leiva, O., Wu, W. Y., Cardin, N., Hainer, J., Bhatt, D. L., Di Carli, M. F., Turchin, A., & Blankstein, R. (2021). Natural language processing for the assessment of cardiovascular disease comorbidities: The cardio-Canary comorbidity project. Clinical Cardiology, 44(9), 1296–1304. https://doi.org/10.1002/clc.23687
Blodgett, J., Theou, O., Kirkland, S., Andreou, P., & Rockwood, K. (2015). Frailty in NHANES: Comparing the frailty index and phenotype. Archives of Gerontology and Geriatrics, 60(3), 464–470. https://doi.org/10.1016/j.archger.2015.01.016
Chen, J., Li, X., Aguilar, B. J., Shishova, E., Morin, P. J., Berlowitz, D., Miller, D. R., O’Connor, M. K., Nguyen, A. H., Zhang, R., Monfared, A. A. T., Zhang, Q., & Xia, W. (2023). Development and validation of a natural language processing system that extracts cognitive test results from clinical notes. Alzheimer’s & Dementia, 19(S18), e075381. https://doi.org/10.1002/alz.075381
Clegg, A., Bates, C., Young, J., Ryan, R., Nichols, L., Ann Teale, E., Mohammed, M. A., Parry, J., & Marshall, T. (2016). Development and validation of an electronic frailty index using routine primary care electronic health record data. Age and Ageing, 45(3), 353–360. https://doi.org/10.1093/ageing/afw039
Clegg, A., Young, J., Iliffe, S., Rikkert, M. O., & Rockwood, K. (2013). Frailty in elderly people. Lancet (London, England), 381(9868), 752–762. https://doi.org/10.1016/S0140-6736(12)62167-9
Coventry, P. A., McMillan, D., Clegg, A., Brown, L., van der Feltz-Cornelis, C., Gilbody, S., & Ali, S. (2020). Frailty and depression predict instrumental activities of daily living in older adults: A population-based longitudinal study using the CARE75+ cohort. PloS One, 15(12), e0243972. https://doi.org/10.1371/journal.pone.0243972
Fan, J., Yu, C., Guo, Y., Bian, Z., Sun, Z., Yang, L., Chen, Y., Du, H., Li, Z., Lei, Y., Sun, D., Clarke, R., Chen, J., Chen, Z., Lv, J., Li, L., & China Kadoorie Biobank Collaborative Group. (2020). Frailty index and all-cause and cause-specific mortality in Chinese adults: A prospective cohort study. The Lancet. Public Health, 5(12), e650–e660. https://doi.org/10.1016/S2468-2667(20)30113-4
Fried, L. P., Cohen, A. A., Xue, Q.-L., Walston, J., Bandeen-Roche, K., & Varadhan, R. (2021). The physical frailty syndrome as a transition from homeostatic symphony to cacophony. Nature Aging, 1(1), 36–46. https://doi.org/10.1038/s43587-020-00017-z
Fried, L. P., Tangen, C. M., Walston, J., Newman, A. B., Hirsch, C., Gottdiener, J., Seeman, T., Tracy, R., Kop, W. J., Burke, G., McBurnie, M. A., & Cardiovascular Health Study Collaborative Research Group. (2001). Frailty in older adults: Evidence for a phenotype. The Journals of Gerontology. Series A, Biological Sciences and Medical Sciences, 56(3), M146-156. https://doi.org/10.1093/gerona/56.3.m146
Gilbert, T., Neuburger, J., Kraindler, J., Keeble, E., Smith, P., Ariti, C., Arora, S., Street, A., Parker, S., Roberts, H. C., Bardsley, M., & Conroy, S. (2018). Development and validation of a Hospital Frailty Risk Score focusing on older people in acute care settings using electronic hospital records: An observational study. Lancet (London, England), 391(10132), 1775–1782. https://doi.org/10.1016/S0140-6736(18)30668-8
Hanlon, P., Nicholl, B. I., Jani, B. D., Lee, D., McQueenie, R., & Mair, F. S. (2018). Frailty and pre-frailty in middle-aged and older adults and its association with multimorbidity and mortality: A prospective analysis of 493 737 UK Biobank participants. The Lancet. Public Health, 3(7), e323–e332. https://doi.org/10.1016/S2468-2667(18)30091-4
Irving, J., Patel, R., Oliver, D., Colling, C., Pritchard, M., Broadbent, M., Baldwin, H., Stahl, D., Stewart, R., & Fusar-Poli, P. (2021). Using Natural Language Processing on Electronic Health Records to Enhance Detection and Prediction of Psychosis Risk. Schizophrenia Bulletin, 47(2), 405–414. https://doi.org/10.1093/schbul/sbaa126
Kang, Y., Choi, H. Y., Kwon, Y. E., Shin, J. H., Won, E. M., Yang, K. H., Oh, H. J., & Ryu, D.-R. (2021). Clinical outcomes among hemodialysis patients with atrial fibrillation: A Korean nationwide population-based study. Kidney Research and Clinical Practice, 40(1), 99–108. https://doi.org/10.23876/j.krcp.20.022
Kerminen, H. (2021). Geriatric Assessment in Clinical Practice: Current Situation and Challenges in Implementation. Tampere University. https://trepo.tuni.fi/handle/10024/124920
Kerminen, H., Jämsen, E., Jäntti, P., Huhtala, H., Strandberg, T., & Valvanne, J. (2016). How Finnish geriatricians perform comprehensive geriatric assessment in clinical practice? European Geriatric Medicine, 7(5), 454–458. https://doi.org/10.1016/j.eurger.2016.06.006
Korpi, T. (2025a). W1: Bar Plot Analysis of Case Distribution Per Patient: Data Visualization and Statistical Summary. GitHub. https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/W1.Cases_per_Patient_Bar_Plot.R
Korpi, T. (2025b). W2: Age Distribution Analysis by Group: A Statistical Visualization Using Bar Plots. GitHub. https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/W2.Age_Distribution_by_Group_Plot.R
Korpi, T. (2025c). W3: Distribution of Patients’ Status by Group: A Visual and Statistical Analysis Using Bar Charts. GitHub. https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/W3.Distribution_of_Patients'_Status.R
Korpi, T. (2025d). W4: Demographic Distribution of Living and Deceased Individuals: A Statistical Visualization Using Bar Charts. GitHub. https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/demographics/W4.Living_Deceased_Distribution.R
Korpi, T. (2025e). W5: Yearly Mortality Trends: Statistical Analysis and Visualization of Death Year Distribution. GitHub. https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/demographics/W5.Death_Year_Distribution.R
Korpi, T. (2025f). W6: Patient_ID Overlap Analysis and Visualization Using Venn Diagrams in Python. GitHub. https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/W6.Vennd_Overlap.ipynb
Korpi, T. (2025g). W7: Combining and Reshaping Health Diagnoses Data: A Python Jupyter Notebook for Merging and Cleaning. GitHub. https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/W7.Combine_data.ipynb
Korpi, T. (2025h). W8: Comprehensive Patient Data Integration and HFRS Scoring in Python. GitHub. https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/HFRS/W8.HFRS.2.Calculate_HFRS_Points.ipynb
Korpi, T. (2025i). W9: Histogram and Boxplot Visualization of HFRS Scores: A Jupyter Notebook for Distribution and Outlier Analysis. GitHub. https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/HFRS/W9.HFRS.3.HFRS_Points_Histogram-n-Boxplot.ipynb
Korpi, T. (2025j). W10: ICD-10–Based HFRS Score Calculation and Risk Classification Visualization. GitHub. https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/HFRS/W10.HFRS.4.HFRS_Scores_Risk_Classification.ipynb
Korpi, T. (2025k). W12: Pivoting and Summarizing ICD-10 Diagnoses by Patient_ID. GitHub. https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/HFRS/W12.HFRS.6.Pivot_HFRS.ipynb
Korpi, T. (2025l). W13: Calculating the Hospital Frailty Risk Score (HFRS) from ICD‑10 Codes: A Jupyter Notebook Approach. GitHub. https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/HFRS/W13.HFRS.7.Calculate_Pivot_HFRS.ipynb
Korpi, T. (2025m). W14: Histogram of HFRS Scores per Patient: Distribution Analysis and Risk Classification. GitHub. https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/HFRS/W14.HFRS.8.Plot_Pivot_HFRS.ipynb
Korpi, T. (2025n). W15: Modified Charlson Comorbidity Index Calculation and ICD-10 Code Expansion. GitHub. https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/CCI/W15.CCI.2.mo_CCI_weights.ipynb
Korpi, T. (2025o). W16: Removing Dots and Standardizing ICD-10 Codes in Modified Charlson Comorbidity Index. GitHub. https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/CCI/W16.CCI.3.procc_mo_CCI_weights.ipynb
Korpi, T. (2025p). W17: Preprocessing and Truncating ICD-10 Codes in Large Medical Datasets. GitHub. https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/CCI/W17.CCI.4.procc_CCI_data.ipynb
Korpi, T. (2025q). W18: Calculation of Modified Charlson Comorbidity Index Scores Using ICD-10 Codes. GitHub. https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/CCI/W18.CCI.5.Pivot_CCI_data.ipynb
Korpi, T. (2025r). W19: Correlation Analysis and Visualization of CCI and HFRS Using R. GitHub. https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/correlation_analysis/W19.Correlation_Analysis_CCI_HFRS.R
Korpi, T. (2025s). W20: Correlation Analysis of CCI and HFRS by Gender: An R Script. GitHub. https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/correlation_analysis/W20.Correlation_Analysis_CCI_HFRS_Men_Women.R
Korpi, T. (2025t). W21: Calculation and Visualization of Pearson Correlation Coefficient between CCI and HFRS. GitHub. https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/correlation_analysis/W21.Pearson_Correlation_Coefficient.R
Korpi, T. (2025u). W22: Case-Insensitive Search for BMI, Painoindeksi, or PI in EHR Data. https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/BMI/W22.BMI.1.All_Records_BMI.ipynb
Korpi, T. (2025v). W23: BMI Calculation from Extracted Height and Weight Data: A Jupyter Notebook Script. GitHub. https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/BMI/W23.BMI.2.Calculate_BMI_Height_Weight.ipynb
Korpi, T. (2025w). W24: Function to Compute and Print Cohort Summaries of Calculated BMI Data. GitHub. https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/BMI/W24.BMI.3.Function_2Compute_BMI_summaries.ipynb
Korpi, T. (2025). W25: Extracting and Summarizing BMI Values from Text Data. GitHub. https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/BMI/W25.BMI.4.Create_BMI_column.ipynb
Korpi, T. (2025x). W26: BMI Data Fusion and Cleanup: Combining Extracted and Calculated BMI Values. GitHub. https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/BMI/W26.BMI.5.Combine_BMI.ipynb
Korpi, T. (2025y). W27: Cohort Summaries of Combined BMI Data: Function Creation and Analysis. GitHub. https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/BMI/W27.BMI.6.Function_2Compute_Combine_BMI_Sum.ipynb
Korpi, T. (2025z). W28: Logistic Regression Analysis on Mortality: Adjusting for BMI, CCI, HFRS, Birth Year, and Gender. GitHub. https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/logistic_regression/W28.LRM.1.Mortality.BMI.CCI.HFRS.Adjusted.V1.ipynb
Korpi, T. (2025aa). W29: Logistic Regression Analysis on Mortality Using CCI and HFRS: Adjusting for Demographics. GitHub. https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/logistic_regression/W29.LRM.2.Mortality.CCI.HFRS.Adjusted.V2.ipynb
Korpi, T. (2025ab). W30: Logistic Regression Analysis on Mortality Using CCI and HFRS with Adjustments for Birth Year and Gender. GitHub. https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/logistic_regression/W30.LRM.3.Mortality.CCI.HFRS.Adjusted.R
Korpi, T. (2025ac). W31: Logistic Regression for Mortality Using CCI and HFRS with Gender-Specific Analyses and Comprehensive Model Visualizations. GitHub. https://github.com/Tupatuko2023/Python-R-Scripts/blob/main/logistic_regression/W31.LRM.4.Visualize.Model.R
Kwak, D., & Thompson, L. V. (2021). Frailty: Past, present, and future? Sports Medicine and Health Science, 3(1), 1–10. https://doi.org/10.1016/j.smhs.2020.11.005
Lekan, D. A., Wallace, D. C., McCoy, T. P., Hu, J., Silva, S. G., & Whitson, H. E. (2017). Frailty Assessment in Hospitalized Older Adults Using the Electronic Health Record. Biological Research for Nursing, 19(2), 213–228. https://doi.org/10.1177/1099800416679730
Lin, J., Korpi, T., Kuukka, A., Tirkkonen, A., Kariluoto, A., Kaijansinkko, J., Satamo, M., Pajulammi, H., Haapanen, M. J., Häyrynen, S., Pursiainen, E., Ciovica, D., Bonsdorff, M. B. von, & Jylhävä, J. (2024). Identification of Health Conditions in Unstructured Health Records with Deep Learning-Based Natural Language Processing (p. 2024.10.08.24315141). medRxiv. https://doi.org/10.1101/2024.10.08.24315141
Luo, J., Liao, X., Zou, C., Zhao, Q., Yao, Y., Fang, X., & Spicer, J. (2022). Identifying Frail Patients by Using Electronic Health Records in Primary Care: Current Status and Future Directions. Frontiers in Public Health, 10, 901068. https://doi.org/10.3389/fpubh.2022.901068
Mak, J. K. L., Eriksdotter, M., Annetorp, M., Kuja-Halkola, R., Kananen, L., Boström, A.-M., Kivipelto, M., Metzner, C., Bäck Jerlardtz, V., Engström, M., Johnson, P., Lundberg, L. G., Åkesson, E., Sühl Öberg, C., Olsson, M., Cederholm, T., Hägg, S., Religa, D., & Jylhävä, J. (2023). Two Years with COVID-19: The Electronic Frailty Index Identifies High-Risk Patients in the Stockholm GeroCovid Study. Gerontology, 69(4), 396–405. https://doi.org/10.1159/000527206
Mak, J. K. L., Hägg, S., Eriksdotter, M., Annetorp, M., Kuja-Halkola, R., Kananen, L., Boström, A.-M., Kivipelto, M., Metzner, C., Bäck Jerlardtz, V., Engström, M., Johnson, P., Lundberg, L. G., Åkesson, E., Sühl Öberg, C., Olsson, M., Cederholm, T., Jylhävä, J., & Religa, D. (2022). Development of an Electronic Frailty Index for Hospitalized Older Adults in Sweden. The Journals of Gerontology. Series A, Biological Sciences and Medical Sciences, 77(11), 2311–2319. https://doi.org/10.1093/gerona/glac069
McIsaac, D. I., MacDonald, D. B., & Aucoin, S. D. (2020). Frailty for Perioperative Clinicians: A Narrative Review. Anesthesia and Analgesia, 130(6), 1450–1460. https://doi.org/10.1213/ANE.0000000000004602
Microsoft. (2023, December 19). How to label your data for Custom Named Entity Recognition (NER)—Azure AI services. Learn.Microsoft.Com. https://learn.microsoft.com/en-us/azure/ai-services/language-service/custom-named-entity-recognition/how-to/tag-data
Niederstrasser, N. G., Rogers, N. T., & Bandelow, S. (2019). Determinants of frailty development and progression using a multidimensional frailty index: Evidence from the English Longitudinal Study of Ageing. PloS One, 14(10), e0223799. https://doi.org/10.1371/journal.pone.0223799
Paulson, D., & Lichtenberg, P. A. (2015). The Paulson-Lichtenberg Frailty Index: Evidence for a self-report measure of frailty. Aging & Mental Health, 19(10), 892–901. https://doi.org/10.1080/13607863.2014.986645
Puls, M., Sobisiak, B., Bleckmann, A., Jacobshagen, C., Danner, B. C., Hünlich, M., Beißbarth, T., Schöndube, F., Hasenfuß, G., Seipelt, R., & Schillinger, W. (2014). Impact of frailty on short- and long-term morbidity and mortality after transcatheter aortic valve implantation: Risk assessment by Katz Index of activities of daily living. EuroIntervention: Journal of EuroPCR in Collaboration with the Working Group on Interventional Cardiology of the European Society of Cardiology, 10(5), 609–619. https://doi.org/10.4244/EIJY14M08_03
Quan, H., Sundararajan, V., Halfon, P., Fong, A., Burnand, B., Luthi, J.-C., Saunders, L. D., Beck, C. A., Feasby, T. E., & Ghali, W. A. (2005). Coding algorithms for defining comorbidities in ICD-9-CM and ICD-10 administrative data. Medical Care, 43(11), 1130–1139. https://doi.org/10.1097/01.mlr.0000182534.19832.83
Remillard, E. T., Fausset, C. B., & Fain, W. B. (2019). Aging With Long-Term Mobility Impairment: Maintaining Activities of Daily Living via Selection, Optimization, and Compensation. The Gerontologist, 59(3), 559–569. https://doi.org/10.1093/geront/gnx186
Searle, S. D., Mitnitski, A., Gahbauer, E. A., Gill, T. M., & Rockwood, K. (2008). A standard procedure for creating a frailty index. BMC Geriatrics, 8(1), 24. https://doi.org/10.1186/1471-2318-8-24
Tayefi, M., Ngo, P., Chomutare, T., Dalianis, H., Salvi, E., Budrionis, A., & Godtliebsen, F. (2021). Challenges and opportunities beyond structured data in analysis of electronic health records. WIREs Computational Statistics, 13(6), e1549. https://doi.org/10.1002/wics.1549
Virtanen, A., Kanerva, J., Ilo, R., Luoma, J., Luotolahti, J., Salakoski, T., Ginter, F., & Pyysalo, S. (2019). Multilingual is not enough: BERT for Finnish (No. arXiv:1912.07076). arXiv. https://doi.org/10.48550/arXiv.1912.07076

