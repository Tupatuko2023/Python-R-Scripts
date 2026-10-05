"""Protected command-line entry point for a version-locked DEAC v2 run."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
import sys
import stat
from datetime import date, datetime, timezone
from pathlib import Path
from typing import Any

from deac_cohort_runner import (
    MOIAgeRemovalCorrection,
    score_first_visit_cohort,
    select_first_visit_cohort,
    validate_xlsx_source_metadata,
    write_participant_results_csv,
)


def _read_env(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if line.startswith("export "):
            line = line[7:].lstrip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip().strip('"').strip("'")
    return values


def _resolve_source(env: dict[str, str], expected_sha256: str) -> Path:
    candidates: set[Path] = set()
    for key, value in env.items():
        if not value or not any(
            token in key.upper()
            for token in ("DATA", "SOURCE", "WORKBOOK", "AUTH", "XLS")
        ):
            continue
        path = Path(os.path.expandvars(os.path.expanduser(value)))
        if path.is_file():
            candidates.add(path)
        elif path.is_dir():
            candidates.update(path.glob("*.xls*"))
    matches = []
    for candidate in candidates:
        try:
            if _sha256_file(candidate) == expected_sha256:
                matches.append(candidate)
        except OSError:
            continue
    if len(matches) != 1:
        raise ValueError("Protected source configuration must resolve one approved snapshot")
    return matches[0]


def _sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def _require_private_file(path: Path) -> None:
    file_stat = path.stat(follow_symlinks=False)
    if not stat.S_ISREG(file_stat.st_mode) or stat.S_IMODE(file_stat.st_mode) & 0o077:
        raise ValueError("Protected runtime files must be regular files with private permissions")


def _resolve_identifier_position(
    configured_value: str, headers: tuple[str, ...], expected_position: int
) -> int:
    matches = [
        index + 1
        for index, header in enumerate(headers)
        if header.strip().casefold() == configured_value.strip().casefold()
    ]
    if len(matches) != 1 or matches[0] != expected_position:
        raise ValueError("Protected identifier selector does not match source metadata")
    return matches[0]


def _load_json(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError("Protected JSON configuration must be an object")
    return value


def _atomic_json(path: Path, value: dict[str, Any]) -> None:
    payload = (json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n").encode()
    temporary = path.with_name(f".{path.name}.{os.getpid()}.tmp")
    descriptor = os.open(temporary, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    try:
        os.fchmod(descriptor, 0o600)
        with os.fdopen(descriptor, "wb", closefd=False) as stream:
            stream.write(payload)
            stream.flush()
            os.fsync(stream.fileno())
    finally:
        os.close(descriptor)
    os.rename(temporary, path)
    directory_descriptor = os.open(path.parent, os.O_RDONLY | getattr(os, "O_DIRECTORY", 0))
    try:
        os.fsync(directory_descriptor)
    finally:
        os.close(directory_descriptor)


def run(args: argparse.Namespace) -> Path:
    env_path = Path(args.env).resolve(strict=True)
    bindings_path = Path(args.bindings).resolve(strict=True)
    selector_path = Path(args.selector).resolve(strict=True)
    correction_path = Path(args.correction).resolve(strict=True)
    for protected_file in (env_path, bindings_path, selector_path, correction_path):
        _require_private_file(protected_file)
    env = _read_env(env_path)
    bindings_config = _load_json(bindings_path)
    selector = _load_json(selector_path)
    correction_record = _load_json(correction_path)

    if selector.get("schema_version") != 1:
        raise ValueError("Unsupported protected cohort selector configuration")
    env_sha256 = _sha256_file(env_path)
    if selector.get("env_sha256") != env_sha256:
        raise ValueError("Protected cohort selector does not match the current env file")
    if selector.get("source_sha256") != bindings_config.get("source_sha256"):
        raise ValueError("Protected selector and source bindings refer to different snapshots")
    if env.get(selector.get("identifier_setting")) is None:
        raise ValueError("Protected identifier setting is missing")

    source_path = _resolve_source(env, bindings_config["source_sha256"])
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    source_bindings, metadata = validate_xlsx_source_metadata(
        source_path,
        bindings_config,
        sheet_name=bindings_config["sheet"],
        identifier_position_1based=selector["identifier_position_1based"],
    )
    identifier_position = _resolve_identifier_position(
        env[selector["identifier_setting"]],
        metadata.physical_headers,
        selector["identifier_position_1based"],
    )
    cohort = select_first_visit_cohort(
        source_path,
        metadata,
        source_bindings,
        data_start_row=bindings_config["data_start_row"],
        identifier_position_1based=identifier_position,
        visit_date_position_1based=selector["visit_date_position_1based"],
    )
    preflight = cohort.preflight
    expected = selector.get("expected_preflight", {})
    observed = {
        "source_rows": preflight.source_rows,
        "unique_people": preflight.unique_people,
        "later_visit_rows": preflight.later_visit_rows,
        "missing_identifiers": preflight.missing_identifiers,
        "missing_visit_dates": preflight.missing_visit_dates,
        "first_visit_conflict_people": preflight.first_visit_conflict_people,
    }
    if expected and observed != expected:
        raise ValueError("Cohort preflight differs from the protected expected summary")

    correction = MOIAgeRemovalCorrection(
        person_key=correction_record["person_key"],
        visit_date=date.fromisoformat(correction_record["baseline_visit"]),
        source_sha256=correction_record["source_sha256"],
        source_total=correction_record["source_moi_total"],
        baseline_age_years=correction_record["baseline_age_years"],
        corrected_without_age=correction_record["corrected_moi_without_age"],
        approval_reference=correction_record["approval_provenance"],
    )
    results, summary = score_first_visit_cohort(
        cohort, source_bindings, moi_correction=correction
    )

    now = datetime.now(timezone.utc)
    run_id = now.strftime("%Y%m%dT%H%M%SZ")
    parent = Path(args.output_parent).resolve(strict=True)
    run_dir = parent / f"deac_v2_run_{run_id}"
    run_dir.mkdir(mode=0o700)
    os.chmod(run_dir, 0o700)
    output_path = run_dir / f"deac_v2_participant_results_{run_id}.csv"
    write_participant_results_csv(results, output_path, protected_root=run_dir)

    source_files = {}
    for name in (
        "deac_cohort_runner.py",
        "deac_source_adapter.py",
        "deac_components.py",
        "deac_moi.py",
        "deac_index.py",
        "deac_run.py",
    ):
        source_files[name] = _sha256_file(Path(__file__).resolve().parent / name)
    repository_root = Path(__file__).resolve().parents[2]
    revision = subprocess.check_output(
        ["git", "rev-parse", "HEAD"], cwd=repository_root, text=True
    ).strip()
    manifest = {
        "manifest_schema": "deac-v2-protected-run-manifest-v1",
        "status": "VERIFIED_VERSION_LOCKED_RERUN",
        "run_id": run_id,
        "run_manifest_finalized_utc": now.isoformat(),
        "source": {"path_alias": "AUTH_SOURCE", "sha256": metadata.sha256},
        "runtime_bindings": {
            "path_alias": "protected SourceBindings",
            "sha256": _sha256_file(bindings_path),
        },
        "cohort_selector": {
            "config_path_alias": "protected cohort selector",
            "config_sha256": _sha256_file(selector_path),
            "env_path_alias": "repo config/.env",
            "env_sha256": env_sha256,
            "identifier_column_position_1based": identifier_position,
            "visit_date_column_position_1based": selector["visit_date_position_1based"],
            "selector_rule": selector["selector_rule"],
            **observed,
        },
        "moi": {
            "correction_record_path_alias": "protected MOI correction log",
            "correction_record_sha256": _sha256_file(correction_path),
            "age_points_removed_once": True,
            "reference_people": summary.moi_reference_people,
            "recomputed_cutpoints": list(summary.moi_cutpoints),
        },
        "coverage": {
            "minimum_fraction": 0.8,
            "eligible_people": summary.coverage_eligible_people,
            "insufficient_coverage_people": summary.insufficient_coverage_people,
            "index_calculable_people": summary.index_calculable_people,
        },
        "code_version": {"git_head": revision, "source_files": source_files},
        "output": {
            "relative_path": output_path.name,
            "sha256": _sha256_file(output_path),
            "record_count": len(results),
        },
        "aggregate_qc": {
            **observed,
            "moi_reference_people": summary.moi_reference_people,
            "moi_cutpoints": list(summary.moi_cutpoints),
            "coverage_eligible_people": summary.coverage_eligible_people,
            "insufficient_coverage_people": summary.insufficient_coverage_people,
            "index_calculable_people": summary.index_calculable_people,
        },
    }
    manifest_path = run_dir / f"deac_v2_run_manifest_{run_id}.json"
    _atomic_json(manifest_path, manifest)
    return manifest_path


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--env", required=True)
    parser.add_argument("--bindings", required=True)
    parser.add_argument("--selector", required=True)
    parser.add_argument("--correction", required=True)
    parser.add_argument("--output-parent", required=True)
    args = parser.parse_args()
    manifest = run(args)
    payload = json.loads(manifest.read_text(encoding="utf-8"))
    qc = payload["aggregate_qc"]
    print(f"manifest={manifest}")
    print(
        "QC: "
        f"source_rows={qc['source_rows']} people={qc['unique_people']} "
        f"later_visits={qc['later_visit_rows']} moi={qc['moi_reference_people']} "
        f"cutpoints={','.join(map(str, qc['moi_cutpoints']))} "
        f"indexes={qc['index_calculable_people']} below_coverage={qc['insufficient_coverage_people']}"
    )


if __name__ == "__main__":
    main()
