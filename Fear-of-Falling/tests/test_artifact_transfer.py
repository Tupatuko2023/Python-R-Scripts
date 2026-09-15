"""Phase 1 conformance harness; not a runtime exporter or sender invocation."""
import copy
import hashlib
import json
import re
import unittest
from datetime import datetime
from pathlib import Path

from jsonschema import Draft202012Validator, ValidationError

ROOT = Path(__file__).resolve().parents[1]
DOC = (ROOT / "docs/ARTIFACT_TRANSFER.md").read_text(encoding="utf-8")
SECTION = DOC.split("<!-- FOF_PROFILE_SCHEMA_BEGIN -->")[1].split(
    "<!-- FOF_PROFILE_SCHEMA_END -->")[0]
SCHEMA = json.loads(SECTION.split(chr(96) * 3 + "json")[1].split(chr(96) * 3)[0])
VALIDATOR = Draft202012Validator(SCHEMA)
PROFILE = ROOT / "config/artifact-transfer/a4-general-fi.json"
DENIED = {
    "data", "dataset", "datasets", "raw", "raw_data", "external_data",
    "participant", "participants", "participant-level", "provenance",
    ".git", ".ssh", ".aws", ".azure", "secrets", "credentials",
}
SUFFIXES = {
    ".rdata", ".rda", ".rds", ".sqlite", ".sqlite3", ".db", ".sav", ".dta",
    ".xlsx", ".xls", ".pem", ".key", ".secret", ".p12", ".pfx", ".kdbx",
    ".r", ".py", ".sh", ".ps1",
}
REF = re.compile(r"[a-zA-Z0-9][a-zA-Z0-9._-]{0,127}\Z")


def fail(message):
    raise ValueError(message)


def canonical(value):
    def check(x):
        if type(x) is str:
            if not x.isascii():
                fail("non-ASCII string")
        elif type(x) in (int, bool) or x is None:
            return
        elif type(x) is list:
            for item in x:
                check(item)
        elif type(x) is dict:
            for k, v in x.items():
                if type(k) is not str:
                    fail("non-string key")
                check(k)
                check(v)
        else:
            fail("non-JSON type or float")
    check(value)
    return json.dumps(value, sort_keys=True, separators=(",", ":"),
                      ensure_ascii=True, allow_nan=False).encode("utf-8")


def digest(value):
    return hashlib.sha256(canonical(value)).hexdigest()


def safe_path(value, staging=False):
    if type(value) is not str or not value or not value.isascii():
        fail("empty/non-ASCII path")
    if len(value) > (100 if staging else 1024):
        fail("path too long")
    parts = value.split("/")
    if staging and len(parts) != 1:
        fail("staging filename required")
    for part in parts:
        if (not part or part in (".", "..") or part != part.strip()
                or part.endswith(".") or len(part) > 255):
            fail("ambiguous component")
        if any(ord(c) < 32 or ord(c) == 127 or c in '\\:<>"|*?[]' for c in part):
            fail("unsafe character")
        if re.match(r"(?i)^(con|prn|aux|nul|com[0-9]|lpt[0-9])(?:\.|$)", part):
            fail("reserved Windows name")
    if not staging and (parts[0] != "Fear-of-Falling" or len(parts) < 2):
        fail("wrong repository scope")
    return parts


def deny(parts):
    for part in parts:
        name = part.lower()
        if (name in DENIED
                or name in {".renviron", ".netrc", ".npmrc",
                            "fi_candidate_registry.csv", "fi_changelog.md"}
                or name == ".env" or name.startswith(".env.")
                or name.startswith(("id_rsa", "id_ed25519", "id_ecdsa", "id_dsa"))
                or "secret" in name or "credential" in name
                or any(name.endswith(s) for s in SUFFIXES)):
            fail("hard deny")


def validate(profile, execute=False):
    VALIDATOR.validate(profile)
    seen_source, seen_staging = set(), set()
    for row in profile["files"]:
        if (not REF.fullmatch(row["approval_reference"])
                or not re.fullmatch(r"[0-9a-f]{64}", row["expected_sha256"])):
            fail("invalid approval/hash token")
        source = safe_path(row["source_path"])
        staging = safe_path(row["staging_path"], True)
        deny(source)
        deny(staging)
        for name, seen in [(row["source_path"], seen_source),
                           (row["staging_path"], seen_staging)]:
            if name.lower() in seen:
                fail("duplicate or case collision")
            seen.add(name.lower())
        csv = source[-1].lower().endswith(".csv") or staging[-1].lower().endswith(".csv")
        approval = row["csv_approval_reference"]
        if csv:
            if ("outputs" not in source[:-1] or type(approval) is not str
                    or not REF.fullmatch(approval)):
                fail("CSV exact output approval required")
        elif approval is not None:
            fail("non-CSV approval must be null")
    if execute and profile["state"] != "APPROVED":
        fail("EMPTY_NOT_EXECUTABLE")
    return profile


def parse(text):
    def unique(pairs):
        result = {}
        for key, value in pairs:
            if key in result:
                fail("duplicate JSON key")
            result[key] = value
        return result
    return validate(json.loads(text, object_pairs_hook=unique,
                               parse_constant=lambda _: fail("non-finite")))


def profile_digest(profile):
    p = copy.deepcopy(validate(profile))
    p["files"].sort(key=lambda r: (r["source_path"], r["staging_path"]))
    return digest(p)


