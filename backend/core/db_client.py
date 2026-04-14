from motor.motor_asyncio import AsyncIOMotorClient
from beanie import init_beanie
from core.config import settings

_client: AsyncIOMotorClient | None = None


async def init_db():
    """Initialise Motor client and Beanie ODM with all document models."""
    global _client
    _client = AsyncIOMotorClient(settings.MONGODB_URI)

    # Import document models here to avoid circular imports
    from users.data.model import User
    from dataforge.data.model import (
        Project, ProjectMember,
        EndpointRegistry, RiskReport, CloudPricing, ShareLink, ScanSyncLog,
        ProjectApiKey, ScanSession,
    )
    from teams.data.model import Team, TeamInvite

    await init_beanie(
        connection_string=f"{settings.MONGODB_URI}/{settings.MONGODB_DB_NAME}",
        document_models=[
            User, Project, ProjectMember,
            Team, TeamInvite,
            EndpointRegistry, RiskReport, CloudPricing, ShareLink, ScanSyncLog,
            ProjectApiKey, ScanSession,
        ],
    )


async def close_db():
    """Close the Motor client connection."""
    global _client
    if _client:
        _client.close()
        _client = None


def get_database():
    """Get the Motor database instance (for ad-hoc queries outside Beanie)."""
    if not _client:
        raise RuntimeError("Database not initialised. Call init_db() first.")
    return _client[settings.MONGODB_DB_NAME]
