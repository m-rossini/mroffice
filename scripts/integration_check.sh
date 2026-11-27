#!/usr/bin/env bash
# Integration check — Nextcloud <-> Paperless (local unified stack first, split-host still supported)

set -e
source "$(dirname "$0")/lib/runtime.sh" 2>/dev/null || true
[ -f ".env" ] && set -a && source .env && set +a
restore_env

echo "=== Integration check ==="
echo "Mode: ${INTEGRATION_MODE:-consume-drop}"
echo "Paperless URL: ${PAPERLESS_URL:-not set}"
echo "DATA_ROOT: ${DATA_ROOT:-/srv/mroffice}"
echo ""

case "${INTEGRATION_MODE:-consume-drop}" in
    consume-drop)
        echo "Consume drop: files in Nextcloud share -> Paperless consume folder."
        echo "  Local unified stack: copy/drop into $DATA_ROOT/paperless/consume/"
        echo "  Nextcloud share: ${NEXTCLOUD_PAPERLESS_SHARE:-Paperless-Ingest}"
        if [ -d "${DATA_ROOT:-/srv/mroffice}/paperless/consume" ] && [ -w "${DATA_ROOT:-/srv/mroffice}/paperless/consume" ]; then
            echo "  ✓ local consume dir writable"
        else
            echo "  ✗ local consume dir missing/not writable (run make init)"
            exit 1
        fi
        echo "  Split-host: expose consume/ via SFTP/SMB and mount as Nextcloud External Storage."
        ;;
    api-push)
        echo "API push: script/webhook pushes to Paperless API."
        echo "  Endpoint: ${PAPERLESS_API_URL:-$PAPERLESS_URL}/api/documents/post_document/"
        if [ -z "${PAPERLESS_API_TOKEN:-}" ] && [ -f "config/.secrets.env" ]; then
            # shellcheck disable=SC1091
            set -a && source config/.secrets.env && set +a
        fi
        if [ -z "${PAPERLESS_API_TOKEN:-}" ]; then
            echo "  ✗ PAPERLESS_API_TOKEN not set (in config/.secrets.env)"
            exit 1
        else
            echo "  ✓ PAPERLESS_API_TOKEN present"
        fi
        ;;
    bridge)
        echo "Bridge: read-only view of Paperless media via Nextcloud external storage."
        echo "  Source: ${DATA_ROOT:-/srv/mroffice}/paperless/media (local) or SFTP/SMB (split-host)"
        if [ -d "${DATA_ROOT:-/srv/mroffice}/paperless/media" ]; then
            echo "  ✓ local media dir present"
        else
            echo "  ✗ local media dir missing"
            exit 1
        fi
        ;;
esac

echo ""
echo "✓ Integration config OK — verify end-to-end with: make consume FILE=<doc> && make smoke"
