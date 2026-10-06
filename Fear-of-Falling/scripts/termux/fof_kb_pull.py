#!/usr/bin/env python3
"""FOF_KB_PULL/1: explicit snapshot approval, binary SSH pull, staging only."""
import argparse
import base64
from contextlib import contextmanager
import hashlib
import io
import json
import os
from pathlib import Path
import re
import stat
import select
import time
import subprocess
import sys
import tarfile
from datetime import datetime, timezone
import uuid

PROTOCOL = 'FOF_KB_PULL/1'
MAX_FILES = 100
MAX_FILE = 16 * 1024 * 1024
MAX_TOTAL = 64 * 1024 * 1024
MAX_WIRE = MAX_TOTAL + 2 * 1024 * 1024
MAX_JSON = 256 * 1024
DENIED_DIRS = {'data', 'dataset', 'datasets', 'raw', 'raw_data', 'external_data',
               'participant', 'participants', 'participant-level', '.git', '.ssh',
               '.aws', '.azure', 'secrets', 'credentials', 'provenance'}
DENIED_SUFFIXES = {'.rdata', '.rda', '.rds', '.sqlite', '.sqlite3', '.db', '.sav',
                   '.dta', '.xlsx', '.xls', '.pem', '.key', '.secret', '.p12',
                   '.pfx', '.kdbx', '.r', '.py', '.sh', '.ps1', '.exe', '.dll',
                   '.csv', '.zip', '.tar', '.gz'}
PROFILE_KEYS = {'protocol', 'profile_id', 'enabled', 'source_repository_id', 'files'}
ROW_KEYS = {'source_path', 'staging_path', 'classification', 'approval_reference'}
REPOSITORIES = {'Python-R-Scripts', 'FOF-Dissertation-Project'}


class Reject(Exception):
    pass


class PublicationUncertain(Reject):
    """Valid receipt is visible, but durable publication was not confirmed."""
    pass


def require(condition, code):
    if not condition:
        raise Reject(code)


def canonical(value):
    return json.dumps(value, sort_keys=True, ensure_ascii=True,
                      separators=(',', ':'), allow_nan=False).encode('ascii')


def digest(value):
    return hashlib.sha256(canonical(value)).hexdigest()


def sha(data):
    return hashlib.sha256(data).hexdigest()


def pairs(items):
    obj = {}
    for key, value in items:
        require(key not in obj, 'DUPLICATE_JSON_KEY')
        obj[key] = value
    return obj


def decode(data):
    require(len(data) <= MAX_JSON, 'JSON_LIMIT')
    try:
        return json.loads(data.decode('utf-8'), object_pairs_hook=pairs,
                          parse_constant=lambda x: (_ for _ in ()).throw(Reject('INVALID_JSON')))
    except (ValueError, UnicodeError) as exc:
        raise Reject('INVALID_JSON') from exc


def path_parts(value):
    require(isinstance(value, str) and len(value) <= 240, 'UNSAFE_PATH')
    parts = value.split('/')
    for part in parts:
        require(re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9_. -]{0,100}', part) is not None
                and part not in ('.', '..') and part == part.strip()
                and not part.endswith('.')
                and re.match(r'(?i)^(con|prn|aux|nul|com[0-9]|lpt[0-9])(?:\.|$)', part) is None,
                'UNSAFE_PATH')
    return parts


def hard_deny(value):
    for part in path_parts(value):
        name = part.casefold()
        require(name not in DENIED_DIRS and name not in {'.renviron', '.netrc', '.npmrc'}
                and not name.startswith(('.env', 'id_rsa', 'id_ed25519', 'id_ecdsa', 'id_dsa'))
                and 'secret' not in name and 'credential' not in name
                and not any(name.endswith(suffix) for suffix in DENIED_SUFFIXES), 'HARD_DENY')


