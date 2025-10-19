# nginx Configuration Test Suite

Professional pytest-based test suite that validates nginx proxy configuration across all deployment scenarios.

## Quick Start

```bash
# Run all tests
cd tests
docker compose -f docker-compose.test.yml up --abort-on-container-exit test

# Cleanup
docker compose -f docker-compose.test.yml down -v
```

**Expected output:** `========================= 7 passed in 0.0Xs =========================`

## What Gets Tested

This suite validates that nginx correctly handles proxy headers in three real-world deployment scenarios:

### 1. Reverse Proxy Setup (Most Common)
**Scenario:** User → HTTPS → Traefik/Caddy/nginx → nginx → wger
**Challenge:** Preserve the original HTTPS protocol through the proxy chain
**Why it matters:** Django's CSRF protection requires knowing the original protocol

**Test coverage:**
- ✅ X-Forwarded-Proto: http (when user connects via HTTP)
- ✅ X-Forwarded-Proto: https (when user connects via HTTPS)

### 2. Direct Connection
**Scenario:** User → HTTP → nginx → wger (no reverse proxy)
**Challenge:** No upstream proxy to set X-Forwarded-Proto
**Why it matters:** nginx must fall back to its own scheme ($scheme)

**Test coverage:**
- ✅ Fallback to http when no X-Forwarded-Proto header present

### 3. Port Forwarding (Home Routers)
**Scenario:** User → Router → Port Forward → nginx → wger
**Challenge:** Router forwards traffic without setting proxy headers
**Why it matters:** Same as direct connection - nginx must use $scheme

**Test coverage:**
- ✅ Same fallback behavior as direct connection

### 4. WebSocket Support
**Scenario:** Any deployment with real-time features
**Challenge:** WebSocket connections require specific headers
**Why it matters:** Web app login and real-time features fail without these

**Test coverage:**
- ✅ Upgrade header proxied correctly
- ✅ Connection header proxied correctly

### 5. Standard Proxy Headers
**Test coverage:**
- ✅ X-Real-IP is valid IPv4 address
- ✅ X-Forwarded-For contains valid IP
- ✅ Host header forwarded correctly

## How It Works

1. **Mock Backend** (`mock_backend.py`) - Python HTTP server that echoes all received headers as JSON
2. **Test Suite** (`test_nginx_config.py`) - pytest tests that validate header values (not just presence)
3. **Test Environment** (`docker-compose.test.yml`) - Orchestrates nginx + mock backend + test runner

**Key difference from amateur tests:** These tests validate actual header **values** using proper assertions, not just grep for strings.

## Test Details

### TestReverseProxyScenarios
- `test_preserves_http_from_upstream_proxy` - Verifies X-Forwarded-Proto: http preserved
- `test_preserves_https_from_upstream_proxy` - Verifies X-Forwarded-Proto: https preserved

### TestDirectConnection
- `test_fallback_to_scheme_when_no_upstream_header` - Verifies fallback to $scheme (http)

### TestWebSocketSupport
- `test_proxies_upgrade_and_connection_headers` - Verifies WebSocket headers proxied

### TestProxyHeaders
- `test_x_real_ip_is_valid_ip_address` - Validates IPv4 format (e.g., 172.18.0.3)
- `test_x_forwarded_for_contains_valid_ip` - Validates IP present in forwarded list
- `test_host_header_forwarding` - Verifies custom Host header preserved

## Manual Test Execution

```bash
# Start services only (for debugging)
docker compose -f docker-compose.test.yml up -d web nginx

# Check service health
docker compose -f docker-compose.test.yml ps

# Run tests manually with verbose output
docker compose -f docker-compose.test.yml run --rm test

# View logs
docker compose -f docker-compose.test.yml logs nginx
docker compose -f docker-compose.test.yml logs web

# Cleanup
docker compose -f docker-compose.test.yml down -v
```

## Common Issues

**nginx unhealthy:** Check `docker compose -f docker-compose.test.yml logs nginx` for configuration errors

**Tests fail on header validation:** The config likely has incorrect `proxy_set_header` directives

**Connection refused:** Backend (mock_backend.py) failed to start, check web service logs

## CI/CD Integration

Tests run automatically on:
- Push to `master` or `main` branches
- Pull requests
- Changes to `config/nginx.conf` or `tests/**`

See `.github/workflows/test-nginx.yml` for workflow details.
