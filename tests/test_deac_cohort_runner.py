"""Synthetic tests for aggregate-only DEAC cohort orchestration."""

from __future__ import annotations

import os
import sys
from datetime import date
from hashlib import sha256
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile
from xml.etree import ElementTree as ET

import pytest


SRC_DIR = Path(__file__).resolve().parents[1] / "DEAC-Frailty-Index" / "src"
sys.path.insert(0, str(SRC_DIR))

from deac_cohort_runner import (  # noqa: E402
    FirstVisitCohort,
    DEACParticipantResult,
    MOIAgeRemovalCorrection,
    WorkbookCohortPreflight,
    iter_xlsx_source_rows,
    run_baseline_cohort,
    score_first_visit_cohort,
    select_first_visit_cohort,
    source_bindings_from_config,
    validate_xlsx_source_metadata,
    write_participant_results_csv,
)
from deac_source_adapter import PerformanceDisposition, SourceBindings  # noqa: E402


LOGICAL_FIELDS = {
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
    "selected_max_10m_seconds",
}


def _synthetic_cohort() -> tuple[list[dict[str, object]], SourceBindings]:
    columns = {field: f"synthetic_{field}" for field in LOGICAL_FIELDS}
    rows: list[dict[str, object]] = []
    for total in (2, 3, 4, 5, 6):
        row: dict[str, object] = {columns[field]: 0 for field in LOGICAL_FIELDS}
        row[columns["moi_total"]] = total
        row[columns["baseline_age_years"]] = 60
        row[columns["hearing"]] = 3
        row[columns["vision"]] = 4
        row[columns["pain_vas_cm"]] = 4.0
        row[columns["better_leg_stance_seconds"]] = 8.0
        row[columns["five_chair_rises_seconds"]] = 14.0
        row[columns["better_hand_grip_class"]] = 2
        row[columns["selected_max_10m_seconds"]] = 8.0
        rows.append(row)
    return rows, SourceBindings(columns=columns)


def _first_visit_cohort(
    rows: list[dict[str, object]], *, source_sha256: str = "a" * 64
) -> FirstVisitCohort:
    identifiers = tuple(f"synthetic-person-{index}" for index in range(len(rows)))
    dates = tuple(date(2026, 1, 1) for _ in rows)
    return FirstVisitCohort._from_selector(
        selected_records=tuple(zip(identifiers, dates, rows, strict=True)),
        source_sha256=source_sha256,
        preflight=WorkbookCohortPreflight(
            source_rows=len(rows),
            unique_people=len(rows),
            later_visit_rows=0,
            missing_identifiers=0,
            missing_visit_dates=0,
            first_visit_conflict_people=0,
        ),
    )


def test_runner_fits_moi_and_returns_only_cohort_aggregates() -> None:
    rows, bindings = _synthetic_cohort()
    summary = run_baseline_cohort(_first_visit_cohort(rows), bindings)

    assert summary.baseline_rows == 5
    assert summary.moi_reference_rows == 5
    assert summary.coverage_eligible_rows == 5
    assert summary.insufficient_coverage_rows == 0
    assert summary.index_calculable_rows == 5
    assert summary.missing_by_component["vision"] == 5
    assert len(summary.missing_by_component) == 20


def test_runner_excludes_rows_missing_moi_from_reference_but_keeps_them_in_cohort() -> None:
    rows, bindings = _synthetic_cohort()
    rows[0][bindings.columns["moi_total"]] = None
    summary = run_baseline_cohort(_first_visit_cohort(rows), bindings)

    assert summary.baseline_rows == 5
    assert summary.moi_reference_rows == 4
    assert summary.missing_by_component["moi"] == 1
    assert summary.index_calculable_rows == 5


def test_runner_rejects_unverified_row_factory() -> None:
    rows, bindings = _synthetic_cohort()
    with pytest.raises(ValueError, match="verified FirstVisitCohort"):
        run_baseline_cohort(lambda: iter(rows), bindings)  # type: ignore[arg-type]


def test_runner_rejects_directly_constructed_cohort_without_selector_origin() -> None:
    rows, bindings = _synthetic_cohort()
    forged = FirstVisitCohort(
        rows=tuple(rows),
        identifiers=tuple(f"synthetic-person-{i}" for i in range(len(rows))),
        visit_dates=tuple(date(2026, 1, 1) for _ in rows),
        source_sha256="a" * 64,
        preflight=WorkbookCohortPreflight(
            source_rows=len(rows),
            unique_people=len(rows),
            later_visit_rows=0,
            missing_identifiers=0,
            missing_visit_dates=0,
            first_visit_conflict_people=0,
        ),
    )

    with pytest.raises(ValueError, match="originate from the verified selector"):
        score_first_visit_cohort(forged, bindings)