@contextmanager
def locked_read(path):
    """Walk from private HOME on POSIX; refuse links/reparse points."""
    path = Path(path).absolute()
    require('..' not in path.parts, 'UNSAFE_PATH')
    handles = []
    if os.name == 'nt':
        import ctypes
        from ctypes import wintypes
        kernel = ctypes.WinDLL('kernel32', use_last_error=True)
        create = kernel.CreateFileW
        create.argtypes = [wintypes.LPCWSTR, wintypes.DWORD, wintypes.DWORD,
                           wintypes.LPVOID, wintypes.DWORD, wintypes.DWORD, wintypes.HANDLE]
        create.restype = wintypes.HANDLE
        kernel.CloseHandle.argtypes = [wintypes.HANDLE]
        kernel.GetFileAttributesW.argtypes = [wintypes.LPCWSTR]
        kernel.GetFileAttributesW.restype = wintypes.DWORD
        try:
            chain = list(reversed(path.parents)) + [path]
            for item in chain:
                handle = create(str(item), 0x80000000, 1, None, 3, 0x02200000, None)
                require(handle != wintypes.HANDLE(-1).value, 'SAFE_OPEN_FAILED')
                handles.append(handle)
                attrs = kernel.GetFileAttributesW(str(item))
                require(attrs != 0xffffffff and not attrs & 0x400, 'REPARSE_POINT')
                require(bool(attrs & 0x10) == (item != path), 'NONREGULAR_FILE')
            import msvcrt
            fd = msvcrt.open_osfhandle(handles[-1], os.O_RDONLY | os.O_BINARY)
            handles.pop()  # CRT owns the HANDLE only after successful conversion.
            try:
                stream = os.fdopen(fd, 'rb')
            except BaseException:
                os.close(fd)
                raise
            with stream:
                require(stat.S_ISREG(os.fstat(stream.fileno()).st_mode), 'NONREGULAR_FILE')
                yield stream
        finally:
            for handle in reversed(handles):
                kernel.CloseHandle(handle)
    else:
        # HOME is runtime configuration, never a profile/payload field. Find
        # the first ancestor the current user can replace children in or chmod.
        # Its preceding system-owned, non-writable chain cannot be swapped by
        # this user. Open that anchor, then walk ALL user-controlled ancestors
        # with dir_fd/no-follow (Android forbids opening '/', /data, /data/data).
        root = Path.home().absolute()
        require(root != Path(root.anchor) and '..' not in root.parts, 'UNSAFE_ROOT')
        # Android lacks effective_ids for access(); disallow set-id execution
        # so its real-id access check still represents the caller's authority.
        require(os.getuid() == os.geteuid() and os.getgid() == os.getegid(),
                'SET_ID_RUNTIME_DENIED')
        chain = [*reversed(root.parents), root]
        anchor = None
        for ancestor in chain:
            info = ancestor.lstat()
            require(stat.S_ISDIR(info.st_mode), 'ROOT_SYMLINK_OR_NONDIR')
            if info.st_uid == os.geteuid() or os.access(ancestor, os.W_OK):
                anchor = ancestor
                anchor_info = info
                break
        require(anchor is not None and anchor != Path(root.anchor), 'UNSAFE_ROOT')
        try:
            relative = path.relative_to(root)
        except ValueError as exc:
            raise Reject('OUTSIDE_PRIVATE_ROOT') from exc
        require(relative.parts and all(part not in ('.', '..') for part in relative.parts),
                'UNSAFE_PATH')
        fd = os.open(anchor, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
        handles.append(fd)
        try:
            opened_anchor = os.fstat(fd)
            require((opened_anchor.st_dev, opened_anchor.st_ino)
                    == (anchor_info.st_dev, anchor_info.st_ino), 'ROOT_CHANGED')
            for part in root.relative_to(anchor).parts:
                fd = os.open(part, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW,
                             dir_fd=fd)
                handles.append(fd)
            opened = os.fstat(fd)
            require(stat.S_ISDIR(opened.st_mode) and opened.st_uid == os.getuid()
                    and stat.S_IMODE(opened.st_mode) == 0o700,
                    'PRIVATE_ROOT_REQUIRED')
            for index, part in enumerate(relative.parts):
                flags = os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK
                if index < len(relative.parts) - 1:
                    flags |= os.O_DIRECTORY
                fd = os.open(part, flags, dir_fd=fd)
                handles.append(fd)
            require(stat.S_ISREG(os.fstat(fd).st_mode), 'NONREGULAR_FILE')
            with os.fdopen(os.dup(fd), 'rb') as stream:
                before = os.fstat(fd)
                yield stream
                after = os.fstat(fd)
                require((before.st_size, before.st_mtime_ns, before.st_ctime_ns)
                        == (after.st_size, after.st_mtime_ns, after.st_ctime_ns), 'SOURCE_CHANGED')
        finally:
            for fd in reversed(handles):
                os.close(fd)


def read(path, limit=MAX_FILE):
    with locked_read(path) as stream:
        data = stream.read(limit + 1)
        require(len(data) <= limit, 'SIZE_LIMIT')
        return data


def load(path):
    return decode(read(path, MAX_JSON))


def write_new(path, data):
    with Path(path).open('xb') as stream:
        stream.write(data)
        stream.flush()
        os.fsync(stream.fileno())


def atomic_new(path, value):
    path = Path(path)
    require(not path.exists() and not path.is_symlink(), 'RECEIPT_EXISTS')
    temp = path.with_name('.' + path.name + '.' + uuid.uuid4().hex)
    write_new(temp, canonical(value) + b'\n')
    # The run directory is private, new and never reused. Rename is atomic.
    os.rename(temp, path)
    if os.name != "nt":
        try:
            fd = os.open(path.parent, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
            try:
                os.fsync(fd)
            finally:
                os.close(fd)
        except OSError as exc:
            raise PublicationUncertain("PUBLISHED_RECEIPT_DURABILITY_UNCONFIRMED") from exc


def new_directory(root, name):
    root = Path(root).absolute()
    require(root.exists() and root.is_dir(), 'RUNTIME_ROOT_MISSING')
    for item in [root] + list(root.parents):
        info = item.lstat()
        require(not stat.S_ISLNK(info.st_mode)
                and not getattr(info, 'st_file_attributes', 0) & 0x400, 'UNSAFE_RUNTIME_ROOT')
    target = root / name
    target.mkdir(mode=0o700)  # exist_ok deliberately false
    return target


def profile(path, synthetic=False):
    return profile_object(load(path), synthetic)


def profile_object(obj, synthetic=False):
    obj = decode(canonical(obj))
    require(isinstance(obj, dict) and set(obj) == PROFILE_KEYS, 'PROFILE_SCHEMA')
    require(obj['protocol'] == PROTOCOL and type(obj['enabled']) is bool, 'PROFILE_SCHEMA')
    expected = 'kb-pull-synthetic-1' if synthetic else 'kb-pull-documents-1'
    require(obj['profile_id'] == expected, 'PROFILE_IDENTITY')
    require(obj['source_repository_id'] in REPOSITORIES, 'SOURCE_IDENTITY')
    require(obj['enabled'] and isinstance(obj['files'], list)
            and 1 <= len(obj['files']) <= MAX_FILES, 'PROFILE_CLOSED')
    source_names, target_names = set(), set()
    for row in obj['files']:
        require(isinstance(row, dict) and set(row) == ROW_KEYS, 'PROFILE_ROW')
        for key, names in [('source_path', source_names), ('staging_path', target_names)]:
            hard_deny(row[key])
            folded = row[key].casefold()
            require(folded not in names, 'PATH_COLLISION')
            require(not any(folded.startswith(p + '/') or p.startswith(folded + '/')
                            for p in names), 'PATH_COLLISION')
            names.add(folded)
        require(row['classification'] == 'DISTRIBUTABLE_AS_IS'
                and isinstance(row['approval_reference'], str)
                and re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9_.:/ -]{0,160}', row['approval_reference'])
                is not None, 'CONTENT_APPROVAL_REQUIRED')
    obj['files'].sort(key=lambda row: row['source_path'])
    return obj


def provenance(root, identity):
    # read-only Git queries; no remote operations or payload printed
    def git(*args):
        process = subprocess.run(['git', '-C', str(root), *args], stdout=subprocess.PIPE,
                                 stderr=subprocess.DEVNULL, check=False)
        require(process.returncode == 0, 'SOURCE_NOT_GIT')
        return process.stdout.decode('utf-8').strip()
    require(Path(git('rev-parse', '--show-toplevel')).resolve() == Path(root).resolve(),
            'SOURCE_ROOT_NOT_CHECKOUT')
    head = git('rev-parse', 'HEAD')
    require(re.fullmatch(r'[0-9a-f]{40}', head) is not None, 'SOURCE_HEAD')
    remote = git('config', '--get', 'remote.origin.url')
    require(re.search(r'(?:/|:)' + re.escape(identity) + r'(?:\.git)?$', remote) is not None,
            'SOURCE_REMOTE_IDENTITY')
    return {'repository_id': identity, 'head': head}


def preview(source, profile_path, batch_root, synthetic=False):
    p = profile(profile_path, synthetic)
    source = Path(source).absolute()
    origin = provenance(source, p['source_repository_id'])
    batch_id = uuid.uuid4().hex
    batch = new_directory(batch_root, batch_id)
    (batch / 'snapshots').mkdir(mode=0o700)
    rows = []
    total = 0
    for index, row in enumerate(p['files']):
        data = read(source / row['source_path'])
        total += len(data)
        require(total <= MAX_TOTAL, 'TOTAL_LIMIT')
        snapshot = f'snapshots/{index:04d}'
        write_new(batch / snapshot, data)
        rows.append(dict(row, size=len(data), sha256=sha(data), snapshot=snapshot))
    require(provenance(source, p['source_repository_id']) == origin, 'SOURCE_CHANGED')
    content = {'protocol': PROTOCOL, 'profile': p, 'profile_digest': digest(p),
               'source': origin, 'files': rows}
    manifest = dict(content, batch_id=batch_id, content_digest=digest(content))
    write_new(batch / 'manifest.json', canonical(manifest) + b'\n')
    # Local-only runtime root, never part of portable profile/manifest/Git.
    write_new(batch / 'runtime.json', canonical({'source_root': str(source)}))
    verify_batch(batch)
    return manifest


def manifest_check(m, p, approved, batch_id):
    require(isinstance(m, dict) and set(m) == {'protocol', 'profile', 'profile_digest',
            'source', 'files', 'batch_id', 'content_digest'}, 'MANIFEST_SCHEMA')
    require(re.fullmatch(r'[0-9a-f]{32}', batch_id) is not None
            and m['batch_id'] == batch_id and m['protocol'] == PROTOCOL, 'BATCH_IDENTITY')
    require(m['profile'] == p and m['profile_digest'] == digest(p), 'PROFILE_CHANGED')
    require(set(m['source']) == {'repository_id', 'head'}
            and m['source']['repository_id'] == p['source_repository_id']
            and re.fullmatch(r'[0-9a-f]{40}', m['source']['head']) is not None, 'PROVENANCE')
    require(isinstance(m['files'], list) and len(m['files']) == len(p['files']), 'EXACT_SET')
    total = 0
    for index, (row, selected) in enumerate(zip(m['files'], p['files'])):
        require(set(row) == ROW_KEYS | {'size', 'sha256', 'snapshot'}, 'MANIFEST_ROW')
        require({key: row[key] for key in ROW_KEYS} == selected, 'EXACT_SET')
        require(row['snapshot'] == f'snapshots/{index:04d}', 'SNAPSHOT_PATH')
        require(type(row['size']) is int and 0 <= row['size'] <= MAX_FILE, 'SIZE_LIMIT')
        require(isinstance(row['sha256'], str)
                and re.fullmatch(r'[0-9a-f]{64}', row['sha256']) is not None, 'HASH_FORMAT')
        total += row['size']
    require(total <= MAX_TOTAL, 'TOTAL_LIMIT')
    content = {key: m[key] for key in m if key not in ('batch_id', 'content_digest')}
    require(m['content_digest'] == digest(content) == approved, 'DIGEST_MISMATCH')


def exact_files(root):
    found = set()
    for current, dirs, files in os.walk(root, followlinks=False):
        for name in dirs + files:
            path = Path(current) / name
            info = path.lstat()
            require(not stat.S_ISLNK(info.st_mode)
                    and not getattr(info, 'st_file_attributes', 0) & 0x400, 'LINK_REJECTED')
            require(stat.S_ISREG(info.st_mode) or stat.S_ISDIR(info.st_mode), 'NONREGULAR_FILE')
        found.update((Path(current) / name).relative_to(root).as_posix() for name in files)
    return found


def verify_batch(batch, approved=None):
    batch = Path(batch)
    m = load(batch / 'manifest.json')
    # Validate embedded profile through the same schema, never a weaker test path.
    p = profile_from_object(m['profile'])
    manifest_check(m, p, approved or m['content_digest'], batch.name)
    expected = {'manifest.json', 'runtime.json'} | {r['snapshot'] for r in m['files']}
    if (batch / 'APPROVED.json').exists():
        expected.add('APPROVED.json')
    require(exact_files(batch) == expected, 'BATCH_EXACT_SET')
    runtime = load(batch / 'runtime.json')
    require(set(runtime) == {'source_root'}, 'RUNTIME_SCHEMA')
    source = Path(runtime['source_root'])
    require(provenance(source, p['source_repository_id']) == m['source'], 'SOURCE_CHANGED')
    for row in m['files']:
        for path in (batch / row['snapshot'], source / row['source_path']):
            data = read(path)
            require(len(data) == row['size'] and sha(data) == row['sha256'], 'SOURCE_OR_BATCH_CHANGED')
    return m


def profile_from_object(obj):
    return profile_object(obj, obj.get('profile_id') == 'kb-pull-synthetic-1')


def approve(batch, approved):
    require(re.fullmatch(r'[0-9a-f]{64}', approved or '') is not None, 'APPROVAL_REQUIRED')
    m = verify_batch(batch, approved)
    atomic_new(Path(batch) / 'APPROVED.json', {'batch_id': m['batch_id'], 'content_digest': approved})
    return {'status': 'APPROVED', 'batch_id': m['batch_id'], 'content_digest': approved}


def archive_bytes(batch, approved):
    m = verify_batch(batch, approved)
    require(load(Path(batch) / 'APPROVED.json') == {'batch_id': m['batch_id'],
            'content_digest': approved}, 'APPROVAL_REQUIRED')
    # Materialize and check the complete bounded wire before exposing any byte.
    output = io.BytesIO()
    with tarfile.open(fileobj=output, mode='w', format=tarfile.USTAR_FORMAT) as archive:
        entries = [('manifest.json', canonical(m))]
        for row in m['files']:
            data = read(Path(batch) / row['snapshot'])
            require(len(data) == row['size'] and sha(data) == row['sha256'], 'BATCH_CHANGED')
            entries.append(('payload/' + row['staging_path'], data))
        for name, data in entries:
            entry = tarfile.TarInfo(name)
            entry.size = len(data)
            entry.mode = 0o600
            archive.addfile(entry, io.BytesIO(data))
    verify_batch(batch, approved)
    data = output.getvalue()
    require(len(data) <= MAX_WIRE, 'WIRE_LIMIT')
    return data


def reserve_receive(root, run_id):
    require(os.name != 'nt', 'RECEIVER_REQUIRES_POSIX')
    require(re.fullmatch(r'[0-9]{8}T[0-9]{6}Z-[0-9a-f]{32}', run_id or '') is not None,
            'RUN_ID')
    root = Path(root).absolute()
    home = Path.home().absolute()
    require(root != home and home in root.parents, 'PRIVATE_HOME_REQUIRED')
    info = root.stat()
    require(info.st_uid == os.getuid() and stat.S_IMODE(info.st_mode) & 0o077 == 0,
            'PRIVATE_RUNTIME_ROOT_REQUIRED')
    return new_directory(root, run_id)


def validate_ustar(wire):
    offset = 0
    while offset + 512 <= len(wire):
        header = wire[offset:offset + 512]
        if header == b'\0' * 512:
            require(wire[offset:offset + 1024] == b'\0' * 1024
                    and not any(wire[offset:]), 'TRAILING_ARCHIVE_DATA')
            return
        require(header[156:157] == b'0' and header[257:265] == b'ustar\x0000',
                'USTAR_REGULAR_ONLY')
        info = tarfile.TarInfo.frombuf(header, 'ascii', 'strict')
        require(info.size <= MAX_FILE and info.size >= 0, 'SIZE_LIMIT')
        offset += 512 + ((info.size + 511) // 512) * 512
        require(offset <= len(wire), 'TRUNCATED_MEMBER')
    raise Reject('TRUNCATED_ARCHIVE')


def verify_wire(run, wire, p, approved, batch_id):
    require(len(wire) <= MAX_WIRE and len(wire) % 512 == 0
            and wire.endswith(b'\0' * 1024), 'TRUNCATED_OR_OVERSIZE_WIRE')
    validate_ustar(wire)
    expected = {'manifest.json'} | {'payload/' + r['staging_path'] for r in p['files']}
    found = set()
    manifest = None
    payload = Path(run) / 'payload'
    payload.mkdir(mode=0o700)
    with tarfile.open(fileobj=io.BytesIO(wire), mode='r:') as archive:
        for member in archive:
            require(member.isfile() and not member.pax_headers
                    and member.type == tarfile.REGTYPE, 'UNSAFE_ARCHIVE_MEMBER')
            path_parts(member.name)
            require(member.name in expected and member.name not in found, 'EXACT_SET')
            found.add(member.name)
            limit = MAX_JSON if member.name == 'manifest.json' else MAX_FILE
            require(0 <= member.size <= limit, 'SIZE_LIMIT')
            stream = archive.extractfile(member)
            data = stream.read(limit + 1)
            require(len(data) == member.size, 'TRUNCATED_MEMBER')
            if member.name == 'manifest.json':
                manifest = decode(data)
                manifest_check(manifest, p, approved, batch_id)
                write_new(Path(run) / 'manifest.json', canonical(manifest))
            else:
                require(manifest is not None, 'MANIFEST_MUST_BE_FIRST')
                target = Path(run) / member.name
                target.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
                write_new(target, data)
        # Reject second tar archive or nonzero bytes after first archive's end.
        require(not any(wire[archive.offset:]), 'TRAILING_ARCHIVE_DATA')
    require(found == expected and manifest is not None, 'EXACT_SET')
    require(exact_files(payload) == {r['staging_path'] for r in manifest['files']}, 'EXACT_SET')
    for row in manifest['files']:
        data = read(payload / row['staging_path'])
        require(len(data) == row['size'], 'SIZE_MISMATCH')
        require(sha(data) == row['sha256'], 'HASH_MISMATCH')
    for current, _, _ in os.walk(run, topdown=False):
        fd = os.open(current, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
        try:
            os.fsync(fd)
        finally:
            os.close(fd)
    fd = os.open(Path(run).parent, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
    try:
        os.fsync(fd)
    finally:
        os.close(fd)
    receipt = {'protocol': PROTOCOL, 'status': 'VERIFIED', 'run_id': Path(run).name,
               'batch_id': batch_id, 'content_digest': approved,
               'file_count': len(manifest['files']),
               'verified_at_utc': datetime.now(timezone.utc).isoformat().replace('+00:00', 'Z'),
               'return_receipt_status': 'NOT_DELIVERED'}
    atomic_new(Path(run) / 'VERIFIED.json', receipt)
    return receipt


def ssh_command(environ, batch_id, approved):
    alias = environ.get('FOF_KB_SSH_ALIAS', '')
    script = environ.get('FOF_KB_REMOTE_SCRIPT', '')
    root = environ.get('FOF_KB_REMOTE_BATCH_ROOT', '')
    require(re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9_.-]{0,127}', alias) is not None, 'SSH_ALIAS')
    for value in (script, root):
        require(re.fullmatch(r'[A-Za-z]:/(?:[A-Za-z0-9][A-Za-z0-9_. -]*/)*[A-Za-z0-9][A-Za-z0-9_. -]*', value)
                is not None, 'REMOTE_RUNTIME_PATH')
        path_parts(value[3:])
    require(script.endswith('/scripts/termux/fof_kb_pull.py'), 'REMOTE_SCRIPT_IDENTITY')
    require(re.fullmatch(r'[0-9a-f]{32}', batch_id) is not None
            and re.fullmatch(r'[0-9a-f]{64}', approved or '') is not None, 'APPROVAL_REQUIRED')
    # All arguments are narrow validated literals. Native Process raw streams avoid
    # PowerShell's object/text pipeline, including under Windows PowerShell 5.1.
    arguments = f'"{script}" serve --batch "{root}/{batch_id}" --approved-content-digest {approved}'
    command = ("$ErrorActionPreference='Stop'; $p=New-Object System.Diagnostics.Process; "
               "$p.StartInfo.FileName='python'; $p.StartInfo.Arguments='" + arguments + "'; "
               "$p.StartInfo.UseShellExecute=$false; $p.StartInfo.CreateNoWindow=$true; "
               "$p.StartInfo.RedirectStandardOutput=$true; $p.StartInfo.RedirectStandardError=$true; "
               "[void]$p.Start(); $e=$p.StandardError.ReadToEndAsync(); "
               "$p.StandardOutput.BaseStream.CopyTo([Console]::OpenStandardOutput()); "
               "$p.WaitForExit(); [Console]::Error.Write($e.Result); exit $p.ExitCode")
    encoded = base64.b64encode(command.encode('utf-16le')).decode('ascii')
    return ['ssh', '-T', '-o', 'BatchMode=yes', '-o', 'StrictHostKeyChecking=yes',
            '-o', 'ConnectionAttempts=1', '-o', 'ConnectTimeout=10',
            '-o', 'ClearAllForwardings=yes', '-o', 'PermitLocalCommand=no', alias,
            'powershell -NoLogo -NoProfile -NonInteractive -EncodedCommand ' + encoded]


def pull(profile_path, batch_id, approved, staging_root, run_id, synthetic=False):
    p = profile(profile_path, synthetic)
    require(re.fullmatch(r'[0-9a-f]{64}', approved or '') is not None, 'APPROVAL_REQUIRED')
    # Local explicit approval is checked before argv construction or payload fetch.
    argv = ssh_command(os.environ, batch_id, approved)
    run = reserve_receive(staging_root, run_id)
    wire_path = run / 'wire.tar'
    process = None
    try:
        with wire_path.open('xb') as wire:
            process = subprocess.Popen(argv, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                                       stderr=subprocess.DEVNULL, shell=False)
            total = 0
            deadline = time.monotonic() + 120
            while True:
                remaining = deadline - time.monotonic()
                require(remaining > 0, 'TRANSPORT_DEADLINE')
                ready, _, _ = select.select([process.stdout], [], [], remaining)
                require(bool(ready), 'TRANSPORT_DEADLINE')
                chunk = os.read(process.stdout.fileno(), 65536)
                if not chunk:
                    break
                total += len(chunk)
                require(total <= MAX_WIRE, 'WIRE_LIMIT')
                wire.write(chunk)
            process.stdout.close()
            status = process.wait(timeout=max(0.01, deadline - time.monotonic()))
            wire.flush()
            os.fsync(wire.fileno())
        require(status == 0, 'TRANSPORT_UNCERTAIN')
        return verify_wire(run, read(wire_path, MAX_WIRE), p, approved, batch_id)
    except BaseException as exc:
        if process is not None:
            if process.poll() is None:
                process.kill()
                process.wait()
            if process.stdout is not None:
                process.stdout.close()
        if (run / 'VERIFIED.json').exists():
            # Never publish contradictory UNVERIFIED after a valid receipt became
            # visible. This marker is best-effort because the filesystem just failed.
            marker = {'status': 'LOCAL_VERIFIED_DURABILITY_UNCONFIRMED',
                      'run_id': run_id, 'batch_id': batch_id,
                      'content_digest': approved, 'automatic_retry': False}
            try:
                write_new(run / 'PUBLICATION_UNCERTAIN.json', canonical(marker))
            except OSError:
                pass
            raise PublicationUncertain('LOCAL_VERIFIED_DURABILITY_UNCONFIRMED') from exc
        atomic_new(run / 'UNVERIFIED.json', {'status': 'UNVERIFIED', 'run_id': run_id,
                   'batch_id': batch_id, 'content_digest': approved, 'automatic_retry': False})
        raise


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['preview', 'approve', 'serve', 'pull'])
    parser.add_argument('--profile')
    parser.add_argument('--source-root')
    parser.add_argument('--batch-root')
    parser.add_argument('--batch')
    parser.add_argument('--batch-id')
    parser.add_argument('--approved-content-digest')
    parser.add_argument('--staging-root')
    parser.add_argument('--run-id')
    parser.add_argument('--synthetic-test', action='store_true')
    args = parser.parse_args()
    try:
        if args.action == 'preview':
            result = preview(args.source_root, args.profile, args.batch_root, args.synthetic_test)
        elif args.action == 'approve':
            result = approve(args.batch, args.approved_content_digest)
        elif args.action == 'serve':
            sys.stdout.buffer.write(archive_bytes(args.batch, args.approved_content_digest))
            sys.stdout.buffer.flush()
            return 0
        else:
            result = pull(args.profile, args.batch_id, args.approved_content_digest,
                          args.staging_root, args.run_id, args.synthetic_test)
        print(canonical(result).decode('ascii'))
        return 0
    except (Reject, OSError, ValueError, TypeError, KeyError, tarfile.TarError, subprocess.TimeoutExpired) as exc:
        # No paths, payload, remote stderr or exception text in user diagnostics.
        code = str(exc) if isinstance(exc, Reject) else 'LOCAL_OR_TRANSPORT_FAILURE'
        print('FOF_KB_PULL_REJECTED: ' + code, file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
