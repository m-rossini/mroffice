#!/usr/bin/env bash
# mroffice config validation

set -e
source "$(dirname "$0")/lib/runtime.sh" 2>/dev/null || true

echo "=== mroffice config ==="

# Load env
[ -f ".env" ] && set -a && source .env && set +a
[ -f "config/.secrets.env" ] && set -a && source config/.secrets.env && set +a

# Check required vars
REQUIRED=(DATA_ROOT RUNTIME PROFILE ENV)
for var in "${REQUIRED[@]}"; do
    if [ -z "${!var}" ]; then
        echo "✗ Missing required: $var"
        exit 1
    else
        echo "✓ $var=${!var}"
    fi
done

# Validate DATA_ROOT is absolute and not in repo
case "$DATA_ROOT" in
    /*)
        echo "✓ DATA_ROOT is absolute"
        ;;
    *)
        echo "✗ DATA_ROOT must be absolute path"
        exit 1
        ;;
esac

REPO_ROOT="$(pwd)"
if [[ "$DATA_ROOT" == "$REPO_ROOT"* ]]; then
    echo "✗ DATA_ROOT must not be inside the repository"
    exit 1
else
    echo "✓ DATA_ROOT not inside repo"
fi

# Check data dirs exist or can be created
for d in "$DATA_ROOT/nextcloud/data" "$DATA_ROOT/nextcloud/config"; do
    if [ -d "$d" ]; then
        echo "✓ $d exists"
    else
        echo "⚠ $d missing (run make init)"
    fi
done

echo ""
echo "=== Config OK ==="
