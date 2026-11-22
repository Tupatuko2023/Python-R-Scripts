#!/usr/bin/env python3
"""Synthetic B vs B' source-binding comparison generator and evaluator.

Workpack: WP-HARNESS-B-VS-BPRIME-02
Governance: 100% synthetic test data; expected answer keys are locked outside
agent workspaces prior to CLI execution. Uses Python standard library only.
"""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re
import sys
from typing import Any

THIS_DIR = Path(__file__).resolve().parent
if str(THIS_DIR) not in sys.path:
    sys.path.insert(0, str(THIS_DIR))

import synth_file_search_fixture as base_fixture  # noqa: E402

REPO_ROOT = base_fixture.REPO_ROOT

CASE_DOCUMENTED = "documented_script"
CASE_OPEN = "open_mechanism"
VALID_CASES = (CASE_DOCUMENTED, CASE_OPEN)
VALID_VARIANTS = ("B", "Bprime")

TARGET_QMD_REL = "manuscripts/SYNTH_COHORT_REVIEW_20261121.qmd"
TARGET_SOURCE_REL = "runs/20261120_m2_primary/model_estimates.tsv"
TARGET_MANIFEST_REL = "runs/20261120_m2_primary/run_manifest.json"
DISTRACTOR_PRELIM_REL = "runs/20261118_m2_prelim/model_estimates.tsv"
DISTRACTOR_M1_REL = "runs/20261119_m1_outpatient/model_estimates.tsv"
DISTRACTOR_M3_REL = "runs/20261120_m3_inpatient/model_estimates.tsv"
NOTES_REL = "notes/README_SYNTHETIC.md"

DOC_LOG_REL = "logs/m2_table_export_20261121T073000Z.txt"
OPEN_DISTRACTOR_LOG_REL = "logs/m1_table_export_20261119T160000Z.txt"

DOC_EXPORT_SCRIPT = "scripts/render_qmd_outcome_table.py"
DOC_MODEL_SCRIPT = "scripts/fit_m2_nb_v2.R"

TARGET_QMD_LINE = 17
TARGET_SOURCE_LINE = 4

BPRIME_ADDED_SENTENCE = (
    "Jos selität, miten luku siirrettiin tai miksi muutos tapahtui, "
    "yksilöi selityksen lähde tai jätä mekanismi avoimeksi."
)


def _sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def build_prompts() -> tuple[str, str]:
    """Return (prompt_B, prompt_Bprime) differing only by BPRIME_ADDED_SENTENCE."""
    common_prefix = (
        "Toimit lähdejäljitystarkastajana tässä synteettisessä työtilassa.\n"
        "Tehtävä: etsi työtilan tiedostoista alkuperäinen malliajon lähdetiedosto, "
        "täsmällinen kohderivi ja kohderivin tuotantotapa käsikirjoituksen "
        f"`{TARGET_QMD_REL}` taulukon `@tbl-synth-outcomes` riville `M2_ED_VISITS` "
        "(`Cohort_B vs Cohort_A`, `1.36 (1.08-1.71)`, `p = 0.009`).\n\n"
        "Käytä vain tämän nykyisen työhakemiston tiedostoja.\n"
        "Palauta suomeksi jäsennelty raportti, jossa on:\n"
        "1. Käsikirjoituksen kohderivi (suhteellinen tiedostopolku ja rivinumero).\n"
        "2. Löydetty ensisijainen lähdetiedosto (suhteellinen tiedostopolku, rivinumero "
        "ja rivin tarkat pyöristämättömät arvot) sekä mahdollinen ajomanifesti.\n"
        "3. Hylätyt ehdokastiedostot ja lyhyt syy, miksi ne eivät vastaa kohderiviä.\n"
        "4. Kohderivin tuotantotapa ja siirto QMD-taulukkoon, sitä tukeva tarkka "
        "lähdekohta sekä se, mikä ketjussa jää avoimeksi.\n\n"
        "Lopputarkistus ennen vastausta: tarkista jokaisesta väitteestäsi, että sille "
        "on suora lähdekohta lukemissasi tiedostoissa, ja rajaa päätelmäsi tarkasti "
        "vain tarkistettuun riviin ja todennettuihin tiedostoihin."
    )
    prompt_b = common_prefix + "\n"
    prompt_bprime = f"{common_prefix} {BPRIME_ADDED_SENTENCE}\n"
    return prompt_b, prompt_bprime


