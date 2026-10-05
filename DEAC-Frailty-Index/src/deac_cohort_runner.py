"""Aggregate-only DEAC runner core for an already selected baseline cohort.

This module deliberately does not open workbooks, select visits, or emit
participant rows. A protected source reader must validate its snapshot and
metadata before supplying a re-iterable baseline-row factory.
"""

from __future__ import annotations

import csv
import os
import stat
from collections import Counter
from collections.abc import Iterable, Mapping
from dataclasses import dataclass, field
from datetime import date, datetime, timedelta
from hashlib import sha256
from math import isfinite
from pathlib import Path
import posixpath
import re
from xml.etree import ElementTree as ET
from zipfile import BadZipFile, ZipFile

from deac_index import COMPONENT_NAMES, ComponentStatus, assemble_deac_index
from deac_moi import (
    fit_moi_quintile_cutpoints,
    remove_moi_age_points,
    waris_2011_age_points,
)
from deac_source_adapter import (
    PerformanceDisposition,
    SourceBindings,
    _read_value,
    _validate_bindings,
    score_source_row,
    validate_source_schema_bindings,
)


Row = Mapping[str, object]

_MAIN_NS = "http://schemas.openxmlformats.org/spreadsheetml/2006/main"
_DOC_REL_NS = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
_PKG_REL_NS = "http://schemas.openxmlformats.org/package/2006/relationships"


@dataclass(frozen=True)
class WorkbookMetadata:
    """Metadata-only identity and sheet location for one validated workbook."""

    sha256: str
    sheet_path: str
    physical_headers: tuple[str, ...]
    label_row: tuple[str, ...]
    positions_by_field: Mapping[str, int]
    date_style_ids: frozenset[int]
    date_1904: bool


@dataclass(frozen=True)
class WorkbookCohortPreflight:
    """Privacy-minimized workbook row/identifier checks."""

    source_rows: int
    unique_people: int
    later_visit_rows: int
    missing_identifiers: int
    missing_visit_dates: int
    first_visit_conflict_people: int


@dataclass(frozen=True)
class FirstVisitCohort:
    """Selected first-visit rows plus aggregate QC; rows are hidden from repr."""

    rows: tuple[Row, ...] = field(repr=False)
    identifiers: tuple[str, ...] = field(repr=False)
    visit_dates: tuple[date, ...] = field(repr=False)
    source_sha256: str
    preflight: WorkbookCohortPreflight


@dataclass(frozen=True)
class MOIAgeRemovalCorrection:
    """One approved, row-specific correction; sensitive fields stay repr-hidden."""

    person_key: str = field(repr=False)
    visit_date: date = field(repr=False)
    source_sha256: str
    source_total: int | float = field(repr=False)
    baseline_age_years: int = field(repr=False)
    corrected_without_age: float = field(repr=False)
    approval_reference: str

    def __post_init__(self) -> None:
        if not isinstance(self.person_key, str) or not self.person_key.strip():
            raise ValueError("MOI correction requires one protected person key")
        if not isinstance(self.visit_date, date):
            raise ValueError("MOI correction requires the protected baseline visit date")
        if not isinstance(self.source_sha256, str) or not re.fullmatch(
            r"[0-9a-f]{64}", self.source_sha256
        ):
            raise ValueError("MOI correction requires a lowercase source snapshot SHA-256")
        if not isinstance(self.approval_reference, str) or not self.approval_reference.strip():
            raise ValueError("MOI correction requires approval provenance")
        if self.corrected_without_age != 0.0:
            raise ValueError("This approved MOI correction must set age-removed value to zero")
        try:
            remove_moi_age_points(self.source_total, self.baseline_age_years)
        except ValueError as exc:
            if str(exc) != "MOI age points exceed the age-inclusive MOI index":
                raise
        else:
            raise ValueError("MOI correction applies only to a negative age-removed value")

    @property
    def age_points(self) -> int:
        return waris_2011_age_points(self.baseline_age_years)


