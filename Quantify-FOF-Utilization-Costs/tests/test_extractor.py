import importlib.util
import json
import sys
import tempfile
import unittest
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
SCRIPT = PROJECT_ROOT / "scripts" / "20_extract_pdf_pptx.py"
sys.path.insert(0, str(PROJECT_ROOT / "scripts"))

spec = importlib.util.spec_from_file_location("extractor", SCRIPT)
extractor = importlib.util.module_from_spec(spec)
assert spec and spec.loader
sys.modules["extractor"] = extractor
spec.loader.exec_module(extractor)


class TestExtractorHelpers(unittest.TestCase):
    def test_table_to_markdown_basic(self):
        md = extractor.table_to_markdown([["a", "b"], ["1", "2"]])
        self.assertIn("| a | b |", md)
        self.assertIn("| --- | --- |", md)
        self.assertIn("| 1 | 2 |", md)

    def test_write_jsonl_roundtrip(self):
        with tempfile.TemporaryDirectory() as td:
            out = Path(td) / "chunks.jsonl"
            chunks = [
                extractor.Chunk(source_file="x.pdf", page=1, chunk_type="text", content_md="hello", created_at="t"),
                extractor.Chunk(source_file="x.pdf", page=1, chunk_type="table", content_md="|a|", created_at="t"),
            ]
            extractor.write_jsonl(out, chunks)
            lines = out.read_text(encoding="utf-8").splitlines()
            self.assertEqual(len(lines), 2)
            obj = json.loads(lines[0])
            self.assertEqual(obj["chunk_type"], "text")

    def test_safety_check_blocks_id_token(self):
        with self.assertRaises(SystemExit):
            extractor._safety_check_no_identifier("this has id, inside")


if __name__ == "__main__":
    unittest.main()
