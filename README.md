# mroffice

Reproducible, self-hosted office and document stack using containers with `make` as the CLI interface.

## Features

- **Nextcloud AIO** with **Collabora Online** for file sync and browser-based Office editing
- **Integration with remote Paperless-ngx** for document ingestion and archival (Paperless runs on separate machine)
- Runtime-agnostic: Podman (rootless/Quadlet) first, Docker fallback
- Host-bound storage via bind mounts under `DATA_ROOT`
- All operations through Make targets
- Idempotent, safe operations

## Quick Start

```bash
# Initialize
make init DATA_ROOT=~/mroffice

# Configure
make config

# Check system
make doctor

# Start Nextcloud AIO
make up

# Access
# AIO Admin: http://localhost:8080
# Nextcloud: https://localhost:443 (after AIO setup)
```

## Architecture

- **Host A/B**: Nextcloud AIO can run on one host, Paperless-ngx on another
- **Integration modes**: consume-drop (via external storage), API push, or read-only bridge
- **Storage**: All persistent data in bind mounts under `DATA_ROOT` (AIO internals documented as exceptions)

## Make Targets

Run `make help` for all available targets.

## Documentation

- [Quickstart](docs/quickstart.md)
- [Integration](docs/integration.md)
- [Backup & Restore](docs/backup-restore.md)
- [AGENT.md](AGENT.md) - Full specification

## License

See repository for details.
