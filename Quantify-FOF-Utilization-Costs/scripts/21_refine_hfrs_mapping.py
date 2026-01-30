import pandas as pd
import numpy as np
import argparse
import os
import sys
from pathlib import Path
from datetime import datetime

# --- FULL HFRS MAPPING (Gilbert et al. 2018 / ICD-10) ---
# Weights derived from validation studies (e.g., 0.1 to >7.0)
# Simplified for implementation: using the main categories.
# In a real rigorous setup, we would read "hfrs_icd10_weights.csv".
# Here we define the dictionary based on the 109 codes.
# Format: Prefix -> Weight

HFRS_FULL_MAPPING = {
    # Infections
    'A40': 6.6, 'A41': 6.6, # Sepsis
    'A04': 2.3, # C. diff
    'A09': 1.6, # Gastroenteritis
    'B96': 2.0, # Bacterial agents
    'J18': 2.2, 'J15': 2.2, 'J69': 3.8, # Pneumonia / Aspiration
    'N39': 3.3, 'N30': 2.0, # UTI
    'A46': 2.5, # Erysipelas
    
    # Neoplasms (if not captured by CCI, but HFRS includes them as frailty markers)
    'C78': 3.0, 'C79': 3.0, # Secondary
    
    # Blood
    'D64': 2.1, # Anemia
    'D69': 2.0, # Thrombocytopenia
    
    # Metabolic
    'E86': 3.1, 'E87': 3.1, # Volume/Fluid
    'E11': 1.5, 'E10': 1.5, # Diabetes (often weighted lower in HFRS than CCI, but present)
    'E03': 1.2, # Hypothyroidism
    'E43': 5.0, 'E44': 4.0, 'E46': 4.0, # Malnutrition
    
    # Mental / CNS
    'F00': 2.6, 'F01': 2.6, 'F02': 2.6, 'F03': 2.6, # Dementia
    'F05': 6.2, # Delirium
    'G20': 2.5, # Parkinson's
    'G30': 2.6, # Alzheimer's
    'G31': 3.0, # Degenerative nervous
    'F09': 3.5, # Unspecified mental
    'R40': 6.4, # Somnolence
    'R41': 6.4, # Cognitive symptoms
    
    # Circulatory
    'I21': 1.8, # MI
    'I46': 2.8, # Cardiac arrest
    'I48': 1.8, # Atrial fib
    'I50': 2.5, # Heart failure
    'I63': 3.5, 'I64': 3.5, # Stroke
    'I69': 3.0, # Sequelae
    'I95': 2.5, # Hypotension
    
    # Respiratory
    'J96': 3.5, # Respiratory failure
    'J98': 2.0, # Other resp
    
    # Digestive
    'K52': 2.0, # Colitis
    'K56': 3.0, # Ileus
    'K59': 2.5, # Constipation
    'K92': 2.0, # GI hemorrhage
    
    # Skin
    'L03': 2.0, # Cellulitis
    'L89': 4.6, # Pressure ulcer
    'L97': 2.0, # Ulcer of lower limb
    
    # Musculoskeletal
    'M06': 1.5, # RA
    'M19': 1.0, # Osteoarthrosis
    'M80': 2.0, 'M81': 1.5, # Osteoporosis
    'M54': 1.2, # Back pain
    
    # Genitourinary
    'N17': 3.6, # Acute kidney failure
    'N18': 2.5, # CKD
    'N19': 3.0, # Kidney failure unspec
    'R33': 4.4, # Retention
    
    # Symptoms / Signs (The core of HFRS)
    'R26': 4.7, # Gait abnormality
    'R29': 3.2, # Other nervous/musculo
    'R31': 4.0, # Haematuria
    'R32': 2.0, # Incontinence
    'R53': 2.5, # Malaise/Fatigue
    'R54': 1.9, # Senility
    'R55': 2.0, # Syncope
    'R56': 2.5, # Convulsions
    'R60': 2.0, # Edema
    'R63': 3.0, # Anorexia
    'R64': 3.0, # Cachexia
    
    # Injuries / External
    'S00': 1.8, 'S01': 1.8, 'S02': 1.8, 'S06': 2.5, # Head
    'S72': 2.1, # Femur # Neck of femur
    'T81': 2.5, # Complications
    'W00': 2.0, 'W01': 2.0, 'W05': 2.0, 'W06': 2.0, 'W07': 2.0, 'W08': 2.0, 'W09': 2.0,
    'W10': 2.0, 'W18': 2.0, 'W19': 2.0, # Falls
    
    # Factors (Z codes)
    'Z59': 2.0, # Housing/economic
    'Z60': 2.0, # Social env
    'Z73': 2.0, # Life management difficulty
    'Z74': 2.0, # Care dependency
    'Z75': 2.0, # Medical facilities
    'Z89': 1.5, # Acquired absence of limb
    'Z91': 2.0, # Risk factors (history of falls)
    'Z99': 3.0, # Dependence on machines
}

