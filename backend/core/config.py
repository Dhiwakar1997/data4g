import os
from dotenv import load_dotenv

env_file = os.getenv("ENV_FILE", ".env.dev")
load_dotenv(env_file)


def _split_csv_env(name: str, default: str) -> list[str]:
    return [
        item.strip()
        for item in os.getenv(name, default).split(",")
        if item.strip()
    ]


class Settings:
    APP_NAME: str = os.getenv("APP_NAME", "DataForge")
    DEBUG: bool = os.getenv("DEBUG", "false").lower() == "true"
    EMAIL_VERIFICATION_REQUIRED: bool = os.getenv(
        "EMAIL_VERIFICATION_REQUIRED",
        "false" if DEBUG else "true",
    ).lower() == "true"

    # MongoDB
    MONGODB_URI: str = os.getenv("MONGODB_URI", "mongodb://localhost:27017")
    MONGODB_DB_NAME: str = os.getenv("MONGODB_DB_NAME", "dataforge")

    # JWT
    SECRET_KEY: str = os.getenv("SECRET_KEY", "change-me-in-production")
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "60"))
    REFRESH_TOKEN_EXPIRE_DAYS: int = int(os.getenv("REFRESH_TOKEN_EXPIRE_DAYS", "30"))

    # CORS
    CORS_ORIGINS: list[str] = _split_csv_env(
        "CORS_ORIGINS",
        "http://localhost:3000,http://localhost:8080,http://localhost:5173",
    )
    CORS_ORIGIN_REGEX: str = os.getenv(
        "CORS_ORIGIN_REGEX",
        r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$",
    )

    # SMTP (optional — email features disabled when not set)
    SMTP_SERVER: str = os.getenv("SMTP_SERVER", "smtp.gmail.com")
    SMTP_PORT: int = int(os.getenv("SMTP_PORT", "587"))
    SMTP_USERNAME: str | None = os.getenv("SMTP_USERNAME")
    SMTP_PASSWORD: str | None = os.getenv("SMTP_PASSWORD")
    DOMAIN_ENDPOINT: str = os.getenv("ENDPOINT", "http://localhost:8000")

    # Google OAuth (optional — google auth disabled when not set)
    GOOGLE_WEB_CLIENT_ID: str | None = os.getenv("GOOGLE_WEB_CLIENT_ID")

    # Pricing API (optional — uses defaults when not set)
    AWS_PRICING_API_KEY: str | None = os.getenv("AWS_PRICING_API_KEY")
    GCP_BILLING_API_KEY: str | None = os.getenv("GCP_BILLING_API_KEY")
    AZURE_PRICING_API_KEY: str | None = os.getenv("AZURE_PRICING_API_KEY")

    # Scan ingestion (formerly MCP_SERVER_* — analyzer now lives in the
    # client-side `data4g-mcp` package; backend just validates inbound writes)
    SCANNER_ENABLED: bool = os.getenv(
        "SCANNER_ENABLED",
        os.getenv("MCP_SERVER_ENABLED", "false"),
    ).lower() == "true"

    # Pricing sync schedule (cron expression)
    PRICING_SYNC_CRON: str = os.getenv("PRICING_SYNC_CRON", "0 3 * * *")


settings = Settings()
