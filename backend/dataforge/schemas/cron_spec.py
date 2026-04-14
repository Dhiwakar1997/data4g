from pydantic import BaseModel


class CronSchedule(BaseModel):
    cron_expression: str = "0 */6 * * *"
    timezone: str = "UTC"


class CronJobSpec(BaseModel):
    topology_component_id: str
    schedule: CronSchedule = CronSchedule()
    target_service_component_id: str | None = None
    target_endpoint: str | None = None
    retry_policy: dict = {"max_retries": 3, "backoff_seconds": 60}
    timeout_seconds: int = 300
    estimated_duration_seconds: int = 30
    estimated_compute_cost_per_run: float = 0.01


class CronJobSpecUpdateRequest(BaseModel):
    schedule: CronSchedule | None = None
    target_service_component_id: str | None = None
    target_endpoint: str | None = None
    retry_policy: dict | None = None
    timeout_seconds: int | None = None
    estimated_duration_seconds: int | None = None
    estimated_compute_cost_per_run: float | None = None
