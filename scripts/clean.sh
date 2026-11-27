#!/usr/bin/env bash
# mroffice clean — DESTRUCTIVE. Requires FORCE=1 (gated by Makefile too).
# Removes containers for STACK, then deletes that stack's bind-mounted data under DATA_ROOT.
# Usage: STACK=paperless make clean FORCE=1

set -e
source "$(dirname "$0")/lib/runtime.sh" 2>/dev/null || true

[ -f ".env" ] && set -a && source .env && set +a
restore_env

STACK=${STACK:-all}
DATA_ROOT=${DATA_ROOT:-/srv/mroffice}

echo "=== mroffice clean (STACK=$STACK) ==="
echo "DATA_ROOT: $DATA_ROOT"
echo ""
bash "$(dirname "$0")/storage.sh"
echo ""
echo "About to DELETE the above paths for STACK=$STACK. FORCE=$FORCE"

if [ "${FORCE:-0}" != "1" ]; then
    echo "Refusing without FORCE=1."
    exit 1
fi

if [ "$STACK" = "paperless" ] || [ "$STACK" = "all" ]; then
    # shellcheck disable=SC2086
    compose -f compose/paperless.yml down -v 2>/dev/null || true
    $RUNTIME rm -f mroffice-paperless-webserver mroffice-paperless-db mroffice-paperless-broker mroffice-paperless-gotenberg mroffice-paperless-tika mroffice-ollama 2>/dev/null || true
    echo "Deleting $DATA_ROOT/paperless ..."
    rm -rf "$DATA_ROOT/paperless"
fi

if [ "$STACK" = "nextcloud" ] || [ "$STACK" = "all" ]; then
    $RUNTIME stop nextcloud-aio-mastercontainer 2>/dev/null || true
    $RUNTIME rm -f nextcloud-aio-mastercontainer 2>/dev/null || true
    # shellcheck disable=SC2086
    compose -f compose/nextcloud-aio.yml down -v 2>/dev/null || true
    echo "Deleting $DATA_ROOT/nextcloud ..."
    rm -rf "$DATA_ROOT/nextcloud"
fi

echo "✓ Clean done (containers removed, selected DATA_ROOT deleted)"
