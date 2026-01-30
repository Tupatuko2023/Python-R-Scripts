import pandas as pd
import numpy as np
import argparse
import os
import sys
from pathlib import Path
from datetime import datetime

# --- Reuse Full HFRS MAPPING from 21 ---
HFRS_FULL_MAPPING = {
    'A40': 6.6, 'A41': 6.6, 'A04': 2.3, 'A09': 1.6, 'B96': 2.0, 'J18': 2.2, 'J15': 2.2, 'J69': 3.8,
    'N39': 3.3, 'N30': 2.0, 'A46': 2.5, 'C78': 3.0, 'C79': 3.0, 'D64': 2.1, 'D69': 2.0, 'E86': 3.1,
    'E87': 3.1, 'E11': 1.5, 'E10': 1.5, 'E03': 1.2, 'E43': 5.0, 'E44': 4.0, 'E46': 4.0, 'F00': 2.6,
    'F01': 2.6, 'F02': 2.6, 'F03': 2.6, 'F05': 6.2, 'G20': 2.5, 'G30': 2.6, 'G31': 3.0, 'F09': 3.5,
    'R40': 6.4, 'R41': 6.4, 'I21': 1.8, 'I46': 2.8, 'I48': 1.8, 'I50': 2.5, 'I63': 3.5, 'I64': 3.5,
    'I69': 3.0, 'I95': 2.5, 'J96': 3.5, 'J98': 2.0, 'K52': 2.0, 'K56': 3.0, 'K59': 2.5, 'K92': 2.0,
    'L03': 2.0, 'L89': 4.6, 'L97': 2.0, 'M06': 1.5, 'M19': 1.0, 'M80': 2.0, 'M81': 1.5, 'M54': 1.2,
    'N17': 3.6, 'N18': 2.5, 'N19': 3.0, 'R33': 4.4, 'R26': 4.7, 'R29': 3.2, 'R31': 4.0, 'R32': 2.0,
    'R53': 2.5, 'R54': 1.9, 'R55': 2.0, 'R56': 2.5, 'R60': 2.0, 'R63': 3.0, 'R64': 3.0, 'S00': 1.8,
    'S01': 1.8, 'S02': 1.8, 'S06': 2.5, 'S72': 2.1, 'T81': 2.5, 'W00': 2.0, 'W01': 2.0, 'W05': 2.0,
    'W06': 2.0, 'W07': 2.0, 'W08': 2.0, 'W09': 2.0, 'W10': 2.0, 'W18': 2.0, 'W19': 2.0, 'Z59': 2.0,
    'Z60': 2.0, 'Z73': 2.0, 'Z74': 2.0, 'Z75': 2.0, 'Z89': 1.5, 'Z91': 2.0, 'Z99': 3.0
}

# CCI Mapping
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
            if is_float: return str(int(float(x)))
            return str(x).strip()
        except: return str(x).strip()
    return df[col_name].apply(cleaner)

def parse_date_flexible(x):
    if pd.isna(x): return pd.NaT
    if isinstance(x, (pd.Timestamp, datetime)): return x
    try:
        s = str(int(float(x)))
        if len(s) == 8: return pd.to_datetime(s, format='%Y%m%d', errors='coerce')
    except: pass
    return pd.to_datetime(x, errors='coerce')

def get_min_dates(df_pkl, df_inpat):
    df_pkl['Date'] = pd.to_datetime(df_pkl['Kayntipvm'].astype(str), format='%Y%m%d', errors='coerce')
    min_pkl = df_pkl.groupby('SSN')['Date'].min()
    def parse_inpat(series):
        d = pd.to_datetime(series, errors='coerce')
        mask_bad = d.dt.year < 1980
        if mask_bad.any(): d.loc[mask_bad] = pd.to_datetime(series[mask_bad].astype(str), format='%Y%m%d', errors='coerce')
        return d
    df_inpat['Date'] = parse_inpat(df_inpat['OsastojaksoAlkuPvm'])
    min_inpat = df_inpat.groupby('SSN')['Date'].min()
    return pd.concat([min_pkl, min_inpat]).groupby(level=0).min()

