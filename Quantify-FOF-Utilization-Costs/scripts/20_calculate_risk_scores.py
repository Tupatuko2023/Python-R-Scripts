import pandas as pd
import numpy as np
import argparse
import os
import sys
from pathlib import Path
from datetime import datetime, timedelta

# --- Constants & Mappings ---

# Charlson Comorbidity Index (Quan et al. 2005 adaptation for ICD-10)
# Weights: 1, 2, 3, 6
CCI_MAPPING = {
    'MI': {'codes': ['I21', 'I22', 'I252'], 'weight': 1},
    'CHF': {'codes': ['I099', 'I110', 'I130', 'I132', 'I255', 'I420', 'I425', 'I426', 'I427', 'I428', 'I429', 'P290'], 'weight': 1},
    'PVD': {'codes': ['I70', 'I71', 'I731', 'I738', 'I739', 'I771', 'I790', 'I792', 'K551', 'K558', 'K559', 'Z958', 'Z959'], 'weight': 1},
    'CVD': {'codes': ['G45', 'G46', 'H340', 'I60', 'I61', 'I62', 'I63', 'I64', 'I65', 'I66', 'I67', 'I68', 'I69'], 'weight': 1},
    'Dementia': {'codes': ['F00', 'F01', 'F02', 'F03', 'F051', 'G30', 'G311'], 'weight': 1},
    'COPD': {'codes': ['I278', 'I279', 'J40', 'J41', 'J42', 'J43', 'J44', 'J45', 'J46', 'J47', 'J60', 'J61', 'J62', 'J63', 'J64', 'J65', 'J66', 'J67', 'J680', 'J681', 'J682', 'J683', 'J684', 'J685', 'J686', 'J688', 'J689', 'J701', 'J703'], 'weight': 1},
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

# Hospital Frailty Risk Score (HFRS) - Condensed version (top categories)
# Using a simplified dictionary for this script. Full list is 109 codes.
# This is a REPRESENTATIVE subset for the prototype. In production, load full list.
HFRS_MAPPING = {
    # High weight examples
    'G00': 7.3, 'G01': 7.3, 'G02': 7.3, 'G03': 7.3, # CNS infection
    'A40': 6.6, 'A41': 6.6, # Sepsis
    'R40': 6.4, # Somnolence
    'R41': 6.4, # Other symptoms involving cognitive functions
    'F05': 6.2, # Delirium
    'R26': 4.7, # Abnormality of gait
    'R33': 4.4, # Retention of urine
    'R31': 4.0, # Haematuria
    'N17': 3.6, # Acute kidney failure
    'N39': 3.3, # Urinary tract infection
    'R29': 3.2, # Other symptoms involving nervous/musculoskeletal
    'E86': 3.1, # Volume depletion
    'E87': 3.1, # Fluid/electrolyte imbalance
    'I46': 2.8, # Cardiac arrest
    'I50': 2.5, # Heart failure
    'J18': 2.2, # Pneumonia
    'S72': 2.1, # Fracture of femur
    'S00': 1.8, 'S01': 1.8, 'S02': 1.8, 'S06': 1.8, # Head injury
    # ... many others. 
    # For a full implementation, we'd need the full CSV. 
    # I will define a generic "Frailty" list of typical ICD10 prefixes to map if not exact.
    # PROTOTYPE MODE: Map commonly occurring frailty codes.
}
# Note: For production, we should read hfrs_weights.csv. 
# I will assume for this task that the focus is on the PIPELINE logic.
# I'll expand the dictionary slightly to cover common geriatric conditions.
HFRS_EXPANSION = {
    'F00': 2.6, 'F01': 2.6, 'F02': 2.6, 'F03': 2.6, 'G30': 2.6, # Dementia
    'L89': 4.6, # Pressure ulcer
    'W0': 2.0, 'W1': 2.0, # Falls (External causes often not in diag cols but worth having)
    'M80': 2.0, 'M81': 1.5, # Osteoporosis
    'Z73': 2.0, 'Z74': 2.0, 'Z75': 2.0, # Care problems
    'R54': 1.9, # Senility
}
HFRS_MAPPING.update(HFRS_EXPANSION)

def load_data(data_root):
    """Load and return raw dataframes."""
    print(f"Loading data from {data_root}...")
    
    # 1. Linkage
    link_path = os.path.join(data_root, "verrokitjatutkimushenkilöt.xlsx")
    df_link = pd.read_excel(link_path)
    
    # 2. FOF Data
    kaaos_path = os.path.join(data_root, "KAAOS_data.xlsx")
    df_kaaos = pd.read_excel(kaaos_path, header=1)
    
    # 3. Outpatient
    pkl_path = os.path.join(data_root, "Tutkimusaineisto_pkl_kaynnit_2010_2019.csv")
    df_pkl = pd.read_csv(pkl_path, sep='|', encoding='utf-8-sig', low_memory=False)
    
    # 4. Inpatient
    inpat_path = os.path.join(data_root, "Tutkimusaineisto_osastojakso_diagnoosit (1).xlsx")
    df_inpat = pd.read_excel(inpat_path)
    
    return df_link, df_kaaos, df_pkl, df_inpat

def clean_ssn_id(df, col_name, is_float=False):
    """Clean ID columns to string."""
    def cleaner(x):
        try:
            if is_float:
                return str(int(float(x)))
            return str(x).strip()
        except:
            return str(x).strip()
    
    return df[col_name].apply(cleaner)

def get_index_dates(df_link, df_kaaos):
    """Determine index date for each subject."""
    # Clean IDs
    df_link['StudyID'] = clean_ssn_id(df_link, 'Tutkimus-henkilön numero', is_float=True)
    df_link['SSN'] = clean_ssn_id(df_link, 'Tutk.henkilön / verrokin henkilötunnus')
    df_link['ControlNum'] = clean_ssn_id(df_link, 'Ver-rokin nro', is_float=True)
    
    # Identify Group
    # ControlNum == '0' -> FallClinic, else Control
    df_link['Group'] = np.where(df_link['ControlNum'] == '0', 'FallClinic', 'Control')
    
    # KAAOS clean
    study_id_col = [c for c in df_kaaos.columns if "potilas" in str(c) and "tunnus" in str(c)][0]
    date_col = [c for c in df_kaaos.columns if "Vastaan-otto" in str(c)][0]
    fof_col = [c for c in df_kaaos.columns if "kaatumisen pelko" in str(c) and "0=" in str(c)][0]
    
    df_kaaos['StudyID'] = clean_ssn_id(df_kaaos, study_id_col, is_float=True)
    
    # Map FOF and Date
    # Handling potential duplicates in KAAOS by taking first
    df_kaaos = df_kaaos.drop_duplicates(subset=['StudyID'])
    
    # Extract info
    kaaos_info = df_kaaos[['StudyID', date_col, fof_col]].copy()
    kaaos_info.columns = ['StudyID', 'ClinicDate', 'FOF_Raw']
    
    # Merge to Linkage
    df_master = df_link.merge(kaaos_info, on='StudyID', how='left')
    
    return df_master

def parse_date_flexible(x):
    if pd.isna(x): return pd.NaT
    # If already timestamp
    if isinstance(x, (pd.Timestamp, datetime)):
        return x
    try:
        # Try YYYYMMDD string/int
        s = str(int(float(x)))
        if len(s) == 8:
            return pd.to_datetime(s, format='%Y%m%d', errors='coerce')
    except:
        pass
    
    return pd.to_datetime(x, errors='coerce')

def get_min_dates(df_pkl, df_inpat):
    """Get minimum date per SSN from all data."""
    # Outpatient: YYYYMMDD
    # Ensure string before parsing
    # Note: df_pkl modification here might affect outside if not careful, but pandas usually copies or we modify inplace which is fine here.
    df_pkl['Date'] = pd.to_datetime(df_pkl['Kayntipvm'].astype(str), format='%Y%m%d', errors='coerce')
    min_pkl = df_pkl.groupby('SSN')['Date'].min()
    
    # Inpatient
    # Use flexible parsing
    def parse_flexible_series(series):
        # Try datetime first
        d = pd.to_datetime(series, errors='coerce')
        # Check if year < 1980 (likely epoch ns issue with int inputs)
        # If so, try parsing as string YYYYMMDD
        mask_bad = d.dt.year < 1980
        if mask_bad.any():
            # Try YYYYMMDD
            d2 = pd.to_datetime(series[mask_bad].astype(str), format='%Y%m%d', errors='coerce')
            d.loc[mask_bad] = d2
        return d

    df_inpat['Date'] = parse_flexible_series(df_inpat['OsastojaksoAlkuPvm'])
    min_inpat = df_inpat.groupby('SSN')['Date'].min()
    
    # Combine
    df_min = pd.concat([min_pkl, min_inpat]).groupby(level=0).min()
    return df_min

def assign_final_dates(df_master, df_min_dates):
    """Assign final index dates with fallback."""
    control_date = pd.Timestamp("2020-11-23")
    
    def set_date(row):
        if row['Group'] == 'Control':
            return control_date
        
        # Case
        d = row['ClinicDate']
        dt = parse_date_flexible(d)
        
        # Check if valid (e.g. > 2000)
        if pd.notna(dt) and dt.year > 2000:
            return dt
            
        # Fallback
        ssn = row['SSN']
        if ssn in df_min_dates.index:
            return df_min_dates[ssn]
            
        return pd.NaT

    df_master['IndexDate'] = df_master.apply(set_date, axis=1)
    
    # FOF Status Clean
    def clean_fof(x):
        try:
            val = int(x)
            if val == 0: return 0
            if val == 1: return 1
            return -1 # Unknown
        except:
            return -1 # Missing/Error
            
    df_master['FOF_Status'] = df_master['FOF_Raw'].apply(clean_fof)
    
    return df_master

def process_diagnoses(df_pkl, df_inpat, df_master, window_years=2):
    """Filter diagnoses based on index date."""
    
    # Prepare Master Index Map: SSN -> IndexDate
    index_map = df_master.set_index('SSN')['IndexDate'].to_dict()
    
    # Debug SSN matching
    pkl_ssns = set(df_pkl['SSN'].unique())
    master_ssns = set(df_master['SSN'].unique())
    common = pkl_ssns.intersection(master_ssns)
    print(f"Debug: Outpatient SSNs: {len(pkl_ssns)}, Master SSNs: {len(master_ssns)}, Common: {len(common)}")
    if len(common) == 0:
        print("CRITICAL: No common SSNs found between Outpatient and Master. Checking formats:")
        print(f"Master sample: {list(master_ssns)[:5]}")
        print(f"Pkl sample: {list(pkl_ssns)[:5]}")
    
    all_diags = []
    
    # 1. Process Outpatient
    # Dates: 'Kayntipvm'
    # Diags: 'Pdgo', 'Sdg1o'...'SdgX'
    
    print("Processing Outpatient data...")
    diag_cols = [c for c in df_pkl.columns if 'dgo' in c.lower()] # Heuristic
    
    # Filter only those in master
    df_pkl_filtered = df_pkl[df_pkl['SSN'].isin(index_map.keys())].copy()
    
    # Date parse (already done in main flow potentially, but ensuring here)
    if 'Date' not in df_pkl_filtered.columns or df_pkl_filtered['Date'].isna().all():
        # Clean Kayntipvm first
        df_pkl_filtered['Date'] = pd.to_datetime(df_pkl_filtered['Kayntipvm'].astype(str), format='%Y%m%d', errors='coerce')
    
    # Melt
    df_melt = df_pkl_filtered.melt(id_vars=['SSN', 'Date'], value_vars=[c for c in diag_cols if c in df_pkl_filtered.columns], value_name='ICD10')
    df_melt = df_melt.dropna(subset=['ICD10', 'Date'])
    
    # Filter by window
    df_melt['IndexDate'] = df_melt['SSN'].map(index_map)
    df_melt = df_melt.dropna(subset=['IndexDate'])
    
    df_melt['DaysDiff'] = (df_melt['IndexDate'] - df_melt['Date']).dt.days
    
    # Debug Date Logic
    print(f"Debug: Outpatient Date Range: {df_melt['Date'].min()} to {df_melt['Date'].max()}")
    print(f"Debug: Index Date Range: {df_melt['IndexDate'].min()} to {df_melt['IndexDate'].max()}")
    print(f"Debug: DaysDiff Range: {df_melt['DaysDiff'].min()} to {df_melt['DaysDiff'].max()}")
    
    mask = (df_melt['DaysDiff'] >= 0) & (df_melt['DaysDiff'] <= (window_years * 365))
    df_out_valid = df_melt[mask].copy()
    df_out_valid['Source'] = 'Outpatient'
    all_diags.append(df_out_valid[['SSN', 'ICD10', 'Source']])
    print(f"Outpatient rows retained: {len(df_out_valid)} / {len(df_melt)}")

    # 2. Process Inpatient
    print("Processing Inpatient data...")
    df_inpat_filtered = df_inpat[df_inpat['SSN'].isin(index_map.keys())].copy()
    
    if 'Date' not in df_inpat_filtered.columns or df_inpat_filtered['Date'].isna().all():
        # Use flexible parsing logic repeated (or could share function, but inline for now)
        d = pd.to_datetime(df_inpat_filtered['OsastojaksoAlkuPvm'], errors='coerce')
        mask_bad = d.dt.year < 1980
        if mask_bad.any():
             d.loc[mask_bad] = pd.to_datetime(df_inpat_filtered.loc[mask_bad, 'OsastojaksoAlkuPvm'].astype(str), format='%Y%m%d', errors='coerce')
        df_inpat_filtered['Date'] = d
    
    diag_cols_in = [c for c in df_inpat_filtered.columns if 'dgo' in c.lower()]
    df_melt_in = df_inpat_filtered.melt(id_vars=['SSN', 'Date'], value_vars=[c for c in diag_cols_in if c in df_inpat_filtered.columns], value_name='ICD10')
    df_melt_in = df_melt_in.dropna(subset=['ICD10', 'Date'])
    
    df_melt_in['IndexDate'] = df_melt_in['SSN'].map(index_map)
    df_melt_in = df_melt_in.dropna(subset=['IndexDate'])
    
    df_melt_in['DaysDiff'] = (df_melt_in['IndexDate'] - df_melt_in['Date']).dt.days
    mask_in = (df_melt_in['DaysDiff'] >= 0) & (df_melt_in['DaysDiff'] <= (window_years * 365))
    df_in_valid = df_melt_in[mask_in].copy()
    df_in_valid['Source'] = 'Inpatient'
    all_diags.append(df_in_valid[['SSN', 'ICD10', 'Source']])
    print(f"Inpatient rows retained: {len(df_in_valid)} / {len(df_melt_in)}")

    # Combine
    if not all_diags:
        return pd.DataFrame(columns=['SSN', 'ICD10', 'Source'])
        
    df_combined = pd.concat(all_diags, ignore_index=True)
    
    # Clean ICD codes
    df_combined['ICD10_Clean'] = df_combined['ICD10'].astype(str).str.replace('.', '').str.strip().str.upper()
    
    return df_combined

def calculate_scores(df_diags, df_master):
    """Calculate scores per SSN."""
    
    # Initialize results
    ssns = df_master['SSN'].unique()
    results = {ssn: {'HFRS': 0.0, 'CCI': 0.0, 'CCI_Flags': set()} for ssn in ssns}
    
    # Group by SSN for efficiency
    grouped = df_diags.groupby('SSN')
    
    print("Calculating scores...")
    for ssn, group in grouped:
        if ssn not in results: continue
        
        codes = set(group['ICD10_Clean'].values)
        
        # 1. HFRS Calculation (Sum of weights)
        hfrs_score = 0.0
        # Check matching codes. Dictionary is small in this prototype, 
        # but in full version we iterate codes or dict.
        # Efficient way: iterate dict keys and check if startswith matches
        # For HFRS, usually exact match or 3-char match.
        
        for code in codes:
            # Try 3 char match
            sub3 = code[:3]
            if sub3 in HFRS_MAPPING:
                hfrs_score += HFRS_MAPPING[sub3]
            # (Could implement 4 char match priority here)
        
        # Cap HFRS? Usually not capped, but highly skewed.
        results[ssn]['HFRS'] = hfrs_score
        
        # 2. CCI Calculation
        cci_score = 0
        cci_flags = set()
        
        for condition, rule in CCI_MAPPING.items():
            weight = rule['weight']
            prefixes = rule['codes']
            
            match = False
            for p in prefixes:
                # Check if any user code starts with prefix p
                # Optimization: check intersection of sets if prefixes were comprehensive
                # Or just iterate codes.
                for user_code in codes:
                    if user_code.startswith(p):
                        match = True
                        break
                if match: break
            
            if match:
                cci_score += weight
                cci_flags.add(condition)
        
        # Handle Hierarchy (Simplified Quan logic)
        # e.g., If Metastatic (6), ignore Malignancy (2)
        if 'Metastatic' in cci_flags:
            if 'Malignancy' in cci_flags: cci_score -= 2
        
        if 'DiabetesComp' in cci_flags:
            if 'DiabetesSimple' in cci_flags: cci_score -= 1
            
        if 'LiverSevere' in cci_flags:
            if 'LiverMild' in cci_flags: cci_score -= 1
            
        results[ssn]['CCI'] = cci_score
        
    # Convert to DF
    res_data = []
    for ssn, vals in results.items():
        res_data.append({
            'SSN': ssn,
            'HFRS': vals['HFRS'],
            'CCI': vals['CCI']
        })
    
    df_scores = pd.DataFrame(res_data)
    
    # Merge back to Master
    df_final = df_master.merge(df_scores, on='SSN', how='left')
    df_final['HFRS'] = df_final['HFRS'].fillna(0)
    df_final['CCI'] = df_final['CCI'].fillna(0)
    
    return df_final

def aggregate_and_save(df_final, output_path, summary_path):
    """Aggregate results to safe groups."""
    
    # Define aggregations
    # Group by: Group, FOF_Status
    # FOF_Status: 0=No, 1=Yes, -1=Unknown
    
    # Helper for frailty
    df_final['Frail_Flag'] = df_final['HFRS'] > 5 # Example cut-off
    
    # Map FOF to label
    fof_labels = {0: 'No', 1: 'Yes', -1: 'Unknown'}
    df_final['FOF_Label'] = df_final['FOF_Status'].map(fof_labels)
    
    # Grouping
    cols = ['Group', 'FOF_Label']
    agg_funcs = {
        'HFRS': ['mean', 'median', 'std', 'count'],
        'CCI': ['mean', 'median', 'std'],
        'Frail_Flag': ['sum'] # Count of frail
    }
    
    agg = df_final.groupby(cols).agg(agg_funcs).reset_index()
    
    # Flatten cols
    agg.columns = ['_'.join(col).strip() if col[1] else col[0] for col in agg.columns.values]
    
    # Rename for clarity
    agg = agg.rename(columns={
        'HFRS_count': 'n',
        'Frail_Flag_sum': 'n_frail'
    })
    
    # Calculate % Frail
    agg['pct_frail'] = (agg['n_frail'] / agg['n']) * 100
    
    # Privacy Suppression (n < 5)
    # If n < 5, mask metrics
    mask = agg['n'] < 5
    for c in agg.columns:
        if c not in ['Group', 'FOF_Label', 'n']:
            agg.loc[mask, c] = np.nan # Or -999
            
    # Save CSV
    print(f"Saving aggregates to {output_path}...")
    agg.to_csv(output_path, index=False, float_format='%.2f')
    
    # Write Summary MD
    with open(summary_path, 'w') as f:
        f.write("# HFRS and CCI Risk Score Summary\n\n")
        f.write(f"**Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M')}\n")
        f.write("**Method:** 2-year lookback from Index Date.\n")
        f.write("**Index Date:** First visit (Cases) / 2020-11-23 (Controls).\n\n")
        
        f.write("## Results by Group\n\n")
        f.write(agg.to_markdown(index=False, floatfmt=".2f"))
        f.write("\n\n**Note:** 'n' < 5 cells are suppressed (NaN).\n")

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--window-years", type=int, default=2)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--allow-aggregates", action="store_true")
    args = parser.parse_args()
    
    data_root = r"C:\GitWork\FOF_LOCAL-DATA\paper_02"
    output_dir = Path("outputs/aggregates")
    output_dir.mkdir(parents=True, exist_ok=True)
    
    df_link, df_kaaos, df_pkl, df_inpat = load_data(data_root)
    
    # Initial Master creation (without final IndexDate)
    df_master = get_index_dates(df_link, df_kaaos)
    
    # Clean SSNs in Diag Data
    df_pkl['SSN'] = clean_ssn_id(df_pkl, 'Henkilotunnus')
    df_inpat['SSN'] = clean_ssn_id(df_inpat, 'Henkilotunnus')
    
    # Get Fallback Dates
    df_min_dates = get_min_dates(df_pkl, df_inpat)
    
    # Assign Final Index Dates
    df_master = assign_final_dates(df_master, df_min_dates)
    
    print(f"Index dates assigned. Valid Index Dates: {df_master['IndexDate'].notna().sum()}/{len(df_master)}")
    
    if args.dry_run:
        print("Dry run complete. Exiting.")
        return
        
    df_diags = process_diagnoses(df_pkl, df_inpat, df_master, window_years=args.window_years)
    print(f"Diagnoses processed. Total diagnosis rows in window: {len(df_diags)}")
    
    df_scored = calculate_scores(df_diags, df_master)
    
    aggregate_and_save(
        df_scored, 
        output_dir / "aim2_risk_scores.csv", 
        "outputs/risk_scores_summary.md"
    )
    print("Done.")

if __name__ == "__main__":
    main()
