#!/usr/bin/env python3
from __future__ import annotations

import argparse
from pathlib import Path
from typing import Iterable, Tuple

import pandas as pd

from scripts.path_resolver import get_data_root, safe_join_path


REQ_AIM2 = {"id", "FOF_status", "age", "sex", "followup_days"}
REQ_LINK = {"id", "register_id"}
REQ_VISITS = {"Henkilotunnus", "Pdgo"}
REQ_TREAT = {"Henkilotunnus", "OsastojaksoAlkuPvm", "OsastojaksoLoppuPvm"}


def _must_have(df: pd.DataFrame, cols: Iterable[str], ctx: str) -> None:
    missing = sorted(set(cols) - set(df.columns))
    if missing:
        raise SystemExit(f"{ctx}: missing required columns: {', '.join(missing)}")


def _read_csv_auto(path: Path) -> pd.DataFrame:
    df = pd.read_csv(path)
    if len(df.columns) == 1 and "|" in str(df.columns[0]):
        df = pd.read_csv(path, sep="|")
    return df


def _icd_injury_mask(series: pd.Series) -> pd.Series:
    x = (
        series.astype(str)
        .str.upper()
        .str.replace(r"[^A-Z0-9]", "", regex=True)
        .str.strip()
    )
    letter = x.str[0]
    num2 = pd.to_numeric(x.str[1:3], errors="coerce")
    return ((letter == "S") & num2.between(0, 99)) | ((letter == "T") & num2.between(0, 14))


def _resolve_rel(data_root: Path, rel: str) -> Path:
    return safe_join_path(data_root, rel)


def _read_excel(path: Path, sheet_name: str) -> pd.DataFrame:
    if sheet_name:
        return pd.read_excel(path, sheet_name=sheet_name)
    return pd.read_excel(path)


def _build_case_map(
    cohort_roster: pd.DataFrame,
    cohort_id_col: str,
    case_flag_col: str,
    case_flag_case_value: str,
) -> pd.DataFrame:
    _must_have(cohort_roster, {cohort_id_col, case_flag_col}, "cohort roster")
    c = cohort_roster[[cohort_id_col, case_flag_col]].copy()
    c = c.rename(columns={cohort_id_col: "register_id", case_flag_col: "case_flag"})
    c["register_id"] = c["register_id"].astype(str).str.strip()
    c["case_status"] = c["case_flag"].astype(str).str.strip().apply(
        lambda v: "case" if v == case_flag_case_value else "control"
    )
    c = c[["register_id", "case_status"]].drop_duplicates()
    dup = c.duplicated(subset=["register_id"], keep=False)
    if dup.any():
        raise SystemExit("Case/control mapping is ambiguous for some roster IDs.")
    return c


def _validate_controls_requirements(
    case_map: pd.DataFrame,
    controls_link_table_rel: str,
    controls_panel_file_rel: str,
) -> None:
    has_controls = (case_map["case_status"] == "control").any()
    if not has_controls:
        raise SystemExit("Cohort roster gate failed: no controls found in roster.")
    if not controls_link_table_rel:
        raise SystemExit(
            "Controls linkage gate failed: roster contains controls but table3.controls_link_table is empty."
        )
    if not controls_panel_file_rel:
        raise SystemExit(
            "Controls panel gate failed: table3.controls_panel_file is empty (required for age/sex/py)."
        )


