import os
import pandas as pd
from pathlib import Path
from subprocess import run, CalledProcessError

def test_cli_produces_scores(tmp_path):
    # Input
    inp = tmp_path / "synthetic.csv"
    inp.write_text(
        "id,age,sex,def_hypertension,def_diabetes\n"
        "P001,72,F,1,0\nP002,81,M,0,1\n",
        encoding="utf-8",
    )
    out = tmp_path / "scores.csv"
    # Run
    r = run(
        ["python", "src/efi/cli.py", "--input", str(inp), "--out", str(out)],
        capture_output=True,
        text=True,
    )
    assert r.returncode == 0, r.stderr
    assert out.exists()
    df = pd.read_csv(out)
    assert set(df.columns) == {"id", "efi_score"}
    assert len(df) == 2
