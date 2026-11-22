import json
from pathlib import Path
import sys
import tempfile
import unittest

TOOLS_DIR = Path(__file__).resolve().parents[1]
if str(TOOLS_DIR) not in sys.path:
    sys.path.insert(0, str(TOOLS_DIR))

import synth_file_search_fixture as fixture  # noqa: E402


class SynthFileSearchFixtureTests(unittest.TestCase):
    def test_materialize_is_deterministic_and_writes_cli_settings(self) -> None:
        with tempfile.TemporaryDirectory() as tmp1, tempfile.TemporaryDirectory() as tmp2:
            b1 = Path(tmp1)
            b2 = Path(tmp2)
            k1 = fixture.materialize(b1 / "ws", b1 / "eval")
            k2 = fixture.materialize(b2 / "ws", b2 / "eval")
            self.assertEqual(k1["workspace_files_sha256"], k2["workspace_files_sha256"])
            self.assertEqual(k1["prompt_sha256"], k2["prompt_sha256"])
            self.assertFalse((b1 / "ws" / "expected_answer_key.json").exists())
            self.assertTrue((b1 / "eval" / "expected_answer_key.json").is_file())
            settings = json.loads((b1 / "eval" / "cli_settings.json").read_text("utf-8"))
            self.assertIn("command(*)", settings["permissions"]["deny"])
            self.assertIn(
                "mcp(filesystem/directory_tree)", settings["permissions"]["allow"]
            )

    def test_overlapping_workspace_and_eval_dirs_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            with self.assertRaises(ValueError):
                fixture.materialize(base / "ws", base / "ws" / "eval")
            with self.assertRaises(ValueError):
                fixture.materialize(base / "ws", base / "ws")

    def test_workspace_inside_repo_rejected_by_default(self) -> None:
        inside = fixture.REPO_ROOT / "tools" / "antigravity_harness" / "outputs" / "_bad_ws"
        with tempfile.TemporaryDirectory() as tmp_eval:
            with self.assertRaises(ValueError):
                fixture.materialize(inside, Path(tmp_eval) / "eval")

    def test_evaluate_passes_valid_filesystem_mcp_and_read_file_trace(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            ws = base / "ws"
            ev = base / "eval"
            fixture.materialize(ws, ev)

            response = (
                "1. Käsikirjoitus: `manuscripts/SYNTH_COHORT_REVIEW_20261120.qmd` rivi 17.\n"
                "2. Päälähde: `runs/20261119_model_s2_primary/model_estimates.tsv` rivi 4 "
                "(`1.4204`, `1.1102`, `1.8173`, `0.0052`), manifesti "
                "`runs/20261119_model_s2_primary/run_manifest.json`.\n"
                "3. Hylätyt: `runs/20261118_model_s2_prelim/model_estimates.tsv`.\n"
                "4. Siirtotapa QMD-taulukkoon jää avoimeksi (ei voida todentaa onko käsin vai ulkoisella skriptillä).\n"
            )
            events = [
                {
                    "event": "init",
                    "conversation_id": "conv-synth-pass",
                    "init": {"model": "gemini-4-carbon-medium", "cwd": str(ws)},
                },
                {
                    "event": "step_update",
                    "step_update": {
                        "step_index": 1,
                        "state": "DONE",
                        "step_type": "tool",
                        "tool_name": "read_file",
                        "duration_seconds": 0.01,
                        "tool_info": {
                            "name": "read_file",
                            "parameters": {
                                "Path": "/home/user/.gemini/antigravity-cli/mcp/filesystem/directory_tree.json"
                            },
                        },
                    },
                },
                {
                    "event": "step_update",
                    "step_update": {
                        "step_index": 2,
                        "state": "DONE",
                        "step_type": "tool",
                        "tool_name": "call_mcp_tool",
                        "duration_seconds": 0.02,
                        "tool_info": {
                            "name": "call_mcp_tool",
                            "parameters": {
                                "ServerName": "filesystem",
                                "ToolName": "directory_tree",
                                "Arguments": {"path": str(ws)},
                            },
                        },
                    },
                },
                {
                    "event": "step_update",
                    "step_update": {
                        "step_index": 3,
                        "state": "DONE",
                        "step_type": "tool",
                        "tool_name": "read_file",
                        "duration_seconds": 0.02,
                        "tool_info": {
                            "name": "read_file",
                            "parameters": {
                                "Path": str(
                                    ws / "runs/20261119_model_s2_primary/model_estimates.tsv"
                                )
                            },
                        },
                    },
                },
                {
                    "event": "result",
                    "result": {
                        "conversation_id": "conv-synth-pass",
                        "status": "SUCCESS",
                        "response": response,
                        "duration_seconds": 12.3,
                        "num_turns": 1,
                        "usage": {"input_tokens": 1000, "output_tokens": 200},
                    },
                },
            ]
            stream_file = base / "run.jsonl"
            stream_file.write_text(
                "\n".join(json.dumps(e) for e in events) + "\n", encoding="utf-8"
            )
            rep = fixture.evaluate(
                ev, stream_file, base / "report.json", base / "report.md"
            )
            self.assertTrue(rep["primary_criterion_pass"])
            self.assertTrue(rep["checks"]["workspace_isolated"])
            self.assertEqual(rep["mcp_schema_reads"], ["directory_tree.json"])
            self.assertFalse(rep["checks"]["unsupported_manual_copy_claim"])

    def test_evaluate_fails_escape_or_forbidden_tool_and_flags_manual_copy(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            ws = base / "ws"
            ev = base / "eval"
            fixture.materialize(ws, ev)

            bad_response = (
                "Lähde on `runs/20261118_model_s2_prelim/model_estimates.tsv` ja "
                "luvut on käsin kopioitu taulukkoon."
            )
            events = [
                {
                    "event": "init",
                    "conversation_id": "conv-synth-fail",
                    "init": {"model": "gemini-4-carbon-medium", "cwd": str(ws)},
                },
                {
                    "event": "step_update",
                    "step_update": {
                        "step_index": 1,
                        "state": "DONE",
                        "step_type": "tool",
                        "tool_name": "run_command",
                        "tool_info": {"parameters": {"CommandLine": "ls"}},
                    },
                },
                {
                    "event": "step_update",
                    "step_update": {
                        "step_index": 2,
                        "state": "DONE",
                        "step_type": "tool",
                        "tool_name": "read_file",
                        "tool_info": {
                            "parameters": {"Path": str(ev / "expected_answer_key.json")}
                        },
                    },
                },
                {
                    "event": "result",
                    "result": {
                        "conversation_id": "conv-synth-fail",
                        "status": "SUCCESS",
                        "response": bad_response,
                        "duration_seconds": 5.0,
                        "num_turns": 1,
                        "usage": {},
                    },
                },
            ]
            stream_file = base / "bad.jsonl"
            stream_file.write_text(
                "\n".join(json.dumps(e) for e in events) + "\n", encoding="utf-8"
            )
            rep = fixture.evaluate(
                ev, stream_file, base / "bad_report.json", base / "bad_report.md"
            )
            self.assertFalse(rep["primary_criterion_pass"])
            self.assertFalse(rep["checks"]["workspace_isolated"])
            self.assertIn("run_command", rep["forbidden_tools_used"])
            self.assertTrue(rep["checks"]["wrong_distractor_as_primary"])
            self.assertTrue(rep["checks"]["unsupported_manual_copy_claim"])


if __name__ == "__main__":
    unittest.main()
