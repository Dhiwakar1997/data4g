from pydantic import BaseModel


class ThirdPartyAPISpec(BaseModel):
    topology_component_id: str
    url: str = ""
    sla_uptime_percentage: float = 99.9
    expected_latency_ms: float = 200.0
    fallback_behavior: str = "circuit_breaker"
    estimated_calls_per_month: int = 100_000
    cost_per_call: float = 0.0
    monthly_subscription_cost: float = 0.0


class ThirdPartyAPISpecUpdateRequest(BaseModel):
    url: str | None = None
    sla_uptime_percentage: float | None = None
    expected_latency_ms: float | None = None
    fallback_behavior: str | None = None
    estimated_calls_per_month: int | None = None
    cost_per_call: float | None = None
    monthly_subscription_cost: float | None = None
