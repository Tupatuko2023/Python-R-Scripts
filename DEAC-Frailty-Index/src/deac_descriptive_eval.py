"""Create aggregate-only DEAC v2 descriptive outputs from a verified run.

Participant data is read only from protected Termux files. The output contains
aggregate tables and a histogram; it never contains participant keys or rows.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import math
import os
import secrets
import stat
import subprocess
from collections import Counter
from datetime import datetime, timezone
from decimal import Decimal, InvalidOperation
from io import StringIO
from pathlib import Path
from statistics import mean, median, stdev
from typing import Any, Iterable, Mapping, Sequence

from deac_index import COMPONENT_NAMES
from deac_run import (
    _require_private_file,
    _resolve_identifier_position,
    _resolve_source,
    _sha256_file,
)
from deac_cohort_runner import (
    select_first_visit_cohort,
    validate_xlsx_source_metadata,
)


GROUPS = {
    "cohort": None,
    "index_calculable": True,
    "below_coverage": False,
}
PHYSICAL_TEST_COMPONENTS = COMPONENT_NAMES[16:]
INDEX_BIN_WIDTH = 0.05


def _private_input(path: Path) -> None:
    _require_private_file(path)


def _read_private_snapshot(path: Path) -> bytes:
    _private_input(path)
    flags = os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0) | getattr(os, "O_CLOEXEC", 0)
    descriptor = os.open(path, flags)
    try:
        before = os.fstat(descriptor)
        if not stat.S_ISREG(before.st_mode) or stat.S_IMODE(before.st_mode) & 0o077:
            raise ValueError("Protected input must be a private regular file")
        with os.fdopen(descriptor, "rb", closefd=False) as stream:
            content = stream.read()
        after = os.fstat(descriptor)
        path_after = os.stat(path, follow_symlinks=False)
        identity_before = (
            before.st_dev,
            before.st_ino,
            before.st_size,
            before.st_mtime_ns,
            before.st_ctime_ns,
        )
        identity_after = (
            after.st_dev,
            after.st_ino,
            after.st_size,
            after.st_mtime_ns,
            after.st_ctime_ns,
        )
        identity_path = (
            path_after.st_dev,
            path_after.st_ino,
            path_after.st_size,
            path_after.st_mtime_ns,
            path_after.st_ctime_ns,
        )
        if identity_before != identity_after or identity_before != identity_path:
            raise ValueError("Protected input changed while it was read")
        return content
    finally:
        os.close(descriptor)


def _sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def _q(values: Sequence[float], probability: float) -> float:
    ordered = sorted(values)
    if not ordered:
        raise ValueError("Cannot calculate a quantile from no observations")
    position = (len(ordered) - 1) * probability
    lower = math.floor(position)
    upper = math.ceil(position)
    if lower == upper:
        return ordered[lower]
    return ordered[lower] + (ordered[upper] - ordered[lower]) * (position - lower)


def _summary(values: Sequence[float]) -> dict[str, float | int | None]:
    if not values:
        return {
            "n": 0,
            "mean": None,
            "sd_sample": None,
            "median": None,
            "q1": None,
            "q3": None,
            "min": None,
            "max": None,
        }
    return {
        "n": len(values),
        "mean": mean(values),
        "sd_sample": stdev(values) if len(values) > 1 else 0.0,
        "median": median(values),
        "q1": _q(values, 0.25),
        "q3": _q(values, 0.75),
        "min": min(values),
        "max": max(values),
    }


def _write_private(path: Path, payload: bytes) -> str:
    if path.exists() or path.is_symlink():
        raise FileExistsError("Refusing to replace an existing evaluation artifact")
    temporary = f".{path.name}.{secrets.token_hex(12)}.tmp"
    directory_fd = os.open(path.parent, os.O_RDONLY | getattr(os, "O_DIRECTORY", 0))
    file_fd = -1
    try:
        file_fd = os.open(
            temporary,
            os.O_WRONLY | os.O_CREAT | os.O_EXCL | getattr(os, "O_NOFOLLOW", 0),
            0o600,
            dir_fd=directory_fd,
        )
        os.fchmod(file_fd, 0o600)
        with os.fdopen(file_fd, "wb", closefd=False) as stream:
            stream.write(payload)
            stream.flush()
            os.fsync(stream.fileno())
        os.close(file_fd)
        file_fd = -1
        os.rename(
            temporary,
            path.name,
            src_dir_fd=directory_fd,
            dst_dir_fd=directory_fd,
        )
        os.fsync(directory_fd)
    except BaseException:
        if file_fd >= 0:
            os.close(file_fd)
        try:
            os.unlink(temporary, dir_fd=directory_fd)
        except FileNotFoundError:
            pass
        raise
    finally:
        os.close(directory_fd)
    return _sha256_bytes(payload)


def _csv_bytes(fieldnames: Sequence[str], rows: Iterable[Mapping[str, object]]) -> bytes:
    from io import StringIO

    stream = StringIO(newline="")
    writer = csv.DictWriter(stream, fieldnames=fieldnames, extrasaction="raise")
    writer.writeheader()
    writer.writerows(rows)
    return stream.getvalue().encode("utf-8")


def _parse_age(value: object, missing_codes: Sequence[object]) -> int | None:
    if value is None or (isinstance(value, str) and not value.strip()):
        return None
    if any(value == code for code in missing_codes):
        return None
    if isinstance(value, bool):
        raise ValueError("Baseline age binding contains a non-age value")
    try:
        number = Decimal(str(value).strip())
    except (InvalidOperation, ValueError) as exc:
        raise ValueError("Baseline age binding contains an unparseable value") from exc
    if not number.is_finite() or number < 0 or number != number.to_integral_value():
        raise ValueError("Baseline age binding is not completed years")
    return int(number)


def _value_groups(rows: Sequence[dict[str, str]]) -> dict[str, list[dict[str, str]]]:
    output: dict[str, list[dict[str, str]]] = {}
    for name, eligibility in GROUPS.items():
        output[name] = [
            row for row in rows if eligibility is None or row["eligible"] == str(eligibility)
        ]
    return output


def _annual_component_missingness_rows(
    rows: Sequence[dict[str, str]], year_by_key: Mapping[str, int]
) -> list[dict[str, object]]:
    """Summarize component availability by verified clinic year and cohort group."""
    annual_rows: list[dict[str, object]] = []
    for group_name, group_rows in _value_groups(rows).items():
        by_year: dict[int, list[dict[str, str]]] = {}
        for row in group_rows:
            key = row["participant_key"]
            if key not in year_by_key:
                raise ValueError("Clinic year is unavailable for a selected participant")
            by_year.setdefault(year_by_key[key], []).append(row)
        for year, year_rows in sorted(by_year.items()):
            for component in COMPONENT_NAMES:
                observed = sum(row[component] not in ("", "NOT_APPLICABLE") for row in year_rows)
                missing = sum(row[component] == "" for row in year_rows)
                not_applicable = sum(row[component] == "NOT_APPLICABLE" for row in year_rows)
                annual_rows.append(
                    {
                        "clinic_visit_year": year,
                        "group": group_name,
                        "component": component,
                        "people": len(year_rows),
                        "observed": observed,
                        "missing": missing,
                        "not_applicable": not_applicable,
                        "missing_percent": missing / len(year_rows),
                    }
                )
    return annual_rows


def _render_histogram(values: Sequence[float], bins: Sequence[Mapping[str, object]]) -> bytes:
    width, height = 760, 440
    left, right, top, bottom = 64, 24, 28, 64
    plot_width = width - left - right
    plot_height = height - top - bottom
    max_count = max((int(row["count"]) for row in bins), default=0) or 1
    bar_width = plot_width / len(bins)
    bars: list[str] = []
    for index, item in enumerate(bins):
        count = int(item["count"])
        bar_height = plot_height * count / max_count
        x = left + index * bar_width + 1
        y = top + plot_height - bar_height
        bars.append(
            f'<rect x="{x:.2f}" y="{y:.2f}" width="{max(bar_width-2, 1):.2f}" '
            f'height="{bar_height:.2f}" fill="#286090" />'
        )
    ticks = []
    for fraction in (0, 0.25, 0.5, 0.75, 1):
        x = left + plot_width * fraction
        label = f"{fraction:.2f}"
        ticks.append(
            f'<text x="{x:.2f}" y="{height-28}" text-anchor="middle" '
            f'font-size="12">{label}</text>'
        )
    max_ticks = []
    for fraction in (0, 0.5, 1):
        y = top + plot_height * (1 - fraction)
        label = str(round(max_count * fraction))
        max_ticks.append(
            f'<text x="{left-10}" y="{y+4:.2f}" text-anchor="end" '
            f'font-size="12">{label}</text>'
        )
    svg = """<svg xmlns="http://www.w3.org/2000/svg" width="760" height="440" viewBox="0 0 760 440">
