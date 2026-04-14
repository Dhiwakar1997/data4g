from pydantic import BaseModel


class CircuitBreakerConfig(BaseModel):
    enabled: bool = True
    failure_threshold: int = 5
    recovery_timeout_seconds: int = 30
    half_open_requests: int = 3


class ServiceMeshSpec(BaseModel):
    topology_component_id: str
    mtls_enabled: bool = True
    circuit_breaker: CircuitBreakerConfig = CircuitBreakerConfig()
    retry_policy: dict = {"max_retries": 3, "per_try_timeout_seconds": 5}
    load_balancing_algorithm: str = "round_robin"
    observability_enabled: bool = True
    sidecar_cpu_request: str = "100m"
    sidecar_memory_request: str = "128Mi"


class ServiceMeshSpecUpdateRequest(BaseModel):
    mtls_enabled: bool | None = None
    circuit_breaker: CircuitBreakerConfig | None = None
    retry_policy: dict | None = None
    load_balancing_algorithm: str | None = None
    observability_enabled: bool | None = None
    sidecar_cpu_request: str | None = None
    sidecar_memory_request: str | None = None