def content_base(profile, rows, head):
    validate(profile, execute=True)
    if type(head) is not str or not re.fullmatch(r"([0-9a-f]{40}|[0-9a-f]{64})", head):
        fail("invalid source_head")
    if type(rows) is not list:
        fail("files must be array")
    approved = {r["source_path"]: r for r in profile["files"]}
    seen = set()
    for row in rows:
        if type(row) is not dict or set(row) != {"source_path", "staging_path", "size_bytes", "sha256"}:
            fail("invalid manifest row")
        safe_path(row["source_path"])
        safe_path(row["staging_path"], True)
        source = row["source_path"]
        if source in seen or source not in approved:
            fail("extra/duplicate member")
        seen.add(source)
        if row["staging_path"] != approved[source]["staging_path"]:
            fail("mapping drift")
        if type(row["size_bytes"]) is not int or not 0 <= row["size_bytes"] <= 1073741824:
            fail("invalid size")
        if row["sha256"] != approved[source]["expected_sha256"]:
            fail("hash drift")
    if seen != set(approved) or sum(r["size_bytes"] for r in rows) > 1073741824:
        fail("missing member or size limit")
    base = {k: profile[k] for k in ("protocol_version", "source_repository_id",
                                    "profile_id", "profile_version", "workstream")}
    base.update(source_head=head, profile_sha256=profile_digest(profile),
                files=sorted(copy.deepcopy(rows), key=lambda r: (r["source_path"], r["staging_path"])))
    return base


def manifest(profile, rows, head, run):
    if type(run) is not str or not re.fullmatch(r"[0-9]{8}T[0-9]{6}Z-[0-9a-f]{32}", run):
        fail("invalid run_id")
    datetime.strptime(run.split("-")[0], "%Y%m%dT%H%M%SZ")
    base = content_base(profile, rows, head)
    content = digest(base)
    return dict(base, run_id=run, content_digest=content, run_correlation_digest=digest({
        "protocol_version": profile["protocol_version"], "run_id": run, "content_digest": content,
    }))


def fixture(count=1):
    """Synthetic metadata only, never an inventory of real files."""
    p = json.loads(PROFILE.read_text(encoding="utf-8"))
    p.update(state="APPROVED", files=[{
        "source_path": "Fear-of-Falling/outputs/synthetic-%d.md" % i,
        "staging_path": "synthetic-%d.md" % i,
        "classification": "DISTRIBUTABLE_AS_IS",
        "approval_reference": "SYNTHETIC-ONLY",
        "csv_approval_reference": None,
        "expected_sha256": hashlib.sha256(b"abc").hexdigest(),
    } for i in range(count)])
    rows = [dict(source_path=r["source_path"], staging_path=r["staging_path"],
                 size_bytes=3, sha256=r["expected_sha256"]) for r in p["files"]]
    return p, rows