def test_runner_rechecks_unique_keys_valid_dates_and_record_alignment() -> None:
    rows, bindings = _synthetic_cohort()
    one = rows[0]
    preflight = WorkbookCohortPreflight(
        source_rows=2,
        unique_people=2,
        later_visit_rows=0,
        missing_identifiers=0,
        missing_visit_dates=0,
        first_visit_conflict_people=0,
    )
    duplicate_keys = FirstVisitCohort._from_selector(
        selected_records=(
            ("synthetic-duplicate", date(2026, 1, 1), one),
            ("synthetic-duplicate", date(2026, 1, 2), rows[1]),
        ),
        source_sha256="a" * 64,
        preflight=preflight,
    )
    with pytest.raises(ValueError, match="duplicate person keys"):
        score_first_visit_cohort(duplicate_keys, bindings)

    invalid_date = FirstVisitCohort._from_selector(
        selected_records=(("synthetic-person", "2026-01-01", one),),  # type: ignore[arg-type]
        source_sha256="a" * 64,
        preflight=WorkbookCohortPreflight(1, 1, 0, 0, 0, 0),
    )
    with pytest.raises(ValueError, match="invalid visit date"):
        score_first_visit_cohort(invalid_date, bindings)

    valid = _first_visit_cohort(rows)
    object.__setattr__(
        valid,
        "_selection_records",
        (("synthetic-mismatched", valid.visit_dates[0], valid.rows[0]),
         *valid._selection_records[1:]),
    )
    with pytest.raises(ValueError, match="key, date, and row alignment"):
        score_first_visit_cohort(valid, bindings)


def test_selected_cohort_rows_cannot_be_mutated_after_validation() -> None:
    rows, bindings = _synthetic_cohort()
    cohort = _first_visit_cohort(rows)
    with pytest.raises(TypeError):
        cohort.rows[0][bindings.columns["moi_total"]] = 99  # type: ignore[index]
    assert run_baseline_cohort(cohort, bindings).baseline_rows == len(rows)


def test_runner_rejects_empty_cohort() -> None:
    _, bindings = _synthetic_cohort()
    with pytest.raises(ValueError, match="preflight is not fully resolved"):
        run_baseline_cohort(_first_visit_cohort([]), bindings)


def _first_visit_fixture_with_one_negative_moi() -> tuple[FirstVisitCohort, SourceBindings]:
    rows, bindings = _synthetic_cohort()
    rows[0][bindings.columns["moi_total"]] = 1
    return _first_visit_cohort(rows), bindings


def test_case_specific_moi_correction_sets_only_age_removed_value_to_zero() -> None:
    cohort, bindings = _first_visit_fixture_with_one_negative_moi()
    source_rows = tuple(dict(row) for row in cohort.rows)
    correction = MOIAgeRemovalCorrection(
        person_key=cohort.identifiers[0],
        visit_date=cohort.visit_dates[0],
        source_sha256=cohort.source_sha256,
        source_total=1,
        baseline_age_years=60,
        corrected_without_age=0.0,
        approval_reference="synthetic Owner/senior-biostatistician approval",
    )

    results, summary = score_first_visit_cohort(
        cohort, bindings, moi_correction=correction
    )

    assert summary.cohort_people == 5
    assert summary.moi_reference_people == 5
    assert results[0].component_scores["moi"] is not None
    assert tuple(dict(row) for row in cohort.rows) == source_rows
    assert "synthetic-person-0" not in repr(correction)
    assert "source_total=1" not in repr(correction)


def test_aggregate_and_detailed_routes_share_case_specific_moi_correction() -> None:
    cohort, bindings = _first_visit_fixture_with_one_negative_moi()
    correction = MOIAgeRemovalCorrection(
        person_key=cohort.identifiers[0],
        visit_date=cohort.visit_dates[0],
        source_sha256=cohort.source_sha256,
        source_total=1,
        baseline_age_years=60,
        corrected_without_age=0.0,
        approval_reference="synthetic Owner/senior-biostatistician approval",
    )

    detailed_results, detailed = score_first_visit_cohort(
        cohort, bindings, moi_correction=correction
    )
    aggregate = run_baseline_cohort(
        cohort, bindings, moi_correction=correction
    )

    assert aggregate.baseline_rows == detailed.cohort_people
    assert aggregate.moi_reference_rows == detailed.moi_reference_people == 5
    assert aggregate.moi_cutpoints == detailed.moi_cutpoints
    assert aggregate.coverage_eligible_rows == detailed.coverage_eligible_people
    assert aggregate.insufficient_coverage_rows == detailed.insufficient_coverage_people
    assert aggregate.index_calculable_rows == detailed.index_calculable_people
    assert aggregate.missing_by_component == detailed.missing_by_component
    assert aggregate.not_applicable_by_component == detailed.not_applicable_by_component
    assert detailed_results[0].component_scores["moi"] is not None


