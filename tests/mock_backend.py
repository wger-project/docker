#!/usr/bin/env python3
"""Mock backend server for testing nginx proxy configuration.

This server echoes back all received HTTP headers as JSON,
allowing us to verify that nginx correctly forwards headers
like X-Forwarded-Proto, Upgrade, Connection, etc.

Usage:
    python3 mock_backend.py [port]

Default port: 8000
"""

import json
import sys
from http.server import HTTPServer, BaseHTTPRequestHandler
from socketserver import ThreadingMixIn


class HeaderEchoHandler(BaseHTTPRequestHandler):
    """HTTP request handler that returns all received headers as JSON."""

    def do_GET(self):
        """Handle GET requests."""
        self._handle_request()

    def do_POST(self):
        """Handle POST requests."""
        self._handle_request()

    def do_HEAD(self):
        """Handle HEAD requests."""
        self._handle_request()

    def _handle_request(self):
        """Process request and return headers as JSON."""
        # Convert headers to dict
        headers_dict = dict(self.headers.items())

        # Prepare response
        response = {
            "method": self.command,
            "path": self.path,
            "headers": headers_dict,
            "client_address": f"{self.client_address[0]}:{self.client_address[1]}"
        }

        # Send response
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(response, indent=2).encode('utf-8'))

    def log_message(self, format, *args):
        """Override to provide cleaner log output."""
        sys.stdout.write(f"[{self.log_date_time_string()}] {format % args}\n")


class ThreadedHTTPServer(ThreadingMixIn, HTTPServer):
    """Handle requests in separate threads."""
    daemon_threads = True


def main():
    """Start the mock backend server."""
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8000

    server = ThreadedHTTPServer(('0.0.0.0', port), HeaderEchoHandler)

    print(f"Mock backend server starting on port {port}...")
    print(f"Server will echo all received headers as JSON")
    print(f"Press Ctrl+C to stop\n")

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down server...")
        server.shutdown()
        print("Server stopped")


if __name__ == '__main__':
    main()
