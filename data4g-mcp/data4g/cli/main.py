"""`data4g` CLI entry point (Typer).

Subcommands:

- ``init``   — write MCP configs for detected IDEs in the current repo
- ``doctor`` — validate env, configs, git leak, and backend reachability
- ``health`` — minimal scriptable backend ping (exit code + optional JSON)
- ``--version`` — print package version and exit
"""

from __future__ import annotations

import typer

from .. import __version__
from .doctor import run_doctor
from .health import run_health
from .init_cmd import run_init

app = typer.Typer(
    add_completion=False,
    help="Data4G setup CLI. Use `data4g init` once per repo, then run your AI agent.",
    no_args_is_help=True,
)


def _version_cb(value: bool) -> None:
    if value:
        typer.echo(f"data4g {__version__}")
        raise typer.Exit(code=0)


@app.callback()
def root(
    version: bool = typer.Option(
        False, "--version", callback=_version_cb, is_eager=True,
        help="Show version and exit.",
    ),
) -> None:
    """Root callback — just the global --version flag."""


@app.command("init")
def init(
    project_id: str | None = typer.Option(
        None, "--project-id", "-p",
        help="Data4G project id. Defaults to $DATA4G_PROJECT_ID.",
    ),
    ide: list[str] | None = typer.Option(
        None, "--ide",
        help="Force-enable specific agents (claude, cursor, codex). Auto-detect if omitted.",
    ),
    force: bool = typer.Option(False, "--force", help="Overwrite existing entries."),
) -> None:
    """Write MCP configs for detected AI agents in the current repo."""
    run_init(project_id=project_id, requested_ides=ide, force=force)


@app.command("doctor")
def doctor(
    api_base: str | None = typer.Option(
        None, "--api-base",
        help="Override the backend base URL just for this check.",
    ),
) -> None:
    """Diagnose env, MCP configs, git leak guard, and backend reachability."""
    run_doctor(api_base_override=api_base)


@app.command("health")
def health(
    api_base: str | None = typer.Option(
        None, "--api-base",
        help="Override the backend base URL just for this check.",
    ),
    as_json: bool = typer.Option(
        False, "--json",
        help="Emit machine-readable JSON (handy for CI / monitoring).",
    ),
) -> None:
    """Ping the backend with the current API key. Exit 0 if healthy, non-zero otherwise."""
    run_health(api_base_override=api_base, as_json=as_json)


if __name__ == "__main__":
    app()
