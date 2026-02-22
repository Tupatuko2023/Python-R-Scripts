#!/usr/bin/env python3
import argparse
import os
import re
import subprocess
import sys
from pathlib import Path


DATA_BLOCKLIST_PREFIXES = ("data/", "data/external/")
R_SCRIPT_PREFIXES = ("R-scripts/", "Fear-of-Falling/R-scripts/")
VAR_HEAD_RE = re.compile(r"^([A-Za-zÀ-ÖØ-öø-ÿ_][A-Za-z0-9À-ÖØ-öø-ÿ_]*)")


def run_git_diff():
    try:
        root = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            check=True,
            capture_output=True,
            text=True,
        )
    except subprocess.CalledProcessError:
        print("FAIL: preflight requires a git repo.")
        return None, None
    repo_root = root.stdout.strip()

    result = subprocess.run(
        ["git", "diff", "--name-only", "--diff-filter=ACMRTUXB"],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print("FAIL: git diff failed. preflight requires git diff to run.")
        return None, None

    files = [line.strip() for line in result.stdout.splitlines() if line.strip()]
    return repo_root, files


def read_lines(path):
    try:
        return Path(path).read_text(encoding="utf-8").splitlines()
    except OSError as exc:
        return None, f"cannot read file: {exc}"


def _debug_enabled():
    return os.getenv("FOF_PREFLIGHT_DEBUG") in ("1", "true", "TRUE", "yes", "YES")


def _debug_add(debug_rows, reason, line):
    if debug_rows is None or len(debug_rows) >= 20:
        return
    snippet = (line or "").strip()
    if len(snippet) > 140:
        snippet = snippet[:137] + "..."
    debug_rows.append(f"{reason}: {snippet}")


def extract_required_vars(lines):
    req_lines = []
    warn = None
    debug_rows = [] if _debug_enabled() else None
    req_indices = [
        i
        for i, line in enumerate(lines)
        if re.search(r"Required vars", line, flags=re.IGNORECASE)
    ]
    if not req_indices:
        return None, "Required vars header not found", debug_rows
    if len(req_indices) > 1:
        warn = (
            f"multiple Required vars headers found ({len(req_indices)}); "
            "using the first header block"
        )

    start = req_indices[0] + 1
    stop_markers = re.compile(
        r"Reproducibility|Outputs \+ manifest|Workflow|Mapping example|Mapping|Note:|Analyses performed",
        re.IGNORECASE,
    )
    for line in lines[start:]:
        stripped = line.strip()
        if not stripped:
            _debug_add(debug_rows, "stop-empty", line)
            break
        if stripped == "#":
            _debug_add(debug_rows, "stop-comment-only", line)
            break
        if not stripped.startswith("#"):
            _debug_add(debug_rows, "stop-not-comment", line)
            break
        if stop_markers.search(stripped):
            _debug_add(debug_rows, "stop-marker", line)
            break
        req_lines.append(stripped.lstrip("#").strip())

    if not req_lines:
        return None, "Required vars list not found under header", debug_rows

    parsed = []
    skip_tokens = {
        "required",
        "vars",
        "raw_data",
        "analysis",
        "df",
        "after",
        "from",
        "factor",
        "robust",
        "pre",
        "frail",
    }
    for raw in req_lines:
        line = re.sub(r"^[-*]\s*", "", raw.strip())
        if not line:
            _debug_add(debug_rows, "skip-empty", raw)
            continue
        lower = line.lower()
        if (line.startswith("[") and line.endswith("]")) or line.startswith("("):
            _debug_add(debug_rows, "skip-bracketed", raw)
            continue
        if lower.startswith("typical candidates:") or lower.startswith("note:"):
            _debug_add(debug_rows, "skip-note", raw)
            continue
        parts = [part.strip() for part in line.split(",") if part.strip()]
        for part in parts:
            m = VAR_HEAD_RE.match(part)
            if not m:
                _debug_add(debug_rows, "skip-no-var-head", part)
                continue
            token = m.group(1)
            if token.lower() in skip_tokens:
                _debug_add(debug_rows, "skip-stop-token", token)
                continue
            parsed.append(token)

    if not parsed:
        return None, "Required vars list could not be parsed", debug_rows
    return parsed, warn, debug_rows


def extract_req_cols(lines):
    matches = []
    for i, line in enumerate(lines):
        if re.search(r"^\s*req_cols\s*<-", line):
            matches.append((i, "req_cols"))
        elif re.search(r"^\s*req_raw_cols\s*<-", line):
            matches.append((i, "req_raw_cols"))
    if not matches:
        return None, "req_cols/req_raw_cols definition not found"
    names = [name for _, name in matches]
    if names.count("req_cols") > 1 or names.count("req_raw_cols") > 1:
        return None, "multiple req_cols/req_raw_cols definitions found"

    preferred = None
    for idx, name in matches:
        if name == "req_cols":
            preferred = idx
            break
    if preferred is None:
        preferred = matches[0][0]

    i = preferred
    buf = []
    open_parens = 0
    started = False
    for line in lines[i:]:
        if not started:
            if "c(" in line:
                started = True
        if started:
            buf.append(line)
            open_parens += line.count("(")
            open_parens -= line.count(")")
            if open_parens <= 0:
                break
    content = "\n".join(buf)
    if "c(" not in content:
        return None, "req_cols c(...) block not found"

    quoted = re.findall(r"['\"]([^'\"]+)['\"]", content)
    if not quoted:
        return None, "req_cols values could not be parsed"
    return quoted, None


def check_standard_intro(path, lines):
    intro_hits = [
        i for i, line in enumerate(lines) if re.search(r"Required vars", line, re.IGNORECASE)
    ]
    if not intro_hits:
        return False, f"{path}: Required vars header missing"
    if intro_hits[0] > 150:
        return False, f"{path}: Required vars header too deep in file"
    return True, None


def check_outputs_references(path, lines):
    warns = []
    fails = []
    for idx, line in enumerate(lines, start=1):
        if "outputs/" not in line:
            continue
        if "R-scripts/" in line:
            continue
        if any(
            token in line
            for token in (
                "outputs_dir",
                "fof.outputs_dir",
                "getOption(\"fof.outputs_dir\")",
                "init_paths(",
            )
        ):
            continue
        lowered = line.lower()
        if re.search(r"\./outputs/|['\"]outputs/|here::here\([^)]*outputs|file\.path\([^)]*outputs", lowered):
            fails.append(f"{path}:{idx}: suspicious outputs/ reference: {line.strip()}")
        else:
            fails.append(
                f"{path}:{idx}: outputs/ reference not tied to outputs_dir/init_paths: {line.strip()}"
            )
    return warns, fails


def check_manifest_logging(path, lines):
    patterns = ["append_manifest(", "manifest_row(", "save_sessioninfo_manifest("]
    for line in lines:
        if any(pat in line for pat in patterns):
            return True
    return False


def is_k15_derivation_exception(path):
    base = os.path.basename(path)
    norm = path.replace("\\", "/")
    if "/R-scripts/K15/" in norm:
        return True
    return bool(re.match(r"^K15[._]", base))


def determine_requirements_source(script_path, lines):
    req_vars, req_err, req_debug = extract_required_vars(lines)
    req_cols, cols_err = extract_req_cols(lines)

    out = {
        "source": None,
        "parsed_vars": [],
        "parsed_n": 0,
        "should_fail": False,
        "hard_stop": False,
        "fail_reason": None,
        "warnings": [],
        "debug": [],
    }

    if req_cols is not None:
        out["source"] = "req_cols"
        out["parsed_vars"] = req_cols
        out["parsed_n"] = len(req_cols)
        if req_vars is not None and req_vars != req_cols:
            out["should_fail"] = True
            out["fail_reason"] = "Required vars list does not match req_cols 1:1."
    elif req_vars is not None and len(req_vars) > 0:
        out["source"] = "doc_block"
        out["parsed_vars"] = req_vars
        out["parsed_n"] = len(req_vars)
    else:
        if is_k15_derivation_exception(script_path):
            out["source"] = "warn_only"
            out["warnings"].append(
                "requirements not declared; skipped req_cols check "
                f"(reason: {cols_err or req_err})"
            )
        else:
            out["should_fail"] = True
            out["hard_stop"] = True
            out["fail_reason"] = cols_err or req_err

    if req_err and "multiple Required vars headers found" in req_err:
        out["warnings"].append(req_err)
    if cols_err and "multiple req_cols/req_raw_cols definitions found" in cols_err:
        out["warnings"].append(cols_err)
    if req_debug:
        out["debug"] = req_debug

    return out


def main():
    parser = argparse.ArgumentParser(
        description="FOF preflight guardrails (diff-aware; fail-closed).",
    )
    parser.add_argument("--verbose", action="store_true", help="Print per-file details.")
    args = parser.parse_args()

    repo_root, diff_files = run_git_diff()
    if diff_files is None:
        sys.exit(1)

    fails = []
    warns = []

    data_touches = [f for f in diff_files if f.startswith(DATA_BLOCKLIST_PREFIXES)]
    if data_touches:
        fails.append(
            "Raw data paths changed (blocked):\n" + "\n".join(f" - {p}" for p in data_touches)
        )

    r_files = [
        f
        for f in diff_files
        if f.endswith(".R") and any(f.startswith(prefix) for prefix in R_SCRIPT_PREFIXES)
    ]
    for r_path in r_files:
        abs_path = os.path.join(repo_root, r_path)
        lines = read_lines(abs_path)
        if isinstance(lines, tuple):
            lines, err = lines
        if lines is None:
            fails.append(f"{r_path}: {err}")
            continue

        ok, intro_err = check_standard_intro(r_path, lines)
        if not ok:
            fails.append(intro_err)
            continue

        req_decision = determine_requirements_source(r_path, lines)
        print(
            f"INFO: {r_path}: requirements source: {req_decision['source']}; "
            f"parsed_n={req_decision['parsed_n']}"
        )
        for msg in req_decision["warnings"]:
            warns.append(f"{r_path}: {msg}")
        if req_decision["should_fail"]:
            fails.append(f"{r_path}: {req_decision['fail_reason']}")
        if req_decision["hard_stop"]:
            continue

        file_warns, file_fails = check_outputs_references(r_path, lines)
        warns.extend(file_warns)
        fails.extend(file_fails)

        if not check_manifest_logging(r_path, lines):
            warns.append(f"{r_path}: no manifest logging hints found")

        if args.verbose:
            print(f"Checked {r_path}")

    status = "PASS"
    if fails:
        status = "FAIL"
    elif warns:
        status = "WARN"

    print(f"Preflight status: {status}")
    if warns:
        print("Warnings:")
        for msg in warns:
            print(f" - {msg}")
    if fails:
        print("Failures:")
        for msg in fails:
            print(f" - {msg}")

    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
