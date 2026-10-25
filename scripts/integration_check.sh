#!/usr/bin/env bash
# Integration check

set -e
[ -f ".env" ] && set -a && source .env && set +a

echo "=== Integration check ==="
echo "Mode: ${INTEGRATION_MODE:-consume-drop}"
echo "Paperless URL: ${PAPERLESS_URL:-not set}"
echo ""

case "${INTEGRATION_MODE:-consume-drop}" in
    consume-drop)
        echo "Consume drop mode: files in Nextcloud share -> copied to remote Paperless consume folder"
        echo "  Nextcloud share: ${NEXTCLOUD_PAPERLESS_SHARE:-Paperless-Ingest}"
        echo "  Needs: external storage (SMB/SFTP/WebDAV) or sidecar to reach remote Paperless consume/"
        ;;
    api-push)
        echo "API push mode: script/webhook pushes to Paperless API"
        echo "  Endpoint: ${PAPERLESS_API_URL:-$PAPERLESS_URL}/api/documents/post_document/"
        echo "  Needs: PAPERLESS_API_TOKEN"
        ;;
    bridge)
        echo "Bridge mode: read-only view of Paperless media via external storage"
        ;;
esac

echo ""
echo "Manual verification needed - see docs/integration.md"