<rect width="100%" height="100%" fill="white" />
<text x="380" y="20" text-anchor="middle" font-family="sans-serif" font-size="16">DEAC v2 index distribution</text>
<g font-family="sans-serif" fill="#222">
""" + "\n".join(bars + ticks + max_ticks) + f"""
<line x1="{left}" y1="{top+plot_height}" x2="{width-right}" y2="{top+plot_height}" stroke="#222" />
<line x1="{left}" y1="{top}" x2="{left}" y2="{top+plot_height}" stroke="#222" />
<text x="{width/2}" y="{height-7}" text-anchor="middle" font-size="13">DEAC v2 index (0–1)</text>
<text x="16" y="{height/2}" text-anchor="middle" font-size="13" transform="rotate(-90 16 {height/2})">People</text>
</g></svg>\n"""
    return svg.encode("utf-8")


def _protected_cohort(
    *, env_path: Path, bindings_path: Path, selector_path: Path, expected_manifest: Mapping[str, Any]
):
    env_bytes = _read_private_snapshot(env_path)
    bindings_bytes = _read_private_snapshot(bindings_path)
    selector_bytes = _read_private_snapshot(selector_path)
    env = _read_env_bytes(env_bytes)
    config = json.loads(bindings_bytes)
    selector = json.loads(selector_bytes)
    if _sha256_bytes(env_bytes) != selector.get("env_sha256"):
        raise ValueError("Current protected environment does not match cohort selector")
    if _sha256_bytes(bindings_bytes) != expected_manifest["runtime_bindings"]["sha256"]:
        raise ValueError("Current SourceBindings do not match the verified run")
    if _sha256_bytes(selector_bytes) != expected_manifest["cohort_selector"]["config_sha256"]:
        raise ValueError("Current cohort selector does not match the verified run")
    if selector.get("source_sha256") != expected_manifest["source"]["sha256"]:
        raise ValueError("Cohort selector source snapshot differs from run manifest")
    source_path = _resolve_source(env, expected_manifest["source"]["sha256"])
    bindings, metadata = validate_xlsx_source_metadata(
        source_path,
        config,
        sheet_name=config["sheet"],
        identifier_position_1based=selector["identifier_position_1based"],
    )
    if metadata.sha256 != expected_manifest["source"]["sha256"]:
        raise ValueError("Validated workbook snapshot differs from run manifest")
    identifier_setting = selector["identifier_setting"]
    if identifier_setting not in env:
        raise ValueError("Protected identifier setting is unavailable")
    identifier_position = _resolve_identifier_position(
        env[identifier_setting],
        metadata.physical_headers,
        selector["identifier_position_1based"],
    )
    cohort = select_first_visit_cohort(
        source_path,
        metadata,
        bindings,
        data_start_row=config["data_start_row"],
        identifier_position_1based=identifier_position,
        visit_date_position_1based=selector["visit_date_position_1based"],
    )
    expected = selector.get("expected_preflight", {})
    observed = {
        "source_rows": cohort.preflight.source_rows,
        "unique_people": cohort.preflight.unique_people,
        "later_visit_rows": cohort.preflight.later_visit_rows,
        "missing_identifiers": cohort.preflight.missing_identifiers,
        "missing_visit_dates": cohort.preflight.missing_visit_dates,
        "first_visit_conflict_people": cohort.preflight.first_visit_conflict_people,
    }
    if expected and observed != expected:
        raise ValueError("Protected first-visit cohort differs from selector preflight")
    if cohort.source_sha256 != expected_manifest["source"]["sha256"]:
        raise ValueError("Selected cohort source hash differs from verified manifest")
    if _sha256_file(source_path) != cohort.source_sha256:
        raise ValueError("Source workbook changed after verified cohort selection")
    return bindings, cohort, cohort.source_sha256, {
        "env_sha256": _sha256_bytes(env_bytes),
        "source_bindings_sha256": _sha256_bytes(bindings_bytes),
        "cohort_selector_sha256": _sha256_bytes(selector_bytes),
    }


def _read_env_bytes(raw: bytes) -> dict[str, str]:
    values: dict[str, str] = {}
    for raw_line in raw.decode("utf-8").splitlines():
        line = raw_line.strip()
        if line.startswith("export "):
            line = line[7:].lstrip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip().strip('"').strip("'")
    return values


def _check_run(
    manifest_path: Path, result_path: Path
) -> tuple[dict[str, Any], list[dict[str, str]], str, bytes]:
    manifest_bytes = _read_private_snapshot(manifest_path)
    manifest = json.loads(manifest_bytes)
    if manifest.get("status") != "VERIFIED_VERSION_LOCKED_RERUN":
        raise ValueError("Input run manifest is not a verified version-locked run")
    result_bytes = _read_private_snapshot(result_path)
    if _sha256_bytes(result_bytes) != manifest["output"]["sha256"]:
        raise ValueError("Participant result file does not match run manifest")
    if result_path.name != manifest["output"]["relative_path"]:
        raise ValueError("Participant result filename differs from run manifest")
    required = {
        "participant_key",
        *COMPONENT_NAMES,
        "deac_index",
        "observed_components",
        "relevant_components",
        "coverage",
        "eligible",
    }
    with StringIO(result_bytes.decode("utf-8"), newline="") as stream:
        reader = csv.DictReader(stream)
        if set(reader.fieldnames or ()) != required:
            raise ValueError("Protected participant result schema differs from DEAC v2")
        rows = list(reader)
    keys = [row["participant_key"] for row in rows]
    if any(not key for key in keys) or len(keys) != len(set(keys)):
        raise ValueError("Protected participant keys are empty or duplicated")
    if len(rows) != manifest["output"]["record_count"]:
        raise ValueError("Protected result row count differs from run manifest")
    qc = manifest["aggregate_qc"]
    if len(rows) != qc["unique_people"]:
        raise ValueError("Protected result rows differ from aggregate cohort count")
    if manifest["coverage"]["index_calculable_people"] != sum(
        row["eligible"] == "True" for row in rows
    ):
        raise ValueError("Stored eligibility group sizes differ from manifest")
    if manifest["coverage"]["insufficient_coverage_people"] != sum(
        row["eligible"] == "False" for row in rows
    ):
        raise ValueError("Stored below-coverage group size differs from manifest")
    for row in rows:
        observed = sum(row[name] not in ("", "NOT_APPLICABLE") for name in COMPONENT_NAMES)
        relevant = sum(row[name] != "NOT_APPLICABLE" for name in COMPONENT_NAMES)
        if observed != int(row["observed_components"]) or relevant != int(
            row["relevant_components"]
        ):
            raise ValueError("Component values do not reconcile with stored coverage")
        if observed / relevant != float(row["coverage"]):
            raise ValueError("Component values do not reconcile with stored coverage fraction")
        if (observed * 5 >= relevant * 4) != (row["eligible"] == "True"):
            raise ValueError("Stored coverage group violates the approved threshold")
        if (row["deac_index"] != "") != (row["eligible"] == "True"):
            raise ValueError("Index availability does not match eligibility")
    if len(rows) != 527 or sum(row["eligible"] == "True" for row in rows) != 470:
        raise ValueError("Verified cohort differs from the expected descriptive scope")
    return manifest, rows, _sha256_bytes(manifest_bytes), _sha256_bytes(result_bytes)


def evaluate(args: argparse.Namespace) -> Path:
    manifest_path = Path(args.manifest).resolve(strict=True)
    run_directory = manifest_path.parent
    manifest_content = _read_private_snapshot(manifest_path)
    run_manifest, result_rows, source_manifest_sha256, source_result_sha256 = _check_run(
        manifest_path,
        run_directory / json.loads(manifest_content)["output"]["relative_path"],
    )
    if _sha256_bytes(manifest_content) != source_manifest_sha256:
        raise ValueError("Source run manifest changed between validation reads")
    env_path = Path(args.env).resolve(strict=True)
    bindings_path = Path(args.bindings).resolve(strict=True)
    selector_path = Path(args.selector).resolve(strict=True)
    bindings, cohort, source_sha256, config_hashes = _protected_cohort(
        env_path=env_path,
        bindings_path=bindings_path,
        selector_path=selector_path,
        expected_manifest=run_manifest,
    )
    results_by_key = {row["participant_key"]: row for row in result_rows}
    cohort_keys = cohort.identifiers
    if set(results_by_key) != set(cohort_keys) or len(cohort_keys) != len(results_by_key):
        raise ValueError("Verified result membership does not match selected first visits")

    age_header = bindings.columns.get("baseline_age_years")
    age_missing_codes = bindings.ordinary_missing_codes.get("baseline_age_years", ())
    if not age_header:
        raise ValueError("Verified source binding has no baseline age field")
    age_by_key: dict[str, int | None] = {}
    year_by_key: dict[str, int] = {}
    for key, visit_date, source_row in zip(
        cohort_keys, cohort.visit_dates, cohort.rows, strict=True
    ):
        age_by_key[key] = _parse_age(source_row.get(age_header), age_missing_codes)
        year_by_key[key] = visit_date.year

    group_rows = _value_groups(result_rows)
    annual_component_missingness_rows = _annual_component_missingness_rows(
        result_rows, year_by_key
    )
    index_values = [float(row["deac_index"]) for row in result_rows if row["deac_index"]]
    index_summary = _summary(index_values)
    index_bins: list[dict[str, object]] = []
    bin_count = round(1.0 / INDEX_BIN_WIDTH)
    for number in range(bin_count):
        lower = number * INDEX_BIN_WIDTH
        upper = lower + INDEX_BIN_WIDTH
        count = sum(lower <= value < upper for value in index_values)
        if number == bin_count - 1:
            count += sum(value == 1.0 for value in index_values)
        index_bins.append(
            {
                "bin_lower": f"{lower:.2f}",
                "bin_upper": f"{upper:.2f}",
                "count": count,
                "percent": count / len(index_values),
            }
        )

    index_distribution = [
        {"record_type": "summary", "statistic": key, "value": value}
        for key, value in index_summary.items()
    ] + [
        {
            "record_type": "histogram_bin",
            "statistic": f"{item['bin_lower']}-{item['bin_upper']}",
            "value": item["count"],
        }
        for item in index_bins
    ]

    observed_count_rows: list[dict[str, object]] = []
    for group_name, values in group_rows.items():
        counts = Counter(int(row["observed_components"]) for row in values)
        for number in range(21):
            observed_count_rows.append(
                {
                    "group": group_name,
                    "observed_components": number,
                    "people": counts[number],
                    "percent": counts[number] / len(values) if values else 0,
                }
            )

    component_missing_rows: list[dict[str, object]] = []
    component_distribution_rows: list[dict[str, object]] = []
    for group_name, values in group_rows.items():
        for component in COMPONENT_NAMES:
            scores = [
                float(row[component])
                for row in values
                if row[component] not in ("", "NOT_APPLICABLE")
            ]
            missing_count = sum(row[component] == "" for row in values)
            not_applicable = sum(row[component] == "NOT_APPLICABLE" for row in values)
            component_missing_rows.append(
                {
                    "group": group_name,
                    "component": component,
                    "people": len(values),
                    "observed": len(scores),
                    "missing": missing_count,
                    "not_applicable": not_applicable,
                    "missing_percent": missing_count / len(values) if values else 0,
                }
            )
            score_counts = Counter(scores)
            for score in sorted(score_counts):
                component_distribution_rows.append(
                    {
                        "group": group_name,
                        "component": component,
                        "record_type": "score",
                        "score": f"{score:.6g}",
                        "count": score_counts[score],
                        "percent_of_observed": score_counts[score] / len(scores),
                    }
                )
            component_distribution_rows.append(
                {
                    "group": group_name,
                    "component": component,
                    "record_type": "missing",
                    "score": "",
                    "count": missing_count,
                    "percent_of_observed": "",
                }
            )

    component_group_rows: list[dict[str, object]] = []
    component_groups = {
        "components_1_16": COMPONENT_NAMES[:16],
        "physical_performance_components_17_20": PHYSICAL_TEST_COMPONENTS,
    }
    for group_name, values in group_rows.items():
        for subset_name, component_names in component_groups.items():
            missing_people = 0
            all_missing_people = 0
            missing_cells = 0
            possible_cells = len(values) * len(component_names)
            for row in values:
                row_missing = sum(row[name] == "" for name in component_names)
                missing_cells += row_missing
                missing_people += row_missing > 0
                all_missing_people += row_missing == len(component_names)
            component_group_rows.append(
                {
                    "group": group_name,
                    "component_subset": subset_name,
                    "components_n": len(component_names),
                    "people": len(values),
                    "missing_cells": missing_cells,
                    "possible_cells": possible_cells,
                    "missing_cell_percent": (
                        missing_cells / possible_cells if possible_cells else 0
                    ),
                    "people_with_any_missing": missing_people,
                    "people_with_all_missing": all_missing_people,
                }
            )

    baseline_rows: list[dict[str, object]] = []
    age_summaries: dict[str, dict[str, float | int | None]] = {}
    age_missing_by_group: dict[str, int] = {}
    year_counts_by_group: dict[str, Counter[int]] = {}
    for group_name, values in group_rows.items():
        group_ages = [age_by_key[row["participant_key"]] for row in values]
        present_ages = [float(age) for age in group_ages if age is not None]
        age_summary = _summary(present_ages)
        age_summaries[group_name] = age_summary
        age_missing_by_group[group_name] = len(values) - len(present_ages)
        baseline_rows.append(
            {
                "group": group_name,
                "field": "baseline_age_years",
                "availability": "VERIFIED_PROTECTED_SOURCE_BINDING",
                "category": "summary",
                "n": age_summary["n"],
                "percent_group": "",
                "missing": len(values) - len(present_ages),
                "missing_percent": (len(values) - len(present_ages)) / len(values),
                **{key: age_summary[key] for key in ("mean", "sd_sample", "median", "q1", "q3", "min", "max")},
            }
        )
        years = [year_by_key[row["participant_key"]] for row in values]
        year_counts = Counter(years)
        year_counts_by_group[group_name] = year_counts
        for year, count in sorted(year_counts.items()):
            baseline_rows.append(
                {
                    "group": group_name,
                    "field": "clinic_visit_year",
                    "availability": "VERIFIED_COHORT_SELECTOR_DATE",
                    "category": year,
                    "n": count,
                    "percent_group": count / len(values),
                    "missing": len(values) - len(years),
                    "missing_percent": (len(values) - len(years)) / len(values),
                    "mean": "",
                    "sd_sample": "",
                    "median": "",
                    "q1": "",
                    "q3": "",
                    "min": "",
                    "max": "",
                }
            )
        baseline_rows.append(
            {
                "group": group_name,
                "field": "sex",
                "availability": "NOT_VERIFIED_NO_PROTECTED_BINDING_OR_KAAOS_DICTIONARY",
                "category": "not_reported",
                "n": "",
                "percent_group": "",
                "missing": "unknown",
                "missing_percent": "unknown",
                "mean": "",
                "sd_sample": "",
                "median": "",
                "q1": "",
                "q3": "",
                "min": "",
                "max": "",
            }
        )

    code_path = Path(__file__).resolve()
    code_hash = _sha256_file(code_path)
    repo_root = code_path.parents[2]
    git_commit = subprocess.check_output(
        ["git", "rev-parse", "HEAD"], cwd=repo_root, text=True
    ).strip()
    evaluation_id = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    raw_output_parent = Path(args.output_parent)
    if raw_output_parent.is_symlink():
        raise ValueError("Evaluation output parent must not be a symbolic link")
    output_parent = raw_output_parent.resolve(strict=True)
    parent_stat = output_parent.stat(follow_symlinks=False)
    if (
        output_parent.is_symlink()
        or not stat.S_ISDIR(parent_stat.st_mode)
        or stat.S_IMODE(parent_stat.st_mode) & 0o077
    ):
        raise ValueError("Evaluation output parent must be a private regular directory")
    output_directory = output_parent / f"deac_v2_descriptive_{evaluation_id}"
    output_directory.mkdir(mode=0o700)
    os.chmod(output_directory, 0o700)

    artifacts = {
        "deac_index_distribution.csv": _csv_bytes(
            ("record_type", "statistic", "value"), index_distribution
        ),
        "deac_index_histogram_bins.csv": _csv_bytes(
            ("bin_lower", "bin_upper", "count", "percent"), index_bins
        ),
        "observed_component_count_distribution.csv": _csv_bytes(
            ("group", "observed_components", "people", "percent"), observed_count_rows
        ),
        "component_score_distribution.csv": _csv_bytes(
            ("group", "component", "record_type", "score", "count", "percent_of_observed"),
            component_distribution_rows,
        ),
        "component_missingness.csv": _csv_bytes(
            ("group", "component", "people", "observed", "missing", "not_applicable", "missing_percent"),
            component_missing_rows,
        ),
        "component_group_missingness.csv": _csv_bytes(
            ("group", "component_subset", "components_n", "people", "missing_cells", "possible_cells", "missing_cell_percent", "people_with_any_missing", "people_with_all_missing"),
            component_group_rows,
        ),
        "annual_component_missingness.csv": _csv_bytes(
            ("clinic_visit_year", "group", "component", "people", "observed", "missing", "not_applicable", "missing_percent"),
            annual_component_missingness_rows,
        ),
        "baseline_group_comparison.csv": _csv_bytes(
            ("group", "field", "availability", "category", "n", "percent_group", "missing", "missing_percent", "mean", "sd_sample", "median", "q1", "q3", "min", "max"),
            baseline_rows,
        ),
        "deac_index_histogram.svg": _render_histogram(index_values, index_bins),
    }
    artifact_hashes = {
        name: _write_private(output_directory / name, content)
        for name, content in artifacts.items()
    }

    year_values = sorted({year for counts in year_counts_by_group.values() for year in counts})
    baseline_table = [
        "| Ryhmä | n | Ikä, keskiarvo (SD) | Ikä, mediaani (Q1–Q3) | Ikä puuttuu | "
        + " | ".join(str(year) for year in year_values)
        + " |",
        "|---|---:|---:|---:|---:|" + "---:|" * len(year_values),
    ]
    for group_name, label in (
        ("cohort", "Koko kohortti"),
        ("index_calculable", "Indeksi muodostui"),
        ("below_coverage", "Alle kattavuusrajan"),
    ):
        age_summary = age_summaries[group_name]
        year_counts = year_counts_by_group[group_name]
        baseline_table.append(
            "| "
            + " | ".join(
                [
                    label,
                    str(len(group_rows[group_name])),
                    f"{age_summary['mean']:.2f} ({age_summary['sd_sample']:.2f})",
                    f"{age_summary['median']:.0f} ({age_summary['q1']:.0f}–{age_summary['q3']:.0f})",
                    f"{age_missing_by_group[group_name]}/{len(group_rows[group_name])}",
                    *(
                        f"{year_counts[year]} ({year_counts[year]/len(group_rows[group_name]):.1%})"
                        for year in year_values
                    ),
                ]
            )
            + " |"
        )

    component_group_lookup = {
        (str(row["group"]), str(row["component_subset"])): row
        for row in component_group_rows
    }
    missingness_table = [
        "| Kattavuusryhmä | Osat 1–16 puuttuvat solut | Henkilöillä ≥1 puuttuva | Osat 17–20 puuttuvat solut | Henkilöillä ≥1 puuttuva | Kaikki 4 puuttuvat |",
        "|---|---:|---:|---:|---:|---:|",
    ]
    for group_name, label in (
        ("cohort", "Koko kohortti"),
        ("index_calculable", "Indeksi muodostui"),
        ("below_coverage", "Alle kattavuusrajan"),
    ):
        general = component_group_lookup[(group_name, "components_1_16")]
        performance = component_group_lookup[
            (group_name, "physical_performance_components_17_20")
        ]
        missingness_table.append(
            f"| {label} (n={len(group_rows[group_name])}) "
            f"| {general['missing_cells']}/{general['possible_cells']} "
            f"({general['missing_cell_percent']:.1%}) "
            f"| {general['people_with_any_missing']} "
            f"| {performance['missing_cells']}/{performance['possible_cells']} "
            f"({performance['missing_cell_percent']:.1%}) "
            f"| {performance['people_with_any_missing']} "
            f"| {performance['people_with_all_missing']} |"
        )

    late_year_shares = {
        group_name: sum(
            count
            for year, count in year_counts_by_group[group_name].items()
            if year >= 2015
        )
        / len(group_rows[group_name])
        for group_name in ("index_calculable", "below_coverage")
    }

    report_lines = [
        "# DEAC v2:n kuvaileva arviointi",
        "",
        f"- Arviointitunnus: `{evaluation_id}`",
        f"- Lähtöajo: `{run_manifest['run_id']}`",
        f"- Lähtömanifestin SHA-256: `{source_manifest_sha256}`",
        f"- Tulos-CSV:n SHA-256: `{run_manifest['output']['sha256']}`",
        f"- Lähtöajon koodin Git-HEAD: `{run_manifest['code_version']['git_head']}`",
        f"- Arviointikoodin pohja-HEAD: `{git_commit}`; arvioinnissa käytetty tiedosto yksilöidään SHA-256-tiivisteellä `{code_hash}`.",
        f"- Asetushashit (ei asetusten arvoja): `.env` `{config_hashes['env_sha256']}`, SourceBindings `{config_hashes['source_bindings_sha256']}`, valitsin `{config_hashes['cohort_selector_sha256']}`, MOI-korjaus `{run_manifest['moi']['correction_record_sha256']}`.",
        "- Laskentamoduulien tiedostokohtaiset SHA-256:t ovat arviointimanifestissa lähdeajon version alla.",
        "",
        "## Indeksi ja kattavuus",
        "",
        f"Indeksin laskentakelpoisia havaintoja oli {len(index_values)}. Keskiarvo oli {index_summary['mean']:.4f}, keskihajonta {index_summary['sd_sample']:.4f}, mediaani {index_summary['median']:.4f}, kvartiilit {index_summary['q1']:.4f} ja {index_summary['q3']:.4f}, vaihteluväli {index_summary['min']:.4f}–{index_summary['max']:.4f}.",
        "",
        "Histogrammi ja jakaumataulukko ovat suojatussa arviointihakemistossa. Havaittujen komponenttien lukumäärä tallentuu koko kohortille ja kattavuusryhmittäin.",
        "",
        "## Puuttuvuus",
        "",
        "Komponenttien pistejakaumat, puuttuvuusluvut ja kahden kuvailevan komponenttijoukon kasautumistaulukot tallentuvat erillisiin CSV-tiedostoihin. Käyntivuosittainen komponenttipuuttuvuus on tiedostossa `annual_component_missingness.csv` vuosittain, kattavuusryhmittäin ja komponenteittain. Joukko 17–20 vastaa handoverin neljää fyysisen suorituskyvyn osaa; osat 1–16 ovat vain tämän raportin vertailujoukko, eivät uusi domain-luokitus.",
        "",
        *missingness_table,
        "",
        f"Kattavuusrajan alittaneista {component_group_lookup[('below_coverage', 'physical_performance_components_17_20')]['people_with_all_missing']}/57:ltä puuttuivat kaikki neljä fyysisen suorituskyvyn osaa. Näin kasautuminen näkyy ryhmässä, mutta se ei yksin kerro puuttumisen syytä.",
        "",
        "Tuloksen participant CSV säilyttää normalisoidut komponenttipisteet mutta ei lähderivin puuttuvuuden syytä. Suojattu SourceBindings määrittää tavalliset puuttuvat arvot, testikohtaiset suoritusstatuskoodit sekä varmennetun kyvyttömyyden syykohtaisen käsittelyn. Tästä koosteesta ei voi kohdistaa yksittäistä puuttuvaa arvoa tiettyyn syyhyn. Tyhjä soluarvo, lähteen puuttuvakoodi, testin muu suoriutumattomuus ja oletettu kirjaamatta jäänyt mittaus on pidettävä erillään; niitä ei tulkita havaituiksi syiksi ilman syykohtaisia lähderivejä.",
        "",
        "## Lähtötilanteen ryhmävertailu",
        "",
        *baseline_table,
        "",
        f"Ikäjakauman keskiarvot ja mediaanit ovat ryhmissä lähellä toisiaan. Käyntivuosista 2015–2016 oli {late_year_shares['below_coverage']:.1%} kattavuusrajan alle jääneistä ja {late_year_shares['index_calculable']:.1%} indeksin saaneista; tämä on ajallinen yhteys, ei näyttö puuttuvuuden syystä.",
        "",
        "Lähtöikä on sidottu varmennetun SourceBindings-konfiguraation baseline_age_years-kenttään. Klinikkakäynnin vuosi johdetaan varmennetun ensimmäisen käynnin valitsimen päivämäärästä. Sukupuolta ei raportoida: suojatussa sidonnassa ei ole sukupuolikenttää eikä paikallinen FIRA1 Data Dictionary ole KAAOS-lähteen sanakirja. Kentän saatavuutta ei siten voi luokitella puuttuvaksi tai ei-puuttuvaksi.",
        "",
        "Ikä- ja vuosijakaumat sekä vertailukenttien havainto-/puuttuvuusmäärät ovat `baseline_group_comparison.csv`-tiedostossa. Tulokset ovat kuvailevia; ryhmien erilainen mittauskattavuus rajoittaa havaittujen komponenttiarvojen rinnastamista.",
        "",
        "## Seuraavan vaiheen ehdotukset (ei toteutettu)",
        "",
        "1. Varmista puuttuvien mittausten syyt suojatuista lähdekentistä ja raportoi vain aggregaatit.",
        "2. Selvitä käyntivuoden mukaan ositettuna, liittyykö vuoden 2015–2016 ryhmäero lähdemittauksen tai kirjaamisen saatavuuteen.",
        "3. Määrittele ennen jatkolaskentaa, mitkä kattavuuden tai komponenttien herkkyystarkastelut ovat tutkimuskysymyksen kannalta perusteltuja. Ne eivät korvaa hyväksyttyä ensisijaista laskentaa.",
        "",
        "## Rajaukset",
        "",
        "Tämä erä ei muuta hyväksyttyjä pisteytyssääntöjä tai 80 prosentin rajaa, eikä se ole validointitutkimus. Lähdesnapshot ja laskentakoodi on tarkistettu ajomanifestia vasten. Herkkyysanalyysit sekä puuttuvuuden syykohtainen lähderivianalyysi jäävät seuraavan vaiheen ehdotuksiksi.",
        "",
        "Kaikki tämän raportin taulukot ja histogrammi on kirjoitettu suojattuun arviointihakemistoon; henkilötunnisteita tai osallistujarivejä ei sisällytetä.",
        "",
    ]
    report_bytes = "\n".join(report_lines).encode("utf-8")
    artifact_hashes["report.md"] = _write_private(output_directory / "report.md", report_bytes)

    manifest = {
        "schema": "deac-v2-descriptive-evaluation-v1",
        "status": "AGGREGATE_DESCRIPTIVE_EVALUATION",
        "evaluation_id": evaluation_id,
        "source_run_id": run_manifest["run_id"],
        "source_run_manifest_sha256": source_manifest_sha256,
        "source_snapshot_sha256": source_sha256,
        "source_result_sha256": source_result_sha256,
        "source_run_code_version": run_manifest["code_version"],
        "evaluation_code": {
            "git_head_at_evaluation": git_commit,
            "sha256_of_executed_file": code_hash,
            "source_run_git_head": run_manifest["code_version"]["git_head"],
        },
        "configuration_sha256": {
            **config_hashes,
            "moi_correction_from_source_run": run_manifest["moi"]["correction_record_sha256"],
        },
        "counts": {
            "cohort": len(result_rows),
            "index_calculable": len(group_rows["index_calculable"]),
            "below_coverage": len(group_rows["below_coverage"]),
        },
        "baseline_bindings": {
            "age": "VERIFIED_PROTECTED_SOURCE_BINDING",
            "clinic_year": "VERIFIED_COHORT_SELECTOR_DATE",
            "sex": "NOT_VERIFIED_NO_PROTECTED_BINDING_OR_KAAOS_DICTIONARY",
        },
        "missingness_cause": {
            "status": "NOT_ATTRIBUTABLE_FROM_PARTICIPANT_RESULT_CSV",
            "source_reason_fields_present_in_runtime_config": len(bindings.reason_columns),
            "note": "No per-participant source reason values were copied to evaluation outputs.",
        },
        "artifact_sha256": artifact_hashes,
    }
    manifest_bytes = (json.dumps(manifest, ensure_ascii=False, indent=2, sort_keys=True) + "\n").encode()
    _write_private(output_directory / "evaluation_manifest.json", manifest_bytes)
    return output_directory


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", required=True)
    parser.add_argument("--env", required=True)
    parser.add_argument("--bindings", required=True)
    parser.add_argument("--selector", required=True)
    parser.add_argument("--output-parent", required=True)
    args = parser.parse_args()
    output = evaluate(args)
    final_manifest = json.loads((output / "evaluation_manifest.json").read_text())
    counts = final_manifest["counts"]
    print(
        "DEAC descriptive evaluation complete: "
        f"cohort={counts['cohort']} indexed={counts['index_calculable']} "
        f"below_coverage={counts['below_coverage']}"
    )
    print(f"protected_output={output.name}")


if __name__ == "__main__":
    main()
