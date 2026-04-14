from datetime import datetime

from pydantic import BaseModel


class ExportRequest(BaseModel):
    topology_id: str
    format: str = "png"
    include_specs: bool = False
    include_cost_summary: bool = False


class ExportResponse(BaseModel):
    download_url: str
    format: str
    generated_at: datetime
    expires_at: datetime
