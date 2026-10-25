#!/usr/bin/env bash
# Integration scripts for Nextcloud <-> remote Paperless

set -e
[ -f ".env" ] && set -a && source .env && set +a
[ -f "config/.secrets.env" ] && set -a && source config/.secrets.env && set +a

echo "=== Paperless connectivity check ==="
PAPERLESS_URL=${PAPERLESS_URL:-http://localhost:8000}

if command -v curl >/dev/null 2>&1; then
    echo "Checking: $PAPERLESS_URL/api/"
    curl -s -o /dev/null -w "HTTP:%{http_code}\n" "$PAPERLESS_URL/api/" 2>&1 | tail -1
    echo ""
    echo "Note: API may require auth/token. Set PAPERLESS_API_TOKEN in config/.secrets.env"
else
    echo "curl not found"
fi