@dataclass(frozen=True)
class DEACParticipantResult:
    """Participant-level output record; repr hides both ID and component vector."""

    identifier: str = field(repr=False)
    component_scores: Mapping[str, object] = field(repr=False)
    deac_index: float | None
    observed_components: int
    relevant_components: int
    coverage: float
    eligible: bool


@dataclass(frozen=True)
class DEACRunSummary:
    """Aggregate-only QC from a complete selected baseline cohort."""

    cohort_people: int
    moi_reference_people: int
    moi_cutpoints: tuple[float, float, float, float]
    coverage_eligible_people: int
    insufficient_coverage_people: int
    index_calculable_people: int
    missing_by_component: Mapping[str, int]
    not_applicable_by_component: Mapping[str, int]
    index_mean: float | None
    index_median: float | None
    index_min: float | None
    index_max: float | None


def _sha256_file(path: Path) -> str:
    digest = sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def _sheet_member(archive: ZipFile, sheet_name: str) -> str:
    workbook = ET.fromstring(archive.read("xl/workbook.xml"))
    relationships = ET.fromstring(archive.read("xl/_rels/workbook.xml.rels"))
    relationship_targets = {
        relationship.attrib["Id"]: relationship.attrib["Target"]
        for relationship in relationships.findall(f"{{{_PKG_REL_NS}}}Relationship")
    }
    for sheet in workbook.findall(f".//{{{_MAIN_NS}}}sheet"):
        if sheet.attrib.get("name") == sheet_name:
            relation_id = sheet.attrib.get(f"{{{_DOC_REL_NS}}}id")
            target = relationship_targets.get(relation_id or "")
            if target is None:
                break
            if target.startswith("/"):
                return target.lstrip("/")
            return posixpath.normpath(posixpath.join("xl", target))
    raise ValueError("Required worksheet is missing from source workbook")


def _shared_strings(archive: ZipFile) -> list[str]:
    try:
        root = ET.fromstring(archive.read("xl/sharedStrings.xml"))
    except KeyError:
        return []
    return [
        "".join(text.text or "" for text in item.findall(f".//{{{_MAIN_NS}}}t"))
        for item in root.findall(f"{{{_MAIN_NS}}}si")
    ]


def _date_style_metadata(archive: ZipFile) -> tuple[frozenset[int], bool]:
    builtin_date_formats = set(range(14, 23)) | set(range(27, 37)) | set(
        range(45, 48)
    ) | set(range(50, 59))
    try:
        styles = ET.fromstring(archive.read("xl/styles.xml"))
    except KeyError:
        return frozenset(), False
    custom_formats = {
        int(item.attrib["numFmtId"]): item.attrib.get("formatCode", "")
        for item in styles.findall(f".//{{{_MAIN_NS}}}numFmt")
    }
    cell_xfs = styles.find(f"{{{_MAIN_NS}}}cellXfs")
    date_styles: set[int] = set()
    if cell_xfs is not None:
        for style_index, style in enumerate(cell_xfs):
            try:
                num_format_id = int(style.attrib.get("numFmtId", "0"))
            except ValueError:
                continue
            format_code = re.sub(
                r'"[^"]*"|\\.|_.', "", custom_formats.get(num_format_id, "")
            ).casefold()
            custom_date = (
                "y" in format_code and ("d" in format_code or "m" in format_code)
            )
            if num_format_id in builtin_date_formats or custom_date:
                date_styles.add(style_index)
    try:
        workbook = ET.fromstring(archive.read("xl/workbook.xml"))
        workbook_properties = workbook.find(f"{{{_MAIN_NS}}}workbookPr")
        date_1904 = bool(
            workbook_properties is not None
            and workbook_properties.attrib.get("date1904", "0").casefold()
            in {"1", "true"}
        )
    except KeyError:
        date_1904 = False
    return frozenset(date_styles), date_1904


def _column_index(cell_reference: str) -> int:
    letters = re.match(r"([A-Z]+)", cell_reference.upper())
    if letters is None:
        raise ValueError("Workbook contains an invalid cell reference")
    index = 0
    for character in letters.group(1):
        index = index * 26 + ord(character) - ord("A") + 1
    return index - 1


