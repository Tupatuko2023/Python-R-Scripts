#!/usr/bin/env python3
from __future__ import annotations

import os
from pathlib import Path
from typing import Dict, Optional

try:
    # Package execution
    from ._io_utils import safe_join_path
except ImportError:
    # Script / repo-root execution
    from _io_utils import safe_join_path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
CONFIG_DIR = PROJECT_ROOT / "config"
ENV_FILE = CONFIG_DIR / ".env"
SAMPLE_DIR = PROJECT_ROOT / "data" / "sample"


def _parse_dotenv(path: Path) -> Dict[str, str]:
    out: Dict[str, str] = {}
    if not path.exists():
        return out
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if "=" not in line:
            continue
        k, v = line.split("=", 1)
        out[k.strip()] = v.strip().strip('"').strip("'")
    return out


def _validate_absolute(p: Path) -> Path:
    # Termux + PRoot can resolve ~ differently; require absolute paths to avoid ambiguity.
    if not p.is_absolute():
        raise SystemExit(
            "DATA_ROOT must be an absolute path (Termux/PRoot-safe). "
            "Update Quantify-FOF-Utilization-Costs/config/.env (from .env.example) "
            "and set DATA_ROOT to an absolute secure location."
        )
    return p


def get_data_root(require: bool = False) -> Optional[Path]:
    """Return DATA_ROOT if set (env var or config/.env)."""
    env = os.environ.get("DATA_ROOT")
    if env:
        return _validate_absolute(Path(env).expanduser())

    cfg = _parse_dotenv(ENV_FILE)
    if cfg.get("DATA_ROOT"):
        return _validate_absolute(Path(cfg["DATA_ROOT"]).expanduser())

    if require:
        raise SystemExit(
            "DATA_ROOT is not set. Create Quantify-FOF-Utilization-Costs/config/.env from "
            ".env.example and set DATA_ROOT to your secure repo-external data location."
        )
    return None


def safe_join_path(base: Path, relative: str) -> Path:
    """
    Safely joins a base directory with a relative path string.
    Raises ValueError if the resulting path is outside the base directory.
    """
    base_abs = base.resolve()
    target = (base_abs / relative).resolve()
    if not str(target).startswith(str(base_abs)):
        raise ValueError("Security Violation: Path traversal detected.")
    return target


def get_paper02_dir(data_root: Path) -> Path:
    cfg = _parse_dotenv(ENV_FILE)
    rel = cfg.get("PAPER_02_DIR", "paper_02")
    return safe_join_path(data_root, rel)
