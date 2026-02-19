#!/usr/bin/env python3
"""Build AIM2 cohort flowchart outputs with fail-fast count validation."""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

DEFAULT_COUNTS = {
    "age65_raw": 489,  # Annotation only; not used as a filter step.
    "n1": 551,
    "ex1": 65,
    "n3": 486,
    "ex2": 45,
    "n5": 441,
    "g1": 302,
    "g2": 139,
}


def pct(part: int, whole: int) -> str:
    return f"{(100.0 * part / whole):.1f}" if whole else "0.0"


def load_counts(path: Path | None) -> dict[str, int]:
    if path is None:
        return dict(DEFAULT_COUNTS)
    data = json.loads(path.read_text(encoding="utf-8"))
    return {key: int(value) for key, value in data.items()}


def validate_counts(counts: dict[str, int]) -> None:
    n1, ex1, n3 = counts["n1"], counts["ex1"], counts["n3"]
    ex2, n5, g1, g2 = counts["ex2"], counts["n5"], counts["g1"], counts["g2"]

    errors: list[str] = []
    if n1 - ex1 != n3:
        errors.append(f"{n1} - {ex1} != {n3} (got {n1 - ex1})")
    if n3 - ex2 != n5:
        errors.append(f"{n3} - {ex2} != {n5} (got {n3 - ex2})")
    if g1 + g2 != n5:
        errors.append(f"{g1} + {g2} != {n5} (got {g1 + g2})")

    if errors:
        msg = "Count validation failed. Rendering aborted:\n- " + "\n- ".join(errors)
        raise ValueError(msg)


def render_dot(template_text: str, counts: dict[str, int]) -> str:
    replacements = {
        "__AGE65_RAW__": str(counts["age65_raw"]),
        "__N1__": str(counts["n1"]),
        "__EX1__": str(counts["ex1"]),
        "__N3__": str(counts["n3"]),
        "__EX2__": str(counts["ex2"]),
        "__N5__": str(counts["n5"]),
        "__G1__": str(counts["g1"]),
        "__G2__": str(counts["g2"]),
        "__EX1_PCT__": pct(counts["ex1"], counts["n1"]),
        "__N3_PCT__": pct(counts["n3"], counts["n1"]),
        "__EX2_PCT__": pct(counts["ex2"], counts["n3"]),
        "__N5_PCT__": pct(counts["n5"], counts["n3"]),
        "__G1_PCT__": pct(counts["g1"], counts["n5"]),
        "__G2_PCT__": pct(counts["g2"], counts["n5"]),
    }

    rendered = template_text
    for token, value in replacements.items():
        rendered = rendered.replace(token, value)
    return rendered


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--counts-json",
        type=Path,
        default=None,
        help="Optional JSON file to override count values.",
    )
    args = parser.parse_args()

    project_root = Path(__file__).resolve().parent.parent
    dot_template = project_root / "diagram" / "aim2_cohort_flow.dot"
    out_dir = project_root / "outputs" / "flowchart"
    out_dot = out_dir / "aim2_cohort_flow.rendered.dot"
    counts = load_counts(args.counts_json)

    dot_bin = shutil.which("dot")
    if not dot_bin:
        print("Graphviz 'dot' not found on PATH. Rendering aborted.", file=sys.stderr)
        return 2

    try:
        validate_counts(counts)
    except ValueError as exc:
        print(str(exc), file=sys.stderr)
        return 2

    template_text = dot_template.read_text(encoding="utf-8")
    rendered = render_dot(template_text, counts)

    # Fail-fast only on unresolved template placeholders of the form __TOKEN__.
    if re.search(r"__[A-Z0-9_]+__", rendered):
        print("Unresolved template tokens found in DOT. Rendering aborted.", file=sys.stderr)
        return 2

    out_dir.mkdir(parents=True, exist_ok=True)
    out_dot.write_text(rendered, encoding="utf-8")
    # Remove legacy filename to keep deterministic output set.
    (out_dir / "aim2_cohort_flow.png").unlink(missing_ok=True)

    targets = [
        ("svg", out_dir / "aim2_cohort_flow.svg", []),
        ("pdf", out_dir / "aim2_cohort_flow.pdf", []),
        ("png", out_dir / "aim2_cohort_flow_300dpi.png", ["-Gdpi=300"]),
    ]

    for fmt, outfile, extra_args in targets:
        cmd = [dot_bin, f"-T{fmt}", *extra_args, str(out_dot), "-o", str(outfile)]
        try:
            # Security: argv list, shell=False, fixed executable, no user-controlled args.
            subprocess.run(cmd, check=True, shell=False)  # nosec B603,B607 (audited)
        except subprocess.CalledProcessError as exc:
            joined = " ".join(cmd)
            print(f"Graphviz render failed (exit {exc.returncode}): {joined}", file=sys.stderr)
            return 2

    print("Built flowchart artifacts:")
    for _, outfile, _ in targets:
        print(f"- {outfile.relative_to(project_root).as_posix()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