def _cell_text(cell: ET.Element | None, shared_strings: list[str]) -> str:
    if cell is None:
        return ""
    cell_type = cell.attrib.get("t")
    if cell_type == "inlineStr":
        return "".join(
            text.text or "" for text in cell.findall(f".//{{{_MAIN_NS}}}t")
        )
    value = cell.find(f"{{{_MAIN_NS}}}v")
    if value is None or value.text is None:
        return ""
    if cell_type == "s":
        try:
            return shared_strings[int(value.text)]
        except (IndexError, ValueError) as exc:
            raise ValueError("Workbook contains an invalid shared-string index") from exc
    if cell_type == "e":
        raise ValueError("Workbook contains an error cell in a selected field")
    return value.text


def _metadata_rows(
    archive: ZipFile,
    sheet_path: str,
    header_row: int,
    label_row: int,
) -> tuple[tuple[str, ...], tuple[str, ...]]:
    shared_strings = _shared_strings(archive)
    found: dict[int, tuple[str, ...]] = {}
    with archive.open(sheet_path) as stream:
        for _, element in ET.iterparse(stream, events=("end",)):
            if element.tag != f"{{{_MAIN_NS}}}row":
                continue
            try:
                row_number = int(element.attrib.get("r", "0"))
            except ValueError as exc:
                raise ValueError("Workbook contains an invalid row number") from exc
            if row_number in (header_row, label_row):
                cells = {
                    _column_index(cell.attrib.get("r", "")): _cell_text(
                        cell, shared_strings
                    )
                    for cell in element.findall(f"{{{_MAIN_NS}}}c")
                }
                width = max(cells, default=-1) + 1
                found[row_number] = tuple(cells.get(i, "") for i in range(width))
            element.clear()
            if len(found) == 2:
                break
    if header_row not in found or label_row not in found:
        raise ValueError("Workbook is missing the configured metadata rows")
    return found[header_row], found[label_row]


def validate_xlsx_source_metadata(
    path: str | Path,
    config: Mapping[str, object],
    *,
    sheet_name: str,
    identifier_position_1based: int,
) -> tuple[SourceBindings, WorkbookMetadata]:
    """Validate source hash and metadata before any participant rows are read."""
    workbook_path = Path(path)
    actual_sha256 = _sha256_file(workbook_path)
    try:
        with ZipFile(workbook_path) as archive:
            sheet_path = _sheet_member(archive, sheet_name)
            header_row = config.get("header_row")
            label_row_number = config.get("label_row")
            if (
                isinstance(header_row, bool)
                or not isinstance(header_row, int)
                or isinstance(label_row_number, bool)
                or not isinstance(label_row_number, int)
            ):
                raise ValueError("Protected workbook metadata rows are invalid")
            headers, labels = _metadata_rows(
                archive, sheet_path, header_row, label_row_number
            )
            date_style_ids, date_1904 = _date_style_metadata(archive)
    except BadZipFile as exc:
        raise ValueError("Source workbook is not a valid XLSX package") from exc

    bindings = source_bindings_from_config(
        config,
        actual_sha256=actual_sha256,
        physical_headers=headers,
        label_row=labels,
    )
    positions = config.get("positions_1based")
    if not isinstance(positions, Mapping):
        raise ValueError("Protected source positions must be a mapping")
    bound_positions = set(positions.values())
    if (
        isinstance(identifier_position_1based, bool)
        or not isinstance(identifier_position_1based, int)
        or not 1 <= identifier_position_1based <= len(headers)
        or identifier_position_1based in bound_positions
    ):
        raise ValueError("Protected identifier binding is invalid or overlaps a component")
    if not headers[identifier_position_1based - 1].strip() or not labels[
        identifier_position_1based - 1
    ].strip():
        raise ValueError("Protected identifier metadata is incomplete")
    metadata = WorkbookMetadata(
        sha256=actual_sha256,
        sheet_path=sheet_path,
        physical_headers=headers,
        label_row=labels,
        positions_by_field={
            field: position - 1 for field, position in positions.items()
        },
        date_style_ids=date_style_ids,
        date_1904=date_1904,
    )
    return bindings, metadata


