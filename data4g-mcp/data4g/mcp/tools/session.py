"""Session lifecycle tools: start, get, finalize, abort."""

from __future__ import annotations

from typing import TYPE_CHECKING, Any

from ..client import BackendError

if TYPE_CHECKING:
    from mcp.server.fastmcp import FastMCP

    from ..server import ServerContext


def register(mcp: "FastMCP", ctx: "ServerContext") -> None:
    @mcp.tool()
    async def start_sync(note: str | None = None) -> dict[str, Any]:
        """Open a new scan session. Returns `{ sync_id, state, expires_at, ... }`.

        The session is a staging area — nothing commits to the live
        topology until `finalize_sync`. Sessions auto-expire after 2h.
        """
        try:
            return await ctx.client.start_session(note=note)
        except BackendError as err:
            return _error(err)

    @mcp.tool()
    async def get_session(sync_id: str) -> dict[str, Any]:
        """Read-after-write: return the current state of a session (counts
        per artefact type, expiry, state: active | finalized | aborted | expired).
        """
        try:
            return await ctx.client.get_session(sync_id)
        except BackendError as err:
            return _error(err)

    @mcp.tool()
    async def finalize_sync(sync_id: str) -> dict[str, Any]:
        """Atomically commit the staged session into the live topology.

        Returns a diff summary: endpoints_added, entities_added, risks_added,
        and a `topology_url` for the updated live view. After this call the
        session is sealed — further writes will 409.
        """
        try:
            return await ctx.client.finalize_session(sync_id)
        except BackendError as err:
            return _error(err)

    @mcp.tool()
    async def abort_sync(sync_id: str) -> dict[str, Any]:
        """Discard all staged data for this session. No live-topology impact."""
        try:
            return await ctx.client.abort_session(sync_id)
        except BackendError as err:
            return _error(err)


def _error(err: BackendError) -> dict[str, Any]:
    return {
        "error": {
            "status_code": err.status_code,
            "detail": err.detail,
        }
    }
