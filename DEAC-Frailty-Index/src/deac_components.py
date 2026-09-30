"""Synthetic-only DEAC component scorers from approved handover v1.1.0.

This module does not bind source headers, calculate a partial index, or read
participant data. Apart from the publicly approved hearing and vision category
4, a protected source adapter must normalize source-specific missing codes to
None before calling it.
"""

from __future__ import annotations

from collections.abc import Mapping

Score = float | None


class UnresolvedNeurologicalInput(ValueError):
    """Partial inputs without a known positive have no approved score."""


def _score_category(value: int | None, scores: Mapping[int, Score]) -> Score:
    if value is None:
        return None
    if isinstance(value, bool) or not isinstance(value, int):
        raise ValueError("Expected an approved integer category or None")
    try:
        return scores[value]
    except KeyError as exc:
        raise ValueError("Category is not covered by the approved rule") from exc


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
        raise UnresolvedNeurologicalInput(
            "Partial neurological inputs require reviewed missingness handling"
        )
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
