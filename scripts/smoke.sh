#!/usr/bin/env bash
# mroffice smoke test

set -e
[ -f ".env" ] && set -a && source .env && set +a

echo "=== mroffice smoke ==="

# Check Nextcloud AIO
echo "[1/4] Nextcloud AIO mastercontainer..."
if command -v podman >/dev/null 2>&1; then
    if podman ps --format '{{.Names}}' 2>/dev/null | grep -q nextcloud-aio-mastercontainer; then
        echo "  ✓ Running"
    else
        echo "  ⚠ Not running (run make up)"
    fi
fi

# Check Collabora via AIO (after setup) - would need discovery
echo "[2/4] Collabora... (configured via AIO after setup)"

# Paperless remote check
echo "[3/4] Paperless remote..."
PAPERLESS_URL=${PAPERLESS_URL:-not-set}
if [ "$PAPERLESS_URL" != "not-set" ]; then
    if command -v curl >/dev/null 2>&1; then
        code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$PAPERLESS_URL" 2>&1 || echo "000")
        echo "  $PAPERLESS_URL -> HTTP $code"
    fi
else
    echo "  ⚠ PAPERLESS_URL not configured"
fi

# Integration
echo "[4/4] Integration..."
bash scripts/integration_check.sh 2>&1 | tail -5

echo ""
echo "=== Smoke complete ==="
