import pandas as pd
import numpy as np
import os
import random

# Config
DATA_ROOT = os.environ.get("DATA_ROOT", "data_root_test")
RAW_DIR = os.path.join(DATA_ROOT, "raw", "paper_02")
os.makedirs(RAW_DIR, exist_ok=True)

def generate_kaaos():
    n_rows = 100
    df = pd.DataFrame({
        'nro': range(1, n_rows + 1),
        'kaatumisen pelko (0= ei pelkää, 1= pelkää, 2= ei tietoa)': np.random.choice([0, 1, 2], size=n_rows, p=[0.4, 0.4, 0.2]),
        'ikä (a)': np.random.randint(65, 95, size=n_rows),
        'sukupuoli (0= nainen, 1= mies)': np.random.choice([1, 2], size=n_rows), # 1=Male, 2=Female
        'BMI (kg/m^2)': np.random.normal(25, 4, size=n_rows),
        'vastaan-otto pvm': pd.date_range(start='2020-01-01', periods=n_rows, freq='D')
    })

    # Add some other columns to match patterns
    df['tupakointi'] = np.random.choice([0, 1], size=n_rows)
    df['diabetes'] = np.random.choice([0, 1], size=n_rows)

    output_path = os.path.join(RAW_DIR, "KAAOS_data_sotullinen.xlsx")
    df.to_excel(output_path, index=False)
    print(f"Generated {output_path}")

def generate_sotut():
    n_rows = 100
    df = pd.DataFrame({
        'NRO': range(1, n_rows + 1),
        'Sotu': [f"SOTU_{i}" for i in range(1, n_rows + 1)]
    })
    output_path = os.path.join(RAW_DIR, "sotut.xlsx")
    df.to_excel(output_path, index=False)
    print(f"Generated {output_path}")

def generate_panel():
    # Generate derived panel for frailty lookup
    DERIVED_DIR = os.path.join(DATA_ROOT, "derived")
    os.makedirs(DERIVED_DIR, exist_ok=True)

    n_rows = 100
    df = pd.DataFrame({
        'id': [f"SOTU_{i}" for i in range(1, n_rows + 1)],
        'frailty_fried': np.random.choice(["robust", "pre-frail", "frail"], size=n_rows)
    })
    output_path = os.path.join(DERIVED_DIR, "aim2_panel.csv")
    df.to_csv(output_path, index=False)
    print(f"Generated {output_path}")

if __name__ == "__main__":
    generate_kaaos()
    generate_sotut()
    generate_panel()
