from datetime import datetime
from uuid import uuid4

from pydantic import BaseModel, Field


class DBCallMetadata(BaseModel):
    query_type: str
    target_entity: str
    is_paginated: bool = False
    estimated_rows_affected: str | None = None
    raw_query_pattern: str | None = None


class CacheCallMetadata(BaseModel):
    operation: str
    key_pattern: str
    ttl_seconds: int | None = None


class ServiceCallMetadata(BaseModel):
    target_service: str
    target_endpoint: str
    http_method: str = "GET"
    is_async: bool = False


class QueueInteraction(BaseModel):
    role: str
    queue_name: str
    message_type: str | None = None


class EndpointMetadata(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid4()))
    path: str
    http_method: str
    handler_function: str
    source_file: str
    db_calls: list[DBCallMetadata] = []
    cache_calls: list[CacheCallMetadata] = []
    service_calls: list[ServiceCallMetadata] = []
    queue_interactions: list[QueueInteraction] = []
    estimated_response_time_ms: float | None = None
    risk_score: float = 0.0
    risk_findings: list[str] = []


class ServerEndpointRegistry(BaseModel):
    topology_component_id: str
    endpoints: list[EndpointMetadata] = []
    last_synced_at: datetime | None = None
    sync_version: int = 0
