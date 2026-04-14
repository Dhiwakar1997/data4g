"""Optional local analyzer tool.

Exposes the deterministic walker as an MCP tool so the agent can cheaply
get a first pass over a large repo instead of reading every file. Purely
additive — the agent can skip this and register everything itself.
"""

from __future__ import annotations

from pathlib import Path
from typing import TYPE_CHECKING, Any

from ...analyzer import run_static_analysis

if TYPE_CHECKING:
    from mcp.server.fastmcp import FastMCP

    from ..server import ServerContext


def register(mcp: "FastMCP", _ctx: "ServerContext") -> None:
    @mcp.tool()
    async def run_static_analysis_tool(path: str = ".") -> dict[str, Any]:
        """Run the deterministic analyzer over `path` (default: CWD).

        Returns `{ endpoints, entities, services, risks, notes }`. The agent
        should treat this as a starting point, not a verdict — enrich each
        entry with `semantic_description` and project-specific context
        before calling `register_*`.
        """
        try:
            result = run_static_analysis(Path(path))
        except FileNotFoundError as err:
            return {"error": {"status_code": 404, "detail": str(err)}}
        return result.model_dump(mode="json")
