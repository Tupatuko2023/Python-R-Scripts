import pandas as pd
import numpy as np
import argparse
import os
import sys
from pathlib import Path
from datetime import datetime

# Reuse loading logic
def load_data(data_root):
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
    return df_master

def analyze_density(df_pkl, df_inpat, df_master, window_years=2):
    """Calculate diagnosis density."""
    
    index_map = df_master.set_index('SSN')['IndexDate'].to_dict()
    
    # Track stats per SSN
    stats = {ssn: {'Outpatient_Visits': 0, 'Inpatient_Episodes': 0, 
                   'Primary_Diags': 0, 'Secondary_Diags': 0,
                   'Unique_ICD10': set()} 
             for ssn in df_master['SSN']}

    # 1. Outpatient
    df_pkl_f = df_pkl[df_pkl['SSN'].isin(index_map.keys())].copy()
    if 'Date' not in df_pkl_f.columns:
        df_pkl_f['Date'] = pd.to_datetime(df_pkl_f['Kayntipvm'].astype(str), format='%Y%m%d', errors='coerce')
    
    df_pkl_f['IndexDate'] = df_pkl_f['SSN'].map(index_map)
    df_pkl_f = df_pkl_f.dropna(subset=['IndexDate'])
    df_pkl_f['DaysDiff'] = (df_pkl_f['IndexDate'] - df_pkl_f['Date']).dt.days
    mask = (df_pkl_f['DaysDiff'] >= 0) & (df_pkl_f['DaysDiff'] <= (window_years * 365))
    df_out = df_pkl_f[mask].copy()
    
    # Columns
    pdgo_col = 'Pdgo'
    sdg_cols = [c for c in df_out.columns if c.startswith('Sdg') or c.startswith('sdg')]
    
    for idx, row in df_out.iterrows():
        ssn = row['SSN']
        stats[ssn]['Outpatient_Visits'] += 1
        
        # Primary
        if pd.notna(row.get(pdgo_col)):
            stats[ssn]['Primary_Diags'] += 1
            stats[ssn]['Unique_ICD10'].add(str(row[pdgo_col]).strip().upper())
            
        # Secondary
        for c in sdg_cols:
            val = row.get(c)
            if pd.notna(val) and str(val).strip() != '':
                stats[ssn]['Secondary_Diags'] += 1
                stats[ssn]['Unique_ICD10'].add(str(val).strip().upper())

    # 2. Inpatient
    df_in_f = df_inpat[df_inpat['SSN'].isin(index_map.keys())].copy()
    # Assume 'Date' logic handled/copied or redundant if clean load
    def parse_inpat(series):
        d = pd.to_datetime(series, errors='coerce')
        mask_bad = d.dt.year < 1980
        if mask_bad.any():
            d.loc[mask_bad] = pd.to_datetime(series[mask_bad].astype(str), format='%Y%m%d', errors='coerce')
        return d
    df_in_f['Date'] = parse_inpat(df_in_f['OsastojaksoAlkuPvm'])
    
    df_in_f['IndexDate'] = df_in_f['SSN'].map(index_map)
    df_in_f = df_in_f.dropna(subset=['IndexDate'])
    df_in_f['DaysDiff'] = (df_in_f['IndexDate'] - df_in_f['Date']).dt.days
    mask_in = (df_in_f['DaysDiff'] >= 0) & (df_in_f['DaysDiff'] <= (window_years * 365))
    df_in = df_in_f[mask_in].copy()
    
    pdgo_col_in = [c for c in df_in.columns if 'Pdgo' in c or 'pdgo' in c][0] # Assuming one
    sdg_cols_in = [c for c in df_in.columns if c.startswith('Sdg') or c.startswith('sdg')] # Assuming one

    for idx, row in df_in.iterrows():
        ssn = row['SSN']
        stats[ssn]['Inpatient_Episodes'] += 1
        
        if pd.notna(row.get(pdgo_col_in)):
            stats[ssn]['Primary_Diags'] += 1
            stats[ssn]['Unique_ICD10'].add(str(row[pdgo_col_in]).strip().upper())
            
        for c in sdg_cols_in:
            val = row.get(c)
            if pd.notna(val) and str(val).strip() != '':
                stats[ssn]['Secondary_Diags'] += 1
                stats[ssn]['Unique_ICD10'].add(str(val).strip().upper())
                
    # Summarize
    res_data = []
    for ssn, v in stats.items():
        res_data.append({
            'SSN': ssn,
            'Total_Visits': v['Outpatient_Visits'] + v['Inpatient_Episodes'],
            'Primary_Diags': v['Primary_Diags'],
            'Secondary_Diags': v['Secondary_Diags'],
            'Unique_ICD10_Count': len(v['Unique_ICD10'])
        })
        
    df_res = pd.DataFrame(res_data)
    df_final = df_master.merge(df_res, on='SSN', how='left')
    df_final = df_final.fillna(0)
    
    print("## Diagnosis Audit Report\n")
    print(df_final.groupby('Group')[['Total_Visits', 'Primary_Diags', 'Secondary_Diags', 'Unique_ICD10_Count']].describe().T.to_string())
    print("\n## Secondary Diagnosis Ratio")
    
    df_final['Sdg_Ratio'] = df_final['Secondary_Diags'] / (df_final['Primary_Diags'] + 0.0001)
    print(df_final.groupby('Group')['Sdg_Ratio'].describe().to_string())
    
    # Zero stats
    print("\n## Zero Data Analysis")
    zero_diags = df_final[df_final['Unique_ICD10_Count'] == 0]
    print(f"Subjects with 0 diagnoses: {len(zero_diags)} / {len(df_final)} ({len(zero_diags)/len(df_final)*100:.1f}%)")
    print(zero_diags.groupby('Group').size())
    
    # Only those with data
    print("\n## Among those with >= 1 Diagnosis")
    with_data = df_final[df_final['Unique_ICD10_Count'] > 0]
    print(with_data.groupby('Group')[['Unique_ICD10_Count', 'Secondary_Diags']].describe().T.to_string())

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", help="Optional path to aggregate file")
    args = parser.parse_args()
    
    data_root = os.environ.get("DATA_ROOT", r"data/external")
    
    df_link, df_kaaos, df_pkl, df_inpat = load_data(data_root)
    
    # Clean
    df_pkl['SSN'] = clean_ssn_id(df_pkl, 'Henkilotunnus')
    df_inpat['SSN'] = clean_ssn_id(df_inpat, 'Henkilotunnus')
    
    df_min = get_min_dates(df_pkl, df_inpat)
    df_master = build_master(df_link, df_kaaos, df_min)
    
    analyze_density(df_pkl, df_inpat, df_master)

if __name__ == "__main__":
    main()
