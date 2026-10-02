"""Synthetic-only tests for configurable DEAC source normalization."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest


SRC_DIR = Path(__file__).resolve().parents[1] / "DEAC-Frailty-Index" / "src"
sys.path.insert(0, str(SRC_DIR))

import deac_source_adapter as adapter  # noqa: E402
from deac_components import UnresolvedNeurologicalInput  # noqa: E402
from deac_index import COMPONENT_NAMES, ComponentStatus  # noqa: E402


LOGICAL_FIELDS = {
    "diabetes",
    "alzheimer",
    "parkinson",
    "stroke_avh",
    "self_rated_health",
    "moi_total",
    "baseline_age_years",
    "alcohol",
    "hearing",
    "vision",
    "memory",
    "mood",
    "sleep",
    "self_rated_mobility",
    "walking_500m",
    "balance_difficulty",
    "previous_fall",
    "fear_of_falling",
    "pain_vas_cm",
    "better_leg_stance_seconds",
    "five_chair_rises_seconds",
    "better_hand_grip_class",
    "selected_max_10m_seconds",
}


def synthetic_fixture() -> tuple[dict[str, object], adapter.SourceBindings]:
    columns = {field: f"synthetic_{field}" for field in LOGICAL_FIELDS}
    row: dict[str, object] = {
        columns[field]: 0 for field in LOGICAL_FIELDS
    }
    row[columns["moi_total"]] = 2
    row[columns["baseline_age_years"]] = 60
    row[columns["hearing"]] = 3
    row[columns["vision"]] = 4
    row[columns["pain_vas_cm"]] = 4.0
    row[columns["better_leg_stance_seconds"]] = 4.99
    row[columns["five_chair_rises_seconds"]] = 11.20
    row[columns["better_hand_grip_class"]] = 2
    row[columns["selected_max_10m_seconds"]] = 8.0
    return row, adapter.SourceBindings(columns=columns)


def test_synthetic_row_normalizes_to_twenty_slots_and_assembles() -> None:
    row, bindings = synthetic_fixture()
    scores = adapter.score_source_row(row, bindings, (1, 2, 3, 4))

    assert tuple(scores) == COMPONENT_NAMES
    assert scores["moi"] == 0.0
    assert scores["hearing"] == 1.0
    assert scores["vision"] is None
    assert scores["pain_vas"] == 0.5
    assert scores["single_leg_stance"] == 1.0
    assert scores["five_chair_rises"] == 0.25
    assert scores["grip_strength"] == 0.6
    assert scores["maximal_10m_gait_speed"] == 0.0  # 10 / 8 s = 1.25 m/s
    assert adapter.calculate_deac_from_source_row(row, bindings, (1, 2, 3, 4)) == pytest.approx(
        sum(value for value in scores.values() if isinstance(value, (int, float))) / 19
    )


def test_moi_age_is_removed_once_before_supplied_quintile_scoring() -> None:
    row, bindings = synthetic_fixture()
    row[bindings.columns["moi_total"]] = 4
    row[bindings.columns["baseline_age_years"]] = 60

    assert adapter.score_source_row(row, bindings, (1, 2, 3, 4))["moi"] == 0.25


def test_source_missing_codes_are_field_specific() -> None:
    row, bindings = synthetic_fixture()
    row[bindings.columns["pain_vas_cm"]] = "synthetic_missing"
    bindings = adapter.SourceBindings(
        columns=bindings.columns,
        ordinary_missing_codes={"pain_vas_cm": ("synthetic_missing",)},
    )
    assert adapter.score_source_row(row, bindings, (1, 2, 3, 4))["pain_vas"] is None


def test_performance_codes_are_test_specific_and_keep_three_states_distinct() -> None:
    row, bindings = synthetic_fixture()
    synthetic_code = "synthetic_code_a"
    row[bindings.columns["better_leg_stance_seconds"]] = synthetic_code
    row[bindings.columns["five_chair_rises_seconds"]] = synthetic_code
    row[bindings.columns["better_hand_grip_class"]] = "synthetic_code_b"
    bindings = adapter.SourceBindings(
        columns=bindings.columns,
        performance_codes={
            "better_leg_stance_seconds": {
                synthetic_code: adapter.PerformanceDisposition.OTHER_NONPERFORMANCE
            },
            "five_chair_rises_seconds": {
                synthetic_code: adapter.PerformanceDisposition.FUNCTIONAL_INABILITY
            },
            "better_hand_grip_class": {
                "synthetic_code_b": adapter.PerformanceDisposition.NOT_APPLICABLE
            },
        },
    )

    scores = adapter.score_source_row(row, bindings, (1, 2, 3, 4))
    assert scores["single_leg_stance"] is None
    assert scores["five_chair_rises"] == 1.0
    assert scores["grip_strength"] is ComponentStatus.NOT_APPLICABLE


@pytest.mark.parametrize(
    "logical_field",
    [
        "better_leg_stance_seconds",
        "five_chair_rises_seconds",
        "better_hand_grip_class",
        "selected_max_10m_seconds",
    ],
)
def test_unmapped_test_code_fails_closed(logical_field: str) -> None:
    row, bindings = synthetic_fixture()
    row[bindings.columns[logical_field]] = "synthetic_unmapped_code"

    with pytest.raises(adapter.UnresolvedSourceCodeError):
        adapter.score_source_row(row, bindings, (1, 2, 3, 4))


def test_gait_time_must_be_positive_and_selection_is_upstream() -> None:
    row, bindings = synthetic_fixture()
    row[bindings.columns["selected_max_10m_seconds"]] = 0
    with pytest.raises(ValueError, match="positive seconds"):
        adapter.score_source_row(row, bindings, (1, 2, 3, 4))

    columns = dict(bindings.columns)
    columns["maximal_10m_speed_m_per_second"] = "synthetic_speed"
    invalid_bindings = adapter.SourceBindings(columns=columns)
    with pytest.raises(ValueError, match="exactly one"):
        adapter.score_source_row(row, invalid_bindings, (1, 2, 3, 4))


def test_bound_column_and_all_required_fields_are_mandatory() -> None:
    row, bindings = synthetic_fixture()
    incomplete = dict(bindings.columns)
    del incomplete["better_hand_grip_class"]
    with pytest.raises(ValueError, match="semantic fields"):
        adapter.score_source_row(row, adapter.SourceBindings(columns=incomplete), (1, 2, 3, 4))

    del row[bindings.columns["diabetes"]]
    with pytest.raises(ValueError, match="column is missing"):
        adapter.score_source_row(row, bindings, (1, 2, 3, 4))


def test_partial_neurological_input_remains_unresolved() -> None:
    row, bindings = synthetic_fixture()
    row[bindings.columns["parkinson"]] = None
    with pytest.raises(UnresolvedNeurologicalInput):
        adapter.score_source_row(row, bindings, (1, 2, 3, 4))
