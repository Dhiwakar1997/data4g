"""Session-based scan ingestion API.

Guarded by project-scoped API keys (see `require_project_api_key`). JWTs
are intentionally not accepted on these routes — human users don't drive
ingestion; agents do via the `data4g-mcp` local MCP server.
"""

from fastapi import APIRouter, Depends

from core.access_control import require_project_access, require_project_api_key
from dataforge.data.model import ProjectApiKey
from dataforge.schemas.scan import (
    ScanRegisterEndpoint,
    ScanRegisterEntity,
    ScanRegisterNote,
    ScanRegisterRisk,
    ScanRegisterService,
    ScanSessionStart,
    ScanSessionState,
    ScanSyncResult,
)
from dataforge.service.scan_ingestion_service import ScanIngestionService

scan_router = APIRouter(prefix="/projects/{project_id}/scan", tags=["scan"])


def _service() -> ScanIngestionService:
    return ScanIngestionService()


# ── Session lifecycle ────────────────────────────────────────


@scan_router.post("/sessions", response_model=ScanSessionState, status_code=201)
async def start_session(
    project_id: str,
    payload: ScanSessionStart | None = None,
    key: ProjectApiKey = Depends(require_project_api_key),
) -> ScanSessionState:
    svc = _service()
    session = await svc.start_session(
        project_id=project_id,
        api_key=key,
        note=(payload.note if payload else None),
    )
    return svc.to_state(session)


@scan_router.get("/sessions/{sync_id}", response_model=ScanSessionState)
async def get_session(
    project_id: str,
    sync_id: str,
    _key: ProjectApiKey = Depends(require_project_api_key),
) -> ScanSessionState:
    svc = _service()
    session = await svc.get_session(project_id, sync_id)
    return svc.to_state(session)


@scan_router.post("/sessions/{sync_id}/finalize", response_model=ScanSyncResult)
async def finalize_session(
    project_id: str,
    sync_id: str,
    _key: ProjectApiKey = Depends(require_project_api_key),
) -> ScanSyncResult:
    return await _service().finalize(project_id, sync_id)


@scan_router.post("/sessions/{sync_id}/abort", response_model=ScanSyncResult)
async def abort_session(
    project_id: str,
    sync_id: str,
    _key: ProjectApiKey = Depends(require_project_api_key),
) -> ScanSyncResult:
    return await _service().abort(project_id, sync_id)


# ── Registration ─────────────────────────────────────────────


@scan_router.post(
    "/sessions/{sync_id}/endpoints", response_model=ScanSessionState,
)
async def register_endpoint(
    project_id: str,
    sync_id: str,
    payload: ScanRegisterEndpoint,
    _key: ProjectApiKey = Depends(require_project_api_key),
) -> ScanSessionState:
    return await _service().register_endpoint(project_id, sync_id, payload)


@scan_router.post(
    "/sessions/{sync_id}/entities", response_model=ScanSessionState,
)
async def register_entity(
    project_id: str,
    sync_id: str,
    payload: ScanRegisterEntity,
    _key: ProjectApiKey = Depends(require_project_api_key),
) -> ScanSessionState:
    return await _service().register_entity(project_id, sync_id, payload)


@scan_router.post(
    "/sessions/{sync_id}/services", response_model=ScanSessionState,
)
async def register_service(
    project_id: str,
    sync_id: str,
    payload: ScanRegisterService,
    _key: ProjectApiKey = Depends(require_project_api_key),
) -> ScanSessionState:
    return await _service().register_service(project_id, sync_id, payload)


@scan_router.post(
    "/sessions/{sync_id}/risks", response_model=ScanSessionState,
)
async def register_risk(
    project_id: str,
    sync_id: str,
    payload: ScanRegisterRisk,
    _key: ProjectApiKey = Depends(require_project_api_key),
) -> ScanSessionState:
    return await _service().register_risk(project_id, sync_id, payload)


@scan_router.post(
    "/sessions/{sync_id}/notes", response_model=ScanSessionState,
)
async def add_note(
    project_id: str,
    sync_id: str,
    payload: ScanRegisterNote,
    _key: ProjectApiKey = Depends(require_project_api_key),
) -> ScanSessionState:
    return await _service().add_note(project_id, sync_id, payload)


# ── Read-only dashboard views (JWT-guarded) ─────────────────
# These exist so the frontend can surface sync state without holding an API
# key. The ingestion routes above are strictly API-key-only.


@scan_router.get("/status")
async def scan_status(
    project_id: str,
    _user_id: str = Depends(require_project_access),
) -> dict:
    svc = _service()
    latest = await svc.get_latest_log(project_id)
    active = [
        svc.to_state(s).model_dump(mode="json")
        for s in await svc.list_recent_sessions(project_id, limit=5)
        if s.state == "active"
    ]
    return {
        "project_id": project_id,
        "last_sync": (
            {
                "sync_id": latest.sync_id,
                "status": latest.status,
                "endpoints_synced": latest.endpoints_synced,
                "entities_synced": latest.entities_synced,
                "risk_findings_count": latest.risk_findings_count,
                "synced_at": latest.synced_at.isoformat(),
                "api_key_id": latest.api_key_id,
            }
            if latest else None
        ),
        "active_sessions": active,
    }


@scan_router.get("/history")
async def scan_history(
    project_id: str,
    limit: int = 20,
    _user_id: str = Depends(require_project_access),
) -> list[dict]:
    logs = await _service().list_recent_logs(project_id, limit=limit)
    return [
        {
            "sync_id": log.sync_id,
            "status": log.status,
            "sync_mode": log.sync_mode,
            "endpoints_synced": log.endpoints_synced,
            "entities_synced": log.entities_synced,
            "risk_findings_count": log.risk_findings_count,
            "synced_at": log.synced_at.isoformat(),
            "api_key_id": log.api_key_id,
        }
        for log in logs
    ]
