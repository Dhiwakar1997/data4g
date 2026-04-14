import logging
from datetime import datetime

from dataforge.data.repository import CloudPricingRepository

logger = logging.getLogger(__name__)


# Default pricing fallbacks (used when DB has no synced data)
DEFAULT_PRICING = {
    ("aws", "ec2", "us-east-1", "general_purpose.medium"): 0.05,
    ("aws", "rds", "us-east-1", "db.m5.large"): 0.171,
    ("aws", "elasticache", "us-east-1", "cache.m5.large"): 0.156,
    ("aws", "s3", "us-east-1", "standard_storage_per_gb"): 0.023,
    ("aws", "s3", "us-east-1", "get_request_per_1000"): 0.0004,
    ("aws", "s3", "us-east-1", "put_request_per_1000"): 0.005,
    ("aws", "s3", "us-east-1", "egress_per_gb"): 0.09,
    ("aws", "api_gateway", "us-east-1", "request_per_million"): 3.50,
    ("aws", "api_gateway", "us-east-1", "data_transfer_per_gb"): 0.09,
    ("aws", "cloudfront", "us-east-1", "per_gb"): 0.085,
    ("aws", "alb", "us-east-1", "fixed_monthly"): 22.0,
}


class PricingSyncService:
    """Manages cloud pricing data. Sync from APIs or use defaults."""

    def __init__(self):
        self.repo = CloudPricingRepository()

    async def get_price(
        self, provider: str, service: str, region: str, sku: str,
    ) -> float:
        """Look up a price, falling back to defaults if not in DB."""
        db_price = await self.repo.get_price(provider, service, region, sku)
        if db_price is not None:
            return db_price
        return DEFAULT_PRICING.get((provider, service, region, sku), 0.0)

    async def sync_aws_pricing(self) -> int:
        """Fetch from AWS Pricing API and upsert into cloud_pricing collection.
        Currently seeds default pricing data."""
        count = 0
        for (provider, service, region, sku), price in DEFAULT_PRICING.items():
            if provider == "aws":
                await self.repo.upsert_price(
                    provider=provider,
                    service=service,
                    region=region,
                    sku=sku,
                    price=price,
                    unit="per_unit",
                )
                count += 1
        logger.info("Synced %d AWS pricing entries", count)
        return count

    async def sync_gcp_pricing(self) -> int:
        """Placeholder for GCP Cloud Billing API sync."""
        logger.info("GCP pricing sync not yet implemented")
        return 0

    async def sync_azure_pricing(self) -> int:
        """Placeholder for Azure Retail Prices API sync."""
        logger.info("Azure pricing sync not yet implemented")
        return 0

    async def sync_all(self) -> dict:
        """Run all provider syncs."""
        aws = await self.sync_aws_pricing()
        gcp = await self.sync_gcp_pricing()
        azure = await self.sync_azure_pricing()
        return {"aws": aws, "gcp": gcp, "azure": azure}