class ContractTests(unittest.TestCase):
    def setUp(self):
        self.p, self.rows = fixture()
        self.head = "1" * 40
        self.run = "20260914T120000Z-" + "a" * 32

    def bad_entry(self, changes):
        p = copy.deepcopy(self.p)
        p["files"][0].update(changes)
        with self.assertRaises((ValueError, ValidationError)):
            validate(p)

    def test_schema_and_empty_live_profile(self):
        Draft202012Validator.check_schema(SCHEMA)
        p = parse(PROFILE.read_text(encoding="utf-8"))
        self.assertEqual(p["files"], [])
        self.assertEqual(p["state"], "EMPTY_NOT_EXECUTABLE")
        with self.assertRaises(ValueError):
            validate(p, execute=True)

    def test_schema_missing_keys_types_and_state(self):
        for key in self.p:
            p = copy.deepcopy(self.p)
            del p[key]
            with self.subTest(missing=key), self.assertRaises(ValidationError):
                validate(p)
        for key, value in [("files", {}), ("files", []), ("state", "EMPTY_NOT_EXECUTABLE"),
                           ("workstream", "papers/A4_placeholder"), ("profile_version", 1),
                           ("protocol_version", "LEGACY/1"), ("source_repository_id", "other"),
                           ("classification_policy", "BYPASS")]:
            p = copy.deepcopy(self.p)
            p[key] = value
            with self.subTest(key=key), self.assertRaises(ValidationError):
                validate(p)

    def test_json_ambiguity(self):
        for text in ['{"files":[],"files":[]}', '{"x":NaN}', '{"x":Infinity}',
                     "\ufeff" + json.dumps(self.p)]:
            with self.subTest(text=text), self.assertRaises(ValueError):
                parse(text)

    def test_endpoint_and_unknown_fields_rejected(self):
        for key in ["host", "user", "port", "ssh_alias", "credentials", "source_root",
                    "windows_root", "receiver_path", "staging_root", "destination", "hard_deny"]:
            for entry in [False, True]:
                p = copy.deepcopy(self.p)
                (p["files"][0] if entry else p)[key] = "UNAUTHORIZED"
                with self.subTest(key=key, entry=entry), self.assertRaises(ValidationError):
                    validate(p)

    def test_path_adversaries(self):
        paths = ["", "/absolute", "C:/x", "C:x", "//host/share", r"..\x",
                 "../x", "Fear-of-Falling//x", "Fear-of-Falling/./x",
                 "Fear-of-Falling/../x", "Fear-of-Falling/a /x",
                 "Fear-of-Falling/a./x", "Fear-of-Falling/*.md",
                 "Fear-of-Falling/[x].md", "Fear-of-Falling/x?.md",
                 "Fear-of-Falling/x:stream", "Fear-of-Falling/CON.md",
                 "Fear-of-Falling/LPT1.txt", "Fear-of-Falling/x\n.md",
                 "Fear-of-Falling/\x7f.md", "Fear-of-Falling/\u00e4.md",
                 "Fear-of-Falling/a\u0308.md", "Other/outputs/x.md",
                 "Fear-of-Falling/" + "x" * 256]
        for path in paths:
            with self.subTest(path=path):
                self.bad_entry({"source_path": path})

    def test_staging_injection(self):
        for path in ["papers/A4_placeholder/x.md", "/x", "../x", r"C:\x",
                     "dir/x", "x" * 101, "\u00df.md"]:
            with self.subTest(path=path):
                self.bad_entry({"staging_path": path})

    def test_duplicate_source_staging_and_case(self):
        for field in ["source_path", "staging_path"]:
            for case in [False, True]:
                p, _ = fixture(2)
                name = p["files"][0][field]
                p["files"][1][field] = name.replace("synthetic", "SYNTHETIC") if case else name
                with self.subTest(field=field, case=case), self.assertRaises(ValueError):
                    validate(p)

    def test_hard_deny(self):
        names = [".env", ".env.local", ".Renviron", ".netrc", ".npmrc",
                 "id_ed25519.pub", "Credentials.md", "secret-notes.md",
                 "FI_CANDIDATE_REGISTRY.csv", "FI_CHANGELOG.md"]
        names += ["payload" + s.upper() for s in SUFFIXES]
        for name in names:
            for field in ["source_path", "staging_path"]:
                with self.subTest(name=name, field=field):
                    self.bad_entry({field: ("Fear-of-Falling/outputs/" if field == "source_path" else "") + name})
        for part in DENIED:
            with self.subTest(part=part):
                self.bad_entry({"source_path": "Fear-of-Falling/" + part.upper() + "/x.md"})

    def test_classification_and_exact_hash_required(self):
        for changes in [{"classification": "PROTECTED"}, {"classification": "DENY_UNCLASSIFIED"},
                        {"approval_reference": ""}, {"expected_sha256": "a" * 63},
                        {"approval_reference": "SYNTHETIC\n"}, {"expected_sha256": "a" * 64 + "\n"}]:
            self.bad_entry(changes)

    def test_csv_approval_and_no_renaming_bypass(self):
        p = copy.deepcopy(self.p)
        p["files"][0].update(source_path="Fear-of-Falling/outputs/synthetic.csv",
                             staging_path="synthetic.csv", csv_approval_reference="SYNTHETIC-CSV")
        validate(p)
        for changes in [{"csv_approval_reference": None}, {"csv_approval_reference": ""},
                        {"source_path": "Fear-of-Falling/reports/synthetic.csv"},
                        {"source_path": "Fear-of-Falling/outputs/*.csv"},
                        {"source_path": "Fear-of-Falling/data/outputs/synthetic.csv"},
                        {"source_path": "Fear-of-Falling/reports/synthetic.md"}]:
            q = copy.deepcopy(p)
            q["files"][0].update(changes)
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                validate(q)
        self.bad_entry({"csv_approval_reference": "SYNTHETIC-CSV"})

    def test_stable_profile_digest(self):
        p, _ = fixture(2)
        before = profile_digest(p)
        p["files"].reverse()
        p = json.loads(json.dumps(p, sort_keys=True, indent=4))
        self.assertEqual(before, profile_digest(p))
        p["files"][0]["approval_reference"] = "DIFFERENT-APPROVAL"
        self.assertNotEqual(before, profile_digest(p))

    def test_independent_serialization_vector(self):
        self.assertEqual(canonical({"z": 0, "a": [True, None, 'a"b']}),
                         b'{"a":[true,null,"a\\"b"],"z":0}')
        self.assertEqual(digest({}), "44136fa355b3678a1146ad16f7e8649e94fb4fc21fe77e8310c060f61caaff8a")
        for value in [1.0, float("nan"), {"x": float("inf")}, {1: "x"}]:
            with self.assertRaises(ValueError):
                canonical(value)

    def test_content_order_run_and_head(self):
        p, rows = fixture(2)
        a = manifest(p, rows, self.head, self.run)
        p["files"].reverse()
        b = manifest(p, list(reversed(rows)), self.head, self.run)
        self.assertEqual(a, b)
        b = manifest(p, rows, self.head, self.run[:-1] + "b")
        self.assertEqual(a["content_digest"], b["content_digest"])
        self.assertNotEqual(a["run_correlation_digest"], b["run_correlation_digest"])
        b = manifest(p, rows, "2" * 40, self.run)
        self.assertNotEqual(a["content_digest"], b["content_digest"])
        base = content_base(p, rows, self.head)
        self.assertEqual(set(base), {"protocol_version", "source_repository_id", "source_head",
                                    "profile_id", "profile_version", "profile_sha256", "workstream", "files"})
        self.assertEqual(a["content_digest"], digest(base))

    def test_manifest_row_drift_and_invalid_sizes(self):
        for changes in [{"size_bytes": True}, {"size_bytes": 3.0}, {"size_bytes": -1},
                        {"size_bytes": 1073741825}, {"sha256": "0" * 64},
                        {"staging_path": "changed.md"}, {"extra": "injection"}]:
            rows = copy.deepcopy(self.rows)
            rows[0].update(changes)
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                content_base(self.p, rows, self.head)
        for rows in [[], self.rows * 2]:
            with self.assertRaises(ValueError):
                content_base(self.p, rows, self.head)
        rows = copy.deepcopy(self.rows)
        rows[0]["source_path"] = "Fear-of-Falling/outputs/extra.md"
        with self.assertRaises(ValueError):
            content_base(self.p, rows, self.head)

    def test_invalid_run_and_head(self):
        for run in ["../x", self.run.upper(), "20260230T120000Z-" + "a" * 32]:
            with self.assertRaises(ValueError):
                manifest(self.p, self.rows, self.head, run)
        with self.assertRaises(ValueError):
            manifest(self.p, self.rows, "not-a-head", self.run)

    def test_combined_size_limit(self):
        p, rows = fixture(2)
        for row in rows:
            row["size_bytes"] = 1073741824
        with self.assertRaises(ValueError):
            content_base(p, rows, self.head)

    def test_content_changes_when_approved_bytes_change(self):
        before = manifest(self.p, self.rows, self.head, self.run)
        new_hash = hashlib.sha256(b"abcd").hexdigest()
        self.p["files"][0]["expected_sha256"] = new_hash
        self.rows[0].update(size_bytes=4, sha256=new_hash)
        after = manifest(self.p, self.rows, self.head, self.run)
        self.assertNotEqual(before["profile_sha256"], after["profile_sha256"])
        self.assertNotEqual(before["content_digest"], after["content_digest"])

    def test_a4_and_legacy_contract_boundaries(self):
        self.assertEqual(self.p["workstream"], "A4")
        self.assertNotIn("papers/", json.dumps(self.p))
        for token in ["LEGACY/1", "--allowlist", "--execute", "UNKNOWN_REMOTE_STATE",
                      "EMPTY_NOT_EXECUTABLE", "ei tuotanto-API"]:
            self.assertIn(token, DOC)
        legacy = DOC.split("## FOF_ARTIFACT_HANDOFF/2", 1)[0]
        self.assertIn("config/artifact-transfer.allowlist", legacy)