def test_new_negative_moi_still_fails_without_specific_correction() -> None:
    cohort, bindings = _first_visit_fixture_with_one_negative_moi()
    with pytest.raises(ValueError, match="age points exceed"):
        score_first_visit_cohort(cohort, bindings)


def test_moi_correction_must_match_exactly_one_record_and_source_values() -> None:
    cohort, bindings = _first_visit_fixture_with_one_negative_moi()
    missing_target = MOIAgeRemovalCorrection(
        person_key="not-in-cohort",
        visit_date=date(2026, 1, 1),
        source_sha256=cohort.source_sha256,
        source_total=1,
        baseline_age_years=60,
        corrected_without_age=0.0,
        approval_reference="synthetic approval",
    )
    with pytest.raises(ValueError, match="exactly one"):
        score_first_visit_cohort(cohort, bindings, moi_correction=missing_target)

    stale_record = MOIAgeRemovalCorrection(
        person_key=cohort.identifiers[0],
        visit_date=cohort.visit_dates[0],
        source_sha256=cohort.source_sha256,
        source_total=0,
        baseline_age_years=60,
        corrected_without_age=0.0,
        approval_reference="synthetic approval",
    )
    with pytest.raises(ValueError, match="no longer matches"):
        score_first_visit_cohort(cohort, bindings, moi_correction=stale_record)


def _synthetic_bindings_config() -> tuple[dict[str, object], list[str], list[str]]:
    fields = sorted(LOGICAL_FIELDS)
    headers = [f"synthetic_header_{index}" for index in range(1, len(fields) + 1)]
    labels = [f"synthetic_label_{index}" for index in range(1, len(fields) + 1)]
    config: dict[str, object] = {
        "schema_version": 1,
        "source_sha256": "a" * 64,
        "columns": dict(zip(fields, headers, strict=True)),
        "positions_1based": dict(
            zip(fields, range(1, len(fields) + 1), strict=True)
        ),
        "expected_labels": dict(zip(fields, labels, strict=True)),
        "ordinary_missing_codes": {"self_rated_mobility": [3]},
        "performance_codes": {
            "better_leg_stance_seconds": {
                "E": "other_nonperformance",
                "E1": "other_nonperformance",
            },
            "five_chair_rises_seconds": {
                "E": "other_nonperformance",
                "E1": "other_nonperformance",
            },
            "better_hand_grip_class": {
                "E": "other_nonperformance",
                "E1": "other_nonperformance",
            },
            "selected_max_10m_seconds": {
                "E": "other_nonperformance",
                "E1": "other_nonperformance",
            },
        },
    }
    return config, headers, labels


def test_runtime_bindings_require_matching_snapshot_and_metadata() -> None:
    config, headers, labels = _synthetic_bindings_config()
    bindings = source_bindings_from_config(
        config,
        actual_sha256="a" * 64,
        physical_headers=headers,
        label_row=labels,
    )

    assert bindings.columns["self_rated_mobility"] in headers


def test_runtime_bindings_fail_closed_on_snapshot_or_column_mismatch() -> None:
    config, headers, labels = _synthetic_bindings_config()
    with pytest.raises(ValueError, match="fingerprint"):
        source_bindings_from_config(
            config,
            actual_sha256="b" * 64,
            physical_headers=headers,
            label_row=labels,
        )

    config, headers, labels = _synthetic_bindings_config()
    config["positions_1based"]["self_rated_mobility"] = 1  # type: ignore[index]
    with pytest.raises(ValueError, match="duplicate"):
        source_bindings_from_config(
            config,
            actual_sha256="a" * 64,
            physical_headers=headers,
            label_row=labels,
        )


def _column_name(index: int) -> str:
    result = ""
    while index:
        index, remainder = divmod(index - 1, 26)
        result = chr(ord("A") + remainder) + result
    return result


