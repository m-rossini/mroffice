#!/usr/bin/env bash
# mroffice down

set -e
source "$(dirname "$0")/lib/runtime.sh" 2>/dev/null || true

echo "=== mroffice down ==="
echo "Stopping containers... (bind mounts preserved)"

# Stop Nextcloud AIO if running
$RUNTIME stop nextcloud-aio-mastercontainer 2>/dev/null || true

echo "✓ Containers stopped"
echo "Data directories under DATA_ROOT untouched"
