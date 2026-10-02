"""Configurable, synthetic-testable adapter for normalized DEAC source rows.

Actual source headers, missing-code lists, and test-specific codebooks are
provided by a protected runtime configuration and are intentionally absent
from this repository. This module never selects a measurement, hand, or leg
and never reads files or participant data.
"""

from __future__ import annotations

from collections.abc import Mapping, Sequence
from dataclasses import dataclass, field
from enum import Enum
from math import isfinite
from typing import Any

from deac_components import (
    score_alcohol,
    score_balance_difficulty,
    score_diabetes,
    score_fear_of_falling,
    score_five_chair_rises,
    score_grip_source_class,
    score_hearing,
    score_maximal_10m_gait_speed,
    score_memory,
    score_mood,
    score_pain_vas,
    score_previous_fall,
    score_self_rated_health,
    score_self_rated_mobility,
    score_single_leg_stance,
    score_sleep,
    score_vision,
    score_walking_500m,
    score_neurological,
)
from deac_index import ComponentInput, ComponentStatus, assemble_deac_index
from deac_moi import remove_moi_age_points, score_moi_quintile


class PerformanceDisposition(Enum):
    """Protocol-resolved meaning of a test-specific non-numeric source code."""

    FUNCTIONAL_INABILITY = "functional_inability"
    OTHER_NONPERFORMANCE = "other_nonperformance"
    NOT_APPLICABLE = "not_applicable"


class UnresolvedSourceCodeError(ValueError):
    """A source code lacks an explicit field- or test-specific interpretation."""


@dataclass(frozen=True)
class SourceBindings:
    """Protected runtime mapping from semantic inputs to actual source columns.

    ``columns`` maps the logical names documented below to source headers.
    ``ordinary_missing_codes`` is field-specific and applies only to ordinary
    non-performance values. ``performance_codes`` maps source codes separately
    for each physical test to a ``PerformanceDisposition``. Do not place raw
    source headers or code lists in committed configuration or tests.
    """

    columns: Mapping[str, str]
    ordinary_missing_codes: Mapping[str, Sequence[object]] = field(default_factory=dict)
    performance_codes: Mapping[str, Mapping[object, PerformanceDisposition]] = field(
        default_factory=dict
    )


_GAIT_SPEED_FIELD = "maximal_10m_speed_m_per_second"
_GAIT_TIME_FIELD = "selected_max_10m_seconds"
_BASE_FIELDS = frozenset(
    {
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
    }
)
_PERFORMANCE_FIELDS = frozenset(
    {
        "better_leg_stance_seconds",
        "five_chair_rises_seconds",
        "better_hand_grip_class",
        _GAIT_TIME_FIELD,
        _GAIT_SPEED_FIELD,
    }
)
_FUNCTIONAL_INABILITY = object()


def _validate_bindings(bindings: SourceBindings) -> None:
    if not isinstance(bindings, SourceBindings):
        raise ValueError("Expected a protected SourceBindings configuration")
    columns = bindings.columns
    if not isinstance(columns, Mapping):
        raise ValueError("Source columns must be a mapping")
    gait_fields = {_GAIT_SPEED_FIELD, _GAIT_TIME_FIELD} & set(columns)
    expected = _BASE_FIELDS | gait_fields
    if gait_fields not in ({_GAIT_SPEED_FIELD}, {_GAIT_TIME_FIELD}):
        raise ValueError("Bind exactly one normalized gait speed or selected 10 m time")
    if set(columns) != expected:
        raise ValueError("Source bindings do not match the required semantic fields")
    headers = list(columns.values())
    if any(not isinstance(header, str) or not header for header in headers):
        raise ValueError("Every semantic field must bind to one nonempty source column")
    if len(set(headers)) != len(headers):
        raise ValueError("Each semantic field must bind to a distinct source column")
    if set(bindings.ordinary_missing_codes) - (_BASE_FIELDS - _PERFORMANCE_FIELDS):
        raise ValueError("Ordinary missing codes are only allowed for non-test fields")
    if set(bindings.performance_codes) - (_PERFORMANCE_FIELDS & set(columns)):
        raise ValueError("Performance codebooks must be scoped to a bound test field")
    for test_field, codebook in bindings.performance_codes.items():
        if not isinstance(codebook, Mapping) or any(
            not isinstance(disposition, PerformanceDisposition)
            for disposition in codebook.values()
        ):
            raise ValueError(f"Invalid test-specific codebook for {test_field}")