def _numeric_cell_value(value: str, cell_type: str | None) -> object:
    if value == "":
        return None
    if cell_type in {"s", "inlineStr", "str"}:
        candidate = value.strip()
        if not re.fullmatch(
            r"[+-]?\d+(?:[.,]\d+)?(?:[eE][+-]?\d+)?", candidate
        ):
            return value
        value = candidate.replace(",", ".")
    if cell_type == "b":
        return value == "1"
    try:
        numeric = float(value)
    except ValueError:
        return value
    if numeric.is_integer():
        return int(numeric)
    return numeric


def _clinic_date_value(
    cell: ET.Element | None, value: str, metadata: WorkbookMetadata
) -> date | None:
    if value == "":
        return None
    cell_type = None if cell is None else cell.attrib.get("t")
    if cell_type == "d":
        try:
            return datetime.fromisoformat(value.replace("Z", "+00:00")).date()
        except ValueError as exc:
            raise ValueError("Clinic visit date is not in a supported ISO form") from exc
    if cell_type in {"s", "inlineStr", "str"}:
        try:
            return date.fromisoformat(value[:10])
        except ValueError as exc:
            raise ValueError("Clinic visit date is not in a supported ISO form") from exc
    if cell is None:
        return None
    try:
        style_id = int(cell.attrib.get("s", "0"))
        serial = float(value)
    except ValueError as exc:
        raise ValueError("Clinic visit date is not a valid date cell") from exc
    if style_id not in metadata.date_style_ids:
        raise ValueError("Clinic visit date cell lacks a date-formatted style")
    origin = date(1904, 1, 1) if metadata.date_1904 else date(1899, 12, 30)
    try:
        return origin + timedelta(days=serial)
    except OverflowError as exc:
        raise ValueError("Clinic visit date is outside the supported range") from exc


def iter_xlsx_source_rows(
    path: str | Path,
    metadata: WorkbookMetadata,
    bindings: SourceBindings,
    *,
    data_start_row: int,
    identifier_position_1based: int,
    visit_date_position_1based: int,
) -> Iterable[tuple[str | None, date | None, Row]]:
    """Yield selected source cells only; never log identifiers or row values."""
    workbook_path = Path(path)
    if _sha256_file(workbook_path) != metadata.sha256:
        raise ValueError("Source workbook changed after metadata validation")
    if set(metadata.positions_by_field) != set(bindings.columns):
        raise ValueError("Protected field positions do not match SourceBindings")
    field_positions = dict(metadata.positions_by_field)
    selected_positions = set(field_positions.values())
    identifier_index = identifier_position_1based - 1
    visit_date_index = visit_date_position_1based - 1
    if not 0 <= visit_date_index < len(metadata.physical_headers):
        raise ValueError("Protected clinic-date binding is outside the source schema")
    if visit_date_index in selected_positions or visit_date_index == identifier_index:
        raise ValueError("Clinic date, identifier, and component fields must be distinct")
    selected_positions.update((identifier_index, visit_date_index))
    with ZipFile(workbook_path) as archive:
        shared_strings = _shared_strings(archive)
        with archive.open(metadata.sheet_path) as stream:
            for _, element in ET.iterparse(stream, events=("end",)):
                if element.tag != f"{{{_MAIN_NS}}}row":
                    continue
                try:
                    row_number = int(element.attrib.get("r", "0"))
                except ValueError as exc:
                    raise ValueError("Workbook contains an invalid row number") from exc
                if row_number < data_start_row:
                    element.clear()
                    continue
                selected_cells: dict[int, ET.Element] = {}
                for cell in element.findall(f"{{{_MAIN_NS}}}c"):
                    index = _column_index(cell.attrib.get("r", ""))
                    if index in selected_positions:
                        selected_cells[index] = cell
                raw: dict[int, object] = {}
                for index in selected_positions:
                    cell = selected_cells.get(index)
                    cell_text = _cell_text(cell, shared_strings)
                    if index == identifier_index:
                        raw[index] = cell_text
                    else:
                        raw[index] = _numeric_cell_value(
                            cell_text,
                            None if cell is None else cell.attrib.get("t"),
                        )
                identifier_value = raw[identifier_index]
                identifier = (
                    None
                    if identifier_value is None or not str(identifier_value).strip()
                    else str(identifier_value).strip()
                )
                date_cell = selected_cells.get(visit_date_index)
                visit_date = _clinic_date_value(
                    date_cell,
                    _cell_text(date_cell, shared_strings),
                    metadata,
                )
                row = {
                    bindings.columns[field_name]: raw[index]
                    for field_name, index in field_positions.items()
                }
                has_component_data = any(value is not None for value in row.values())
                if identifier is None and visit_date is None and not has_component_data:
                    element.clear()
                    continue
                yield identifier, visit_date, row
                element.clear()


