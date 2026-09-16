#!/usr/bin/env python3
"""Trusted binary stdio bridge for FOF_ARTIFACT_HANDOFF/2; never selects files."""
import argparse
import base64
import os
import re
import sys


def command(environ, check=False):
    alias = environ.get("FOF_V2_SSH_ALIAS", "")
    receiver = environ.get("FOF_V2_RECEIVER_SCRIPT", "")
    session = environ.get("FOF_V2_SMOKE_SESSION", "")
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_.-]{0,127}", alias):
        raise ValueError("FOF_V2_SSH_ALIAS_REQUIRED_OR_INVALID")
    # Deliberately narrow Windows drive/forward-slash contract, not shell syntax.
    if not re.fullmatch(r"[A-Za-z]:/(?:[A-Za-z0-9_. -]+/)+receive_artifact_bundle\.ps1", receiver):
        raise ValueError("FOF_V2_RECEIVER_SCRIPT_INVALID")
    parts = receiver[3:].split("/")
    if len(parts) < 3 or parts[-2] != "scripts":
        raise ValueError("FOF_V2_RECEIVER_INSTALLATION_REQUIRED")
    for part in parts:
        if (part in (".", "..") or part != part.strip() or part.endswith(".")
                or re.fullmatch(r"(?i:con|prn|aux|nul|com[0-9]|lpt[0-9])(?:\..*)?", part)):
            raise ValueError("FOF_V2_RECEIVER_PATH_AMBIGUOUS")
    if session and not re.fullmatch(r"[0-9a-f]{32}", session):
        raise ValueError("FOF_V2_SMOKE_SESSION_INVALID")
    # The encoded command contains only a validated literal path/session. No payload.
    if check:
        script = ("$ErrorActionPreference='Stop'; "
                  "if ($PSVersionTable.PSVersion -lt [version]'7.4') { exit 2 }; "
                  "[void][System.Formats.Tar.TarReader]; "
                  "if (-not (Test-Path -LiteralPath '" + receiver + "' -PathType Leaf)) { exit 2 }; "
                  "[Console]::Error.WriteLine('FOF_V2_SSH_PREFLIGHT_OK'); exit 0")
    else:
        script = "& '" + receiver + "'"
        if session:
            script += " -SmokeTest -SmokeSession '" + session + "'"
        script += "; exit $LASTEXITCODE"
    encoded = base64.b64encode(script.encode("utf-16le")).decode("ascii")
    return ["ssh", "-T", "-o", "BatchMode=yes", "-o", "StrictHostKeyChecking=yes",
            "-o", "ConnectionAttempts=1", "-o", "ConnectTimeout=10",
            "-o", "ClearAllForwardings=yes", "-o", "PermitLocalCommand=no",
            alias, "pwsh -NoLogo -NoProfile -NonInteractive -EncodedCommand " + encoded]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="SSH/runtime check only; no artifact stdin")
    args = parser.parse_args()
    try:
        argv = command(os.environ, args.check)
        if args.check:
            fd = os.open(os.devnull, os.O_RDONLY)
            os.dup2(fd, 0)
            os.close(fd)
        # No stream reads, pipes, JSON rewriting, retry, or child left after timeout.
        os.execvp(argv[0], argv)
    except (ValueError, OSError) as exc:
        message = str(exc) if isinstance(exc, ValueError) else "SSH_EXEC_UNAVAILABLE"
        print("FOF_V2_ADAPTER: " + message, file=sys.stderr)
        return 255  # No invented correlated FAILED receipt: sender remains UNKNOWN.


if __name__ == "__main__":
    sys.exit(main())
