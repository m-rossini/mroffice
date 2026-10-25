#!/usr/bin/env bash
# mroffice storage map

set -e
source "$(dirname "$0")/lib/runtime.sh" 2>/dev/null || true

[ -f ".env" ] && set -a && source .env && set +a

DATA_ROOT=${DATA_ROOT:-/srv/mroffice}

echo "=== Storage Map ==="
echo "DATA_ROOT: $DATA_ROOT"
echo ""
printf "%-25s %-40s %-40s %-5s %-15s\n" "SERVICE" "HOST PATH" "CONTAINER PATH" "MODE" "OWNER"
printf "%s\n" "---------------------------------------------------------------------------------------------"

# Nextcloud AIO
printf "%-25s %-40s %-40s %-5s %-15s\n" "nextcloud-aio-data" "$DATA_ROOT/nextcloud/data" "/mnt/ncdata" "rw" "33:33"
printf "%-25s %-40s %-40s %-5s %-15s\n" "nextcloud-aio-config" "$DATA_ROOT/nextcloud/config" "/mnt/ncdata/../config" "rw" "33:33"
echo "  Note: AIO mastercontainer and internal DB may be engine-managed (documented exception per O7)"

# Paperless - existing on remote
echo ""
echo "Paperless-ngx: configured on separate host (not managed by this stack)"
echo "  PAPERLESS_URL: ${PAPERLESS_URL:-not set}"
echo "  INTEGRATION_MODE: ${INTEGRATION_MODE:-consume-drop}"
echo ""
echo "=== End ==="
