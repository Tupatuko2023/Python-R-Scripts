#!/usr/bin/env python3
"""Render the project registry into one CSV view.

Reads every ``PRJ-*.md`` file under the registry directory *without writing it*
and atomically publishes one CSV at the named output path (default
``outputs/cache/project_registry/projects.csv``). The output path must be
Git-ignored; a tracked path is refused. This tool is not read-only: it writes the
CSV. Only the registry sources are read-only for it.

The export layout is this tool's own documented schema. It is not the legacy
``tasks/agent_projects_v0.1.csv`` layout, and the legacy file is never modified.

Modes
-----
  (default)                  validate the registry, then write the CSV view
  --check                    validate and compare; write nothing
  --verify-guard FILE        pre-write guard for one registry file
  --print-source-hash FILE   print the SHA256 of the stored source block

Exit codes
----------
  0  OK
  1  validation or output-gate rejection
  2  --check mismatch, or a stale/foreign observation copy
  3  usage error
"""

from __future__ import annotations

import argparse
import csv
from dataclasses import dataclass
import hashlib
import io
import os
import re
import subprocess
import sys
import tempfile

BEGIN_MARKER = "<!-- source-description:begin -->"
END_MARKER = "<!-- source-description:end -->"
WORKTREE_HEADING = "## Worktree-havainnot"

# This tool's documented export schema (20 columns). Not the legacy v0.1 layout.
HEADER = [
    "Projekti-ID",
    "Projekti",
    "Nimi",
    "Tavoite ja valmistumiskriteeri",
    "Tila",
    "Viimeisin tilanne",
    "Seuraava toimenpide",
    "Este",
    "Toimituksen tila",
    "Worktree-siivous",
    "lyhenne",
    "Orkestroija",
    "Agentinnimi",
    "Agentti",
    "ympäristö",
    "pvm_aloitettu",
    "pvm_jäi_kesken",
    "pvm_valmis",
    "Jos, niin miksi projekti on nyt jäissä",
    "Linkki",
]

STATES = {"planned", "active", "paused", "closed", "unknown"}
DELIVERY = {"not_delivered", "delivered", "unknown"}
WORKTREE_STATES = {"active", "retained", "removed", "unknown"}
INVENTORY = {"unknown", "complete"}

REQUIRED_KEYS = (
    "id",
    "title",
    "short_name",
    "repo",
    "repo_ref",
    "state",
    "delivery",
    "goal",
    "done_criterion",
    "latest_status",
    "next_step",
    "source_description_sha256",
    "source_captured_at",
    "observed_at",
    "observed_commit",
    "observed_worktree_label",
)
# Present but allowed to be empty (documented meaning: nothing recorded).
OPTIONAL_EMPTY_KEYS = (
    "blocker",
    "orchestrator",
    "agent",
    "agent_tool",
    "environment",
    "started_date",
    "paused_date",
    "completed_date",
    "pause_reason",
    "link",
)

ID_RE = re.compile(r"^PRJ-[A-Z0-9]+(?:-[A-Z0-9]+)*$")
DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
SHA_RE = re.compile(r"^[0-9a-f]{64}$")
REPO_REF_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._/-]*$")
ABSOLUTE_RE = re.compile(r"^(?:[A-Za-z]:[\\/]|\\\\|~[\\/]|/)")

DEFAULT_REGISTRY = "docs/governance/project_registry"
DEFAULT_OUTPUT = "outputs/cache/project_registry/projects.csv"


class RegistryError(Exception):
    """Validation failure carrying one or more messages."""

    def __init__(self, messages):
        self.messages = list(messages)
        super().__init__("; ".join(self.messages))


# --------------------------------------------------------------------------- io


def read_text(path):
    with open(path, encoding="utf-8", newline="") as handle:
        return handle.read()


def normalise_newlines(text):
    return text.replace("\r\n", "\n").replace("\r", "\n")


