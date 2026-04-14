from pydantic import BaseModel


class RateLimitConfig(BaseModel):
    enabled: bool = True
    requests_per_second: int = 100
    burst_size: int = 200
    window_seconds: int = 60


class AuthConfig(BaseModel):
    type: str = "jwt"
    provider: str | None = None


class RoutingRule(BaseModel):
    path_pattern: str
    target_component_id: str
    methods: list[str] = ["GET", "POST", "PUT", "DELETE"]
    strip_prefix: bool = False


class APIGatewaySpec(BaseModel):
    topology_component_id: str
    rate_limiting: RateLimitConfig = RateLimitConfig()
    auth_config: AuthConfig = AuthConfig()
    routing_rules: list[RoutingRule] = []
    cors_enabled: bool = True
    request_logging: bool = True
    estimated_requests_per_second: float = 100.0


class APIGatewaySpecUpdateRequest(BaseModel):
    rate_limiting: RateLimitConfig | None = None
    auth_config: AuthConfig | None = None
    routing_rules: list[RoutingRule] | None = None
    cors_enabled: bool | None = None
    request_logging: bool | None = None
    estimated_requests_per_second: float | None = None


class APIGatewayCostBreakdown(BaseModel):
    topology_component_id: str
    request_cost_monthly: float
    data_transfer_cost_monthly: float
    total_monthly: float
