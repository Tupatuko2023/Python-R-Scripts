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


def main():
    parser = argparse.ArgumentParser(description='Preview by default; --execute transfers via SSH with explicit completion outcomes.')
    parser.add_argument('--allowlist', default='config/artifact-transfer.allowlist')
    parser.add_argument('--execute', action='store_true')
    args = parser.parse_args(sys.argv[2:])
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
