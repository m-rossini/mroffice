#!/usr/bin/env bash
# Paperless connectivity check — works for local unified stack and remote split-host.
# Prefers PAPERLESS_URL from .env, falls back to localhost.

set -e
source "$(dirname "$0")/lib/runtime.sh" 2>/dev/null || true
[ -f ".env" ] && set -a && source .env && set +a
restore_env
[ -f "config/.secrets.env" ] && set -a && source config/.secrets.env && set +a
restore_env

echo "=== Paperless connectivity check ==="
PAPERLESS_URL=${PAPERLESS_URL:-http://localhost:${PAPERLESS_PORT:-8000}}
DATA_ROOT=${DATA_ROOT:-/srv/mroffice}

echo "URL: $PAPERLESS_URL/api/"

if command -v curl >/dev/null 2>&1; then
    code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$PAPERLESS_URL/api/" 2>/dev/null || true)
    echo "HTTP: $code"
    if [ "$code" = "000" ]; then
        echo "✗ unreachable — is STACK=paperless up? (STACK=paperless make up)"
        exit 1
    fi
    echo ""
    echo "Note: API may require auth. Set PAPERLESS_API_TOKEN in config/.secrets.env for API push mode."
else
    echo "curl not found"
    exit 1
fi

echo ""
echo "--- Local consume dir ---"
if [ -d "$DATA_ROOT/paperless/consume" ]; then
    echo "✓ $DATA_ROOT/paperless/consume ($(ls "$DATA_ROOT/paperless/consume" 2>/dev/null | wc -l) file(s) waiting)"
else
    echo "⚠ $DATA_ROOT/paperless/consume missing (run make init)"
fi
