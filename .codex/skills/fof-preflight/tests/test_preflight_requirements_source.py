#!/usr/bin/env python3
import importlib.util
import tempfile
from pathlib import Path


def load_preflight_module():
    script_path = Path(__file__).resolve().parents[1] / "scripts" / "preflight.py"
    spec = importlib.util.spec_from_file_location("fof_preflight", script_path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


def write_r(tmpdir, rel_path, text):
    path = Path(tmpdir) / rel_path
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")
    return path


def main():
    pf = load_preflight_module()

    with tempfile.TemporaryDirectory() as td:
        a_path = write_r(
            td,
            "R-scripts/K11/K11.reqcols.R",
            """# Required vars (doc)
# id, age
req_cols <- c("id", "age")
""",
        )
        a = pf.determine_requirements_source(str(a_path), a_path.read_text(encoding="utf-8").splitlines())
        assert a["source"] == "req_cols", a
        assert a["parsed_n"] == 2, a
        assert a["should_fail"] is False, a

        b_path = write_r(
            td,
            "R-scripts/K15/K15.3.docblock.R",
            """# Required vars (analysis)
# id, age, FOF_status
# Composite_Z0
print("x")
""",
        )
        b = pf.determine_requirements_source(str(b_path), b_path.read_text(encoding="utf-8").splitlines())
        assert b["source"] == "doc_block", b
        assert b["parsed_n"] > 0, b
        assert b["should_fail"] is False, b

        c_path = write_r(
            td,
            "R-scripts/K15/K15.9.warnonly.R",
            """print("no req metadata here")""",
        )
        c = pf.determine_requirements_source(str(c_path), c_path.read_text(encoding="utf-8").splitlines())
        assert c["source"] == "warn_only", c
        assert c["should_fail"] is False, c
        assert any("skipped req_cols check" in w for w in c["warnings"]), c

        d_path = write_r(
            td,
            "R-scripts/K14/K14.1.strict.R",
            """print("no req metadata here")""",
        )
        d = pf.determine_requirements_source(str(d_path), d_path.read_text(encoding="utf-8").splitlines())
        assert d["should_fail"] is True, d
        assert d["hard_stop"] is True, d

    print("OK: preflight requirements source regression tests passed")


if __name__ == "__main__":
    main()
