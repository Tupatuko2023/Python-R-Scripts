﻿import pandas as pd
from efi.cli import compute_efi

def test_compute_efi_basic():
    df = pd.DataFrame({
        "id": [1, 2],
        "age": [80, 40],
        "def_a": [1, 0],
        "def_b": [1, 1],
    })
    out = compute_efi(df, min_deficits=1)
    assert list(out.columns) == ["id", "efi_score"]
    assert len(out) == 2
    # Row 1: 2 deficits (def_a=1, def_b=1) / 2 columns = 1.0
    # Row 2: 1 deficit (def_b=1) / 2 columns = 0.5
    assert out.loc[out["id"] == 1, "efi_score"].values[0] == 1.0
    assert out.loc[out["id"] == 2, "efi_score"].values[0] == 0.5

