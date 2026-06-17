"""Professional test suite for nginx proxy configuration.

Tests validate that nginx correctly handles:
- X-Forwarded-Proto in all deployment scenarios (reverse proxy, direct connection)
- WebSocket upgrade headers
- Standard proxy headers (X-Real-IP, X-Forwarded-For, Host)

All tests use proper assertions on header VALUES, not just presence.
"""
import pytest
import requests
import re
import os


@pytest.fixture
def nginx_url():
    """Base URL for nginx under test"""
    return os.getenv('NGINX_URL', 'http://localhost:8080')


class TestReverseProxyScenarios:
    """Test X-Forwarded-Proto handling when behind upstream proxy"""

    def test_preserves_http_from_upstream_proxy(self, nginx_url):
        """Verify nginx preserves X-Forwarded-Proto: http from upstream (Traefik, Caddy, etc.)"""
        response = requests.get(nginx_url, headers={'X-Forwarded-Proto': 'http'})

        assert response.status_code == 200, f"Expected 200 OK, got {response.status_code}"
        data = response.json()

        assert 'X-Forwarded-Proto' in data['headers'], \
            "X-Forwarded-Proto header missing in backend request"
        assert data['headers']['X-Forwarded-Proto'] == 'http', \
            f"Expected X-Forwarded-Proto: http, got {data['headers']['X-Forwarded-Proto']}"

    def test_preserves_https_from_upstream_proxy(self, nginx_url):
        """Verify nginx preserves X-Forwarded-Proto: https from upstream (Traefik, Caddy, etc.)"""
        response = requests.get(nginx_url, headers={'X-Forwarded-Proto': 'https'})

        assert response.status_code == 200, f"Expected 200 OK, got {response.status_code}"
        data = response.json()

        assert 'X-Forwarded-Proto' in data['headers'], \
            "X-Forwarded-Proto header missing in backend request"
        assert data['headers']['X-Forwarded-Proto'] == 'https', \
            f"Expected X-Forwarded-Proto: https, got {data['headers']['X-Forwarded-Proto']}"


class TestDirectConnection:
    """Test fallback to $scheme for direct connections without upstream proxy"""

    def test_fallback_to_scheme_when_no_upstream_header(self, nginx_url):
        """Verify nginx falls back to $scheme (http) when no upstream X-Forwarded-Proto"""
        response = requests.get(nginx_url)  # No X-Forwarded-Proto header

        assert response.status_code == 200, f"Expected 200 OK, got {response.status_code}"
        data = response.json()

        assert 'X-Forwarded-Proto' in data['headers'], \
            "X-Forwarded-Proto header missing in backend request"
        assert data['headers']['X-Forwarded-Proto'] == 'http', \
            f"Expected fallback to $scheme (http), got {data['headers']['X-Forwarded-Proto']}"


class TestWebSocketSupport:
    """Test WebSocket upgrade header proxying"""

    def test_proxies_upgrade_and_connection_headers(self, nginx_url):
        """Verify nginx proxies WebSocket Upgrade and Connection headers"""
        response = requests.get(
            nginx_url,
            headers={
                'Upgrade': 'websocket',
                'Connection': 'upgrade'
            }
        )

        assert response.status_code == 200, f"Expected 200 OK, got {response.status_code}"
        data = response.json()

        assert 'Upgrade' in data['headers'], \
            "Upgrade header not proxied to backend"
        assert data['headers']['Upgrade'] == 'websocket', \
            f"Expected Upgrade: websocket, got {data['headers']['Upgrade']}"

        assert 'Connection' in data['headers'], \
            "Connection header not proxied to backend"
        assert data['headers']['Connection'] == 'upgrade', \
            f"Expected Connection: upgrade, got {data['headers']['Connection']}"


