import pandas as pd
import numpy as np
import os

# Config

OUTPUT_DIR = 'data/sample'
OUTPUT_FILE = 'synthetic_sample.csv'
N_ROWS = 100
SEED = 42

def generate_synthetic():
    np.random.seed(SEED)
    df = pd.DataFrame({
        'id': range(1, N_ROWS + 1),
        'FOF_status': np.random.choice([0, 1], size=N_ROWS, p=[0.7, 0.3]),
        'util_visits_total': np.random.poisson(lam=2, size=N_ROWS),
        'cost_total_eur': np.round(np.random.gamma(shape=2, scale=100, size=N_ROWS), 2)
    })
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    path = os.path.join(OUTPUT_DIR, OUTPUT_FILE)
    df.to_csv(path, index=False)
    print(f"Generated {path} with {len(df)} rows.")

if __name__ == "__main__":
    generate_synthetic()