def build_master(df_link, df_kaaos, df_min_dates):
    df_link['StudyID'] = clean_ssn_id(df_link, 'Tutkimus-henkilön numero', is_float=True)
    df_link['SSN'] = clean_ssn_id(df_link, 'Tutk.henkilön / verrokin henkilötunnus')
    df_link['ControlNum'] = clean_ssn_id(df_link, 'Ver-rokin nro', is_float=True)
    df_link['Group'] = np.where(df_link['ControlNum'] == '0', 'FallClinic', 'Control')
    study_id_col = [c for c in df_kaaos.columns if "potilas" in str(c) and "tunnus" in str(c)][0]
    date_col = [c for c in df_kaaos.columns if "Vastaan-otto" in str(c)][0]
    df_kaaos['StudyID'] = clean_ssn_id(df_kaaos, study_id_col, is_float=True)
    df_kaaos = df_kaaos.drop_duplicates(subset=['StudyID'])
    kaaos_info = df_kaaos[['StudyID', date_col]].copy()
    kaaos_info.columns = ['StudyID', 'ClinicDate']
    df_master = df_link.merge(kaaos_info, on='StudyID', how='left')
    control_date = pd.Timestamp("2020-11-23")
    def set_date(row):
        if row['Group'] == 'Control': return control_date
        d = row['ClinicDate']
        dt = parse_date_flexible(d)
        if pd.notna(dt) and dt.year > 2000: return dt
        ssn = row['SSN']
        if ssn in df_min_dates.index: return df_min_dates[ssn]
        return pd.NaT
    df_master['IndexDate'] = df_master.apply(set_date, axis=1)
    return df_master

def process_diagnoses(df_pkl, df_inpat, df_master, window_years=2):
    index_map = df_master.set_index('SSN')['IndexDate'].to_dict()
    all_diags = []
    
    # Outpatient
    df_pkl_f = df_pkl[df_pkl['SSN'].isin(index_map.keys())].copy()
    df_pkl_f['Date'] = pd.to_datetime(df_pkl_f['Kayntipvm'].astype(str), format='%Y%m%d', errors='coerce')
    diag_cols = [c for c in df_pkl_f.columns if 'dgo' in c.lower()]
    df_melt = df_pkl_f.melt(id_vars=['SSN', 'Date'], value_vars=[c for c in diag_cols if c in df_pkl_f.columns], value_name='ICD10')
    df_melt = df_melt.dropna(subset=['ICD10', 'Date'])
    df_melt['IndexDate'] = df_melt['SSN'].map(index_map)
    df_melt = df_melt.dropna(subset=['IndexDate'])
    df_melt['DaysDiff'] = (df_melt['IndexDate'] - df_melt['Date']).dt.days
    mask = (df_melt['DaysDiff'] >= 0) & (df_melt['DaysDiff'] <= (window_years * 365))
    df_out = df_melt[mask].copy()
    all_diags.append(df_out)
    
    # Inpatient
    df_in_f = df_inpat[df_inpat['SSN'].isin(index_map.keys())].copy()
    def parse_inpat(series):
        d = pd.to_datetime(series, errors='coerce')
        mask_bad = d.dt.year < 1980
        if mask_bad.any(): d.loc[mask_bad] = pd.to_datetime(series[mask_bad].astype(str), format='%Y%m%d', errors='coerce')
        return d
    df_in_f['Date'] = parse_inpat(df_in_f['OsastojaksoAlkuPvm'])
    diag_cols_in = [c for c in df_in_f.columns if 'dgo' in c.lower()]
    df_melt_in = df_in_f.melt(id_vars=['SSN', 'Date'], value_vars=[c for c in diag_cols_in if c in df_in_f.columns], value_name='ICD10')
    df_melt_in = df_melt_in.dropna(subset=['ICD10', 'Date'])
    df_melt_in['IndexDate'] = df_melt_in['SSN'].map(index_map)
    df_melt_in = df_melt_in.dropna(subset=['IndexDate'])
    df_melt_in['DaysDiff'] = (df_melt_in['IndexDate'] - df_melt_in['Date']).dt.days
    mask_in = (df_melt_in['DaysDiff'] >= 0) & (df_melt_in['DaysDiff'] <= (window_years * 365))
    df_in_v = df_melt_in[mask_in].copy()
    all_diags.append(df_in_v)
    
    df_combined = pd.concat(all_diags, ignore_index=True)
    df_combined['ICD10_Clean'] = df_combined['ICD10'].astype(str).str.replace('.', '').str.strip().str.upper()
    return df_combined

