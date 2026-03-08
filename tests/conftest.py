"""pytest configuration and fixtures for nginx configuration tests.

Provides:
- Service readiness checks before test execution
- Shared fixtures for all test modules
"""
import pytest
import time
import requests


def pytest_configure(config):
    """
    Wait for nginx to be ready before running tests.

    This hook runs once before any tests execute, ensuring the test
    environment is properly initialized.
    """
    nginx_url = 'http://nginx:80'
    max_retries = 30
    retry_delay = 1  # seconds

    print("\n" + "=" * 60)
    print("Waiting for nginx to become ready...")
    print("=" * 60)

    for attempt in range(1, max_retries + 1):
        try:
            response = requests.get(nginx_url, timeout=2)
            if response.status_code == 200:
                print(f"✓ nginx is ready (attempt {attempt}/{max_retries})")
                print("=" * 60 + "\n")
                return
        except requests.exceptions.RequestException as e:
            if attempt < max_retries:
                print(f"  Attempt {attempt}/{max_retries}: {type(e).__name__}, retrying in {retry_delay}s...")
                time.sleep(retry_delay)
            else:
                print(f"✗ nginx failed to become ready after {max_retries} attempts")
                print("=" * 60 + "\n")
                raise Exception(
                    f"nginx did not become ready after {max_retries} attempts. "
                    f"Last error: {type(e).__name__}: {str(e)}"
                )
