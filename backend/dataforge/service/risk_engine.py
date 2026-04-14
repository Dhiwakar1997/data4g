from datetime import datetime

from fastapi import HTTPException

from dataforge.data.repository import (
    ProjectRepository, RiskReportRepository, EndpointRegistryRepository,
)
from dataforge.data.model import RiskReport
from dataforge.schemas.risk import (
    RiskFinding, EndpointRiskSummary, RiskDashboard,
)
from dataforge.schemas.enums import RiskSeverity, RiskType


SEVERITY_WEIGHTS = {
    RiskSeverity.CRITICAL: 10.0,
    RiskSeverity.HIGH: 7.0,
    RiskSeverity.MEDIUM: 4.0,
    RiskSeverity.LOW: 1.0,
    RiskSeverity.INFO: 0.0,
}


class RiskEngine:

    def __init__(self):
        self.project_repo = ProjectRepository()
        self.risk_repo = RiskReportRepository()
        self.endpoint_repo = EndpointRegistryRepository()

    def calculate_endpoint_risk_score(self, findings: list[RiskFinding]) -> float:
        if not findings:
            return 0.0
        total = sum(SEVERITY_WEIGHTS.get(f.severity, 0) for f in findings)
        return min(total, 10.0)

    async def build_dashboard(
        self, project_id: str, topology_id: str,
    ) -> RiskDashboard:
        report = await self.risk_repo.get_latest(project_id, topology_id)

        if not report or not report.findings:
            return RiskDashboard(
                project_id=project_id,
                topology_id=topology_id,
                total_endpoints=0,
                analyzed_endpoints=0,
                overall_risk_score=0.0,
            )

        findings = [RiskFinding.model_validate(f) for f in report.findings]

        # Group by endpoint
        endpoint_map: dict[str, list[RiskFinding]] = {}
        for f in findings:
            endpoint_map.setdefault(f.endpoint_id, []).append(f)

        summaries: list[EndpointRiskSummary] = []
        for eid, efindings in endpoint_map.items():
            score = self.calculate_endpoint_risk_score(efindings)
            summaries.append(EndpointRiskSummary(
                endpoint_id=eid,
                endpoint_path=efindings[0].endpoint_path,
                http_method="",
                overall_risk_score=score,
                finding_count=len(efindings),
                critical_count=sum(1 for f in efindings if f.severity == RiskSeverity.CRITICAL),
                high_count=sum(1 for f in efindings if f.severity == RiskSeverity.HIGH),
                medium_count=sum(1 for f in efindings if f.severity == RiskSeverity.MEDIUM),
                findings=efindings,
            ))

        summaries.sort(key=lambda s: s.overall_risk_score, reverse=True)

        # Distribution
        dist: dict[str, int] = {}
        type_dist: dict[str, int] = {}
        for f in findings:
            dist[f.severity.value] = dist.get(f.severity.value, 0) + 1
            type_dist[f.risk_type.value] = type_dist.get(f.risk_type.value, 0) + 1

        overall = (
            sum(s.overall_risk_score for s in summaries) / len(summaries)
            if summaries else 0.0
        )

        registries = await self.endpoint_repo.list_by_topology(project_id, topology_id)
        total_endpoints = sum(len(r.endpoints) for r in registries)

        return RiskDashboard(
            project_id=project_id,
            topology_id=topology_id,
            total_endpoints=total_endpoints,
            analyzed_endpoints=len(endpoint_map),
            overall_risk_score=round(overall, 2),
            risk_distribution=dist,
            top_risks=summaries[:10],
            risk_by_type=type_dist,
            last_analyzed_at=report.analyzed_at,
        )

    async def get_endpoints_by_risk(
        self, project_id: str, topology_id: str, min_score: float = 0.0,
    ) -> list[EndpointRiskSummary]:
        dashboard = await self.build_dashboard(project_id, topology_id)
        return [s for s in dashboard.top_risks if s.overall_risk_score >= min_score]

    async def filter_by_type(
        self, project_id: str, topology_id: str, risk_type: RiskType,
    ) -> list[RiskFinding]:
        report = await self.risk_repo.get_latest(project_id, topology_id)
        if not report:
            return []
        findings = [RiskFinding.model_validate(f) for f in report.findings]
        return [f for f in findings if f.risk_type == risk_type]

    async def trigger_analysis(self, project_id: str, topology_id: str) -> RiskDashboard:
        """Re-analyze risk from stored endpoint registries."""
        registries = await self.endpoint_repo.list_by_topology(project_id, topology_id)
        all_findings: list[dict] = []

        for reg in registries:
            for ep_data in reg.endpoints:
                for rf_str in ep_data.get("risk_findings", []):
                    if isinstance(rf_str, str):
                        all_findings.append({
                            "endpoint_id": ep_data.get("id", ""),
                            "endpoint_path": ep_data.get("path", ""),
                            "risk_type": RiskType.UNBOUNDED_FETCH.value,
                            "severity": RiskSeverity.MEDIUM.value,
                            "message": rf_str,
                            "source_file": ep_data.get("source_file", ""),
                        })
                    elif isinstance(rf_str, dict):
                        all_findings.append(rf_str)

        report = RiskReport(
            project_id=project_id,
            topology_id=topology_id,
            findings=all_findings,
            overall_score=0.0,
            analyzed_at=datetime.now(),
        )
        await self.risk_repo.save_report(report)

        return await self.build_dashboard(project_id, topology_id)
