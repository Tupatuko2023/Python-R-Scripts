import json
from pathlib import Path
import sys
import tempfile
import unittest

TOOLS_DIR = Path(__file__).resolve().parents[1]
if str(TOOLS_DIR) not in sys.path:
    sys.path.insert(0, str(TOOLS_DIR))

import b_vs_bprime_comparison as comp  # noqa: E402


class BVsBprimeComparisonTests(unittest.TestCase):
    def test_prompts_differ_only_by_single_added_sentence(self) -> None:
        p_b, p_bp = comp.build_prompts()
        self.assertTrue(p_b.endswith("\n"))
        self.assertEqual(
            p_bp,
            f"{p_b[:-1]} {comp.BPRIME_ADDED_SENTENCE}\n",
        )

    def test_materialize_pair_locks_identical_files_and_rejects_overlap(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            k_doc = comp.materialize_pair(
                comp.CASE_DOCUMENTED,
                base / "c1_b",
                base / "c1_bp",
                base / "eval_c1",
            )
            self.assertEqual(
                k_doc["expected_mechanism"]["status"], "documented_script"
            )
            self.assertTrue(
                (base / "c1_b" / comp.DOC_LOG_REL).is_file()
            )
            self.assertEqual(
                (base / "c1_b" / comp.DOC_LOG_REL).read_bytes(),
                (base / "c1_bp" / comp.DOC_LOG_REL).read_bytes(),
            )
            self.assertFalse((base / "c1_b" / "expected_answer_key.json").exists())

            k_open = comp.materialize_pair(
                comp.CASE_OPEN,
                base / "c2_b",
                base / "c2_bp",
                base / "eval_c2",
            )
            self.assertEqual(k_open["expected_mechanism"]["status"], "open")
            self.assertFalse((base / "c2_b" / comp.DOC_LOG_REL).exists())
            self.assertTrue((base / "c2_b" / comp.OPEN_DISTRACTOR_LOG_REL).is_file())

            with self.assertRaises(ValueError):
                comp.materialize_pair(
                    comp.CASE_OPEN,
                    base / "bad_ws",
                    base / "bad_ws",
                    base / "bad_eval",
                )

    def test_documented_case_requires_script_and_log_citation(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            comp.materialize_pair(
                comp.CASE_DOCUMENTED, base / "b", base / "bp", base / "eval"
            )
            good_resp = (
                "1. QMD `manuscripts/SYNTH_COHORT_REVIEW_20261121.qmd` rivi 17.\n"
                "2. Lähde `runs/20261120_m2_primary/model_estimates.tsv` rivi 4 "
                "(`1.3604`, `1.0803`, `1.7131`, `0.0091`), manifesti "
                "`runs/20261120_m2_primary/run_manifest.json`.\n"
                "4. Rivi tuotettiin skriptillä `scripts/render_qmd_outcome_table.py`, "
                "mikä osoitetaan lokissa `logs/m2_table_export_20261121T073000Z.txt` "
                "(ja malliskripti `scripts/fit_m2_nb_v2.R`).\n"
            )
            events = [
                {
                    "event": "init",
                    "conversation_id": "c1-pass",
                    "init": {"model": "gemini-4-carbon-medium"},
                },
                {
                    "event": "step_update",
                    "step_update": {
                        "step_index": 1,
                        "state": "DONE",
                        "step_type": "tool",
                        "tool_name": "read_file",
                        "tool_info": {
                            "parameters": {
                                "Path": str(base / "b" / comp.DOC_LOG_REL)
                            }
                        },
                    },
                },
                {
                    "event": "result",
                    "result": {
                        "conversation_id": "c1-pass",
                        "status": "SUCCESS",
                        "response": good_resp,
                        "duration_seconds": 10.0,
                        "num_turns": 1,
                        "usage": {},
                    },
                },
            ]
            sf = base / "c1.jsonl"
            sf.write_text("\n".join(json.dumps(e) for e in events) + "\n", encoding="utf-8")
            rep = comp.evaluate_run(
                base / "eval", "B", sf, base / "r.json", base / "r.md"
            )
            self.assertTrue(rep["source_search_pass"])
            self.assertTrue(rep["mechanism_pass"])
            self.assertTrue(rep["log_compliance_pass"])
            self.assertTrue(rep["combined_pass"])

    def test_open_case_passes_when_open_and_fails_unsupported_attribution(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            comp.materialize_pair(
                comp.CASE_OPEN, base / "b", base / "bp", base / "eval"
            )
            open_resp = (
                "1. QMD `manuscripts/SYNTH_COHORT_REVIEW_20261121.qmd` rivi 17.\n"
                "2. Lähde `runs/20261120_m2_primary/model_estimates.tsv` rivi 4 "
                "(`1.3604`, `1.0803`, `1.7131`, `0.0091`).\n"
                "4. Loki `logs/m1_table_export_20261119T160000Z.txt` koskee vain "
                "M1_OUTPATIENT-riviä 16, joten M2_ED_VISITS-rivin tuotantotapa ja "
                "siirto QMD-taulukkoon jää avoimeksi.\n"
            )
            bad_resp = (
                "1. QMD `manuscripts/SYNTH_COHORT_REVIEW_20261121.qmd` rivi 17.\n"
                "2. Lähde `runs/20261120_m2_primary/model_estimates.tsv` rivi 4 "
                "(`1.3604`, `1.0803`, `1.7131`, `0.0091`).\n"
                "4. Luvut on käsin kopioitu taulukkoon.\n"
            )
            for idx, (resp, expected_mech_pass) in enumerate(
                ((open_resp, True), (bad_resp, False))
            ):
                events = [
                    {
                        "event": "init",
                        "conversation_id": f"c2-{idx}",
                        "init": {"model": "gemini-4-carbon-medium"},
                    },
                    {
                        "event": "step_update",
                        "step_update": {
                            "step_index": 1,
                            "state": "DONE",
                            "step_type": "tool",
                            "tool_name": "read_file",
                            "tool_info": {
                                "parameters": {
                                    "Path": str(base / "b" / comp.TARGET_SOURCE_REL)
                                }
                            },
                        },
                    },
                    {
                        "event": "result",
                        "result": {
                            "conversation_id": f"c2-{idx}",
                            "status": "SUCCESS",
                            "response": resp,
                            "duration_seconds": 8.0,
                            "num_turns": 1,
                            "usage": {},
                        },
                    },
                ]
                sf = base / f"c2_{idx}.jsonl"
                sf.write_text(
                    "\n".join(json.dumps(e) for e in events) + "\n", encoding="utf-8"
                )
                rep = comp.evaluate_run(
                    base / "eval", "B", sf, base / f"r{idx}.json", base / f"r{idx}.md"
                )
                self.assertTrue(rep["source_search_pass"])
                self.assertEqual(rep["mechanism_pass"], expected_mech_pass)


if __name__ == "__main__":
    unittest.main()
