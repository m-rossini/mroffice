#!/usr/bin/env bash
# mroffice init

set -e
source "$(dirname "$0")/lib/runtime.sh" 2>/dev/null || true

# Get DATA_ROOT from env or default
DATA_ROOT="${DATA_ROOT:-/srv/mroffice}"
# Expand tilde properly
if [[ "$DATA_ROOT" == ~* ]]; then
    DATA_ROOT="${DATA_ROOT/#\~/$HOME}"
fi

echo "=== mroffice init ==="
echo "DATA_ROOT: $DATA_ROOT"

# Create config from template
if [ ! -f ".env" ]; then
    if [ -f "config/env.example" ]; then
        cp config/env.example .env
        sed -i "s|^DATA_ROOT=.*|DATA_ROOT=$DATA_ROOT|" .env 2>/dev/null || true
        echo "✓ Created .env from config/env.example"
    else
        echo "✗ config/env.example not found"
        exit 1
    fi
else
    echo "✓ .env already exists"
    sed -i "s|^DATA_ROOT=.*|DATA_ROOT=$DATA_ROOT|" .env 2>/dev/null || true
fi

# Generate secrets
if [ ! -f "config/.secrets.env" ]; then
    echo "Generating secrets..."
    {
        echo "# Generated secrets - DO NOT COMMIT"
        echo "NEXTCLOUD_ADMIN_PASSWORD=$(openssl rand -base64 32 | tr -d '=+/')"
        echo "PAPERLESS_ADMIN_PASSWORD=$(openssl rand -base64 32 | tr -d '=+/')"
        echo "PAPERLESS_API_TOKEN=$(openssl rand -hex 32)"
        echo "PAPERLESS_SECRET_KEY=$(openssl rand -hex 32)"
        echo "POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d '=+/')"
        echo "REDIS_PASSWORD=$(openssl rand -base64 32 | tr -d '=+/')"
    } > config/.secrets.env
    chmod 600 config/.secrets.env
    echo "✓ Generated config/.secrets.env (600)"
else
    echo "✓ config/.secrets.env already exists"
fi

# Create DATA_ROOT directories
echo ""
echo "Creating directories under $DATA_ROOT..."
mkdir -p "$DATA_ROOT"/nextcloud/{data,config} "$DATA_ROOT"/backups 2>&1
mkdir -p "$DATA_ROOT"/paperless/{media,data,consume,export,pgdata} 2>&1

if [ "$(id -u)" -eq 0 ]; then
    chown -R 33:33 "$DATA_ROOT/nextcloud" 2>/dev/null || chown -R www-data:www-data "$DATA_ROOT/nextcloud" 2>/dev/null || true
    chown -R 1000:1000 "$DATA_ROOT/paperless" 2>/dev/null || true
else
    echo "⚠ Running as non-root; ensure container users can access bind mounts"
fi

chmod -R 755 "$DATA_ROOT" 2>/dev/null || true

echo "✓ Directories created"
ls -la "$DATA_ROOT" 2>&1 | head -6
echo ""
echo "=== Done ==="
