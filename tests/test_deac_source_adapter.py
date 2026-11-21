"""Synthetic-only tests for configurable DEAC source normalization."""

from __future__ import annotations

import sys
from itertools import product
from pathlib import Path

import pytest


SRC_DIR = Path(__file__).resolve().parents[1] / "DEAC-Frailty-Index" / "src"
sys.path.insert(0, str(SRC_DIR))

import deac_source_adapter as adapter  # noqa: E402
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


def test_fof_source_code_two_is_normalized_as_ordinary_missing() -> None:
    row, bindings = synthetic_fixture()
    row[bindings.columns["fear_of_falling"]] = 2
    bindings = adapter.SourceBindings(
        columns=bindings.columns,
        ordinary_missing_codes={"fear_of_falling": (2,)},
    )

    assert adapter.score_source_row(row, bindings, (1, 2, 3, 4))["fear_of_falling"] is None


@pytest.mark.parametrize(
    ("source_field", "component"),
    [
        ("self_rated_health", "self_rated_health"),
        ("alcohol", "alcohol"),
        ("memory", "memory"),
        ("sleep", "sleep"),
        ("walking_500m", "walking_500m"),
        ("balance_difficulty", "balance_difficulty"),
        ("mood", "mood"),
        ("previous_fall", "previous_fall"),
    ],
)
def test_documented_field_missing_codes_are_not_scored(
    source_field: str, component: str
) -> None:
    row, bindings = synthetic_fixture()
    synthetic_marker = "synthetic_documented_missing"
    row[bindings.columns[source_field]] = synthetic_marker
    bindings = adapter.SourceBindings(
        columns=bindings.columns,
        ordinary_missing_codes={source_field: (synthetic_marker,)},
    )

    assert adapter.score_source_row(row, bindings, (1, 2, 3, 4))[component] is None


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


@pytest.mark.parametrize(
    ("reason", "expected"),
    [
        (None, None),
        ("synthetic_unverified_reason", None),
        ("synthetic_verified_reason", 1.0),
    ],
)
def test_functional_inability_status_requires_verified_reason_in_row_scoring(
    reason: object, expected: float | None
) -> None:
    row, bindings = synthetic_fixture()
    field = "selected_max_10m_seconds"
    reason_header = "synthetic_10m_reason"
    row[bindings.columns[field]] = "synthetic_E"
    row[reason_header] = reason
    bindings = adapter.SourceBindings(
        columns=bindings.columns,
        performance_codes={
            field: {"synthetic_E": adapter.PerformanceDisposition.FUNCTIONAL_INABILITY}
        },
        reason_columns={field: reason_header},
        verified_functional_inability_codes={
            field: ("synthetic_verified_reason",)
        },
    )

    result = adapter.score_source_row(row, bindings, (1, 2, 3, 4))
    assert result["maximal_10m_gait_speed"] == expected


def test_numeric_performance_status_codes_match_exactly() -> None:
    status = 99
    codebook = {status: adapter.PerformanceDisposition.OTHER_NONPERFORMANCE}
    assert (
        adapter.normalize_preselected_test_value(
            status, codebook, "selected_max_10m_seconds"
        )
        is None
    )
    assert (
        adapter.normalize_preselected_test_value(
            99.5, codebook, "selected_max_10m_seconds"
        )
        == 99.5
    )

    row, bindings = synthetic_fixture()
    field = "selected_max_10m_seconds"
    row[bindings.columns[field]] = status
    bindings = adapter.SourceBindings(
        columns=bindings.columns,
        performance_codes={field: codebook},
    )
    assert (
        adapter.score_source_row(row, bindings, (1, 2, 3, 4))[
            "maximal_10m_gait_speed"
        ]
        is None
    )


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


@pytest.mark.parametrize("source_status", ["e", " e1 "])
def test_performance_status_normalizes_case_and_edge_whitespace(
    source_status: str,
) -> None:
    row, bindings = synthetic_fixture()
    row[bindings.columns["selected_max_10m_seconds"]] = source_status
    bindings = adapter.SourceBindings(
        columns=bindings.columns,
        performance_codes={
            "selected_max_10m_seconds": {
                "E": adapter.PerformanceDisposition.OTHER_NONPERFORMANCE,
                "E1": adapter.PerformanceDisposition.OTHER_NONPERFORMANCE,
            }
        },
    )

    assert (
        adapter.score_source_row(row, bindings, (1, 2, 3, 4))["maximal_10m_gait_speed"]
        is None
    )


