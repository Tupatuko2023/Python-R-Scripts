#!/usr/bin/env bash
# Artifact preview and explicit SSH export; Python 3.9+ standard library required.
# Usage: bash scripts/termux/export_artifacts_to_windows.sh [--allowlist PATH] [--execute]
# PATH is relative to Fear-of-Falling; only --execute permits SSH.
# Exit 0: preview/no selection or confirmed SUCCESS; 1: FAILED; 3: UNKNOWN_REMOTE_STATE.
set -Eeuo pipefail
if [[ -L "${BASH_SOURCE[0]}" ]]; then
  printf '%s\n' 'ERROR: sender must not be a symlink' >&2
  exit 1
fi
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
FOF_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd -P)"
exec python3 - "$FOF_ROOT" "$@" <<'PY'
import argparse
import base64
import fnmatch
import hashlib
import io
import json
import os
import re
import stat
import subprocess
import tarfile
import tempfile
import sys
import unicodedata
import uuid
from datetime import datetime, timezone
from contextlib import contextmanager


class TransferOutcomeError(Exception):
    def __init__(self, outcome, message):
        self.outcome = outcome
        super().__init__(message)


def fail(message):
    raise ValueError(message)


def components(path, pattern=False):
    if not path or path != path.strip() or unicodedata.normalize('NFC', path) != path:
        fail('empty, padded or non-NFC path')
    parts = path.split('/')
    for i, part in enumerate(parts):
        if not part or part in ('.', '..') or part.endswith((' ', '.')):
            fail('absolute, traversal or ambiguous path')
        allowed_glob = pattern and i == len(parts) - 1
        forbidden = '\\:<>"|' + ('' if allowed_glob else '*?[]')
        if any(ord(c) < 32 or ord(c) == 127 or c in forbidden for c in part):
            fail('unsafe path characters')
        if '**' in part or re.match(r'(?i)^(con|prn|aux|nul|com[0-9]|lpt[0-9])(?:\.|$)', part):
            fail('recursive glob or reserved Windows name')
    return parts


DENIED_DIRS = {'data', 'dataset', 'raw_data', 'external_data', '.git', '.ssh',
               '.aws', '.azure', 'secrets', 'credentials'}
DENIED_SUFFIXES = {'.rdata', '.rda', '.rds', '.sqlite', '.sqlite3', '.db', '.sav',
                   '.dta', '.xlsx', '.xls', '.pem', '.key', '.secret', '.p12',
                   '.pfx', '.kdbx', '.r', '.py', '.sh', '.ps1'}


def deny(parts):
    for part in parts:
        name = part.casefold()
        if (name in DENIED_DIRS or name in {'.renviron', '.netrc', '.npmrc'}
                or name == '.env' or name.startswith('.env.')
                or name.startswith(('id_rsa', 'id_ed25519', 'id_ecdsa', 'id_dsa'))
                or 'secret' in name or 'credential' in name
                or any(name.endswith(suffix) for suffix in DENIED_SUFFIXES)):
            fail('hard-denied selection')


@contextmanager
def opened(root_fd, parts, directory=False):
    # Walk directory descriptors, never symlinks, including during races.
    fd = os.dup(root_fd)
    try:
        for i, part in enumerate(parts):
            flags = os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK
            if i < len(parts) - 1 or directory:
                flags |= os.O_DIRECTORY
            next_fd = os.open(part, flags, dir_fd=fd)
            os.close(fd)
            fd = next_fd
        mode = os.fstat(fd).st_mode
        if not (stat.S_ISDIR(mode) if directory else stat.S_ISREG(mode)):
            fail('only regular files or traversal directories are permitted')
        yield fd
    finally:
        os.close(fd)



