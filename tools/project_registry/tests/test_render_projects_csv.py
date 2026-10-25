#!/usr/bin/env python3
"""Tests for the project registry CSV generator and its pre-write guard.

T1 source preservation, T2 single-project scope, T3 missing/ambiguous data,
T4 working-tree user edit, T5 stale observation, T6 idempotent rerun,
T7 done is not cleanup, T9 source round-trip, T10 new export fields,
T11 header semantics, T12 unknown worktree inventory, plus absolute-path,
output-gate and CSV-shape checks.
"""

import contextlib
import importlib.util
import io
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

MODULE_PATH = Path(__file__).resolve().parents[1] / "render_projects_csv.py"
_spec = importlib.util.spec_from_file_location("render_projects_csv", MODULE_PATH)
registry = importlib.util.module_from_spec(_spec)
sys.modules[_spec.name] = registry
_spec.loader.exec_module(registry)

SOURCE_TEXT = """[V1]
Tavoitteena on, että agentti ylläpitää yhden projektin jatkamiseen
tarvittavia tietoja työn aikana.

[V2]
Toinen kappale, jossa on pilkku, lainaus "näin" ja risuaita # mukana.
"""


def parse_csv(payload):
    text = payload.decode("utf-8") if isinstance(payload, bytes) else payload
    return list(registry.csv.reader(io.StringIO(text, newline="")))


def project_text(**overrides):
    values = {
        "id": "PRJ-TEST",
        "title": "Testiprojekti",
        "short_name": "Testi",
        "repo": "FOF-Dissertation-Project",
        "repo_ref": "origin/main",
        "worktree_inventory": "unknown",
        "state": "active",
        "delivery": "not_delivered",
        "goal": "Testata generaattoria.",
        "done_criterion": "CSV muodostuu ja testit menevät läpi.",
        "latest_status": "2026-10-24: testit ajettu.",
        "next_step": "Owner: päätä toimituksesta.",
        "blocker": "",
        "orchestrator": "DCOA1",
        "agent": "agent-researcher",
        "agent_tool": "opencode-agent",
        "environment": "windows",
        "started_date": "2026-10-24",
        "paused_date": "",
        "completed_date": "",
        "pause_reason": "",
        "link": "tasks/03-review/PRJ-TEST.md",
        "source_description_sha256": "",
        "source_captured_at": "2026-10-24",
        "observed_at": "2026-10-24",
        "observed_commit": "7c5b144d",
        "observed_worktree_label": "pilot-impl",
    }
    values.update(overrides)
    worktrees = values.pop("_worktrees", [("impl", "active", "local")])
    block = (
        "<!-- source-description:begin -->\n"
        + SOURCE_TEXT
        + "<!-- source-description:end -->\n"
    )
    digest = registry.hashlib.sha256(SOURCE_TEXT.encode("utf-8")).hexdigest()
    if values.get("source_description_sha256") == "":
        values["source_description_sha256"] = digest
    lines = ["---"]
    for key, value in values.items():
        lines.append(f'{key}: "{value}"')
    lines.append("tasks:")
    lines.append('  - "TASK-TEST-001"')
    lines.append("---")
    lines.append("")
    lines.append("# Projekti")
    lines.append("")
    lines.append("## Lähdekuvaus")
    lines.append("")
    lines.append(block)
    lines.append("## Worktree-havainnot")
    lines.append("")
    lines.append("| label | state | evidence |")
    lines.append("|---|---|---|")
    for row in worktrees:
        lines.append(f"| {row[0]} | {row[1]} | {row[2]} |")
    lines.append("")
    return "\n".join(lines)