def select_first_visit_cohort(
    path: str | Path,
    metadata: WorkbookMetadata,
    bindings: SourceBindings,
    *,
    data_start_row: int,
    identifier_position_1based: int,
    visit_date_position_1based: int,
) -> FirstVisitCohort:
    """Select the earliest dated record per verified person key, order-free."""
    records_by_person: dict[str, list[tuple[date, Row]]] = {}
    row_count = missing_ids = missing_dates = 0
    for identifier, visit_date, row in iter_xlsx_source_rows(
        path,
        metadata,
        bindings,
        data_start_row=data_start_row,
        identifier_position_1based=identifier_position_1based,
        visit_date_position_1based=visit_date_position_1based,
    ):
        row_count += 1
        if identifier is None:
            missing_ids += 1
            continue
        if visit_date is None:
            missing_dates += 1
            continue
        records_by_person.setdefault(identifier, []).append((visit_date, row))

    selected: list[tuple[str, date, Row]] = []
    later_visit_rows = conflict_people = 0
    for next_id, records in records_by_person.items():
        first_date = min(record_date for record_date, _ in records)
        first_day_rows = [row for record_date, row in records if record_date == first_date]
        later_visit_rows += len(records) - len(first_day_rows)
        canonical_row = first_day_rows[0]
        if any(row != canonical_row for row in first_day_rows[1:]):
            conflict_people += 1
        else:
            selected.append((next_id, first_date, canonical_row))

    preflight = WorkbookCohortPreflight(
        source_rows=row_count,
        unique_people=len(records_by_person),
        later_visit_rows=later_visit_rows,
        missing_identifiers=missing_ids,
        missing_visit_dates=missing_dates,
        first_visit_conflict_people=conflict_people,
    )
    selected.sort(key=lambda item: item[0])
    return FirstVisitCohort(
        rows=tuple(row for _, _, row in selected),
        identifiers=tuple(identifier for identifier, _, _ in selected),
        visit_dates=tuple(visit_date for _, visit_date, _ in selected),
        source_sha256=metadata.sha256,
        preflight=preflight,
    )


