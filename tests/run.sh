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

echo ""
echo "=== All tests passed ==="
