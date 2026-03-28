from fastapi import APIRouter, HTTPException

from dataforge.schemas.enums import (
    DatabaseId, DatabaseCategory, DATABASE_CATEGORY_MAP,
    Region, CloudProvider,
)

reference_router = APIRouter(prefix="/reference", tags=["reference"])


# ── Pre-built database metadata ─────────────────────────────────

_DB_METADATA = {
    DatabaseId.POSTGRESQL: {
        "name": "PostgreSQL", "category": "sql",
        "managed_services": ["AWS RDS", "Aurora", "Supabase"],
        "sharding": "Citus / native partitioning",
        "export_format": "SQL DDL / Prisma",
    },
    DatabaseId.MYSQL: {
        "name": "MySQL", "category": "sql",
        "managed_services": ["AWS RDS", "PlanetScale"],
        "sharding": "Vitess / ProxySQL",
        "export_format": "SQL DDL / Prisma",
    },
    DatabaseId.MONGODB: {
        "name": "MongoDB", "category": "document_kv",
        "managed_services": ["MongoDB Atlas"],
        "sharding": "Hash / Range keys",
        "export_format": "Mongoose schema",
    },
    DatabaseId.DYNAMODB: {
        "name": "DynamoDB", "category": "document_kv",
        "managed_services": ["AWS (native)"],
        "sharding": "Partition key (auto)",
        "export_format": "JSON table definition",
    },
    DatabaseId.REDIS: {
        "name": "Redis", "category": "in_memory",
        "managed_services": ["Redis Cloud", "ElastiCache"],
        "sharding": "Cluster (hash slots)",
        "export_format": "N/A (cache layer)",
    },
    DatabaseId.VALKEY: {
        "name": "Valkey", "category": "in_memory",
        "managed_services": ["ElastiCache (default)"],
        "sharding": "Cluster (hash slots)",
        "export_format": "N/A (cache layer)",
    },
    DatabaseId.NEO4J: {
        "name": "Neo4j", "category": "graph",
        "managed_services": ["AuraDB"],
        "sharding": "Fabric (enterprise)",
        "export_format": "Cypher",
    },
    DatabaseId.ELASTICSEARCH: {
        "name": "Elasticsearch", "category": "search",
        "managed_services": ["Elastic Cloud"],
        "sharding": "Index sharding",
        "export_format": "Elasticsearch mapping JSON",
    },
    DatabaseId.PINECONE: {
        "name": "Pinecone", "category": "vector",
        "managed_services": ["Pinecone (native)"],
        "sharding": "Namespace",
        "export_format": "Index config JSON",
    },
    DatabaseId.INFLUXDB: {
        "name": "InfluxDB", "category": "time_series",
        "managed_services": ["InfluxDB Cloud"],
        "sharding": "Tag partitioning",
        "export_format": "InfluxDB schema",
    },
}


@reference_router.get("/databases")
async def list_databases():
    result = []
    for db_id in DatabaseId:
        meta = _DB_METADATA.get(db_id, {})
        result.append({
            "id": db_id.value,
            "name": meta.get("name", db_id.value.title()),
            "category": DATABASE_CATEGORY_MAP.get(db_id, "unknown").value
                if DATABASE_CATEGORY_MAP.get(db_id) else "unknown",
        })
    return {"databases": result, "total": len(result)}


@reference_router.get("/databases/{db_id}")
async def get_database_detail(db_id: str):
    try:
        database_id = DatabaseId(db_id)
    except ValueError:
        raise HTTPException(status_code=404, detail=f"Unknown database: {db_id}")

    meta = _DB_METADATA.get(database_id, {})
    category = DATABASE_CATEGORY_MAP.get(database_id)

    return {
        "id": database_id.value,
        "name": meta.get("name", database_id.value.title()),
        "category": category.value if category else "unknown",
        "managed_services": meta.get("managed_services", []),
        "sharding": meta.get("sharding", "N/A"),
        "export_format": meta.get("export_format", "N/A"),
    }


@reference_router.get("/databases/categories")
async def list_categories():
    return {
        "categories": [
            {"id": c.value, "name": c.value.replace("_", " ").title()}
            for c in DatabaseCategory
        ]
    }


@reference_router.get("/regions")
async def list_regions():
    return {
        "regions": [{"id": r.value, "name": r.value} for r in Region]
    }


@reference_router.get("/cloud-providers")
async def list_cloud_providers():
    return {
        "providers": [{"id": p.value, "name": p.value.replace("_", " ").title()} for p in CloudProvider]
    }
