"""`data4g doctor` — verify env + MCP configs + backend reachability.

One-line summary per check (✓ / ✗ / ⚠). Exits non-zero if any hard check
fails so CI can gate on it.
"""

from __future__ import annotations

import asyncio
import json
from dataclasses import dataclass
from pathlib import Path

import typer
from rich.console import Console

from ..mcp.client import BackendError, Data4gClient
from ..mcp.config import ConfigError, assert_key_not_in_tracked_files, load_config
from .init_cmd import (
    CLAUDE_REPO_CONFIG,
    CLAUDE_USER_CONFIG,
    CODEX_USER_CONFIG,
    CURSOR_REPO_CONFIG,
    CURSOR_USER_CONFIG,
    SERVER_NAME,
)

console = Console()


@dataclass
class CheckResult:
    name: str
    status: str  # "ok" | "warn" | "fail"
    detail: str = ""


def run_doctor(*, api_base_override: str | None) -> None:
    results: list[CheckResult] = []

    # ── Env ──────────────────────────────────────────────────
    try:
        config = load_config()
    except ConfigError as err:
        results.append(CheckResult("env: DATA4G_API_KEY / DATA4G_PROJECT_ID", "fail", str(err)))
        _render(results)
        raise typer.Exit(code=1)
    results.append(CheckResult(
        "env: DATA4G_API_KEY + DATA4G_PROJECT_ID", "ok",
        f"key {config.redacted_key}, project {config.project_id}",
    ))

    # ── Git leak guard ───────────────────────────────────────
    try:
        assert_key_not_in_tracked_files(config.api_key, cwd=Path.cwd())
        results.append(CheckResult("git leak guard", "ok", "key is not in any tracked file"))
    except ConfigError as err:
        results.append(CheckResult("git leak guard", "fail", str(err)))

    # ── MCP configs ──────────────────────────────────────────
    for name, path in _config_targets():
        if not path.exists():
            results.append(CheckResult(f"mcp config: {name}", "warn", f"not present at {path}"))
            continue
        ok, detail = _inspect_config(path)
        results.append(CheckResult(
            f"mcp config: {name} ({path})",
            "ok" if ok else "warn",
            detail,
        ))

    # ── Backend reach + key validity ─────────────────────────
    api_base = (api_base_override or config.api_base).rstrip("/")
    if api_base_override:
        # load_config already normalised; mutate via a fresh Config for the call
        config = config.__class__(
            api_key=config.api_key,
            project_id=config.project_id,
            api_base=api_base,
            http_timeout=config.http_timeout,
            skip_leak_guard=config.skip_leak_guard,
        )
    try:
        verify = asyncio.run(_verify_backend(config))
    except BackendError as err:
        results.append(CheckResult(
            "backend /keys/verify", "fail",
            f"{err.status_code}: {err.detail}",
        ))
    except Exception as err:  # network / DNS / TLS
        results.append(CheckResult("backend /keys/verify", "fail", f"unreachable: {err}"))
    else:
        results.append(CheckResult(
            "backend /keys/verify", "ok",
            f"label={verify.get('label')!r} at {api_base}",
        ))

    _render(results)
    if any(r.status == "fail" for r in results):
        raise typer.Exit(code=1)


async def _verify_backend(config) -> dict:
    async with Data4gClient(config) as client:
        return await client.verify_key()


def _config_targets() -> list[tuple[str, Path]]:
    cwd = Path.cwd()
    return [
        ("Claude Code (repo)", cwd / CLAUDE_REPO_CONFIG),
        ("Claude Code (user)", CLAUDE_USER_CONFIG),
        ("Cursor (repo)", cwd / CURSOR_REPO_CONFIG),
        ("Cursor (user)", CURSOR_USER_CONFIG),
        ("Codex (user)", CODEX_USER_CONFIG),
    ]


def _inspect_config(path: Path) -> tuple[bool, str]:
    try:
        text = path.read_text()
    except OSError as err:
        return False, f"unreadable: {err}"
    if path.suffix == ".toml":
        # Cheap substring check rather than full TOML parse — good enough
        # for a diagnostic.
        return (SERVER_NAME in text, "entry present" if SERVER_NAME in text else "entry missing")
    try:
        data = json.loads(text or "{}")
    except json.JSONDecodeError as err:
        return False, f"invalid JSON: {err}"
    servers = data.get("mcpServers") or {}
    if SERVER_NAME not in servers:
        return False, f"no server named {SERVER_NAME!r}"
    entry = servers[SERVER_NAME]
    command = entry.get("command", "")
    if command != "data4g-mcp":
        return False, f"unexpected command: {command!r}"
    env = entry.get("env") or {}
    if "DATA4G_API_KEY" in env:
        return False, "API key literal in config file (should come from shell env)"
    if "DATA4G_PROJECT_ID" not in env:
        return False, "missing DATA4G_PROJECT_ID in env"
    return True, "entry valid; project id present; no key literal"


def _render(results: list[CheckResult]) -> None:
    icon = {"ok": "[green]✓[/green]", "warn": "[yellow]⚠[/yellow]", "fail": "[red]✗[/red]"}
    for r in results:
        console.print(f"  {icon[r.status]} {r.name}", end="")
        if r.detail:
            console.print(f"  — {r.detail}")
        else:
            console.print()
