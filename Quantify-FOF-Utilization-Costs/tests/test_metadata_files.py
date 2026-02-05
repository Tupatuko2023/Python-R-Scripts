import csv
import unittest
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    PROJECT_ROOT / "data" / "data_dictionary.csv",
    PROJECT_ROOT / "data" / "VARIABLE_STANDARDIZATION.csv",
    PROJECT_ROOT / "manifest" / "dataset_manifest.csv",
    PROJECT_ROOT / "manifest" / "run_log.csv",
]

EXPECTED_HEADERS = {
    "data_dictionary.csv": ["dataset", "variable", "label", "type", "unit", "coding", "required", "notes"],
    "VARIABLE_STANDARDIZATION.csv": [
        "source_dataset",
        "original_variable",
        "standard_variable",
        "transform_rule",
        "unit",
        "coding",
        "notes",
    ],
    "dataset_manifest.csv": [
        "logical_name",
        "relative_path",
        "file_glob",
        "description",
        "sensitivity",
        "header_row",
    ],
    "run_log.csv": [
        "timestamp",
        "actor",
        "script",
        "status",
        "message",
    ],
}


class TestMetadataFiles(unittest.TestCase):
    def test_files_exist(self) -> None:
        for p in REQUIRED_FILES:
            self.assertTrue(p.exists(), f"Missing required file: {p}")

    def test_headers_match(self) -> None:
        for p in REQUIRED_FILES:
            with p.open("r", encoding="utf-8", newline="") as f:
                reader = csv.reader(f)
                header = next(reader)
            if p.name == "data_dictionary.csv":
                # Accept legacy header or expanded schema with provenance/redaction/standardization columns.
                legacy = EXPECTED_HEADERS[p.name]
                required_new = [
                    "source_dataset",
                    "source_dataset_redacted",
                    "source_name_redaction_reason",
                    "identifier_like_filename",
                    "source_file_sha256_prefix1mb",
                    "variable",
                    "dtype",
                    "units",
                    "coding",
                    "notes",
                    "variable_en",
                    "standard_name_en",
                    "description_en",
                ]
                if header == legacy:
                    continue
                missing = [c for c in required_new if c not in header]
                self.assertEqual(missing, [], f"Header mismatch for {p.name}; missing: {missing}")
                continue
            if p.name == "VARIABLE_STANDARDIZATION.csv":
                # Accept legacy or expanded standardization schema.
                legacy = EXPECTED_HEADERS[p.name]
                required_new = [
                    "source_dataset",
                    "variable_original",
                    "variable_en",
                    "standard_name_en",
                    "role_guess",
                    "dtype_example",
                    "description_en",
                    "notes",
                ]
                if header == legacy:
                    continue
                missing = [c for c in required_new if c not in header]
                self.assertEqual(missing, [], f"Header mismatch for {p.name}; missing: {missing}")
                continue
            self.assertEqual(header, EXPECTED_HEADERS[p.name], f"Header mismatch for {p.name}")

    def test_no_case_duplicate_data_readme(self) -> None:
        data_dir = PROJECT_ROOT / "data"
        self.assertTrue((data_dir / "readme.md").exists(), "Canonical data/readme.md missing")
        self.assertFalse((data_dir / "README.md").exists(), "Duplicate data/README.md must not exist")


if __name__ == "__main__":
    unittest.main()
