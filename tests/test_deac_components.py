"""Synthetic tests for the 14 rule-ready DEAC components."""

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
