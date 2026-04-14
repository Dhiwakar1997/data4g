from datetime import datetime
from dataforge.data.model import (
    Project, ProjectMember, EndpointRegistry, RiskReport,
    CloudPricing, ShareLink, ScanSyncLog,
    ProjectApiKey, ScanSession,
)


class ProjectRepository:

    async def create_project(self, project: Project) -> Project:
        await project.insert()
        return project

    async def get_project_by_id(self, project_id: str) -> Project | None:
        return await Project.find_one(
            Project.project_id == project_id,
            Project.is_deleted == False,
        )

    async def list_projects(self, skip: int = 0, limit: int = 50) -> tuple[list[Project], int]:
        query = Project.find(Project.is_deleted == False).sort("-created_at")
        total = await query.count()
        projects = await query.skip(skip).limit(limit).to_list()
        return projects, total

    async def list_projects_for_user(self, user_id: str, skip: int = 0, limit: int = 50) -> tuple[list[Project], int]:
        """List projects the user owns or is a member of."""
        memberships = await ProjectMember.find(
            ProjectMember.user_id == user_id,
        ).to_list()
        project_ids = [m.project_id for m in memberships]

        query = Project.find(
            {"$and": [
                {"project_id": {"$in": project_ids}},
                {"is_deleted": False},
            ]}
        ).sort("-created_at")
        total = await query.count()
        projects = await query.skip(skip).limit(limit).to_list()
        return projects, total

    async def update_project(self, project: Project) -> Project:
        project.updated_at = datetime.now()
        await project.save()
        return project

    async def delete_project(self, project_id: str) -> Project | None:
        project = await self.get_project_by_id(project_id)
        if not project:
            return None
        project.is_deleted = True
        project.updated_at = datetime.now()
        await project.save()
        return project


class MemberRepository:

    async def add_member(self, member: ProjectMember) -> ProjectMember:
        await member.insert()
        return member

    async def get_member(self, project_id: str, user_id: str) -> ProjectMember | None:
        return await ProjectMember.find_one(
            ProjectMember.project_id == project_id,
            ProjectMember.user_id == user_id,
        )

    async def list_members(self, project_id: str) -> list[ProjectMember]:
        return await ProjectMember.find(
            ProjectMember.project_id == project_id,
        ).to_list()

    async def update_member(self, member: ProjectMember) -> ProjectMember:
        member.updated_at = datetime.now()
        await member.save()
        return member

    async def remove_member(self, project_id: str, user_id: str) -> bool:
        member = await self.get_member(project_id, user_id)
        if not member:
            return False
        await member.delete()
        return True

    async def remove_all_members(self, project_id: str):
        """Remove all members when a project is deleted."""
        await ProjectMember.find(
            ProjectMember.project_id == project_id,
        ).delete()


class EndpointRegistryRepository:

    async def upsert(self, project_id: str, topology_id: str, component_id: str, data: dict) -> EndpointRegistry:
        existing = await EndpointRegistry.find_one(
            EndpointRegistry.project_id == project_id,
            EndpointRegistry.topology_id == topology_id,
            EndpointRegistry.component_id == component_id,
        )
        if existing:
            existing.endpoints = data.get("endpoints", [])
            existing.last_synced_at = datetime.now()
            existing.sync_version += 1
            await existing.save()
            return existing
        registry = EndpointRegistry(
            project_id=project_id,
            topology_id=topology_id,
            component_id=component_id,
            endpoints=data.get("endpoints", []),
            last_synced_at=datetime.now(),
            sync_version=1,
        )
        await registry.insert()
        return registry

    async def get_by_component(self, project_id: str, topology_id: str, component_id: str) -> EndpointRegistry | None:
        return await EndpointRegistry.find_one(
            EndpointRegistry.project_id == project_id,
            EndpointRegistry.topology_id == topology_id,
            EndpointRegistry.component_id == component_id,
        )

    async def list_by_topology(self, project_id: str, topology_id: str) -> list[EndpointRegistry]:
        return await EndpointRegistry.find(
            EndpointRegistry.project_id == project_id,
            EndpointRegistry.topology_id == topology_id,
        ).to_list()


class RiskReportRepository:

    async def save_report(self, report: RiskReport) -> RiskReport:
        await report.insert()
        return report

    async def get_latest(self, project_id: str, topology_id: str) -> RiskReport | None:
        return await RiskReport.find(
            RiskReport.project_id == project_id,
            RiskReport.topology_id == topology_id,
        ).sort("-analyzed_at").first_or_none()

    async def list_reports(self, project_id: str, limit: int = 20) -> list[RiskReport]:
        return await RiskReport.find(
            RiskReport.project_id == project_id,
        ).sort("-analyzed_at").limit(limit).to_list()


