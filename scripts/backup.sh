#!/usr/bin/env bash
# mroffice backup — STACK-aware (nextcloud|paperless|all)
# Paperless: pg_dump + media.tar.gz (mirrors document_repo, adapted to DATA_ROOT)
# Nextcloud: tar of DATA_ROOT/nextcloud + config snapshot (.env, versions, env.example)
# Secrets (config/.secrets.env) are included in the backup tar — store backups securely, off-machine.
# Usage: make backup [STACK=paperless]

set -e
source "$(dirname "$0")/lib/runtime.sh" 2>/dev/null || true

[ -f ".env" ] && set -a && source .env && set +a
restore_env
[ -f "config/versions.env" ] && set -a && source config/versions.env && set +a
restore_env
[ -f "config/.secrets.env" ] && set -a && source config/.secrets.env && set +a
restore_env

STACK=${STACK:-all}
DATA_ROOT=${DATA_ROOT:-/srv/mroffice}
BACKUP_TARGET=${BACKUP_TARGET:-/var/backups/mroffice}
stamp=$(date +%Y%m%d-%H%M)
dest="$BACKUP_TARGET/$stamp"

echo "=== mroffice backup (STACK=$STACK) -> $dest ==="
mkdir -p "$dest"

if [ "$STACK" = "paperless" ] || [ "$STACK" = "all" ]; then
    echo "--- Paperless-ngx ---"
    echo "Dumping postgres..."
    # shellcheck disable=SC2086
    compose -f compose/paperless.yml exec -T db pg_dump -U "${POSTGRES_USER:-paperless}" "${POSTGRES_DB:-paperless}" > "$dest/paperless-db.sql"
    echo "Archiving media..."
    tar -czf "$dest/paperless-media.tar.gz" -C "$DATA_ROOT/paperless" media
    echo "✓ paperless-db.sql + paperless-media.tar.gz"
fi

if [ "$STACK" = "nextcloud" ] || [ "$STACK" = "all" ]; then
    echo "--- Nextcloud ---"
    echo "Archiving DATA_ROOT/nextcloud + config snapshot..."
    tar -czf "$dest/nextcloud-data.tar.gz" -C "$DATA_ROOT" nextcloud 2>/dev/null || echo "⚠ no nextcloud data yet"
    {
        [ -f ".env" ] && echo ".env"
        [ -f "config/env.example" ] && echo "config/env.example"
        [ -f "config/versions.env" ] && echo "config/versions.env"
        [ -f "config/.secrets.env" ] && echo "config/.secrets.env"
        [ -f "compose/nextcloud-aio.yml" ] && echo "compose/nextcloud-aio.yml"
        [ -f "compose/paperless.yml" ] && echo "compose/paperless.yml"
    } | tar -czf "$dest/config-snapshot.tar.gz" -T - 2>/dev/null || true
    echo "✓ nextcloud-data.tar.gz + config-snapshot.tar.gz"
    echo "  NOTE: config-snapshot contains secrets — keep $BACKUP_TARGET secure and copy off-machine."
fi

ls -lh "$dest"
echo ""
echo "=== Backup done: $dest ==="
echo "Copy off this machine for real safety."
