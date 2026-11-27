#!/usr/bin/env bash
# mroffice update — recreate stack(s) with pinned images. Backup is done by `make update` deps.
# Usage: STACK=paperless make update

set -e
source "$(dirname "$0")/lib/runtime.sh" 2>/dev/null || true

[ -f ".env" ] && set -a && source .env && set +a
restore_env
[ -f "config/versions.env" ] && set -a && source config/versions.env && set +a
restore_env

STACK=${STACK:-all}

echo "=== mroffice update (STACK=$STACK) ==="

if [ "$STACK" = "paperless" ] || [ "$STACK" = "all" ]; then
    echo "--- Paperless-ngx ---"
    # shellcheck disable=SC2086
    compose -f compose/paperless.yml up -d 2>&1 | tail -10
fi

if [ "$STACK" = "nextcloud" ] || [ "$STACK" = "all" ]; then
    echo "--- Nextcloud AIO ---"
    # shellcheck disable=SC2086
    compose -f compose/nextcloud-aio.yml up -d 2>&1 | tail -10 || true
fi

echo "=== Update recreated containers (run make smoke) ==="
