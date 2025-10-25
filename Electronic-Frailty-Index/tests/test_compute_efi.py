import pandas as pd
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
    assert 0.0 <= out["efi_score"].min() <= 1.0
    assert 0.0 <= out["efi_score"].max() <= 1.0