def _build_case_and_control_cohorts(
    data_root: Path,
    aim2: pd.DataFrame,
    link: pd.DataFrame,
    case_map: pd.DataFrame,
    controls_link_table_rel: str,
    controls_panel_file_rel: str,
) -> Tuple[pd.DataFrame, pd.DataFrame]:
    case_link = aim2.merge(link, on="id", how="inner")
    if len(case_link) != len(aim2):
        raise SystemExit("Case link coverage failure: not all aim2 IDs map to register_id.")
    case_link["register_id"] = case_link["register_id"].astype(str).str.strip()
    case_cohort = case_link.merge(case_map, on="register_id", how="inner")
    case_cohort = case_cohort[case_cohort["case_status"] == "case"].copy()
    if case_cohort.empty:
        raise SystemExit("Case cohort gate failed: no case rows after linkage.")

    controls_link_path = _resolve_rel(data_root, controls_link_table_rel)
    if not controls_link_path.exists():
        raise SystemExit(
            "Controls linkage gate failed: controls_link_table file not found under DATA_ROOT."
        )
    controls_link = pd.read_csv(controls_link_path)
    _must_have(controls_link, REQ_LINK, "controls_link_table")
    controls_link["register_id"] = controls_link["register_id"].astype(str).str.strip()

    controls_panel_path = _resolve_rel(data_root, controls_panel_file_rel)
    if not controls_panel_path.exists():
        raise SystemExit(
            "Controls panel gate failed: controls_panel_file not found under DATA_ROOT."
        )
    controls_panel = _read_csv_auto(controls_panel_path)
    _must_have(controls_panel, {"id", "FOF_status", "age", "sex", "py"}, "controls_panel_file")

    controls_ids = case_map.loc[case_map["case_status"] == "control", ["register_id"]].copy()
    controls_cohort = controls_ids.merge(controls_link, on="register_id", how="inner")
    controls_cohort = controls_cohort.merge(controls_panel, on="id", how="inner")
    if controls_cohort.empty:
        raise SystemExit(
            "Controls linkage gate failed: no controls could be mapped to controls_link_table + controls_panel_file."
        )
    controls_cohort["case_status"] = "control"

    overlap_ids = set(case_cohort["id"].astype(str)) & set(controls_cohort["id"].astype(str))
    if overlap_ids:
        raise SystemExit("ID disjointness gate failed: same id found in both case and control cohorts.")

    return case_cohort, controls_cohort


