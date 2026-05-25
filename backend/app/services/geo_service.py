"""Geo service - IP geolocation and VPN/proxy detection."""

import logging
from typing import Optional

import httpx

logger = logging.getLogger(__name__)


class GeoService:
    """Service for IP geolocation and proxy detection."""

    async def get_country_code(self, ip: str) -> str:
        """
        Get country code from IP address.

        Args:
            ip: Client IP address

        Returns:
            Two-letter country code or 'US' as default
        """
        try:
            async with httpx.AsyncClient(timeout=3.0) as client:
                response = await client.get(
                    f"http://ip-api.com/json/{ip}",
                    params={"fields": "countryCode"},
                )
                if response.status_code == 200:
                    return response.json().get("countryCode", "US")
        except Exception as e:
            logger.error(f"Country detection failed: {str(e)}")
        return "US"

    async def check_proxy(self, ip: str) -> dict:
        """
        Detect VPN/proxy/hosting IPs.

        Args:
            ip: Client IP address

        Returns:
            Dict with proxy detection results
        """
        try:
            async with httpx.AsyncClient(timeout=3.0) as client:
                response = await client.get(
                    f"http://ip-api.com/json/{ip}",
                    params={"fields": "countryCode,proxy,hosting,mobile"},
                )
                if response.status_code == 200:
                    data = response.json()
                    return {
                        "country_code": data.get("countryCode", "US"),
                        "is_proxy": data.get("proxy", False),
                        "is_hosting": data.get("hosting", False),
                        "is_mobile": data.get("mobile", False),
                    }
        except Exception as e:
            logger.error(f"Proxy check failed: {str(e)}")

        return {
            "country_code": "US",
            "is_proxy": False,
            "is_hosting": False,
            "is_mobile": False,
        }


geo_service = GeoService()
