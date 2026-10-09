#!/usr/bin/env python3
"""PLACE/1: place a verified reception's payload into a chosen local repo folder.

Preview and execute only. No overwrite; no Git operations; no auto-import.
Reads a supported verified reception (FOF_KB_PULL/1 staging run) and copies its
payload into a target Git checkout, creating missing files and refusing to
change existing ones. The transfer VERIFIED.json is never modified.
"""
import argparse
import hashlib
import json
import os
import re
import stat
import subprocess
import sys
import uuid
from contextlib import contextmanager
from datetime import datetime, timezone
from pathlib import Path

PROTOCOL = 'PLACE/1'
RECEIPT_PROTOCOL = 'PLACE_RECEIPT/1'
FORMS = {
    'FOF_KB_PULL/1': {'protocol_key': 'protocol', 'payload_dir': 'payload', 'size_key': 'size'},
    'FOF_ARTIFACT_HANDOFF/2': {'protocol_key': 'protocol_version', 'payload_dir': 'files',
                               'size_key': 'size_bytes'},
}
SUPPORTED_FORMS = tuple(FORMS)
MAX_FILE = 16 * 1024 * 1024
MAX_TOTAL = 64 * 1024 * 1024
DENIED_DIRS = {'data', 'dataset', 'datasets', 'raw', 'raw_data', 'external_data',
               'participant', 'participants', 'participant-level', '.git', '.ssh',
               '.aws', '.azure', 'secrets', 'credentials', 'provenance'}
DENIED_SUFFIXES = {'.rdata', '.rda', '.rds', '.sqlite', '.sqlite3', '.db', '.sav',
                   '.dta', '.xlsx', '.xls', '.pem', '.key', '.secret', '.p12',
                   '.pfx', '.kdbx', '.r', '.py', '.sh', '.ps1', '.exe', '.dll',
                   '.csv', '.zip', '.tar', '.gz'}


class Reject(Exception):
    pass


def require(condition, code):
    if not condition:
        raise Reject(code)


def canonical(value):
    return json.dumps(value, sort_keys=True, ensure_ascii=True,
                      separators=(',', ':'), allow_nan=False).encode('ascii')


def sha(data):
    return hashlib.sha256(data).hexdigest()


def path_parts(value):
    require(isinstance(value, str) and value and value == value.strip(), 'UNSAFE_PATH')
    require('\\' not in value and '\x00' not in value, 'UNSAFE_PATH')
    parts = value.split('/')
    for part in parts:
        require(re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9_. -]{0,100}', part) is not None
                and part not in ('.', '..') and part == part.strip() and not part.endswith('.')
                and re.match(r'(?i)^(con|prn|aux|nul|com[0-9]|lpt[0-9])(?:\.|$)', part) is None,
                'UNSAFE_PATH')
    return parts


def hard_deny(value):
    for part in path_parts(value):
        name = part.casefold()
        require(name not in DENIED_DIRS
                and not name.startswith(('.env', 'id_rsa', 'id_ed25519', 'id_ecdsa', 'id_dsa'))
                and 'secret' not in name and 'credential' not in name
                and not any(name.endswith(suffix) for suffix in DENIED_SUFFIXES), 'HARD_DENY')


def _no_reparse(path):
    info = os.lstat(path)
    require(not stat.S_ISLNK(info.st_mode), 'LINK_REJECTED')
    require(not (getattr(info, 'st_file_attributes', 0) & 0x400), 'REPARSE_REJECTED')
    return info


def _posix_anchor(directory):
    """Resolve the first ancestor the current user controls, never the fs root.

    Android forbids opening '/', /data and /data/data; a system-owned ancestor
    above this anchor cannot be opened but also cannot be swapped by this user.
    Walks user-controlled ancestors only, mirroring the reviewed
    fof_kb_pull.py anchor resolution."""
    require(os.getuid() == os.geteuid() and os.getgid() == os.getegid(),
            'SET_ID_RUNTIME_DENIED')
    directory = Path(directory).absolute()
    for ancestor in [*reversed(directory.parents), directory]:
        info = ancestor.lstat()
        require(stat.S_ISDIR(info.st_mode), 'ROOT_SYMLINK_OR_NONDIR')
        if info.st_uid == os.geteuid() or os.access(ancestor, os.W_OK):
            require(ancestor != Path(ancestor.anchor), 'UNSAFE_ROOT')
            return ancestor, info
    raise Reject('UNSAFE_ROOT')


