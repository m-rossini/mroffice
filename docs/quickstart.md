# Quickstart

## Prerequisites
- Podman (rootless preferred) or Docker
- Network access to remote Paperless-ngx instance
- Domain/DNS configured or use localhost

## Setup

```bash
# 1. Initialize (create dirs, secrets, config)
make init

# 2. Review and edit config
vim .env
vim config/.secrets.env  # add PAPERLESS_API_TOKEN if using API mode

# 3. Check system
make doctor
make config

# 4. Start Nextcloud AIO
make up

# 5. Complete Nextcloud AIO setup in browser
#    http://localhost:8080 - follow AIO wizard
#    Enable Collabora through AIO interface

# 6. Configure integration with remote Paperless
#    See docs/integration.md
make paperless-check
make integration-check
```

## Notes
- Paperless-ngx runs on another machine - not managed by this repo
- Nextcloud AIO creates some engine-managed storage (see `make storage`)
- All persistent data under DATA_ROOT bind-mounted where possible
- Use `make help` for all commands
