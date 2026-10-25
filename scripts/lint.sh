#!/usr/bin/env bash
# lint

set -e
echo "=== mroffice lint ==="

# shellcheck
if command -v shellcheck >/dev/null 2>&1; then
    echo "[shellcheck]"
    for s in scripts/*.sh tests/*.sh; do
        [ -f "$s" ] && shellcheck "$s" && echo "  ✓ $s"
    done
else
    echo "shellcheck not installed"
fi

# make -n dry runs
echo ""
echo "[make -n]"
for t in help doctor init config up down ps storage; do
    make -n $t >/dev/null 2>&1 && echo "  ✓ make -n $t"
done

# basic secret scan
echo ""
echo "[secret scan]"
if git rev-parse --git-dir >/dev/null 2>&1; then
    if git ls-files | grep -E '\.env$|secrets' | grep -v example | grep -v secrets.env.example; then
        echo "  ⚠ Possible secrets tracked"
    else
        echo "  ✓ No secrets tracked"
    fi
fi

echo ""
echo "=== Lint done ==="