def _matches_code(value: object, codes: Sequence[object]) -> bool:
    return any(value == code for code in codes)


def normalize_pain_vas_cm(
    value: object, ordinary_missing_codes: Sequence[object] = ()
) -> object | None:
    """Pass an already-centimeter VAS through, mapping configured missing codes.

    The protected runtime binding supplies source-specific missing codes. This
    function performs no unit conversion and does not reinterpret test status.
    """
    if value is None or _matches_code(value, ordinary_missing_codes):
        return None
    return value


def _read_value(
    row: Mapping[str, object], bindings: SourceBindings, logical_field: str
) -> object:
    if logical_field not in bindings.columns:
        raise ValueError(f"No source binding for semantic field {logical_field}")
    header = bindings.columns[logical_field]
    if header not in row:
        raise ValueError(f"Bound source column is missing for {logical_field}")
    value = row[header]
    if logical_field == "pain_vas_cm":
        return normalize_pain_vas_cm(
            value, bindings.ordinary_missing_codes.get(logical_field, ())
        )
    if value is None or _matches_code(
        value, bindings.ordinary_missing_codes.get(logical_field, ())
    ):
        return None
    return value


def normalize_preselected_test_value(
    value: object,
    codebook: Mapping[object, PerformanceDisposition],
    logical_field: str,
) -> object:
    """Normalize one already-selected test result without choosing a trial/side.

    Numeric measured values are returned unchanged. Configured test-specific
    dispositions remain distinct; unknown textual codes fail closed.
    """
    if value is None:
        return None
    try:
        disposition = codebook.get(value)
    except TypeError:
        disposition = None
    if disposition is PerformanceDisposition.FUNCTIONAL_INABILITY:
        return _FUNCTIONAL_INABILITY
    if disposition is PerformanceDisposition.OTHER_NONPERFORMANCE:
        return None
    if disposition is PerformanceDisposition.NOT_APPLICABLE:
        return ComponentStatus.NOT_APPLICABLE
    if isinstance(value, str):
        raise UnresolvedSourceCodeError(
            f"Unmapped test-specific source code for {logical_field}"
        )
    return value


def _test_value(
    row: Mapping[str, object], bindings: SourceBindings, logical_field: str
) -> object:
    return normalize_preselected_test_value(
        _read_value(row, bindings, logical_field),
        bindings.performance_codes.get(logical_field, {}),
        logical_field,
    )


def _score_moi(
    row: Mapping[str, object],
    bindings: SourceBindings,
    moi_cutpoints: Sequence[int | float],
) -> float | None:
    total = _read_value(row, bindings, "moi_total")
    age = _read_value(row, bindings, "baseline_age_years")
    if total is None or age is None:
        return None
    if isinstance(age, bool) or not isinstance(age, (int, float)):
        raise ValueError("Baseline age must be numeric completed years")
    try:
        age_number = float(age)
    except OverflowError as exc:
        raise ValueError("Baseline age must be numeric completed years") from exc
    if not isfinite(age_number) or not age_number.is_integer():
        raise ValueError("Baseline age must be numeric completed years")
    without_age = remove_moi_age_points(total, int(age_number))  # type: ignore[arg-type]
    return score_moi_quintile(without_age, moi_cutpoints)


def _score_test_field(
    row: Mapping[str, object],
    bindings: SourceBindings,
    logical_field: str,
    scorer: Any,
    *,
    gait_time: bool = False,
) -> ComponentInput:
    value = _test_value(row, bindings, logical_field)
    if value is _FUNCTIONAL_INABILITY:
        return 1.0
    if value is None or value is ComponentStatus.NOT_APPLICABLE:
        return value
    if gait_time:
        if isinstance(value, bool) or not isinstance(value, (int, float)):
            raise ValueError("Selected 10 m time must be numeric seconds")
        try:
            seconds = float(value)
        except OverflowError as exc:
            raise ValueError("Selected 10 m time must be finite positive seconds") from exc
        if not isfinite(seconds) or seconds <= 0:
            raise ValueError("Selected 10 m time must be finite positive seconds")
        value = 10.0 / seconds
    return scorer(value)