def test_performance_codebook_rejects_normalized_key_collisions() -> None:
    row, bindings = synthetic_fixture()
    bindings = adapter.SourceBindings(
        columns=bindings.columns,
        performance_codes={
            "selected_max_10m_seconds": {
                "E": adapter.PerformanceDisposition.OTHER_NONPERFORMANCE,
                " e ": adapter.PerformanceDisposition.OTHER_NONPERFORMANCE,
            }
        },
    )

    with pytest.raises(ValueError, match="duplicate normalized codes"):
        adapter.score_source_row(row, bindings, (1, 2, 3, 4))


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


def test_partial_neurological_input_uses_ordinary_missing_denominator() -> None:
    row, bindings = synthetic_fixture()
    row[bindings.columns["parkinson"]] = None
    scores = adapter.score_source_row(row, bindings, (1, 2, 3, 4))
    assert scores["neurological"] is None


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


def _single_walking_fixture(
    header: str = "synthetic_walking_header",
) -> tuple[dict[str, object], adapter.SourceBindings, dict]:
    row: dict[str, object] = {"synthetic_decoy_header": 2, header: 0}
    bindings = adapter.SourceBindings(
        columns={"walking_500m": header},
        ordinary_missing_codes={"walking_500m": ("synthetic_missing",)},
    )
    schema = {
        "actual_sha256": "a" * 64,
        "expected_sha256": "a" * 64,
        "physical_headers": ("synthetic_other_header", header, "synthetic_neighbour"),
        "label_row": ("other", "synthetic walking difficulty", "other question"),
        "source_position": 1,
        "semantic_prefix": "synthetic walking difficulty",
    }
    return row, bindings, schema


@pytest.mark.parametrize(
    ("value", "expected"),
    [(0, 0.0), (1, 0.5), (2, 1.0), ("synthetic_missing", None), (None, None)],
)
def test_single_walking_component_uses_bound_source_and_existing_scorer(
    value: object, expected: float | None
) -> None:
    row, bindings, schema = _single_walking_fixture()
    row[bindings.columns["walking_500m"]] = value
    assert adapter.score_bound_walking_500m(row, bindings, **schema) == expected


def test_single_walking_component_uses_alternate_bound_header() -> None:
    row, bindings, schema = _single_walking_fixture("synthetic_alternate_header")
    row[bindings.columns["walking_500m"]] = 2
    assert adapter.score_bound_walking_500m(row, bindings, **schema) == 1.0


@pytest.mark.parametrize("value", [99, True, "unlisted", 1.0, ComponentStatus.NOT_APPLICABLE])
def test_single_walking_component_rejects_unlisted_or_wrong_type(value: object) -> None:
    row, bindings, schema = _single_walking_fixture()
    row[bindings.columns["walking_500m"]] = value
    with pytest.raises(ValueError):
        adapter.score_bound_walking_500m(row, bindings, **schema)


@pytest.mark.parametrize(
    "change",
    [
        {"actual_sha256": "b" * 64},
        {"source_position": 2},
        {"semantic_prefix": "different question"},
        {"physical_headers": ("synthetic_other_header", "", "synthetic_neighbour")},
        {"label_row": ("other", "", "other question")},
    ],
)
def test_single_walking_component_rejects_wrong_or_missing_schema(change: dict) -> None:
    row, bindings, schema = _single_walking_fixture()
    schema.update(change)
    with pytest.raises(adapter.SourceSchemaError):
        adapter.score_bound_walking_500m(row, bindings, **schema)


def test_single_walking_component_rejects_wrong_or_missing_bound_header() -> None:
    row, bindings, schema = _single_walking_fixture()
    with pytest.raises(adapter.SourceSchemaError):
        adapter.score_bound_walking_500m(
            row,
            adapter.SourceBindings(columns={"walking_500m": "synthetic_neighbour"}),
            **schema,
        )
    with pytest.raises(ValueError, match="missing"):
        adapter.score_bound_walking_500m({}, bindings, **schema)


def test_single_walking_component_rejects_ambiguous_physical_header() -> None:
    row, bindings, schema = _single_walking_fixture()
    schema["physical_headers"] = (
        "synthetic_walking_header",
        "synthetic_walking_header",
        "synthetic_neighbour",
    )
    with pytest.raises(adapter.SourceSchemaError):
        adapter.score_bound_walking_500m(row, bindings, **schema)


