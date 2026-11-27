# Backup and Restore

STACK-aware (`STACK=all|nextcloud|paperless`). Destructive restore requires `FORCE=1`.

## Backup
`make backup [STACK=...]` writes to `BACKUP_TARGET/<YYYYMMDD-HHMM>/`:

| File | Contents |
|------|----------|
| `paperless-db.sql` | Full PostgreSQL dump |
| `paperless-media.tar.gz` | Originals + archived documents (`DATA_ROOT/paperless/media`) |
| `nextcloud-data.tar.gz` | `DATA_ROOT/nextcloud/` bind mounts |
| `config-snapshot.tar.gz` | `.env`, `config/{env.example,versions.env,.secrets.env}`, compose files |

```bash
STACK=paperless make backup   # paperless only
make backup                   # everything
```

Notes:
- `BACKUP_TARGET` defaults to `/var/backups/mroffice` (override per invocation).
- `config-snapshot.tar.gz` **contains secrets** — keep `BACKUP_TARGET` secure and copy off-machine
  (NAS / S3 / restic) for real safety.
- Nextcloud AIO also has its own backup mechanism via the AIO interface — recommended in addition.
- Always backup before updates (`make update` runs backup first via deps).

## Restore
```bash
# preview (refuses without FORCE=1, lists the stamp):
make restore BACKUP=/var/backups/mroffice/20261127-1200 STACK=paperless

# actually restore:
make restore BACKUP=/var/backups/mroffice/20261127-1200 STACK=paperless FORCE=1
STACK=paperless make up
```

Procedure per stack:
- **Paperless**: `down` → restore `media/` → `up db` → `psql < db.sql` → `up`. Documents, DB and
  search index survive; test with `make smoke`.
- **Nextcloud**: stop AIO mastercontainer → restore `DATA_ROOT/nextcloud/` → `up`. Re-run AIO setup
  if the AIO wizard demands it; see `make storage` for engine-managed AIO paths.

## Manual backup
```bash
make down
tar czf /var/backups/mroffice/manual-$(date +%Y%m%d).tar.gz -C $(dirname $DATA_ROOT) $(basename $DATA_ROOT)
make up
```

## Notes
- Test restores periodically; record RPO/RTO.
- Never copy `data/db` (`pgdata`) raw on rootless podman (subuid ownership) — use `make backup` (`pg_dump`).
