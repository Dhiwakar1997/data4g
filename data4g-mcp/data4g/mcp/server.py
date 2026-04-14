"""stdio MCP server for Data4G.

Spawned by the user's AI agent via the MCP config written by `data4g init`.
Exposes fine-grained tools the agent composes to sync a repo: `start_sync`,
optional `run_static_analysis`, a batch of `register_*` calls, then
`finalize_sync`.

Boot sequence:
1. Load config from env (fails fast with a structured error the agent
   surfaces to the user if `DATA4G_API_KEY` / `DATA4G_PROJECT_ID` missing).
2. Scan the CWD's git index to make sure the API key isn't accidentally
   committed — refuse to run if it is.
3. Register tools against a shared `Data4gClient` and drive the stdio loop.
"""

from __future__ import annotations

import asyncio
import sys
from contextlib import asynccontextmanager
from dataclasses import dataclass
from pathlib import Path

from mcp.server.fastmcp import FastMCP

from .client import BackendError, Data4gClient
from .config import Config, ConfigError, assert_key_not_in_tracked_files, load_config
from .tools import register_all_tools


@dataclass
class ServerContext:
    """Shared state for every tool call in one server lifetime."""

    config: Config
    client: Data4gClient


def _build_server(config: Config) -> tuple[FastMCP, ServerContext]:
    client = Data4gClient(config)
    context = ServerContext(config=config, client=client)

    @asynccontextmanager
    async def lifespan(_app: FastMCP):
        # Open the HTTP client for the process lifetime.
        await client.__aenter__()
        try:
            yield context
        finally:
            await client.__aexit__(None, None, None)

    mcp = FastMCP(
        name="data4g",
        instructions=(
            "Sync this repository's topology to Data4G. Start with "
            "`start_sync`, then either call `run_static_analysis` for a "
            "first pass or register endpoints/entities/services/risks "
            "directly. Always finish with `finalize_sync` — the server "
            "keeps nothing committed until then. All tools require a live "
            "`sync_id`; the backend rejects stale ones after 2h."
        ),
        lifespan=lifespan,
    )
    register_all_tools(mcp, context)
    return mcp, context


def _startup_checks(config: Config, cwd: Path) -> None:
    if config.skip_leak_guard:
        return
    assert_key_not_in_tracked_files(config.api_key, cwd=cwd)


def main() -> None:
    """CLI entry point for the `data4g-mcp` console script."""
    try:
        config = load_config()
        _startup_checks(config, cwd=Path.cwd())
    except ConfigError as err:
        # Write to stderr so the hosting agent shows the error to the user.
        sys.stderr.write(f"[data4g-mcp] {err}\n")
        sys.exit(2)
    except BackendError as err:
        sys.stderr.write(f"[data4g-mcp] backend error during startup: {err}\n")
        sys.exit(3)

    mcp, _ = _build_server(config)
    try:
        asyncio.run(mcp.run_stdio_async())
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
