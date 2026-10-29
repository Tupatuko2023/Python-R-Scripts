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
from unittest import mock
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


class SafePublicationTests(RegistryCase):
    def setUp(self):
        super().setUp()
        self.source = self.write("PRJ-TEST.md", project_text())
        self.source_bytes = self.source.read_bytes()
        self.output.parent.mkdir()

    def link(self, target, link, directory=False):
        try:
            link.symlink_to(target, target_is_directory=directory)
        except (OSError, NotImplementedError) as exc:
            self.skipTest(f"symbolic links unavailable: {exc}")

    def assert_rejected_without_source_change(self):
        error = io.StringIO()
        with contextlib.redirect_stderr(error):
            self.assertEqual(self.render(), 1)
        self.assertIn("publication failed", error.getvalue())
        self.assertEqual(self.source.read_bytes(), self.source_bytes)
        self.assertEqual(list(self.output.parent.glob(".*.tmp")), [])

    def test_hard_link_to_source_is_rejected(self):
        os.link(self.source, self.output)
        self.assert_rejected_without_source_change()
        self.assertEqual(self.output.read_bytes(), self.source_bytes)

    def test_symbolic_link_to_source_is_rejected(self):
        self.link(self.source, self.output)
        self.assert_rejected_without_source_change()
        self.assertTrue(self.output.is_symlink())

    def test_parent_symbolic_link_into_registry_is_rejected(self):
        alias = self.root / "alias"
        self.link(self.registry_dir, alias, directory=True)
        with contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(registry.main([
                "--registry", str(self.registry_dir),
                "--output", str(alias / self.source.name),
                "--skip-ignore-check",
            ]), 1)
        self.assertEqual(self.source.read_bytes(), self.source_bytes)
        self.assertEqual(sorted(p.name for p in self.registry_dir.iterdir()),
                         [self.source.name])

    def test_replace_is_same_directory_and_old_csv_survives_until_publication(self):
        self.output.write_bytes(b"old CSV\n")
        replace = registry.os.replace
        calls = []

        def checked_replace(temporary, target):
            self.assertEqual(Path(temporary).parent, self.output.parent.resolve())
            self.assertNotEqual(Path(temporary), self.output)
            self.assertEqual(self.output.read_bytes(), b"old CSV\n")
            self.assertEqual(self.source.read_bytes(), self.source_bytes)
            self.assertEqual(parse_csv(Path(temporary).read_bytes())[0], registry.HEADER)
            calls.append(Path(temporary))
            return replace(temporary, target)

        with mock.patch.object(registry.os, "replace", side_effect=checked_replace):
            self.assertEqual(self.render(), 0)
        self.assertEqual(len(calls), 1)
        self.assertFalse(calls[0].exists())
        self.assertEqual(self.rows()[1][1], SOURCE_TEXT)
        self.assertEqual(self.source.read_bytes(), self.source_bytes)

    def test_atomic_replace_does_not_modify_other_hard_link(self):
        old_alias = self.root / "old-view.csv"
        old_alias.write_bytes(b"old CSV\n")
        os.link(old_alias, self.output)
        self.assertEqual(self.render(), 0)
        self.assertEqual(old_alias.read_bytes(), b"old CSV\n")
        self.assertNotEqual(self.output.read_bytes(), old_alias.read_bytes())

    def test_write_and_replace_errors_preserve_old_csv_and_only_clean_owned_temp(self):
        factory = registry.tempfile.NamedTemporaryFile
        other = self.output.parent / ".projects.csv-other-run.tmp"
        other.write_bytes(b"another process")
        for stage in ("write", "short_write", "replace", "fsync"):
            for exists in (False, True):
                with self.subTest(stage=stage, existing_output=exists):
                    if self.output.exists():
                        self.output.unlink()
                    if exists:
                        self.output.write_bytes(b"old CSV\n")

                    def broken_file(*args, **kwargs):
                        handle = factory(*args, **kwargs)
                        write = handle.write

                        def fail_write(data):
                            count = write(data[:3])
                            if stage == "write":
                                raise OSError("injected write failure")
                            return count

                        handle.write = fail_write
                        return handle

                    if stage in {"write", "short_write"}:
                        patch = mock.patch.object(registry.tempfile, "NamedTemporaryFile",
                                                  side_effect=broken_file)
                    else:
                        patch = mock.patch.object(registry.os, stage,
                                                  side_effect=OSError(f"injected {stage} failure"))
                    with patch, contextlib.redirect_stderr(io.StringIO()):
                        self.assertEqual(self.render(), 1)
                    if exists:
                        self.assertEqual(self.output.read_bytes(), b"old CSV\n")
                    else:
                        self.assertFalse(self.output.exists())
                    self.assertEqual(self.source.read_bytes(), self.source_bytes)
                    self.assertEqual(other.read_bytes(), b"another process")
                    self.assertEqual(list(self.output.parent.glob(".*.tmp")), [other])

    def test_alias_created_during_write_is_rechecked_before_replace(self):
        factory = registry.tempfile.NamedTemporaryFile

        def linked_during_write(*args, **kwargs):
            handle = factory(*args, **kwargs)
            write = handle.write

            def link_after_write(data):
                count = write(data)
                os.link(self.source, self.output)
                return count

            handle.write = link_after_write
            return handle

        with mock.patch.object(registry.tempfile, "NamedTemporaryFile",
                               side_effect=linked_during_write):
            self.assert_rejected_without_source_change()
        self.assertEqual(self.output.read_bytes(), self.source_bytes)

    def test_one_read_per_source(self):
        with mock.patch.object(registry, "read_text", wraps=registry.read_text) as read:
            self.assertEqual(self.render(), 0)
        self.assertEqual(read.call_count, 1)

    def test_source_change_after_validation_exports_original_snapshot(self):
        load = registry.load_registry
        changed = project_text(latest_status="new metadata").replace(
            SOURCE_TEXT, "UNVALIDATED second description\n")

        def change_after_validation(registry_dir):
            projects = load(registry_dir)
            self.source.write_text(changed, encoding="utf-8", newline="")
            return projects

        with mock.patch.object(registry, "load_registry", side_effect=change_after_validation), \
                mock.patch.object(registry, "read_text", wraps=registry.read_text) as read:
            self.assertEqual(self.render(), 0)
        self.assertEqual(read.call_count, 1)
        self.assertEqual(self.rows()[1][1], SOURCE_TEXT)
        self.assertEqual(self.rows()[1][5], "2026-10-24: testit ajettu.")
        self.assertEqual(self.source.read_text(encoding="utf-8"), changed)


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

    def test_ignored_hard_link_to_tracked_source_is_rejected(self):
        self.init_repo()
        self.root.joinpath(".gitignore").write_text("out/\n", encoding="utf-8")
        output = self.root / "out" / "projects.csv"
        output.parent.mkdir()
        os.link(self.project, output)
        before = self.project.read_bytes()
        with contextlib.chdir(self.root), contextlib.redirect_stderr(io.StringIO()):
            self.assertTrue(registry.output_is_ignored(str(output)))
            self.assertEqual(registry.main([
                "--registry", str(self.registry_dir), "--output", str(output),
            ]), 1)
        self.assertEqual(self.project.read_bytes(), before)
        self.assertEqual(output.read_bytes(), before)

    def make_directory_alias(self, alias, target):
        """Use a real directory alias; this regression must never be skipped."""
        if os.name == "nt":
            quote = lambda p: "'" + str(p).replace("'", "''") + "'"
            subprocess.run([
                "powershell", "-NoProfile", "-Command",
                f"New-Item -ItemType Junction -Path {quote(alias)} "
                f"-Target {quote(target)} | Out-Null",
            ], check=True, capture_output=True)
        else:
            alias.symlink_to(target, target_is_directory=True)
    @contextlib.contextmanager
    def directory_alias(self, alias, target):
        self.make_directory_alias(alias, target)
        try:
            yield alias
        finally:
            if os.name == "nt":
                os.rmdir(alias)  # Remove this test's junction, never its target.
            else:
                alias.unlink()

    def export(self, output):
        with contextlib.chdir(self.root), contextlib.redirect_stderr(io.StringIO()):
            return registry.main([
                "--registry", str(self.registry_dir), "--output", str(output),
            ])

    def ignored_output(self):
        self.init_repo()
        self.root.joinpath(".gitignore").write_text("out/\n", encoding="utf-8")
        output = self.root / "out" / "projects.csv"
        output.parent.mkdir()
        return output

    def test_directory_alias_to_tracked_file_is_rejected_without_changing_bytes(self):
        output = self.ignored_output()
        protected = self.root / "tracked"
        protected.mkdir()
        victim = protected / "notes.md"
        victim.write_bytes(b"TRACKED CONTENT MUST SURVIVE\n")
        self.commit("track protected notes")
        before = victim.read_bytes()
        with self.directory_alias(output.parent / "alias", protected) as alias:
            self.assertEqual(self.export(alias / victim.name), 1)
        self.assertEqual(victim.read_bytes(), before)
        self.assertFalse(output.exists())
        self.assertEqual(sorted(p.name for p in protected.iterdir()), [victim.name])

    def test_directory_alias_to_nonignored_file_is_rejected(self):
        output = self.ignored_output()
        target = self.root / "ordinary"
        target.mkdir()
        victim = target / "notes.md"
        victim.write_bytes(b"not ignored, not tracked\n")
        with self.directory_alias(output.parent / "alias", target) as alias:
            self.assertEqual(self.export(alias / victim.name), 1)
        self.assertEqual(victim.read_bytes(), b"not ignored, not tracked\n")

    def test_directory_alias_to_ignored_output_matches_normal_export(self):
        output = self.ignored_output()
        self.assertEqual(self.export(output), 0)
        before = output.read_bytes()
        with self.directory_alias(self.root / "view", output.parent) as alias:
            self.assertEqual(self.export(alias / output.name), 0)
            self.assertEqual(output.read_bytes(), before)
            with contextlib.chdir(self.root):
                self.assertEqual(registry.main([
                    "--registry", str(self.registry_dir),
                    "--output", str(alias / output.name), "--check",
                ]), 0)

    def test_nested_directory_aliases_cannot_reach_tracked_file(self):
        output = self.ignored_output()
        protected = self.root / "protected"
        protected.mkdir()
        victim = protected / "keep.txt"
        victim.write_bytes(b"preserve nested target\n")
        self.commit("track nested target")
        with self.directory_alias(output.parent / "first", protected) as first:
            with self.directory_alias(output.parent / "second", first) as second:
                self.assertEqual(self.export(second / victim.name), 1)
        self.assertEqual(victim.read_bytes(), b"preserve nested target\n")

    def test_directory_alias_into_nested_repository_is_rejected(self):
        output = self.ignored_output()
        nested = output.parent / "nested"
        nested.mkdir()
        self.assertEqual(subprocess.run(["git", "init", "-q", str(nested)]).returncode, 0)
        victim = nested / "notes.md"
        victim.write_bytes(b"nested repository content\n")
        with self.directory_alias(output.parent / "alias", nested) as alias:
            self.assertEqual(self.export(alias / victim.name), 1)
        self.assertEqual(victim.read_bytes(), b"nested repository content\n")

    def test_tracking_change_during_write_is_rechecked(self):
        output = self.ignored_output()
        output.write_bytes(b"old CSV\n")
        factory = registry.tempfile.NamedTemporaryFile

        def track_after_write(*args, **kwargs):
            handle = factory(*args, **kwargs)
            write = handle.write

            def write_and_track(data):
                count = write(data)
                self.assertEqual(self.git("add", "-f", str(output)).returncode, 0)
                return count

            handle.write = write_and_track
            return handle

        with mock.patch.object(registry.tempfile, "NamedTemporaryFile",
                               side_effect=track_after_write):
            self.assertEqual(self.export(output), 1)
        self.assertEqual(output.read_bytes(), b"old CSV\n")
        self.assertEqual(list(output.parent.glob(".*.tmp")), [])

    def test_ignore_change_during_write_is_rechecked(self):
        output = self.ignored_output()
        output.write_bytes(b"old CSV\n")
        factory = registry.tempfile.NamedTemporaryFile

        def unignore_after_write(*args, **kwargs):
            handle = factory(*args, **kwargs)
            write = handle.write

            def write_and_unignore(data):
                count = write(data)
                self.root.joinpath(".gitignore").write_text("", encoding="utf-8")
                return count

            handle.write = write_and_unignore
            return handle

        with mock.patch.object(registry.tempfile, "NamedTemporaryFile",
                               side_effect=unignore_after_write):
            self.assertEqual(self.export(output), 1)
        self.assertEqual(output.read_bytes(), b"old CSV\n")
        self.assertEqual(list(output.parent.glob(".*.tmp")), [])

    def test_directory_alias_retargeted_during_write_preserves_both_targets(self):
        output = self.ignored_output()
        output.write_bytes(b"old CSV\n")
        protected = self.root / "protected"
        protected.mkdir()
        victim = protected / output.name
        victim.write_bytes(b"protected target\n")
        self.commit("track alternate target")
        factory = registry.tempfile.NamedTemporaryFile
        alias = self.root / "view"

        def retarget_after_write(*args, **kwargs):
            handle = factory(*args, **kwargs)
            write = handle.write

            def write_and_retarget(data):
                count = write(data)
                if os.name == "nt":
                    os.rmdir(alias)
                else:
                    alias.unlink()
                self.make_directory_alias(alias, protected)
                return count

            handle.write = write_and_retarget
            return handle

        with self.directory_alias(alias, output.parent):
            with mock.patch.object(registry.tempfile, "NamedTemporaryFile",
                                   side_effect=retarget_after_write):
                self.assertEqual(self.export(alias / output.name), 1)
        self.assertEqual(output.read_bytes(), b"old CSV\n")
        self.assertEqual(victim.read_bytes(), b"protected target\n")
        self.assertEqual(list(output.parent.glob(".*.tmp")), [])
        self.assertEqual(sorted(p.name for p in protected.iterdir()), [victim.name])

    def test_staged_deletion_does_not_allow_overwriting_committed_file(self):
        output = self.ignored_output()
        output.write_bytes(b"committed CSV\n")
        self.assertEqual(self.git("add", "-f", str(output)).returncode, 0)
        self.commit("track output before staged deletion")
        self.assertEqual(self.git("rm", "--cached", str(output)).returncode, 0)
        self.assertEqual(self.export(output), 1)
        self.assertEqual(output.read_bytes(), b"committed CSV\n")

    def test_unverifiable_git_state_preserves_old_output(self):
        output = self.ignored_output()
        output.write_bytes(b"old CSV\n")
        git = registry.git

        def unavailable_tracking(args, **kwargs):
            if args[0] == "ls-files":
                return 128, ""
            return git(args, **kwargs)

        with mock.patch.object(registry, "git", side_effect=unavailable_tracking):
            self.assertEqual(self.export(output), 1)
        self.assertEqual(output.read_bytes(), b"old CSV\n")
        self.assertEqual(list(output.parent.glob(".*.tmp")), [])

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