def _write_synthetic_xlsx(
    path: Path,
    duplicate_identifier: bool = False,
    same_day_conflict: bool = False,
) -> dict[str, object]:
    config, headers, labels = _synthetic_bindings_config()
    fields = sorted(LOGICAL_FIELDS)
    identifier_position = len(fields) + 1
    visit_date_position = len(fields) + 2
    headers.append("synthetic_id_header")
    labels.append("synthetic_id_label")
    headers.append("synthetic_date_header")
    labels.append("synthetic_date_label")
    rows, _ = _synthetic_cohort()
    strings: list[str] = []
    string_indices: dict[str, int] = {}

    def shared(value: str) -> int:
        if value not in string_indices:
            string_indices[value] = len(strings)
            strings.append(value)
        return string_indices[value]

    for value in headers + labels:
        shared(value)
    sheet_data = ET.Element("{http://schemas.openxmlformats.org/spreadsheetml/2006/main}worksheet")
    sheet_data_node = ET.SubElement(sheet_data, "{http://schemas.openxmlformats.org/spreadsheetml/2006/main}sheetData")
    for row_number, values in (
        (2, headers),
        (3, labels),
    ):
        row_node = ET.SubElement(sheet_data_node, "{http://schemas.openxmlformats.org/spreadsheetml/2006/main}row", {"r": str(row_number)})
        for column, value in enumerate(values, 1):
            cell = ET.SubElement(row_node, "{http://schemas.openxmlformats.org/spreadsheetml/2006/main}c", {"r": f"{_column_name(column)}{row_number}", "t": "s"})
            ET.SubElement(cell, "{http://schemas.openxmlformats.org/spreadsheetml/2006/main}v").text = str(shared(value))
    for offset, source_row in enumerate(rows[:2]):
        row_number = offset + 4
        row_node = ET.SubElement(sheet_data_node, "{http://schemas.openxmlformats.org/spreadsheetml/2006/main}row", {"r": str(row_number)})
        for column, field in enumerate(fields, 1):
            value = source_row[f"synthetic_{field}"]
            if value is None:
                continue
            if isinstance(value, str):
                cell = ET.SubElement(row_node, "{http://schemas.openxmlformats.org/spreadsheetml/2006/main}c", {"r": f"{_column_name(column)}{row_number}", "t": "s"})
                ET.SubElement(cell, "{http://schemas.openxmlformats.org/spreadsheetml/2006/main}v").text = str(shared(value))
            else:
                cell = ET.SubElement(row_node, "{http://schemas.openxmlformats.org/spreadsheetml/2006/main}c", {"r": f"{_column_name(column)}{row_number}", "t": "n"})
                ET.SubElement(cell, "{http://schemas.openxmlformats.org/spreadsheetml/2006/main}v").text = str(value)
        identifier = "synthetic-person-1" if offset == 0 or duplicate_identifier else "synthetic-person-2"
        cell = ET.SubElement(row_node, "{http://schemas.openxmlformats.org/spreadsheetml/2006/main}c", {"r": f"{_column_name(identifier_position)}{row_number}", "t": "s"})
        ET.SubElement(cell, "{http://schemas.openxmlformats.org/spreadsheetml/2006/main}v").text = str(shared(identifier))
        visit_date = 2 if offset == 0 or same_day_conflict else 1
        cell = ET.SubElement(row_node, "{http://schemas.openxmlformats.org/spreadsheetml/2006/main}c", {"r": f"{_column_name(visit_date_position)}{row_number}", "s": "1", "t": "n"})
        ET.SubElement(cell, "{http://schemas.openxmlformats.org/spreadsheetml/2006/main}v").text = str(visit_date)

    shared_root = ET.Element("{http://schemas.openxmlformats.org/spreadsheetml/2006/main}sst", {"count": str(len(strings)), "uniqueCount": str(len(strings))})
    for value in strings:
        si = ET.SubElement(shared_root, "{http://schemas.openxmlformats.org/spreadsheetml/2006/main}si")
        ET.SubElement(si, "{http://schemas.openxmlformats.org/spreadsheetml/2006/main}t").text = value
    workbook_xml = b'''<?xml version="1.0" encoding="UTF-8"?><workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets><sheet name="Taul1" sheetId="1" r:id="rId1"/></sheets></workbook>'''
    rels_xml = b'''<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/></Relationships>'''
    styles_xml = b'''<?xml version="1.0" encoding="UTF-8"?><styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><numFmts count="0"/><fonts count="1"><font/></fonts><fills count="1"><fill><patternFill patternType="none"/></fill></fills><borders count="1"><border/></borders><cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs><cellXfs count="2"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/><xf numFmtId="14" fontId="0" fillId="0" borderId="0" applyNumberFormat="1"/></cellXfs></styleSheet>'''
    with ZipFile(path, "w", ZIP_DEFLATED) as archive:
        archive.writestr("xl/workbook.xml", workbook_xml)
        archive.writestr("xl/_rels/workbook.xml.rels", rels_xml)
        archive.writestr("xl/sharedStrings.xml", ET.tostring(shared_root, encoding="utf-8", xml_declaration=True))
        archive.writestr("xl/worksheets/sheet1.xml", ET.tostring(sheet_data, encoding="utf-8", xml_declaration=True))
        archive.writestr("xl/styles.xml", styles_xml)
    config["source_sha256"] = sha256(path.read_bytes()).hexdigest()
    config["header_row"] = 2
    config["label_row"] = 3
    config["data_start_row"] = 4
    return {
        "config": config,
        "identifier_position": identifier_position,
        "visit_date_position": visit_date_position,
        "headers": headers,
        "labels": labels,
    }


