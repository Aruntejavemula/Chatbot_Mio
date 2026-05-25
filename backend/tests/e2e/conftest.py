"""Fixtures for E2E tests."""
import pytest


@pytest.fixture(scope="session")
def base_url():
    """Base URL for the test server."""
    return "http://localhost:8000"
