# Quickstart

## Prerequisites
- Docker (or Podman rootless) with Compose v2
- ~2 GB RAM free for Paperless; more with `COMPOSE_PROFILES=ai` (ollama pulls a model)
- Domain/DNS configured or localhost

## Setup

```bash
# 1. Initialize (creates DATA_ROOT dirs, .env, secrets)
make init DATA_ROOT=~/mroffice

# 2. Review and edit config
vim .env
# OCR default is por+eng; AI is off by default (PAPERLESS_AI_ENABLED=0).

# 3. Check system
make doctor
make config
make storage

# 4. Start the unified stack (Nextcloud AIO + local Paperless)
make up
# ...or paperless alone first:
STACK=paperless make up

# 5. Create the Paperless login + feed a document
make admin
make consume FILE=~/Downloads/invoice.pdf
# open http://localhost:8000 — OCR + tags appear within ~a minute

# 6. Complete Nextcloud AIO setup in browser
#    http://localhost:8080 — follow the AIO wizard
#    Enable Collabora through the AIO interface.

# 7. Verify
make paperless-check
make integration-check
STACK=paperless make smoke
```

## AI (optional, local only)

```bash
# in .env:
PAPERLESS_AI_ENABLED=1
# PAPERLESS_AI_LLM_MODEL=qwen3:8b  (default; pull alternatives with: docker exec -it mroffice-ollama ollama pull <model>)

COMPOSE_PROFILES=ai STACK=paperless make up
# or: make ai-up
```

Paperless 3.x native AI gives title/tags/correspondent/type suggestions, chat over documents and
similar-documents. Nothing leaves the machine (ollama is internal to the compose network unless
`OLLAMA_PORT` is set).

## Notes
- Paperless runs **locally** by default (`compose/paperless.yml`); split-host (remote Paperless via
  `PAPERLESS_URL`) is still supported — see `docs/integration.md`.
- Nextcloud AIO creates some engine-managed storage (see `make storage`).
- All persistent data lives under `DATA_ROOT` bind mounts — `make down` never deletes it.
- `make help` lists every target; prefix with `STACK=paperless|nextcloud` to scope.
