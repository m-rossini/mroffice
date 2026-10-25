#!/usr/bin/env bash
# Update up script for Nextcloud AIO

set -e
source "$(dirname "$0")/lib/runtime.sh" 2>/dev/null || true

[ -f ".env" ] && set -a && source .env && set +a
[ -f "config/.secrets.env" ] && set -a && source config/.secrets.env && set +a

echo "=== mroffice up ==="
echo "RUNTIME: $RUNTIME | PROFILE: $PROFILE | STACK: ${STACK:-all}"

make config || exit 1

STACK=${STACK:-all}

if [ "$STACK" = "nextcloud" ] || [ "$STACK" = "all" ]; then
    echo ""
    echo "--- Nextcloud AIO ---"
    echo "Note: Paperless is on remote host (${PAPERLESS_URL:-not configured})"
    
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
        $COMPOSE -f compose/nextcloud-aio.yml up -d 2>&1 | tail -20
        echo ""
        echo "AIO Mastercontainer starting. Access at:"
        echo "  https://localhost:${APACHE_PORT:-443} (after setup)"
        echo "  Admin interface: http://localhost:${AIO_PORT:-8080}"
        echo ""
        echo "Complete AIO setup in browser, then configure Collabora through AIO interface."
    fi
fi

echo ""
echo "=== Up complete ==="
echo "Run 'make ps' to check status"
