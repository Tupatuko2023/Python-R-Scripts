#!/usr/bin/env python3
"""Deterministic synthetic workspace generator and evaluator for Antigravity Harness.

Workpack: WP-HARNESS-SYNTH-FILE-SEARCH-01
Governance: 100% synthetic test data; evaluation answer key is kept outside the
agent workspace directory. Uses Python standard library only.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import sys
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[2]

TARGET_QMD_REL = "manuscripts/SYNTH_COHORT_REVIEW_20261120.qmd"
TARGET_SOURCE_REL = "runs/20261119_model_s2_primary/model_estimates.tsv"
TARGET_MANIFEST_REL = "runs/20261119_model_s2_primary/run_manifest.json"
DISTRACTOR_PRELIM_REL = "runs/20261118_model_s2_prelim/model_estimates.tsv"
DISTRACTOR_S1_REL = "runs/20261115_model_s1_visits/model_estimates.tsv"
DISTRACTOR_S3_REL = "runs/20261119_model_s3_hosp/model_estimates.tsv"
NOTES_REL = "notes/README_SYNTHETIC.md"

TARGET_QMD_LINE = 17
TARGET_SOURCE_LINE = 4

ALLOWED_FS_MCP_TOOLS = frozenset({"directory_tree", "list_directory", "search_files"})


def _sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _build_workspace_contents() -> dict[str, str]:
    qmd = (
        "---\n"
        'title: "Synthetic Cohort Service Utilization Review"\n'
        'date: "2026-11-20"\n'
        "execute:\n"
        "  enabled: false\n"
        "---\n"
        "\n"
        "# Overview\n"
        "\n"
        "This synthetic manuscript summarizes simulated cohort models for harness testing.\n"
        "\n"
        "# Primary Results\n"
        "\n"
        "| Model ID | Outcome | Contrast | Adjusted IRR (95% CI) | p-value |\n"
        "| :--- | :--- | :--- | :--- | :--- |\n"
        "| S1_VISITS | Outpatient visits | Cohort_B vs Cohort_A | 1.18 (0.96-1.45) | 0.118 |\n"
        "| S2_FALL_RATE | Recurrent fall rate | Cohort_B vs Cohort_A | 1.42 (1.11-1.82) | 0.005 |\n"
        "| S3_HOSP_DAYS | Inpatient days | Cohort_B vs Cohort_A | 1.09 (0.84-1.41) | 0.512 |\n"
        "\n"
        ": Synthetic negative binomial estimates {#tbl-synth-outcomes}\n"
    )
    qmd_lines = qmd.splitlines()
    if "| S2_FALL_RATE |" not in qmd_lines[TARGET_QMD_LINE - 1]:
        raise RuntimeError("Internal fixture line-number mismatch for target QMD row")

    target_tsv = (
        "model_id\tmodel_spec\tcontrast\tirr\tci_low\tci_high\tp_value\tstatus\n"
        "S2_FALL_RATE\tadjusted_nb_v2\tCohort_A (ref)\t1.0000\tNA\tNA\tNA\tprimary_frozen\n"
        "S2_FALL_RATE\tadjusted_nb_v2\tAge_per_5y\t1.0712\t1.0198\t1.1252\t0.0061\tprimary_frozen\n"
        "S2_FALL_RATE\tadjusted_nb_v2\tCohort_B vs Cohort_A\t1.4204\t1.1102\t1.8173\t0.0052\tprimary_frozen\n"
        "S2_FALL_RATE\tadjusted_nb_v2\tPrior_fall_yes\t1.6340\t1.2810\t2.0842\t0.0001\tprimary_frozen\n"
    )
    tsv_lines = target_tsv.splitlines()
    if "1.4204" not in tsv_lines[TARGET_SOURCE_LINE - 1]:
        raise RuntimeError("Internal fixture line-number mismatch for target TSV row")

    target_tsv_sha256 = _sha256_bytes(target_tsv.encode("utf-8"))
    target_manifest = (
        json.dumps(
            {
                "run_id": "20261119T141500Z_s2_primary",
                "model_id": "S2_FALL_RATE",
                "model_spec": "adjusted_nb_v2",
                "upstream_synthetic_input": "SYNTH_PANEL_V2",
                "estimates_file": TARGET_SOURCE_REL,
                "estimates_sha256": target_tsv_sha256,
                "status": "primary_frozen",
            },
            indent=2,
        )
        + "\n"
    )

    distractor_prelim = (
        "model_id\tmodel_spec\tcontrast\tirr\tci_low\tci_high\tp_value\tstatus\n"
        "S2_FALL_RATE\tunadjusted_nb_v1\tCohort_A (ref)\t1.0000\tNA\tNA\tNA\tsuperseded_preliminary\n"
        "S2_FALL_RATE\tunadjusted_nb_v1\tCohort_B vs Cohort_A\t1.4910\t1.1620\t1.9132\t0.0018\tsuperseded_preliminary\n"
    )

    distractor_s1 = (
        "model_id\tmodel_spec\tcontrast\tirr\tci_low\tci_high\tp_value\tstatus\n"
        "S1_VISITS\tadjusted_nb_v2\tCohort_A (ref)\t1.0000\tNA\tNA\tNA\tprimary_frozen\n"
        "S1_VISITS\tadjusted_nb_v2\tCohort_B vs Cohort_A\t1.1803\t0.9604\t1.4506\t0.1181\tprimary_frozen\n"
    )

    distractor_s3 = (
        "model_id\tmodel_spec\tcontrast\tirr\tci_low\tci_high\tp_value\tstatus\n"
        "S3_HOSP_DAYS\tadjusted_nb_v2\tCohort_A (ref)\t1.0000\tNA\tNA\tNA\tprimary_frozen\n"
        "S3_HOSP_DAYS\tadjusted_nb_v2\tCohort_B vs Cohort_A\t1.0897\t0.8422\t1.4099\t0.5124\tprimary_frozen\n"
    )

    notes = (
        "# Synthetic Harness Workspace (SYNTH-COHORT-2026)\n"
        "\n"
        "All files in this directory are purely synthetic test artifacts generated for\n"
        "Antigravity Harness file-search verification (`WP-HARNESS-SYNTH-FILE-SEARCH-01`).\n"
        "\n"
        "- `manuscripts/` contains synthetic Quarto manuscript drafts.\n"
        "- `runs/` contains candidate synthetic model run outputs and manifests.\n"
    )

    return {
        NOTES_REL: notes,
        TARGET_QMD_REL: qmd,
        DISTRACTOR_S1_REL: distractor_s1,
        DISTRACTOR_PRELIM_REL: distractor_prelim,
        TARGET_SOURCE_REL: target_tsv,
        TARGET_MANIFEST_REL: target_manifest,
        DISTRACTOR_S3_REL: distractor_s3,
    }


def _build_baseline_prompt() -> str:
    return (
        "Toimit lähdejäljitystarkastajana tässä synteettisessä työtilassa.\n"
        "Tehtävä: etsi työtilan tiedostoista alkuperäinen malliajon lähdetiedosto ja "
        "täsmällinen kohderivi käsikirjoituksen `manuscripts/SYNTH_COHORT_REVIEW_20261120.qmd` "
        "taulukon `@tbl-synth-outcomes` riville `S2_FALL_RATE` (`Cohort_B vs Cohort_A`, "
        "`1.42 (1.11-1.82)`, `p = 0.005`).\n\n"
        "Käytä vain tämän nykyisen työhakemiston tiedostoja.\n"
        "Palauta suomeksi jäsennelty raportti, jossa on:\n"
        "1. Käsikirjoituksen kohderivi (suhteellinen tiedostopolku ja rivinumero).\n"
        "2. Löydetty ensisijainen lähdetiedosto (suhteellinen tiedostopolku, rivinumero "
        "ja rivin tarkat pyöristämättömät arvot) sekä mahdollinen ajomanifesti.\n"
        "3. Hylätyt ehdokastiedostot ja lyhyt syy, miksi ne eivät vastaa kohderiviä.\n"
        "4. Mitä ketjusta voi vahvistaa lähteillä ja mikä jää avoimeksi (esim. tapa, "
        "jolla luvut on viety QMD-taulukkoon).\n\n"
        "Lopputarkistus ennen vastausta: tarkista jokaisesta väitteestäsi, että sille "
        "on suora lähdekohta lukemissasi tiedostoissa, ja rajaa päätelmäsi tarkasti "
        "vain tarkistettuun riviin ja todennettuihin tiedostoihin.\n"
    )


def _build_cli_settings() -> dict[str, Any]:
    """Build session-only Antigravity CLI settings enforcing read-only search.

    Note: Do not pass --dangerously-skip-permissions when invoking agy, because
    that flag bypasses permissions.deny rules. Native read_file is audited from
    stream-json post-run because agy 1.5.14 does not enforce path-scoped
    read_file(...) deny patterns.
    """
    return {
        "permissions": {
            "allow": [
                "mcp(filesystem/directory_tree)",
                "mcp(filesystem/list_directory)",
                "mcp(filesystem/search_files)",
            ],
            "deny": [
                "command(*)",
                "write_file(*)",
                "read_url(*)",
                "mcp(shell/*)",
                "mcp(citecheck/*)",
                "mcp(pandoc/*)",
                "mcp(pubmed/*)",
                "mcp(sqlite/*)",
                "mcp(zotero/*)",
            ],
        }
    }


def _paths_overlap(a: Path, b: Path) -> bool:
    return a == b or a in b.parents or b in a.parents


def materialize(
    workspace_dir: Path,
    eval_dir: Path,
    *,
    allow_inside_repo: bool = False,
) -> dict[str, Any]:
    ws = workspace_dir.resolve()
    ev = eval_dir.resolve()
    repo = REPO_ROOT.resolve()

    if _paths_overlap(ws, ev):
        raise ValueError(
            f"workspace_dir ({ws}) and eval_dir ({ev}) must not overlap; "
            "keep answer key outside agent workspace"
        )
    if not allow_inside_repo and (ws == repo or repo in ws.parents):
        raise ValueError(
            f"workspace_dir ({ws}) must be outside the repository root ({repo})"
        )
    if ws.exists() and any(ws.iterdir()):
        raise ValueError(f"workspace_dir ({ws}) already exists and is non-empty")

    ws.mkdir(parents=True, exist_ok=True)
    ev.mkdir(parents=True, exist_ok=True)

    contents = _build_workspace_contents()
    file_hashes: dict[str, str] = {}
    for rel_path, text in sorted(contents.items()):
        dest = ws / rel_path
        dest.parent.mkdir(parents=True, exist_ok=True)
        raw = text.encode("utf-8")
        dest.write_bytes(raw)
        file_hashes[rel_path] = _sha256_bytes(raw)

    prompt_text = _build_baseline_prompt()
    prompt_path = ev / "prompt_baseline_b.txt"
    prompt_bytes = prompt_text.encode("utf-8")
    prompt_path.write_bytes(prompt_bytes)

    settings_obj = _build_cli_settings()
    settings_path = ev / "cli_settings.json"
    settings_bytes = (json.dumps(settings_obj, indent=2, sort_keys=True) + "\n").encode(
        "utf-8"
    )
    settings_path.write_bytes(settings_bytes)

    answer_key: dict[str, Any] = {
        "workpack_id": "WP-HARNESS-SYNTH-FILE-SEARCH-01",
        "workspace_dir": str(ws),
        "workspace_files_sha256": file_hashes,
        "prompt_file": str(prompt_path),
        "prompt_sha256": _sha256_bytes(prompt_bytes),
        "cli_settings_file": str(settings_path),
        "cli_settings_sha256": _sha256_bytes(settings_bytes),
        "target_claim": {
            "manuscript_file": TARGET_QMD_REL,
            "manuscript_line": TARGET_QMD_LINE,
            "table_id": "@tbl-synth-outcomes",
            "model_id": "S2_FALL_RATE",
            "contrast": "Cohort_B vs Cohort_A",
            "reported_irr_ci": "1.42 (1.11-1.82)",
            "reported_p": "0.005",
        },
        "expected_primary_source": {
            "file": TARGET_SOURCE_REL,
            "line": TARGET_SOURCE_LINE,
            "model_id": "S2_FALL_RATE",
            "model_spec": "adjusted_nb_v2",
            "contrast": "Cohort_B vs Cohort_A",
            "exact_values": {
                "irr": "1.4204",
                "ci_low": "1.1102",
                "ci_high": "1.8173",
                "p_value": "0.0052",
            },
            "supporting_manifest": TARGET_MANIFEST_REL,
        },
        "distractors": [
            {
                "file": DISTRACTOR_PRELIM_REL,
                "reason": "Unadjusted superseded preliminary model (IRR 1.4910 vs 1.42)",
                "unique_value": "1.4910",
            },
            {
                "file": DISTRACTOR_S1_REL,
                "reason": "Different outcome model S1_VISITS (IRR 1.1803)",
                "unique_value": "1.1803",
            },
            {
                "file": DISTRACTOR_S3_REL,
                "reason": "Different outcome model S3_HOSP_DAYS (IRR 1.0897)",
                "unique_value": "1.0897",
            },
        ],
        "grounded_conclusions": [
            "Manuscript line 17 matches runs/20261119_model_s2_primary/model_estimates.tsv line 4 after standard rounding (1.4204 -> 1.42, 1.1102 -> 1.11, 1.8173 -> 1.82, 0.0052 -> 0.005).",
            "run_manifest.json in runs/20261119_model_s2_primary/ locks the exact SHA-256 of model_estimates.tsv for run 20261119T141500Z_s2_primary.",
        ],
        "open_or_unproven_items": [
            "How estimates were inserted into manuscripts/SYNTH_COHORT_REVIEW_20261120.qmd (manual transcription vs external script) is not documented; execute: enabled: false only proves Quarto does not recompute cells at render time.",
            "Upstream synthetic cohort generation script producing SYNTH_PANEL_V2 is not present in the workspace.",
        ],
    }

    key_path = ev / "expected_answer_key.json"
    key_bytes = (json.dumps(answer_key, indent=2, sort_keys=True) + "\n").encode("utf-8")
    key_path.write_bytes(key_bytes)
    answer_key["answer_key_sha256"] = _sha256_bytes(key_bytes)
    answer_key["answer_key_path"] = str(key_path)
    return answer_key


def _extract_candidate_paths(tool_info: Any) -> list[str]:
    found: list[str] = []
    if isinstance(tool_info, dict):
        for key, val in tool_info.items():
            if key.lower() in {
                "path",
                "file",
                "filepath",
                "file_path",
                "directory",
                "searchdirectory",
                "search_path",
                "targetfile",
            }:
                if isinstance(val, str):
                    found.append(val)
                elif isinstance(val, list):
                    found.extend(x for x in val if isinstance(x, str))
            else:
                found.extend(_extract_candidate_paths(val))
    elif isinstance(tool_info, list):
        for item in tool_info:
            found.extend(_extract_candidate_paths(item))
    return found


def _classify_mcp_schema_read(resolved: Path) -> tuple[str, str] | None:
    """Return (server_name, filename) if path is an Antigravity MCP schema JSON."""
    parts = resolved.parts
    if (
        resolved.suffix == ".json"
        and len(parts) >= 4
        and parts[-4:-2] == ("antigravity-cli", "mcp")
    ):
        return parts[-2], resolved.name
    return None


def _is_allowed_mcp_filesystem_schema_read(resolved: Path) -> bool:
    """Allow reading only lazy-loaded Antigravity filesystem MCP tool schema JSONs."""
    classified = _classify_mcp_schema_read(resolved)
    return (
        classified is not None
        and classified[0] == "filesystem"
        and resolved.stem in ALLOWED_FS_MCP_TOOLS
    )


def _check_target_line_cited(response_text: str, source_rel: str, line_no: int) -> bool:
    escaped_src = re.escape(source_rel)
    escaped_base = re.escape(Path(source_rel).name)
    patterns = [
        rf"{escaped_src}(?:#L{line_no}\b|:{line_no}\b)",
        rf"{escaped_base}(?:#L{line_no}\b|:{line_no}\b)",
        rf"\brivi(?:llä|n|lle|ltä)?\s*{line_no}\b",
        rf"\bline\s*{line_no}\b",
        rf"\bL{line_no}\b",
    ]
    return any(re.search(pat, response_text, flags=re.IGNORECASE) for pat in patterns)


def _detect_unsupported_manual_copy(response_text: str) -> bool:
    """Return True if response asserts manual copying without leaving mechanism open."""
    manual_claim = re.search(
        r"(käsin\s+kopioi|manuaalisesti\s+kopioi|kopioitu\s+käsin|manually\s+copied)",
        response_text,
        flags=re.IGNORECASE,
    )
    if not manual_claim:
        return False
    open_qualifier = re.search(
        r"(jää\s+avoimeksi|ei\s+(?:voi\s+)?vahvistaa|ei\s+sulje\s+pois|avoin\b|tuntematon|"
        r"ei\s+ilmene|ei\s+dokumentoitu|ei\s+voida\s+todentaa|käsin\s+vai\s+ulkoisella|"
        r"tai\s+(?:ulkoisella\s+)?(?:koonti)?skriptillä)",
        response_text,
        flags=re.IGNORECASE,
    )
    return open_qualifier is None


def evaluate(
    eval_dir: Path,
    stream_jsonl_path: Path,
    report_json_path: Path,
    report_md_path: Path,
) -> dict[str, Any]:
    ev = eval_dir.resolve()
    key_path = ev / "expected_answer_key.json"
    if not key_path.is_file():
        raise FileNotFoundError(f"Missing pre-locked answer key: {key_path}")

    key_bytes = key_path.read_bytes()
    key_sha256 = _sha256_bytes(key_bytes)
    key = json.loads(key_bytes.decode("utf-8"))
    ws = Path(key["workspace_dir"]).resolve()

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
            cands = _extract_candidate_paths(tinfo)
            if not cands:
                forbidden_used.append("read_file(missing_path)")
            for raw_p in cands:
                cand = Path(raw_p)
                resolved = (ws / cand).resolve() if not cand.is_absolute() else cand.resolve()
                if resolved == ws or ws in resolved.parents:
                    inspected_paths.append(str(resolved.relative_to(ws)))
                    workspace_read_count += 1
                elif _is_allowed_mcp_filesystem_schema_read(resolved):
                    mcp_schema_reads.append(resolved.name)
                else:
                    outside_workspace_paths.append(str(resolved))
                    classified = _classify_mcp_schema_read(resolved)
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
            if server != "filesystem" or subtool not in ALLOWED_FS_MCP_TOOLS:
                forbidden_used.append(f"call_mcp_tool({server}/{subtool})")
                disallowed_mcp_tool_executions.append(f"{server}/{subtool}")
                if server == "sqlite":
                    sqlite_tool_executions.append(str(subtool))
            else:
                cands = _extract_candidate_paths(params.get("Arguments", {}))
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
    target_line_cited = _check_target_line_cited(
        response_text, expected_src, expected_line
    )
    exact_values_cited = all(v in response_text for v in exact_vals.values())
    qmd_line_cited = _check_target_line_cited(
        response_text,
        key["target_claim"]["manuscript_file"],
        int(key["target_claim"]["manuscript_line"]),
    )
    manifest_cited = key["expected_primary_source"]["supporting_manifest"] in response_text
    unsupported_manual_copy = _detect_unsupported_manual_copy(response_text)

    wrong_distractor_as_primary = not source_file_found and any(
        d["file"] in response_text for d in key["distractors"]
    )

    tool_execution_compliant = len(forbidden_used) == 0
    path_scope_compliant = len(outside_workspace_paths) == 0
    workspace_isolated = path_scope_compliant and tool_execution_compliant

    source_search_pass = bool(
        result_info.get("status") == "SUCCESS"
        and workspace_read_count > 0
        and source_file_found
        and target_line_cited
        and exact_values_cited
        and not wrong_distractor_as_primary
    )
    log_compliance_pass = workspace_isolated
    primary_criterion_pass = bool(source_search_pass and workspace_isolated)

    report: dict[str, Any] = {
        "workpack_id": key["workpack_id"],
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
        "outside_workspace_paths": outside_workspace_paths,
        "forbidden_tools_used": forbidden_used,
        "checks": {
            "tool_execution_compliant": tool_execution_compliant,
            "path_scope_compliant": path_scope_compliant,
            "workspace_isolated": workspace_isolated,
            "source_file_found": source_file_found,
            "target_line_cited": target_line_cited,
            "exact_values_cited": exact_values_cited,
            "qmd_line_cited": qmd_line_cited,
            "manifest_cited": manifest_cited,
            "wrong_distractor_as_primary": wrong_distractor_as_primary,
            "unsupported_manual_copy_claim": unsupported_manual_copy,
        },
        "source_search_pass": source_search_pass,
        "log_compliance_pass": log_compliance_pass,
        "primary_criterion_pass": primary_criterion_pass,
    }

    report_json_path.parent.mkdir(parents=True, exist_ok=True)
    report_json_path.write_text(
        json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )

    md_lines = [
        "# WP-HARNESS-SYNTH-FILE-SEARCH-01 — Arviointiraportti",
        "",
        f"- **Yhdistetty ensisijainen onnistumiskriteeri (`primary_criterion_pass`):** `{'PASS' if primary_criterion_pass else 'FAIL'}`",
        f"- **Lähdehaun tulos (`source_search_pass`):** `{'PASS' if source_search_pass else 'FAIL'}`",
        f"- **Työkalujen ja polkujen sääntöjenmukaisuus (`log_compliance_pass`):** `{'PASS' if log_compliance_pass else 'FAIL'}`",
        f"- **Istunto (`conversation_id`):** `{report['conversation_id']}`",
        f"- **Malli:** `{report['model']}`",
        f"- **Kesto / tokenit:** `{report['duration_seconds']} s` / `{json.dumps(report['usage'])}`",
        f"- **Ennakkoon lukitun vastausavaimen SHA-256:** `{key_sha256}`",
        f"- **Vastauksen SHA-256:** `{response_sha256}`",
        "",
        "## 1. Lähdehaun tulos ja perustellut / perusteettomat päätelmät",
        "",
        f"- Oikea lähdetiedosto (`{expected_src}`) tunnistettu: `{source_file_found}`",
        f"- Kohderivi (`rivi {expected_line}`) osoitettu täsmällisellä viitteellä: `{target_line_cited}`",
        f"- Pyöristämättömät lähdearvot (`1.4204`, `1.1102`, `1.8173`, `0.0052`) kirjattu: `{exact_values_cited}`",
        f"- Käsikirjoituksen kohderivi (`rivi {TARGET_QMD_LINE}`) osoitettu: `{qmd_line_cited}`",
        f"- Ajomanifesti (`{TARGET_MANIFEST_REL}`) tunnistettu: `{manifest_cited}`",
        f"- Harhautustiedosto valittu virheellisesti päälähteeksi: `{wrong_distractor_as_primary}`",
        f"- Perusteeton väite varmasta käsin kopioinnista ilman lähdettä: `{unsupported_manual_copy}`",
        "",
        "## 2. Lokissa havaittujen työkalujen ja polkujen sääntöjenmukaisuus",
        "",
        f"- Suoritetut työkalukutsut (`DONE`): `{len(tool_calls)}` (`{', '.join(x or '' for x in report['tool_names'])}`)",
        f"- Työtilan tiedostoluvut (`read_file`): `{workspace_read_count}`",
        f"- Työtilassa tarkistetut suhteelliset polut: `{', '.join(inspected_paths) if inspected_paths else 'ei polkuja'}`",
        f"- Työkalujen suorituksen sääntöjenmukaisuus (`tool_execution_compliant`): `{tool_execution_compliant}` (kielletyt suoritukset: `{forbidden_used}`)",
        f"- Polkujen rajauksen sääntöjenmukaisuus (`path_scope_compliant`, vain työtila + `mcp/filesystem/*.json`): `{path_scope_compliant}`",
        f"- Sallitut `filesystem`-MCP-kuvaustiedostojen luvut (`read_file`): `{mcp_schema_reads}`",
        f"- Muut MCP-kuvaustiedostojen luvut (`read_file`, ei työkalun suoritusta): `{disallowed_mcp_schema_reads}`",
        f"- **SQLite-kuvaustiedoston luku (`read_file` `mcp/sqlite/*.json`):** `{sqlite_schema_reads}` (`{len(sqlite_schema_reads)}` kpl)",
        f"- **Varsinaisen SQLite-työkalun suoritus (`call_mcp_tool` `sqlite/*`):** `{sqlite_tool_executions}` (`{len(sqlite_tool_executions)}` kpl)",
        f"- Muut työtilan ulkopuoliset polut (ei-MCP-kuvaustiedostot): `{non_schema_outside_paths}`",
        "",
        "## 3. Ajon rajoitteet",
        "",
        "- Antigravity CLI `1.5.14` ei sisällä natiivia hakemistolistaustyökalua, joten hakemistorakenne listataan vain lukuoikeuksisella `mcp(filesystem/directory_tree|list_directory|search_files)`-kutsulla, kun `command(*)`, `write_file(*)`, `read_url(*)` ja muut MCP-palvelimet on estetty `cli_settings.json`-tiedostossa (ilman `--dangerously-skip-permissions`-lippua).",
        "- Koska natiivi `read_file` on oletuksena avoin polkujen lukuun paikallisten estojen ulkopuolella, synteettinen koe pidetään erillään suojatusta tutkimusaineistosta ja jokaisen työkalukutsun polku tarkistetaan jälkikäteen `stream-json`-lokista säilyttäen tiukan sallittujen polkujen rajauksen.",
    ]
    report_md_path.parent.mkdir(parents=True, exist_ok=True)
    report_md_path.write_text("\n".join(md_lines) + "\n", encoding="utf-8")

    return report


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_mat = sub.add_parser("materialize", help="Generate synthetic workspace and eval key")
    p_mat.add_argument("--workspace-dir", required=True, type=Path)
    p_mat.add_argument("--eval-dir", required=True, type=Path)

    p_eval = sub.add_parser("evaluate", help="Evaluate stream-json CLI output against key")
    p_eval.add_argument("--eval-dir", required=True, type=Path)
    p_eval.add_argument("--stream-jsonl", required=True, type=Path)
    p_eval.add_argument("--report-json", required=True, type=Path)
    p_eval.add_argument("--report-md", required=True, type=Path)

    args = parser.parse_args(argv)
    try:
        if args.cmd == "materialize":
            res = materialize(args.workspace_dir, args.eval_dir)
            print(
                f"materialized workspace={res['workspace_dir']} "
                f"answer_key_sha256={res['answer_key_sha256']}"
            )
            return 0
        if args.cmd == "evaluate":
            rep = evaluate(
                args.eval_dir, args.stream_jsonl, args.report_json, args.report_md
            )
            print(
                f"evaluated primary_criterion_pass={rep['primary_criterion_pass']} "
                f"source_search_pass={rep['source_search_pass']} "
                f"log_compliance_pass={rep['log_compliance_pass']} "
                f"tool_calls={rep['tool_calls_count']}"
            )
            return 0 if rep["primary_criterion_pass"] else 1
    except Exception as exc:
        print(f"antigravity-harness: error: {exc}", file=sys.stderr)
        return 2
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
