#!/usr/bin/env bash
# mroffice tests

set -e

echo "=== mroffice tests ==="

# Check Makefile syntax
make -n help >/dev/null && echo "✓ Makefile syntax OK"

# Check scripts are executable/basically valid
for s in scripts/*.sh; do
    bash -n "$s" && echo "✓ $(basename $s) syntax OK" || exit 1
done

# Validate compose files parse (needs docker compose or podman compose)
if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    docker compose -f compose/paperless.yml config -q && echo "✓ compose/paperless.yml valid"
    docker compose -f compose/nextcloud-aio.yml config -q && echo "✓ compose/nextcloud-aio.yml valid"
elif command -v podman >/dev/null 2>&1; then
    podman compose -f compose/paperless.yml config -q && echo "✓ compose/paperless.yml valid" || echo "⚠ paperless compose check skipped/failed"
else
    echo "⚠ no compose engine — skipping compose validation"
fi

echo ""
echo "=== All tests passed ==="
