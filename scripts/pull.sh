#!/usr/bin/env bash
# mroffice pull — pull pinned images for the selected STACK

set -e
source "$(dirname "$0")/lib/runtime.sh" 2>/dev/null || true

[ -f ".env" ] && set -a && source .env && set +a
restore_env
[ -f "config/versions.env" ] && set -a && source config/versions.env && set +a
restore_env

STACK=${STACK:-all}

echo "=== mroffice pull (STACK=$STACK) ==="

if [ "$STACK" = "nextcloud" ] || [ "$STACK" = "all" ]; then
    echo "--- Nextcloud AIO ---"
    # shellcheck disable=SC2086
    compose -f compose/nextcloud-aio.yml pull 2>&1 | tail -5 || true
fi

if [ "$STACK" = "paperless" ] || [ "$STACK" = "all" ]; then
    echo "--- Paperless-ngx ---"
    # shellcheck disable=SC2086
    compose -f compose/paperless.yml pull 2>&1 | tail -10 || true
    if [ -n "${COMPOSE_PROFILES:-}" ]; then
        echo "(COMPOSE_PROFILES=$COMPOSE_PROFILES — ollama included)"
    else
        echo "(ollama skipped — run with COMPOSE_PROFILES=ai to include it)"
    fi
fi

echo "=== Pull done ==="
