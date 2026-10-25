# Integration: Nextcloud AIO <-> Remote Paperless-ngx

Paperless-ngx is already running on another machine. This document describes how to integrate them.

## Modes (in order of preference)

### 1. Consume drop via external storage (recommended for split-host)
- Export Paperless `consume/` folder from remote host via SFTP/SMB/WebDAV
- Mount it as Nextcloud External Storage in the "files_external" app
- Drop files into that folder from Nextcloud - Paperless will pick them up
- Works across hosts, no code changes to Paperless

### 2. API push
- Use Paperless API: `POST /api/documents/post_document/` with auth token
- Create a script/Nextcloud flow or webhook to push files
- Token stored in `config/.secrets.env` as `PAPERLESS_API_TOKEN`

### 3. External storage bridge (read-only browse)
- Mount Paperless `media/` read-only via SFTP/SMB as external storage
- Users can browse/view documents from Nextcloud
- Links can point to Paperless UI

## Configuration

In `.env`:
```bash
PAPERLESS_URL=https://paperless.example.com
PAPERLESS_API_URL=https://paperless.example.com
PAPERLESS_API_TOKEN=  # from config/.secrets.env
INTEGRATION_MODE=consume-drop
NEXTCLOUD_PAPERLESS_SHARE=Paperless-Ingest
```

## Steps

1. Configure remote Paperless consume path and ensure accessible
2. Set up network access (VPN/Tailscale/WireGuard recommended)
3. In Nextcloud, enable "External storage support" app
4. Add external storage pointing to remote consume location
5. Test with `make integration-check`
6. Test ingestion end-to-end

## Security
- Use VPN/private network, never expose consume over public internet without auth
- API tokens with minimal scopes
- Read-only mounts where possible
- No secrets in git
