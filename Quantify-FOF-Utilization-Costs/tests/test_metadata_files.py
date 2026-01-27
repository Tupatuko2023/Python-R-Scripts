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
        "file_glob",
        "location",
        "sha256",
        "rows",
        "cols",
        "schema_ref",
        "version",
        "updated_at",
        "last_verified_date",
        "owner",
        "permit_id",
        "sensitivity_level",
        "notes",
    ],
    "run_log.csv": [
        "run_id",
        "timestamp",
        "git_commit",
        "config_hash",
        "input_manifest_version",
        "outputs_written",
        "status",
        "notes",
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
            self.assertEqual(header, EXPECTED_HEADERS[p.name], f"Header mismatch for {p.name}")


if __name__ == "__main__":
    unittest.main()
