from fastapi import HTTPException

from dataforge.data.repository import ProjectRepository
from dataforge.data.model import Project
from dataforge.schemas.topology import Topology
from dataforge.schemas.compute import ComputeSpec, ComputeCostBreakdown
from dataforge.schemas.db_model import (
    DBModelSpec, DBCostBreakdown, DBStorageProjection, DBIOPSProjection,
)
from dataforge.schemas.cache_spec import CacheSpec, CacheCostBreakdown
from dataforge.schemas.lb_spec import LoadBalancerSpec, LBCostBreakdown
from dataforge.schemas.cdn_spec import CDNSpec, CDNCostBreakdown
from dataforge.schemas.dashboard import (
    ComponentCostSummary, CategoryCostSummary, GrowthProjection,
    EntityCostDetail, OptimizationHint, ConsolidatedDashboard,
)
from dataforge.schemas.api_gateway_spec import APIGatewaySpec, APIGatewayCostBreakdown
from dataforge.schemas.object_storage_spec import ObjectStorageSpec, ObjectStorageCostBreakdown
from dataforge.schemas.third_party_spec import ThirdPartyAPISpec
from dataforge.schemas.enums import ComponentType, DatabaseId
from dataforge.service.model_graph import ModelGraph


# ── Pricing constants (placeholder — will be loaded from pricing tables) ─

COMPUTE_PRICE_PER_VCPU_HOUR = 0.05
COMPUTE_PRICE_PER_GB_RAM_HOUR = 0.007
GPU_PRICE_PER_HOUR = {"none": 0, "t4": 0.526, "a10g": 1.006, "a100": 3.67, "l4": 0.81, "h100": 8.50}
STORAGE_PRICE_PER_GB_MONTH = 0.10

DB_INSTANCE_BASE_MONTHLY = {
    "postgresql": 150, "mysql": 130, "oracle": 500, "sqlserver": 300,
    "mariadb": 120, "cockroachdb": 200, "sqlite": 0,
    "mongodb": 250, "dynamodb": 0, "cassandra": 200, "couchdb": 80, "firebase": 0,
    "redis": 70, "valkey": 55, "memcached": 50, "dragonfly": 60,
    "neo4j": 300, "neptune": 350, "arangodb": 200, "dgraph": 150,
    "pinecone": 65, "weaviate": 85, "milvus": 65, "qdrant": 25, "chromadb": 0, "pgvector": 180,
    "elasticsearch": 200, "opensearch": 180,
    "influxdb": 80, "timescaledb": 100,
}
DB_STORAGE_PRICE_PER_GB = 0.115
DB_IOPS_PRICE_PER_IOP = 0.065
DB_BACKUP_PRICE_PER_GB = 0.095
LICENSE_COSTS = {"oracle": 200.0, "sqlserver": 150.0}

CACHE_PRICE_PER_GB = {"redis": 30, "valkey": 25, "memcached": 22, "dragonfly": 28}

LB_FIXED_MONTHLY = 22.0
LB_LCU_PRICE_HOUR = 0.008
CDN_PRICE_PER_GB = 0.085
CDN_PRICE_PER_10K_REQUESTS = 0.0075

API_GATEWAY_PRICE_PER_MILLION_REQUESTS = 3.50
API_GATEWAY_DATA_TRANSFER_PER_GB = 0.09

OBJECT_STORAGE_PRICE_PER_GB = 0.023
OBJECT_STORAGE_REQUEST_PRICE_PER_1000 = 0.005
OBJECT_STORAGE_EGRESS_PER_GB = 0.09

HOURS_PER_MONTH = 730.0