def score_first_visit_cohort(
    cohort: FirstVisitCohort,
    bindings: SourceBindings,
    *,
    moi_correction: MOIAgeRemovalCorrection | None = None,
) -> tuple[tuple[DEACParticipantResult, ...], DEACRunSummary]:
    """Score a verified, conflict-free first-visit cohort in memory."""
    preflight = cohort.preflight
    if (
        preflight.missing_identifiers
        or preflight.missing_visit_dates
        or preflight.first_visit_conflict_people
        or len(cohort.rows) != preflight.unique_people
        or len(cohort.identifiers) != preflight.unique_people
        or len(cohort.visit_dates) != preflight.unique_people
    ):
        raise ValueError("First-visit cohort preflight is not fully resolved")
    correction_matches = 0
    if moi_correction is not None:
        if cohort.source_sha256 != moi_correction.source_sha256:
            raise ValueError("Protected MOI correction source snapshot does not match")
        correction_matches = sum(
            identifier == moi_correction.person_key
            and visit_date == moi_correction.visit_date
            for identifier, visit_date in zip(
                cohort.identifiers, cohort.visit_dates, strict=True
            )
        )
        if correction_matches != 1:
            raise ValueError("Protected MOI correction must match exactly one cohort record")
    moi_values: list[float] = []
    for identifier, visit_date, row in zip(
        cohort.identifiers, cohort.visit_dates, cohort.rows, strict=True
    ):
        value = _age_removed_moi(
            row,
            bindings,
            person_key=identifier,
            visit_date=visit_date,
            correction=moi_correction,
        )
        if value is not None:
            moi_values.append(value)
    cutpoints = fit_moi_quintile_cutpoints(moi_values)
    missing = Counter({name: 0 for name in COMPONENT_NAMES})
    not_applicable = Counter({name: 0 for name in COMPONENT_NAMES})
    outputs: list[DEACParticipantResult] = []
    indices: list[float] = []
    eligible_people = insufficient_people = 0

    for identifier, visit_date, row in zip(
        cohort.identifiers, cohort.visit_dates, cohort.rows, strict=True
    ):
        correction_value = None
        if (
            moi_correction is not None
            and identifier == moi_correction.person_key
            and visit_date == moi_correction.visit_date
        ):
            correction_value = _age_removed_moi(
                row,
                bindings,
                person_key=identifier,
                visit_date=visit_date,
                correction=moi_correction,
            )
        scores = score_source_row(
            row,
            bindings,
            cutpoints,
            _moi_age_removed_override=correction_value,
        )
        observed = relevant = 0
        for component_name, score in scores.items():
            if score is ComponentStatus.NOT_APPLICABLE:
                not_applicable[component_name] += 1
                continue
            relevant += 1
            if score is None:
                missing[component_name] += 1
            else:
                observed += 1
        if relevant == 0:
            raise ValueError("A first-visit row has no relevant DEAC components")
        eligible = observed * 5 >= relevant * 4
        if eligible:
            eligible_people += 1
        else:
            insufficient_people += 1
        index_value = assemble_deac_index(scores)
        if index_value is not None:
            indices.append(float(index_value))
        outputs.append(
            DEACParticipantResult(
                identifier=identifier,
                component_scores=scores,
                deac_index=None if index_value is None else float(index_value),
                observed_components=observed,
                relevant_components=relevant,
                coverage=observed / relevant,
                eligible=eligible,
            )
        )

    ordered_indices = sorted(indices)

    def median(values: list[float]) -> float | None:
        if not values:
            return None
        middle = len(values) // 2
        if len(values) % 2:
            return values[middle]
        return (values[middle - 1] + values[middle]) / 2

    summary = DEACRunSummary(
        cohort_people=len(cohort.rows),
        moi_reference_people=len(moi_values),
        moi_cutpoints=cutpoints,
        coverage_eligible_people=eligible_people,
        insufficient_coverage_people=insufficient_people,
        index_calculable_people=len(indices),
        missing_by_component=dict(missing),
        not_applicable_by_component=dict(not_applicable),
        index_mean=None if not indices else sum(indices) / len(indices),
        index_median=median(ordered_indices),
        index_min=None if not indices else ordered_indices[0],
        index_max=None if not indices else ordered_indices[-1],
    )
    return tuple(outputs), summary


