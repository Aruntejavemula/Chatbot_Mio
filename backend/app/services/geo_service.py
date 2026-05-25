"""Geo service - handles geographic detection for payment routing."""


class GeoService:
    """Service for detecting user country for payment gateway selection."""

    async def detect_country(self, ip_address: str) -> str:
        """Detect country from IP address."""
        pass

    def is_india(self, country_code: str) -> bool:
        """Check if the country code is India (for Razorpay routing)."""
        return country_code.upper() == "IN"