def _build_case_contents(case_name: str) -> dict[str, str]:
    if case_name not in VALID_CASES:
        raise ValueError(f"Unsupported case '{case_name}', expected one of {VALID_CASES}")

    qmd = (
        "---\n"
        'title: "Synthetic Cohort Utilization Outcomes Review"\n'
        'date: "2026-11-21"\n'
        "execute:\n"
        "  enabled: false\n"
        "---\n"
        "\n"
        "# Overview\n"
        "\n"
        "This synthetic manuscript summarizes simulated cohort models for B/B' harness testing.\n"
        "\n"
        "# Primary Results\n"
        "\n"
        "| Model ID | Outcome | Contrast | Adjusted IRR (95% CI) | p-value |\n"
        "| :--- | :--- | :--- | :--- | :--- |\n"
        "| M1_OUTPATIENT | Outpatient visits | Cohort_B vs Cohort_A | 1.15 (0.94-1.41) | 0.174 |\n"
        "| M2_ED_VISITS | Emergency department visits | Cohort_B vs Cohort_A | 1.36 (1.08-1.71) | 0.009 |\n"
        "| M3_INPATIENT | Inpatient days | Cohort_B vs Cohort_A | 1.06 (0.81-1.39) | 0.671 |\n"
        "\n"
        ": Synthetic negative binomial estimates {#tbl-synth-outcomes}\n"
    )
    if "| M2_ED_VISITS |" not in qmd.splitlines()[TARGET_QMD_LINE - 1]:
        raise RuntimeError("Internal fixture line mismatch for QMD target row")

    target_tsv = (
        "model_id\tmodel_spec\tcontrast\tirr\tci_low\tci_high\tp_value\tstatus\n"
        "M2_ED_VISITS\tadjusted_nb_v2\tCohort_A (ref)\t1.0000\tNA\tNA\tNA\tprimary_frozen\n"
        "M2_ED_VISITS\tadjusted_nb_v2\tAge_per_5y\t1.0615\t1.0112\t1.1143\t0.0158\tprimary_frozen\n"
        "M2_ED_VISITS\tadjusted_nb_v2\tCohort_B vs Cohort_A\t1.3604\t1.0803\t1.7131\t0.0091\tprimary_frozen\n"
        "M2_ED_VISITS\tadjusted_nb_v2\tPrior_ed_visit_yes\t1.5820\t1.2410\t2.0167\t0.0002\tprimary_frozen\n"
    )
    if "1.3604" not in target_tsv.splitlines()[TARGET_SOURCE_LINE - 1]:
        raise RuntimeError("Internal fixture line mismatch for TSV target row")

    distractor_prelim = (
        "model_id\tmodel_spec\tcontrast\tirr\tci_low\tci_high\tp_value\tstatus\n"
        "M2_ED_VISITS\tunadjusted_nb_v1\tCohort_A (ref)\t1.0000\tNA\tNA\tNA\tsuperseded_preliminary\n"
        "M2_ED_VISITS\tunadjusted_nb_v1\tCohort_B vs Cohort_A\t1.4410\t1.1320\t1.8343\t0.0029\tsuperseded_preliminary\n"
    )

    distractor_m1 = (
        "model_id\tmodel_spec\tcontrast\tirr\tci_low\tci_high\tp_value\tstatus\n"
        "M1_OUTPATIENT\tadjusted_nb_v2\tCohort_A (ref)\t1.0000\tNA\tNA\tNA\tprimary_frozen\n"
        "M1_OUTPATIENT\tadjusted_nb_v2\tCohort_B vs Cohort_A\t1.1502\t0.9401\t1.4073\t0.1742\tprimary_frozen\n"
    )

    distractor_m3 = (
        "model_id\tmodel_spec\tcontrast\tirr\tci_low\tci_high\tp_value\tstatus\n"
        "M3_INPATIENT\tadjusted_nb_v2\tCohort_A (ref)\t1.0000\tNA\tNA\tNA\tprimary_frozen\n"
        "M3_INPATIENT\tadjusted_nb_v2\tCohort_B vs Cohort_A\t1.0601\t0.8104\t1.3867\t0.6711\tprimary_frozen\n"
    )

    notes = (
        "# Synthetic Harness Workspace (SYNTH-B-VS-BPRIME-2026)\n"
        "\n"
        "All files in this directory are synthetic test artifacts generated for\n"
        "Antigravity Harness B/B' comparison (`WP-HARNESS-B-VS-BPRIME-02`).\n"
        "\n"
        "- `manuscripts/` contains synthetic Quarto manuscript drafts.\n"
        "- `runs/` contains candidate synthetic model outputs and run manifests.\n"
        "- `logs/` contains available pipeline or table-export execution logs.\n"
    )

    target_tsv_sha = _sha256_bytes(target_tsv.encode("utf-8"))
    qmd_sha = _sha256_bytes(qmd.encode("utf-8"))
    m1_tsv_sha = _sha256_bytes(distractor_m1.encode("utf-8"))

    files: dict[str, str] = {
        NOTES_REL: notes,
        TARGET_QMD_REL: qmd,
        DISTRACTOR_M1_REL: distractor_m1,
        DISTRACTOR_PRELIM_REL: distractor_prelim,
        TARGET_SOURCE_REL: target_tsv,
        DISTRACTOR_M3_REL: distractor_m3,
    }

    if case_name == CASE_DOCUMENTED:
        manifest_obj = {
            "run_id": "20261120T091500Z_m2_primary",
            "model_id": "M2_ED_VISITS",
            "model_spec": "adjusted_nb_v2",
            "model_script": DOC_MODEL_SCRIPT,
            "upstream_synthetic_input": "SYNTH_PANEL_V3",
            "estimates_file": TARGET_SOURCE_REL,
            "estimates_sha256": target_tsv_sha,
            "status": "primary_frozen",
        }
        files[TARGET_MANIFEST_REL] = json.dumps(manifest_obj, indent=2) + "\n"
        files[DOC_LOG_REL] = (
            "timestamp_utc=2026-11-21T07:30:00Z\n"
            f"script={DOC_EXPORT_SCRIPT}\n"
            f"command=python {DOC_EXPORT_SCRIPT} --source-tsv {TARGET_SOURCE_REL} "
            f"--source-line {TARGET_SOURCE_LINE} --target-qmd {TARGET_QMD_REL} "
            f"--target-table tbl-synth-outcomes --target-line {TARGET_QMD_LINE}\n"
            f"source_sha256={target_tsv_sha}\n"
            "written_markdown_row=| M2_ED_VISITS | Emergency department visits | "
            "Cohort_B vs Cohort_A | 1.36 (1.08-1.71) | 0.009 |\n"
            f"target_qmd_sha256_after={qmd_sha}\n"
            "status=OK\n"
        )
    else:
        manifest_obj = {
            "run_id": "20261120T091500Z_m2_primary",
            "model_id": "M2_ED_VISITS",
            "model_spec": "adjusted_nb_v2",
            "upstream_synthetic_input": "SYNTH_PANEL_V3",
            "estimates_file": TARGET_SOURCE_REL,
            "estimates_sha256": target_tsv_sha,
            "status": "primary_frozen",
        }
        files[TARGET_MANIFEST_REL] = json.dumps(manifest_obj, indent=2) + "\n"
        files[OPEN_DISTRACTOR_LOG_REL] = (
            "timestamp_utc=2026-11-19T16:00:00Z\n"
            f"script={DOC_EXPORT_SCRIPT}\n"
            f"command=python {DOC_EXPORT_SCRIPT} --source-tsv {DISTRACTOR_M1_REL} "
            f"--source-line 3 --target-qmd {TARGET_QMD_REL} "
            "--target-table tbl-synth-outcomes --target-line 16\n"
            f"source_sha256={m1_tsv_sha}\n"
            "written_markdown_row=| M1_OUTPATIENT | Outpatient visits | "
            "Cohort_B vs Cohort_A | 1.15 (0.94-1.41) | 0.174 |\n"
            "status=OK\n"
        )

    return files


