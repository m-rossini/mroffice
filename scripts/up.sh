#!/usr/bin/env bash
# Update up script for Nextcloud AIO

set -e
source "$(dirname "$0")/lib/runtime.sh" 2>/dev/null || true

[ -f ".env" ] && set -a && source .env && set +a
restore_env
[ -f "config/.secrets.env" ] && set -a && source config/.secrets.env && set +a
restore_env

echo "=== mroffice up ==="
echo "RUNTIME: $RUNTIME | PROFILE: $PROFILE | STACK: ${STACK:-all}"

make config || exit 1

STACK=${STACK:-all}

# Load pinned versions (tags) so compose uses explicit versions, never :latest-by-accident
[ -f "config/versions.env" ] && set -a && source config/versions.env && set +a
restore_env

# NOTE: `compose` comes from scripts/lib/runtime.sh (project name via exported env).
paperless_compose() {
    compose -f compose/paperless.yml "$@"
}

if [ "$STACK" = "nextcloud" ] || [ "$STACK" = "all" ]; then
    echo ""
    echo "--- Nextcloud AIO ---"
    if [ -n "${PAPERLESS_URL:-}" ]; then
        echo "Paperless URL: ${PAPERLESS_URL} (local stack when STACK includes paperless)"
    fi
    if [ "$RUNTIME" = "podman" ]; then
        # Check for podman socket
        if [ -S "/run/podman/podman.sock" ]; then
            echo "✓ Podman socket found at /run/podman/podman.sock"
            export DOCKER_SOCKET_PATH=/run/podman/podman.sock
        elif [ -S "$XDG_RUNTIME_DIR/podman/podman.sock" ]; then
            echo "✓ Podman socket found at $XDG_RUNTIME_DIR/podman/podman.sock"
            export DOCKER_SOCKET_PATH=$XDG_RUNTIME_DIR/podman/podman.sock
        else
            echo "⚠ Podman socket not found. AIO may need rootful podman or docker compatibility."
            echo "  Try: systemctl --user enable --now podman.socket or sudo systemctl enable --now podman.socket"
        fi
    fi
    
    if [ -f "compose/nextcloud-aio.yml" ]; then
        echo "Starting Nextcloud AIO mastercontainer..."
        compose -f compose/nextcloud-aio.yml up -d 2>&1 | tail -20
        echo ""
        echo "AIO Mastercontainer starting. Access at:"
        echo "  https://localhost:${APACHE_PORT:-443} (after setup)"
        echo "  Admin interface: http://localhost:${AIO_PORT:-8080}"
        echo ""
        echo "Complete AIO setup in browser, then configure Collabora through AIO interface."
    fi
fi

if [ "$STACK" = "paperless" ] || [ "$STACK" = "all" ]; then
    echo ""
    echo "--- Paperless-ngx (local unified stack) ---"
    if [ -f "compose/paperless.yml" ]; then
        echo "Starting Paperless-ngx + gotenberg + tika (ollama only with COMPOSE_PROFILES=ai)..."
        paperless_compose up -d 2>&1 | tail -20
        echo ""
        echo "Paperless UI: http://localhost:${PAPERLESS_PORT:-8000}"
        echo "Feed documents: make consume FILE=/path/to/doc.pdf (watches ${DATA_ROOT:-/srv/mroffice}/paperless/consume/)"
        if [ "${PAPERLESS_AI_ENABLED:-0}" = "1" ]; then
            echo "AI enabled: ${PAPERLESS_AI_LLM_MODEL:-qwen3:8b} via ${PAPERLESS_AI_LLM_ENDPOINT:-http://ollama:11434}"
            echo "  (run with COMPOSE_PROFILES=ai to start ollama)"
        fi
    fi
fi

echo ""
echo "=== Up complete ==="
echo "Run 'make ps' to check status"