def git(args, cwd=None):
    """Return (returncode, stdout). Returns (None, "") when git is unavailable."""
    try:
        proc = subprocess.run(
            ["git", *args],
            cwd=cwd,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
    except OSError:
        return None, ""
    return proc.returncode, proc.stdout or ""


def repo_root():
    code, out = git(["rev-parse", "--show-toplevel"])
    if code == 0 and out.strip():
        return out.strip().replace("\\", "/")
    return None


# ----------------------------------------------------------------- frontmatter


def strip_inline_comment(value):
    if value.startswith('"'):
        match = re.match(r'^"((?:[^"\\]|\\.)*)"\s*(?:#.*)?$', value)
        return f'"{match.group(1)}"' if match else value
    if value.startswith("'"):
        match = re.match(r"^'((?:[^'\\]|\\.)*)'\s*(?:#.*)?$", value)
        return f"'{match.group(1)}'" if match else value
    cut = value.find(" #")
    return value[:cut].rstrip() if cut != -1 else value


def scalar(value):
    value = strip_inline_comment(value)
    if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
        return value[1:-1]
    return value


def parse_frontmatter(text):
    """Flat ``key: value`` frontmatter plus ``- item`` lists. No nesting."""
    lines = normalise_newlines(text).split("\n")
    if not lines or lines[0].strip() != "---":
        raise RegistryError(["frontmatter: missing opening '---'"])
    meta = {}
    current_list = None
    for number, raw in enumerate(lines[1:], start=2):
        if raw.strip() == "---":
            return meta
        if not raw.strip():
            continue
        stripped = raw.lstrip()
        if stripped.startswith("- "):
            if current_list is None:
                raise RegistryError([f"frontmatter line {number}: list item without key"])
            meta[current_list].append(scalar(stripped[2:].strip()))
            continue
        if ":" not in raw:
            raise RegistryError([f"frontmatter line {number}: expected 'key: value'"])
        key, value = raw.split(":", 1)
        key = key.strip()
        if key in meta:
            raise RegistryError([f"frontmatter line {number}: duplicate key {key!r}"])
        value = value.strip()
        if value == "":
            meta[key] = []
            current_list = key
        else:
            meta[key] = scalar(value)
            current_list = None
    raise RegistryError(["frontmatter: missing closing '---'"])


def source_block(text):
    text = normalise_newlines(text)
    if BEGIN_MARKER not in text or END_MARKER not in text:
        raise RegistryError(
            [f"source block markers missing ({BEGIN_MARKER} / {END_MARKER})"]
        )
    start = text.index(BEGIN_MARKER) + len(BEGIN_MARKER)
    end = text.index(END_MARKER, start)
    block = text[start:end]
    if block.startswith("\n"):
        block = block[1:]
    return block


def source_sha256(text):
    """SHA256 over the LF-normalised UTF-8 bytes of the stored block."""
    return hashlib.sha256(source_block(text).encode("utf-8")).hexdigest()


def worktree_rows(text):
    """Rows of the '## Worktree-havainnot' table as (label, state, evidence)."""
    rows = []
    in_section = False
    for raw in normalise_newlines(text).split("\n"):
        if raw.startswith("## "):
            in_section = raw.strip() == WORKTREE_HEADING
            continue
        if not in_section or not raw.strip().startswith("|"):
            continue
        cells = [cell.strip() for cell in raw.strip().strip("|").split("|")]
        if not cells or set("".join(cells)) <= set("-: "):
            continue
        if cells[0].lower() == "label":
            continue
        if len(cells) < 2:
            raise RegistryError(["worktree table row needs at least label and state"])
        rows.append((cells[0], cells[1], cells[2] if len(cells) > 2 else ""))
    return rows


def worktree_cell(rows, inventory="unknown"):
    """Derive the cleanup cell.

    A cleanup claim needs both evidence and a known-complete inventory:
    removed known worktrees and complete coverage are different things. An
    empty or unknown-coverage inventory never claims cleanup, and delivery or
    task completion never implies it.
    """
    if not rows:
        return "unknown"
    states = {state for _, state, _ in rows}
    if states & {"active", "retained"}:
        return "retained"
    if states == {"removed"} and inventory == "complete":
        return "removed"
    return "unknown"


# -------------------------------------------------------------------- validate


def validate_project(path, text):
    errors = []
    try:
        meta = parse_frontmatter(text)
        block_sha = source_sha256(text)
        rows = worktree_rows(text)
    except RegistryError as exc:
        raise RegistryError([f"{os.path.basename(path)}: {msg}" for msg in exc.messages])

    name = os.path.basename(path)
    project_id = str(meta.get("id", "")).strip()

    if not ID_RE.match(project_id):
        errors.append(f"{name}: id must match PRJ-<SLUG>, got {project_id!r}")
    elif name != f"{project_id}.md":
        errors.append(f"{name}: filename must be {project_id}.md")

    for key in REQUIRED_KEYS:
        if key not in meta:
            errors.append(f"{name}: missing required key {key!r}")
        elif isinstance(meta[key], list):
            errors.append(f"{name}: key {key!r} must be a scalar")
        elif not str(meta[key]).strip() or str(meta[key]).strip() == "PENDING":
            errors.append(f"{name}: key {key!r} is empty or unresolved")

    state = str(meta.get("state", "")).strip()
    if state and state not in STATES:
        errors.append(f"{name}: state {state!r} not in {sorted(STATES)}")
    delivery = str(meta.get("delivery", "")).strip()
    if delivery and delivery not in DELIVERY:
        errors.append(f"{name}: delivery {delivery!r} not in {sorted(DELIVERY)}")

    repo_ref = str(meta.get("repo_ref", "")).strip()
    if repo_ref:
        if not REPO_REF_RE.match(repo_ref):
            errors.append(f"{name}: repo_ref must be a ref name, got {repo_ref!r}")
        if "@" in repo_ref:
            errors.append(
                f"{name}: repo_ref must not carry an observation commit; "
                "use observed_commit for that"
            )

    inventory = str(meta.get("worktree_inventory", "unknown")).strip() or "unknown"
    if inventory not in INVENTORY:
        errors.append(f"{name}: worktree_inventory {inventory!r} not in {sorted(INVENTORY)}")

    recorded = str(meta.get("source_description_sha256", "")).strip()
    if recorded and recorded != "PENDING":
        if not SHA_RE.match(recorded):
            errors.append(f"{name}: source_description_sha256 is not a SHA256")
        elif recorded != block_sha:
            errors.append(
                f"{name}: source_description_sha256 {recorded[:12]}... does not match "
                f"the stored block {block_sha[:12]}..."
            )

    for key, values in meta.items():
        items = values if isinstance(values, list) else [values]
        for item in items:
            item = str(item)
            if ABSOLUTE_RE.match(item):
                errors.append(f"{name}: field {key!r} contains an absolute path")
            if ".git/" in item.replace("\\", "/"):
                errors.append(f"{name}: field {key!r} references Git internals")

    for key in ("started_date", "paused_date", "completed_date",
                "source_captured_at", "observed_at"):
        value = str(meta.get(key, "")).strip()
        if value and not DATE_RE.match(value):
            errors.append(f"{name}: {key} must be YYYY-MM-DD, got {value!r}")

    for label, row_state, _ in rows:
        if row_state not in WORKTREE_STATES:
            errors.append(
                f"{name}: worktree row {label!r} state {row_state!r} not in "
                f"{sorted(WORKTREE_STATES)}"
            )

    if errors:
        raise RegistryError(errors)
    return meta, block_sha, rows


@dataclass(frozen=True)
class ProjectSnapshot:
    """One validated source read, including its export text and file identity."""

    path: str
    meta: dict
    block_sha: str
    rows: list
    description: str
    identity: tuple


def load_registry(registry_dir):
    if not os.path.isdir(registry_dir):
        raise RegistryError([f"registry directory not found: {registry_dir}"])
    paths = sorted(
        os.path.join(registry_dir, name)
        for name in os.listdir(registry_dir)
        if name.startswith("PRJ-") and name.endswith(".md")
    )
    if not paths:
        raise RegistryError([f"no PRJ-*.md files in {registry_dir}"])
    projects = []
    seen = {}
    errors = []
    for path in paths:
        try:
            text = read_text(path)
            meta, block_sha, rows = validate_project(path, text)
            source_stat = os.stat(path)
        except RegistryError as exc:
            errors.extend(exc.messages)
            continue
        project_id = meta["id"]
        if project_id in seen:
            errors.append(
                f"duplicate id {project_id!r} in {os.path.basename(path)} and {seen[project_id]}"
            )
            continue
        seen[project_id] = os.path.basename(path)
        projects.append(ProjectSnapshot(
            os.path.abspath(path), meta, block_sha, rows, source_block(text),
            (source_stat.st_dev, source_stat.st_ino),
        ))
    if errors:
        raise RegistryError(errors)
    return projects


# ---------------------------------------------------------------------- render


def build_row(meta, rows, description):
    goal = str(meta["goal"]).strip()
    criterion = str(meta["done_criterion"]).strip()
    goal_cell = f"Tavoite: {goal} Valmistumiskriteeri: {criterion}"
    slug = str(meta["id"])[len("PRJ-"):]
    inventory = str(meta.get("worktree_inventory", "unknown")).strip() or "unknown"
    return [
        str(meta["id"]),
        description,
        str(meta["short_name"]),
        goal_cell,
        str(meta["state"]),
        str(meta["latest_status"]),
        str(meta.get("next_step", "") or "NOT_DEFINED"),
        str(meta.get("blocker", "") or "none_recorded"),
        str(meta.get("delivery", "") or "unknown"),
        worktree_cell(rows, inventory),
        slug,
        str(meta.get("orchestrator", "") or "NOT_SET"),
        str(meta.get("agent", "") or "NOT_ASSIGNED"),
        str(meta.get("agent_tool", "") or "NOT_RECORDED"),
        str(meta.get("environment", "") or "NOT_RECORDED"),
        str(meta.get("started_date", "")),
        str(meta.get("paused_date", "")),
        str(meta.get("completed_date", "")),
        str(meta.get("pause_reason", "")),
        str(meta.get("link", "")),
    ]


def render_csv(projects):
    buffer = io.StringIO(newline="")
    writer = csv.writer(buffer, lineterminator="\n", quoting=csv.QUOTE_MINIMAL)
    writer.writerow(HEADER)
    for project in sorted(projects, key=lambda item: item.meta["id"]):
        writer.writerow(build_row(project.meta, project.rows, project.description))
    return buffer.getvalue().encode("utf-8")


# ------------------------------------------------------------------------ gate


def output_is_ignored(output_path):
    """True/False when git can answer, None when it cannot be determined."""
    root = repo_root()
    if root is None:
        return None
    rel = os.path.relpath(os.path.abspath(output_path), root).replace("\\", "/")
    code, _ = git(["check-ignore", "-q", "--", rel], cwd=root)
    if code == 0:
        return True
    if code == 1:
        return False
    return None


def output_target(output_path, registry_dir, projects):
    """Reject source aliases and return the target with its parent resolved."""
    output_abs = os.path.abspath(output_path)
    resolved = os.path.normcase(os.path.realpath(output_abs))
    registry = os.path.normcase(os.path.realpath(registry_dir))
    try:
        inside_registry = os.path.commonpath([resolved, registry]) == registry
    except ValueError:  # Different drives cannot overlap.
        inside_registry = False
    if inside_registry:
        raise RegistryError(["output must not be written inside the registry"])

    try:
        target_stat = os.stat(output_abs)
    except FileNotFoundError:
        target_stat = None
    for project in projects:
        if resolved == os.path.normcase(os.path.realpath(project.path)):
            raise RegistryError(["output aliases a registry source"])
        if target_stat is not None:
            identity = (target_stat.st_dev, target_stat.st_ino)
            if identity == project.identity or os.path.samefile(output_abs, project.path):
                raise RegistryError(["output aliases a registry source"])
    return os.path.join(os.path.realpath(os.path.dirname(output_abs)),
                        os.path.basename(output_abs))


def publish_csv(output_path, registry_dir, projects, payload):
    """Publish a complete, separate file without truncating the old target."""
    target = output_target(output_path, registry_dir, projects)
    parent = os.path.dirname(target)
    os.makedirs(parent, exist_ok=True)
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="wb", dir=parent, prefix=f".{os.path.basename(target)}-",
            suffix=".tmp", delete=False,
        ) as handle:
            temporary = handle.name
            if handle.write(payload) != len(payload):
                raise OSError("incomplete CSV write")
            handle.flush()
            os.fsync(handle.fileno())
        # Recheck aliases after writing, before publishing. Replace the directory
        # entry itself, so an output symlink is never opened for writing.
        if output_target(output_path, registry_dir, projects) != target:
            raise RegistryError(["output parent changed during generation"])
        os.replace(temporary, target)
        temporary = None
    finally:
        if temporary is not None:
            try:
                os.unlink(temporary)
            except FileNotFoundError:
                pass


