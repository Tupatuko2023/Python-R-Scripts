import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "DEAC-Frailty-Index" / "src"))

from deac_run import _resolve_identifier_position


def test_identifier_position_resolves_exact_unique_header():
    assert _resolve_identifier_position("record key", ("name", "Record Key"), 2) == 2


def test_identifier_position_rejects_ambiguous_or_misaligned_header():
    with pytest.raises(ValueError):
        _resolve_identifier_position("record key", ("Record Key", "record key"), 1)
    with pytest.raises(ValueError):
        _resolve_identifier_position("record key", ("other", "Record Key"), 1)