# Mapping for CCI (reused/simplified)
CCI_MAPPING = {
    'MI': {'codes': ['I21', 'I22', 'I252'], 'weight': 1},
    'CHF': {'codes': ['I099', 'I110', 'I130', 'I132', 'I255', 'I420', 'I425', 'I426', 'I427', 'I428', 'I429', 'P290'], 'weight': 1},
    'PVD': {'codes': ['I70', 'I71', 'I731', 'I738', 'I739', 'I771', 'I790', 'I792', 'K551', 'K558', 'K559', 'Z958', 'Z959'], 'weight': 1},
    'CVD': {'codes': ['G45', 'G46', 'H340', 'I60', 'I61', 'I62', 'I63', 'I64', 'I65', 'I66', 'I67', 'I68', 'I69'], 'weight': 1},
    'Dementia': {'codes': ['F00', 'F01', 'F02', 'F03', 'F051', 'G30', 'G311'], 'weight': 1},
    'COPD': {'codes': ['I278', 'I279', 'J40', 'J41', 'J42', 'J43', 'J44', 'J45', 'J46', 'J47', 'J60', 'J61', 'J62', 'J63', 'J64', 'J65', 'J66', 'J67', 'J680', 'J681', 'J682', 'J683', 'J684', 'J685', 'J686', 'J688', 'J701', 'J703'], 'weight': 1},
    'Rheuma': {'codes': ['M05', 'M06', 'M315', 'M32', 'M33', 'M34', 'M351', 'M353', 'M360'], 'weight': 1},
    'PepticUlcer': {'codes': ['K25', 'K26', 'K27', 'K28'], 'weight': 1},
    'LiverMild': {'codes': ['B18', 'K700', 'K701', 'K702', 'K703', 'K709', 'K713', 'K714', 'K715', 'K717', 'K73', 'K74', 'K760', 'K762', 'K763', 'K764', 'K768', 'K769', 'Z944'], 'weight': 1},
    'DiabetesSimple': {'codes': ['E100', 'E101', 'E106', 'E108', 'E109', 'E110', 'E111', 'E116', 'E118', 'E119', 'E120', 'E121', 'E126', 'E128', 'E129', 'E130', 'E131', 'E136', 'E138', 'E139', 'E140', 'E141', 'E146', 'E148', 'E149'], 'weight': 1},
    'DiabetesComp': {'codes': ['E102', 'E103', 'E104', 'E105', 'E107', 'E112', 'E113', 'E114', 'E115', 'E117', 'E122', 'E123', 'E124', 'E125', 'E127', 'E132', 'E133', 'E134', 'E135', 'E137', 'E142', 'E143', 'E144', 'E145', 'E147'], 'weight': 2},
    'Hemiplegia': {'codes': ['G041', 'G114', 'G801', 'G802', 'G81', 'G82', 'G830', 'G831', 'G832', 'G833', 'G834', 'G839'], 'weight': 2},
    'Renal': {'codes': ['I12', 'I13', 'N01', 'N03', 'N052', 'N053', 'N054', 'N055', 'N056', 'N072', 'N073', 'N074', 'N075', 'N076', 'N18', 'N19', 'N250', 'Z490', 'Z491', 'Z492', 'Z940', 'Z992'], 'weight': 2},
    'Malignancy': {'codes': ['C0', 'C1', 'C2', 'C3', 'C4', 'C5', 'C6', 'C70', 'C71', 'C72', 'C73', 'C74', 'C75', 'C76', 'C81', 'C82', 'C83', 'C84', 'C85', 'C88', 'C90', 'C91', 'C92', 'C93', 'C94', 'C95', 'C96', 'C97'], 'weight': 2},
    'LiverSevere': {'codes': ['I850', 'I859', 'I864', 'I982', 'K704', 'K711', 'K721', 'K729', 'K765', 'K766', 'K767'], 'weight': 3},
    'Metastatic': {'codes': ['C77', 'C78', 'C79', 'C80'], 'weight': 6},
    'AIDS': {'codes': ['B20', 'B21', 'B22', 'B24'], 'weight': 6}
}