class TestProxyHeaders:
    """Test standard proxy header forwarding"""

    def test_x_real_ip_is_valid_ip_address(self, nginx_url):
        """Verify X-Real-IP is set to a valid IP address"""
        response = requests.get(nginx_url)

        assert response.status_code == 200, f"Expected 200 OK, got {response.status_code}"
        data = response.json()

        assert 'X-Real-IP' in data['headers'], \
            "X-Real-IP header missing in backend request"

        ip = data['headers']['X-Real-IP']
        assert re.match(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$', ip), \
            f"X-Real-IP must be valid IPv4 address, got: {ip}"

    def test_x_forwarded_for_contains_valid_ip(self, nginx_url):
        """Verify X-Forwarded-For contains at least one valid IP address"""
        response = requests.get(nginx_url)

        assert response.status_code == 200, f"Expected 200 OK, got {response.status_code}"
        data = response.json()

        assert 'X-Forwarded-For' in data['headers'], \
            "X-Forwarded-For header missing in backend request"

        forwarded = data['headers']['X-Forwarded-For']
        assert re.search(r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}', forwarded), \
            f"X-Forwarded-For must contain valid IP address, got: {forwarded}"

    def test_host_header_forwarding(self, nginx_url):
        """Verify Host header is forwarded correctly"""
        response = requests.get(nginx_url, headers={'Host': 'example.com'})

        assert response.status_code == 200, f"Expected 200 OK, got {response.status_code}"
        data = response.json()

        assert 'Host' in data['headers'], \
            "Host header not forwarded to backend"
        assert data['headers']['Host'] == 'example.com', \
            f"Expected Host: example.com, got {data['headers']['Host']}"


class TestPowerSyncProxy:
    """Test the /ps/ reverse proxy to the PowerSync service"""

    def test_strips_ps_prefix_from_path(self, nginx_url):
        """Verify /ps/<path> is forwarded to the upstream as /<path>"""
        response = requests.get(f"{nginx_url}/ps/sync/stream")

        assert response.status_code == 200, f"Expected 200 OK, got {response.status_code}"
        data = response.json()

        assert data['path'] == '/sync/stream', \
            f"Expected upstream path '/sync/stream', got {data['path']}"

    def test_strips_ps_prefix_for_root(self, nginx_url):
        """Verify /ps/ (no further path) is forwarded as /"""
        response = requests.get(f"{nginx_url}/ps/")

        assert response.status_code == 200, f"Expected 200 OK, got {response.status_code}"
        data = response.json()

        assert data['path'] == '/', \
            f"Expected upstream path '/', got {data['path']}"

    def test_proxies_websocket_upgrade_headers(self, nginx_url):
        """Verify /ps/ proxies WebSocket Upgrade/Connection headers (Web SDK + diagnostics)"""
        response = requests.get(
            f"{nginx_url}/ps/sync/stream",
            headers={
                'Upgrade': 'websocket',
                'Connection': 'upgrade',
            },
        )

        assert response.status_code == 200, f"Expected 200 OK, got {response.status_code}"
        data = response.json()

        assert data['headers'].get('Upgrade') == 'websocket', \
            f"Expected Upgrade: websocket, got {data['headers'].get('Upgrade')}"
        assert data['headers'].get('Connection') == 'upgrade', \
            f"Expected Connection: upgrade, got {data['headers'].get('Connection')}"

    def test_preserves_x_forwarded_proto_from_upstream(self, nginx_url):
        """Verify /ps/ respects X-Forwarded-Proto from an upstream reverse proxy"""
        response = requests.get(
            f"{nginx_url}/ps/sync/stream",
            headers={'X-Forwarded-Proto': 'https'},
        )

        assert response.status_code == 200, f"Expected 200 OK, got {response.status_code}"
        data = response.json()

        assert data['headers'].get('X-Forwarded-Proto') == 'https', \
            f"Expected X-Forwarded-Proto: https, got {data['headers'].get('X-Forwarded-Proto')}"

    def test_falls_back_to_scheme_without_upstream_proto(self, nginx_url):
        """Verify /ps/ falls back to $scheme (http) when no upstream X-Forwarded-Proto is set"""
        response = requests.get(f"{nginx_url}/ps/sync/stream")

        assert response.status_code == 200, f"Expected 200 OK, got {response.status_code}"
        data = response.json()

        assert data['headers'].get('X-Forwarded-Proto') == 'http', \
            f"Expected fallback to $scheme (http), got {data['headers'].get('X-Forwarded-Proto')}"
