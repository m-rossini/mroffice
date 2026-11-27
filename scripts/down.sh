#!/usr/bin/env bash
# mroffice down — stop containers, never delete DATA_ROOT

set -e
source "$(dirname "$0")/lib/runtime.sh" 2>/dev/null || true

[ -f ".env" ] && set -a && source .env && set +a
restore_env
[ -f "config/versions.env" ] && set -a && source config/versions.env && set +a
restore_env

STACK=${STACK:-all}

echo "=== mroffice down (STACK=$STACK) ==="
echo "Stopping containers... (bind mounts preserved)"

# Stop Nextcloud AIO if running
if [ "$STACK" = "nextcloud" ] || [ "$STACK" = "all" ]; then
    $RUNTIME stop nextcloud-aio-mastercontainer 2>/dev/null || true
    # shellcheck disable=SC2086
    compose -f compose/nextcloud-aio.yml down 2>/dev/null || true
fi

# Stop Paperless stack (compose down removes containers/network, keeps DATA_ROOT)
if [ "$STACK" = "paperless" ] || [ "$STACK" = "all" ]; then
    if [ -f "compose/paperless.yml" ]; then
        # shellcheck disable=SC2086
        compose -f compose/paperless.yml down 2>/dev/null || true
        # also catch the optional ai profile container
        # shellcheck disable=SC2086
        COMPOSE_PROFILES=ai compose -f compose/paperless.yml down 2>/dev/null || true
    fi
    $RUNTIME stop mroffice-paperless-webserver mroffice-paperless-db mroffice-paperless-broker mroffice-paperless-gotenberg mroffice-paperless-tika mroffice-ollama 2>/dev/null || true
fi

echo "✓ Containers stopped"
echo "Data directories under ${DATA_ROOT:-/srv/mroffice} untouched"
