# mroffice Makefile - thin entry point

-include make/runtime.mk
-include make/nextcloud.mk
-include make/paperless.mk
-include make/integration.mk
-include make/ops.mk

.DEFAULT_GOAL := help

RUNTIME ?= podman
COMPOSE ?= podman compose
PROFILE ?= local
ENV ?= dev
HOST ?= local
STACK ?= all
DATA_ROOT ?= /srv/mroffice
BACKUP_TARGET ?= /var/backups/mroffice
FORCE ?= 0

-include .env
-include config/.secrets.env

## help: List targets and current variable values
help:
	@echo "mroffice - reproducible, self-hosted office and document stack"
	@echo ""
	@echo "Variables (override with VAR=value):"
	@echo "  RUNTIME=$(RUNTIME)  COMPOSE=$(COMPOSE)  PROFILE=$(PROFILE)"
	@echo "  ENV=$(ENV)  HOST=$(HOST)  STACK=$(STACK)"
	@echo "  DATA_ROOT=$(DATA_ROOT)  BACKUP_TARGET=$(BACKUP_TARGET)  FORCE=$(FORCE)"
	@echo ""
	@echo "Targets:"
	@grep -E '^## ' $(MAKEFILE_LIST) | sed -e 's/^## //' | sort

## doctor: Detect runtime, versions, ports, DNS/TLS readiness
doctor:
	@bash scripts/doctor.sh

## init: Create config from template, generate secrets, create dirs
init:
	@bash scripts/init.sh

## config: Render/validate configuration
config:
	@bash scripts/config.sh

## up: Start the selected stack(s), idempotently
up:
	@bash scripts/up.sh

## down: Stop containers; keep bind-mounted host directories untouched
down:
	@bash scripts/down.sh

## restart: Restart without recreating data
restart: down up

## ps: Show container status
ps:
	@$(RUNTIME) ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || docker ps -a 2>/dev/null

## status: Show container status
status: ps

## storage: Print authoritative storage map
storage:
	@bash scripts/storage.sh

## logs: Follow logs [SERVICE=...]
logs:
	@bash scripts/logs.sh $(SERVICE)

## pull: Pull pinned images
pull:
	@bash scripts/pull.sh

## update: Backup, pull, recreate, smoke
update: backup pull
	@bash scripts/update.sh
	@$(MAKE) smoke

## backup: Backup stack
backup:
	@bash scripts/backup.sh

## restore: Restore from backup BACKUP=...
restore:
	@if [ -z "$(BACKUP)" ]; then echo "Error: BACKUP= required"; exit 1; fi
	@bash scripts/restore.sh $(BACKUP)

## smoke: End-to-end checks
smoke:
	@bash scripts/smoke.sh

## test: Config validation + tests
test:
	@bash tests/run.sh

## lint: shellcheck, yamllint, make -n, secret scan
lint:
	@bash scripts/lint.sh

## deploy: Deploy to remote host HOST=<ssh-target>
deploy:
	@if [ -z "$(HOST)" ] || [ "$(HOST)" = "local" ]; then echo "Error: HOST= required"; exit 1; fi
	@bash scripts/deploy.sh $(HOST)

## paperless-check: Verify Paperless reachability
paperless-check:
	@bash scripts/paperless_check.sh

## integration-check: Verify integration
integration-check:
	@bash scripts/integration_check.sh

## clean: Destructive operation - requires FORCE=1
clean:
	@if [ "$(FORCE)" != "1" ]; then echo "Destructive. Use FORCE=1"; $(MAKE) storage; exit 1; fi
	@bash scripts/clean.sh

## dev: Local development profile
dev:
	@$(MAKE) PROFILE=dev ENV=dev up
