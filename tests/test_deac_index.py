"""Synthetic checks for the pure, 20-slot DEAC index assembler."""

import importlib.util
from pathlib import Path

import pytest


MODULE_PATH = (
    Path(__file__).resolve().parents[1] / "DEAC-Frailty-Index" / "src" / "deac_index.py"
)
MODULE_SPEC = importlib.util.spec_from_file_location("deac_index", MODULE_PATH)
assert MODULE_SPEC is not None and MODULE_SPEC.loader is not None
deac = importlib.util.module_from_spec(MODULE_SPEC)
MODULE_SPEC.loader.exec_module(deac)


@pytest.fixture
def zeros() -> dict[str, float | None | deac.ComponentStatus]:
    return dict.fromkeys(deac.COMPONENT_NAMES, 0.0)


def test_exactly_twenty_approved_names_include_moi(zeros: dict[str, object]) -> None:
    assert len(zeros) == 20
    assert "moi" in zeros
    assert deac.assemble_deac_index(zeros) == 0.0


def test_full_coverage_and_observed_mean(zeros: dict[str, object]) -> None:
    assert deac.assemble_deac_index(dict.fromkeys(zeros, 1.0)) == 1.0
    zeros["moi"] = 1.0
    zeros["pain_vas"] = 0.5
    assert deac.assemble_deac_index(zeros) == pytest.approx(1.5 / 20)


def test_ordinary_missing_stays_relevant_but_leaves_denominator(
    zeros: dict[str, object],
) -> None:
    zeros["moi"] = None
    zeros["pain_vas"] = 1.0
    assert deac.assemble_deac_index(zeros) == pytest.approx(1 / 19)


@pytest.mark.parametrize("observed_count", [16, 15])
def test_coverage_boundary_for_twenty_relevant_slots(
    zeros: dict[str, object], observed_count: int
) -> None:
    for name in deac.COMPONENT_NAMES[observed_count:]:
        zeros[name] = None
    zeros["diabetes"] = 1.0
    expected = 1 / 16 if observed_count == 16 else None
    assert deac.assemble_deac_index(zeros) == expected


@pytest.mark.parametrize("observed_count", [16, 15])
def test_not_applicable_changes_relevant_coverage_only(
    zeros: dict[str, object], observed_count: int
) -> None:
    zeros["grip_strength"] = deac.ComponentStatus.NOT_APPLICABLE
    for name in [name for name in deac.COMPONENT_NAMES if name != "grip_strength"][observed_count:]:
        zeros[name] = None
    zeros["diabetes"] = 1.0
    expected = 1 / 16 if observed_count == 16 else None
    assert deac.assemble_deac_index(zeros) == expected


def test_no_relevant_components_fails_closed(zeros: dict[str, object]) -> None:
    with pytest.raises(ValueError, match="at least one relevant"):
        deac.assemble_deac_index(
            dict.fromkeys(zeros, deac.ComponentStatus.NOT_APPLICABLE)
        )


def test_missing_or_extra_component_name_fails_closed(zeros: dict[str, object]) -> None:
    del zeros["moi"]
    with pytest.raises(ValueError, match="exactly the 20"):
        deac.assemble_deac_index(zeros)
    zeros["unapproved_component"] = 0.0
    with pytest.raises(ValueError, match="exactly the 20"):
        deac.assemble_deac_index(zeros)


@pytest.mark.parametrize(
    "invalid", [-0.01, 1.01, True, "unknown", float("nan"), float("inf"), 10**400]
)
def test_invalid_score_fails_closed(zeros: dict[str, object], invalid: object) -> None:
    zeros["moi"] = invalid
    with pytest.raises(ValueError, match="Invalid normalized deficit score"):
        deac.assemble_deac_index(zeros)


def test_invalid_score_is_checked_even_when_coverage_is_insufficient(
    zeros: dict[str, object],
) -> None:
    for name in deac.COMPONENT_NAMES[15:]:
        zeros[name] = None
    zeros["diabetes"] = 2.0
    with pytest.raises(ValueError, match="Invalid normalized deficit score"):
        deac.assemble_deac_index(zeros)