def main() -> None:
    ap = argparse.ArgumentParser(
        description="Build analysis-ready Table 3 inputs under DATA_ROOT/derived (fail-closed)."
    )
    ap.add_argument("--visits-out", required=True, help="Absolute output path for visits input CSV.")
    ap.add_argument("--treat-out", required=True, help="Absolute output path for treatment input CSV.")
    ap.add_argument("--cohort-file", required=True, help="Roster file relative to DATA_ROOT.")
    ap.add_argument("--cohort-sheet", default="", help="Roster sheet name (optional).")
    ap.add_argument("--cohort-id-col", required=True, help="Roster register-ID column name.")
    ap.add_argument("--case-flag-col", required=True, help="Roster case/control flag column name.")
    ap.add_argument(
        "--case-flag-case-value",
        default="0",
        help="Value in case-flag column that indicates case rows.",
    )
    ap.add_argument(
        "--controls-link-table",
        default="",
        help="Controls link table relative to DATA_ROOT (must contain id,register_id).",
    )
    ap.add_argument(
        "--controls-panel-file",
        default="",
        help="Controls panel relative to DATA_ROOT (must contain id,FOF_status,age,sex,py).",
    )
    args = ap.parse_args()

    data_root = get_data_root(require=True)
    assert data_root is not None
    data_root = data_root.expanduser().resolve()

    visits_out = Path(args.visits_out).expanduser().resolve()
    treat_out = Path(args.treat_out).expanduser().resolve()
    if not visits_out.is_absolute() or not treat_out.is_absolute():
        raise SystemExit("Output paths must be absolute.")
    try:
        visits_out.relative_to(data_root)
        treat_out.relative_to(data_root)
    except ValueError:
        raise SystemExit("Output paths must be under DATA_ROOT.")

    aim2_path = _resolve_rel(data_root, "derived/aim2_analysis.csv")
    link_path = _resolve_rel(data_root, "derived/link_table.csv")
    visits_path = _resolve_rel(data_root, "paper_02/Tutkimusaineisto_pkl_kaynnit_2010_2019.csv")
    treat_path = _resolve_rel(data_root, "paper_02/Tutkimusaineisto_osastojaksot_2010_2019.xlsx")
    cohort_path = _resolve_rel(data_root, args.cohort_file)

    aim2 = pd.read_csv(aim2_path)
    link = pd.read_csv(link_path)
    visits = _read_csv_auto(visits_path)
    treat = pd.read_excel(treat_path)
    cohort_roster = _read_excel(cohort_path, args.cohort_sheet)

    _must_have(aim2, REQ_AIM2, "aim2_analysis")
    _must_have(link, REQ_LINK, "link_table")
    _must_have(visits, REQ_VISITS, "visits")
    _must_have(treat, REQ_TREAT, "treatment")

    if aim2["id"].duplicated().any():
        raise SystemExit("aim2_analysis id must be unique.")
    if link["id"].duplicated().any() or link["register_id"].duplicated().any():
        raise SystemExit("link_table must be 1:1 (id and register_id unique).")

    case_map = _build_case_map(
        cohort_roster=cohort_roster,
        cohort_id_col=args.cohort_id_col,
        case_flag_col=args.case_flag_col,
        case_flag_case_value=str(args.case_flag_case_value).strip(),
    )
    _validate_controls_requirements(
        case_map=case_map,
        controls_link_table_rel=args.controls_link_table.strip(),
        controls_panel_file_rel=args.controls_panel_file.strip(),
    )

    case_cohort, controls_cohort = _build_case_and_control_cohorts(
        data_root=data_root,
        aim2=aim2,
        link=link,
        case_map=case_map,
        controls_link_table_rel=args.controls_link_table.strip(),
        controls_panel_file_rel=args.controls_panel_file.strip(),
    )

    case_cohort["py"] = pd.to_numeric(case_cohort["followup_days"], errors="coerce") / 365.25
    if case_cohort["py"].isna().any() or (case_cohort["py"] <= 0).any():
        raise SystemExit("Case cohort py gate failed: invalid followup_days -> py conversion.")

    case_cohort = case_cohort.rename(columns={"FOF_status": "fof_status"})[
        ["id", "register_id", "fof_status", "case_status", "age", "sex", "py"]
    ]
    controls_cohort = controls_cohort.rename(columns={"FOF_status": "fof_status"})[
        ["id", "register_id", "fof_status", "case_status", "age", "sex", "py"]
    ]

    cohort = pd.concat([case_cohort, controls_cohort], ignore_index=True)
    statuses = set(cohort["case_status"].dropna().astype(str).unique().tolist())
    if statuses != {"case", "control"}:
        raise SystemExit("Cohort gate failed: expected both case and control after linkage.")

    visits2 = visits.rename(columns={"Henkilotunnus": "register_id", "Pdgo": "icd10_code"}).copy()
    visits2["register_id"] = visits2["register_id"].astype(str).str.strip()
    visits2 = visits2[visits2["icd10_code"].notna()].copy()
    visits2 = visits2[_icd_injury_mask(visits2["icd10_code"])].copy()

    visits_join = visits2.merge(cohort, on="register_id", how="inner")
    visits_join["event_count"] = 1
    visits_out_df = visits_join[
        ["fof_status", "case_status", "sex", "age", "py", "icd10_code", "event_count"]
    ].copy()
    if visits_out_df.empty:
        raise SystemExit("Built visits input is empty (no linked injury-coded visits).")

    treat2 = treat.rename(columns={"Henkilotunnus": "register_id"}).copy()
    treat2["register_id"] = treat2["register_id"].astype(str).str.strip()
    treat2 = treat2[treat2["register_id"].notna()].copy()
    treat2 = treat2.drop_duplicates(
        subset=["register_id", "OsastojaksoAlkuPvm", "OsastojaksoLoppuPvm"]
    )
    treat_counts = (
        treat2.groupby("register_id", dropna=False)
        .size()
        .reset_index(name="event_count")
    )

    treat_out_df = cohort.merge(treat_counts, on="register_id", how="left")
    treat_out_df["event_count"] = treat_out_df["event_count"].fillna(0).astype(int)
    treat_out_df = treat_out_df[
        ["fof_status", "case_status", "sex", "age", "py", "event_count"]
    ].copy()

    visits_out.parent.mkdir(parents=True, exist_ok=True)
    treat_out.parent.mkdir(parents=True, exist_ok=True)
    visits_out_df.to_csv(visits_out, index=False)
    treat_out_df.to_csv(treat_out, index=False)

    print(f"Built table3 inputs: visits_rows={len(visits_out_df)} treat_rows={len(treat_out_df)}")


if __name__ == "__main__":
    main()
