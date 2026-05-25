"""Web scraper skill for fetching and parsing web page content."""

import ipaddress
import logging
import socket
from typing import Any
from urllib.parse import urlparse

import httpx
from bs4 import BeautifulSoup

from app.services.skills.base_skill import BaseSkill

logger = logging.getLogger(__name__)

MAX_CONTENT_LENGTH = 5000

# Tags to remove from parsed HTML
REMOVE_TAGS = ["script", "style", "nav", "footer", "header", "aside", "iframe", "noscript"]


def _is_private_ip(hostname: str) -> bool:
    """Check if a hostname resolves to a private/internal IP address."""
    try:
        ip_str = socket.gethostbyname(hostname)
        ip = ipaddress.ip_address(ip_str)
        return ip.is_private or ip.is_loopback or ip.is_reserved or ip.is_link_local
    except (socket.gaierror, ValueError):
        return True  # Block if we can't resolve


class WebScraperSkill(BaseSkill):
    """Fetch and extract text content from a web page."""

    name = "web_scraper"
    description = "Fetch and extract text content from a web page URL"
    parameters = {
        "type": "object",
        "properties": {
            "url": {
                "type": "string",
                "description": "The HTTPS URL to scrape content from",
            },
        },
        "required": ["url"],
    }

    async def execute(self, params: dict[str, Any]) -> dict[str, Any]:
        """Fetch URL and extract readable text content."""
        try:
            url = params.get("url", "").strip()
            if not url:
                return {"error": "URL is required"}

            # Validate URL scheme
            parsed = urlparse(url)
            if parsed.scheme != "https":
                return {"error": "Only HTTPS URLs are supported"}

            if not parsed.hostname:
                return {"error": "Invalid URL: no hostname"}

            # Block private/internal IPs
            if _is_private_ip(parsed.hostname):
                return {"error": "Access to internal/private addresses is not allowed"}

            # Fetch the page
            async with httpx.AsyncClient(
                timeout=15.0,
                follow_redirects=True,
                max_redirects=5,
            ) as client:
                response = await client.get(
                    url,
                    headers={
                        "User-Agent": "Mozilla/5.0 (compatible; MioBot/1.0)",
                        "Accept": "text/html,application/xhtml+xml",
                    },
                )
                response.raise_for_status()

            content_type = response.headers.get("content-type", "")
            if "text/html" not in content_type and "text/plain" not in content_type:
                return {"error": f"Unsupported content type: {content_type}"}

            # Parse HTML and extract text
            soup = BeautifulSoup(response.text, "lxml")

            # Remove unwanted tags
            for tag in soup.find_all(REMOVE_TAGS):
                tag.decompose()

            # Extract text
            text = soup.get_text(separator="\n", strip=True)

            # Clean up whitespace
            lines = [line.strip() for line in text.splitlines() if line.strip()]
            cleaned_text = "\n".join(lines)

            # Truncate to max length
            if len(cleaned_text) > MAX_CONTENT_LENGTH:
                cleaned_text = cleaned_text[:MAX_CONTENT_LENGTH] + "..."

            return {
                "content": cleaned_text,
                "url": url,
                "title": soup.title.string.strip() if soup.title and soup.title.string else "",
                "length": len(cleaned_text),
            }

        except httpx.HTTPStatusError as e:
            logger.error("Web scraper HTTP error: %s", str(e))
            return {"error": f"HTTP error {e.response.status_code}: {e.response.reason_phrase}"}
        except httpx.TimeoutException:
            logger.error("Web scraper timeout for URL: %s", params.get("url", ""))
            return {"error": "Request timed out"}
        except Exception as e:
            logger.error("Web scraper error: %s", str(e))
            return {"error": f"Failed to scrape URL: {str(e)}"}
