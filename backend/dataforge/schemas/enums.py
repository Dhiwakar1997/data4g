from enum import Enum


class CloudProvider(str, Enum):
    AWS = "aws"
    GCP = "gcp"
    AZURE = "azure"
    SELF_HOSTED = "self_hosted"


class Region(str, Enum):
    US_EAST_1 = "us-east-1"
    US_WEST_2 = "us-west-2"
    EU_WEST_1 = "eu-west-1"
    EU_CENTRAL_1 = "eu-central-1"
    AP_SOUTH_1 = "ap-south-1"
    AP_SOUTHEAST_1 = "ap-southeast-1"
    AP_NORTHEAST_1 = "ap-northeast-1"
    SA_EAST_1 = "sa-east-1"


class DeploymentMode(str, Enum):
    SINGLE_INSTANCE = "single_instance"
    MULTI_TIER = "multi_tier"
    DISTRIBUTED = "distributed"


class TopologyType(str, Enum):
    LIVE = "live"
    EXPERIMENTAL = "experimental"


class ComponentType(str, Enum):
    COMPUTE = "compute"
    DATABASE = "database"
    CACHE = "cache"
    LOAD_BALANCER = "load_balancer"
    CDN = "cdn"
    CLIENT = "client"
    OBJECT_STORE = "object_store"
    MESSAGE_QUEUE = "message_queue"
    API_GATEWAY = "api_gateway"
    CRON_JOB = "cron_job"
    THIRD_PARTY_API = "third_party_api"
    SERVICE_MESH = "service_mesh"
    KUBERNETES_NODE = "kubernetes_node"


class RiskSeverity(str, Enum):
    CRITICAL = "critical"
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"
    INFO = "info"


class RiskType(str, Enum):
    N_PLUS_ONE = "n_plus_one"
    MISSING_PAGINATION = "missing_pagination"
    UNBOUNDED_FETCH = "unbounded_fetch"
    FULL_TABLE_SCAN = "full_table_scan"
    MISSING_INDEX = "missing_index"
    INEFFICIENT_JOIN = "inefficient_join"
    RACE_CONDITION = "race_condition"


class SyncMode(str, Enum):
    ON_DEMAND = "on_demand"
    CI_CD = "ci_cd"


# ── Database identifiers across all 7 categories ───────────────

class DatabaseId(str, Enum):
    # SQL
    POSTGRESQL = "postgresql"
    MYSQL = "mysql"
    ORACLE = "oracle"
    SQLSERVER = "sqlserver"
    MARIADB = "mariadb"
    COCKROACHDB = "cockroachdb"
    SQLITE = "sqlite"
    # Document / KV
    MONGODB = "mongodb"
    DYNAMODB = "dynamodb"
    CASSANDRA = "cassandra"
    COUCHDB = "couchdb"
    FIREBASE = "firebase"
    # In-Memory
    REDIS = "redis"
    VALKEY = "valkey"
    MEMCACHED = "memcached"
    DRAGONFLY = "dragonfly"
    # Graph
    NEO4J = "neo4j"
    NEPTUNE = "neptune"
    ARANGODB = "arangodb"
    DGRAPH = "dgraph"
    # Vector
    PINECONE = "pinecone"
    WEAVIATE = "weaviate"
    MILVUS = "milvus"
    QDRANT = "qdrant"
    CHROMADB = "chromadb"
    PGVECTOR = "pgvector"
    # Search
    ELASTICSEARCH = "elasticsearch"
    OPENSEARCH = "opensearch"
    # Time-Series
    INFLUXDB = "influxdb"
    TIMESCALEDB = "timescaledb"


class DatabaseCategory(str, Enum):
    SQL = "sql"
    DOCUMENT_KV = "document_kv"
    IN_MEMORY = "in_memory"
    GRAPH = "graph"
    VECTOR = "vector"
    SEARCH = "search"
    TIME_SERIES = "time_series"