def test_single_walking_component_requires_semantic_label() -> None:
    row, bindings, schema = _single_walking_fixture("synthetic walking difficulty code")
    schema["label_row"] = ("other", "unrelated question", "other question")
    with pytest.raises(adapter.SourceSchemaError):
        adapter.score_bound_walking_500m(row, bindings, **schema)


def test_single_walking_component_cannot_mark_a_scoreable_value_missing() -> None:
    row, bindings, schema = _single_walking_fixture()
    bindings = adapter.SourceBindings(
        columns=bindings.columns,
        ordinary_missing_codes={"walking_500m": (1,)},
    )
    with pytest.raises(adapter.SourceSchemaError):
        adapter.score_bound_walking_500m(row, bindings, **schema)


@pytest.mark.parametrize("code", [0.0, 1.0, 2.0])
def test_single_walking_component_rejects_numeric_alias_as_missing(code: float) -> None:
    row, bindings, schema = _single_walking_fixture()
    bindings = adapter.SourceBindings(
        columns=bindings.columns,
        ordinary_missing_codes={"walking_500m": (code,)},
    )
    with pytest.raises(adapter.SourceSchemaError):
        adapter.score_bound_walking_500m(row, bindings, **schema)


def test_single_walking_component_allows_none_in_missing_configuration() -> None:
    row, bindings, schema = _single_walking_fixture()
    bindings = adapter.SourceBindings(
        columns=bindings.columns,
        ordinary_missing_codes={"walking_500m": (None, "synthetic_missing")},
    )
    assert adapter.score_bound_walking_500m(row, bindings, **schema) == 0.0


def test_single_walking_component_uses_validated_binding_snapshot() -> None:
    row, _, schema = _single_walking_fixture()
    columns = {"walking_500m": "synthetic_walking_header"}
    missing_codes: dict[str, tuple[object, ...]] = {
        "walking_500m": ("synthetic_missing",)
    }
    bindings = adapter.SourceBindings(
        columns=columns, ordinary_missing_codes=missing_codes
    )

    class ChangingRow(dict[str, object]):
        def __getitem__(self, key: str) -> object:
            columns["walking_500m"] = "synthetic_decoy_header"
            missing_codes["walking_500m"] = (0,)
            return super().__getitem__(key)

    assert adapter.score_bound_walking_500m(ChangingRow(row), bindings, **schema) == 0.0


QUESTION_FIELDS = (
    "diabetes",
    "alcohol",
    "memory",
    "mood",
    "sleep",
    "self_rated_mobility",
    "balance_difficulty",
    "fear_of_falling",
)


def _question_fixture() -> tuple[dict[str, object], adapter.SourceBindings, dict]:
    columns = {field: f"fictional_header_{field}" for field in QUESTION_FIELDS}
    row: dict[str, object] = {header: 0 for header in columns.values()}
    labels = tuple(f"fictional label {field}" for field in QUESTION_FIELDS)
    schema = {
        "actual_sha256": "a" * 64,
        "expected_sha256": "a" * 64,
        "physical_headers": tuple(columns.values()) + ("fictional_neighbor",),
        "label_row": labels + ("different fictional question",),
        "positions_by_field": {field: i for i, field in enumerate(QUESTION_FIELDS)},
        "semantic_prefixes": {
            field: f"fictional label {field}" for field in QUESTION_FIELDS
        },
    }
    bindings = adapter.SourceBindings(
        columns=columns,
        ordinary_missing_codes={field: () for field in QUESTION_FIELDS},
    )
    return row, bindings, schema