class SenderRuntimeTests(unittest.TestCase):
    """Run the real shell entrypoint in synthetic, non-repository fixtures."""
    def setUp(self):
        import tempfile
        import shutil
        import os
        self.tmp = tempfile.TemporaryDirectory(prefix="fof-v2-local-")
        self.addCleanup(self.tmp.cleanup)
        self.base = Path(self.tmp.name)
        self.root = self.base / "Fear-of-Falling"
        self.sender = self.root / "scripts/termux/export_artifacts_to_windows.sh"
        self.sender.parent.mkdir(parents=True)
        shutil.copyfile(ROOT / "scripts/termux/export_artifacts_to_windows.sh", self.sender)
        (self.root / "config").mkdir()
        (self.root / "config/artifact-transfer.allowlist").write_text("# empty\n")
        self.p, self.rows = fixture(2)
        for row in self.rows:
            path = self.base / row["source_path"]
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(b"abc")
        self.profile = self.root / "config/test-profile.json"
        self.save()
        self.bin = self.base / "bin"
        self.bin.mkdir()
        self.marker = self.base / "NETWORK_USED"
        self.env = {k: v for k, v in os.environ.items()
                    if not k.startswith(("WINDOWS_", "GIT_"))}
        self.env.update(PATH=str(self.bin) + os.pathsep + os.environ["PATH"],
                        TEST_ROOT=str(self.base), TEST_ORIGIN="https://example.invalid/Python-R-Scripts.git",
                        PYTHONDONTWRITEBYTECODE="1", TMPDIR=str(self.base))
        # Stub Git reads only: tests do not initialize, stage, or commit a repository.
        git_stub = """#!/bin/sh
[ "$1" = "-C" ] && [ "$2" = "$TEST_ROOT" ] || exit 97
case "$3 $4" in
 "rev-parse --show-toplevel") printf '%s\\n' "$TEST_ROOT";;
 "rev-parse HEAD") printf '%s\\n' 1111111111111111111111111111111111111111;;
 "config --get") printf '%s\\n' "$TEST_ORIGIN";;
 *) exit 97;;
esac
"""
        (self.bin / "git").write_text(git_stub)
        (self.bin / "git").chmod(0o700)
        for name in ("ssh", "scp", "sftp", "rsync", "curl", "wget"):
            path = self.bin / name
            path.write_text("#!/bin/sh\nprintf unexpected > " + str(self.marker) + "\nexit 97\n")
            path.chmod(0o700)

    def save(self):
        self.profile.write_text(json.dumps(self.p, indent=2))

    def run_sender(self, *args, success=True):
        import subprocess
        result = subprocess.run(["bash", str(self.sender), *args], env=self.env,
                                capture_output=True, text=True, timeout=12)
        self.assertEqual(result.returncode == 0, success, result.stderr)
        self.assertFalse(self.marker.exists(), "network executable invoked")
        return result

    def preview(self):
        return self.run_sender("--profile", "config/test-profile.json")

    def rejected(self):
        self.save()
        r = self.run_sender("--profile", "config/test-profile.json", success=False)
        self.assertEqual(r.stdout, "")
        return r

    def test_profile_happy_path_reference_parity_and_zero_writes(self):
        before = {str(p): p.read_bytes() for p in self.root.rglob("*") if p.is_file()}
        a = json.loads(self.preview().stdout)
        self.p["files"].reverse()
        self.save()
        b = json.loads(self.preview().stdout)
        expected = manifest(self.p, self.rows, "1" * 40, a["run_id"])
        self.assertEqual(a, expected)
        self.assertEqual(a["profile_sha256"], b["profile_sha256"])
        self.assertEqual(a["content_digest"], b["content_digest"])
        self.assertNotEqual(a["run_id"], b["run_id"])
        self.assertNotEqual(a["run_correlation_digest"], b["run_correlation_digest"])
        self.assertEqual(a["workstream"], "A4")
        self.assertNotIn("papers/", json.dumps(a))
        after = {str(p): p.read_bytes() for p in self.root.rglob("*") if p.is_file()}
        before.pop(str(self.profile))
        after.pop(str(self.profile))
        self.assertEqual(before, after)

    def test_empty_profile_and_execute(self):
        self.p = json.loads(PROFILE.read_text())
        self.save()
        preview = json.loads(self.preview().stdout)
        self.assertEqual(preview["state"], "EMPTY_NOT_EXECUTABLE")
        self.assertNotIn("content_digest", preview)
        r = self.run_sender("--profile", "config/test-profile.json", "--execute", success=False)
        self.assertIn("EMPTY_NOT_EXECUTABLE", r.stderr)
        self.assertEqual(r.stdout, "")

    def test_active_execute_stops_at_receiver_dependency(self):
        before = {str(p) for p in self.base.rglob("*")}
        r = self.run_sender("--profile", "config/test-profile.json", "--execute", success=False)
        self.assertIn("RECEIVER_NOT_AVAILABLE_FOR_PROTOCOL_V2", r.stderr)
        self.assertEqual(r.stdout, "")
        self.assertEqual(before, {str(p) for p in self.base.rglob("*")})

    def test_identity_mismatch_from_profile_and_checkout(self):
        self.p["source_repository_id"] = "Other"
        self.assertIn("SOURCE_REPOSITORY_ID_MISMATCH", self.rejected().stderr)
        self.p["source_repository_id"] = "Python-R-Scripts"
        self.save()
        self.env["TEST_ORIGIN"] = "https://example.invalid/Other.git"
        r = self.run_sender("--profile", "config/test-profile.json", success=False)
        self.assertIn("SOURCE_REPOSITORY_ID_MISMATCH", r.stderr)

    def test_runtime_rejects_schema_and_endpoint_injection(self):
        original = copy.deepcopy(self.p)
        for key, value in [("host", "forbidden"), ("destination_root", "forbidden"),
                           ("user", "forbidden"), ("profile_version", "2.0.0"),
                           ("workstream", "papers/A4_placeholder")]:
            with self.subTest(key=key):
                self.p = copy.deepcopy(original)
                self.p[key] = value
                self.rejected()

    def test_runtime_duplicate_case_and_path_rejection(self):
        original = copy.deepcopy(self.p)
        for field in ("source_path", "staging_path"):
            for case in (False, True):
                self.p = copy.deepcopy(original)
                name = self.p["files"][0][field]
                self.p["files"][1][field] = name.replace("synthetic", "SYNTHETIC") if case else name
                self.rejected()
        for path in ("../x", "/x", "C:/x", "Fear-of-Falling//x",
                     "Fear-of-Falling/../x", "Fear-of-Falling/\u00e4.md"):
            self.p = copy.deepcopy(original)
            self.p["files"][0]["source_path"] = path
            self.rejected()

    def test_runtime_hard_deny_csv_and_approved_hash(self):
        original = copy.deepcopy(self.p)
        for path in ("Fear-of-Falling/.env", "Fear-of-Falling/raw/x.md",
                     "Fear-of-Falling/data/x.csv", "Fear-of-Falling/outputs/x.db",
                     "Fear-of-Falling/outputs/x.RDS", "Fear-of-Falling/reports/x.csv"):
            with self.subTest(path=path):
                self.p = copy.deepcopy(original)
                self.p["files"][0]["source_path"] = path
                self.rejected()
        self.p = copy.deepcopy(original)
        self.p["files"][0]["expected_sha256"] = "0" * 64
        self.rejected()

    def test_runtime_symlinks_and_nonregular(self):
        import os
        path = self.base / self.p["files"][0]["source_path"]
        path.unlink()
        path.symlink_to(self.base / self.p["files"][1]["source_path"])
        self.rejected()
        path.unlink()
        os.mkfifo(path)
        self.rejected()
        path.unlink()
        path.mkdir()
        self.rejected()

    def test_runtime_parent_symlink_and_profile_symlink(self):
        import os
        out = self.root / "outputs"
        moved = self.base / "outside"
        out.rename(moved)
        out.symlink_to(moved, target_is_directory=True)
        self.rejected()
        out.unlink()
        moved.rename(out)
        target = self.base / "profile.json"
        self.profile.rename(target)
        self.profile.symlink_to(target)
        r = self.run_sender("--profile", "config/test-profile.json", success=False)
        self.assertEqual(r.stdout, "")

    def test_runtime_malformed_json_and_mixed_modes(self):
        self.profile.write_text('{"files":[],"files":[]}')
        self.run_sender("--profile", "config/test-profile.json", success=False)
        r = self.run_sender("--profile", "config/test-profile.json",
                            "--allowlist", "config/artifact-transfer.allowlist", success=False)
        self.assertEqual(r.returncode, 2)

    def test_runtime_rejects_change_between_validation_reads(self):
        from unittest.mock import patch
        # Load production definitions without invoking its CLI or executing a subprocess.
        source = self.sender.read_text().split("<<'PY'\n", 1)[1].rsplit("\nPY", 1)[0]
        definitions = source.rsplit("\ntry:\n    main()", 1)[0]
        namespace = {}
        exec(compile(definitions, str(self.sender), "exec"), namespace)
        measure = namespace["v2_measure"]
        changed = self.base / self.rows[0]["source_path"]
        calls = []

        def mutate_after_first_read(fd, parts):
            result = measure(fd, parts)
            calls.append(parts)
            if len(calls) == 1:
                changed.write_bytes(b"changed after first read")
            return result

        with patch.dict(namespace, v2_repository=lambda _: "1" * 40,
                        v2_measure=mutate_after_first_read):
            with self.assertRaises(ValueError):
                namespace["profile_main"](str(self.root), "config/test-profile.json", True)
        self.assertGreaterEqual(len(calls), 3)
        self.assertFalse(self.marker.exists())

    def test_legacy_completion_states_without_network(self):
        import contextlib
        import io
        import os
        from types import SimpleNamespace
        from unittest.mock import patch
        source = self.sender.read_text().split("<<'PY'\n", 1)[1].rsplit("\nPY", 1)[0]
        namespace = {}
        exec(compile(source.rsplit("\ntry:\n    main()", 1)[0], str(self.sender), "exec"), namespace)
        rows = [json.dumps({"path": "outputs/synthetic-0.md", "size": 3,
                            "sha256": hashlib.sha256(b"abc").hexdigest()})]
        settings = dict(WINDOWS_HOST="synthetic.invalid", WINDOWS_USER="fixture",
                        WINDOWS_STAGING_DIR="synthetic-stage",
                        WINDOWS_RECEIVER_SCRIPT="synthetic-receiver")
        for mode in ("SUCCESS", "FAILED", "UNKNOWN_REMOTE_STATE"):
            def fake_run(command, **kwargs):
                import base64
                decoded = base64.b64decode(command[-1].split()[-1]).decode("utf-16le")
                config = json.loads(base64.b64decode(
                    re.search(r"FromBase64String\('([^']+)'\)", decoded).group(1)))
                # Consume the actual local tar; no subprocess or network is executed.
                self.assertGreater(len(kwargs["stdin"].read()), 0)
                receipt = {"run_id": config["run_id"], "files": 1,
                           "status": "FAILED" if mode == "FAILED" else "VERIFIED"}
                return SimpleNamespace(returncode={"SUCCESS": 0, "FAILED": 1,
                                                   "UNKNOWN_REMOTE_STATE": 255}[mode],
                                       stdout=json.dumps(receipt).encode(), stderr=b"")
            with self.subTest(mode=mode), patch.dict(os.environ, settings):
                with patch.object(namespace["tempfile"], "gettempdir", return_value=str(self.base)):
                    with patch.object(namespace["subprocess"], "run", side_effect=fake_run):
                        output = io.StringIO()
                        fd = os.open(self.root, os.O_RDONLY | os.O_DIRECTORY)
                        try:
                            with contextlib.redirect_stdout(output), contextlib.redirect_stderr(io.StringIO()):
                                if mode == "SUCCESS":
                                    namespace["execute_transfer"](fd, str(self.root), rows)
                                    self.assertEqual(json.loads(output.getvalue())["outcome"], mode)
                                else:
                                    with self.assertRaises(namespace["TransferOutcomeError"]) as cm:
                                        namespace["execute_transfer"](fd, str(self.root), rows)
                                    self.assertEqual(cm.exception.outcome, mode)
                                    self.assertEqual(output.getvalue(), "")
                        finally:
                            os.close(fd)
        self.assertFalse(self.marker.exists())

    def test_legacy_default_empty_and_execute_gate(self):
        a = self.run_sender()
        self.assertEqual(a.stdout, "")
        self.assertEqual(a.stderr, "PREVIEW ONLY: 0 file(s)\n")
        self.assertEqual(self.run_sender("--execute").stdout, "")
        (self.root / "config/artifact-transfer.allowlist").write_text("file outputs/synthetic-0.md\n")
        preview = self.run_sender()
        self.assertEqual(json.loads(preview.stdout), {
            "path": "outputs/synthetic-0.md", "size": 3,
            "sha256": hashlib.sha256(b"abc").hexdigest(),
        })
        r = self.run_sender("--execute", success=False)  # Missing endpoint: before SSH.
        self.assertIn("FAILED:", r.stderr)