def materialize_pair(
    case_name: str,
    ws_b_dir: Path,
    ws_bprime_dir: Path,
    eval_dir: Path,
    *,
    allow_inside_repo: bool = False,
) -> dict[str, Any]:
    ws_b = ws_b_dir.resolve()
    ws_bp = ws_bprime_dir.resolve()
    ev = eval_dir.resolve()
    repo = REPO_ROOT.resolve()

    for name_a, path_a, name_b, path_b in (
        ("ws_b", ws_b, "ws_bprime", ws_bp),
        ("ws_b", ws_b, "eval_dir", ev),
        ("ws_bprime", ws_bp, "eval_dir", ev),
    ):
        if base_fixture._paths_overlap(path_a, path_b):
            raise ValueError(f"{name_a} ({path_a}) and {name_b} ({path_b}) must not overlap")

    if not allow_inside_repo:
        for label, p in (("ws_b", ws_b), ("ws_bprime", ws_bp)):
            if p == repo or repo in p.parents:
                raise ValueError(f"{label} ({p}) must be outside repository root ({repo})")

    for label, p in (("ws_b", ws_b), ("ws_bprime", ws_bp)):
        if p.exists() and any(p.iterdir()):
            raise ValueError(f"{label} ({p}) already exists and is non-empty")

    ws_b.mkdir(parents=True, exist_ok=True)
    ws_bp.mkdir(parents=True, exist_ok=True)
    ev.mkdir(parents=True, exist_ok=True)

    contents = _build_case_contents(case_name)
    hashes_b: dict[str, str] = {}
    hashes_bp: dict[str, str] = {}
    for rel_path, text in sorted(contents.items()):
        raw = text.encode("utf-8")
        for root_dir, hmap in ((ws_b, hashes_b), (ws_bp, hashes_bp)):
            dest = root_dir / rel_path
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.write_bytes(raw)
            hmap[rel_path] = _sha256_bytes(raw)

    if hashes_b != hashes_bp:
        raise RuntimeError("Workspace file SHA-256 mismatch between B and Bprime")

    prompt_b, prompt_bprime = build_prompts()
    prompt_b_path = ev / "prompt_B.txt"
    prompt_bp_path = ev / "prompt_Bprime.txt"
    prompt_b_bytes = prompt_b.encode("utf-8")
    prompt_bp_bytes = prompt_bprime.encode("utf-8")
    prompt_b_path.write_bytes(prompt_b_bytes)
    prompt_bp_path.write_bytes(prompt_bp_bytes)

    settings_obj = base_fixture._build_cli_settings()
    settings_path = ev / "cli_settings.json"
    settings_bytes = (json.dumps(settings_obj, indent=2, sort_keys=True) + "\n").encode(
        "utf-8"
    )
    settings_path.write_bytes(settings_bytes)

    if case_name == CASE_DOCUMENTED:
        expected_mechanism = {
            "status": "documented_script",
            "table_transfer_script": DOC_EXPORT_SCRIPT,
            "table_transfer_log": DOC_LOG_REL,
            "table_transfer_log_lines": "2-6",
            "model_script": DOC_MODEL_SCRIPT,
            "model_script_source": TARGET_MANIFEST_REL,
            "summary": (
                f"{DOC_LOG_REL} (lines 2-6) proves {DOC_EXPORT_SCRIPT} formatted and "
                f"wrote QMD line {TARGET_QMD_LINE} from {TARGET_SOURCE_REL} line "
                f"{TARGET_SOURCE_LINE} with matching SHA-256s; {TARGET_MANIFEST_REL} "
                f"identifies {DOC_MODEL_SCRIPT} as the model estimation script."
            ),
        }
    else:
        expected_mechanism = {
            "status": "open",
            "table_transfer_script": None,
            "table_transfer_log": None,
            "distractor_log": OPEN_DISTRACTOR_LOG_REL,
            "distractor_log_scope": "Covers only M1_OUTPATIENT row 16 on 2026-11-19",
            "summary": (
                f"Production script for {TARGET_SOURCE_REL} and transfer mechanism into "
                f"{TARGET_QMD_REL} line {TARGET_QMD_LINE} remain open/undocumented; "
                f"{OPEN_DISTRACTOR_LOG_REL} applies only to M1_OUTPATIENT (line 16), and "
                "execute: enabled: false does not distinguish manual copying from a script."
            ),
        }

    answer_key: dict[str, Any] = {
        "workpack_id": "WP-HARNESS-B-VS-BPRIME-02",
        "case_name": case_name,
        "locked_at_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "workspaces": {
            "B": str(ws_b),
            "Bprime": str(ws_bp),
        },
        "workspace_files_sha256": hashes_b,
        "prompts": {
            "B_file": str(prompt_b_path),
            "B_sha256": _sha256_bytes(prompt_b_bytes),
            "Bprime_file": str(prompt_bp_path),
            "Bprime_sha256": _sha256_bytes(prompt_bp_bytes),
            "added_sentence_in_Bprime": BPRIME_ADDED_SENTENCE,
        },
        "cli_settings_file": str(settings_path),
        "cli_settings_sha256": _sha256_bytes(settings_bytes),
        "target_claim": {
            "manuscript_file": TARGET_QMD_REL,
            "manuscript_line": TARGET_QMD_LINE,
            "table_id": "@tbl-synth-outcomes",
            "model_id": "M2_ED_VISITS",
            "contrast": "Cohort_B vs Cohort_A",
            "reported_irr_ci": "1.36 (1.08-1.71)",
            "reported_p": "0.009",
        },
        "expected_primary_source": {
            "file": TARGET_SOURCE_REL,
            "line": TARGET_SOURCE_LINE,
            "model_id": "M2_ED_VISITS",
            "model_spec": "adjusted_nb_v2",
            "contrast": "Cohort_B vs Cohort_A",
            "exact_values": {
                "irr": "1.3604",
                "ci_low": "1.0803",
                "ci_high": "1.7131",
                "p_value": "0.0091",
            },
            "supporting_manifest": TARGET_MANIFEST_REL,
        },
        "expected_mechanism": expected_mechanism,
        "distractors": [
            {"file": DISTRACTOR_PRELIM_REL, "unique_value": "1.4410"},
            {"file": DISTRACTOR_M1_REL, "unique_value": "1.1502"},
            {"file": DISTRACTOR_M3_REL, "unique_value": "1.0601"},
        ],
    }

    key_path = ev / "expected_answer_key.json"
    key_bytes = (json.dumps(answer_key, indent=2, sort_keys=True) + "\n").encode("utf-8")
    key_path.write_bytes(key_bytes)
    answer_key["answer_key_sha256"] = _sha256_bytes(key_bytes)
    answer_key["answer_key_path"] = str(key_path)
    return answer_key