def write_participant_results_csv(
    results: Iterable[DEACParticipantResult],
    output_path: str | Path,
    *,
    protected_root: str | Path,
) -> None:
    """Create a new mode-0600 participant output below a mode-0700 protected dir."""
    root = Path(protected_root).resolve(strict=True)
    target = Path(output_path)
    parent = target.parent.resolve(strict=True)
    if parent != root and root not in parent.parents:
        raise ValueError("Participant output must be below the approved protected root")
    if stat.S_IMODE(parent.stat().st_mode) & 0o077:
        raise ValueError("Protected output directory permissions must exclude group/other")
    if target.exists() or target.is_symlink():
        raise FileExistsError("Refusing to overwrite an existing participant output")

    columns = [
        "participant_key",
        *COMPONENT_NAMES,
        "deac_index",
        "observed_components",
        "relevant_components",
        "coverage",
        "eligible",
    ]
    flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL | getattr(os, "O_NOFOLLOW", 0)
    file_descriptor = os.open(target, flags, 0o600)
    os.fchmod(file_descriptor, 0o600)
    with os.fdopen(file_descriptor, "w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=columns, extrasaction="raise")
        writer.writeheader()
        for result in results:
            row: dict[str, object] = {
                "participant_key": result.identifier,
                "deac_index": result.deac_index,
                "observed_components": result.observed_components,
                "relevant_components": result.relevant_components,
                "coverage": result.coverage,
                "eligible": result.eligible,
            }
            for name in COMPONENT_NAMES:
                value = result.component_scores[name]
                if value is ComponentStatus.NOT_APPLICABLE:
                    row[name] = "NOT_APPLICABLE"
                else:
                    row[name] = value
            writer.writerow(row)


def source_bindings_from_config(
    config: Mapping[str, object],
    *,
    actual_sha256: str,
    physical_headers: Iterable[str],
    label_row: Iterable[str],
) -> SourceBindings:
    """Build bindings only after an external reader validates metadata rows.

    The configuration stores one-based Excel positions and exact protected
    header/label expectations. The source reader supplies only Taul1 metadata
    here; it must not supply participant rows until this function succeeds.
    """
    if not isinstance(config, Mapping) or config.get("schema_version") != 1:
        raise ValueError("Unsupported protected SourceBindings config")
    expected_sha256 = config.get("source_sha256")
    columns = config.get("columns")
    positions = config.get("positions_1based")
    expected_labels = config.get("expected_labels", {})
    if not isinstance(columns, Mapping) or not isinstance(positions, Mapping):
        raise ValueError("Protected source fields and positions must be mappings")
    if not isinstance(expected_labels, Mapping):
        raise ValueError("Expected source labels must be a mapping")
    if set(columns) != set(positions) or set(expected_labels) - set(columns):
        raise ValueError("Protected source metadata keys do not align")

    positions_zero_based: dict[str, int] = {}
    for field_name, position in positions.items():
        if (
            isinstance(position, bool)
            or not isinstance(position, int)
            or position < 1
        ):
            raise ValueError("Source positions must be positive one-based integers")
        positions_zero_based[field_name] = position - 1

    if any(not isinstance(label, str) or not label for label in expected_labels.values()):
        raise ValueError("Expected source labels must be nonempty strings")
    validate_source_schema_bindings(
        actual_sha256,
        expected_sha256,  # type: ignore[arg-type]
        tuple(physical_headers),
        tuple(label_row),
        positions_zero_based,
        semantic_prefixes=expected_labels,  # type: ignore[arg-type]
    )

    def code_lists(key: str) -> dict[str, tuple[object, ...]]:
        raw = config.get(key, {})
        if raw == []:
            return {}
        if not isinstance(raw, Mapping):
            raise ValueError(f"{key} must be a mapping")
        result: dict[str, tuple[object, ...]] = {}
        for field_name, codes in raw.items():
            if isinstance(codes, (str, bytes)) or not isinstance(codes, Iterable):
                raise ValueError(f"{key} values must be code sequences")
            result[field_name] = tuple(codes)
        return result

    raw_performance = config.get("performance_codes", {})
    if raw_performance == []:
        raw_performance = {}
    if not isinstance(raw_performance, Mapping):
        raise ValueError("performance_codes must be a mapping")
    performance: dict[str, dict[object, PerformanceDisposition]] = {}
    for field_name, codebook in raw_performance.items():
        if not isinstance(codebook, Mapping):
            raise ValueError("Each performance codebook must be a mapping")
        try:
            performance[field_name] = {
                code: PerformanceDisposition(disposition)
                for code, disposition in codebook.items()
            }
        except ValueError as exc:
            raise ValueError("Unknown performance disposition in config") from exc

    def string_mapping(key: str) -> dict[str, str]:
        raw = config.get(key, {})
        if raw == []:
            return {}
        if not isinstance(raw, Mapping) or any(
            not isinstance(value, str) for value in raw.values()
        ):
            raise ValueError(f"{key} must map names to strings")
        return dict(raw)

    verified = code_lists("verified_functional_inability_codes")
    bindings = SourceBindings(
        columns=dict(columns),  # type: ignore[arg-type]
        ordinary_missing_codes=code_lists("ordinary_missing_codes"),
        invalid_codes_as_missing=code_lists("invalid_codes_as_missing"),
        performance_codes=performance,
        reason_columns=string_mapping("reason_columns"),
        verified_functional_inability_codes=verified,
    )
    _validate_bindings(bindings)
    return bindings


@dataclass(frozen=True)
class DEACCohortSummary:
    """Privacy-minimized cohort counts and fitted MOI cutpoints only."""

    baseline_rows: int
    moi_reference_rows: int
    moi_cutpoints: tuple[float, float, float, float]
    coverage_eligible_rows: int
    insufficient_coverage_rows: int
    index_calculable_rows: int
    missing_by_component: Mapping[str, int]
    not_applicable_by_component: Mapping[str, int]


def _age_removed_moi(
    row: Row,
    bindings: SourceBindings,
    *,
    person_key: str | None = None,
    visit_date: date | None = None,
    correction: MOIAgeRemovalCorrection | None = None,
) -> float | None:
    total = _read_value(row, bindings, "moi_total")
    age = _read_value(row, bindings, "baseline_age_years")
    if total is None or age is None:
        return None
    if isinstance(age, bool) or not isinstance(age, (int, float)):
        raise ValueError("Baseline age must be numeric completed years")
    try:
        numeric_age = float(age)
    except OverflowError as exc:
        raise ValueError("Baseline age must be numeric completed years") from exc
    if not isfinite(numeric_age) or not numeric_age.is_integer():
        raise ValueError("Baseline age must be numeric completed years")
    age_years = int(numeric_age)
    if (
        correction is None
        or person_key != correction.person_key
        or visit_date != correction.visit_date
    ):
        return remove_moi_age_points(total, age_years)  # type: ignore[arg-type]
    if total != correction.source_total or age_years != correction.baseline_age_years:
        raise ValueError("Protected MOI correction no longer matches its source record")
    try:
        remove_moi_age_points(total, age_years)  # type: ignore[arg-type]
    except ValueError as exc:
        if str(exc) != "MOI age points exceed the age-inclusive MOI index":
            raise
    else:
        raise ValueError("Protected MOI correction no longer addresses a negative value")
    return correction.corrected_without_age


def run_baseline_cohort(
    cohort: FirstVisitCohort,
    bindings: SourceBindings,
    *,
    moi_correction: MOIAgeRemovalCorrection | None = None,
) -> DEACCohortSummary:
    """Return aggregate counts via the correction-aware cohort scorer.

    Accepting the verified cohort object (rather than an arbitrary row
    factory) binds the case-specific MOI correction to the same snapshot,
    person key, and first-visit date as the detailed scoring route.
    """
    if not isinstance(cohort, FirstVisitCohort):
        raise ValueError("Expected a verified FirstVisitCohort")
    _, summary = score_first_visit_cohort(
        cohort, bindings, moi_correction=moi_correction
    )
    return DEACCohortSummary(
        baseline_rows=summary.cohort_people,
        moi_reference_rows=summary.moi_reference_people,
        moi_cutpoints=summary.moi_cutpoints,
        coverage_eligible_rows=summary.coverage_eligible_people,
        insufficient_coverage_rows=summary.insufficient_coverage_people,
        index_calculable_rows=summary.index_calculable_people,
        missing_by_component=summary.missing_by_component,
        not_applicable_by_component=summary.not_applicable_by_component,
    )