if __name__ == "__main__":
    unittest.main()


# Optional environment bindings select a provenance-bound receiver snapshot and a
# local PowerShell launcher. They are test configuration, never transport policy.
LOCAL_RECEIVER_ADAPTER = r'''import os,sys,json,io,tarfile,subprocess,hashlib
from pathlib import Path
base=Path(__file__).resolve().parent
mode=os.environ.get('FOF_TEST_FAULT','ok')
wire=sys.stdin.buffer.read()
with tarfile.open(fileobj=io.BytesIO(wire)) as tar:
 members=[(m,tar.extractfile(m).read() if m.isfile() else b'') for m in tar.getmembers()]
m=json.loads(members[0][1]);original=dict(m)
(base/'last-manifest.json').write_text(json.dumps(m))
registry=json.loads((base/'registry-fixture.json').read_text())
if mode=='profile_hash':registry['profiles'][0]['profile_sha256']='0'*64
if mode in ('profile_version','workstream','source_repository_id','unknown_profile','content_digest','destination_injection'):
 if mode=='unknown_profile':m['profile_id']='unknown'
 elif mode=='destination_injection':m['destination_root']='C:/forbidden'
 elif mode=='content_digest':m['content_digest']='0'*64
 else:m[mode]='wrong'
 members[0]=(members[0][0],json.dumps(m,sort_keys=True,separators=(',',':')).encode())
if mode in ('hash','size'):members[1]=(members[1][0],b'xyz' if mode=='hash' else b'abcd')
if mode=='missing':members.pop()
if mode=='extra':members.append((tarfile.TarInfo('files/extra.md'),b'abc'))
if mode in ('traversal','absolute','duplicate','case'):
 members[-1][0].name={'traversal':'../escape','absolute':'/escape','duplicate':'files/synthetic-0.md','case':'files/SYNTHETIC-0.md'}[mode]
if mode in ('symlink','hardlink'):
 members[1][0].type=tarfile.SYMTYPE if mode=='symlink' else tarfile.LNKTYPE
 members[1][0].linkname='../escape'
 members[1]=(members[1][0],b'')
if mode=='malformed':members[0]=(members[0][0],b'{')
if mode=='unsupported':
 m['protocol_version']='FOF_ARTIFACT_HANDOFF/99'
 members[0]=(members[0][0],json.dumps(m,sort_keys=True,separators=(',',':')).encode())
if mode!='ok' and mode not in ('late_ack','wrong_run','wrong_correlation','early','replay','multiple','invalid_time','profile_hash'):
 buf=io.BytesIO()
 with tarfile.open(fileobj=buf,mode='w',format=tarfile.USTAR_FORMAT) as tar:
  for h,b in members:h.size=len(b);tar.addfile(h,io.BytesIO(b) if h.isfile() else None)
 wire=buf.getvalue()
if mode=='partial':wire=wire[:800]
if mode=='early':sys.exit(255)
(base/'receiver/config/artifact-transfer-profiles.json').write_text(json.dumps(registry))
cmd=[v.replace('{fixture}',str(base)) for v in json.loads(os.environ['FOF_TEST_RECEIVER_COMMAND'])]
def invoke():return subprocess.run(cmd,input=wire,capture_output=True,timeout=45)
def receipt_files():
 root=base/'receiver/artifacts/staging/fof-dissertation-local-handoff/incoming'
 return {str(p.relative_to(root)):hashlib.sha256(p.read_bytes()).hexdigest() for p in root.rglob('*') if p.is_file()}
if mode=='replay':
 first=invoke();assert first.returncode==0,first.stderr
 before=receipt_files();result=invoke();assert before==receipt_files()
else:result=invoke()
(base/'last-receiver-result.json').write_text(json.dumps({'exit':result.returncode,'stdout':result.stdout.decode(errors='replace')}))
if mode=='late_ack':assert result.returncode==0,result.stderr;sys.exit(255)
output=result.stdout
if mode in ('wrong_run','wrong_correlation','invalid_time'):
 r=json.loads(output)
 r[{'wrong_run':'run_id','wrong_correlation':'run_correlation_digest','invalid_time':'verified_at'}[mode]]='wrong'
 output=json.dumps(r).encode()
if mode=='multiple':output=output+output
sys.stdout.buffer.write(output)
sys.exit(result.returncode)
'''


