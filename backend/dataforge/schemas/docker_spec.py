from pydantic import BaseModel, Field

from dataforge.schemas.enums import ContainerProtocol, DockerRestartPolicy


class DockerPortMapping(BaseModel):
    """Port mapping for a Docker container."""
    host_port: int = Field(..., ge=1, le=65535)
    container_port: int = Field(..., ge=1, le=65535)
    protocol: ContainerProtocol = ContainerProtocol.TCP


class DockerVolumeMount(BaseModel):
    """Volume mount for a Docker container."""
    host_path: str | None = None
    container_path: str
    volume_name: str | None = None  # named volume
    read_only: bool = False


class DockerEnvVar(BaseModel):
    """Environment variable for a Docker container."""
    name: str
    value: str


class DockerHealthCheck(BaseModel):
    """Health check for a Docker container."""
    test: str  # e.g., "CMD curl -f http://localhost:8080/health"
    interval_seconds: int = 30
    timeout_seconds: int = 10
    retries: int = 3
    start_period_seconds: int = 5


class DockerResourceLimits(BaseModel):
    """Resource constraints for a Docker container."""
    cpu_count: float | None = None       # e.g., 0.5, 1.0, 2.0
    memory_limit: str | None = None      # e.g., "512m", "1g"
    memory_reservation: str | None = None


class DockerContainerSpec(BaseModel):
    """
    Docker container configuration for a compute component.
    Tied to a TopologyComponent of type COMPUTE.
    """
    topology_component_id: str
    container_name: str
    image: str
    tag: str = "latest"
    ports: list[DockerPortMapping] = Field(default_factory=list)
    volumes: list[DockerVolumeMount] = Field(default_factory=list)
    env: list[DockerEnvVar] = Field(default_factory=list)
    restart_policy: DockerRestartPolicy = DockerRestartPolicy.UNLESS_STOPPED
    health_check: DockerHealthCheck | None = None
    resources: DockerResourceLimits = Field(default_factory=DockerResourceLimits)
    network: str = "bridge"
    depends_on: list[str] = Field(default_factory=list)
    labels: dict[str, str] = Field(default_factory=dict)
    command: str | None = None
    entrypoint: str | None = None


class DockerSpecUpdateRequest(BaseModel):
    container_name: str | None = None
    image: str | None = None
    tag: str | None = None
    ports: list[DockerPortMapping] | None = None
    volumes: list[DockerVolumeMount] | None = None
    env: list[DockerEnvVar] | None = None
    restart_policy: DockerRestartPolicy | None = None
    health_check: DockerHealthCheck | None = None
    resources: DockerResourceLimits | None = None
    network: str | None = None
    depends_on: list[str] | None = None
    labels: dict[str, str] | None = None
    command: str | None = None
    entrypoint: str | None = None