def score_source_row(
    row: Mapping[str, object],
    bindings: SourceBindings,
    moi_cutpoints: Sequence[int | float],
) -> dict[str, ComponentInput]:
    """Normalize one supplied row, score it, and return all 20 named slots.

    The row is caller-provided and must be synthetic during development. This
    function has no file or cohort access. MOI cutpoints must have been fitted
    separately to the approved baseline cohort; this function never fits them.
    Better-side, trial, and nonperformance meanings must already be selected
    in the protected binding configuration.
    """
    if not isinstance(row, Mapping):
        raise ValueError("Expected one caller-provided mapping row")
    _validate_bindings(bindings)

    if _GAIT_SPEED_FIELD in bindings.columns:
        gait_value = _test_value(row, bindings, _GAIT_SPEED_FIELD)
        if gait_value is _FUNCTIONAL_INABILITY:
            gait_score: ComponentInput = 1.0
        elif gait_value is ComponentStatus.NOT_APPLICABLE or gait_value is None:
            gait_score: ComponentInput = gait_value
        else:
            gait_score = score_maximal_10m_gait_speed(gait_value)  # type: ignore[arg-type]
    else:
        gait_score = _score_test_field(
            row,
            bindings,
            _GAIT_TIME_FIELD,
            score_maximal_10m_gait_speed,
            gait_time=True,
        )

    scores: dict[str, ComponentInput] = {
        "diabetes": score_diabetes(_read_value(row, bindings, "diabetes")),  # type: ignore[arg-type]
        "neurological": score_neurological(
            _read_value(row, bindings, "alzheimer"),  # type: ignore[arg-type]
            _read_value(row, bindings, "parkinson"),  # type: ignore[arg-type]
            _read_value(row, bindings, "stroke_avh"),  # type: ignore[arg-type]
        ),
        "self_rated_health": score_self_rated_health(
            _read_value(row, bindings, "self_rated_health")  # type: ignore[arg-type]
        ),
        "moi": _score_moi(row, bindings, moi_cutpoints),
        "alcohol": score_alcohol(_read_value(row, bindings, "alcohol")),  # type: ignore[arg-type]
        "hearing": score_hearing(_read_value(row, bindings, "hearing")),  # type: ignore[arg-type]
        "vision": score_vision(_read_value(row, bindings, "vision")),  # type: ignore[arg-type]
        "memory": score_memory(_read_value(row, bindings, "memory")),  # type: ignore[arg-type]
        "mood": score_mood(_read_value(row, bindings, "mood")),  # type: ignore[arg-type]
        "sleep": score_sleep(_read_value(row, bindings, "sleep")),  # type: ignore[arg-type]
        "self_rated_mobility": score_self_rated_mobility(
            _read_value(row, bindings, "self_rated_mobility")  # type: ignore[arg-type]
        ),
        "walking_500m": score_walking_500m(
            _read_value(row, bindings, "walking_500m")  # type: ignore[arg-type]
        ),
        "balance_difficulty": score_balance_difficulty(
            _read_value(row, bindings, "balance_difficulty")  # type: ignore[arg-type]
        ),
        "previous_fall": score_previous_fall(
            _read_value(row, bindings, "previous_fall")  # type: ignore[arg-type]
        ),
        "fear_of_falling": score_fear_of_falling(
            _read_value(row, bindings, "fear_of_falling")  # type: ignore[arg-type]
        ),
        "pain_vas": score_pain_vas(
            _read_value(row, bindings, "pain_vas_cm")  # type: ignore[arg-type]
        ),
        "single_leg_stance": _score_test_field(
            row,
            bindings,
            "better_leg_stance_seconds",
            score_single_leg_stance,
        ),
        "five_chair_rises": _score_test_field(
            row,
            bindings,
            "five_chair_rises_seconds",
            score_five_chair_rises,
        ),
        "grip_strength": _score_test_field(
            row,
            bindings,
            "better_hand_grip_class",
            score_grip_source_class,
        ),
        "maximal_10m_gait_speed": gait_score,
    }
    if len(scores) != 20:
        raise AssertionError("Adapter must supply exactly the 20 approved components")
    return scores


def calculate_deac_from_source_row(
    row: Mapping[str, object],
    bindings: SourceBindings,
    moi_cutpoints: Sequence[int | float],
) -> float | None:
    """Pass the normalized 20-slot score map to the approved index assembler."""
    return assemble_deac_index(score_source_row(row, bindings, moi_cutpoints))