class CrossEndReceiverTests(unittest.TestCase):
    """Real sender process and byte-identical permanent receiver, local only."""
    save = SenderRuntimeTests.save
    preview = SenderRuntimeTests.preview
    run_sender = SenderRuntimeTests.run_sender

    def setUp(self):
        import os
        import shutil
        import sys
        snapshot = os.environ.get('FOF_TEST_RECEIVER_SNAPSHOT')
        if not snapshot or not os.environ.get('FOF_TEST_RECEIVER_COMMAND'):
            self.skipTest('provenance-bound snapshot and local PowerShell launcher required')
        SenderRuntimeTests.setUp(self)
        self.snapshot = Path(snapshot)
        self.evidence = json.loads((self.snapshot / 'baseline.json').read_text())
        for item in self.evidence['files']:
            self.assertEqual(hashlib.sha256((self.snapshot / item['path']).read_bytes()).hexdigest(), item['sha256'])
        scripts = self.base / 'receiver/scripts'
        scripts.mkdir(parents=True)
        shutil.copyfile(self.snapshot / 'scripts/receive_artifact_bundle.ps1', scripts / 'receive_artifact_bundle.ps1')
        (self.base / 'receiver/config').mkdir()
        registry = json.loads((self.snapshot / 'config/artifact-transfer-profiles.json').read_text())
        manifest = json.loads(self.preview().stdout)
        registry['profiles'][0]['profile_sha256'] = manifest['profile_sha256']
        registry['profiles'][0]['approved_content_digests'] = [manifest['content_digest']]
        (self.base / 'registry-fixture.json').write_text(json.dumps(registry))
        adapter = self.base / 'adapter.py'
        adapter.write_text(LOCAL_RECEIVER_ADAPTER)
        self.launcher = self.base / 'local-receiver'
        import shlex
        self.launcher.write_text('#!/bin/sh\nexec ' + shlex.quote(sys.executable) + ' ' + shlex.quote(str(adapter)) + '\n')
        self.launcher.chmod(0o700)
        self.approved_digest = manifest['content_digest']

    def execute(self, mode='ok', expected=0, approval=None):
        import subprocess
        env = dict(self.env, FOF_TEST_FAULT=mode)
        p = subprocess.run(['bash', str(self.sender), '--profile', 'config/test-profile.json',
                            '--execute', '--local-receiver', str(self.launcher),
                            '--approved-content-digest', approval or self.approved_digest],
                           env=env, capture_output=True, text=True, timeout=90)
        self.assertEqual(p.returncode, expected, p.stderr)
        self.assertFalse(self.marker.exists(), 'network command invoked')
        if expected:
            self.assertEqual(p.stdout, '')
            self.assertIn('FAILED:' if expected == 1 else 'UNKNOWN_REMOTE_STATE:', p.stderr)
        return p

    def receipt_path(self):
        m = json.loads((self.base / 'last-manifest.json').read_text())
        return self.base / 'receiver/artifacts/staging/fof-dissertation-local-handoff/incoming' / m['run_id'] / 'VERIFIED.json'

    def test_happy_path_and_rerun_preservation(self):
        a = json.loads(self.execute().stdout)
        first = self.receipt_path()
        before = first.read_bytes()
        self.assertEqual(a['outcome'], 'SUCCESS')
        self.assertEqual(a['receipt']['content_digest'], self.approved_digest)
        for row in a['receipt']['files']:
            self.assertEqual(hashlib.sha256((first.parent / 'files' / row['staging_path']).read_bytes()).hexdigest(), row['sha256'])
        b = json.loads(self.execute().stdout)
        self.assertEqual(b['outcome'], 'SUCCESS')
        self.assertNotEqual(a['receipt']['run_id'], b['receipt']['run_id'])
        self.assertEqual(first.read_bytes(), before)
        self.assertEqual(a['receipt']['content_digest'], b['receipt']['content_digest'])

    def test_known_receiver_failures_are_failed(self):
        for mode in ('hash', 'size', 'missing', 'extra', 'profile_hash'):
            with self.subTest(mode=mode):
                self.execute(mode, 1)
                result = json.loads((self.base / 'last-receiver-result.json').read_text())
                self.assertEqual(json.loads(result['stdout'])['status'], 'FAILED')
                self.assertFalse(self.receipt_path().exists())

    def test_identity_and_invalid_metadata_reject_without_fabricated_response(self):
        for mode in ('profile_version', 'workstream', 'source_repository_id', 'unknown_profile',
                     'content_digest', 'destination_injection', 'malformed', 'unsupported'):
            with self.subTest(mode=mode):
                self.execute(mode, 3)
                self.assertFalse(self.receipt_path().exists())

    def test_unsafe_archive_members(self):
        for mode, code in [('traversal', 1), ('absolute', 1), ('duplicate', 1), ('case', 1),
                           ('symlink', 3), ('hardlink', 3), ('partial', 3)]:
            with self.subTest(mode=mode):
                self.execute(mode, code)
                self.assertFalse(self.receipt_path().exists())

    def test_wrong_or_missing_acknowledgement_never_succeeds(self):
        for mode in ('wrong_run', 'wrong_correlation', 'multiple', 'invalid_time', 'late_ack'):
            with self.subTest(mode=mode):
                self.execute(mode, 3)
                self.assertTrue(self.receipt_path().is_file())

    def test_existing_run_rejection_preserves_original(self):
        self.execute('replay', 1)
        self.assertTrue(self.receipt_path().is_file())

    def test_early_failure_creates_no_receiver_receipt(self):
        self.execute('early', 3)
        self.assertFalse(self.receipt_path().exists())

    def test_explicit_preview_approval_is_required(self):
        self.execute(approval='0' * 64, expected=1)
        self.assertFalse((self.base / 'last-manifest.json').exists())

    def test_preview_ignores_local_execution_configuration(self):
        self.run_sender('--profile', 'config/test-profile.json', '--local-receiver', str(self.launcher))
        self.assertFalse((self.base / 'last-manifest.json').exists())