def test_xlsx_metadata_validation_and_first_visit_selection(tmp_path: Path) -> None:
    fixture = _write_synthetic_xlsx(tmp_path / "synthetic.xlsx")
    config = fixture["config"]
    bindings, metadata = validate_xlsx_source_metadata(
        tmp_path / "synthetic.xlsx",
        config,  # type: ignore[arg-type]
        sheet_name="Taul1",
        identifier_position_1based=fixture["identifier_position"],  # type: ignore[arg-type]
    )
    selection = select_first_visit_cohort(
        tmp_path / "synthetic.xlsx",
        metadata,
        bindings,
        data_start_row=4,
        identifier_position_1based=fixture["identifier_position"],  # type: ignore[arg-type]
        visit_date_position_1based=fixture["visit_date_position"],  # type: ignore[arg-type]
    )
    assert selection.preflight.source_rows == 2
    assert selection.preflight.unique_people == 2
    assert selection.preflight.later_visit_rows == 0
    assert selection.preflight.missing_identifiers == 0
    assert selection.preflight.missing_visit_dates == 0
    assert selection.preflight.first_visit_conflict_people == 0
    summary = run_baseline_cohort(selection, bindings)
    assert summary.baseline_rows == 2
    assert summary.index_calculable_rows == 2


def test_xlsx_first_visit_selection_uses_earliest_date_not_row_order(
    tmp_path: Path,
) -> None:
    fixture = _write_synthetic_xlsx(
        tmp_path / "duplicate.xlsx", duplicate_identifier=True
    )
    bindings, metadata = validate_xlsx_source_metadata(
        tmp_path / "duplicate.xlsx",
        fixture["config"],  # type: ignore[arg-type]
        sheet_name="Taul1",
        identifier_position_1based=fixture["identifier_position"],  # type: ignore[arg-type]
    )
    selection = select_first_visit_cohort(
        tmp_path / "duplicate.xlsx",
        metadata,
        bindings,
        data_start_row=4,
        identifier_position_1based=fixture["identifier_position"],  # type: ignore[arg-type]
        visit_date_position_1based=fixture["visit_date_position"],  # type: ignore[arg-type]
    )
    assert selection.preflight.source_rows == 2
    assert selection.preflight.unique_people == 1
    assert selection.preflight.later_visit_rows == 1
    assert selection.preflight.first_visit_conflict_people == 0
    assert len(selection.rows) == 1
    # The second source row has the earlier date and is selected, independent
    # of its physical position in the workbook.
    assert selection.rows[0][bindings.columns["moi_total"]] == 3


def test_xlsx_first_visit_conflict_is_visible_without_choosing_a_row(
    tmp_path: Path,
) -> None:
    fixture = _write_synthetic_xlsx(
        tmp_path / "first-date-conflict.xlsx",
        duplicate_identifier=True,
        same_day_conflict=True,
    )
    bindings, metadata = validate_xlsx_source_metadata(
        tmp_path / "first-date-conflict.xlsx",
        fixture["config"],  # type: ignore[arg-type]
        sheet_name="Taul1",
        identifier_position_1based=fixture["identifier_position"],  # type: ignore[arg-type]
    )
    selection = select_first_visit_cohort(
        tmp_path / "first-date-conflict.xlsx",
        metadata,
        bindings,
        data_start_row=4,
        identifier_position_1based=fixture["identifier_position"],  # type: ignore[arg-type]
        visit_date_position_1based=fixture["visit_date_position"],  # type: ignore[arg-type]
    )
    assert selection.preflight.first_visit_conflict_people == 1
    assert selection.rows == ()


