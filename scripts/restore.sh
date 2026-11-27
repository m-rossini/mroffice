#!/usr/bin/env bash
# mroffice restore — from a `make backup` stamp dir. Guarded, STACK-aware.
# Usage: make restore BACKUP=/var/backups/mroffice/20261127-1200 [STACK=paperless]

set -e
source "$(dirname "$0")/lib/runtime.sh" 2>/dev/null || true

[ -f ".env" ] && set -a && source .env && set +a
restore_env
[ -f "config/.secrets.env" ] && set -a && source config/.secrets.env && set +a
restore_env

STACK=${STACK:-all}
DATA_ROOT=${DATA_ROOT:-/srv/mroffice}
BACKUP=${BACKUP:-}

if [ -z "$BACKUP" ]; then
    echo "Error: BACKUP= required (e.g. make restore BACKUP=/var/backups/mroffice/20261127-1200)"
    exit 1
fi
if [ ! -d "$BACKUP" ]; then
    echo "Error: backup dir not found: $BACKUP"
    exit 1
fi

echo "=== mroffice restore (STACK=$STACK) from $BACKUP ==="
echo "DATA_ROOT: $DATA_ROOT"
echo "This will OVERWRITE live data. Re-run with FORCE=1 to confirm."
if [ "${FORCE:-0}" != "1" ]; then
    ls -lh "$BACKUP"
    exit 1
fi

if [ "$STACK" = "paperless" ] || [ "$STACK" = "all" ]; then
    if [ -f "$BACKUP/paperless-media.tar.gz" ] && [ -f "$BACKUP/paperless-db.sql" ]; then
        echo "--- Paperless-ngx ---"
        echo "Stopping paperless..."
        # shellcheck disable=SC2086
        compose -f compose/paperless.yml down 2>/dev/null || true
        echo "Restoring media..."
        tar -xzf "$BACKUP/paperless-media.tar.gz" -C "$DATA_ROOT/paperless"
        echo "Starting db only..."
        # shellcheck disable=SC2086
        compose -f compose/paperless.yml up -d db
        echo "Waiting for db..."
        sleep 8
        echo "Loading dump..."
        # shellcheck disable=SC2086
        compose -f compose/paperless.yml exec -T db psql -U "${POSTGRES_USER:-paperless}" -d "${POSTGRES_DB:-paperless}" < "$BACKUP/paperless-db.sql"
        echo "✓ Paperless restored. Run: STACK=paperless make up"
    else
        echo "⚠ no paperless backup files in $BACKUP (skipping)"
    fi
fi

if [ "$STACK" = "nextcloud" ] || [ "$STACK" = "all" ]; then
    if [ -f "$BACKUP/nextcloud-data.tar.gz" ]; then
        echo "--- Nextcloud ---"
        $RUNTIME stop nextcloud-aio-mastercontainer 2>/dev/null || true
        echo "Restoring DATA_ROOT/nextcloud..."
        tar -xzf "$BACKUP/nextcloud-data.tar.gz" -C "$DATA_ROOT"
        echo "✓ Nextcloud data restored. Re-run AIO setup if needed; see docs/backup-restore.md."
    else
        echo "⚠ no nextcloud backup file in $BACKUP (skipping)"
    fi
fi

echo ""
echo "=== Restore done ==="