class SmokeProfileRuntimeTests(unittest.TestCase):
    """Opt-in test identity; all ordinary profile safety checks stay active."""
    save = SenderRuntimeTests.save
    run_sender = SenderRuntimeTests.run_sender

    def setUp(self):
        SenderRuntimeTests.setUp(self)
        self.p.update(profile_id='fof-synthetic-smoke', profile_version='0.0.0')
        self.save()

    def smoke(self, *args, success=True):
        return self.run_sender('--profile', 'config/test-profile.json', '--smoke-test',
                               *args, success=success)

    def test_exact_identity_requires_explicit_smoke_flag(self):
        self.assertIn('PROFILE_SCHEMA_MISMATCH', self.run_sender(
            '--profile', 'config/test-profile.json', success=False).stderr)
        result = self.smoke()
        self.assertIn('SMOKE PROFILE PREVIEW ONLY', result.stderr)
        self.assertEqual(json.loads(result.stdout)['profile_id'], 'fof-synthetic-smoke')
        self.assertFalse(self.marker.exists())
        self.assertIn('PROFILE_MODE_REQUIRED', self.run_sender('--smoke-test', success=False).stderr)

    def test_smoke_identity_is_exact_and_cannot_admit_production(self):
        for key, value in [('profile_id', 'arbitrary'), ('profile_id', 'a4-general-fi'),
                           ('profile_version', '1.0.0'), ('profile_version', '0.0.1'),
                           ('source_repository_id', 'other'), ('workstream', 'other')]:
            with self.subTest(key=key, value=value):
                old = self.p[key]
                self.p[key] = value
                self.save()
                self.smoke(success=False)
                self.p[key] = old
        self.p.update(profile_id='a4-general-fi', profile_version='1.0.0',
                      state='EMPTY_NOT_EXECUTABLE', files=[])
        self.save()
        self.smoke('--execute', success=False)
        self.assertIn('EMPTY_NOT_EXECUTABLE', self.run_sender(
            '--profile', 'config/test-profile.json', '--execute', success=False).stderr)
        self.assertFalse(self.marker.exists())

    def test_profile_endpoint_and_destination_injection_rejected(self):
        for key in ('host', 'user', 'windows_root', 'registry_path', 'staging_root',
                    'destination_root', 'smoke_test', 'ssh_credentials'):
            with self.subTest(key=key):
                self.p[key] = 'papers/A4_placeholder'
                self.save()
                self.smoke(success=False)
                del self.p[key]
        self.assertFalse(self.marker.exists())

    def test_smoke_digests_and_order_are_deterministic(self):
        a = json.loads(self.smoke().stdout)
        self.p['files'].reverse()
        self.save()
        b = json.loads(self.smoke().stdout)
        for key in ('profile_sha256', 'content_digest', 'files'):
            self.assertEqual(a[key], b[key])
        self.assertNotEqual(a['run_id'], b['run_id'])
        self.assertNotEqual(a['run_correlation_digest'], b['run_correlation_digest'])
        self.assertFalse(self.marker.exists())

    def test_smoke_hard_denies_and_paths(self):
        for path in ('Fear-of-Falling/data/fixture.md', 'Fear-of-Falling/raw/fixture.md',
                     'Fear-of-Falling/outputs/secret.md', 'Fear-of-Falling/outputs/.env',
                     'Fear-of-Falling/outputs/sample.db', 'Fear-of-Falling/outputs/sample.rds',
                     'Fear-of-Falling/outputs/sample.csv', '../outside.md', '/absolute.md',
                     'Fear-of-Falling//empty.md'):
            with self.subTest(path=path):
                self.p['files'][0]['source_path'] = path
                self.save()
                self.smoke(success=False)
        self.assertFalse(self.marker.exists())

    def test_smoke_duplicate_and_case_collision_rejected(self):
        for key, value in [('source_path', self.p['files'][0]['source_path']),
                           ('staging_path', self.p['files'][0]['staging_path']),
                           ('staging_path', self.p['files'][0]['staging_path'].upper())]:
            with self.subTest(key=key):
                old = self.p['files'][1][key]
                self.p['files'][1][key] = value
                self.save()
                self.smoke(success=False)
                self.p['files'][1][key] = old

    def test_smoke_symlink_and_nonregular_rejected(self):
        import os
        paths = []
        link = self.root / 'outputs/link.md'
        link.symlink_to(self.root / 'outputs/synthetic-0.md')
        paths.append(link)
        directory = self.root / 'outputs/directory.md'
        directory.mkdir()
        paths.append(directory)
        fifo = self.root / 'outputs/fifo.md'
        os.mkfifo(fifo)
        paths.append(fifo)
        for path in paths:
            with self.subTest(path=path.name):
                self.p['files'][0]['source_path'] = 'Fear-of-Falling/outputs/' + path.name
                self.save()
                self.smoke(success=False)
        self.assertFalse(self.marker.exists())

    def test_smoke_execute_uses_explicit_local_bridge_with_digest_gate(self):
        import shlex
        import sys
        manifest = json.loads(self.smoke().stdout)
        script = self.base / 'synthetic-receipt.py'
        script.write_text('''import sys,tarfile,json,io
with tarfile.open(fileobj=io.BytesIO(sys.stdin.buffer.read())) as t:
 m=json.load(t.extractfile('manifest.json'))
 for member in t.getmembers():
  t.extractfile(member).read()
r={k:m[k] for k in ('protocol_version','run_id','content_digest','run_correlation_digest')}
r.update(status='VERIFIED',file_count=len(m['files']),verified_at='2026-09-14T00:00:00Z')
print(json.dumps(r))
''')
        launcher = self.base / 'local-receiver'
        launcher.write_text('#!/bin/sh\nexec ' + shlex.quote(sys.executable) + ' ' + shlex.quote(str(script)) + '\n')
        launcher.chmod(0o700)
        self.assertIn('PREVIEW_APPROVAL_REQUIRED', self.smoke(
            '--execute', '--local-receiver', str(launcher), success=False).stderr)
        result = self.smoke('--execute', '--local-receiver', str(launcher),
                            '--approved-content-digest', manifest['content_digest'])
        self.assertEqual(json.loads(result.stdout)['outcome'], 'SUCCESS')
        self.assertFalse(self.marker.exists())
        self.assertIn('RECEIVER_NOT_AVAILABLE_FOR_PROTOCOL_V2', self.smoke('--execute', success=False).stderr)
