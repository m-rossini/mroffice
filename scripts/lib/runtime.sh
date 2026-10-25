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

export -f detect_runtime rt compose_cmd
export RUNTIME COMPOSE
