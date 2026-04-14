"""`data4g health` — lean, scriptable backend ping.

Distinct from `doctor` (which inspects env, configs, git leak guard, and
backend reachability in a human-readable report). `health` is a minimal
check aimed at CI, cron, and shell scripts: hit `/keys/verify`, return
exit 0 on success, non-zero on failure, and optionally emit JSON.
"""

from __future__ import annotations

import asyncio
import json
import time

import typer
from rich.console import Console

from ..mcp.client import BackendError, Data4gClient
from ..mcp.config import ConfigError, load_config

console = Console()


def run_health(*, api_base_override: str | None, as_json: bool) -> None:
    started = time.monotonic()
    try:
        config = load_config()
    except ConfigError as err:
        _emit(
            {"status": "fail", "stage": "env", "detail": str(err)},
            as_json=as_json,
            ok=False,
        )
        raise typer.Exit(code=2)

    if api_base_override:
        config = config.__class__(
            api_key=config.api_key,
            project_id=config.project_id,
            api_base=api_base_override.rstrip("/"),
            http_timeout=config.http_timeout,
            skip_leak_guard=config.skip_leak_guard,
        )

    try:
        verify = asyncio.run(_verify(config))
    except BackendError as err:
        _emit(
            {
                "status": "fail",
                "stage": "backend",
                "status_code": err.status_code,
                "detail": err.detail,
                "api_base": config.api_base,
            },
            as_json=as_json,
            ok=False,
        )
        raise typer.Exit(code=1)
    except Exception as err:  # network / DNS / TLS
        _emit(
            {
                "status": "fail",
                "stage": "network",
                "detail": f"{type(err).__name__}: {err}",
                "api_base": config.api_base,
            },
            as_json=as_json,
            ok=False,
        )
        raise typer.Exit(code=1)

    latency_ms = round((time.monotonic() - started) * 1000, 1)
    _emit(
        {
            "status": "ok",
            "api_base": config.api_base,
            "project_id": config.project_id,
            "key_label": verify.get("label"),
            "latency_ms": latency_ms,
        },
        as_json=as_json,
        ok=True,
    )


async def _verify(config) -> dict:
    async with Data4gClient(config) as client:
        return await client.verify_key()


def _emit(payload: dict, *, as_json: bool, ok: bool) -> None:
    if as_json:
        console.print_json(data=payload)
        return
    if ok:
        console.print(
            f"[green]✓[/green] data4g healthy "
            f"— {payload['api_base']} "
            f"(key={payload['key_label']!r}, {payload['latency_ms']}ms)"
        )
    else:
        stage = payload.get("stage", "?")
        detail = payload.get("detail", "")
        console.print(f"[red]✗[/red] data4g unhealthy at [bold]{stage}[/bold] — {detail}")
