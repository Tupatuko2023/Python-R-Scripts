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


@pytest.mark.parametrize(
    "missing_alias",
    ["synthetic_vas_unknown_a", "synthetic_vas_unknown_b"],
)
def test_vas_non_numeric_missing_aliases_are_unscored(missing_alias: str) -> None:
    row, bindings = synthetic_fixture()
    row[bindings.columns["pain_vas_cm"]] = missing_alias
    bindings = adapter.SourceBindings(
        columns=bindings.columns,
        ordinary_missing_codes={
            "pain_vas_cm": (
                "synthetic_vas_unknown_a",
                "synthetic_vas_unknown_b",
            )
        },
    )

    assert adapter.score_source_row(row, bindings, (1, 2, 3, 4))["pain_vas"] is None


def test_vas_centimeter_value_is_passed_without_unit_conversion() -> None:
    row, bindings = synthetic_fixture()
    centimetres = 4.25
    row[bindings.columns["pain_vas_cm"]] = centimetres

    assert adapter.normalize_pain_vas_cm(centimetres) is centimetres
    assert adapter.score_source_row(row, bindings, (1, 2, 3, 4))["pain_vas"] == 0.5


@pytest.mark.parametrize(
    ("selected_field", "side_fields"),
    [
        ("better_leg_stance_seconds", ("synthetic_right_stance", "synthetic_left_stance")),
        ("better_hand_grip_class", ("synthetic_right_grip", "synthetic_left_grip")),
    ],
)
def test_unselected_sided_measurements_fail_closed(
    selected_field: str, side_fields: tuple[str, str]
) -> None:
    row, bindings = synthetic_fixture()
    columns = dict(bindings.columns)
    del columns[selected_field]
    for side_field in side_fields:
        columns[side_field] = side_field
        row[side_field] = 2

    with pytest.raises(ValueError, match="semantic fields"):
        adapter.score_source_row(
            row, adapter.SourceBindings(columns=columns), (1, 2, 3, 4)
        )


def test_selected_test_measurement_passes_through_without_selection() -> None:
    seconds = 7.25
    assert (
        adapter.normalize_preselected_test_value(
            seconds, {}, "five_chair_rises_seconds"
        )
        is seconds
    )


def test_preselected_test_inability_without_reason_is_missing() -> None:
    result = adapter.normalize_preselected_test_value(
        "synthetic_E",
        {"synthetic_E": adapter.PerformanceDisposition.FUNCTIONAL_INABILITY},
        "five_chair_rises_seconds",
    )
    assert result is None


