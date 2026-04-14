"""Session-based scan ingestion.

The agent calls `start_sync` to open a staging session, then calls one
registration endpoint per artefact (endpoint/entity/service/risk/note), and
finally `finalize` to atomically commit into the live topology. `abort`
discards staged data; expired sessions (TTL 2h) reject writes.
"""

from datetime import datetime, timedelta
from uuid import uuid4

from fastapi import HTTPException

from dataforge.data.model import (
    ProjectApiKey,
    RiskReport,
    ScanSession,
    ScanSyncLog,
)
from dataforge.data.repository import (
    EndpointRegistryRepository,
    ProjectRepository,
    RiskReportRepository,
    ScanSessionRepository,
    ScanSyncLogRepository,
)
from dataforge.schemas.enums import TopologyType
from dataforge.schemas.scan import (
    ScanRegisterEndpoint,
    ScanRegisterEntity,
    ScanRegisterNote,
    ScanRegisterRisk,
    ScanRegisterService,
    ScanSessionState,
    ScanSyncResult,
)

SESSION_TTL = timedelta(hours=2)


class ScanIngestionService:
    """Processes agent-driven scan sessions and commits to live topology."""

    def __init__(self):
        self.project_repo = ProjectRepository()
        self.endpoint_repo = EndpointRegistryRepository()
        self.risk_repo = RiskReportRepository()
        self.session_repo = ScanSessionRepository()
        self.log_repo = ScanSyncLogRepository()

    # ── Session lifecycle ─────────────────────────────────────

    async def start_session(
        self,
        project_id: str,
        api_key: ProjectApiKey,
        note: str | None,
    ) -> ScanSession:
        project = await self.project_repo.get_project_by_id(project_id)
        if not project:
            raise HTTPException(status_code=404, detail="Project not found")

        now = datetime.utcnow()
        session = ScanSession(
            sync_id=str(uuid4()),
            project_id=project_id,
            api_key_id=str(api_key.id),
            started_at=now,
            expires_at=now + SESSION_TTL,
            note=note,
            state="active",
        )
        return await self.session_repo.create(session)

    async def get_session(self, project_id: str, sync_id: str) -> ScanSession:
        session = await self.session_repo.get_by_sync_id(sync_id)
        if not session or session.project_id != project_id:
            raise HTTPException(status_code=404, detail="Scan session not found")
        return session

    def to_state(self, session: ScanSession) -> ScanSessionState:
        return ScanSessionState(
            sync_id=session.sync_id,
            project_id=session.project_id,
            state=session.state,
            started_at=session.started_at,
            expires_at=session.expires_at,
            note=session.note,
            endpoint_count=len(session.endpoints),
            entity_count=len(session.entities),
            service_count=len(session.services),
            risk_count=len(session.risks),
            note_count=len(session.notes),
        )

    async def _load_writable(self, project_id: str, sync_id: str) -> ScanSession:
        session = await self.get_session(project_id, sync_id)
        if session.state != "active":
            raise HTTPException(
                status_code=409,
                detail=f"Session is {session.state}; cannot register more data",
            )
        if datetime.utcnow() >= session.expires_at:
            session.state = "expired"
            await self.session_repo.save(session)
            raise HTTPException(status_code=410, detail="Session has expired")
        return session

    # ── Registration (mutates staging) ───────────────────────

    async def register_endpoint(
        self, project_id: str, sync_id: str, payload: ScanRegisterEndpoint,
    ) -> ScanSessionState:
        session = await self._load_writable(project_id, sync_id)
        dumped = payload.model_dump(mode="json")
        key = (payload.method.upper(), payload.path)
        # Idempotent on (method, path) — overwrite in place
        filtered = [
            ep for ep in session.endpoints
            if (str(ep.get("method", "")).upper(), ep.get("path")) != key
        ]
        filtered.append(dumped)
        session.endpoints = filtered
        await self.session_repo.save(session)
        return self.to_state(session)

    async def register_entity(
        self, project_id: str, sync_id: str, payload: ScanRegisterEntity,
    ) -> ScanSessionState:
        session = await self._load_writable(project_id, sync_id)
        dumped = payload.model_dump(mode="json")
        filtered = [
            e for e in session.entities if e.get("name") != payload.name
        ]
        filtered.append(dumped)
        session.entities = filtered
        await self.session_repo.save(session)
        return self.to_state(session)

    async def register_service(
        self, project_id: str, sync_id: str, payload: ScanRegisterService,
    ) -> ScanSessionState:
        session = await self._load_writable(project_id, sync_id)
        dumped = payload.model_dump(mode="json")
        filtered = [
            s for s in session.services if s.get("name") != payload.name
        ]
        filtered.append(dumped)
        session.services = filtered
        await self.session_repo.save(session)
        return self.to_state(session)

    async def register_risk(
        self, project_id: str, sync_id: str, payload: ScanRegisterRisk,
    ) -> ScanSessionState:
        session = await self._load_writable(project_id, sync_id)
        session.risks.append(payload.model_dump(mode="json"))
        await self.session_repo.save(session)
        return self.to_state(session)

    async def add_note(
        self, project_id: str, sync_id: str, payload: ScanRegisterNote,
    ) -> ScanSessionState:
        session = await self._load_writable(project_id, sync_id)
        session.notes.append(payload.model_dump(mode="json"))
        await self.session_repo.save(session)
        return self.to_state(session)

    # ── Commit / discard ─────────────────────────────────────

    async def finalize(self, project_id: str, sync_id: str) -> ScanSyncResult:
        session = await self._load_writable(project_id, sync_id)
        project = await self.project_repo.get_project_by_id(project_id)
        if not project:
            raise HTTPException(status_code=404, detail="Project not found")

        # Locate or create the live topology.
        topologies = project.topologies or {}
        live_topo_id = next(
            (
                tid for tid, tdata in topologies.items()
                if tdata.get("topology_type") == TopologyType.LIVE.value
            ),
            None,
        )
        if not live_topo_id:
            live_topo_id = str(uuid4())
            topologies[live_topo_id] = {
                "id": live_topo_id,
                "name": "Live",
                "topology_type": TopologyType.LIVE.value,
                "deployment_mode": "multi_tier",
                "components": [],
                "edges": [],
                "base_user_count": 1000,
                "growth_targets": [1_000, 10_000, 100_000, 1_000_000],
                "last_synced_at": datetime.utcnow().isoformat(),
                "sync_version": 1,
            }
        else:
            topo = topologies[live_topo_id]
            topo["last_synced_at"] = datetime.utcnow().isoformat()
            topo["sync_version"] = topo.get("sync_version", 0) + 1

        project.topologies = topologies
        project.last_mcp_sync_at = datetime.now()
        await self.project_repo.update_project(project)

        if session.endpoints:
            await self.endpoint_repo.upsert(
                project_id=project_id,
                topology_id=live_topo_id,
                component_id="scan_auto",
                data={"endpoints": session.endpoints},
            )

        if session.risks:
            report = RiskReport(
                project_id=project_id,
                topology_id=live_topo_id,
                findings=session.risks,
                overall_score=0.0,
                analyzed_at=datetime.now(),
            )
            await self.risk_repo.save_report(report)

        diff_summary = {
            "endpoints_added": len(session.endpoints),
            "entities_added": len(session.entities),
            "services_added": len(session.services),
            "risk_findings_added": len(session.risks),
            "notes_added": len(session.notes),
        }

        await self.log_repo.create_log(ScanSyncLog(
            project_id=project_id,
            sync_mode="agent",
            sync_id=session.sync_id,
            status="success",
            endpoints_synced=len(session.endpoints),
            entities_synced=len(session.entities),
            risk_findings_count=len(session.risks),
            diff_summary=diff_summary,
            synced_at=datetime.now(),
            api_key_id=session.api_key_id,
        ))

        session.state = "finalized"
        await self.session_repo.save(session)

        return ScanSyncResult(
            sync_id=session.sync_id,
            state="finalized",
            endpoints_added=len(session.endpoints),
            entities_added=len(session.entities),
            services_added=len(session.services),
            risks_added=len(session.risks),
            notes_added=len(session.notes),
            topology_url=f"/projects/{project_id}/topology/{live_topo_id}",
        )

    async def abort(self, project_id: str, sync_id: str) -> ScanSyncResult:
        session = await self.get_session(project_id, sync_id)
        if session.state != "active":
            raise HTTPException(
                status_code=409,
                detail=f"Session is already {session.state}",
            )
        session.state = "aborted"
        await self.session_repo.save(session)
        return ScanSyncResult(sync_id=session.sync_id, state="aborted")

    # ── Read-only helpers ────────────────────────────────────

    async def list_recent_sessions(self, project_id: str, limit: int = 20) -> list[ScanSession]:
        return await self.session_repo.list_by_project(project_id, limit=limit)

    async def list_recent_logs(self, project_id: str, limit: int = 20) -> list[ScanSyncLog]:
        return await self.log_repo.list_by_project(project_id, limit=limit)

    async def get_latest_log(self, project_id: str) -> ScanSyncLog | None:
        return await self.log_repo.get_latest(project_id)
