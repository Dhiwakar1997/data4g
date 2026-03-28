from pydantic import BaseModel, Field

from dataforge.schemas.enums import (
    K8sServiceType, K8sRestartPolicy, ContainerProtocol,
)


class K8sResourceLimits(BaseModel):
    """CPU and memory limits for a k8s container."""
    cpu_request: str = "100m"       # e.g., "100m", "0.5", "2"
    cpu_limit: str = "500m"
    memory_request: str = "128Mi"   # e.g., "128Mi", "1Gi"
    memory_limit: str = "512Mi"


class K8sContainerPort(BaseModel):
    """A port exposed by a container in a k8s pod."""
    name: str = ""
    container_port: int = Field(..., ge=1, le=65535)
    protocol: ContainerProtocol = ContainerProtocol.TCP


class K8sEnvVar(BaseModel):
    """Environment variable for a k8s container."""
    name: str
    value: str | None = None
    value_from_secret: str | None = None  # secret_name:key


class K8sContainer(BaseModel):
    """A container definition within a k8s pod."""
    name: str
    image: str
    tag: str = "latest"
    ports: list[K8sContainerPort] = Field(default_factory=list)
    env: list[K8sEnvVar] = Field(default_factory=list)
    resources: K8sResourceLimits = Field(default_factory=K8sResourceLimits)
    command: list[str] | None = None
    args: list[str] | None = None


class K8sHPA(BaseModel):
    """Horizontal Pod Autoscaler configuration."""
    enabled: bool = False
    min_replicas: int = Field(default=1, ge=1)
    max_replicas: int = Field(default=10, ge=1)
    target_cpu_utilization: int = Field(default=70, ge=1, le=100)
    target_memory_utilization: int | None = None


class K8sServiceConfig(BaseModel):
    """Kubernetes Service configuration."""
    type: K8sServiceType = K8sServiceType.CLUSTER_IP
    port: int = Field(default=80, ge=1, le=65535)
    target_port: int = Field(default=8080, ge=1, le=65535)
    node_port: int | None = Field(default=None, ge=30000, le=32767)


class K8sClusterSpec(BaseModel):
    """
    Kubernetes cluster and deployment configuration for a compute component.
    Tied to a TopologyComponent of type COMPUTE.
    """
    topology_component_id: str
    namespace: str = "default"
    replicas: int = Field(default=1, ge=1)
    containers: list[K8sContainer] = Field(default_factory=list)
    restart_policy: K8sRestartPolicy = K8sRestartPolicy.ALWAYS
    service: K8sServiceConfig = Field(default_factory=K8sServiceConfig)
    hpa: K8sHPA = Field(default_factory=K8sHPA)
    node_selector: dict[str, str] = Field(default_factory=dict)
    labels: dict[str, str] = Field(default_factory=dict)
    annotations: dict[str, str] = Field(default_factory=dict)


class K8sSpecUpdateRequest(BaseModel):
    namespace: str | None = None
    replicas: int | None = Field(default=None, ge=1)
    containers: list[K8sContainer] | None = None
    restart_policy: K8sRestartPolicy | None = None
    service: K8sServiceConfig | None = None
    hpa: K8sHPA | None = None
    node_selector: dict[str, str] | None = None
    labels: dict[str, str] | None = None
    annotations: dict[str, str] | None = None
