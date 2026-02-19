#!/usr/bin/env python3
"""Build AIM2 cohort flowchart outputs with fail-fast count validation."""

from __future__ import annotations

import shutil
import subprocess
import sys
from pathlib import Path

COUNTS = {
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


def validate_counts() -> None:
    n1, ex1, n3 = COUNTS["n1"], COUNTS["ex1"], COUNTS["n3"]
    ex2, n5, g1, g2 = COUNTS["ex2"], COUNTS["n5"], COUNTS["g1"], COUNTS["g2"]

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


def render_dot(template_text: str) -> str:
    replacements = {
        "__AGE65_RAW__": str(COUNTS["age65_raw"]),
        "__N1__": str(COUNTS["n1"]),
        "__EX1__": str(COUNTS["ex1"]),
        "__N3__": str(COUNTS["n3"]),
        "__EX2__": str(COUNTS["ex2"]),
        "__N5__": str(COUNTS["n5"]),
        "__G1__": str(COUNTS["g1"]),
        "__G2__": str(COUNTS["g2"]),
        "__EX1_PCT__": pct(COUNTS["ex1"], COUNTS["n1"]),
        "__N3_PCT__": pct(COUNTS["n3"], COUNTS["n1"]),
        "__EX2_PCT__": pct(COUNTS["ex2"], COUNTS["n3"]),
        "__N5_PCT__": pct(COUNTS["n5"], COUNTS["n3"]),
        "__G1_PCT__": pct(COUNTS["g1"], COUNTS["n5"]),
        "__G2_PCT__": pct(COUNTS["g2"], COUNTS["n5"]),
    }

    rendered = template_text
    for token, value in replacements.items():
        rendered = rendered.replace(token, value)
    return rendered


def main() -> int:
    project_root = Path(__file__).resolve().parent.parent
    dot_template = project_root / "diagram" / "aim2_cohort_flow.dot"
    out_dir = project_root / "outputs" / "flowchart"
    out_dot = out_dir / "aim2_cohort_flow.rendered.dot"

    if shutil.which("dot") is None:
        print("Graphviz 'dot' was not found on PATH.", file=sys.stderr)
        return 2

    try:
        validate_counts()
    except ValueError as exc:
        print(str(exc), file=sys.stderr)
        return 2

    template_text = dot_template.read_text(encoding="utf-8")
    rendered = render_dot(template_text)

    if "__" in rendered:
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
        cmd = ["dot", f"-T{fmt}", *extra_args, str(out_dot), "-o", str(outfile)]
        subprocess.run(cmd, check=True)

    print("Built flowchart artifacts:")
    for _, outfile, _ in targets:
        print(f"- {outfile.relative_to(project_root).as_posix()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
