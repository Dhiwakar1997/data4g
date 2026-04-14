"""Registration tools — one per artefact type.

Each tool validates its payload against the shared Pydantic schema before
forwarding to the backend, so malformed calls return a structured error the
agent can recover from instead of leaking an opaque 422.
"""

from __future__ import annotations

from typing import TYPE_CHECKING, Any

from pydantic import ValidationError

from ...schemas import (
    ScanRegisterEndpoint,
    ScanRegisterEntity,
    ScanRegisterNote,
    ScanRegisterRisk,
    ScanRegisterService,
)
from ..client import BackendError

if TYPE_CHECKING:
    from mcp.server.fastmcp import FastMCP

    from ..server import ServerContext


def register(mcp: "FastMCP", ctx: "ServerContext") -> None:
    @mcp.tool()
    async def register_endpoint(
        sync_id: str,
        method: str,
        path: str,
        handler_file: str,
        semantic_description: str,
        handler_line: int | None = None,
        framework: str | None = None,
        auth_required: bool | None = None,
        is_hot_path: bool | None = None,
        notes: str | None = None,
    ) -> dict[str, Any]:
        """Stage an endpoint for this session.

        Idempotent on `(method, path)` within a session — re-registering
        updates in place. `semantic_description` is the highest-signal
        field: business purpose, not just what the code does.
        """
        return await _run(ScanRegisterEndpoint, ctx.client.register_endpoint, sync_id, locals())

    @mcp.tool()
    async def register_entity(
        sync_id: str,
        name: str,
        file: str,
        semantic_description: str,
        fields: list[dict] | None = None,
        pii_fields: list[str] | None = None,
    ) -> dict[str, Any]:
        """Stage a data entity (DB model / schema)."""
        return await _run(ScanRegisterEntity, ctx.client.register_entity, sync_id, locals())

    @mcp.tool()
    async def register_service(
        sync_id: str,
        name: str,
        type: str,
        semantic_description: str,
        depends_on: list[str] | None = None,
    ) -> dict[str, Any]:
        """Stage a service (api, worker, cron, third-party…)."""
        return await _run(ScanRegisterService, ctx.client.register_service, sync_id, locals())

    @mcp.tool()
    async def register_risk(
        sync_id: str,
        type: str,
        severity: str,
        location: str,
        description: str,
        suggested_fix: str = "",
        confidence: float = 1.0,
    ) -> dict[str, Any]:
        """Stage a risk finding. `type` and `severity` are closed vocabularies —
        see `ScanRegisterRisk` for accepted values.
        """
        return await _run(ScanRegisterRisk, ctx.client.register_risk, sync_id, locals())

    @mcp.tool()
    async def add_semantic_note(
        sync_id: str,
        target_type: str,
        target_ref: str,
        note: str,
    ) -> dict[str, Any]:
        """Attach free-form reasoning to an endpoint/entity/service/risk/project."""
        return await _run(ScanRegisterNote, ctx.client.add_note, sync_id, locals())


async def _run(schema_cls, backend_call, sync_id: str, raw: dict) -> dict[str, Any]:
    """Validate + forward; collapse validation + HTTP errors to a uniform
    `{ "error": ... }` shape the agent can branch on.
    """
    payload = {k: v for k, v in raw.items() if k not in {"sync_id"} and v is not None}
    try:
        model = schema_cls.model_validate(payload)
    except ValidationError as err:
        return {"error": {"status_code": 422, "detail": err.errors()}}

    try:
        return await backend_call(sync_id, model.model_dump(mode="json", exclude_none=True))
    except BackendError as err:
        return {"error": {"status_code": err.status_code, "detail": err.detail}}
