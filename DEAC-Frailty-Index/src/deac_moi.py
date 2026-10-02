"""Pure, synthetic-only MOI preparation and quintile scoring helpers.

The caller supplies a baseline MOI index that includes age points and the
corresponding completed baseline age. No source fields or participant data are
read here. Quintile cutpoints use the R-7 linear quantile definition. Values
equal to a cutpoint are assigned to the lower interval, so tied values always
receive the same score.
"""

from __future__ import annotations

from bisect import bisect_left
from collections.abc import Iterable, Sequence
from math import ceil, floor, isfinite

Numeric = int | float
MOI_SCORES: tuple[float, ...] = (0.0, 0.25, 0.5, 0.75, 1.0)
_QUINTILE_PROBABILITIES: tuple[float, ...] = (0.2, 0.4, 0.6, 0.8)


def _finite_nonnegative(value: Numeric, *, label: str) -> float:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise ValueError(f"{label} must be a finite nonnegative number")
    try:
        numeric = float(value)
    except OverflowError as exc:
        raise ValueError(f"{label} must be a finite nonnegative number") from exc
    if not isfinite(numeric) or numeric < 0:
        raise ValueError(f"{label} must be a finite nonnegative number")
    return numeric


def waris_2011_age_points(baseline_age_years: int) -> int:
    """Return Waris 2011 points using the Owner-confirmed 75+ final band.

    Waris 2011 labels the final entry "75 years"; applying it to ages 75+
    is the Owner's 2026-10-01 interpretation, not an explicit article range.
    """
    if isinstance(baseline_age_years, bool) or not isinstance(baseline_age_years, int):
        raise ValueError("Baseline age must be an integer number of completed years")
    if 55 <= baseline_age_years <= 59:
        return 1
    if 60 <= baseline_age_years <= 64:
        return 2
    if 65 <= baseline_age_years <= 69:
        return 3
    if 70 <= baseline_age_years <= 74:
        return 4
    if baseline_age_years >= 75:
        return 6
    raise ValueError("Waris 2011 source does not define this baseline age")


def remove_moi_age_points(moi_index: Numeric, baseline_age_years: int) -> float:
    """Subtract baseline-age points exactly once from the age-inclusive MOI."""
    total = _finite_nonnegative(moi_index, label="MOI index")
    age_points = float(waris_2011_age_points(baseline_age_years))
    without_age = total - age_points
    if without_age < 0:
        raise ValueError("MOI age points exceed the age-inclusive MOI index")
    return without_age


def fit_moi_quintile_cutpoints(
    baseline_moi_without_age: Iterable[Numeric | None],
) -> tuple[float, float, float, float]:
    """Fit four R-7 linear quintile cutpoints from observed baseline values.

    Missing values are omitted. At least one observed value is required. This
    helper does not choose cohort membership; its caller must pass the approved
    DEAC baseline cohort.
    """
    observed = sorted(
        _finite_nonnegative(value, label="Age-point-removed MOI")
        for value in baseline_moi_without_age
        if value is not None
    )
    if not observed:
        raise ValueError("At least one observed baseline MOI value is required")

    last_index = len(observed) - 1
    cutpoints: list[float] = []
    for probability in _QUINTILE_PROBABILITIES:
        position = last_index * probability
        lower_index = floor(position)
        upper_index = ceil(position)
        fraction = position - lower_index
        lower_value = observed[lower_index]
        upper_value = observed[upper_index]
        cutpoints.append(lower_value + fraction * (upper_value - lower_value))
    return (cutpoints[0], cutpoints[1], cutpoints[2], cutpoints[3])


def score_moi_quintile(
    moi_without_age: Numeric | None,
    cutpoints: Sequence[Numeric],
) -> float | None:
    """Map an age-point-removed MOI to 0, .25, .5, .75, or 1.

    Equal values always map to the same category. A value exactly on a
    cutpoint belongs to the lower interval; duplicate cutpoints therefore do
    not split a tied group.
    """
    if len(cutpoints) != 4:
        raise ValueError("Exactly four MOI quintile cutpoints are required")
    validated = tuple(
        _finite_nonnegative(value, label="MOI quintile cutpoint")
        for value in cutpoints
    )
    if tuple(sorted(validated)) != validated:
        raise ValueError("MOI quintile cutpoints must be nondecreasing")
    if moi_without_age is None:
        return None
    value = _finite_nonnegative(moi_without_age, label="Age-point-removed MOI")
    return MOI_SCORES[bisect_left(validated, value)]
