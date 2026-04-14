"""`data4g init` — write MCP server entries for each detected AI agent.

Design rule: configs NEVER contain the literal API key. They rely on shell
env inheritance; the MCP server reads `DATA4G_API_KEY` from the environment
at spawn time.
"""

from __future__ import annotations

import json
import os
from pathlib import Path
from typing import Iterable

import tomli_w
import typer
from rich.console import Console

console = Console()

SERVER_NAME = "data4g"

# ── Config locations per agent ────────────────────────────────────

CLAUDE_REPO_CONFIG = ".mcp.json"
CLAUDE_USER_CONFIG = Path.home() / ".claude.json"
CURSOR_REPO_CONFIG = ".cursor/mcp.json"
CURSOR_USER_CONFIG = Path.home() / ".cursor" / "mcp.json"
CODEX_USER_CONFIG = Path.home() / ".codex" / "config.toml"

KNOWN_IDES = ("claude", "cursor", "codex")


def run_init(
    *,
    project_id: str | None,
    requested_ides: Iterable[str] | None,
    force: bool,
) -> None:
    resolved_project_id = project_id or os.environ.get("DATA4G_PROJECT_ID")
    if not resolved_project_id:
        resolved_project_id = typer.prompt(
            "Data4G project id (set $DATA4G_PROJECT_ID to skip this prompt)"
        ).strip()
    if not resolved_project_id:
        console.print("[red]project id is required[/red]")
        raise typer.Exit(code=1)

    targets = _resolve_targets(requested_ides)
    if not targets:
        console.print(
            "[yellow]No supported AI agents detected.[/yellow] "
            "Printing a generic MCP config you can paste in:"
        )
        console.print_json(data=_generic_config(resolved_project_id))
        return

    cwd = Path.cwd()
    repo_gitignore = cwd / ".gitignore"
    _ensure_env_ignored(repo_gitignore)

    for ide in targets:
        if ide == "claude":
            _write_claude(cwd, resolved_project_id, force)
        elif ide == "cursor":
            _write_cursor(cwd, resolved_project_id, force)
        elif ide == "codex":
            _write_codex(resolved_project_id, force)

    console.print()
    console.print("[bold green]Done.[/bold green] Next steps:")
    console.print(
        "  1. Export [cyan]DATA4G_API_KEY=d4g_...[/cyan] in the shell that "
        "launches your AI agent (shell profile, direnv, or per-session)."
    )
    console.print("  2. Restart your agent so it picks up the MCP config.")
    console.print(
        "  3. Ask the agent: [italic]\"sync this repo to Data4G.\"[/italic]"
    )
    console.print()
    console.print(
        "Run [cyan]data4g doctor[/cyan] any time to verify the whole chain."
    )


# ── Target detection ─────────────────────────────────────────────


def _resolve_targets(requested: Iterable[str] | None) -> list[str]:
    if requested:
        requested_set = {name.lower() for name in requested}
        unknown = requested_set - set(KNOWN_IDES)
        if unknown:
            raise typer.BadParameter(
                f"Unknown --ide values: {', '.join(sorted(unknown))}. "
                f"Known: {', '.join(KNOWN_IDES)}."
            )
        return [ide for ide in KNOWN_IDES if ide in requested_set]

    detected: list[str] = []
    cwd = Path.cwd()
    if (cwd / CLAUDE_REPO_CONFIG).exists() or CLAUDE_USER_CONFIG.exists():
        detected.append("claude")
    if (cwd / CURSOR_REPO_CONFIG).exists() or CURSOR_USER_CONFIG.exists():
        detected.append("cursor")
    if CODEX_USER_CONFIG.exists():
        detected.append("codex")
    # If we can't detect anything, configure Claude Code by default — it's the
    # most common entry-point and creating `.mcp.json` is harmless.
    if not detected:
        detected.append("claude")
    return detected


# ── Writers per agent ────────────────────────────────────────────


def _server_entry(project_id: str) -> dict:
    return {
        "command": "data4g-mcp",
        "env": {"DATA4G_PROJECT_ID": project_id},
    }


def _write_claude(cwd: Path, project_id: str, force: bool) -> None:
    path = cwd / CLAUDE_REPO_CONFIG
    _upsert_json(path, "mcpServers", SERVER_NAME, _server_entry(project_id), force)
    console.print(f"  ✓ wrote Claude Code MCP entry to [cyan]{path}[/cyan]")


def _write_cursor(cwd: Path, project_id: str, force: bool) -> None:
    path = cwd / CURSOR_REPO_CONFIG
    path.parent.mkdir(parents=True, exist_ok=True)
    _upsert_json(path, "mcpServers", SERVER_NAME, _server_entry(project_id), force)
    console.print(f"  ✓ wrote Cursor MCP entry to [cyan]{path}[/cyan]")


def _write_codex(project_id: str, force: bool) -> None:
    path = CODEX_USER_CONFIG
    path.parent.mkdir(parents=True, exist_ok=True)
    existing: dict = {}
    if path.exists():
        try:
            import tomllib  # py311+
            existing = tomllib.loads(path.read_text())
        except Exception:
            existing = {}
    servers = existing.setdefault("mcp_servers", {})
    if SERVER_NAME in servers and not force:
        console.print(
            f"  [yellow]⚠[/yellow] Codex already has an entry named [bold]{SERVER_NAME}[/bold]; "
            f"rerun with --force to overwrite ([cyan]{path}[/cyan])."
        )
        return
    servers[SERVER_NAME] = {
        "command": "data4g-mcp",
        "env": {"DATA4G_PROJECT_ID": project_id},
    }
    path.write_bytes(tomli_w.dumps(existing).encode())
    console.print(f"  ✓ wrote Codex MCP entry to [cyan]{path}[/cyan]")


def _upsert_json(path: Path, root_key: str, name: str, entry: dict, force: bool) -> None:
    data: dict = {}
    if path.exists():
        try:
            data = json.loads(path.read_text() or "{}")
        except json.JSONDecodeError:
            console.print(f"  [yellow]⚠[/yellow] {path} is not valid JSON; overwriting.")
    servers = data.setdefault(root_key, {})
    if name in servers and not force:
        console.print(
            f"  [yellow]⚠[/yellow] {path} already has [bold]{name}[/bold]; "
            "rerun with --force to overwrite."
        )
        return
    servers[name] = entry
    path.write_text(json.dumps(data, indent=2) + "\n")


def _generic_config(project_id: str) -> dict:
    return {"mcpServers": {SERVER_NAME: _server_entry(project_id)}}


def _ensure_env_ignored(gitignore: Path) -> None:
    patterns = {".env", ".env.*"}
    existing: set[str] = set()
    if gitignore.exists():
        existing = {line.strip() for line in gitignore.read_text().splitlines() if line.strip()}
    missing = patterns - existing
    if not missing:
        return
    # Append; never rewrite the user's file wholesale.
    with gitignore.open("a", encoding="utf-8") as fh:
        if gitignore.exists() and gitignore.stat().st_size > 0:
            fh.write("\n# Added by `data4g init` — keep API keys out of git\n")
        for pattern in sorted(missing):
            fh.write(f"{pattern}\n")