def test_question_bundle_scores_only_its_own_fields(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    row, bindings, schema = _question_fixture()
    row[bindings.columns["alcohol"]] = 1
    row[bindings.columns["memory"]] = 1
    row["fictional_neighbor"] = 999
    monkeypatch.setattr(
        adapter, "score_source_row", lambda *args: pytest.fail("called full adapter")
    )
    monkeypatch.setattr(
        adapter, "assemble_deac_index", lambda *args: pytest.fail("called index")
    )

    scores = adapter.score_bound_question_components(row, bindings, **schema)
    assert set(scores) == set(QUESTION_FIELDS)
    assert scores["alcohol"] == 0.5
    assert scores["memory"] == 1.0
    assert scores["diabetes"] == 0.0


@pytest.mark.parametrize("field", QUESTION_FIELDS)
def test_question_bundle_normalizes_only_configured_missing_field(field: str) -> None:
    row, bindings, schema = _question_fixture()
    marker = "fictional_missing"
    row[bindings.columns[field]] = marker
    codes = dict(bindings.ordinary_missing_codes)
    codes[field] = (marker,)
    configured = adapter.SourceBindings(
        columns=bindings.columns, ordinary_missing_codes=codes
    )

    scores = adapter.score_bound_question_components(row, configured, **schema)
    assert scores[field] is None
    assert all(scores[other] == 0.0 for other in QUESTION_FIELDS if other != field)


@pytest.mark.parametrize("field", QUESTION_FIELDS)
@pytest.mark.parametrize(
    "bad", [999, True, 1.0, "fictional_unknown", ComponentStatus.NOT_APPLICABLE]
)
def test_question_bundle_rejects_unknown_type_or_status(
    field: str, bad: object
) -> None:
    row, bindings, schema = _question_fixture()
    row[bindings.columns[field]] = bad
    with pytest.raises(ValueError):
        adapter.score_bound_question_components(row, bindings, **schema)


@pytest.mark.parametrize("field", QUESTION_FIELDS)
def test_question_bundle_accepts_blank_as_missing(field: str) -> None:
    row, bindings, schema = _question_fixture()
    row[bindings.columns[field]] = None
    scores = adapter.score_bound_question_components(row, bindings, **schema)
    assert scores[field] is None


@pytest.mark.parametrize(
    "bad_code", [0, 0.0, "0", True, ComponentStatus.NOT_APPLICABLE]
)
def test_question_bundle_rejects_scoreable_or_invalid_missing_alias(
    bad_code: object,
) -> None:
    row, bindings, schema = _question_fixture()
    codes = dict(bindings.ordinary_missing_codes)
    codes["diabetes"] = (bad_code,)
    configured = adapter.SourceBindings(
        columns=bindings.columns, ordinary_missing_codes=codes
    )
    with pytest.raises(adapter.SourceSchemaError):
        adapter.score_bound_question_components(row, configured, **schema)


@pytest.mark.parametrize(
    "change",
    [
        {"actual_sha256": "b" * 64},
        {
            "positions_by_field": {
                **{field: i for i, field in enumerate(QUESTION_FIELDS)},
                "fear_of_falling": 8,
            }
        },
        {
            "label_row": tuple(
                f"fictional label {field}" for field in QUESTION_FIELDS[:-1]
            ) + ("wrong neighbor", "different fictional question")
        },
        {
            "physical_headers": tuple(
                f"fictional_header_{field}" for field in QUESTION_FIELDS[:-1]
            ) + ("", "fictional_neighbor")
        },
    ],
)
def test_question_bundle_rejects_wrong_schema(change: dict) -> None:
    row, bindings, schema = _question_fixture()
    schema.update(change)
    with pytest.raises(adapter.SourceSchemaError):
        adapter.score_bound_question_components(row, bindings, **schema)


def test_question_bundle_rejects_duplicate_header_and_wrong_neighbor() -> None:
    row, bindings, schema = _question_fixture()
    schema["physical_headers"] = (
        *schema["physical_headers"][:-1],
        bindings.columns["fear_of_falling"],
    )
    with pytest.raises(adapter.SourceSchemaError):
        adapter.score_bound_question_components(row, bindings, **schema)
    row, bindings, schema = _question_fixture()
    columns = dict(bindings.columns)
    columns["fear_of_falling"] = "fictional_neighbor"
    with pytest.raises(adapter.SourceSchemaError):
        adapter.score_bound_question_components(
            row,
            adapter.SourceBindings(
                columns=columns,
                ordinary_missing_codes=bindings.ordinary_missing_codes,
            ),
            **schema,
        )


def test_question_bundle_rejects_missing_field_or_extra_configuration() -> None:
    row, bindings, schema = _question_fixture()
    del row[bindings.columns["sleep"]]
    with pytest.raises(ValueError, match="missing"):
        adapter.score_bound_question_components(row, bindings, **schema)
    row, bindings, schema = _question_fixture()
    codes = dict(bindings.ordinary_missing_codes)
    del codes["sleep"]
    with pytest.raises(adapter.SourceSchemaError):
        adapter.score_bound_question_components(
            row,
            adapter.SourceBindings(
                columns=bindings.columns, ordinary_missing_codes=codes
            ),
            **schema,
        )


def test_question_bundle_uses_binding_snapshot() -> None:
    row, bindings, schema = _question_fixture()
    columns = dict(bindings.columns)
    codes = dict(bindings.ordinary_missing_codes)
    configured = adapter.SourceBindings(columns=columns, ordinary_missing_codes=codes)

    class ChangingRow(dict[str, object]):
        def __getitem__(self, key: str) -> object:
            columns["fear_of_falling"] = "fictional_neighbor"
            codes["fear_of_falling"] = (0,)
            return super().__getitem__(key)

    scores = adapter.score_bound_question_components(
        ChangingRow(row), configured, **schema
    )
    assert scores["fear_of_falling"] == 0.0


def test_question_bundle_scores_verified_subset_when_other_binding_is_missing() -> None:
    row, bindings, schema = _question_fixture()
    excluded = "sleep"
    fields = set(QUESTION_FIELDS) - {excluded}
    subset = adapter.SourceBindings(
        columns={
            field: header
            for field, header in bindings.columns.items()
            if field in fields
        },
        ordinary_missing_codes={field: () for field in fields},
    )
    schema["positions_by_field"] = {
        field: position
        for field, position in schema["positions_by_field"].items()
        if field in fields
    }
    schema["semantic_prefixes"] = {
        field: prefix
        for field, prefix in schema["semantic_prefixes"].items()
        if field in fields
    }
    del row[bindings.columns[excluded]]

    scores = adapter.score_bound_question_components(row, subset, **schema)
    assert set(scores) == fields
    assert all(score == 0.0 for score in scores.values())


def test_question_bundle_reads_each_bound_value_once() -> None:
    row, bindings, schema = _question_fixture()
    reads: dict[str, int] = {}

    class ChangingRow(dict[str, object]):
        def __getitem__(self, key: str) -> object:
            reads[key] = reads.get(key, 0) + 1
            if reads[key] > 1:
                return 999
            return super().__getitem__(key)

    scores = adapter.score_bound_question_components(
        ChangingRow(row), bindings, **schema
    )
    assert set(scores) == set(QUESTION_FIELDS)
    assert all(count == 1 for count in reads.values())


NEUROLOGICAL_FIELDS = ("alzheimer", "parkinson", "stroke_avh")


def _neurological_fixture() -> tuple[dict[str, object], adapter.SourceBindings, dict]:
    columns = {
        field: f"fictional_neurological_header_{field}"
        for field in NEUROLOGICAL_FIELDS
    }
    row: dict[str, object] = {header: 0 for header in columns.values()}
    schema = {
        "actual_sha256": "a" * 64,
        "expected_sha256": "a" * 64,
        "physical_headers": tuple(columns.values()) + ("fictional_neighbor",),
        "label_row": tuple(
            f"fictional neurological label {field}" for field in NEUROLOGICAL_FIELDS
        ) + ("different fictional question",),
        "positions_by_field": {field: i for i, field in enumerate(NEUROLOGICAL_FIELDS)},
        "semantic_prefixes": {
            field: f"fictional neurological label {field}"
            for field in NEUROLOGICAL_FIELDS
        },
    }
    return row, adapter.SourceBindings(columns=columns), schema


@pytest.mark.parametrize("values", list(product((0, 1, None), repeat=3)))
def test_bound_neurological_all_documented_combinations(
    values: tuple[int | None, int | None, int | None],
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    row, bindings, schema = _neurological_fixture()
    for field, value in zip(NEUROLOGICAL_FIELDS, values, strict=True):
        row[bindings.columns[field]] = value
    monkeypatch.setattr(
        adapter, "score_source_row", lambda *args: pytest.fail("called full adapter")
    )
    monkeypatch.setattr(
        adapter, "assemble_deac_index", lambda *args: pytest.fail("called index")
    )
    expected = 1.0 if 1 in values else None if None in values else 0.0
    assert adapter.score_bound_neurological(row, bindings, **schema) == expected


@pytest.mark.parametrize("field", NEUROLOGICAL_FIELDS)
@pytest.mark.parametrize(
    "bad", [2, "fictional_unknown", True, 1.0, ComponentStatus.NOT_APPLICABLE]
)
def test_bound_neurological_rejects_unlisted_code_or_type(
    field: str, bad: object
) -> None:
    row, bindings, schema = _neurological_fixture()
    row[bindings.columns[field]] = bad
    with pytest.raises(adapter.UnresolvedSourceCodeError):
        adapter.score_bound_neurological(row, bindings, **schema)


@pytest.mark.parametrize("bad_code", [0, 1, 0.0, 1.0, "0", "1", "E1", True])
def test_bound_neurological_rejects_unverified_missing_alias(bad_code: object) -> None:
    row, bindings, schema = _neurological_fixture()
    configured = adapter.SourceBindings(
        columns=bindings.columns,
        ordinary_missing_codes={"alzheimer": (bad_code,)},
    )
    with pytest.raises(adapter.SourceSchemaError, match="missing aliases"):
        adapter.score_bound_neurological(row, configured, **schema)


def test_bound_neurological_allows_only_ordinary_none_configuration() -> None:
    row, bindings, schema = _neurological_fixture()
    configured = adapter.SourceBindings(
        columns=bindings.columns,
        ordinary_missing_codes={"alzheimer": (None,)},
    )
    assert adapter.score_bound_neurological(row, configured, **schema) == 0.0


@pytest.mark.parametrize(
    "change",
    [
        {"actual_sha256": "b" * 64},
        {"expected_sha256": "not a digest"},
        {"positions_by_field": {
            "alzheimer": 1, "parkinson": 0, "stroke_avh": 2,
        }},
        {"positions_by_field": {
            "alzheimer": 0, "parkinson": 0, "stroke_avh": 2,
        }},
        {"physical_headers": (
            "fictional_neurological_header_alzheimer", "",
            "fictional_neurological_header_stroke_avh", "fictional_neighbor",
        )},
        {"physical_headers": (
            "fictional_neurological_header_alzheimer",
            "fictional_neurological_header_parkinson",
            "fictional_neurological_header_stroke_avh",
            "fictional_neurological_header_alzheimer",
        )},
        {"label_row": (
            "fictional neurological label alzheimer", "wrong question",
            "fictional neurological label stroke_avh", "different fictional question",
        )},
    ],
)
def test_bound_neurological_rejects_wrong_schema_before_row_read(change: dict) -> None:
    class NoReadRow(dict[str, object]):
        def __getitem__(self, key: str) -> object:
            pytest.fail("row read before schema validation")

    row, bindings, schema = _neurological_fixture()
    schema.update(change)
    with pytest.raises(adapter.SourceSchemaError):
        adapter.score_bound_neurological(NoReadRow(row), bindings, **schema)


def test_bound_neurological_rejects_wrong_neighbor_and_missing_row_column() -> None:
    row, bindings, schema = _neurological_fixture()
    columns = dict(bindings.columns)
    columns["stroke_avh"] = "fictional_neighbor"
    with pytest.raises(adapter.SourceSchemaError):
        adapter.score_bound_neurological(
            row, adapter.SourceBindings(columns=columns), **schema
        )
    del row[bindings.columns["stroke_avh"]]
    with pytest.raises(ValueError, match="missing"):
        adapter.score_bound_neurological(row, bindings, **schema)


def test_bound_neurological_rejects_extra_or_duplicate_binding() -> None:
    row, bindings, schema = _neurological_fixture()
    columns = dict(bindings.columns)
    columns["unrelated"] = "fictional_neighbor"
    with pytest.raises(adapter.SourceSchemaError):
        adapter.score_bound_neurological(
            row, adapter.SourceBindings(columns=columns), **schema
        )
    columns = dict(bindings.columns)
    columns["parkinson"] = columns["alzheimer"]
    with pytest.raises(adapter.SourceSchemaError):
        adapter.score_bound_neurological(
            row, adapter.SourceBindings(columns=columns), **schema
        )


def test_bound_neurological_uses_validated_binding_snapshot() -> None:
    row, bindings, schema = _neurological_fixture()
    columns = dict(bindings.columns)
    configured = adapter.SourceBindings(columns=columns)

    class ChangingRow(dict[str, object]):
        def __getitem__(self, key: str) -> object:
            columns["stroke_avh"] = "fictional_neighbor"
            return super().__getitem__(key)

    assert (
        adapter.score_bound_neurological(ChangingRow(row), configured, **schema)
        == 0.0
    )
