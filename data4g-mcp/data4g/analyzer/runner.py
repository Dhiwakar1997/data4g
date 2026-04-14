"""Entry point: walk a directory, run each analyzer + detector, return an
`AnalyzerResult` the agent can accept, override, or enrich before calling
`register_*`.

Intentionally conservative:

- Hard cap of 2 MB / file and 5000 files per run to keep local latency sane.
- Skip common vendored directories (``node_modules``, ``.venv``, ``build``,
  ``__pycache__``, ``.git``) without making it configurable in v1.
"""

from __future__ import annotations

from pathlib import Path

from ..schemas import AnalyzerResult
from .analyzers import ANALYZERS
from .detectors import DETECTORS

_SKIP_DIRS = {
    ".git", ".hg", ".svn",
    "node_modules", ".venv", "venv", "env",
    "__pycache__", ".mypy_cache", ".ruff_cache", ".pytest_cache",
    "dist", "build", "target", ".next", ".nuxt",
}
_MAX_FILE_BYTES = 2_000_000
_MAX_FILES = 5_000


def run_static_analysis(root: str | Path) -> AnalyzerResult:
    """Walk ``root`` and return aggregated analyzer + detector output."""
    root_path = Path(root).expanduser().resolve()
    if not root_path.exists() or not root_path.is_dir():
        raise FileNotFoundError(f"Analysis root does not exist: {root_path}")

    result = AnalyzerResult()
    seen = 0

    for path in _iter_files(root_path):
        if seen >= _MAX_FILES:
            result.notes.append(
                f"Analyzer stopped at {_MAX_FILES} files; rerun on a subdirectory "
                "for a complete scan."
            )
            break
        seen += 1

        try:
            source = _read_text(path)
        except OSError:
            continue
        if source is None:
            continue

        rel_path = path.relative_to(root_path)
        for analyzer in ANALYZERS:
            if not analyzer.wants(path):
                continue
            try:
                endpoints, entities = analyzer.analyze_file(rel_path, source)
            except Exception as err:  # analyzer bugs must never abort the run
                result.notes.append(f"{analyzer.__class__.__name__} failed on {rel_path}: {err}")
                continue
            result.endpoints.extend(endpoints)
            result.entities.extend(entities)

        for detector in DETECTORS:
            try:
                result.risks.extend(detector.inspect(rel_path, source))
            except Exception as err:
                result.notes.append(f"{detector.__class__.__name__} failed on {rel_path}: {err}")

    return result


def _iter_files(root: Path):
    for path in root.rglob("*"):
        if path.is_dir():
            if path.name in _SKIP_DIRS:
                # rglob doesn't respect prune; skip children by checking ancestors
                continue
            continue
        if any(part in _SKIP_DIRS for part in path.parts):
            continue
        if not path.is_file():
            continue
        yield path


def _read_text(path: Path) -> str | None:
    try:
        size = path.stat().st_size
    except OSError:
        return None
    if size > _MAX_FILE_BYTES:
        return None
    try:
        return path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return None
