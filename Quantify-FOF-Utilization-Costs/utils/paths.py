from __future__ import annotations

import os
from pathlib import Path


def get_output_root(project_root: Path) -> Path:
    """Resolve output root from OUTPUT_DIR env or default to <project_root>/outputs."""
    output_root_env = os.getenv("OUTPUT_DIR")
    return Path(output_root_env) if output_root_env else project_root / "outputs"
