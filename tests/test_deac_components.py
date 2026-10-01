"""Synthetic tests for DEAC component rules without source-field binding."""

import importlib.util
from pathlib import Path

import pytest


MODULE_PATH = (
    Path(__file__).resolve().parents[1]
    / "DEAC-Frailty-Index"
    / "src"
    / "deac_components.py"
)
MODULE_SPEC = importlib.util.spec_from_file_location("deac_components", MODULE_PATH)
assert MODULE_SPEC is not None and MODULE_SPEC.loader is not None
deac = importlib.util.module_from_spec(MODULE_SPEC)
MODULE_SPEC.loader.exec_module(deac)


SCORE_CASES = [
    ("score_diabetes", {0: 0.0, 1: 1.0}),
    ("score_self_rated_health", {0: 0.0, 1: 0.25, 2: 0.5, 3: 0.75, 4: 1.0}),
    ("score_alcohol", {0: 0.0, 1: 0.5, 2: 1.0}),
    ("score_hearing", {0: 0.0, 1: 1.0, 2: 0.0, 3: 1.0, 4: None}),
    ("score_vision", {0: 0.0, 1: 1.0, 2: 0.0, 3: 1.0, 4: None}),
    ("score_memory", {0: 0.0, 1: 1.0, 2: 1.0}),
    ("score_mood", {0: 0.0, 1: 1.0, 2: 1.0}),
    ("score_sleep", {0: 0.0, 1: 0.5, 2: 1.0, 3: 1.0, 4: 1.0}),
    ("score_self_rated_mobility", {0: 0.0, 1: 0.5, 2: 1.0}),
    ("score_walking_500m", {0: 0.0, 1: 0.5, 2: 1.0}),
    ("score_balance_difficulty", {0: 0.0, 1: 1.0}),
    ("score_previous_fall", {0: 0.0, 1: 1.0}),
    ("score_fear_of_falling", {0: 0.0, 1: 1.0}),
]


@pytest.mark.parametrize(
    ("scorer_name", "category", "expected"),
    [
        (scorer_name, category, expected)
        for scorer_name, mapping in SCORE_CASES
        for category, expected in mapping.items()
    ],
)
def test_approved_categories(scorer_name: str, category: int, expected: float | None) -> None:
    scorer = getattr(deac, scorer_name)
    assert scorer(category) == expected


@pytest.mark.parametrize("scorer_name", [name for name, _ in SCORE_CASES])
def test_ordinary_missing_is_not_scored(scorer_name: str) -> None:
    assert getattr(deac, scorer_name)(None) is None


@pytest.mark.parametrize("scorer_name", [name for name, _ in SCORE_CASES])
@pytest.mark.parametrize("unsupported", [-1, "source-specific-missing", 1.0, True])
def test_unmapped_or_unnormalized_input_fails_closed(
    scorer_name: str, unsupported: object
) -> None:
    with pytest.raises(ValueError):
        getattr(deac, scorer_name)(unsupported)


@pytest.mark.parametrize(
    ("scorer_name", "above_range"),
    [(name, max(mapping) + 1) for name, mapping in SCORE_CASES],
)
def test_above_range_category_fails_closed(scorer_name: str, above_range: int) -> None:
    with pytest.raises(ValueError):
        getattr(deac, scorer_name)(above_range)


@pytest.mark.parametrize(
    ("values", "expected"),
    [
        ((0, 0, 0), 0.0),
        ((1, 0, 0), 1.0),
        ((0, 1, 0), 1.0),
        ((0, 0, 1), 1.0),
        ((1, 1, 1), 1.0),
        ((None, None, None), None),
    ],
)
def test_neurological_complete_or_all_missing(
    values: tuple[int | None, int | None, int | None], expected: float | None
) -> None:
    assert deac.score_neurological(*values) == expected


@pytest.mark.parametrize(
    "values",
    [(1, None, 0), (None, 1, 1), (None, None, 1)],
)
def test_neurological_known_positive_with_missing_is_positive(
    values: tuple[int | None, int | None, int | None],
) -> None:
    assert deac.score_neurological(*values) == 1.0