def test_performance_codes_are_test_specific_and_keep_three_states_distinct() -> None:
    row, bindings = synthetic_fixture()
    synthetic_code = "synthetic_code_a"
    row[bindings.columns["better_leg_stance_seconds"]] = synthetic_code
    row[bindings.columns["five_chair_rises_seconds"]] = synthetic_code
    row[bindings.columns["better_hand_grip_class"]] = "synthetic_code_b"
    reason_header = "synthetic_chair_reason"
    row[reason_header] = "synthetic_verified_functional_reason"
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
        reason_columns={"five_chair_rises_seconds": reason_header},
        verified_functional_inability_codes={
            "five_chair_rises_seconds": ("synthetic_verified_functional_reason",)
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


def test_protected_schema_guard_accepts_unique_verified_header_label_pairs() -> None:
    checked = adapter.validate_source_schema_bindings(
        "a" * 64,
        "A" * 64,
        ("1", "2", "2"),
        ("synthetic age", "synthetic MOI", "synthetic gait"),
        {"age": 0, "moi": 1, "gait": 2},
    )

    assert checked == 3


def test_schema_guard_uses_the_header_label_pair_when_headers_are_blank() -> None:
    checked = adapter.validate_source_schema_bindings(
        "a" * 64,
        "a" * 64,
        ("", ""),
        ("synthetic first label", "synthetic second label"),
        {"first": 0, "second": 1},
    )

    assert checked == 2


def test_schema_guard_accepts_same_cell_multiline_semantic_heading() -> None:
    checked = adapter.validate_source_schema_bindings(
        "a" * 64,
        "a" * 64,
        ("5",),
        ("Synthetic age\r\n(years)\r\n0=example",),
        {"baseline_age_years": 0},
        semantic_prefixes={"baseline_age_years": "Synthetic age (years)"},
    )

    assert checked == 1


def test_schema_guard_rejects_multiline_heading_at_wrong_semantic_position() -> None:
    with pytest.raises(adapter.SourceSchemaError, match="semantic source heading"):
        adapter.validate_source_schema_bindings(
            "a" * 64,
            "a" * 64,
            ("5",),
            ("Synthetic visit\r\n(months)\r\n0=example",),
            {"baseline_age_years": 0},
            semantic_prefixes={"baseline_age_years": "Synthetic age (years)"},
        )


@pytest.mark.parametrize(
    ("headers", "labels", "positions", "expected_error"),
    [
        (("1", "1"), ("same", "same"), {"age": 0, "moi": 1}, "pairs are not unique"),
        (("1", "2"), ("age", "moi"), {"age": 0, "moi": 2}, "outside the schema"),
        (("1", "2"), ("age", "moi"), {"age": 0, "moi": 0}, "duplicate columns"),
    ],
)
def test_protected_schema_guard_fails_before_row_access(
    headers: tuple[str, ...],
    labels: tuple[str, ...],
    positions: dict[str, int],
    expected_error: str,
) -> None:
    with pytest.raises(adapter.SourceSchemaError, match=expected_error):
        adapter.validate_source_schema_bindings(
            "a" * 64,
            "a" * 64,
            headers,
            labels,
            positions,
        )


def test_protected_schema_guard_rejects_wrong_workbook_hash() -> None:
    with pytest.raises(adapter.SourceSchemaError, match="fingerprint does not match"):
        adapter.validate_source_schema_bindings(
            "a" * 64,
            "b" * 64,
            ("1",),
            ("synthetic field",),
            {"field": 0},
        )


def _bind_sides(
    row: dict[str, object],
    bindings: adapter.SourceBindings,
    selected_field: str,
    side_fields: tuple[str, str],
    side_values: tuple[object, object],
) -> tuple[dict[str, object], adapter.SourceBindings]:
    columns = dict(bindings.columns)
    del columns[selected_field]
    for field_name, value in zip(side_fields, side_values, strict=True):
        header = f"synthetic_{field_name}"
        columns[field_name] = header
        row[header] = value
    return row, adapter.SourceBindings(columns=columns)


@pytest.mark.parametrize(
    ("field", "side_fields", "values", "expected"),
    [
        (
            "better_leg_stance_seconds",
            ("right_leg_stance_seconds", "left_leg_stance_seconds"),
            (4.0, None),
            1.0,
        ),
        (
            "better_leg_stance_seconds",
            ("right_leg_stance_seconds", "left_leg_stance_seconds"),
            (4.0, 8.0),
            0.5,
        ),
        (
            "better_hand_grip_class",
            ("right_hand_grip_class", "left_hand_grip_class"),
            (0, None),
            1.0,
        ),
        (
            "better_hand_grip_class",
            ("right_hand_grip_class", "left_hand_grip_class"),
            (0, 4),
            0.2,
        ),
    ],
)
def test_sided_measurements_select_the_only_or_better_numeric_result(
    field: str,
    side_fields: tuple[str, str],
    values: tuple[object, object],
    expected: float,
) -> None:
    row, bindings = synthetic_fixture()
    row, sided = _bind_sides(row, bindings, field, side_fields, values)

    result = adapter.score_source_row(row, sided, (1, 2, 3, 4))
    component = "single_leg_stance" if "leg" in field else "grip_strength"
    assert result[component] == expected


def test_grip_class_zero_is_valid_and_configured_invalid_code_is_missing() -> None:
    row, bindings = synthetic_fixture()
    row, sided = _bind_sides(
        row,
        bindings,
        "better_hand_grip_class",
        ("right_hand_grip_class", "left_hand_grip_class"),
        (0, None),
    )
    result = adapter.score_source_row(row, sided, (1, 2, 3, 4))
    assert result["grip_strength"] == 1.0

    synthetic_invalid_code = 99
    row, sided = _bind_sides(
        row,
        bindings,
        "better_hand_grip_class",
        ("right_hand_grip_class", "left_hand_grip_class"),
        (synthetic_invalid_code, None),
    )
    configured = adapter.SourceBindings(
        columns=sided.columns,
        invalid_codes_as_missing={
            "right_hand_grip_class": (synthetic_invalid_code,),
        },
    )
    result = adapter.score_source_row(row, configured, (1, 2, 3, 4))
    assert result["grip_strength"] is None

    with pytest.raises(ValueError):
        adapter.score_source_row(row, sided, (1, 2, 3, 4))


def test_valid_grip_classes_cannot_be_configured_as_missing() -> None:
    row, bindings = synthetic_fixture()
    row, sided = _bind_sides(
        row,
        bindings,
        "better_hand_grip_class",
        ("right_hand_grip_class", "left_hand_grip_class"),
        (0, None),
    )
    invalid_configuration = adapter.SourceBindings(
        columns=sided.columns,
        invalid_codes_as_missing={"right_hand_grip_class": (0,)},
    )

    with pytest.raises(ValueError, match="valid grip class"):
        adapter.score_source_row(row, invalid_configuration, (1, 2, 3, 4))

    string_zero_configuration = adapter.SourceBindings(
        columns=sided.columns,
        invalid_codes_as_missing={"right_hand_grip_class": ("0",)},
    )
    with pytest.raises(ValueError, match="valid grip class"):
        adapter.score_source_row(row, string_zero_configuration, (1, 2, 3, 4))


def test_measured_side_wins_over_unverified_e_or_e1_code() -> None:
    row, bindings = synthetic_fixture()
    row, sided = _bind_sides(
        row,
        bindings,
        "better_leg_stance_seconds",
        ("right_leg_stance_seconds", "left_leg_stance_seconds"),
        (7.0, "synthetic_E1"),
    )
    sided = adapter.SourceBindings(
        columns=sided.columns,
        performance_codes={
            "left_leg_stance_seconds": {
                "synthetic_E1": adapter.PerformanceDisposition.OTHER_NONPERFORMANCE
            }
        },
    )
    scores = adapter.score_source_row(row, sided, (1, 2, 3, 4))
    assert scores["single_leg_stance"] == 0.5


@pytest.mark.parametrize("source_code", ["synthetic_E", "synthetic_E1"])
def test_e_without_verified_cause_and_e1_are_missing(source_code: str) -> None:
    row, bindings = synthetic_fixture()
    row, sided = _bind_sides(
        row,
        bindings,
        "better_leg_stance_seconds",
        ("right_leg_stance_seconds", "left_leg_stance_seconds"),
        (source_code, None),
    )
    sided = adapter.SourceBindings(
        columns=sided.columns,
        performance_codes={
            "right_leg_stance_seconds": {
                source_code: adapter.PerformanceDisposition.OTHER_NONPERFORMANCE
            }
        },
    )

    assert adapter.score_source_row(row, sided, (1, 2, 3, 4))["single_leg_stance"] is None


def test_unverified_e_is_missing_but_verified_inability_scores_one() -> None:
    row, bindings = synthetic_fixture()
    row, sided = _bind_sides(
        row,
        bindings,
        "better_leg_stance_seconds",
        ("right_leg_stance_seconds", "left_leg_stance_seconds"),
        ("synthetic_E", None),
    )
    columns = dict(sided.columns)
    reason_header = "synthetic_stance_reason"
    row[reason_header] = "synthetic_physical_inability"
    sided = adapter.SourceBindings(
        columns=columns,
        performance_codes={
            "right_leg_stance_seconds": {
                "synthetic_E": adapter.PerformanceDisposition.OTHER_NONPERFORMANCE
            }
        },
        reason_columns={"right_leg_stance_seconds": reason_header},
        verified_functional_inability_codes={
            "right_leg_stance_seconds": ("synthetic_physical_inability",)
        },
    )

    assert adapter.score_source_row(row, sided, (1, 2, 3, 4))["single_leg_stance"] == 1.0

    row[reason_header] = "synthetic_unverified_reason"
    assert adapter.score_source_row(row, sided, (1, 2, 3, 4))["single_leg_stance"] is None


def test_missing_gait_time_does_not_become_inability_from_aid_metadata() -> None:
    row, bindings = synthetic_fixture()
    row[bindings.columns["selected_max_10m_seconds"]] = None
    row["synthetic_assistive_device_metadata"] = "recorded"

    scores = adapter.score_source_row(row, bindings, (1, 2, 3, 4))
    assert scores["maximal_10m_gait_speed"] is None
