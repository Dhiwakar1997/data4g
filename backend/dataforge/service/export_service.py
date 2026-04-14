import logging
from datetime import datetime, timedelta

from fastapi import HTTPException

from dataforge.data.repository import ProjectRepository
from dataforge.schemas.topology import Topology
from dataforge.schemas.export import ExportRequest, ExportResponse

logger = logging.getLogger(__name__)


class ExportService:
    """Handles topology/report export to PNG, SVG, PDF."""

    def __init__(self):
        self.repo = ProjectRepository()

    async def generate_export(self, project_id: str, req: ExportRequest) -> ExportResponse:
        project = await self.repo.get_project_by_id(project_id)
        if not project:
            raise HTTPException(status_code=404, detail="Project not found")

        topologies = project.topologies or {}
        if req.topology_id not in topologies:
            raise HTTPException(status_code=404, detail="Topology not found")

        topology = Topology.model_validate(topologies[req.topology_id])

        # Generate based on format
        if req.format == "svg":
            download_url = await self._generate_svg(topology, project_id)
        elif req.format == "pdf":
            download_url = await self._generate_pdf(topology, project_id)
        else:
            download_url = await self._generate_png(topology, project_id)

        return ExportResponse(
            download_url=download_url,
            format=req.format,
            generated_at=datetime.now(),
            expires_at=datetime.now() + timedelta(hours=24),
        )

    async def _generate_png(self, topology: Topology, project_id: str) -> str:
        """Generate PNG export of topology diagram."""
        # Stub: in production, use Pillow to render
        logger.info("PNG export requested for topology %s", topology.id)
        return f"/api/v1/exports/{project_id}_{topology.id}.png"

    async def _generate_svg(self, topology: Topology, project_id: str) -> str:
        """Generate SVG export of topology diagram."""
        logger.info("SVG export requested for topology %s", topology.id)
        return f"/api/v1/exports/{project_id}_{topology.id}.svg"

    async def _generate_pdf(self, topology: Topology, project_id: str) -> str:
        """Generate PDF report of topology with costs."""
        logger.info("PDF export requested for topology %s", topology.id)
        return f"/api/v1/exports/{project_id}_{topology.id}.pdf"
