#!/usr/bin/env bash
# mroffice storage map

set -e
source "$(dirname "$0")/lib/runtime.sh" 2>/dev/null || true

[ -f ".env" ] && set -a && source .env && set +a
restore_env

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

# Paperless-ngx (local unified stack — compose/paperless.yml)
echo ""
echo "--- Paperless-ngx (local, bind-mounted) ---"
printf "%-25s %-40s %-40s %-5s %-15s\n" "paperless-data" "$DATA_ROOT/paperless/data" "/usr/src/paperless/data" "rw" "${USERMAP_UID:-1000}:${USERMAP_GID:-1000}"
printf "%-25s %-40s %-40s %-5s %-15s\n" "paperless-media" "$DATA_ROOT/paperless/media" "/usr/src/paperless/media" "rw" "${USERMAP_UID:-1000}:${USERMAP_GID:-1000}"
printf "%-25s %-40s %-40s %-5s %-15s\n" "paperless-consume" "$DATA_ROOT/paperless/consume" "/usr/src/paperless/consume" "rw" "${USERMAP_UID:-1000}:${USERMAP_GID:-1000}"
printf "%-25s %-40s %-40s %-5s %-15s\n" "paperless-export" "$DATA_ROOT/paperless/export" "/usr/src/paperless/export" "rw" "${USERMAP_UID:-1000}:${USERMAP_GID:-1000}"
printf "%-25s %-40s %-40s %-5s %-15s\n" "paperless-pgdata" "$DATA_ROOT/paperless/pgdata" "/var/lib/postgresql/data" "rw" "db-user"
printf "%-25s %-40s %-40s %-5s %-15s\n" "paperless-redisdata" "$DATA_ROOT/paperless/redisdata" "/data" "rw" "redis-user"
printf "%-25s %-40s %-40s %-5s %-15s\n" "ollama-models" "$DATA_ROOT/paperless/ollama" "/root/.ollama" "rw" "0:0"
echo "  Note: gotenberg/tika are stateless (no volumes). ollama only exists with COMPOSE_PROFILES=ai."
echo ""
echo "  PAPERLESS_URL: ${PAPERLESS_URL:-not set} | INTEGRATION_MODE: ${INTEGRATION_MODE:-consume-drop}"
echo ""
echo "=== End ==="
