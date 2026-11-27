#!/usr/bin/env bash
# mroffice smoke — end-to-end checks, STACK-aware. Fails loudly.

set -e
source "$(dirname "$0")/lib/runtime.sh" 2>/dev/null || true
[ -f ".env" ] && set -a && source .env && set +a
restore_env
[ -f "config/.secrets.env" ] && set -a && source config/.secrets.env && set +a
restore_env

STACK=${STACK:-all}
fail=0

echo "=== mroffice smoke (STACK=$STACK) ==="

if [ "$STACK" = "nextcloud" ] || [ "$STACK" = "all" ]; then
    echo "[1/4] Nextcloud AIO mastercontainer..."
    if $RUNTIME ps --format '{{.Names}}' 2>/dev/null | grep -q nextcloud-aio-mastercontainer; then
        echo "  ✓ Running"
    else
        echo "  ⚠ Not running (run STACK=nextcloud make up)"
    fi

    echo "[2/4] Collabora (via AIO after setup)..."
    echo "  (check Nextcloud UI → Office document opens; discovery: https://<domain>/hosting/discovery)"
fi

if [ "$STACK" = "paperless" ] || [ "$STACK" = "all" ]; then
    echo "[3/4] Paperless-ngx..."
    PAPERLESS_URL=${PAPERLESS_URL:-http://localhost:${PAPERLESS_PORT:-8000}}
    code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$PAPERLESS_URL/api/" 2>/dev/null || true)
    echo "  $PAPERLESS_URL/api/ -> HTTP $code"
    if [ "$code" = "200" ] || [ "$code" = "301" ] || [ "$code" = "302" ] || [ "$code" = "403" ]; then
        echo "  ✓ Paperless reachable"
    else
        echo "  ✗ Paperless NOT reachable (run STACK=paperless make up; check make logs)"
        fail=1
    fi
    if $RUNTIME ps --format '{{.Names}}' 2>/dev/null | grep -q mroffice-paperless-gotenberg; then
        echo "  ✓ gotenberg running (Office→PDF)"
    else
        echo "  ⚠ gotenberg not running"
    fi
    if $RUNTIME ps --format '{{.Names}}' 2>/dev/null | grep -q mroffice-paperless-tika; then
        echo "  ✓ tika running (text extraction)"
    else
        echo "  ⚠ tika not running"
    fi
fi

echo "[4/4] Integration..."
bash scripts/integration_check.sh 2>&1 | tail -8

if [ "$fail" != "0" ]; then
    echo ""
    echo "=== Smoke FAILED ==="
    exit 1
fi
echo ""
echo "=== Smoke complete ==="
