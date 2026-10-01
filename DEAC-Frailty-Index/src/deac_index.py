"""Pure, synthetic-only assembly of the approved 20-component DEAC index.

The caller must provide one named slot for every component. Scoring, source
binding, nonperformance classification, and measurement selection are upstream.
No participant data or source adapter is read here.
"""

from __future__ import annotations

from collections.abc import Mapping
from enum import Enum
from math import fsum, isfinite


class ComponentStatus(Enum):
    """A confirmed applicability state supplied by an upstream adapter."""

    NOT_APPLICABLE = "not_applicable"


COMPONENT_NAMES: tuple[str, ...] = (
    "diabetes",
    "neurological",
    "self_rated_health",
    "moi",
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
    "pain_vas",
    "single_leg_stance",
    "five_chair_rises",
    "grip_strength",
    "maximal_10m_gait_speed",
)

ComponentInput = int | float | None | ComponentStatus


def assemble_deac_index(scores: Mapping[str, ComponentInput]) -> float | None:
    """Return the observed-score mean if at least 80% of relevant slots exist.

    ``None`` is ordinary missing and remains relevant. A confirmed
    ``NOT_APPLICABLE`` slot is excluded from both relevance and the score
    denominator. Insufficient coverage returns ``None``; malformed input fails
    closed with ``ValueError``. This function is not a source-data adapter.
    """
    if not isinstance(scores, Mapping) or set(scores) != set(COMPONENT_NAMES):
        raise ValueError("Expected exactly the 20 approved DEAC component names")

    observed_scores: list[float] = []
    relevant_count = 0
    for name in COMPONENT_NAMES:
        value = scores[name]
        if value is ComponentStatus.NOT_APPLICABLE:
            continue
        relevant_count += 1
        if value is None:
            continue
        if isinstance(value, bool) or not isinstance(value, (int, float)):
            raise ValueError(f"Invalid normalized deficit score for {name}")
        try:
            score = float(value)
        except OverflowError as exc:
            raise ValueError(f"Invalid normalized deficit score for {name}") from exc
        if not isfinite(score) or not 0.0 <= score <= 1.0:
            raise ValueError(f"Invalid normalized deficit score for {name}")
        observed_scores.append(score)

    if relevant_count == 0:
        raise ValueError("DEAC requires at least one relevant component")
    observed_count = len(observed_scores)
    if observed_count * 5 < relevant_count * 4:
        return None
    return fsum(observed_scores) / observed_count