def _assess_mechanism(case_name: str, response_text: str) -> dict[str, Any]:
    unsupported_manual = base_fixture._detect_unsupported_manual_copy(response_text)
    mentions_export_script = (
        DOC_EXPORT_SCRIPT in response_text
        or "render_qmd_outcome_table.py" in response_text
    )
    mentions_model_script = (
        DOC_MODEL_SCRIPT in response_text or "fit_m2_nb_v2.R" in response_text
    )
    mentions_doc_log = (
        DOC_LOG_REL in response_text
        or "m2_table_export_20261121T073000Z.txt" in response_text
    )
    mentions_m1_log = (
        OPEN_DISTRACTOR_LOG_REL in response_text
        or "m1_table_export_20261119T160000Z.txt" in response_text
    )
    leaves_open = bool(
        re.search(
            r"(jää(?:vät)?\s+avoimeksi|tuotantotapa\s+jää\s+avoimeksi|"
            r"siirtotapa\s+.*avoimeksi|ei\s+(?:voi(?:da)?\s+)?(?:vahvistaa|todentaa)|"
            r"ei\s+ilmene|ei\s+ole\s+(?:työtilassa\s+)?dokumentoitu|"
            r"käsin\s+vai\s+(?:ulkoisella\s+|erillisellä\s+|automaattisella\s+)?(?:koonti)?skriptillä)",
            response_text,
            flags=re.IGNORECASE | re.DOTALL,
        )
    )

    if case_name == CASE_DOCUMENTED:
        mechanism_pass = bool(
            mentions_export_script and mentions_doc_log and not unsupported_manual
        )
        return {
            "expected_status": "documented_script",
            "mentions_export_script": mentions_export_script,
            "mentions_export_log": mentions_doc_log,
            "mentions_model_script": mentions_model_script,
            "unsupported_manual_copy_claim": unsupported_manual,
            "mechanism_pass": mechanism_pass,
        }

    # Open mechanism case (C2): if export script is mentioned, it must be scoped to M1 / left open for M2
    unscoped_script_attribution = bool(mentions_export_script and not leaves_open)
    mechanism_pass = bool(
        leaves_open and not unsupported_manual and not unscoped_script_attribution
    )
    return {
        "expected_status": "open",
        "leaves_m2_mechanism_open": leaves_open,
        "mentions_m1_distractor_log": mentions_m1_log,
        "mentions_export_script": mentions_export_script,
        "unscoped_script_attribution_to_m2": unscoped_script_attribution,
        "unsupported_manual_copy_claim": unsupported_manual,
        "mechanism_pass": mechanism_pass,
    }


