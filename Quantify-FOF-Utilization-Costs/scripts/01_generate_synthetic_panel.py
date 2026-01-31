import pandas as pd
import numpy as np
import os

# Config
OUTPUT_DIR = 'data/sample'
OUTPUT_FILE = 'aim2_panel.csv'
N_PEOPLE = 100
N_PERIODS = 2  # Longitudinal
SEED = 42

def generate_synthetic_panel():
    np.random.seed(SEED)
    
    data = []
    for pid in range(1, N_PEOPLE + 1):
        fof = np.random.choice([0, 1], p=[0.7, 0.3])
        age = np.random.randint(65, 95)
        sex = np.random.choice([1, 2]) # 1=M, 2=F
        frailty = np.random.randint(0, 6)
        
        for period in range(1, N_PERIODS + 1):
            # Poisson lambda depends on FOF and age
            lam = 1.5 + 1.0 * fof + 0.05 * (age - 65)
            visits_total = np.random.poisson(lam=lam)
            visits_out = int(visits_total * 0.8)
            visits_in = visits_total - visits_out
            
            # Cost depends on visits
            cost_total = visits_total * 60.0 + np.random.normal(0, 10)
            cost_total = max(0, round(cost_total, 2))
            cost_out = round(cost_total * 0.6, 2)
            cost_in = round(cost_total * 0.4, 2)
            
            data.append({
                'id': str(pid),
                'FOF_status': fof,
                'age': age,
                'sex': sex,
                'period': period,
                'person_time': 1.0, # 1 year
                'frailty_fried': frailty,
                'util_visits_total': visits_total,
                'util_visits_outpatient': visits_out,
                'util_visits_inpatient': visits_in,
                'cost_total_eur': cost_total,
                'cost_outpatient_eur': cost_out,
                'cost_inpatient_eur': cost_in
            })
            
    df = pd.DataFrame(data)
    
    # We want to place it in a location that looks like a DATA_ROOT/derived
    # Let's use a temporary DATA_ROOT
    data_root = os.path.abspath('data/sample/DATA_ROOT_MOCK')
    derived_dir = os.path.join(data_root, 'derived')
    os.makedirs(derived_dir, exist_ok=True)
    
    path = os.path.join(derived_dir, OUTPUT_FILE)
    df.to_csv(path, index=False)
    print(f"Generated {path} with {len(df)} rows.")
    print(f"Set your environment: export DATA_ROOT={data_root}")

if __name__ == "__main__":
    generate_synthetic_panel()
