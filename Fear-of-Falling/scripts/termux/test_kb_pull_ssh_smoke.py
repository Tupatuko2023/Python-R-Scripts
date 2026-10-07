#!/usr/bin/env python3
"""Manual synthetic SSH harness; run only after reviewed Git delivery at both ends."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import time
import tarfile
import uuid
from datetime import datetime, timezone


def run_id():
    return datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ-') + uuid.uuid4().hex


def hashes(root):
    return {str(p.relative_to(root)): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in sorted(root.rglob('*')) if p.is_file()}


def record(path, value):
    temporary = path.with_name(path.name + '.' + uuid.uuid4().hex + '.tmp')
    with temporary.open('x') as stream:
        json.dump(value, stream, sort_keys=True, indent=2)
        stream.flush()
        os.fsync(stream.fileno())
    os.replace(temporary, path)


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def observe_wire(stream, wire_path, received, k, profile, approved, batch_id):
    """Controlled test flush; inspect approved USTAR prefix, never extract."""
    stream.flush()  # Visibility only: neither fsync nor crash durability proof.
    stored = wire_path.stat().st_size
    require(stored == received, 'wire counter differs from flushed file size')
    raw = k.read(wire_path, k.MAX_WIRE)
    require(len(raw) == stored, 'wire changed during observation')
    state = {'received_bytes': received, 'wire_bytes': stored,
             'flush_performed': True, 'durability': 'NOT_PROVEN',
             'payload_received_bytes': 0, 'payload_expected_bytes': None,
             'approved_wire_expected_bytes': None}
    if len(raw) < 512:
        return state
    first = tarfile.TarInfo.frombuf(raw[:512], 'ascii', 'strict')
    require(first.name == 'manifest.json' and first.type == tarfile.REGTYPE
            and raw[257:265] == b'ustar\x0000' and 0 <= first.size <= k.MAX_JSON,
            'invalid manifest header')
    if len(raw) < 512 + first.size:
        return state
    manifest = k.decode(raw[512:512 + first.size])
    k.manifest_check(manifest, profile, approved, batch_id)
    entries = [('manifest.json', first.size)] + [
        ('payload/' + row['staging_path'], row['size']) for row in manifest['files']]
    state['payload_expected_bytes'] = sum(row['size'] for row in manifest['files'])
    used = sum(512 + ((size + 511) // 512) * 512 for _, size in entries) + 1024
    state['approved_wire_expected_bytes'] = (
        (used + tarfile.RECORDSIZE - 1) // tarfile.RECORDSIZE * tarfile.RECORDSIZE)
    offset = 0
    for name, size in entries:
        if len(raw) < offset + 512:
            break
        header = raw[offset:offset + 512]
        item = tarfile.TarInfo.frombuf(header, 'ascii', 'strict')
        require(item.name == name and item.size == size and item.type == tarfile.REGTYPE
                and header[257:265] == b'ustar\x0000', 'invalid payload header')
        available = min(size, max(0, len(raw) - offset - 512))
        if name.startswith('payload/'):
            state['payload_received_bytes'] += available
        if available < size:
            break
        offset += 512 + ((size + 511) // 512) * 512
    return state


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--profile', required=True)
    parser.add_argument('--batch-id', required=True)
    parser.add_argument('--digest', required=True)
    parser.add_argument('--staging-root', required=True)
    parser.add_argument('--evidence-root', required=True)
    parser.add_argument('--reviewed-delivered-both-ends', action='store_true')
    parser.add_argument('--interrupt-worker', action='store_true', help=argparse.SUPPRESS)
    args = parser.parse_args()
    if not args.reviewed_delivered_both_ends:
        parser.error('reviewed delivery and exact-version verification at both ends required')
    evidence = Path(args.evidence_root)
    if args.interrupt_worker:
        import fof_kb_pull as k
        original_read = os.read
        original_popen = subprocess.Popen
        transport = []
        total = 0
        wire_path = (Path(args.staging_root).absolute() / os.environ['FOF_SMOKE_RUN_ID'] / 'wire.tar')
        original_open = Path.open
        wire_stream = []
        profile = k.profile(args.profile, True)
        def observed_open(path, *items, **options):
            stream = original_open(path, *items, **options)
            if path == wire_path and (items[0] if items else options.get('mode')) == 'xb':
                wire_stream.append(stream)  # The real receiver-owned buffered stream.
            return stream
        def observed_popen(*items, **options):
            child = original_popen(*items, **options)
            transport.append(child)
            return child
        def observed_read(fd, length):
            nonlocal total
            if total and transport and fd == transport[-1].stdout.fileno():
                # Barrier after at least one chunk was returned to receiver,
                # before its next transport read. Never substitute wire bytes.
                require(len(wire_stream) == 1, 'receiver wire stream not observed')
                state = observe_wire(wire_stream[0], wire_path, total, k, profile,
                                     args.digest, args.batch_id)
                record(evidence / 'interrupt-barrier.json', state)
                request = evidence / 'interrupt-request.json'
                while not request.exists():
                    time.sleep(0.05)
                expected = json.loads(request.read_text())['expected_wire_bytes']
                require(state['approved_wire_expected_bytes'] in (None, expected),
                        'supervisor wire size differs from approved manifest')
                payload_expected = state['payload_expected_bytes']
                partial = (0 < state['wire_bytes'] == total < expected
                           and payload_expected is not None
                           and 0 < state['payload_received_bytes'] < payload_expected)
                # Fresh liveness check immediately before self-interruption.
                live = transport[-1].poll() is None
                state.update({'ssh_pid': transport[-1].pid,
                    'ssh_live_at_interrupt_request': live,
                    'proven_in_progress': live and partial,
                    'interrupt_requested_at_utc': datetime.now(timezone.utc).isoformat()})
                record(evidence / 'interrupt-decision.json', state)
                # Recheck after publishing evidence, adjacent to signal delivery.
                if transport[-1].poll() is not None:
                    record(evidence / 'interrupt-decision.json', {
                        'proven_in_progress': False, 'reason': 'SSH_EXITED_BEFORE_SIGINT'})
                signal.raise_signal(signal.SIGINT)
                raise RuntimeError('SIGINT did not interrupt worker')
            data = original_read(fd, length)
            total += len(data)
            return data
        k.subprocess.Popen = observed_popen
        k.os.read = observed_read
        k.Path.open = observed_open
        try:
            k.pull(args.profile, args.batch_id, args.digest, args.staging_root,
                   os.environ['FOF_SMOKE_RUN_ID'], True)
        finally:
            k.Path.open = original_open
            k.os.read = original_read
            k.subprocess.Popen = original_popen
            record(evidence / 'interrupt-cleanup.json', {
                'ssh_exit': transport[-1].poll() if transport else None,
                'ssh_stopped': bool(transport) and transport[-1].poll() is not None})
        return
    evidence.mkdir(mode=0o700)  # New directory only: preserve every earlier run.
    script = Path(__file__).with_name('fof_kb_pull.py')
    base = [sys.executable, str(script), 'pull', '--synthetic-test',
            '--profile', args.profile, '--batch-id', args.batch_id,
            '--staging-root', args.staging_root]
    results = {}
    def execute(name, ident, digest):
        with (evidence / (name + '.log')).open('xb') as log:
            result = subprocess.run(base + ['--run-id', ident,
                '--approved-content-digest', digest], stdout=log, stderr=log, check=False)
        results[name] = {'exit': result.returncode, 'run_id': ident}
        record(evidence / 'results.json', results)
        return result.returncode
    RunId_POS = run_id()
    record(evidence / 'RunId_POS.json', {'RunId_POS': RunId_POS})
    positive_exit = execute('positive', RunId_POS, args.digest)
    require(positive_exit == 0, 'positive pull failed')
    positive = Path(args.staging_root) / RunId_POS
    receipt = json.loads((positive / 'VERIFIED.json').read_text())
    require(receipt['status'] == 'VERIFIED', 'positive receipt missing verification')
    results['local_verified'] = receipt['status']
    results['return_receipt_status'] = receipt['return_receipt_status']
    bad = ('0' if args.digest[0] != '0' else '1') + args.digest[1:]
    bad_id = run_id()
    bad_exit = execute('wrong-digest', bad_id, bad)
    require(bad_exit != 0, 'wrong digest unexpectedly accepted')
    require(not (Path(args.staging_root) / bad_id / 'VERIFIED.json').exists(),
            'wrong digest published VERIFIED')
    before = hashes(positive)
    record(evidence / 'collision-before.json', before)
    collision_exit = execute('collision', RunId_POS, args.digest)
    require(collision_exit != 0, 'run-id collision unexpectedly accepted')
    after = hashes(positive)
    record(evidence / 'collision-after.json', after)
    require(before == after, 'collision changed previous run')
    expected_size = (positive / 'wire.tar').stat().st_size
    interrupt_id = run_id()
    environment = os.environ.copy(); environment['FOF_SMOKE_RUN_ID'] = interrupt_id
    with (evidence / 'interrupt.log').open('xb') as log:
        child = subprocess.Popen([sys.executable, __file__, *sys.argv[1:],
                                  '--interrupt-worker'], env=environment, stdout=log, stderr=log)
        forced_cleanup = False
        worker_timeout = False
        try:
            deadline = time.monotonic() + 110
            marker = evidence / 'interrupt-barrier.json'
            while child.poll() is None and not marker.exists() and time.monotonic() < deadline:
                time.sleep(0.05)
            if child.poll() is None and marker.exists():
                record(evidence / 'interrupt-request.json', {'expected_wire_bytes': expected_size})
                try:
                    child.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    worker_timeout = True
        finally:
            if child.poll() is None:
                forced_cleanup = True
                child.send_signal(signal.SIGINT)
                try:
                    child.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    child.kill()
                    child.wait()
        code = child.returncode
    wire = Path(args.staging_root) / interrupt_id / 'wire.tar'
    decision_path = evidence / 'interrupt-decision.json'
    cleanup_path = evidence / 'interrupt-cleanup.json'
    state = json.loads(decision_path.read_text()) if decision_path.exists() else {}
    cleanup = json.loads(cleanup_path.read_text()) if cleanup_path.exists() else {}
    unverified_path = wire.parent / 'UNVERIFIED.json'
    unverified = json.loads(unverified_path.read_text()) if unverified_path.exists() else {}
    preserved = (wire.exists() and 0 < wire.stat().st_size < expected_size
                 and unverified.get('status') == 'UNVERIFIED'
                 and unverified.get('automatic_retry') is False
                 and not (wire.parent / 'VERIFIED.json').exists())
    proven = (state.get('proven_in_progress') is True and cleanup.get('ssh_stopped') is True
              and preserved and not forced_cleanup and code != 0)
    interrupted_with_proof = state.get('proven_in_progress') is True
    status = 'PASS' if proven else ('FAIL' if interrupted_with_proof else 'NOT_RUN')
    results['interruption'] = {'status': status,
        'exit': code, 'run_id': interrupt_id, 'evidence': state, 'cleanup': cleanup,
        'preserved_unverified': preserved, 'forced_cleanup': forced_cleanup,
        'worker_timeout': worker_timeout,
        'expected_wire_bytes': expected_size}
    record(evidence / 'results.json', results)
    print(json.dumps(results, sort_keys=True))


if __name__ == '__main__':
    main()