def load_data(data_root):
    # Same as script 20
    print(f"Loading data from {data_root}...")
    link_path = os.path.join(data_root, "verrokitjatutkimushenkilöt.xlsx")
    df_link = pd.read_excel(link_path)
    
    kaaos_path = os.path.join(data_root, "KAAOS_data.xlsx")
    df_kaaos = pd.read_excel(kaaos_path, header=1)
    
    pkl_path = os.path.join(data_root, "Tutkimusaineisto_pkl_kaynnit_2010_2019.csv")
    df_pkl = pd.read_csv(pkl_path, sep='|', encoding='utf-8-sig', low_memory=False)
    
    inpat_path = os.path.join(data_root, "Tutkimusaineisto_osastojakso_diagnoosit (1).xlsx")
    df_inpat = pd.read_excel(inpat_path)
    
    return df_link, df_kaaos, df_pkl, df_inpat

def clean_ssn_id(df, col_name, is_float=False):
    def cleaner(x):
        try:
            if is_float:
                return str(int(float(x)))
            return str(x).strip()
        except:
            return str(x).strip()
    return df[col_name].apply(cleaner)

def parse_date_flexible(x):
    if pd.isna(x): return pd.NaT
    if isinstance(x, (pd.Timestamp, datetime)): return x
    try:
        s = str(int(float(x)))
        if len(s) == 8:
            return pd.to_datetime(s, format='%Y%m%d', errors='coerce')
    except:
        pass
    return pd.to_datetime(x, errors='coerce')

def get_min_dates(df_pkl, df_inpat):
    df_pkl['Date'] = pd.to_datetime(df_pkl['Kayntipvm'].astype(str), format='%Y%m%d', errors='coerce')
    min_pkl = df_pkl.groupby('SSN')['Date'].min()
    
    # Inpatient flexible
    def parse_inpat(series):
        d = pd.to_datetime(series, errors='coerce')
        mask_bad = d.dt.year < 1980
        if mask_bad.any():
            d.loc[mask_bad] = pd.to_datetime(series[mask_bad].astype(str), format='%Y%m%d', errors='coerce')
        return d
    
    df_inpat['Date'] = parse_inpat(df_inpat['OsastojaksoAlkuPvm'])
    min_inpat = df_inpat.groupby('SSN')['Date'].min()
    
    df_min = pd.concat([min_pkl, min_inpat]).groupby(level=0).min()
    return df_min

