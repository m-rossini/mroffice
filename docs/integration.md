# Integration: Nextcloud AIO <-> Paperless-ngx

Local-first (unified stack). Split-host remains supported for an existing remote Paperless.

## Modes (in order of preference)

### 1. Consume drop (default, local)
- Drop files into `${DATA_ROOT}/paperless/consume/` (or `make consume FILE=...`).
- Paperless polls it (~every 10s), OCRs (`por+eng`), converts Office via gotenberg/tika, applies tags.
- To surface it in Nextcloud: enable "External storage support" and add a Local mount pointing at the
  consume dir (same host), or SMB/SFTP/WebDAV for split-host.
- Nextcloud share name: `NEXTCLOUD_PAPERLESS_SHARE=Paperless-Ingest`.

### 2. API push
- Use Paperless API: `POST /api/documents/post_document/` with auth token.
- Token lives in `config/.secrets.env` as `PAPERLESS_API_TOKEN`.
- Useful when no shared filesystem is possible (strict split-host).

### 3. External storage bridge (read-only browse)
- Mount Paperless `media/` read-only into Nextcloud (Local on same host, SFTP/SMB split-host).
- Users browse/view archived PDFs from Nextcloud; metadata/search stays in the Paperless UI.

## Configuration

In `.env`:
```bash
PAPERLESS_URL=http://localhost:8000
PAPERLESS_PORT=8000
INTEGRATION_MODE=consume-drop   # consume-drop|api-push|bridge
NEXTCLOUD_PAPERLESS_SHARE=Paperless-Ingest
# PAPERLESS_API_TOKEN lives in config/.secrets.env
```

Split-host (Paperless on another machine):
```bash
PAPERLESS_URL=https://paperless.example.com
PAPERLESS_API_URL=https://paperless.example.com
INTEGRATION_MODE=consume-drop  # via SFTP/SMB/WebDAV, or api-push
```

## Steps (local)

1. `STACK=paperless make up && make paperless-check`
2. In Nextcloud: enable "External storage support" app.
3. Add storage pointing at the local consume (write) and/or media (read-only) dirs.
4. Test: `make consume FILE=<doc>`, then `make integration-check` and `make smoke`.

## Steps (split-host)

1. Ensure network (VPN/Tailscale/WireGuard) between hosts.
2. Export remote `consume/` via SFTP/SMB; mount in Nextcloud as external storage.
3. Or set `INTEGRATION_MODE=api-push`, put the token in `config/.secrets.env`.
4. Test with `make paperless-check` (checks `$PAPERLESS_URL/api/` + local consume dir).

## Security
- Use VPN/private network for split-host; never expose consume over public internet without auth.
- API tokens with minimal scope; read-only mounts where possible.
- No secrets in git (`config/.secrets.env` is gitignored and included only in backup tars — keep those secure).