@pytest.mark.parametrize(
    "values",
    [
        (0, None, 0),
        (0, 0, None),
        (None, None, 0),
    ],
)
def test_neurological_partial_missing_is_unresolved(
    values: tuple[int | None, int | None, int | None],
) -> None:
    with pytest.raises(deac.UnresolvedNeurologicalInput):
        deac.score_neurological(*values)


@pytest.mark.parametrize("values", [(2, 0, 0), (True, 0, 0), (0, "unknown", 0)])
def test_neurological_unsupported_input_fails_closed(values: tuple[object, ...]) -> None:
    with pytest.raises(ValueError):
        deac.score_neurological(*values)


@pytest.mark.parametrize(
    ("value", "expected"),
    [(0, 0.0), (3.99, 0.0), (4, 0.5), (6, 0.5), (6.01, 1.0), (10, 1.0)],
)
def test_pain_vas_normalized_boundaries(value: float, expected: float) -> None:
    assert deac.score_pain_vas(value) == expected


@pytest.mark.parametrize(
    ("seconds", "expected"),
    [(0, 1.0), (4.99, 1.0), (5, 0.5), (9.99, 0.5), (10, 0.0)],
)
def test_single_leg_stance_selected_measurement(
    seconds: float, expected: float
) -> None:
    assert deac.score_single_leg_stance(seconds) == expected


@pytest.mark.parametrize(
    ("seconds", "expected"),
    [
        (11.19, 0.0),
        (11.20, 0.25),
        (13.69, 0.25),
        (13.70, 0.5),
        (16.69, 0.5),
        (16.70, 0.75),
        (60.00, 0.75),
        (60.01, 1.0),
    ],
)
def test_five_chair_rises_completed_time(seconds: float, expected: float) -> None:
    assert deac.score_five_chair_rises(seconds) == expected


@pytest.mark.parametrize(
    ("source_class", "expected"),
    [(0, 1.0), (1, 0.8), (2, 0.6), (3, 0.4), (4, 0.2), (5, 0.0)],
)
def test_grip_already_selected_source_class(source_class: int, expected: float) -> None:
    assert deac.score_grip_source_class(source_class) == expected


@pytest.mark.parametrize(
    ("speed", "expected"),
    [(0.59, 1.0), (0.60, 0.5), (1.00, 0.5), (1.01, 0.0)],
)
def test_maximal_gait_measured_speed(speed: float, expected: float) -> None:
    assert deac.score_maximal_10m_gait_speed(speed) == expected


@pytest.mark.parametrize(
    "scorer_name",
    [
        "score_pain_vas",
        "score_single_leg_stance",
        "score_five_chair_rises",
        "score_grip_source_class",
        "score_maximal_10m_gait_speed",
    ],
)
def test_new_scorers_leave_ordinary_missing_unscored(scorer_name: str) -> None:
    assert getattr(deac, scorer_name)(None) is None


@pytest.mark.parametrize(
    "scorer_name",
    [
        "score_pain_vas",
        "score_single_leg_stance",
        "score_five_chair_rises",
        "score_maximal_10m_gait_speed",
    ],
)
@pytest.mark.parametrize(
    "unsupported", [-1, True, "unknown", float("nan"), float("inf")]
)
def test_measurement_scorers_reject_unnormalized_input(
    scorer_name: str, unsupported: object
) -> None:
    with pytest.raises(ValueError):
        getattr(deac, scorer_name)(unsupported)


@pytest.mark.parametrize("unsupported", [-1, 6, True, 1.0, "unknown"])
def test_grip_rejects_unsupported_class(unsupported: object) -> None:
    with pytest.raises(ValueError):
        deac.score_grip_source_class(unsupported)


@pytest.mark.parametrize(
    ("scorer_name", "value"),
    [
        ("score_pain_vas", 10.01),
        ("score_five_chair_rises", 0),
        ("score_maximal_10m_gait_speed", 0),
    ],
)
def test_measurement_specific_invalid_inputs(scorer_name: str, value: float) -> None:
    with pytest.raises(ValueError):
        getattr(deac, scorer_name)(value)