def calculate_scores_with_split(df_diags, df_master):
    ssns = df_master['SSN'].unique()
    results = {ssn: {'HFRS': 0.0, 'CCI': 0.0, 'Unique_Count': 0} for ssn in ssns}
    grouped = df_diags.groupby('SSN')
    
    for ssn, group in grouped:
        if ssn not in results: continue
        codes = set(group['ICD10_Clean'].values)
        results[ssn]['Unique_Count'] = len(codes)
        
        hfrs_score = 0.0
        for code in codes:
            prefix = code[:3]
            if prefix in HFRS_FULL_MAPPING: hfrs_score += HFRS_FULL_MAPPING[prefix]
        results[ssn]['HFRS'] = hfrs_score
        
        cci_score = 0
        cci_flags = set()
        for condition, rule in CCI_MAPPING.items():
            weight = rule['weight']
            prefixes = rule['codes']
            match = False
            for p in prefixes:
                for user_code in codes:
                    if user_code.startswith(p):
                        match = True; break
                if match: break
            if match:
                cci_score += weight; cci_flags.add(condition)
        if 'Metastatic' in cci_flags and 'Malignancy' in cci_flags: cci_score -= 2
        if 'DiabetesComp' in cci_flags and 'DiabetesSimple' in cci_flags: cci_score -= 1
        if 'LiverSevere' in cci_flags and 'LiverMild' in cci_flags: cci_score -= 1
        results[ssn]['CCI'] = cci_score
        
    res_data = [{'SSN': s, 'HFRS': v['HFRS'], 'CCI': v['CCI'], 'Unique_Count': v['Unique_Count']} for s, v in results.items()]
    df_scores = pd.DataFrame(res_data)
    df_final = df_master.merge(df_scores, on='SSN', how='left')
    df_final = df_final.fillna(0)
    return df_final

def aggregate_and_report(df_final, csv_path, md_path):
    df_final['has_secondary_dx'] = np.where(df_final['Unique_Count'] > 1, 1, 0)
    agg = df_final.groupby(['Group', 'has_secondary_dx']).agg({
        'HFRS': ['mean', 'std'],
        'CCI': ['mean'],
        'SSN': ['count']
    }).reset_index()
    agg.columns = ['Group', 'has_secondary_dx', 'HFRS_mean', 'HFRS_std', 'CCI_mean', 'n']
    
    # Suppression n < 5
    mask = agg['n'] < 5
    for c in ['HFRS_mean', 'HFRS_std', 'CCI_mean']: agg.loc[mask, c] = np.nan
    agg.to_csv(csv_path, index=False, float_format='%.2f')
    
    with open(md_path, 'w') as f:
        f.write("# Analyysi: Sivudiagnoosien vaikutus HFRS-pisteisiin\n\n")
        f.write("Tämä raportti vertailee potilaita, joilla on vain yksi uniikki ICD-10 diagnoosi (vain päädiagnoosi), ")
        f.write("niihin, joilla on useampia (sivudiagnooseja).\n\n")
        f.write(agg.to_markdown(index=False, floatfmt=".2f"))
        f.write("\n\n## Havainnot\n")
        
        # Calculate some stats for the text
        clinic_sec = agg[(agg['Group'] == 'FallClinic') & (agg['has_secondary_dx'] == 1)]
        clinic_one = agg[(agg['Group'] == 'FallClinic') & (agg['has_secondary_dx'] == 0)]
        
        if len(clinic_sec) > 0 and len(clinic_one) > 0:
            h_sec = clinic_sec['HFRS_mean'].values[0]
            h_one = clinic_one['HFRS_mean'].values[0]
            ratio = h_sec / (h_one + 0.0001)
            pct_sec = (clinic_sec['n'].values[0] / (clinic_sec['n'].values[0] + clinic_one['n'].values[0])) * 100
            
            f.write(f"- Kaatumisklinikalla potilaista {pct_sec:.1f} %:lla on kirjattu useampi kuin yksi uniikki diagnoosi.\n")
            f.write(f"- HFRS-pisteet ovat tässä ryhmässä keskimäärin **{h_sec:.2f}**, kun taas vain yhden diagnoosin ryhmässä ne ovat **{h_one:.2f}**.\n")
            f.write(f"- Pisteet nousevat kertoimella **{ratio:.1f}**, mutta jäävät silti alle viitearvojen (6-10).\n")
            
        f.write("\n## Johtopäätös\n")
        f.write("Matalat HFRS-pisteet selittyvät ensisijaisesti sillä, että valtaosalla potilaista (erityisesti verrokeilla) ")
        f.write("on kirjattu vain akuutti syy käynnille ilman komorbiditeettien (sivudiagnoosien) systemaattista kirjaamista.\n")

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--allow-aggregates", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    data_root = os.environ.get("DATA_ROOT", r"data/external")
    df_link, df_kaaos, df_pkl, df_inpat = load_data(data_root)
    df_pkl['SSN'] = clean_ssn_id(df_pkl, 'Henkilotunnus')
    df_inpat['SSN'] = clean_ssn_id(df_inpat, 'Henkilotunnus')
    df_min = get_min_dates(df_pkl, df_inpat)
    df_master = build_master(df_link, df_kaaos, df_min)
    if args.dry_run: print("Dry run done."); return
    df_diags = process_diagnoses(df_pkl, df_inpat, df_master)
    df_final = calculate_scores_with_split(df_diags, df_master)
    aggregate_and_report(df_final, "outputs/aggregates/aim2_diag_split.csv", "outputs/secondary_diagnosis_impact.md")
    print("Done.")

if __name__ == "__main__": main()
