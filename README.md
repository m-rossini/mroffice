# mroffice

Reproducible, self-hosted office and document stack using containers with `make` as the CLI interface.
One repo for editing **and** archiving: Nextcloud + Collabora for Office work, local Paperless-ngx for
scan / OCR / AI / search, all on host-bound storage under `DATA_ROOT`.

## Features

- **Nextcloud AIO** with **Collabora Online** for file sync and browser-based Office editing (`.odt/.docx/.xlsx/.pptx`)
- **Local Paperless-ngx** for document ingestion, OCR (`por+eng`), tagging and archival — `compose/paperless.yml`
  (webserver + postgres + redis + gotenberg for Office→PDF + tika for text extraction)
- **Optional local AI** (Paperless-ngx 3.x native): `COMPOSE_PROFILES=ai make ai-up` starts ollama for
  title/tags/correspondent suggestions, document chat and similar-documents — no cloud, data stays local
- **Integration**: Nextcloud ⇄ Paperless via consume-drop (default), API push, or read-only media bridge;
  works local-first, split-host still supported
- Runtime-agnostic: Podman (rootless/Quadlet) first, Docker fallback
- Host-bound storage via bind mounts under `DATA_ROOT` (`make storage` is authoritative)
- All operations through Make targets (`STACK=all|nextcloud|paperless`), idempotent and safe

## Quick Start

```bash
# Initialize (dirs under DATA_ROOT, .env, secrets)
make init DATA_ROOT=~/mroffice

# Configure + check
make config
make doctor

# Start everything (Nextcloud AIO + local Paperless)
make up
# ...or one stack at a time:
STACK=paperless make up
STACK=nextcloud make up

# Paperless admin + first document
make admin
make consume FILE=~/Downloads/invoice.pdf

# Access
# Paperless: http://localhost:8000
# AIO Admin: http://localhost:8080
# Nextcloud: https://localhost:443 (after AIO setup)
```

With AI (local LLM, no cloud):

```bash
# enable in .env: PAPERLESS_AI_ENABLED=1, then:
COMPOSE_PROFILES=ai STACK=paperless make up
# or: make ai-up
```

## Architecture

- **Single host (default)**: Nextcloud AIO + local Paperless-ngx side by side (`STACK=all`)
- **Split host (optional)**: Nextcloud AIO on host A, Paperless-ngx on host B via `PAPERLESS_URL` + `make deploy`
- **Integration modes**: consume-drop (via external storage or local consume dir), API push, or read-only bridge
- **Storage**: All persistent data in bind mounts under `DATA_ROOT` (AIO internals documented as exceptions).
  Paperless dirs: `paperless/{data,media,consume,export,pgdata,redisdata,ollama}` — see `make storage`.

## Make Targets

Run `make help` for all available targets.

## Documentation

- [Quickstart](docs/quickstart.md)
- [Integration](docs/integration.md)
- [Backup & Restore](docs/backup-restore.md)
- [AGENT.md](AGENT.md) - Full specification

## License

See repository for details.
