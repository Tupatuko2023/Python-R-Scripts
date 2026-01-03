#!/usr/bin/env python3
import argparse
import os
import re
import subprocess
import sys
from pathlib import Path


DATA_BLOCKLIST_PREFIXES = ("data/", "data/external/")
R_SCRIPT_PREFIXES = ("R-scripts/", "Fear-of-Falling/R-scripts/")


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


def extract_required_vars(lines):
    req_lines = []
    req_indices = [
        i
        for i, line in enumerate(lines)
        if re.search(r"Required vars", line, flags=re.IGNORECASE)
    ]
    if not req_indices:
        return None, "Required vars header not found"
    if len(req_indices) > 1:
        return None, "multiple Required vars headers found"

    start = req_indices[0] + 1
    stop_markers = re.compile(
        r"Reproducibility|Outputs \+ manifest|Workflow|Mapping example|Mapping|Note:|Analyses performed",
        re.IGNORECASE,
    )
    for line in lines[start:]:
        stripped = line.strip()
        if not stripped:
            break
        if stripped == "#":
            break
        if not stripped.startswith("#"):
            break
        if stop_markers.search(stripped):
            break
        req_lines.append(stripped.lstrip("#").strip())

    if not req_lines:
        return None, "Required vars list not found under header"

    parsed = []
    for raw in req_lines:
        line = re.sub(r"^[-*]\s*", "", raw.strip())
        if not line:
            continue
        if "," in line:
            parts = [part.strip() for part in line.split(",") if part.strip()]
            parsed.extend(parts)
        else:
            if re.search(r"\s", line):
                return None, f"Required vars line ambiguous: {raw}"
            parsed.append(line)

    if not parsed:
        return None, "Required vars list could not be parsed"
    return parsed, None


def extract_req_cols(lines):
    matches = []
    for i, line in enumerate(lines):
        if re.search(r"^\s*req_cols\s*<-", line):
            matches.append(i)
    if not matches:
        return None, "req_cols definition not found"
    if len(matches) > 1:
        return None, "multiple req_cols definitions found"

    i = matches[0]
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

        req_vars, req_err = extract_required_vars(lines)
        if req_vars is None:
            fails.append(f"{r_path}: {req_err}")
            continue

        req_cols, cols_err = extract_req_cols(lines)
        if req_cols is None:
            fails.append(f"{r_path}: {cols_err}")
            continue

        if req_vars != req_cols:
            fails.append(f"{r_path}: Required vars list does not match req_cols 1:1.")

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
