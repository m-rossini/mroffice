#!/usr/bin/env bash
# Runtime abstraction for podman/docker

RUNTIME=${RUNTIME:-podman}
COMPOSE=${COMPOSE:-$RUNTIME compose}

detect_runtime() {
    if command -v podman >/dev/null 2>&1 && podman info >/dev/null 2>&1; then
        RUNTIME="podman"
        COMPOSE="podman compose"
        return 0
    elif command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
        RUNTIME="docker"
        COMPOSE="docker compose"
        return 0
    else
        echo "ERROR: Neither podman nor docker available/running"
        return 1
    fi
}

rt() {
    case "$1" in
        ps)
            $RUNTIME ps "$@"
            ;;
        run)
            $RUNTIME run "$@"
            ;;
        exec)
            $RUNTIME exec "$@"
            ;;
        *)
            $RUNTIME "$@"
            ;;
    esac
}

compose_cmd() {
    $COMPOSE "$@"
}

# Orchestration vars that `make VAR=x target` (and the environment) must win over
# .env files for. Snapshot them now (runtime.sh is sourced before any .env file),
# call `restore_env` after sourcing env files.
_mroffice_orch_vars="RUNTIME COMPOSE COMPOSE_PROJECT_NAME PROFILE ENV HOST STACK DATA_ROOT BACKUP_TARGET FORCE SERVICE FILE BACKUP"
for _v in $_mroffice_orch_vars; do
    if [ -n "${!_v+x}" ]; then
        printf -v "_mroffice_saved_${_v}" '%s' "${!_v}"
    else
        printf -v "_mroffice_saved_${_v}" '%s' '__MROFFICE_UNSET__'
    fi
done
unset _v

# Restore CLI/environment orchestration vars after sourcing .env/secret/version files.
restore_env() {
    local _v _s
    for _v in $_mroffice_orch_vars; do
        _s="_mroffice_saved_${_v}"
        if [ "${!_s}" != '__MROFFICE_UNSET__' ]; then
            printf -v "$_v" '%s' "${!_s}"
        fi
    done
}

# Project name for every compose invocation. Exported (not a --project-name flag):
# compose's own .env parsing chokes on our space-containing `COMPOSE="... compose"`
# line, so an explicit env var is the reliable channel on all engine versions.
COMPOSE_PROJECT_NAME=${COMPOSE_PROJECT_NAME:-mroffice}
compose() {
    # $COMPOSE is "podman compose" or "docker compose" (contains a space) — no quoting.
    # shellcheck disable=SC2086
    COMPOSE_PROJECT_NAME="$COMPOSE_PROJECT_NAME" COMPOSE_PROFILES="${COMPOSE_PROFILES:-}" $COMPOSE "$@"
}

export -f detect_runtime rt compose_cmd compose restore_env
export RUNTIME COMPOSE COMPOSE_PROJECT_NAME
