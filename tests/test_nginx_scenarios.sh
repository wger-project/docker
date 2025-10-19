#!/bin/bash
# Test script for nginx configuration scenarios
#
# This script validates that the nginx configuration correctly handles
# X-Forwarded-Proto in all deployment scenarios:
# 1. Behind reverse proxy (with X-Forwarded-Proto header present)
# 2. Direct connection (without X-Forwarded-Proto header)
# 3. WebSocket upgrade requests
#
# Prerequisites:
# - nginx container running with config mounted
# - mock backend server running (mock_backend.py)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
NGINX_URL="${NGINX_URL:-http://localhost:8080}"
EXPECTED_BACKEND_URL="http://wger:8000"  # What nginx proxies to

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Helper function to print test results
print_result() {
    local test_name="$1"
    local result="$2"
    local message="$3"

    TESTS_RUN=$((TESTS_RUN + 1))

    if [ "$result" = "PASS" ]; then
        echo -e "${GREEN}✓ PASS${NC}: $test_name"
        [ -n "$message" ] && echo "  → $message"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: $test_name"
        [ -n "$message" ] && echo "  → $message"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Helper function to check header value
check_header() {
    local response="$1"
    local header_name="$2"
    local expected_value="$3"

    # Extract header value from JSON response (case-insensitive)
    # Headers come back with their original case, so we need to match flexibly
    actual_value=$(echo "$response" | grep -oi "\"$header_name\": \"[^\"]*\"" | cut -d'"' -f4)

    if [ "$actual_value" = "$expected_value" ]; then
        return 0
    else
        echo "Expected: $expected_value, Got: $actual_value"
        return 1
    fi
}

echo "========================================="
echo "nginx Configuration Test Suite"
echo "========================================="
echo ""
echo "Testing URL: $NGINX_URL"
echo ""

# Test 1a: Reverse Proxy with HTTP (X-Forwarded-Proto: http)
echo "---"
echo "[Test 1a] Reverse Proxy + HTTP caller"
echo "  Simulating: User → HTTP → Traefik → nginx → backend"
echo "  Traefik sets: X-Forwarded-Proto: http"
response=$(curl -s "$NGINX_URL/" -H "X-Forwarded-Proto: http")
if check_header "$response" "x-forwarded-proto" "http"; then
    print_result "Scenario 1a: Reverse proxy (HTTP)" "PASS" "Correctly forwards X-Forwarded-Proto: http"
else
    print_result "Scenario 1a: Reverse proxy (HTTP)" "FAIL" "$(check_header "$response" "x-forwarded-proto" "http" 2>&1)"
fi

# Test 1b: Reverse Proxy with HTTPS (X-Forwarded-Proto: https)
echo ""
echo "[Test 1b] Reverse Proxy + HTTPS caller"
echo "  Simulating: User → HTTPS → Traefik → nginx → backend"
echo "  Traefik sets: X-Forwarded-Proto: https"
response=$(curl -s "$NGINX_URL/" -H "X-Forwarded-Proto: https")
if check_header "$response" "x-forwarded-proto" "https"; then
    print_result "Scenario 1b: Reverse proxy (HTTPS)" "PASS" "Correctly forwards X-Forwarded-Proto: https"
else
    print_result "Scenario 1b: Reverse proxy (HTTPS)" "FAIL" "$(check_header "$response" "x-forwarded-proto" "https" 2>&1)"
fi

# Test 2a: Direct HTTP Connection (no X-Forwarded-Proto header)
echo ""
echo "[Test 2a] Direct HTTP connection"
echo "  Simulating: User → HTTP → nginx → backend"
echo "  No reverse proxy, no X-Forwarded-Proto header"
response=$(curl -s "$NGINX_URL/")
if check_header "$response" "x-forwarded-proto" "http"; then
    print_result "Scenario 2a: Direct connection (HTTP)" "PASS" "Falls back to \$scheme (http)"
else
    print_result "Scenario 2a: Direct connection (HTTP)" "FAIL" "$(check_header "$response" "x-forwarded-proto" "http" 2>&1)"
fi

# Test 2b: Direct HTTPS Connection would require SSL setup, skip for now
# This would be tested in the full docker-compose environment

# Test 3: WebSocket Upgrade Headers
echo ""
echo "[Test 3] WebSocket upgrade headers"
echo "  Verifying Upgrade and Connection headers are proxied"
response=$(curl -s "$NGINX_URL/" -H "Upgrade: websocket" -H "Connection: upgrade")
if echo "$response" | grep -qi '"upgrade": "websocket"' && echo "$response" | grep -qi '"connection": "upgrade"'; then
    print_result "Scenario 3: WebSocket support" "PASS" "Upgrade and Connection headers proxied correctly"
else
    print_result "Scenario 3: WebSocket support" "FAIL" "WebSocket headers not proxied correctly"
fi

# Test 4: X-Real-IP header
echo ""
echo "[Test 4] X-Real-IP header forwarding"
response=$(curl -s "$NGINX_URL/")
if echo "$response" | grep -qi '"x-real-ip"'; then
    print_result "X-Real-IP header" "PASS" "X-Real-IP is set"
else
    print_result "X-Real-IP header" "FAIL" "X-Real-IP not set"
fi

# Test 5: X-Forwarded-For header
echo ""
echo "[Test 5] X-Forwarded-For header forwarding"
response=$(curl -s "$NGINX_URL/")
if echo "$response" | grep -qi '"x-forwarded-for"'; then
    print_result "X-Forwarded-For header" "PASS" "X-Forwarded-For is set"
else
    print_result "X-Forwarded-For header" "FAIL" "X-Forwarded-For not set"
fi

# Test 6: Host header
echo ""
echo "[Test 6] Host header forwarding"
response=$(curl -s "$NGINX_URL/" -H "Host: example.com")
if check_header "$response" "host" "example.com"; then
    print_result "Host header" "PASS" "Host header forwarded correctly"
else
    print_result "Host header" "FAIL" "$(check_header "$response" "host" "example.com" 2>&1)"
fi

# Summary
echo ""
echo "========================================="
echo "Test Summary"
echo "========================================="
echo "Total tests run: $TESTS_RUN"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
    exit 1
else
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
fi