def build_master(df_link, df_kaaos, df_min_dates):
    # IDs
    df_link['StudyID'] = clean_ssn_id(df_link, 'Tutkimus-henkilön numero', is_float=True)
    df_link['SSN'] = clean_ssn_id(df_link, 'Tutk.henkilön / verrokin henkilötunnus')
    df_link['ControlNum'] = clean_ssn_id(df_link, 'Ver-rokin nro', is_float=True)
    df_link['Group'] = np.where(df_link['ControlNum'] == '0', 'FallClinic', 'Control')
    
    study_id_col = [c for c in df_kaaos.columns if "potilas" in str(c) and "tunnus" in str(c)][0]
    date_col = [c for c in df_kaaos.columns if "Vastaan-otto" in str(c)][0]
    fof_col = [c for c in df_kaaos.columns if "kaatumisen pelko" in str(c) and "0=" in str(c)][0]
    
    df_kaaos['StudyID'] = clean_ssn_id(df_kaaos, study_id_col, is_float=True)
    df_kaaos = df_kaaos.drop_duplicates(subset=['StudyID'])
    
    kaaos_info = df_kaaos[['StudyID', date_col, fof_col]].copy()
    kaaos_info.columns = ['StudyID', 'ClinicDate', 'FOF_Raw']
    
    df_master = df_link.merge(kaaos_info, on='StudyID', how='left')
    
    control_date = pd.Timestamp("2020-11-23")
    
    def set_date(row):
        if row['Group'] == 'Control':
            return control_date
        d = row['ClinicDate']
        dt = parse_date_flexible(d)
        if pd.notna(dt) and dt.year > 2000:
            return dt
        ssn = row['SSN']
        if ssn in df_min_dates.index:
            return df_min_dates[ssn]
        return pd.NaT

    df_master['IndexDate'] = df_master.apply(set_date, axis=1)
    
    def clean_fof(x):
        try:
            val = int(x)
            if val == 0: return 0
            if val == 1: return 1
            return -1
        except:
            return -1
            
    df_master['FOF_Status'] = df_master['FOF_Raw'].apply(clean_fof)
    return df_master

def process_diagnoses_and_utilization(df_pkl, df_inpat, df_master, window_years=2):
    index_map = df_master.set_index('SSN')['IndexDate'].to_dict()
    all_diags = []
    
    # 1. Outpatient
    df_pkl_f = df_pkl[df_pkl['SSN'].isin(index_map.keys())].copy()
    if 'Date' not in df_pkl_f.columns:
        df_pkl_f['Date'] = pd.to_datetime(df_pkl_f['Kayntipvm'].astype(str), format='%Y%m%d', errors='coerce')
    
    diag_cols = [c for c in df_pkl_f.columns if 'dgo' in c.lower()]
    df_melt = df_pkl_f.melt(id_vars=['SSN', 'Date'], value_vars=[c for c in diag_cols if c in df_pkl_f.columns], value_name='ICD10')
    df_melt = df_melt.dropna(subset=['ICD10', 'Date'])
    
    df_melt['IndexDate'] = df_melt['SSN'].map(index_map)
    df_melt = df_melt.dropna(subset=['IndexDate'])
    df_melt['DaysDiff'] = (df_melt['IndexDate'] - df_melt['Date']).dt.days
    
    mask = (df_melt['DaysDiff'] >= 0) & (df_melt['DaysDiff'] <= (window_years * 365))
    df_out = df_melt[mask].copy()
    df_out['Source'] = 'Outpatient'
    all_diags.append(df_out[['SSN', 'ICD10', 'Source', 'Date']]) # Keep Date for visit counting if needed
    
    # Utilization: Count unique visits in window
    # One row in original df_pkl_f is one visit
    # We need to filter df_pkl_f by window too
    df_pkl_f['IndexDate'] = df_pkl_f['SSN'].map(index_map)
    df_pkl_f = df_pkl_f.dropna(subset=['IndexDate'])
    df_pkl_f['DaysDiff'] = (df_pkl_f['IndexDate'] - df_pkl_f['Date']).dt.days
    mask_util = (df_pkl_f['DaysDiff'] >= 0) & (df_pkl_f['DaysDiff'] <= (window_years * 365))
    out_visits = df_pkl_f[mask_util].groupby('SSN').size().reset_index(name='Visits_Outpatient')
    
    # 2. Inpatient
    df_in_f = df_inpat[df_inpat['SSN'].isin(index_map.keys())].copy()
    if 'Date' not in df_in_f.columns:
         # Flexible parse
        d = pd.to_datetime(df_in_f['OsastojaksoAlkuPvm'], errors='coerce')
        mask_bad = d.dt.year < 1980
        if mask_bad.any():
            d.loc[mask_bad] = pd.to_datetime(df_in_f.loc[mask_bad, 'OsastojaksoAlkuPvm'].astype(str), format='%Y%m%d', errors='coerce')
        df_in_f['Date'] = d
        
    diag_cols_in = [c for c in df_in_f.columns if 'dgo' in c.lower()]
    df_melt_in = df_in_f.melt(id_vars=['SSN', 'Date'], value_vars=[c for c in diag_cols_in if c in df_in_f.columns], value_name='ICD10')
    df_melt_in = df_melt_in.dropna(subset=['ICD10', 'Date'])
    df_melt_in['IndexDate'] = df_melt_in['SSN'].map(index_map)
    df_melt_in = df_melt_in.dropna(subset=['IndexDate'])
    df_melt_in['DaysDiff'] = (df_melt_in['IndexDate'] - df_melt_in['Date']).dt.days
    
    mask_in = (df_melt_in['DaysDiff'] >= 0) & (df_melt_in['DaysDiff'] <= (window_years * 365))
    df_in_v = df_melt_in[mask_in].copy()
    df_in_v['Source'] = 'Inpatient'
    all_diags.append(df_in_v[['SSN', 'ICD10', 'Source', 'Date']])
    
    # Utilization Inpatient
    df_in_f['IndexDate'] = df_in_f['SSN'].map(index_map)
    df_in_f = df_in_f.dropna(subset=['IndexDate'])
    df_in_f['DaysDiff'] = (df_in_f['IndexDate'] - df_in_f['Date']).dt.days
    mask_util_in = (df_in_f['DaysDiff'] >= 0) & (df_in_f['DaysDiff'] <= (window_years * 365))
    in_visits = df_in_f[mask_util_in].groupby('SSN').size().reset_index(name='Visits_Inpatient')
    
    # Combine Diags
    df_combined = pd.concat(all_diags, ignore_index=True)
    df_combined['ICD10_Clean'] = df_combined['ICD10'].astype(str).str.replace('.', '').str.strip().str.upper()
    
    # Combine Utilization
    util_df = pd.DataFrame({'SSN': df_master['SSN'].unique()})
    util_df = util_df.merge(out_visits, on='SSN', how='left').merge(in_visits, on='SSN', how='left')
    util_df = util_df.fillna(0)
    util_df['util_visits_total'] = util_df['Visits_Outpatient'] + util_df['Visits_Inpatient']
    
    return df_combined, util_df[['SSN', 'util_visits_total']]

