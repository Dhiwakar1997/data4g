"""Runtime config for the local MCP server.

Single source of truth is the process environment:

- `DATA4G_API_KEY`        — project-scoped key (required; never written to disk)
- `DATA4G_PROJECT_ID`     — project id the key is bound to (required)
- `DATA4G_API_BASE`       — backend base URL; default `https://api.data4g.io/api/v1`
- `DATA4G_HTTP_TIMEOUT`   — seconds for HTTP calls (default 20)
- `DATA4G_SKIP_LEAK_GUARD`— set to `1` to skip the git-tracked-file leak check
                            (emergency escape hatch only)
"""

from __future__ import annotations

import os
import subprocess
from dataclasses import dataclass
from pathlib import Path


class ConfigError(RuntimeError):
    """Raised on missing or invalid env config.

    The MCP server surfaces this as a structured error back to the agent,
    which then tells the user to set up their shell.
    """


@dataclass(frozen=True)
class Config:
    api_key: str
    project_id: str
    api_base: str
    http_timeout: float
    skip_leak_guard: bool

    @property
    def redacted_key(self) -> str:
        return f"d4g_...{self.api_key[-4:]}" if len(self.api_key) >= 4 else "d4g_..."


DEFAULT_API_BASE = "https://api.data4g.io/api/v1"


def load_config() -> Config:
    api_key = os.environ.get("DATA4G_API_KEY", "").strip()
    project_id = os.environ.get("DATA4G_PROJECT_ID", "").strip()

    missing: list[str] = []
    if not api_key:
        missing.append("DATA4G_API_KEY")
    if not project_id:
        missing.append("DATA4G_PROJECT_ID")
    if missing:
        raise ConfigError(
            f"Missing required env var(s): {', '.join(missing)}. "
            "See https://data4g.io/docs/setup."
        )

    try:
        timeout = float(os.environ.get("DATA4G_HTTP_TIMEOUT", "20"))
    except ValueError as err:
        raise ConfigError(f"DATA4G_HTTP_TIMEOUT must be numeric: {err}") from err

    return Config(
        api_key=api_key,
        project_id=project_id,
        api_base=os.environ.get("DATA4G_API_BASE", DEFAULT_API_BASE).rstrip("/"),
        http_timeout=timeout,
        skip_leak_guard=os.environ.get("DATA4G_SKIP_LEAK_GUARD") == "1",
    )


def assert_key_not_in_tracked_files(api_key: str, cwd: Path | None = None) -> None:
    """Refuse to run if the plaintext key lives in a git-tracked file.

    Cheap, catches the #1 foot-gun (committed `.env`). Skipped if the CWD
    isn't a git repo, if `git` isn't on PATH, or if the user explicitly
    opted out via `DATA4G_SKIP_LEAK_GUARD=1`.
    """
    cwd = cwd or Path.cwd()
    try:
        result = subprocess.run(
            ["git", "ls-files", "-z"],
            cwd=cwd,
            capture_output=True,
            check=False,
            timeout=10,
        )
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return
    if result.returncode != 0:
        return

    for raw in result.stdout.split(b"\x00"):
        if not raw:
            continue
        try:
            path = cwd / raw.decode()
        except UnicodeDecodeError:
            continue
        if not path.is_file():
            continue
        try:
            with path.open("rb") as fh:
                blob = fh.read(2_000_000)  # 2 MB cap per file
        except OSError:
            continue
        if api_key.encode() in blob:
            raise ConfigError(
                f"DATA4G_API_KEY value appears in tracked file {path.relative_to(cwd)}. "
                "Remove it from git, rotate the key, then retry. "
                "Set DATA4G_SKIP_LEAK_GUARD=1 to bypass (not recommended)."
            )
