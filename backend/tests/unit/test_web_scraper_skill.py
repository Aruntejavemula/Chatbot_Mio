"""Unit tests for WebScraperSkill."""
import pytest

from app.services.skills.web_scraper_skill import WebScraperSkill


@pytest.fixture
def scraper():
    return WebScraperSkill()


class TestValidateUrl:
    """Tests for WebScraperSkill.validate_url."""

    def test_valid_https_url(self, scraper):
        """Test that a valid https URL returns True."""
        assert scraper.validate_url("https://example.com") is True

    def test_valid_http_url(self, scraper):
        """Test that a valid http URL returns True."""
        assert scraper.validate_url("http://example.com/path") is True

    def test_invalid_no_scheme(self, scraper):
        """Test that a URL without scheme returns False."""
        assert scraper.validate_url("example.com") is False

    def test_invalid_ftp_scheme(self, scraper):
        """Test that ftp scheme is not allowed."""
        assert scraper.validate_url("ftp://example.com") is False

    def test_empty_string(self, scraper):
        """Test that an empty string returns False."""
        assert scraper.validate_url("") is False

    def test_invalid_no_netloc(self, scraper):
        """Test that URL without netloc returns False."""
        assert scraper.validate_url("https://") is False


class TestExtractDomain:
    """Tests for WebScraperSkill.extract_domain."""

    def test_extract_simple_domain(self, scraper):
        """Test extracting domain from a simple URL."""
        assert scraper.extract_domain("https://example.com/path") == "example.com"

    def test_extract_domain_with_port(self, scraper):
        """Test extracting domain with port."""
        assert scraper.extract_domain("https://example.com:8080/path") == "example.com:8080"

    def test_extract_domain_invalid_url_raises(self, scraper):
        """Test that an invalid URL raises ValueError."""
        with pytest.raises(ValueError):
            scraper.extract_domain("not-a-url")


class TestExtractPath:
    """Tests for WebScraperSkill.extract_path."""

    def test_extract_path(self, scraper):
        """Test extracting path from URL."""
        assert scraper.extract_path("https://example.com/api/v1") == "/api/v1"

    def test_extract_root_path(self, scraper):
        """Test extracting path when none is specified."""
        assert scraper.extract_path("https://example.com") == "/"

    def test_extract_path_invalid_url_raises(self, scraper):
        """Test that an invalid URL raises ValueError."""
        with pytest.raises(ValueError):
            scraper.extract_path("bad-url")
