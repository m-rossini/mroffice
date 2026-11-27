#!/usr/bin/env bash
# mroffice logs — follow logs for the selected STACK
# Usage: make logs [STACK=paperless] [SERVICE=webserver]

set -e
source "$(dirname "$0")/lib/runtime.sh" 2>/dev/null || true

[ -f ".env" ] && set -a && source .env && set +a
restore_env

STACK=${STACK:-all}
SERVICE=${SERVICE:-${1:-}}

if [ "$STACK" = "paperless" ]; then
    # shellcheck disable=SC2086
    exec compose -f compose/paperless.yml logs -f --tail=100 $SERVICE
elif [ "$STACK" = "nextcloud" ]; then
    if [ -n "$SERVICE" ]; then
        exec $RUNTIME logs -f "$SERVICE"
    else
        exec $RUNTIME logs -f nextcloud-aio-mastercontainer
    fi
else
    echo "STACK=$STACK — showing paperless logs (use STACK=nextcloud for AIO)."
    echo "Press Ctrl-C, then: STACK=nextcloud make logs"
    # shellcheck disable=SC2086
    exec compose -f compose/paperless.yml logs -f --tail=100 $SERVICE
fi