class CostEngine:
    """Calculates costs for all components and aggregates into a dashboard."""

    def __init__(self):
        self.repo = ProjectRepository()

    # ── Consolidated dashboard ──────────────────────────────────

    async def get_dashboard(self, project_id: str) -> ConsolidatedDashboard:
        project = await self._get_or_404(project_id)
        if not project.topology:
            raise HTTPException(status_code=400, detail="Topology not configured yet")

        topology = Topology.model_validate(project.topology)
        component_costs: list[ComponentCostSummary] = []

        # Compute costs
        for cid, spec_data in (project.compute_specs or {}).items():
            spec = ComputeSpec.model_validate(spec_data)
            breakdown = self._calc_compute_cost(spec)
            component_costs.append(ComponentCostSummary(
                topology_component_id=cid,
                component_name=self._component_name(topology, cid),
                component_type=ComponentType.COMPUTE,
                total_monthly=breakdown.total_monthly,
                details={
                    "instance": breakdown.instance_cost_monthly,
                    "gpu": breakdown.gpu_cost_monthly,
                    "storage": breakdown.storage_cost_monthly,
                },
            ))

        # DB costs
        entity_details: list[EntityCostDetail] = []
        for cid, spec_data in (project.db_specs or {}).items():
            spec = DBModelSpec.model_validate(spec_data)
            user_count = topology.base_user_count
            breakdown = self._calc_db_cost(spec, user_count)
            component_costs.append(ComponentCostSummary(
                topology_component_id=cid,
                component_name=self._component_name(topology, cid),
                component_type=ComponentType.DATABASE,
                total_monthly=breakdown.total_monthly,
                details={
                    "instance": breakdown.instance_cost_monthly,
                    "storage": breakdown.storage_cost_monthly,
                    "iops": breakdown.iops_cost_monthly,
                    "backup": breakdown.backup_cost_monthly,
                    "license": breakdown.license_cost_monthly,
                },
            ))
            # Per-entity details
            graph = ModelGraph(spec)
            storage_proj = graph.calculate_storage(user_count)
            for ep in storage_proj.per_entity:
                storage_gb = ep.total_size_bytes / (1024 ** 3)
                cost = storage_gb * DB_STORAGE_PRICE_PER_GB
                entity_details.append(EntityCostDetail(
                    entity_id=ep.entity_id,
                    entity_name=ep.entity_name,
                    record_count=ep.record_count,
                    storage_gb=round(storage_gb, 4),
                    storage_cost_monthly=round(cost, 2),
                    percentage_of_db_cost=0.0,
                ))

        # Cache costs
        for cid, spec_data in (project.cache_specs or {}).items():
            spec = CacheSpec.model_validate(spec_data)
            breakdown = self._calc_cache_cost(spec)
            component_costs.append(ComponentCostSummary(
                topology_component_id=cid,
                component_name=self._component_name(topology, cid),
                component_type=ComponentType.CACHE,
                total_monthly=breakdown.total_monthly,
                details={"memory": breakdown.memory_cost_monthly},
            ))

        # LB costs
        for cid, spec_data in (project.lb_specs or {}).items():
            spec = LoadBalancerSpec.model_validate(spec_data)
            breakdown = self._calc_lb_cost(spec)
            component_costs.append(ComponentCostSummary(
                topology_component_id=cid,
                component_name=self._component_name(topology, cid),
                component_type=ComponentType.LOAD_BALANCER,
                total_monthly=breakdown.total_monthly,
                details={
                    "fixed": breakdown.fixed_cost_monthly,
                    "lcu": breakdown.lcu_cost_monthly,
                    "data_processing": breakdown.data_processing_cost_monthly,
                },
            ))

        # API Gateway costs
        for cid, spec_data in (project.api_gateway_specs or {}).items():
            spec = APIGatewaySpec.model_validate(spec_data)
            breakdown = self._calc_api_gateway_cost(spec)
            component_costs.append(ComponentCostSummary(
                topology_component_id=cid,
                component_name=self._component_name(topology, cid),
                component_type=ComponentType.API_GATEWAY,
                total_monthly=breakdown.total_monthly,
                details={
                    "requests": breakdown.request_cost_monthly,
                    "data_transfer": breakdown.data_transfer_cost_monthly,
                },
            ))

        # Object Storage costs
        for cid, spec_data in (project.object_storage_specs or {}).items():
            spec = ObjectStorageSpec.model_validate(spec_data)
            breakdown = self._calc_object_storage_cost(spec)
            component_costs.append(ComponentCostSummary(
                topology_component_id=cid,
                component_name=self._component_name(topology, cid),
                component_type=ComponentType.OBJECT_STORE,
                total_monthly=breakdown.total_monthly,
                details={
                    "storage": breakdown.storage_cost_monthly,
                    "requests": breakdown.request_cost_monthly,
                    "egress": breakdown.egress_cost_monthly,
                },
            ))

        # Third-party API costs
        for cid, spec_data in (project.third_party_specs or {}).items():
            spec = ThirdPartyAPISpec.model_validate(spec_data)
            monthly_cost = (
                spec.monthly_subscription_cost
                + spec.cost_per_call * spec.estimated_calls_per_month
            )
            component_costs.append(ComponentCostSummary(
                topology_component_id=cid,
                component_name=self._component_name(topology, cid),
                component_type=ComponentType.THIRD_PARTY_API,
                total_monthly=round(monthly_cost, 2),
                details={
                    "subscription": spec.monthly_subscription_cost,
                    "per_call": round(spec.cost_per_call * spec.estimated_calls_per_month, 2),
                },
            ))

        # CDN costs
        for cid, spec_data in (project.cdn_specs or {}).items():
            spec = CDNSpec.model_validate(spec_data)
            breakdown = self._calc_cdn_cost(spec)
            component_costs.append(ComponentCostSummary(
                topology_component_id=cid,
                component_name=self._component_name(topology, cid),
                component_type=ComponentType.CDN,
                total_monthly=breakdown.total_monthly,
                details={
                    "data_transfer": breakdown.data_transfer_cost_monthly,
                    "requests": breakdown.request_cost_monthly,
                },
            ))

        total_monthly = sum(c.total_monthly for c in component_costs)

        # Fix entity percentages
        total_db_cost = sum(c.total_monthly for c in component_costs if c.component_type == ComponentType.DATABASE)
        if total_db_cost > 0:
            for ed in entity_details:
                ed.percentage_of_db_cost = round((ed.storage_cost_monthly / total_db_cost) * 100, 2)

        # Category aggregation
        per_category = self._aggregate_categories(component_costs, total_monthly)

        # Growth projections
        growth_projections = self._calc_growth_projections(project, topology)

        # Optimization hints
        hints = self._generate_hints(component_costs, project)

        dashboard = ConsolidatedDashboard(
            project_id=project.project_id,
            project_name=project.name,
            deployment_mode=topology.deployment_mode.value,
            base_user_count=topology.base_user_count,
            total_monthly_cost=round(total_monthly, 2),
            per_component=component_costs,
            per_category=per_category,
            per_entity_storage=entity_details,
            growth_projections=growth_projections,
            optimization_hints=hints,
        )

        # Cache the snapshot
        project.cost_snapshot = dashboard.model_dump(mode="json")
        await self.repo.update_project(project)

        return dashboard

    # ── Per-component cost breakdowns ───────────────────────────

    async def get_compute_cost(self, project_id: str, component_id: str) -> ComputeCostBreakdown:
        project = await self._get_or_404(project_id)
        specs = project.compute_specs or {}
        if component_id not in specs:
            raise HTTPException(status_code=404, detail="Compute spec not found")
        spec = ComputeSpec.model_validate(specs[component_id])
        return self._calc_compute_cost(spec)

    async def get_db_cost(self, project_id: str, component_id: str) -> DBCostBreakdown:
        project = await self._get_or_404(project_id)
        specs = project.db_specs or {}
        if component_id not in specs:
            raise HTTPException(status_code=404, detail="DB spec not found")
        spec = DBModelSpec.model_validate(specs[component_id])
        topology = Topology.model_validate(project.topology) if project.topology else None
        user_count = topology.base_user_count if topology else 1000
        return self._calc_db_cost(spec, user_count)

    async def get_cache_cost(self, project_id: str, component_id: str) -> CacheCostBreakdown:
        project = await self._get_or_404(project_id)
        specs = project.cache_specs or {}
        if component_id not in specs:
            raise HTTPException(status_code=404, detail="Cache spec not found")
        spec = CacheSpec.model_validate(specs[component_id])
        return self._calc_cache_cost(spec)

    # ── Growth projections ──────────────────────────────────────

    async def get_growth_projections(self, project_id: str) -> list[GrowthProjection]:
        project = await self._get_or_404(project_id)
        if not project.topology:
            raise HTTPException(status_code=400, detail="Topology not configured yet")
        topology = Topology.model_validate(project.topology)
        return self._calc_growth_projections(project, topology)

    # ── Compare ─────────────────────────────────────────────────

    async def compare_database(self, project_id: str, alternate_db_id: DatabaseId) -> ConsolidatedDashboard:
        dashboard = await self.get_dashboard(project_id)
        project = await self._get_or_404(project_id)
        topology = Topology.model_validate(project.topology)

        # Recalculate DB costs with alternate DB
        alt_total = 0.0
        for cid, spec_data in (project.db_specs or {}).items():
            spec = DBModelSpec.model_validate(spec_data)
            spec.database_id = alternate_db_id
            breakdown = self._calc_db_cost(spec, topology.base_user_count)
            alt_total += breakdown.total_monthly

        # Non-DB costs stay the same
        non_db_total = sum(
            c.total_monthly for c in dashboard.per_component
            if c.component_type != ComponentType.DATABASE
        )
        alt_full_total = round(non_db_total + alt_total, 2)

        dashboard.comparison_database = alternate_db_id
        dashboard.comparison_total_monthly = alt_full_total
        dashboard.comparison_delta = round(alt_full_total - dashboard.total_monthly_cost, 2)
        return dashboard

    # ── Per-entity storage details ──────────────────────────────

    async def get_entity_costs(self, project_id: str) -> list[EntityCostDetail]:
        dashboard = await self.get_dashboard(project_id)
        return dashboard.per_entity_storage

    # ── Optimization hints ──────────────────────────────────────

    async def get_hints(self, project_id: str) -> list[OptimizationHint]:
        dashboard = await self.get_dashboard(project_id)
        return dashboard.optimization_hints

    # ── Internal calculators ────────────────────────────────────

    def _calc_compute_cost(self, spec: ComputeSpec) -> ComputeCostBreakdown:
        count = spec.effective_instance_count
        instance_cost = (
            spec.cpu_cores * COMPUTE_PRICE_PER_VCPU_HOUR
            + spec.ram_gb * COMPUTE_PRICE_PER_GB_RAM_HOUR
        ) * HOURS_PER_MONTH * count

        gpu_cost = 0.0
        if spec.gpu.type.value != "none" and spec.gpu.count > 0:
            gpu_rate = GPU_PRICE_PER_HOUR.get(spec.gpu.type.value, 0)
            gpu_cost = gpu_rate * HOURS_PER_MONTH * spec.gpu.count * count

        storage_cost = spec.storage_gb * STORAGE_PRICE_PER_GB_MONTH * count

        total = round(instance_cost + gpu_cost + storage_cost, 2)
        desc = f"{count}x {spec.instance_family}.{spec.instance_size} ({spec.cpu_cores} vCPU, {spec.ram_gb} GB)"

        return ComputeCostBreakdown(
            topology_component_id=spec.topology_component_id,
            instance_cost_monthly=round(instance_cost, 2),
            gpu_cost_monthly=round(gpu_cost, 2),
            storage_cost_monthly=round(storage_cost, 2),
            total_monthly=total,
            instance_description=desc,
        )

    def _calc_db_cost(self, spec: DBModelSpec, user_count: int) -> DBCostBreakdown:
        graph = ModelGraph(spec)
        storage_proj = graph.calculate_storage(user_count)
        iops_proj = graph.calculate_iops(user_count)

        db_key = spec.database_id.value
        instance_cost = DB_INSTANCE_BASE_MONTHLY.get(db_key, 150)
        storage_gb = storage_proj.total_storage_bytes / (1024 ** 3)
        storage_cost = storage_gb * DB_STORAGE_PRICE_PER_GB
        iops_cost = max(0, (iops_proj.total_iops - 3000)) * DB_IOPS_PRICE_PER_IOP
        backup_cost = storage_gb * DB_BACKUP_PRICE_PER_GB * (7 / 30)
        license_cost = LICENSE_COSTS.get(db_key, 0)

        total = round(instance_cost + storage_cost + iops_cost + backup_cost + license_cost, 2)

        return DBCostBreakdown(
            topology_component_id=spec.topology_component_id,
            database_id=spec.database_id,
            instance_cost_monthly=round(instance_cost, 2),
            storage_cost_monthly=round(storage_cost, 2),
            iops_cost_monthly=round(iops_cost, 2),
            backup_cost_monthly=round(backup_cost, 2),
            license_cost_monthly=license_cost,
            total_monthly=total,
            tier_description=f"{db_key} managed instance",
        )

    def _calc_cache_cost(self, spec: CacheSpec) -> CacheCostBreakdown:
        db_key = spec.cache_database.value
        price_per_gb = CACHE_PRICE_PER_GB.get(db_key, 30)
        memory_cost = spec.memory_gb * price_per_gb * spec.cluster_nodes
        overhead = memory_cost * 0.15 if spec.high_availability else 0
        total = round(memory_cost + overhead, 2)
        return CacheCostBreakdown(
            topology_component_id=spec.topology_component_id,
            memory_cost_monthly=round(memory_cost, 2),
            cluster_overhead_monthly=round(overhead, 2),
            total_monthly=total,
        )

    def _calc_lb_cost(self, spec: LoadBalancerSpec) -> LBCostBreakdown:
        lcu_cost = LB_LCU_PRICE_HOUR * HOURS_PER_MONTH
        data_cost = spec.estimated_data_processed_gb_month * 0.008
        total = round(LB_FIXED_MONTHLY + lcu_cost + data_cost, 2)
        return LBCostBreakdown(
            topology_component_id=spec.topology_component_id,
            fixed_cost_monthly=LB_FIXED_MONTHLY,
            lcu_cost_monthly=round(lcu_cost, 2),
            data_processing_cost_monthly=round(data_cost, 2),
            total_monthly=total,
        )

    def _calc_cdn_cost(self, spec: CDNSpec) -> CDNCostBreakdown:
        transfer_cost = spec.estimated_data_transfer_gb_month * CDN_PRICE_PER_GB
        request_cost = spec.estimated_requests_million_month * 1000 * CDN_PRICE_PER_10K_REQUESTS / 10
        ssl_cost = 0.0
        total = round(transfer_cost + request_cost + ssl_cost, 2)
        return CDNCostBreakdown(
            topology_component_id=spec.topology_component_id,
            data_transfer_cost_monthly=round(transfer_cost, 2),
            request_cost_monthly=round(request_cost, 2),
            ssl_cost_monthly=ssl_cost,
            total_monthly=total,
        )

    def _calc_api_gateway_cost(self, spec: APIGatewaySpec) -> APIGatewayCostBreakdown:
        monthly_requests = spec.estimated_requests_per_second * 3600 * 24 * 30
        request_cost = (monthly_requests / 1_000_000) * API_GATEWAY_PRICE_PER_MILLION_REQUESTS
        # Estimate ~1KB per request for data transfer
        data_gb = monthly_requests * 0.001 / (1024 ** 2)
        data_cost = data_gb * API_GATEWAY_DATA_TRANSFER_PER_GB
        total = round(request_cost + data_cost, 2)
        return APIGatewayCostBreakdown(
            topology_component_id=spec.topology_component_id,
            request_cost_monthly=round(request_cost, 2),
            data_transfer_cost_monthly=round(data_cost, 2),
            total_monthly=total,
        )

    def _calc_object_storage_cost(self, spec: ObjectStorageSpec) -> ObjectStorageCostBreakdown:
        storage_cost = spec.estimated_storage_gb * OBJECT_STORAGE_PRICE_PER_GB
        request_cost = (spec.estimated_requests_per_month / 1000) * OBJECT_STORAGE_REQUEST_PRICE_PER_1000
        egress_cost = spec.estimated_egress_gb_month * OBJECT_STORAGE_EGRESS_PER_GB
        total = round(storage_cost + request_cost + egress_cost, 2)
        return ObjectStorageCostBreakdown(
            topology_component_id=spec.topology_component_id,
            storage_cost_monthly=round(storage_cost, 2),
            request_cost_monthly=round(request_cost, 2),
            egress_cost_monthly=round(egress_cost, 2),
            total_monthly=total,
        )

    # ── Aggregation helpers ─────────────────────────────────────

    def _aggregate_categories(
        self, costs: list[ComponentCostSummary], total: float,
    ) -> list[CategoryCostSummary]:
        category_map: dict[str, float] = {}
        for c in costs:
            cat = c.component_type.value
            category_map[cat] = category_map.get(cat, 0) + c.total_monthly

        return [
            CategoryCostSummary(
                category=cat,
                total_monthly=round(amount, 2),
                percentage=round((amount / total * 100) if total > 0 else 0, 2),
            )
            for cat, amount in sorted(category_map.items(), key=lambda x: -x[1])
        ]

    def _calc_growth_projections(
        self, project: Project, topology: Topology,
    ) -> list[GrowthProjection]:
        projections: list[GrowthProjection] = []
        for target in topology.growth_targets:
            per_component: list[ComponentCostSummary] = []
            ratio = target / max(topology.base_user_count, 1)

            # Scale compute linearly with user count (simplified)
            for cid, spec_data in (project.compute_specs or {}).items():
                spec = ComputeSpec.model_validate(spec_data)
                base = self._calc_compute_cost(spec)
                scaled = round(base.total_monthly * max(1, ratio ** 0.5), 2)
                per_component.append(ComponentCostSummary(
                    topology_component_id=cid,
                    component_name=self._component_name(topology, cid),
                    component_type=ComponentType.COMPUTE,
                    total_monthly=scaled,
                ))

            # DB scales with storage (linear with users)
            for cid, spec_data in (project.db_specs or {}).items():
                spec = DBModelSpec.model_validate(spec_data)
                breakdown = self._calc_db_cost(spec, target)
                per_component.append(ComponentCostSummary(
                    topology_component_id=cid,
                    component_name=self._component_name(topology, cid),
                    component_type=ComponentType.DATABASE,
                    total_monthly=breakdown.total_monthly,
                ))

            # Cache, LB, CDN scale moderately
            for cid, spec_data in (project.cache_specs or {}).items():
                spec = CacheSpec.model_validate(spec_data)
                base = self._calc_cache_cost(spec)
                scaled = round(base.total_monthly * max(1, ratio ** 0.3), 2)
                per_component.append(ComponentCostSummary(
                    topology_component_id=cid,
                    component_name=self._component_name(topology, cid),
                    component_type=ComponentType.CACHE,
                    total_monthly=scaled,
                ))

            for cid, spec_data in (project.lb_specs or {}).items():
                spec = LoadBalancerSpec.model_validate(spec_data)
                base = self._calc_lb_cost(spec)
                per_component.append(ComponentCostSummary(
                    topology_component_id=cid,
                    component_name=self._component_name(topology, cid),
                    component_type=ComponentType.LOAD_BALANCER,
                    total_monthly=base.total_monthly,
                ))

            for cid, spec_data in (project.cdn_specs or {}).items():
                spec = CDNSpec.model_validate(spec_data)
                base = self._calc_cdn_cost(spec)
                scaled = round(base.total_monthly * max(1, ratio ** 0.4), 2)
                per_component.append(ComponentCostSummary(
                    topology_component_id=cid,
                    component_name=self._component_name(topology, cid),
                    component_type=ComponentType.CDN,
                    total_monthly=scaled,
                ))

            total = round(sum(c.total_monthly for c in per_component), 2)
            projections.append(GrowthProjection(
                user_count=target,
                total_monthly=total,
                per_component=per_component,
            ))

        return projections

    def _generate_hints(
        self, costs: list[ComponentCostSummary], project: Project,
    ) -> list[OptimizationHint]:
        hints: list[OptimizationHint] = []

        # Hint: no cache configured but DB costs are significant
        has_cache = bool(project.cache_specs)
        db_cost = sum(c.total_monthly for c in costs if c.component_type == ComponentType.DATABASE)
        if not has_cache and db_cost > 100:
            hints.append(OptimizationHint(
                category="caching",
                message="Adding a cache layer (Redis/Valkey) could reduce DB read IOPS and lower DB costs.",
                estimated_savings_monthly=round(db_cost * 0.25, 2),
                confidence=0.7,
            ))

        # Hint: compute costs dominate — suggest reserved instances
        compute_cost = sum(c.total_monthly for c in costs if c.component_type == ComponentType.COMPUTE)
        total = sum(c.total_monthly for c in costs)
        if total > 0 and (compute_cost / total) > 0.5:
            hints.append(OptimizationHint(
                category="compute",
                message="Compute is >50% of total cost. Reserved or spot instances could save 30-60%.",
                estimated_savings_monthly=round(compute_cost * 0.35, 2),
                confidence=0.8,
            ))

        # Hint: no CDN but LB has high data processing
        has_cdn = bool(project.cdn_specs)
        if not has_cdn and project.lb_specs:
            hints.append(OptimizationHint(
                category="network",
                message="Adding a CDN for static assets can reduce load balancer data processing costs.",
                estimated_savings_monthly=15.0,
                confidence=0.5,
            ))

        return hints

    def _component_name(self, topology: Topology, component_id: str) -> str:
        for c in topology.components:
            if c.id == component_id:
                return c.name
        return component_id

    async def _get_or_404(self, project_id: str) -> Project:
        project = await self.repo.get_project_by_id(project_id)
        if not project:
            raise HTTPException(status_code=404, detail="Project not found")
        return project
