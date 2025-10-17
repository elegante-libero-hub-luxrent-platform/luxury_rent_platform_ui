#!/bin/bash
# Simple script to serve the web UI locally to avoid CORS issues
# Usage: ./scripts/serve_ui.sh

cd "$(dirname "$0")/.." || exit 1

PORT=${1:-8000}

echo "Serving web UI on http://localhost:${PORT}"
echo "Open http://localhost:${PORT}/web_ui.html in your browser"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

python3 -m http.server "$PORT"