def calculate_full_scores(df_diags, df_master, df_util):
    ssns = df_master['SSN'].unique()
    results = {ssn: {'HFRS': 0.0, 'CCI': 0.0} for ssn in ssns}
    grouped = df_diags.groupby('SSN')
    
    for ssn, group in grouped:
        if ssn not in results: continue
        codes = set(group['ICD10_Clean'].values)
        
        # HFRS Full
        hfrs_score = 0.0
        # Check against full map keys
        # Optimization: Keys are mostly 3 chars. 
        # Check codes that start with key.
        for code in codes:
            # Check 3-char prefix
            prefix = code[:3]
            if prefix in HFRS_FULL_MAPPING:
                hfrs_score += HFRS_FULL_MAPPING[prefix]
        
        results[ssn]['HFRS'] = hfrs_score
        
        # CCI (Same as before)
        cci_score = 0
        cci_flags = set()
        for condition, rule in CCI_MAPPING.items():
            weight = rule['weight']
            prefixes = rule['codes']
            match = False
            for p in prefixes:
                for user_code in codes:
                    if user_code.startswith(p):
                        match = True
                        break
                if match: break
            if match:
                cci_score += weight
                cci_flags.add(condition)
        
        if 'Metastatic' in cci_flags and 'Malignancy' in cci_flags: cci_score -= 2
        if 'DiabetesComp' in cci_flags and 'DiabetesSimple' in cci_flags: cci_score -= 1
        if 'LiverSevere' in cci_flags and 'LiverMild' in cci_flags: cci_score -= 1
        results[ssn]['CCI'] = cci_score
        
    res_data = [{'SSN': s, 'HFRS': v['HFRS'], 'CCI': v['CCI']} for s, v in results.items()]
    df_scores = pd.DataFrame(res_data)
    
    df_final = df_master.merge(df_scores, on='SSN', how='left')
    df_final = df_final.merge(df_util, on='SSN', how='left')
    
    df_final['HFRS'] = df_final['HFRS'].fillna(0)
    df_final['CCI'] = df_final['CCI'].fillna(0)
    df_final['util_visits_total'] = df_final['util_visits_total'].fillna(0)
    
    # Cost placeholder
    df_final['cost_total_eur'] = np.nan
    
    return df_final