@contextmanager
def locked_read(path):
    """Read a regular file holding every ancestor against replacement."""
    path = Path(path).absolute()
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
            for item in list(reversed(path.parents)) + [path]:
                handle = create(str(item), 0x80000000, 1, None, 3, 0x02200000, None)
                require(handle != wintypes.HANDLE(-1).value, 'SAFE_OPEN_FAILED')
                handles.append(handle)
                attrs = kernel.GetFileAttributesW(str(item))
                require(attrs != 0xffffffff and not attrs & 0x400, 'REPARSE_REJECTED')
                require(bool(attrs & 0x10) == (item != path), 'NONREGULAR_FILE')
            import msvcrt
            fd = msvcrt.open_osfhandle(handles[-1], os.O_RDONLY | os.O_BINARY)
            handles.pop()
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
        parent = path.parent
        anchor, anchor_info = _posix_anchor(parent)
        fd = os.open(anchor, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
        handles.append(fd)
        try:
            opened = os.fstat(fd)
            require((opened.st_dev, opened.st_ino)
                    == (anchor_info.st_dev, anchor_info.st_ino), 'ROOT_CHANGED')
            for part in parent.relative_to(anchor).parts:
                fd = os.open(part, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW,
                             dir_fd=fd)
                handles.append(fd)
            fd = os.open(path.name, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK,
                         dir_fd=fd)
            handles.append(fd)
            require(stat.S_ISREG(os.fstat(fd).st_mode), 'NONREGULAR_FILE')
            with os.fdopen(os.dup(fd), 'rb') as stream:
                yield stream
        finally:
            for handle in reversed(handles):
                os.close(handle)


def read_bytes(path):
    _no_reparse(Path(path))
    with locked_read(path) as stream:
        data = stream.read(MAX_FILE + 1)
    require(len(data) <= MAX_FILE, 'SIZE_LIMIT')
    return data


def read_json(path):
    data = read_bytes(path)
    require(len(data) <= 256 * 1024, 'JSON_LIMIT')
    try:
        obj = json.loads(data.decode('utf-8'))
    except (ValueError, UnicodeDecodeError) as exc:
        raise Reject('JSON_INVALID') from exc
    require(canonical(obj) == data.rstrip(b'\n'), 'JSON_NOT_CANONICAL')
    return obj


def _identity_of(path):
    info = os.lstat(path)
    return (info.st_dev, info.st_ino, stat.S_IFMT(info.st_mode))


def _verify_chain(path):
    """Reject symlink/reparse on every existing ancestor (missing ones are created later)."""
    path = Path(path).absolute()
    for item in [path, *path.parents]:
        try:
            info = os.lstat(item)
        except FileNotFoundError:
            continue
        require(not stat.S_ISLNK(info.st_mode), 'LINK_REJECTED')
        require(not (getattr(info, 'st_file_attributes', 0) & 0x400), 'REPARSE_REJECTED')
    return path


def _parent_identity(directory):
    directory = Path(directory).absolute()
    return [_identity_of(item) for item in reversed([directory, *directory.parents])]


@contextmanager
def _hold_dir(directory):
    """Open a directory and every ancestor without following links; hold them open.

    Yields the directory's descriptor (POSIX) or None (Windows). Holding the
    handles blocks concurrent replacement of the chain while the caller writes."""
    directory = Path(directory).absolute()
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
            for item in list(reversed(directory.parents)) + [directory]:
                handle = create(str(item), 0x80000000, 1, None, 3, 0x02200000, None)
                require(handle != wintypes.HANDLE(-1).value, 'SAFE_OPEN_FAILED')
                handles.append(handle)
                attrs = kernel.GetFileAttributesW(str(item))
                require(attrs != 0xffffffff and not attrs & 0x400, 'REPARSE_REJECTED')
                require(bool(attrs & 0x10), 'NONREGULAR_ANCESTOR')
            yield None
        finally:
            for handle in reversed(handles):
                kernel.CloseHandle(handle)
    else:
        anchor, anchor_info = _posix_anchor(directory)
        fd = os.open(anchor, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
        handles.append(fd)
        try:
            opened = os.fstat(fd)
            require((opened.st_dev, opened.st_ino)
                    == (anchor_info.st_dev, anchor_info.st_ino), 'ROOT_CHANGED')
            for part in directory.relative_to(anchor).parts:
                fd = os.open(part, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW,
                             dir_fd=fd)
                handles.append(fd)
            require(stat.S_ISDIR(os.fstat(fd).st_mode), 'NONREGULAR_ANCESTOR')
            yield fd
        finally:
            for handle in reversed(handles):
                os.close(handle)


def create_new(path, data):
    """Create a new file inside a held parent without overwrite; fsync."""
    path = Path(path).absolute()
    parent = path.parent
    _verify_chain(parent)
    if not parent.exists():
        parent.mkdir(parents=True, exist_ok=True)
        _verify_chain(parent)
    before = _parent_identity(parent)
    if os.name == 'nt':
        flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL | getattr(os, 'O_BINARY', 0)
        target = str(path)
    else:
        flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW
        target = path.name
    with _hold_dir(parent) as parent_fd:
        try:
            fd = os.open(target, flags, 0o600) if parent_fd is None \
                else os.open(target, flags, 0o600, dir_fd=parent_fd)
        except FileExistsError as exc:
            raise Reject('TARGET_EXISTS') from exc
        with os.fdopen(fd, 'wb') as stream:
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
    require(_parent_identity(parent) == before, 'PARENT_CHANGED')
    return len(data)


def git_identity(root):
    def git(*args):
        process = subprocess.run(['git', '-C', str(root), *args], stdout=subprocess.PIPE,
                                 stderr=subprocess.DEVNULL, check=False)
        require(process.returncode == 0, 'TARGET_NOT_GIT')
        return process.stdout.decode('utf-8').strip()
    require(Path(git('rev-parse', '--show-toplevel')).resolve() == Path(root).resolve(),
            'TARGET_ROOT_NOT_CHECKOUT')
    head = git('rev-parse', 'HEAD')
    require(re.fullmatch(r'[0-9a-f]{40}', head) is not None, 'TARGET_HEAD')
    origin = git('config', '--get', 'remote.origin.url')
    return {'origin_url': origin, 'head': head}


def detect_form(staging_run):
    """Return the reception protocol, or reject unsupported forms (incl. LEGACY)."""
    manifest = read_json(Path(staging_run) / 'manifest.json')
    for protocol, spec in FORMS.items():
        if manifest.get(spec['protocol_key']) == protocol:
            return protocol, manifest
    raise Reject('UNSUPPORTED_RECEPTION_FORM')


def _bind_reception(protocol, manifest, receipt, run_id):
    """Recompute the reception digest with the protocol's own canonical rules.

    Binds the recomputed digest to the manifest, the VERIFIED receipt and (for
    v2) the run correlation. Rejects any tamper or correlation mismatch. Each
    form is bound exactly as its sender computes it; no shared manifest shape is
    invented."""
    if protocol == 'FOF_KB_PULL/1':
        content = {key: value for key, value in manifest.items()
                   if key not in ('batch_id', 'content_digest')}
        recomputed = sha(canonical(content))
        require(manifest.get('content_digest') == recomputed, 'MANIFEST_DIGEST')
        batch_id = manifest.get('batch_id')
        require(isinstance(batch_id, str)
                and re.fullmatch(r'[0-9a-f]{32}', batch_id) is not None
                and batch_id == receipt.get('batch_id'), 'BATCH_ID_CORRELATION')
        return recomputed, batch_id
    rows = manifest.get('files')
    require(isinstance(rows, list) and rows, 'MANIFEST_FILES')
    for row in rows:
        require(isinstance(row, dict)
                and {'sha256', 'size_bytes', 'source_path', 'staging_path'} <= set(row),
                'MANIFEST_ROW')
    base = {'files': [{'sha256': row['sha256'], 'size_bytes': row['size_bytes'],
                       'source_path': row['source_path'], 'staging_path': row['staging_path']}
                      for row in sorted(rows, key=lambda item: (item['source_path'],
                                                                item['staging_path']))],
            'profile_id': manifest['profile_id'],
            'profile_sha256': manifest['profile_sha256'],
            'profile_version': manifest['profile_version'],
            'protocol_version': manifest['protocol_version'],
            'source_head': manifest['source_head'],
            'source_repository_id': manifest['source_repository_id'],
            'workstream': manifest['workstream']}
    recomputed = sha(canonical(base))
    require(manifest.get('content_digest') == recomputed, 'MANIFEST_DIGEST')
    require(manifest.get('run_id') == run_id, 'RUN_ID')
    correlation = sha(canonical({'content_digest': recomputed,
                                 'protocol_version': manifest['protocol_version'],
                                 'run_id': run_id}))
    require(manifest.get('run_correlation_digest') == correlation
            and receipt.get('run_correlation_digest') == correlation,
            'RUN_CORRELATION')
    return recomputed, correlation


def exact_set(root, expected):
    root = Path(root)
    require(root.is_dir(), 'PAYLOAD_DIR_MISSING')
    found = set()
    for current, _dirs, files in os.walk(root, followlinks=False):
        for name in files:
            info = os.lstat(Path(current) / name)
            require(not stat.S_ISLNK(info.st_mode)
                    and not (getattr(info, 'st_file_attributes', 0) & 0x400), 'LINK_REJECTED')
            found.add((Path(current) / name).relative_to(root).as_posix())
    return found


def verify_staging(staging_run):
    """Verify a supported verified reception; return (run_id, content_digest, files)."""
    staging_run = Path(staging_run)
    protocol, manifest = detect_form(staging_run)
    spec = FORMS[protocol]
    receipt = read_json(staging_run / 'VERIFIED.json')
    require(receipt.get('status') == 'VERIFIED', 'NOT_VERIFIED')
    require(receipt.get(spec['protocol_key']) == protocol, 'RECEIPT_PROTOCOL')
    run_id = receipt.get('run_id')
    require(run_id == staging_run.name
            and re.fullmatch(r'[0-9]{8}T[0-9]{6}Z-[0-9a-f]{32}', run_id or '') is not None,
            'RUN_ID')
    content_digest, correlation = _bind_reception(protocol, manifest, receipt, run_id)
    require(receipt.get('content_digest') == manifest.get('content_digest')
            == content_digest, 'RECEIPT_DIGEST')
    rows = manifest.get('files')
    require(isinstance(rows, list) and rows, 'MANIFEST_FILES')
    require(receipt.get('file_count') == len(rows), 'FILE_COUNT')
    total = 0
    files = []
    seen_sources = set()
    seen_folded = set()
    for row in rows:
        require(isinstance(row, dict) and {'staging_path', 'sha256', spec['size_key']} <= set(row),
                'MANIFEST_ROW')
        staging_path = row['staging_path']
        hard_deny(staging_path)
        require(staging_path not in seen_sources and staging_path.casefold() not in seen_folded,
                'MANIFEST_DUP')
        seen_sources.add(staging_path)
        seen_folded.add(staging_path.casefold())
        size = row[spec['size_key']]
        require(type(size) is int and 0 <= size <= MAX_FILE, 'SIZE_LIMIT')
        data = read_bytes(staging_run / spec['payload_dir'] / staging_path)
        require(len(data) == size and sha(data) == row['sha256'], 'PAYLOAD_MISMATCH')
        total += len(data)
        require(total <= MAX_TOTAL, 'TOTAL_LIMIT')
        files.append({'staging_path': staging_path, 'size': len(data), 'sha256': sha(data)})
    expected = {row['staging_path'] for row in files}
    require(exact_set(staging_run / spec['payload_dir'], expected) == expected, 'PAYLOAD_EXACT_SET')
    return run_id, content_digest, files, protocol, correlation


def load_map(path, files):
    mapping = {}
    obj = read_json(path)
    require(isinstance(obj, dict) and set(obj) == {'map'}, 'MAP_SCHEMA')
    rows = obj['map']
    require(isinstance(rows, list) and rows, 'MAP_ROWS')
    known = {row['staging_path'] for row in files}
    seen_targets = set()
    seen_sources = set()
    for row in rows:
        require(isinstance(row, dict) and set(row) == {'staging_path', 'target_path'}, 'MAP_ROW')
        require(row['staging_path'] in known, 'MAP_UNKNOWN_SOURCE')
        require(row['staging_path'] not in seen_sources, 'MAP_SOURCE_DUP')
        seen_sources.add(row['staging_path'])
        target = row['target_path']
        hard_deny(target)
        folded = target.casefold()
        require(folded not in seen_targets, 'TARGET_COLLISION')
        require(not any(folded.startswith(p + '/') or p.startswith(folded + '/')
                        for p in seen_targets), 'TARGET_COLLISION')
        seen_targets.add(folded)
        mapping[row['staging_path']] = target
    require(set(mapping) == known, 'MAP_INCOMPLETE')
    return mapping


def placement_digest(run_id, content_digest, protocol, correlation, repo, mapping, files):
    content = {'protocol': PROTOCOL, 'run_id': run_id,
               'reception_protocol': protocol, 'reception_correlation': correlation,
               'transfer_content_digest': content_digest, 'target_repository': repo,
               'map': {row['staging_path']: {'target_path': mapping[row['staging_path']],
                        'size': row['size'], 'sha256': row['sha256']} for row in files}}
    return sha(canonical(content))


def target_state(target_root, target_rel, expected_size, expected_sha):
    target = Path(target_root).absolute() / target_rel
    _verify_chain(target.parent)
    if not target.exists() and not target.is_symlink():
        return 'ABSENT'
    _no_reparse(target)
    require(target.is_file(), 'TARGET_NOT_REGULAR')
    try:
        data = read_bytes(target)
    except Reject as exc:
        if str(exc) == 'SIZE_LIMIT':
            return 'CONFLICT'
        raise
    if len(data) == expected_size and sha(data) == expected_sha:
        return 'ALREADY_PRESENT'
    return 'CONFLICT'


def build_plan(staging_run, target_root, map_path):
    run_id, content_digest, files, protocol, correlation = verify_staging(staging_run)
    repo = git_identity(target_root)
    mapping = load_map(map_path, files)
    rows = []
    for row in sorted(files, key=lambda r: r['staging_path']):
        target_rel = mapping[row['staging_path']]
        state = target_state(target_root, target_rel, row['size'], row['sha256'])
        rows.append({'staging_path': row['staging_path'], 'target_path': target_rel,
                     'size': row['size'], 'sha256': row['sha256'], 'state': state})
    digest = placement_digest(run_id, content_digest, protocol, correlation,
                              repo, mapping, files)
    return {'run_id': run_id, 'reception_protocol': protocol,
            'reception_correlation': correlation,
            'transfer_content_digest': content_digest,
            'target_repository': repo, 'placement_digest': digest, 'files': rows}


def _assert_receipt_external(receipt_path, target_root):
    """Reject a receipt inside the target repository or reached through a link."""
    receipt = Path(os.path.realpath(receipt_path))
    root = Path(os.path.realpath(target_root))
    _verify_chain(Path(receipt_path).absolute().parent)
    require(receipt != root and root not in receipt.parents, 'RECEIPT_INSIDE_TARGET')
    return receipt


def _link_no_replace(source, target):
    """Atomically give `target` the content of `source`; EEXIST if taken."""
    os.link(str(source), str(target))


def _fsync_dir(directory):
    """Best-effort directory fsync so a freshly linked entry is crash-durable."""
    if os.name == 'nt':
        return
    try:
        fd = os.open(str(directory), os.O_RDONLY | getattr(os, 'O_DIRECTORY', 0))
    except OSError:
        return
    try:
        os.fsync(fd)
    except OSError:
        pass
    finally:
        os.close(fd)


def _write_receipt(path, value):
    """Publish the receipt atomically without ever overwriting an existing file.

    A fully written and fsynced temporary file is hard-linked to the final path:
    link() is atomic and fails with FileExistsError if the target already exists,
    so the receipt never appears partially and is never replaced. If the
    filesystem cannot hard-link, publication fails safely (no partial receipt)."""
    path = Path(path)
    _verify_chain(path.parent)
    require(not path.exists() and not path.is_symlink(), 'RECEIPT_EXISTS')
    if not path.parent.exists():
        path.parent.mkdir(parents=True, exist_ok=True)
        _verify_chain(path.parent)
    data = canonical(value) + b'\n'
    temp = path.with_name('.' + path.name + '.' + uuid.uuid4().hex)
    try:
        with temp.open('xb') as stream:
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
        try:
            _link_no_replace(temp, path)
        except FileExistsError as exc:
            raise Reject('RECEIPT_EXISTS') from exc
        except OSError as exc:
            raise Reject('RECEIPT_PUBLISH_UNSUPPORTED') from exc
        _fsync_dir(path.parent)
    finally:
        if temp.exists():
            os.unlink(temp)
    require(read_bytes(path) == data, 'RECEIPT_MISMATCH')


def execute(staging_run, target_root, map_path, approved, receipt_path):
    receipt = _assert_receipt_external(receipt_path, target_root)
    require(not receipt.exists() and not receipt.is_symlink(), 'RECEIPT_EXISTS')
    plan = build_plan(staging_run, target_root, map_path)
    require(not receipt.exists() and not receipt.is_symlink(), 'RECEIPT_EXISTS')
    require(plan['placement_digest'] == approved, 'APPROVAL_MISMATCH')
    require(all(row['state'] != 'CONFLICT' for row in plan['files']), 'CONFLICT')
    payload_dir = FORMS[detect_form(staging_run)[0]]['payload_dir']
    results = []
    for row in plan['files']:
        if row['state'] == 'ALREADY_PRESENT':
            results.append(dict(row, result='ALREADY_PRESENT'))
            continue
        require(row['state'] == 'ABSENT', 'UNEXPECTED_STATE')
        data = read_bytes(Path(staging_run) / payload_dir / row['staging_path'])
        create_new(Path(target_root).absolute() / row['target_path'], data)
        final = read_bytes(Path(target_root).absolute() / row['target_path'])
        require(len(final) == row['size'] and sha(final) == row['sha256'], 'POST_WRITE_MISMATCH')
        results.append(dict(row, result='CREATED'))
    payload = {'protocol': RECEIPT_PROTOCOL, 'run_id': plan['run_id'],
               'reception_protocol': plan['reception_protocol'],
               'reception_correlation': plan['reception_correlation'],
               'transfer_content_digest': plan['transfer_content_digest'],
               'target_repository': plan['target_repository'],
               'placement_digest': plan['placement_digest'],
               'files': [{'source_path': row['staging_path'], 'target_path': row['target_path'],
                          'size': row['size'], 'sha256': row['sha256'], 'state': row['result']}
                         for row in results],
               'status': 'PLACED',
               'placed_at_utc': datetime.now(timezone.utc).isoformat().replace('+00:00', 'Z')}
    _write_receipt(receipt, payload)
    return payload


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='action', required=True)
    for name in ('preview', 'execute'):
        p = sub.add_parser(name)
        p.add_argument('--staging-run', required=True)
        p.add_argument('--target-root', required=True)
        p.add_argument('--map', required=True)
        if name == 'execute':
            p.add_argument('--approved-placement-digest', required=True)
            p.add_argument('--receipt', required=True)
    args = parser.parse_args()
    try:
        if args.action == 'preview':
            print(canonical(build_plan(args.staging_run, args.target_root, args.map)).decode('ascii'))
        else:
            print(canonical(execute(args.staging_run, args.target_root, args.map,
                                    args.approved_placement_digest, args.receipt)).decode('ascii'))
        return 0
    except (Reject, OSError, ValueError, KeyError, TypeError) as exc:
        print('PLACE_REJECTED: ' + (str(exc) if isinstance(exc, Reject) else 'LOCAL_FAILURE'),
              file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
