from pydantic import BaseModel, Field


class TopologyCompareRequest(BaseModel):
    """Request to compare two topologies."""
    source_project_id: str
    source_topology_id: str
    target_project_id: str
    target_topology_id: str


class ComponentDiff(BaseModel):
    """Difference for a single component between two topologies."""
    component_name: str
    component_type: str
    status: str  # "added", "removed", "modified", "unchanged"
    source_config: dict | None = None
    target_config: dict | None = None
    changes: list[str] = Field(default_factory=list)


class TopologyCompareResponse(BaseModel):
    source_project_id: str
    source_topology_id: str
    source_topology_name: str
    target_project_id: str
    target_topology_id: str
    target_topology_name: str
    source_component_count: int
    target_component_count: int
    source_edge_count: int
    target_edge_count: int
    source_deployment_mode: str
    target_deployment_mode: str
    component_diffs: list[ComponentDiff] = Field(default_factory=list)
    added_components: int = 0
    removed_components: int = 0
    modified_components: int = 0
    unchanged_components: int = 0