def verify_guard(relative_path, expect_commit):
    relative_path = relative_path.replace("\\", "/")
    root = repo_root()
    if root is None:
        return 1, ["NOT_A_GIT_REPOSITORY"]

    code, out = git(["rev-parse", f"HEAD:{relative_path}"], cwd=root)
    head_blob = out.strip() if code == 0 and out.strip() else None
    code, out = git(["ls-files", "-s", "--", relative_path], cwd=root)
    index_blob = out.split()[1] if code == 0 and out.strip() else None
    code, out = git(["hash-object", f"--path={relative_path}", relative_path], cwd=root)
    worktree_blob = out.strip() if code == 0 and out.strip() else None

    violations = []
    stale = []
    if index_blob is None:
        violations.append("NOT_TRACKED: file is not in the index")
    if head_blob is None:
        violations.append("UNTRACKED_IN_HEAD: file has no committed blob")
    if index_blob and worktree_blob and index_blob != worktree_blob:
        violations.append("WORKING_TREE_CHANGED: working copy differs from the index")
    if index_blob and head_blob and index_blob != head_blob:
        violations.append("INDEX_DIVERGES_FROM_HEAD: staged change not committed")

    if expect_commit:
        code, _ = git(["merge-base", "--is-ancestor", expect_commit, "HEAD"], cwd=root)
        if code != 0:
            stale.append(f"FOREIGN_COMMIT: {expect_commit} is not an ancestor of HEAD")
        else:
            code, _ = git(["diff", "--quiet", expect_commit, "HEAD", "--", relative_path],
                          cwd=root)
            if code != 0:
                stale.append(
                    f"STALE_COPY: {relative_path} changed between {expect_commit} and HEAD"
                )

    if violations:
        return 1, violations
    if stale:
        return 2, stale
    return 0, ["OK"]


