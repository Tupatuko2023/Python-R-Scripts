"""Synthetic-only tests for MOI age-point removal and quintile scoring."""

import importlib.util
from pathlib import Path

import pytest


MODULE_PATH = (
    Path(__file__).resolve().parents[1]
    / "DEAC-Frailty-Index"
    / "src"
    / "deac_moi.py"
)
MODULE_SPEC = importlib.util.spec_from_file_location("deac_moi", MODULE_PATH)
assert MODULE_SPEC is not None and MODULE_SPEC.loader is not None
moi = importlib.util.module_from_spec(MODULE_SPEC)
MODULE_SPEC.loader.exec_module(moi)


@pytest.mark.parametrize(
    ("age", "expected"),
    [
        (55, 1),
        (59, 1),
        (60, 2),
        (64, 2),
        (65, 3),
        (69, 3),
        (70, 4),
        (74, 4),
        (75, 6),
        (76, 6),
        (80, 6),
    ],
)
def test_owner_confirmed_waris_age_points(age: int, expected: int) -> None:
    assert moi.waris_2011_age_points(age) == expected


@pytest.mark.parametrize("age", [54])
def test_unsupported_age_bands_fail_closed(age: int) -> None:
    with pytest.raises(ValueError, match="does not define"):
        moi.waris_2011_age_points(age)


@pytest.mark.parametrize("age", [True, 70.0, "70"])
def test_age_requires_completed_integer_years(age: object) -> None:
    with pytest.raises(ValueError, match="integer"):
        moi.waris_2011_age_points(age)


@pytest.mark.parametrize(
    ("moi_index", "age", "expected"),
    [
        (8, 60, 6.0),
        (4, 70, 0.0),
        (10.5, 55, 9.5),
        (10, 75, 4.0),
        (10, 76, 4.0),
        (10, 80, 4.0),
    ],
)
def test_age_points_are_removed_once(
    moi_index: int | float, age: int, expected: float
) -> None:
    assert moi.remove_moi_age_points(moi_index, age) == expected


def test_age_points_cannot_be_removed_twice_from_inconsistent_total() -> None:
    with pytest.raises(ValueError, match="exceed"):
        moi.remove_moi_age_points(3, 70)


def test_r7_cutpoints_and_quintile_boundaries() -> None:
    cutpoints = moi.fit_moi_quintile_cutpoints([0, 1, 2, 3, 4])
    assert cutpoints == pytest.approx((0.8, 1.6, 2.4, 3.2))
    assert [moi.score_moi_quintile(value, cutpoints) for value in [0, 1, 2, 3, 4]] == [
        0.0,
        0.25,
        0.5,
        0.75,
        1.0,
    ]
    assert moi.score_moi_quintile(0.8, cutpoints) == 0.0
    assert moi.score_moi_quintile(0.8001, cutpoints) == 0.25


def test_missing_baseline_values_are_omitted_when_fitting_cutpoints() -> None:
    assert moi.fit_moi_quintile_cutpoints([None, 0, 1, 2, 3, 4]) == pytest.approx(
        (0.8, 1.6, 2.4, 3.2)
    )
    assert moi.score_moi_quintile(None, (1, 2, 3, 4)) is None


def test_tied_values_are_never_split_across_quintile_scores() -> None:
    cutpoints = moi.fit_moi_quintile_cutpoints([0, 0, 0, 1, 2])
    tied_scores = [moi.score_moi_quintile(0, cutpoints) for _ in range(3)]
    assert tied_scores == [tied_scores[0]] * 3
    assert tied_scores[0] == 0.0


def test_all_equal_cohort_values_receive_the_same_score() -> None:
    cutpoints = moi.fit_moi_quintile_cutpoints([5, 5, 5, 5, 5])
    assert cutpoints == (5.0, 5.0, 5.0, 5.0)
    assert {moi.score_moi_quintile(5, cutpoints)} == {0.0}


@pytest.mark.parametrize("values", [[], [None, None]])
def test_empty_observed_baseline_cohort_fails_closed(values: list[None]) -> None:
    with pytest.raises(ValueError, match="At least one"):
        moi.fit_moi_quintile_cutpoints(values)


@pytest.mark.parametrize("bad_value", [-1, True, "1", float("nan"), float("inf")])
def test_invalid_moi_values_fail_closed(bad_value: object) -> None:
    with pytest.raises(ValueError):
        moi.fit_moi_quintile_cutpoints([0, 1, bad_value])


def test_quantile_cutpoints_must_be_four_ordered_finite_values() -> None:
    with pytest.raises(ValueError, match="four"):
        moi.score_moi_quintile(1, (1, 2, 3))
    with pytest.raises(ValueError, match="nondecreasing"):
        moi.score_moi_quintile(1, (1, 3, 2, 4))
