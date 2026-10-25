# Backup and Restore

## Backup
`make backup` backs up:
- Nextcloud AIO data from bind mounts (`DATA_ROOT/nextcloud/`) 
- Configuration files (`.env`, `config/`)
- For AIO internals (mastercontainer config/volume) - documented in `make storage`

Paperless is on remote machine - backup separately using Paperless `document_exporter` or its own backup procedure.

## Restore
`make restore BACKUP=path/to/backup` - restore from named backup

## Manual backup
```bash
# Stop services
make down

# Backup DATA_ROOT
tar czf /var/backups/mroffice/backup-$(date +%Y%m%d).tar.gz -C $(dirname $DATA_ROOT) $(basename $DATA_ROOT) .env config/

# Start services
make up
```

## Notes
- Always backup before updates (`make update` does this)
- AIO has its own backup mechanism via AIO interface - recommended to use it too
- Test restores periodically