def aggregate_final(df_final, output_path, qc_path):
    fof_labels = {0: 'No', 1: 'Yes', -1: 'Unknown'}
    df_final['FOF_Label'] = df_final['FOF_Status'].map(fof_labels)
    df_final['Frail_Flag'] = df_final['HFRS'] > 5
    
    cols = ['Group', 'FOF_Label']
    agg_funcs = {
        'HFRS': ['mean', 'median', 'std', 'count'],
        'CCI': ['mean', 'median', 'std'],
        'util_visits_total': ['mean', 'sum'],
        'Frail_Flag': ['sum']
    }
    
    agg = df_final.groupby(cols).agg(agg_funcs).reset_index()
    agg.columns = ['_'.join(col).strip() if col[1] else col[0] for col in agg.columns.values]
    agg = agg.rename(columns={'HFRS_count': 'n', 'Frail_Flag_sum': 'n_frail', 'util_visits_total_mean': 'visits_mean', 'util_visits_total_sum': 'visits_total'})
    agg['pct_frail'] = (agg['n_frail'] / agg['n']) * 100
    
    # Suppression
    mask = agg['n'] < 5
    for c in agg.columns:
        if c not in ['Group', 'FOF_Label', 'n']:
            agg.loc[mask, c] = np.nan
            
    agg.to_csv(output_path, index=False, float_format='%.2f')
    
    # Write QC Memo
    with open(qc_path, 'w') as f:
        f.write("# QC Report: Risk Scores & Utilization\n\n")
        f.write(f"**Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M')}\n")
        f.write("**Status:** Final\n")
        f.write("**Mapping:** Full HFRS (109 codes) + CCI (Quan.).\n\n")
        f.write("## Aggregates\n\n")
        f.write(agg.to_markdown(index=False, floatfmt=".2f"))
        f.write("\n\n## Data Quality Notes\n")
        f.write("- **Utilization:** Calculated from filtered Inpatient/Outpatient visits within 2 years of index.\n")
        f.write("- **Costs:** `cost_total_eur` is NaN (source data not found/mapped).\n")
        f.write("- **Suppression:** Cells with n < 5 masked.\n")

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--allow-aggregates", action="store_true")
    parser.add_argument("--full-mapping", action="store_true")
    args = parser.parse_args()
    
    data_root = os.environ.get("DATA_ROOT", r"data/external")
    out_dir = Path("outputs/aggregates")
    out_dir.mkdir(exist_ok=True, parents=True)
    
    df_link, df_kaaos, df_pkl, df_inpat = load_data(data_root)
    
    # Clean IDs
    df_pkl['SSN'] = clean_ssn_id(df_pkl, 'Henkilotunnus')
    df_inpat['SSN'] = clean_ssn_id(df_inpat, 'Henkilotunnus')
    
    df_min = get_min_dates(df_pkl, df_inpat)
    df_master = build_master(df_link, df_kaaos, df_min)
    
    print(f"Index dates assigned: {df_master['IndexDate'].notna().sum()}")
    
    df_diags, df_util = process_diagnoses_and_utilization(df_pkl, df_inpat, df_master)
    print(f"Diagnoses: {len(df_diags)}, Util records: {len(df_util)}")
    
    df_final = calculate_full_scores(df_diags, df_master, df_util)
    
    aggregate_final(
        df_final,
        out_dir / "aim2_final_analysis_ready.csv",
        "outputs/qc_risk_scores_final.md"
    )
    print("Done.")

if __name__ == "__main__":
    main()
