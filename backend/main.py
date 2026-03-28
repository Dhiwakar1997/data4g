from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from core.config import settings
from core.db_client import init_db, close_db

# ── Import all routers ──────────────────────────────────────────

from users.route.auth_route import auth_router
from users.route.user_route import user_router

from dataforge.route.project_route import project_router
from dataforge.route.topology_route import topology_router
from dataforge.route.spec_route import spec_router
from dataforge.route.db_schema_route import db_schema_router
from dataforge.route.cost_route import cost_router
from dataforge.route.reference_route import reference_router
from dataforge.route.membership_route import membership_router
from dataforge.route.comparison_route import comparison_router


# ── Lifespan (Motor + Beanie init / shutdown) ───────────────────

@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    yield
    await close_db()


# ── App ─────────────────────────────────────────────────────────

app = FastAPI(
    title=settings.APP_NAME,
    version="0.1.0",
    description="Data model & infrastructure cost planner API",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_origin_regex=settings.CORS_ORIGIN_REGEX,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Health ──────────────────────────────────────────────────────

@app.get("/health", tags=["health"])
async def health():
    return {"status": "ok", "app": settings.APP_NAME, "version": "0.1.0"}


# ── Mount routers ───────────────────────────────────────────────

# Users / Auth
app.include_router(auth_router, prefix="/api/v1", tags=["auth"])
app.include_router(user_router, prefix="/api/v1", tags=["users"])

# DataForge
app.include_router(project_router, prefix="/api/v1", tags=["projects"])
app.include_router(topology_router, prefix="/api/v1", tags=["topology"])
app.include_router(spec_router, prefix="/api/v1", tags=["specs"])
app.include_router(db_schema_router, prefix="/api/v1", tags=["db-schema"])
app.include_router(cost_router, prefix="/api/v1", tags=["cost"])
app.include_router(reference_router, prefix="/api/v1", tags=["reference"])
app.include_router(membership_router, prefix="/api/v1", tags=["membership"])
app.include_router(comparison_router, prefix="/api/v1", tags=["comparison"])