class RegistryCase(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.root = Path(self._tmp.name)
        self.registry_dir = self.root / "registry"
        self.registry_dir.mkdir()
        self.output = self.root / "out" / "projects.csv"

    def tearDown(self):
        self._tmp.cleanup()

    def write(self, name, text):
        path = self.registry_dir / name
        path.write_text(text, encoding="utf-8", newline="")
        return path

    def render(self, *extra):
        return registry.main([
            "--registry", str(self.registry_dir),
            "--output", str(self.output),
            "--skip-ignore-check",
            *extra,
        ])

    def rows(self):
        return parse_csv(self.output.read_bytes())


class RenderTests(RegistryCase):
    def test_t6_render_is_idempotent_and_has_one_data_row(self):
        self.write("PRJ-TEST.md", project_text())
        self.assertEqual(self.render(), 0)
        first = self.output.read_bytes()
        self.assertEqual(self.render(), 0)
        self.assertEqual(first, self.output.read_bytes())

        rows = self.rows()
        self.assertEqual(len(rows), 2)
        self.assertEqual(rows[0], registry.HEADER)
        self.assertEqual(len(rows[1]), 20)
        self.assertEqual(rows[1][0], "PRJ-TEST")
        self.assertEqual(rows[1][10], "TEST")

    def test_t9_source_description_round_trips_in_projekti_column(self):
        self.write("PRJ-TEST.md", project_text())
        self.assertEqual(self.render(), 0)
        row = self.rows()[1]
        self.assertEqual(row[1], SOURCE_TEXT)
        self.assertIn("\n", row[1])
        self.assertEqual(row[2], "Testi")
        self.assertNotEqual(row[1], "Testiprojekti")

    def test_t10_next_step_blocker_and_delivery_are_exported(self):
        self.write("PRJ-TEST.md", project_text(
            next_step="Aja review ja päätä toimituksesta.",
            blocker="BLK-999 odottaa Owner-päätöstä",
            delivery="not_delivered",
        ))
        self.assertEqual(self.render(), 0)
        row = self.rows()[1]
        self.assertEqual(row[6], "Aja review ja päätä toimituksesta.")
        self.assertEqual(row[7], "BLK-999 odottaa Owner-päätöstä")
        self.assertEqual(row[8], "not_delivered")

    def test_missing_next_step_and_blocker_are_explicit(self):
        self.write("PRJ-TEST.md", project_text(next_step="", blocker=""))
        self.assertEqual(self.render(), 1)  # next_step is required
        self.write("PRJ-TEST.md", project_text(blocker=""))
        self.assertEqual(self.render(), 0)
        self.assertEqual(self.rows()[1][7], "none_recorded")

    def test_t11_header_semantics_match_the_value_vocabulary(self):
        self.assertIn("Worktree-siivous", registry.HEADER)
        self.assertNotIn("worktrees_purettu_kun valmis", " ".join(registry.HEADER))
        self.assertFalse(any("0=ei" in column for column in registry.HEADER))
        for column in ("Seuraava toimenpide", "Este", "Toimituksen tila"):
            self.assertIn(column, registry.HEADER)

    def test_t12_empty_or_unknown_inventory_never_claims_cleanup(self):
        cases = [
            ([], "unknown", "unknown"),
            ([("a", "removed", "e")], "unknown", "unknown"),
            ([("a", "removed", "e")], "complete", "removed"),
            ([("a", "removed", "e"), ("b", "active", "e")], "complete", "retained"),
            ([("a", "removed", "e"), ("b", "unknown", "e")], "complete", "unknown"),
        ]
        for rows, inventory, expected in cases:
            with self.subTest(rows=rows, inventory=inventory):
                cell = registry.worktree_cell(rows, inventory)
                self.assertEqual(cell, expected)
                self.assertNotIn(cell, {"0", "1"})

    def test_delivery_and_completion_do_not_imply_cleanup(self):
        self.write("PRJ-TEST.md", project_text(
            delivery="delivered", state="closed",
            completed_date="2026-10-24",
            _worktrees=[("impl", "active", "still here")],
        ))
        self.assertEqual(self.render(), 0)
        self.assertEqual(self.rows()[1][9], "retained")

    def test_t2_render_does_not_write_registry_sources(self):
        first = self.write("PRJ-TEST.md", project_text())
        before = first.read_bytes()
        self.assertEqual(self.render(), 0)
        self.assertEqual(before, first.read_bytes())
        self.assertEqual(os.listdir(self.registry_dir), ["PRJ-TEST.md"])

    def test_t1_source_block_hash_binds_the_stored_text(self):
        text = project_text()
        self.write("PRJ-TEST.md", text)
        self.assertEqual(self.render(), 0)

        tampered = text.replace("tarvittavia tietoja", "tarvittavia tietoja ")
        self.write("PRJ-TEST.md", tampered)
        self.assertEqual(self.render(), 1)

    def test_csv_quoting_round_trips_commas_quotes_and_hashes(self):
        status = 'Tila: a, b "c" # d'
        self.write("PRJ-TEST.md", project_text(latest_status=status))
        self.assertEqual(self.render(), 0)
        row = self.rows()[1]
        self.assertEqual(len(row), 20)
        self.assertEqual(row[5], status)


class ValidationTests(RegistryCase):
    def test_duplicate_frontmatter_keys_preserve_output(self):
        cases = [
            ('state', 'state: "active"\n'),
            ('state', 'state: "closed"\n'),
            ('tasks', 'tasks:\n  - "TASK-TEST-001"\n'),
            ('tasks', 'tasks:\n  - "TASK-OTHER"\n'),
            ('tasks', 'tasks: "scalar replacement"\n'),
            ('state', 'state:\n  - "active"\n'),
        ]
        for key, duplicate in cases:
            for existing_output in (False, True):
                with self.subTest(key=key, duplicate=duplicate,
                                  existing_output=existing_output):
                    text = project_text()
                    if existing_output:
                        self.write("PRJ-TEST.md", text)
                        self.assertEqual(self.render(), 0)
                        before = self.output.read_bytes()
                    elif self.output.exists():
                        self.output.unlink()
                    invalid = text.replace("\n---\n", "\n" + duplicate + "---\n", 1)
                    self.write("PRJ-TEST.md", invalid)
                    error = io.StringIO()
                    with contextlib.redirect_stderr(error):
                        self.assertEqual(self.render(), 1)
                    message = error.getvalue()
                    self.assertIn("PRJ-TEST.md", message)
                    self.assertIn(f"duplicate key {key!r}", message)
                    self.assertIn("frontmatter line", message)
                    if existing_output:
                        self.assertEqual(self.output.read_bytes(), before)
                    else:
                        self.assertFalse(self.output.exists())

    def test_t3_missing_required_key_fails_closed(self):
        text = project_text().replace('next_step: "Owner: päätä toimituksesta."\n', "")
        self.write("PRJ-TEST.md", text)
        self.assertEqual(self.render(), 1)
        self.assertFalse(self.output.exists())

    def test_t3_ambiguous_identity_fails_closed(self):
        self.write("PRJ-OTHER.md", project_text())
        self.assertEqual(self.render(), 1)
        self.assertFalse(self.output.exists())

    def test_t3_invalid_id_and_state_fail_closed(self):
        self.write("PRJ-TEST.md", project_text(state="odottaa"))
        self.assertEqual(self.render(), 1)
        self.write("PRJ-TEST.md", project_text(id="project-1"))
        self.assertEqual(self.render(), 1)

    def test_repo_ref_must_not_carry_an_observation_commit(self):
        self.write("PRJ-TEST.md", project_text(repo_ref="origin/main@c31d4e22"))
        self.assertEqual(self.render(), 1)
        self.write("PRJ-TEST.md", project_text(repo_ref="origin/main"))
        self.assertEqual(self.render(), 0)

    def test_inventory_vocabulary_is_enforced(self):
        self.write("PRJ-TEST.md", project_text(worktree_inventory="osittainen"))
        self.assertEqual(self.render(), 1)

    def test_absolute_paths_are_rejected(self):
        for value in ("C:/GitWork/repo", "/home/user/repo", "~/repo", "\\\\host\\share"):
            with self.subTest(value=value):
                self.write("PRJ-TEST.md", project_text(link=value))
                self.assertEqual(self.render(), 1)

    def test_unknown_worktree_state_is_rejected(self):
        self.write("PRJ-TEST.md", project_text(_worktrees=[("impl", "purettu", "e")]))
        self.assertEqual(self.render(), 1)

    def test_check_mode_writes_nothing(self):
        self.write("PRJ-TEST.md", project_text())
        self.assertEqual(self.render("--check"), 2)
        self.assertFalse(self.output.exists())
        self.assertEqual(self.render(), 0)
        before = self.output.read_bytes()
        self.assertEqual(self.render("--check"), 0)
        self.assertEqual(before, self.output.read_bytes())


class GitGateTests(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.root = Path(self._tmp.name)
        self.registry_dir = self.root / "registry"
        self.registry_dir.mkdir()
        self.project = self.registry_dir / "PRJ-TEST.md"
        self.project.write_text(project_text(), encoding="utf-8", newline="")

    def tearDown(self):
        self._tmp.cleanup()

    def git(self, *args):
        return subprocess.run(
            ["git", *args], cwd=self.root, capture_output=True, text=True
        )

    def commit(self, message):
        self.git("add", "-A")
        self.assertEqual(self.git("commit", "-m", message).returncode, 0)
        return self.git("rev-parse", "HEAD").stdout.strip()

    def init_repo(self):
        self.assertEqual(self.git("init", "-q", ".").returncode, 0)
        self.git("config", "user.email", "test@example.invalid")
        self.git("config", "user.name", "Test")
        return self.commit("initial")

    def test_t4_working_tree_edit_is_reported(self):
        base = self.init_repo()
        with contextlib.chdir(self.root):
            self.assertEqual(
                registry.verify_guard("registry/PRJ-TEST.md", base)[0], 0)

            self.project.write_text(
                project_text(latest_status="muokattu"), encoding="utf-8", newline="")
            code, messages = registry.verify_guard("registry/PRJ-TEST.md", base)
            self.assertEqual(code, 1)
            self.assertIn("WORKING_TREE_CHANGED", "\n".join(messages))

    def test_t5_stale_observation_is_reported(self):
        first = self.init_repo()
        self.project.write_text(
            project_text(latest_status="toinen"), encoding="utf-8", newline="")
        self.commit("second")
        with contextlib.chdir(self.root):
            code, messages = registry.verify_guard("registry/PRJ-TEST.md", first)
            self.assertEqual(code, 2)
            self.assertIn("STALE_COPY", "\n".join(messages))

    def test_index_divergence_is_reported(self):
        self.init_repo()
        self.project.write_text(
            project_text(latest_status="staged"), encoding="utf-8", newline="")
        self.git("add", "-A")
        with contextlib.chdir(self.root):
            code, messages = registry.verify_guard("registry/PRJ-TEST.md", None)
            self.assertEqual(code, 1)
            self.assertIn("INDEX_DIVERGES_FROM_HEAD", "\n".join(messages))

    def test_output_must_be_git_ignored(self):
        self.init_repo()
        self.registry_dir.joinpath("PRJ-TEST.md").write_text(
            project_text(), encoding="utf-8", newline="")
        output = self.root / "tracked.csv"
        with contextlib.chdir(self.root):
            code = registry.main([
                "--registry", str(self.registry_dir),
                "--output", str(output),
            ])
        self.assertEqual(code, 1)
        self.assertFalse(output.exists())


if __name__ == "__main__":
    unittest.main()
