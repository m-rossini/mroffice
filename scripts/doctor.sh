#!/usr/bin/env bash
# mroffice doctor

set -e
source "$(dirname "$0")/lib/runtime.sh" 2>/dev/null || true

echo "=== mroffice doctor ==="
echo "Date: $(date)"
echo ""

# Runtime detection
if detect_runtime; then
    echo "✓ Runtime: $RUNTIME"
else
    echo "✗ Runtime: not found"
fi

# Compose
if command -v podman-compose >/dev/null 2>&1; then
    echo "✓ podman-compose available"
elif command -v docker-compose >/dev/null 2>&1; then
    echo "✓ docker-compose available"
fi
echo "✓ COMPOSE: ${COMPOSE:-unknown}"

# Disk space
echo ""
echo "--- Disk ---"
df -h /srv 2>/dev/null || df -h / | tail -1

# SELinux
if command -v getenforce >/dev/null 2>&1; then
    echo ""
    echo "--- SELinux ---"
    getenforce
fi

# Check DATA_ROOT
echo ""
echo "--- DATA_ROOT ---"
DATA_ROOT=${DATA_ROOT:-/srv/mroffice}
if [ -d "$DATA_ROOT" ]; then
    echo "✓ $DATA_ROOT exists"
    ls -ld "$DATA_ROOT" 2>&1 | head -1
else
    echo "⚠ $DATA_ROOT does not exist (run make init)"
fi

# Check config
echo ""
echo "--- Config ---"
if [ -f ".env" ]; then
    echo "✓ .env exists"
else
    echo "⚠ .env missing (run make init)"
fi
if [ -f "config/.secrets.env" ]; then
    echo "✓ config/.secrets.env exists"
else
    echo "⚠ config/.secrets.env missing (run make init)"
fi

echo ""
echo "=== Done ==="
