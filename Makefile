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
SERVICE ?=
FILE ?=
BACKUP ?=
COMPOSE_PROJECT_NAME ?= mroffice

export RUNTIME COMPOSE PROFILE ENV HOST STACK DATA_ROOT BACKUP_TARGET FORCE SERVICE FILE BACKUP COMPOSE_PROJECT_NAME

.PHONY: help doctor init config up down restart ps status storage logs consume admin shell ai-up pull update backup restore smoke test lint deploy paperless-check integration-check clean dev

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

## logs: Follow logs [STACK=all|paperless|nextcloud SERVICE=...]
logs:
	@bash scripts/logs.sh $(SERVICE)

## consume: Queue a file for Paperless import: make consume FILE=/path/to/doc.pdf
consume:
	@if [ -z "$(FILE)" ]; then echo "Usage: make consume FILE=/path/to/document.pdf"; exit 1; fi
	@test -f "$(FILE)" || { echo "No such file: $(FILE)"; exit 1; }
	@test -d "$(DATA_ROOT)/paperless/consume" || { echo "Consume dir missing: $(DATA_ROOT)/paperless/consume (run make init)"; exit 1; }
	@cp "$(FILE)" "$(DATA_ROOT)/paperless/consume/"
	@echo "Queued $(notdir $(FILE)) for import."

## admin: Create the Paperless superuser (interactive)
admin:
	@COMPOSE_PROJECT_NAME="$(COMPOSE_PROJECT_NAME)" $(COMPOSE) -f compose/paperless.yml exec webserver python3 manage.py createsuperuser

## shell: Open a shell inside the Paperless webserver container
shell:
	@COMPOSE_PROJECT_NAME="$(COMPOSE_PROJECT_NAME)" $(COMPOSE) -f compose/paperless.yml exec webserver bash

## ai-up: Start Paperless + local LLM (ollama) for AI suggestions/chat
ai-up:
	@COMPOSE_PROFILES=ai STACK=paperless bash scripts/up.sh

## pull: Pull pinned images
pull:
	@bash scripts/pull.sh

## update: Backup, pull, recreate, smoke
update: backup pull
	@bash scripts/update.sh
	@$(MAKE) smoke

## backup: Backup stack(s) [STACK=all|nextcloud|paperless]
backup:
	@bash scripts/backup.sh

## restore: Restore from backup BACKUP=... [STACK=... FORCE=1]
restore:
	@if [ -z "$(BACKUP)" ]; then echo "Error: BACKUP= required"; exit 1; fi
	@BACKUP="$(BACKUP)" FORCE="$(FORCE)" STACK="$(STACK)" bash scripts/restore.sh

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