class CloudPricingRepository:

    async def upsert_price(self, provider: str, service: str, region: str, sku: str, price: float, unit: str):
        existing = await CloudPricing.find_one(
            CloudPricing.provider == provider,
            CloudPricing.service == service,
            CloudPricing.region == region,
            CloudPricing.sku == sku,
        )
        if existing:
            existing.price_per_unit = price
            existing.unit = unit
            existing.last_updated = datetime.now()
            await existing.save()
            return existing
        doc = CloudPricing(
            provider=provider, service=service, region=region,
            sku=sku, price_per_unit=price, unit=unit,
        )
        await doc.insert()
        return doc

    async def get_price(self, provider: str, service: str, region: str, sku: str) -> float | None:
        doc = await CloudPricing.find_one(
            CloudPricing.provider == provider,
            CloudPricing.service == service,
            CloudPricing.region == region,
            CloudPricing.sku == sku,
        )
        return doc.price_per_unit if doc else None


class ShareLinkRepository:

    async def create_link(self, link: ShareLink) -> ShareLink:
        await link.insert()
        return link

    async def get_by_token(self, token: str) -> ShareLink | None:
        return await ShareLink.find_one(
            ShareLink.share_token == token,
            ShareLink.is_active == True,
        )

    async def deactivate(self, token: str) -> bool:
        link = await self.get_by_token(token)
        if not link:
            return False
        link.is_active = False
        await link.save()
        return True


class ScanSyncLogRepository:

    async def create_log(self, log: ScanSyncLog) -> ScanSyncLog:
        await log.insert()
        return log

    async def get_by_sync_id(self, sync_id: str) -> ScanSyncLog | None:
        return await ScanSyncLog.find_one(ScanSyncLog.sync_id == sync_id)

    async def list_by_project(self, project_id: str, limit: int = 20) -> list[ScanSyncLog]:
        return await ScanSyncLog.find(
            ScanSyncLog.project_id == project_id,
        ).sort("-synced_at").limit(limit).to_list()

    async def get_latest(self, project_id: str) -> ScanSyncLog | None:
        return await ScanSyncLog.find(
            ScanSyncLog.project_id == project_id,
        ).sort("-synced_at").first_or_none()


class ProjectApiKeyRepository:

    async def create(self, key: ProjectApiKey) -> ProjectApiKey:
        await key.insert()
        return key

    async def list_active(self, project_id: str) -> list[ProjectApiKey]:
        return await ProjectApiKey.find(
            ProjectApiKey.project_id == project_id,
            ProjectApiKey.revoked_at == None,  # noqa: E711 (Beanie filter)
        ).sort("-created_at").to_list()

    async def list_all(self, project_id: str) -> list[ProjectApiKey]:
        return await ProjectApiKey.find(
            ProjectApiKey.project_id == project_id,
        ).sort("-created_at").to_list()

    async def count_active(self, project_id: str) -> int:
        return await ProjectApiKey.find(
            ProjectApiKey.project_id == project_id,
            ProjectApiKey.revoked_at == None,  # noqa: E711
        ).count()

    async def get_by_hash(self, key_hash: str) -> ProjectApiKey | None:
        return await ProjectApiKey.find_one(ProjectApiKey.key_hash == key_hash)

    async def get_by_id(self, key_id: str) -> ProjectApiKey | None:
        return await ProjectApiKey.get(key_id)

    async def revoke(self, key: ProjectApiKey) -> ProjectApiKey:
        key.revoked_at = datetime.now()
        await key.save()
        return key

    async def touch_last_used(self, key: ProjectApiKey) -> None:
        key.last_used_at = datetime.now()
        await key.save()


class ScanSessionRepository:

    async def create(self, session: ScanSession) -> ScanSession:
        await session.insert()
        return session

    async def get_by_sync_id(self, sync_id: str) -> ScanSession | None:
        return await ScanSession.find_one(ScanSession.sync_id == sync_id)

    async def save(self, session: ScanSession) -> ScanSession:
        await session.save()
        return session

    async def list_by_project(self, project_id: str, limit: int = 20) -> list[ScanSession]:
        return await ScanSession.find(
            ScanSession.project_id == project_id,
        ).sort("-started_at").limit(limit).to_list()