def test_xlsx_reader_rejects_source_change_after_metadata_validation(tmp_path: Path) -> None:
    fixture = _write_synthetic_xlsx(tmp_path / "changed.xlsx")
    config = fixture["config"]
    bindings, metadata = validate_xlsx_source_metadata(
        tmp_path / "changed.xlsx",
        config,  # type: ignore[arg-type]
        sheet_name="Taul1",
        identifier_position_1based=fixture["identifier_position"],  # type: ignore[arg-type]
    )
    with (tmp_path / "changed.xlsx").open("ab") as stream:
        stream.write(b"mutation")
    with pytest.raises(ValueError, match="changed after metadata validation"):
        list(
            iter_xlsx_source_rows(
                tmp_path / "changed.xlsx",
                metadata,
                bindings,
                data_start_row=4,
                identifier_position_1based=fixture["identifier_position"],  # type: ignore[arg-type]
                visit_date_position_1based=fixture["visit_date_position"],  # type: ignore[arg-type]
            )
        )


def test_xlsx_reader_rejects_replaced_snapshot_after_metadata_validation(
    tmp_path: Path,
) -> None:
    source = tmp_path / "replace.xlsx"
    fixture = _write_synthetic_xlsx(source)
    bindings, metadata = validate_xlsx_source_metadata(
        source,
        fixture["config"],  # type: ignore[arg-type]
        sheet_name="Taul1",
        identifier_position_1based=fixture["identifier_position"],  # type: ignore[arg-type]
    )
    replacement = tmp_path / "replacement.xlsx"
    replacement.write_bytes(source.read_bytes())
    os.replace(replacement, source)

    with pytest.raises(ValueError, match="changed after metadata validation"):
        list(
            iter_xlsx_source_rows(
                source,
                metadata,
                bindings,
                data_start_row=4,
                identifier_position_1based=fixture["identifier_position"],  # type: ignore[arg-type]
                visit_date_position_1based=fixture["visit_date_position"],  # type: ignore[arg-type]
            )
        )


def _protected_test_results() -> tuple[DEACParticipantResult, ...]:
    rows, bindings = _synthetic_cohort()
    results, _ = score_first_visit_cohort(_first_visit_cohort(rows), bindings)
    return results


def test_participant_csv_publishes_atomically_without_overwrite(tmp_path: Path) -> None:
    protected_root = tmp_path / "protected"
    protected_root.mkdir(mode=0o700)
    os.chmod(protected_root, 0o700)
    target = protected_root / "participants.csv"
    results = _protected_test_results()

    write_participant_results_csv(results, target, protected_root=protected_root)
    assert target.is_file()
    assert target.stat().st_mode & 0o777 == 0o600
    original = target.read_bytes()

    with pytest.raises(FileExistsError):
        write_participant_results_csv(results, target, protected_root=protected_root)
    assert target.read_bytes() == original


def test_participant_csv_rejects_symlinked_intermediate_directory(
    tmp_path: Path,
) -> None:
    protected_root = tmp_path / "protected"
    protected_root.mkdir(mode=0o700)
    os.chmod(protected_root, 0o700)
    outside = tmp_path / "outside"
    outside.mkdir(mode=0o700)
    os.chmod(outside, 0o700)
    (protected_root / "redirect").symlink_to(outside, target_is_directory=True)

    with pytest.raises(OSError):
        write_participant_results_csv(
            _protected_test_results(),
            protected_root / "redirect" / "participants.csv",
            protected_root=protected_root,
        )
    assert not (outside / "participants.csv").exists()


def test_participant_csv_failure_mid_write_cleans_temporary_file(
    tmp_path: Path,
) -> None:
    protected_root = tmp_path / "protected"
    protected_root.mkdir(mode=0o700)
    os.chmod(protected_root, 0o700)
    target = protected_root / "participants.csv"
    results = _protected_test_results()

    def fail_after_one_row():
        yield results[0]
        raise RuntimeError("synthetic interrupted result stream")

    with pytest.raises(RuntimeError, match="interrupted result stream"):
        write_participant_results_csv(
            fail_after_one_row(), target, protected_root=protected_root
        )
    assert not target.exists()
    assert list(protected_root.iterdir()) == []
