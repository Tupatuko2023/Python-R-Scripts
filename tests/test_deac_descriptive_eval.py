from pathlib import Path
import sys

import pytest


SRC_DIR = Path(__file__).resolve().parents[1] / "DEAC-Frailty-Index" / "src"
sys.path.insert(0, str(SRC_DIR))

from deac_descriptive_eval import _annual_component_missingness_rows  # noqa: E402
from deac_index import COMPONENT_NAMES  # noqa: E402


def test_annual_component_missingness_uses_verified_year_and_coverage_group():
    component = COMPONENT_NAMES[0]
    rows = [
        {
            **dict.fromkeys(COMPONENT_NAMES, ""),
            "participant_key": "synthetic-a",
            "eligible": "True",
        },
        {
            **dict.fromkeys(COMPONENT_NAMES, ""),
            "participant_key": "synthetic-b",
            "eligible": "False",
            component: "0",
        },
    ]
    years = {"synthetic-a": 2015, "synthetic-b": 2016}

    result = _annual_component_missingness_rows(rows, years)

    observed = {
        (row["group"], row["clinic_visit_year"]): (
            row["people"], row["observed"], row["missing"], row["missing_percent"]
        )
        for row in result
        if row["component"] == component
    }
    assert observed == {
        ("cohort", 2015): (1, 0, 1, 1.0),
        ("cohort", 2016): (1, 1, 0, 0.0),
        ("index_calculable", 2015): (1, 0, 1, 1.0),
        ("below_coverage", 2016): (1, 1, 0, 0.0),
    }


def test_annual_component_missingness_fails_when_verified_year_is_missing():
    row = {
        **dict.fromkeys(COMPONENT_NAMES, ""),
        "participant_key": "synthetic-a",
        "eligible": "True",
    }
    with pytest.raises(ValueError, match="Clinic year is unavailable"):
        _annual_component_missingness_rows([row], {})