# Maps each DatabaseId to its category
DATABASE_CATEGORY_MAP: dict[DatabaseId, DatabaseCategory] = {
    DatabaseId.POSTGRESQL: DatabaseCategory.SQL,
    DatabaseId.MYSQL: DatabaseCategory.SQL,
    DatabaseId.ORACLE: DatabaseCategory.SQL,
    DatabaseId.SQLSERVER: DatabaseCategory.SQL,
    DatabaseId.MARIADB: DatabaseCategory.SQL,
    DatabaseId.COCKROACHDB: DatabaseCategory.SQL,
    DatabaseId.SQLITE: DatabaseCategory.SQL,
    DatabaseId.MONGODB: DatabaseCategory.DOCUMENT_KV,
    DatabaseId.DYNAMODB: DatabaseCategory.DOCUMENT_KV,
    DatabaseId.CASSANDRA: DatabaseCategory.DOCUMENT_KV,
    DatabaseId.COUCHDB: DatabaseCategory.DOCUMENT_KV,
    DatabaseId.FIREBASE: DatabaseCategory.DOCUMENT_KV,
    DatabaseId.REDIS: DatabaseCategory.IN_MEMORY,
    DatabaseId.VALKEY: DatabaseCategory.IN_MEMORY,
    DatabaseId.MEMCACHED: DatabaseCategory.IN_MEMORY,
    DatabaseId.DRAGONFLY: DatabaseCategory.IN_MEMORY,
    DatabaseId.NEO4J: DatabaseCategory.GRAPH,
    DatabaseId.NEPTUNE: DatabaseCategory.GRAPH,
    DatabaseId.ARANGODB: DatabaseCategory.GRAPH,
    DatabaseId.DGRAPH: DatabaseCategory.GRAPH,
    DatabaseId.PINECONE: DatabaseCategory.VECTOR,
    DatabaseId.WEAVIATE: DatabaseCategory.VECTOR,
    DatabaseId.MILVUS: DatabaseCategory.VECTOR,
    DatabaseId.QDRANT: DatabaseCategory.VECTOR,
    DatabaseId.CHROMADB: DatabaseCategory.VECTOR,
    DatabaseId.PGVECTOR: DatabaseCategory.VECTOR,
    DatabaseId.ELASTICSEARCH: DatabaseCategory.SEARCH,
    DatabaseId.OPENSEARCH: DatabaseCategory.SEARCH,
    DatabaseId.INFLUXDB: DatabaseCategory.TIME_SERIES,
    DatabaseId.TIMESCALEDB: DatabaseCategory.TIME_SERIES,
}


# ── Entity / field level enums ──────────────────────────────────

class RelationshipType(str, Enum):
    ONE_TO_ONE = "1:1"
    ONE_TO_MANY = "1:N"
    MANY_TO_MANY = "N:M"


class FieldType(str, Enum):
    STRING = "string"
    TEXT = "text"
    INTEGER = "integer"
    FLOAT = "float"
    DECIMAL = "decimal"
    BOOLEAN = "boolean"
    DATE = "date"
    DATETIME = "datetime"
    TIMESTAMP = "timestamp"
    UUID = "uuid"
    JSON = "json"
    ARRAY = "array"
    BINARY = "binary"
    ENUM = "enum"
    VECTOR = "vector"
    GEOSPATIAL = "geospatial"
    REFERENCE = "reference"


class KeyType(str, Enum):
    PRIMARY = "primary"
    FOREIGN = "foreign"
    COMPOSITE_PRIMARY = "composite_primary"
    NONE = "none"


class IndexType(str, Enum):
    BTREE = "btree"
    HASH = "hash"
    GIN = "gin"
    GIST = "gist"
    FULLTEXT = "fulltext"
    VECTOR_HNSW = "vector_hnsw"
    VECTOR_IVFFLAT = "vector_ivfflat"


# ── Infrastructure enums ────────────────────────────────────────

class GPUType(str, Enum):
    NONE = "none"
    T4 = "t4"
    A10G = "a10g"
    A100 = "a100"
    L4 = "l4"
    H100 = "h100"


class LBAlgorithm(str, Enum):
    ROUND_ROBIN = "round_robin"
    LEAST_CONNECTIONS = "least_connections"
    IP_HASH = "ip_hash"
    WEIGHTED = "weighted"


class CDNProvider(str, Enum):
    CLOUDFRONT = "cloudfront"
    CLOUDFLARE = "cloudflare"
    FASTLY = "fastly"
    AKAMAI = "akamai"
    NONE = "none"


class CacheEvictionPolicy(str, Enum):
    LRU = "lru"
    LFU = "lfu"
    TTL = "ttl"
    RANDOM = "random"
    ALLKEYS_LRU = "allkeys_lru"


# ── Access control enums ─────────────────────────────────────

class ProjectRole(str, Enum):
    OWNER = "owner"
    MEMBER = "member"


# ── Orchestration enums ──────────────────────────────────────

class K8sServiceType(str, Enum):
    CLUSTER_IP = "ClusterIP"
    NODE_PORT = "NodePort"
    LOAD_BALANCER = "LoadBalancer"


class K8sRestartPolicy(str, Enum):
    ALWAYS = "Always"
    ON_FAILURE = "OnFailure"
    NEVER = "Never"


class ContainerProtocol(str, Enum):
    TCP = "TCP"
    UDP = "UDP"


class DockerRestartPolicy(str, Enum):
    NO = "no"
    ALWAYS = "always"
    UNLESS_STOPPED = "unless-stopped"
    ON_FAILURE = "on-failure"
