"""Synthetic-only DEAC component scorers from approved handover v1.1.0.

This module does not bind source headers, calculate a partial index, or read
participant data. Apart from the publicly approved hearing and vision category
4, a protected source adapter must normalize source-specific missing codes to
None before calling it. Performance scorers require an already selected,
measured result; they do not determine nonperformance reasons or source units.
"""

from __future__ import annotations

from collections.abc import Mapping
from math import isfinite

Score = float | None


def _score_category(value: int | None, scores: Mapping[int, Score]) -> Score:
    if value is None:
        return None
    if isinstance(value, bool) or not isinstance(value, int):
        raise ValueError("Expected an approved integer category or None")
    try:
        return scores[value]
    except KeyError as exc:
        raise ValueError("Category is not covered by the approved rule") from exc


def _measurement(value: int | float | None, *, positive: bool = False) -> float | None:
    if value is None:
        return None
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise ValueError("Expected a normalized numeric measurement or None")
    try:
        measured = float(value)
    except OverflowError as exc:
        raise ValueError("Expected a finite measured result") from exc
    if not isfinite(measured) or measured < 0 or (positive and measured == 0):
        raise ValueError("Expected a finite measured result")
    return measured


def score_diabetes(value: int | None) -> Score:
    return _score_category(value, {0: 0.0, 1: 1.0})


def score_neurological(
    alzheimer: int | None, parkinson: int | None, stroke_avh: int | None
) -> Score:
    """Score a known positive; leave an all-zero/unknown combination unresolved."""
    values = (alzheimer, parkinson, stroke_avh)
    for value in values:
        if value is not None:
            _score_category(value, {0: 0.0, 1: 1.0})
    if all(value is None for value in values):
        return None
    if any(value == 1 for value in values):
        return 1.0
    if any(value is None for value in values):
        return None
    return 0.0


def score_self_rated_health(value: int | None) -> Score:
    return _score_category(value, {0: 0.0, 1: 0.25, 2: 0.5, 3: 0.75, 4: 1.0})


def score_alcohol(value: int | None) -> Score:
    return _score_category(value, {0: 0.0, 1: 0.5, 2: 1.0})


def score_hearing(value: int | None) -> Score:
    """DMA1-D-010: source category 4 is ordinary missing."""
    return _score_category(value, {0: 0.0, 1: 1.0, 2: 0.0, 3: 1.0, 4: None})


def score_vision(value: int | None) -> Score:
    """DMA1-D-010: source category 4 is ordinary missing."""
    return _score_category(value, {0: 0.0, 1: 1.0, 2: 0.0, 3: 1.0, 4: None})


def score_memory(value: int | None) -> Score:
    return _score_category(value, {0: 0.0, 1: 1.0, 2: 1.0})


def score_mood(value: int | None) -> Score:
    return _score_category(value, {0: 0.0, 1: 1.0, 2: 1.0})


def score_sleep(value: int | None) -> Score:
    return _score_category(value, {0: 0.0, 1: 0.5, 2: 1.0, 3: 1.0, 4: 1.0})


def score_self_rated_mobility(value: int | None) -> Score:
    return _score_category(value, {0: 0.0, 1: 0.5, 2: 1.0})


def score_walking_500m(value: int | None) -> Score:
    return _score_category(value, {0: 0.0, 1: 0.5, 2: 1.0})


def score_balance_difficulty(value: int | None) -> Score:
    return _score_category(value, {0: 0.0, 1: 1.0})


def score_previous_fall(value: int | None) -> Score:
    return _score_category(value, {0: 0.0, 1: 1.0})


def score_fear_of_falling(value: int | None) -> Score:
    return _score_category(value, {0: 0.0, 1: 1.0})


def score_pain_vas(value: int | float | None) -> Score:
    """Score a VAS value already normalized to the approved 0–10 scale."""
    measured = _measurement(value)
    if measured is None:
        return None
    if measured > 10:
        raise ValueError("VAS must be normalized to the 0–10 scale")
    if measured < 4:
        return 0.0
    if measured <= 6:
        return 0.5
    return 1.0


def score_single_leg_stance(seconds: int | float | None) -> Score:
    """Score the measured better-leg duration; leg selection is upstream."""
    measured = _measurement(seconds)
    if measured is None:
        return None
    if measured < 5:
        return 1.0
    if measured < 10:
        return 0.5
    return 0.0


def score_five_chair_rises(seconds: int | float | None) -> Score:
    """Score a completed five-rise time; incomplete tests need separate review."""
    measured = _measurement(seconds, positive=True)
    if measured is None:
        return None
    if measured < 11.20:
        return 0.0
    if measured < 13.70:
        return 0.25
    if measured < 16.70:
        return 0.5
    if measured <= 60.00:
        return 0.75
    return 1.0


def score_grip_source_class(value: int | None) -> Score:
    """Score an already selected better-hand source class, not raw strength."""
    return _score_category(value, {0: 1.0, 1: 0.8, 2: 0.6, 3: 0.4, 4: 0.2, 5: 0.0})


def score_maximal_10m_gait_speed(metres_per_second: int | float | None) -> Score:
    """Score a measured maximal speed in m/s; timing and aids are upstream."""
    measured = _measurement(metres_per_second, positive=True)
    if measured is None:
        return None
    if measured > 1.0:
        return 0.0
    if measured >= 0.6:
        return 0.5
    return 1.0