def execute_transfer(root_fd, root, rows):
    if not rows:
        return
    host = os.environ.get('WINDOWS_HOST', '')
    user = os.environ.get('WINDOWS_USER', '')
    staging = os.environ.get('WINDOWS_STAGING_DIR', '')
    receiver = os.environ.get('WINDOWS_RECEIVER_SCRIPT', '')
    if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9.-]{0,252}', host):
        fail('WINDOWS_HOST must be a DNS name or IPv4 address')
    if not re.fullmatch(r'[A-Za-z0-9_][A-Za-z0-9_.-]{0,63}', user):
        fail('WINDOWS_USER must be a simple SSH account name')
    if not staging or not receiver or any(ord(c) < 32 for c in staging + receiver):
        fail('WINDOWS_STAGING_DIR and WINDOWS_RECEIVER_SCRIPT are required')
    run_id = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ-') + uuid.uuid4().hex
    # Configuration crosses the remote shell only as Base64, never shell syntax.
    config = base64.b64encode(json.dumps({'staging': staging, 'receiver': receiver, 'run_id': run_id},
                                       ensure_ascii=True).encode()).decode('ascii')
    command = ("$ErrorActionPreference='Stop'; "
               "$c=[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('" + config + "')) | ConvertFrom-Json; "
               "& $c.receiver -StagingDir $c.staging -TransferId $c.run_id; if (-not $?) { exit 1 }")
    encoded = base64.b64encode(command.encode('utf-16le')).decode('ascii')
    temp_root = os.path.realpath(tempfile.gettempdir())
    if os.path.commonpath([os.path.realpath(root), temp_root]) == os.path.realpath(root):
        fail('temporary storage must be outside the FOF root')
    bundle_dir = tempfile.mkdtemp(prefix='fof-artifact-bundle-', dir=temp_root)
    bundle_path = os.path.join(bundle_dir, 'bundle.tar')
    # Retain every run-specific local bundle; no automatic cleanup, even on failure.
    print('LOCAL BUNDLE: ' + json.dumps(bundle_path), file=sys.stderr)
    manifest = ('\n'.join(rows) + '\n').encode('utf-8')
    with open(bundle_path, 'xb') as output:
        with tarfile.open(fileobj=output, mode='w', format=tarfile.USTAR_FORMAT,
                          encoding='utf-8', errors='strict') as archive:
            entry = tarfile.TarInfo('transfer-manifest.jsonl')
            entry.size = len(manifest)
            archive.addfile(entry, io.BytesIO(manifest))
            for index, row in enumerate(rows):
                info = json.loads(row)
                parts = components(info['path'])
                deny(parts)
                snapshot_path = os.path.join(bundle_dir, str(index) + '.snapshot')
                digest = hashlib.sha256()
                size = 0
                with opened(root_fd, parts) as fd, open(snapshot_path, 'xb') as snapshot:
                    before = os.fstat(fd)
                    while True:
                        chunk = os.read(fd, 1024 * 1024)
                        if not chunk:
                            break
                        snapshot.write(chunk)
                        digest.update(chunk)
                        size += len(chunk)
                    after = os.fstat(fd)
                    if (before.st_mtime_ns, before.st_ctime_ns, before.st_size) != (
                            after.st_mtime_ns, after.st_ctime_ns, after.st_size):
                        fail('source changed during snapshot')
                if size != info['size'] or digest.hexdigest() != info['sha256']:
                    fail('source changed after preview')
                entry = tarfile.TarInfo('payload/' + info['path'])
                entry.size = size
                with open(snapshot_path, 'rb') as snapshot:
                    archive.addfile(entry, snapshot)
        if output.tell() > 1073741824:
            fail('bundle exceeds receiver size limit')
    print('TRANSFER_RUN_ID: ' + run_id, file=sys.stderr, flush=True)
    with open(bundle_path, 'rb') as payload:
        result = subprocess.run(
            ['ssh', '-T', '-o', 'BatchMode=yes', '-o', 'StrictHostKeyChecking=yes',
             '-o', 'ConnectTimeout=15', '-o', 'ServerAliveInterval=15',
             '-o', 'ServerAliveCountMax=3', '-l', user, host,
             'pwsh -NoLogo -NoProfile -NonInteractive -EncodedCommand ' + encoded],
            stdin=payload, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
    try:
        receipt = json.loads(result.stdout.decode('utf-8-sig'))
    except (ValueError, UnicodeError):
        receipt = None
    correlated = isinstance(receipt, dict) and receipt.get('run_id') == run_id
    # An explicit receiver rejection establishes failure. SSH 255 or a lost,
    # malformed or contradictory reply establishes only uncertainty.
    if (result.returncode not in (0, 255) and correlated
            and receipt.get('status') == 'FAILED'):
        raise TransferOutcomeError('FAILED', 'receiver rejected run ' + run_id)
    if (result.returncode != 0 or not correlated or receipt.get('status') != 'VERIFIED'
            or type(receipt.get('files')) is not int or receipt['files'] != len(rows)):
        raise TransferOutcomeError(
            'UNKNOWN_REMOTE_STATE',
            'completion was not confirmed; inspect WINDOWS_STAGING_DIR/incoming/'
            + run_id + '/ manually. Do not import based on this sender result. '
            'No automatic retry or remote receipt change was performed.')
    print(json.dumps({'outcome': 'SUCCESS', 'receipt': receipt}, ensure_ascii=True,
                     sort_keys=True, separators=(',', ':')))


# Profile mode is local-only until the permanent v2 receiver is available.
V2 = 'FOF_ARTIFACT_HANDOFF/2'
V2_CONSTANTS = {
    'protocol_version': V2, 'profile_id': 'a4-general-fi',
    'profile_version': '1.0.0', 'source_repository_id': 'Python-R-Scripts',
    'workstream': 'A4',
    'classification_policy': 'EXPLICIT_APPROVAL_HARD_DENY_PRECEDENCE',
}
V2_ROW_KEYS = {'source_path', 'staging_path', 'classification',
               'approval_reference', 'csv_approval_reference', 'expected_sha256'}
V2_EXTRA_DENIED = {'datasets', 'raw', 'participant', 'participants',
                   'participant-level', 'provenance',
                   'fi_candidate_registry.csv', 'fi_changelog.md'}


def v2_error(code):
    raise TransferOutcomeError('FAILED', code)


def v2_json(value):
    return json.dumps(value, ensure_ascii=True, sort_keys=True,
                      separators=(',', ':'), allow_nan=False).encode('ascii')


def v2_digest(value):
    return hashlib.sha256(v2_json(value)).hexdigest()


def v2_path(value, staging=False):
    if (type(value) is not str or not value.isascii()
            or len(value) > (100 if staging else 1024)):
        fail('invalid profile path')
    parts = components(value)
    if any(len(p) > 255 or p != p.strip() for p in parts):
        fail('ambiguous component')
    if staging:
        if len(parts) != 1:
            fail('staging must be a filename')
    elif parts[0] != 'Fear-of-Falling' or len(parts) < 2:
        fail('invalid source scope')
    deny(parts)
    if any(p.lower() in V2_EXTRA_DENIED for p in parts):
        fail('hard-denied profile selection')
    return parts


def v2_load(root_fd, path, smoke_test=False):
    def unique(pairs):
        result = {}
        for key, value in pairs:
            if key in result:
                fail('duplicate JSON key')
            result[key] = value
        return result
    with opened(root_fd, components(path)) as fd:
        with os.fdopen(os.dup(fd), encoding='utf-8', errors='strict') as stream:
            # Bound the profile itself; do not read an unbounded local file.
            text = stream.read(16 * 1024 * 1024 + 1)
    if len(text.encode('utf-8')) > 16 * 1024 * 1024:
        fail('profile too large')
    try:
        p = json.loads(text, object_pairs_hook=unique,
                       parse_constant=lambda _: fail('non-finite JSON'))
    except RecursionError:
        fail('profile nesting limit')
    if type(p) is not dict or set(p) != set(V2_CONSTANTS) | {'state', 'files'}:
        fail('profile schema mismatch')
    # Smoke identity is a separate opt-in admission policy, never a profile field.
    constants = dict(V2_CONSTANTS)
    if smoke_test:
        constants.update(profile_id='fof-synthetic-smoke', profile_version='0.0.0')
    for key, expected in constants.items():
        if type(p[key]) is not str or p[key] != expected:
            v2_error('SOURCE_REPOSITORY_ID_MISMATCH' if key == 'source_repository_id'
                     else 'PROFILE_SCHEMA_MISMATCH')
    if (p['state'] not in ('EMPTY_NOT_EXECUTABLE', 'APPROVED')
            or type(p['files']) is not list or len(p['files']) > 1000):
        fail('invalid profile state/files')
    if (p['state'] == 'APPROVED') != bool(p['files']):
        fail('profile state/files mismatch')
    sources, targets = set(), set()
    ref = r'[A-Za-z0-9][A-Za-z0-9._-]{0,127}'
    for row in p['files']:
        if type(row) is not dict or set(row) != V2_ROW_KEYS:
            fail('profile entry schema mismatch')
        source = v2_path(row['source_path'])
        target = v2_path(row['staging_path'], staging=True)
        if (row['classification'] != 'DISTRIBUTABLE_AS_IS'
                or type(row['approval_reference']) is not str
                or not re.fullmatch(ref, row['approval_reference'])
                or type(row['expected_sha256']) is not str
                or not re.fullmatch(r'[0-9a-f]{64}', row['expected_sha256'])):
            fail('unapproved content')
        for name, seen in ((row['source_path'], sources), (row['staging_path'], targets)):
            if name.lower() in seen:
                fail('duplicate/case collision')
            seen.add(name.lower())
        csv = source[-1].lower().endswith('.csv') or target[-1].lower().endswith('.csv')
        approval = row['csv_approval_reference']
        if csv:
            if ('outputs' not in source[:-1] or type(approval) is not str
                    or not re.fullmatch(ref, approval)):
                fail('CSV requires exact output approval')
        elif approval is not None:
            fail('unexpected CSV approval')
    p['files'].sort(key=lambda r: (r['source_path'], r['staging_path']))
    return p


def v2_repository(root):
    # Bind to the checkout containing this sender, never a profile-supplied root.
    parent = os.path.dirname(root)
    env = {k: v for k, v in os.environ.items() if not k.startswith('GIT_')}
    env['GIT_OPTIONAL_LOCKS'] = '0'

    def git(*args):
        result = subprocess.run(['git', '-C', parent, *args], env=env,
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                check=False)
        if result.returncode:
            v2_error('SOURCE_REPOSITORY_ID_MISMATCH')
        return result.stdout.decode('utf-8', errors='strict').strip()

    top = git('rev-parse', '--show-toplevel')
    if not os.path.samefile(top, parent) or os.path.basename(root) != 'Fear-of-Falling':
        v2_error('SOURCE_REPOSITORY_ID_MISMATCH')
    origin = git('config', '--get', 'remote.origin.url')
    if not re.search(r'(?:^|[/:])Python-R-Scripts(?:\.git)?/?$', origin):
        v2_error('SOURCE_REPOSITORY_ID_MISMATCH')
    head = git('rev-parse', 'HEAD')
    if not re.fullmatch(r'(?:[0-9a-f]{40}|[0-9a-f]{64})', head):
        fail('invalid source HEAD')
    return head


def v2_measure(root_fd, parts):
    with opened(root_fd, parts) as fd:
        before = os.fstat(fd)
        if before.st_size > 1073741824:
            fail('file size limit')
        h, size = hashlib.sha256(), 0
        while True:
            chunk = os.read(fd, 1024 * 1024)
            if not chunk:
                break
            size += len(chunk)
            if size > 1073741824:
                fail('file size limit')
            h.update(chunk)
        after = os.fstat(fd)
        signature = lambda s: (s.st_dev, s.st_ino, s.st_size, s.st_mtime_ns, s.st_ctime_ns)
        if size != before.st_size or signature(before) != signature(after):
            fail('file changed during hashing')
    return size, h.hexdigest()


def v2_local_execute(root_fd, root, profile_path, profile, manifest, receiver, approved_digest, smoke_test=False):
    """Explicit trusted local process only; no profile-mode SSH configuration."""
    if approved_digest != manifest['content_digest']:
        v2_error('PREVIEW_APPROVAL_REQUIRED')
    if (not os.path.isabs(receiver) or os.path.realpath(receiver) != receiver
            or not os.path.isfile(receiver) or not os.access(receiver, os.X_OK)):
        v2_error('LOCAL_RECEIVER_REQUIRED')
    temp_root = os.path.realpath(tempfile.gettempdir())
    if os.path.commonpath([os.path.realpath(root), temp_root]) == os.path.realpath(root):
        v2_error('TEMP_OUTSIDE_SOURCE_REQUIRED')
    # Preserve uniquely named local evidence; never retry, overwrite or delete a run.
    bundle_dir = tempfile.mkdtemp(prefix='fof-v2-local-', dir=temp_root)
    bundle_path = os.path.join(bundle_dir, 'bundle.tar')
    with os.fdopen(os.open(bundle_path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600), 'wb') as out:
        with tarfile.open(fileobj=out, mode='w', format=tarfile.USTAR_FORMAT) as archive:
            data = v2_json(manifest)
            info = tarfile.TarInfo('manifest.json')
            info.size = len(data)
            archive.addfile(info, io.BytesIO(data))
            for row in manifest['files']:
                parts = v2_path(row['source_path'])[1:]
                with opened(root_fd, parts) as fd:
                    before = os.fstat(fd)
                    with os.fdopen(os.dup(fd), 'rb') as stream:
                        data = stream.read(row['size_bytes'] + 1)
                    after = os.fstat(fd)
                signature = lambda s: (s.st_dev, s.st_ino, s.st_size, s.st_mtime_ns, s.st_ctime_ns)
                if (signature(before) != signature(after) or len(data) != row['size_bytes']
                        or hashlib.sha256(data).hexdigest() != row['sha256']):
                    v2_error('SNAPSHOT_PARITY_FAILURE')
                info = tarfile.TarInfo('files/' + row['staging_path'])
                info.size = len(data)
                archive.addfile(info, io.BytesIO(data))
        if out.tell() > 1073741824:
            v2_error('ARCHIVE_TOO_LARGE')
    for row in manifest['files']:
        if v2_measure(root_fd, v2_path(row['source_path'])[1:]) != (row['size_bytes'], row['sha256']):
            v2_error('SNAPSHOT_PARITY_FAILURE')
    if (v2_repository(root) != manifest['source_head']
            or v2_digest(v2_load(root_fd, profile_path, smoke_test)) != v2_digest(profile)):
        v2_error('SOURCE_STATE_CHANGED')
    print('LOCAL V2 BUNDLE: ' + json.dumps(bundle_path), file=sys.stderr)
    child_env = dict(os.environ, FOF_V2_TRANSFER_ID=manifest['run_id'])
    with open(bundle_path, 'rb') as wire, tempfile.TemporaryFile() as stdout, tempfile.TemporaryFile() as stderr:
        try:
            result = subprocess.run([receiver], stdin=wire, stdout=stdout, stderr=stderr,
                                    timeout=60, env=child_env)
        except subprocess.TimeoutExpired:
            raise TransferOutcomeError('UNKNOWN_REMOTE_STATE', 'local receiver acknowledgement timed out; do not retry')
        except OSError:
            v2_error('LOCAL_RECEIVER_START_FAILED')
        if stdout.tell() > 1048576:
            raise TransferOutcomeError('UNKNOWN_REMOTE_STATE', 'oversized receiver response')
        stdout.seek(0)
        def unique_pairs(pairs):
            answer = {}
            for key, value in pairs:
                if key in answer:
                    raise ValueError('duplicate response key')
                answer[key] = value
            return answer
        try:
            receipt = json.loads(stdout.read().decode('ascii'), object_pairs_hook=unique_pairs,
                                 parse_constant=lambda _: fail('invalid JSON constant'))
        except (ValueError, UnicodeError, RecursionError):
            receipt = None
    correlated = (type(receipt) is dict and all(receipt.get(k) == manifest[k] for k in
                  ('protocol_version', 'run_id', 'content_digest', 'run_correlation_digest'))
                  and type(receipt.get('file_count')) is int
                  and receipt['file_count'] == len(manifest['files']))
    if (correlated and result.returncode == 1 and receipt.get('status') == 'FAILED'
            and type(receipt.get('error_code')) is str
            and re.fullmatch(r'[A-Z][A-Z0-9_]{0,127}', receipt['error_code'])
            and 'verified_at' not in receipt):
        raise TransferOutcomeError('FAILED', 'correlated receiver rejection: ' + receipt['error_code'])
    timestamp_ok = False
    if correlated and type(receipt.get('verified_at')) is str:
        try:
            stamp = datetime.strptime(receipt['verified_at'], '%Y-%m-%dT%H:%M:%SZ')
            timestamp_ok = stamp.strftime('%Y-%m-%dT%H:%M:%SZ') == receipt['verified_at']
        except ValueError:
            pass
    if not (correlated and result.returncode == 0 and receipt.get('status') == 'VERIFIED' and timestamp_ok):
        raise TransferOutcomeError('UNKNOWN_REMOTE_STATE', 'completion not confirmed; inspect unique run; do not retry')
    print(v2_json({'outcome': 'SUCCESS', 'receipt': receipt}).decode('ascii'))


def profile_main(root, path, execute, local_receiver=None, approved_digest=None, smoke_test=False):
    root_fd = os.open(root, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
    try:
        p = v2_load(root_fd, path, smoke_test)
        head = v2_repository(root)
        if p['state'] == 'EMPTY_NOT_EXECUTABLE':
            if execute:
                v2_error('EMPTY_NOT_EXECUTABLE')
            print('PROFILE PREVIEW ONLY: EMPTY_NOT_EXECUTABLE; no transferable manifest',
                  file=sys.stderr)
            print(v2_json({'protocol_version': V2, 'profile_id': p['profile_id'],
                           'state': p['state'], 'files': []}).decode('ascii'))
            return
        rows, total = [], 0
        for entry in p['files']:
            parts = v2_path(entry['source_path'])
            # root_fd already denotes Fear-of-Falling, unlike repo-relative metadata.
            size, sha = v2_measure(root_fd, parts[1:])
            if sha != entry['expected_sha256']:
                fail('approved content hash drift')
            total += size
            if total > 1073741824:
                fail('total size limit')
            rows.append({'source_path': entry['source_path'],
                         'staging_path': entry['staging_path'],
                         'size_bytes': size, 'sha256': sha})
        # A second safe-open read catches replacement after an earlier member was hashed.
        for row in rows:
            if v2_measure(root_fd, v2_path(row['source_path'])[1:]) != (
                    row['size_bytes'], row['sha256']):
                fail('source changed after manifest preparation')
        if v2_repository(root) != head:
            fail('source HEAD changed')
        if v2_digest(v2_load(root_fd, path, smoke_test)) != v2_digest(p):
            fail('profile changed during preparation')
        base = {k: p[k] for k in ('protocol_version', 'source_repository_id',
                                  'profile_id', 'profile_version', 'workstream')}
        base.update(source_head=head, profile_sha256=v2_digest(p), files=rows)
        content = v2_digest(base)
        run = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ-') + uuid.uuid4().hex
        manifest = dict(base, run_id=run, content_digest=content,
                        run_correlation_digest=v2_digest({
                            'protocol_version': V2, 'run_id': run, 'content_digest': content}))
        if len(v2_json(manifest)) > 16 * 1024 * 1024:
            fail('manifest size limit')
        if execute:
            if local_receiver is not None:
                v2_local_execute(root_fd, root, path, p, manifest, local_receiver, approved_digest, smoke_test)
                return
            # No snapshots, archive, subprocess SSH, or misleading success before v2 wiring.
            v2_error('RECEIVER_NOT_AVAILABLE_FOR_PROTOCOL_V2')
        print(('SMOKE PROFILE PREVIEW ONLY: ' if smoke_test else 'PROFILE PREVIEW ONLY: ') + V2, file=sys.stderr)
        print(v2_json(manifest).decode('ascii'))
    finally:
        os.close(root_fd)


def main():
    parser = argparse.ArgumentParser(description='Preview by default; --execute transfers via SSH with explicit completion outcomes.')
    modes = parser.add_mutually_exclusive_group()
    modes.add_argument('--allowlist', default='config/artifact-transfer.allowlist')
    modes.add_argument('--profile', help='FOF-relative v2 profile; local preview/preparation only')
    parser.add_argument('--execute', action='store_true')
    parser.add_argument('--smoke-test', action='store_true', help='test-only fof-synthetic-smoke/0.0.0 admission; requires --profile')
    parser.add_argument('--local-receiver', help='trusted local executable for v2; never inferred from a profile')
    parser.add_argument('--approved-content-digest', help='v2 content digest explicitly approved from preview')
    args = parser.parse_args(sys.argv[2:])
    if args.profile is not None:
        profile_main(sys.argv[1], args.profile, args.execute, args.local_receiver,
                     args.approved_content_digest, args.smoke_test)
        return
    if args.smoke_test or args.local_receiver is not None or args.approved_content_digest is not None:
        v2_error('PROFILE_MODE_REQUIRED')
    root_fd = os.open(sys.argv[1], os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
    try:
        with opened(root_fd, components(args.allowlist)) as fd:
            with os.fdopen(os.dup(fd), encoding='utf-8', errors='strict') as stream:
                rules = stream.read().splitlines()
        selected = set()
        for number, rule in enumerate(rules, 1):
            if not rule or rule.startswith('#'):
                continue
            kind, separator, path = rule.partition(' ')
            if not separator or kind not in ('file', 'glob'):
                fail(f'line {number}: expected file PATH or glob PATH')
            parts = components(path, pattern=kind == 'glob')
            deny(parts)
            if kind == 'glob':
                with opened(root_fd, parts[:-1], directory=True) as parent_fd:
                    matches = sorted(name for name in os.listdir(parent_fd)
                                     if fnmatch.fnmatchcase(name, parts[-1]))
                paths = ['/'.join(parts[:-1] + [name]) for name in matches]
            else:
                paths = [path]
            if not paths:
                fail(f'line {number}: unmatched glob')
            for candidate in paths:
                candidate_parts = components(candidate)
                deny(candidate_parts)
                if candidate.casefold().endswith('.csv'):
                    if kind != 'file' or 'outputs' not in candidate_parts[:-1]:
                        fail('CSV requires an exact file rule under outputs')
                with opened(root_fd, candidate_parts):
                    pass
                selected.add(candidate)
        ordered = sorted(selected)
        folded = [path.casefold() for path in ordered]
        if len(set(folded)) != len(folded):
            fail('Windows case-insensitive path collision')
        # Buffer the whole preview: a failed selection never emits a partial list.
        rows = []
        for path in ordered:
            with opened(root_fd, components(path)) as fd:
                before = os.fstat(fd)
                digest = hashlib.sha256()
                size = 0
                while True:
                    chunk = os.read(fd, 1024 * 1024)
                    if not chunk:
                        break
                    digest.update(chunk)
                    size += len(chunk)
                after = os.fstat(fd)
                signature = lambda info: (info.st_dev, info.st_ino, info.st_size,
                                          info.st_mtime_ns, info.st_ctime_ns)
                if size != before.st_size or signature(before) != signature(after):
                    fail('file changed during hashing')
            rows.append(json.dumps({'path': path, 'sha256': digest.hexdigest(),
                                    'size': size}, ensure_ascii=True, sort_keys=True,
                                   separators=(',', ':')))
        mode = 'VALIDATED' if args.execute else 'PREVIEW ONLY'
        print(f'{mode}: {len(rows)} file(s)', file=sys.stderr)
        if rows:
            print('\n'.join(rows), flush=True)
        if args.execute:
            execute_transfer(root_fd, sys.argv[1], rows)
    finally:
        os.close(root_fd)


try:
    main()
except TransferOutcomeError as exc:
    print(f'{exc.outcome}: {exc}', file=sys.stderr)
    sys.exit(3 if exc.outcome == 'UNKNOWN_REMOTE_STATE' else 1)
except (OSError, ValueError, UnicodeError) as exc:
    # Avoid echoing sensitive candidate paths or exception filenames.
    print(f'FAILED: local validation or preparation failed ({type(exc).__name__}); no confirmed success', file=sys.stderr)
    sys.exit(1)
PY