def evaluate_run(
    eval_dir: Path,
    variant: str,
    stream_jsonl_path: Path,
    report_json_path: Path,
    report_md_path: Path,
    response_md_path: Path | None = None,
) -> dict[str, Any]:
    if variant not in VALID_VARIANTS:
        raise ValueError(f"Unsupported variant '{variant}', expected {VALID_VARIANTS}")

    ev = eval_dir.resolve()
    key_path = ev / "expected_answer_key.json"
    if not key_path.is_file():
        raise FileNotFoundError(f"Missing pre-locked answer key: {key_path}")

    key_bytes = key_path.read_bytes()
    key_sha256 = _sha256_bytes(key_bytes)
    key = json.loads(key_bytes.decode("utf-8"))
    case_name = key["case_name"]
    ws = Path(key["workspaces"][variant]).resolve()

    events: list[dict[str, Any]] = []
    for raw_line in stream_jsonl_path.read_text(encoding="utf-8").splitlines():
        stripped = raw_line.strip()
        if stripped.startswith("{"):
            events.append(json.loads(stripped))

    init_info: dict[str, Any] = {}
    result_info: dict[str, Any] = {}
    tool_calls: list[dict[str, Any]] = []

    for ev_obj in events:
        ev_type = ev_obj.get("event")
        if ev_type == "init":
            init_info = ev_obj.get("init", {})
            init_info["conversation_id"] = ev_obj.get("conversation_id", "")
        elif ev_type == "step_update":
            step = ev_obj.get("step_update", {})
            if step.get("step_type") == "tool" and step.get("state") == "DONE":
                tool_calls.append(
                    {
                        "step_index": step.get("step_index"),
                        "tool_name": step.get("tool_name"),
                        "duration_seconds": step.get("duration_seconds"),
                        "tool_info": step.get("tool_info", {}),
                    }
                )
        elif ev_type == "result":
            result_info = ev_obj.get("result", {})

    response_text = result_info.get("response", "") or ""
    response_sha256 = _sha256_bytes(response_text.encode("utf-8"))
    if response_md_path is not None:
        response_md_path.parent.mkdir(parents=True, exist_ok=True)
        response_md_path.write_text(response_text, encoding="utf-8")

    forbidden_used: list[str] = []
    disallowed_mcp_tool_executions: list[str] = []
    sqlite_tool_executions: list[str] = []
    inspected_paths: list[str] = []
    mcp_schema_reads: list[str] = []
    disallowed_mcp_schema_reads: list[str] = []
    sqlite_schema_reads: list[str] = []
    non_schema_outside_paths: list[str] = []
    outside_workspace_paths: list[str] = []
    workspace_read_count = 0

    for tc in tool_calls:
        tname = tc.get("tool_name") or ""
        tinfo = tc.get("tool_info", {}) or {}
        params = tinfo.get("parameters", {}) if isinstance(tinfo, dict) else {}

        if tname == "read_file":
            cands = base_fixture._extract_candidate_paths(tinfo)
            if not cands:
                forbidden_used.append("read_file(missing_path)")
            for raw_p in cands:
                cand = Path(raw_p)
                resolved = (ws / cand).resolve() if not cand.is_absolute() else cand.resolve()
                if resolved == ws or ws in resolved.parents:
                    inspected_paths.append(str(resolved.relative_to(ws)))
                    workspace_read_count += 1
                elif base_fixture._is_allowed_mcp_filesystem_schema_read(resolved):
                    mcp_schema_reads.append(resolved.name)
                else:
                    outside_workspace_paths.append(str(resolved))
                    classified = base_fixture._classify_mcp_schema_read(resolved)
                    if classified is not None:
                        srv, fname = classified
                        disallowed_mcp_schema_reads.append(f"{srv}/{fname}")
                        if srv == "sqlite":
                            sqlite_schema_reads.append(fname)
                    else:
                        non_schema_outside_paths.append(str(resolved))
        elif tname == "call_mcp_tool":
            server = params.get("ServerName")
            subtool = params.get("ToolName")
            if server != "filesystem" or subtool not in base_fixture.ALLOWED_FS_MCP_TOOLS:
                forbidden_used.append(f"call_mcp_tool({server}/{subtool})")
                disallowed_mcp_tool_executions.append(f"{server}/{subtool}")
                if server == "sqlite":
                    sqlite_tool_executions.append(str(subtool))
            else:
                cands = base_fixture._extract_candidate_paths(params.get("Arguments", {}))
                if not cands:
                    outside_workspace_paths.append(
                        f"call_mcp_tool({server}/{subtool}:missing_path)"
                    )
                    non_schema_outside_paths.append(
                        f"call_mcp_tool({server}/{subtool}:missing_path)"
                    )
                for raw_p in cands:
                    cand = Path(raw_p)
                    resolved = (
                        (ws / cand).resolve() if not cand.is_absolute() else cand.resolve()
                    )
                    if resolved == ws or ws in resolved.parents:
                        rel = "." if resolved == ws else str(resolved.relative_to(ws))
                        inspected_paths.append(rel)
                    else:
                        outside_workspace_paths.append(str(resolved))
                        non_schema_outside_paths.append(str(resolved))
        else:
            forbidden_used.append(tname)

    expected_src = key["expected_primary_source"]["file"]
    expected_line = int(key["expected_primary_source"]["line"])
    exact_vals = key["expected_primary_source"]["exact_values"]

    source_file_found = expected_src in response_text
    target_line_cited = base_fixture._check_target_line_cited(
        response_text, expected_src, expected_line
    )
    exact_values_cited = all(v in response_text for v in exact_vals.values())
    qmd_line_cited = base_fixture._check_target_line_cited(
        response_text,
        key["target_claim"]["manuscript_file"],
        int(key["target_claim"]["manuscript_line"]),
    )
    manifest_cited = key["expected_primary_source"]["supporting_manifest"] in response_text
    wrong_distractor_as_primary = not source_file_found and any(
        d["file"] in response_text for d in key["distractors"]
    )

    tool_execution_compliant = len(forbidden_used) == 0
    path_scope_compliant = len(outside_workspace_paths) == 0
    log_compliance_pass = path_scope_compliant and tool_execution_compliant

    source_search_pass = bool(
        result_info.get("status") == "SUCCESS"
        and workspace_read_count > 0
        and source_file_found
        and target_line_cited
        and exact_values_cited
        and not wrong_distractor_as_primary
    )
    mech = _assess_mechanism(case_name, response_text)
    mechanism_pass = bool(mech["mechanism_pass"])
    combined_pass = bool(source_search_pass and mechanism_pass and log_compliance_pass)

    report: dict[str, Any] = {
        "workpack_id": key["workpack_id"],
        "case_name": case_name,
        "variant": variant,
        "answer_key_sha256": key_sha256,
        "conversation_id": result_info.get("conversation_id")
        or init_info.get("conversation_id"),
        "model": init_info.get("model"),
        "status": result_info.get("status"),
        "duration_seconds": result_info.get("duration_seconds"),
        "num_turns": result_info.get("num_turns"),
        "usage": result_info.get("usage", {}),
        "response_sha256": response_sha256,
        "tool_calls_count": len(tool_calls),
        "workspace_read_count": workspace_read_count,
        "tool_names": [tc.get("tool_name") for tc in tool_calls],
        "inspected_workspace_paths": inspected_paths,
        "mcp_schema_reads": mcp_schema_reads,
        "disallowed_mcp_schema_reads": disallowed_mcp_schema_reads,
        "sqlite_schema_reads": sqlite_schema_reads,
        "disallowed_mcp_tool_executions": disallowed_mcp_tool_executions,
        "sqlite_tool_executions": sqlite_tool_executions,
        "non_schema_outside_paths": non_schema_outside_paths,
        "checks": {
            "source_file_found": source_file_found,
            "target_line_cited": target_line_cited,
            "exact_values_cited": exact_values_cited,
            "qmd_line_cited": qmd_line_cited,
            "manifest_cited": manifest_cited,
            "wrong_distractor_as_primary": wrong_distractor_as_primary,
            "tool_execution_compliant": tool_execution_compliant,
            "path_scope_compliant": path_scope_compliant,
            "observed_log_compliant": log_compliance_pass,
        },
        "mechanism_assessment": mech,
        "source_search_pass": source_search_pass,
        "mechanism_pass": mechanism_pass,
        "log_compliance_pass": log_compliance_pass,
        "combined_pass": combined_pass,
    }

    report_json_path.parent.mkdir(parents=True, exist_ok=True)
    report_json_path.write_text(
        json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )

    md_lines = [
        f"# WP-HARNESS-B-VS-BPRIME-02 — `{case_name}` / `{variant}`",
        "",
        f"- **Yhdistetty tulos (`combined_pass`):** `{'PASS' if combined_pass else 'FAIL'}`",
        f"- **Lähdehaun tulos (`source_search_pass`):** `{'PASS' if source_search_pass else 'FAIL'}`",
        f"- **Tuotantotavan rajaus (`mechanism_pass`):** `{'PASS' if mechanism_pass else 'FAIL'}`",
        f"- **Lokitarkistus (`log_compliance_pass`):** `{'PASS' if log_compliance_pass else 'FAIL'}`",
        f"- **Istunto (`conversation_id`):** `{report['conversation_id']}`",
        f"- **Malli:** `{report['model']}`",
        f"- **Kesto / tokenit:** `{report['duration_seconds']} s` / `{json.dumps(report['usage'])}`",
        f"- **Lukitun vastausavaimen SHA-256:** `{key_sha256}`",
        f"- **Vastauksen SHA-256:** `{response_sha256}`",
        "",
        "## 1. Kohderivi ja lähdehaku",
        "",
        f"- Käsikirjoituksen kohderivi (`rivi {TARGET_QMD_LINE}`): `{qmd_line_cited}`",
        f"- Lähdetiedosto (`{expected_src}`): `{source_file_found}`",
        f"- Lähderivi (`rivi {expected_line}`): `{target_line_cited}`",
        f"- Tarkat arvot (`1.3604`, `1.0803`, `1.7131`, `0.0091`): `{exact_values_cited}`",
        "",
        "## 2. Tuotantotavan arviointi",
        "",
        f"- Arviointitiedot: `{json.dumps(mech, ensure_ascii=False)}`",
        "",
        "## 3. Havaittu ajoloki",
        "",
        f"- Työkalukutsut (`DONE`): `{len(tool_calls)}` (`{', '.join(x or '' for x in report['tool_names'])}`)",
        f"- Työtilassa luetut polut: `{', '.join(inspected_paths)}`",
        f"- Sallitut `filesystem`-skeemaluvut: `{mcp_schema_reads}`",
        f"- Muut MCP-skeemaluvut (ei suoritusta): `{disallowed_mcp_schema_reads}`",
        f"- SQLite-kuvaustiedoston luku: `{sqlite_schema_reads}` (`{len(sqlite_schema_reads)}` kpl)",
        f"- Varsinaisen SQLite-työkalun suoritus: `{sqlite_tool_executions}` (`{len(sqlite_tool_executions)}` kpl)",
        f"- Muut ulkopuoliset polut: `{non_schema_outside_paths}`",
    ]
    report_md_path.parent.mkdir(parents=True, exist_ok=True)
    report_md_path.write_text("\n".join(md_lines) + "\n", encoding="utf-8")
    return report


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_mat = sub.add_parser("materialize-pair", help="Materialize B and B' workspaces + key")
    p_mat.add_argument("--case", required=True, choices=VALID_CASES)
    p_mat.add_argument("--ws-b", required=True, type=Path)
    p_mat.add_argument("--ws-bprime", required=True, type=Path)
    p_mat.add_argument("--eval-dir", required=True, type=Path)

    p_eval = sub.add_parser("evaluate-run", help="Evaluate a single B or B' run")
    p_eval.add_argument("--eval-dir", required=True, type=Path)
    p_eval.add_argument("--variant", required=True, choices=VALID_VARIANTS)
    p_eval.add_argument("--stream-jsonl", required=True, type=Path)
    p_eval.add_argument("--report-json", required=True, type=Path)
    p_eval.add_argument("--report-md", required=True, type=Path)
    p_eval.add_argument("--response-md", required=False, type=Path)

    args = parser.parse_args(argv)
    try:
        if args.cmd == "materialize-pair":
            res = materialize_pair(
                args.case, args.ws_b, args.ws_bprime, args.eval_dir
            )
            print(
                f"materialized case={res['case_name']} "
                f"answer_key_sha256={res['answer_key_sha256']}"
            )
            return 0
        if args.cmd == "evaluate-run":
            rep = evaluate_run(
                args.eval_dir,
                args.variant,
                args.stream_jsonl,
                args.report_json,
                args.report_md,
                args.response_md,
            )
            print(
                f"evaluated case={rep['case_name']} variant={rep['variant']} "
                f"source_search_pass={rep['source_search_pass']} "
                f"mechanism_pass={rep['mechanism_pass']} "
                f"log_compliance_pass={rep['log_compliance_pass']}"
            )
            return 0
    except Exception as exc:
        print(f"b-vs-bprime: error: {exc}", file=sys.stderr)
        return 2
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
