"""Web scraper skill for URL validation and domain extraction."""
from urllib.parse import urlparse


class WebScraperSkill:
    """Validates URLs and extracts domain information."""

    ALLOWED_SCHEMES = {'http', 'https'}

    def validate_url(self, url: str) -> bool:
        """Check if a URL is valid and uses an allowed scheme."""
        try:
            result = urlparse(url)
            return result.scheme in self.ALLOWED_SCHEMES and bool(result.netloc)
        except Exception:
            return False

    def extract_domain(self, url: str) -> str:
        """Extract the domain from a URL."""
        if not self.validate_url(url):
            raise ValueError(f"Invalid URL: {url}")
        parsed = urlparse(url)
        return parsed.netloc

    def extract_path(self, url: str) -> str:
        """Extract the path from a URL."""
        if not self.validate_url(url):
            raise ValueError(f"Invalid URL: {url}")
        parsed = urlparse(url)
        return parsed.path or '/'