# ------------------------------------------------------------------------- cli


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--registry", default=DEFAULT_REGISTRY,
                        help="registry directory holding PRJ-*.md files")
    parser.add_argument("--output", default=DEFAULT_OUTPUT,
                        help="single CSV output path (must be Git-ignored)")
    parser.add_argument("--check", action="store_true",
                        help="validate and compare with --output; write nothing")
    parser.add_argument("--verify-guard", metavar="FILE",
                        help="pre-write guard for one registry file")
    parser.add_argument("--expect-commit", metavar="SHA",
                        help="commit whose version of FILE was read (guard mode)")
    parser.add_argument("--print-source-hash", metavar="FILE",
                        help="print the SHA256 of the stored source block")
    parser.add_argument("--skip-ignore-check", action="store_true",
                        help="skip the Git-ignore gate (tests only)")
    args = parser.parse_args(argv)

    if args.verify_guard:
        code, messages = verify_guard(args.verify_guard, args.expect_commit)
        print("\n".join(messages))
        return code

    if args.print_source_hash:
        try:
            print(source_sha256(read_text(args.print_source_hash)))
        except RegistryError as exc:
            print("\n".join(exc.messages), file=sys.stderr)
            return 1
        return 0

    try:
        projects = load_registry(args.registry)
    except RegistryError as exc:
        for message in exc.messages:
            print(f"project-registry: {message}", file=sys.stderr)
        return 1

    payload = render_csv(projects)

    if args.check:
        try:
            with open(args.output, "rb") as handle:
                current = handle.read()
        except OSError:
            print(f"project-registry: output missing: {args.output}", file=sys.stderr)
            return 2
        if current != payload:
            print("project-registry: CHECK_MISMATCH: output is not current",
                  file=sys.stderr)
            return 2
        print(f"project-registry: OK ({len(projects)} project(s), output current)")
        return 0

    if not args.skip_ignore_check:
        ignored = output_is_ignored(args.output)
        if ignored is False:
            print("project-registry: output path is not Git-ignored: "
                  f"{args.output}", file=sys.stderr)
            return 1
        if ignored is None:
            print("project-registry: cannot verify the Git-ignore state of the "
                  f"output path: {args.output}", file=sys.stderr)
            return 1

    try:
        publish_csv(args.output, args.registry, projects, payload)
    except (RegistryError, OSError) as exc:
        print(f"project-registry: publication failed: {exc}", file=sys.stderr)
        return 1
    print(f"project-registry: wrote {len(projects)} project(s) to {args.output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
