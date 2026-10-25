# AGENT.md — mroffice

> Entry point for humans and AI agents working on this repository.
> Read this before changing anything. If an objective below changes, update this file in the same change.

## 1. Mission

Provide a **reproducible, self-hosted office and document stack** that the owner can deploy,
update, back up and tear down **on demand**, using **containers** as the unit of packaging, with
**`make` as the only supported CLI interface**.

Two independent services must work together, and must be able to live on **different machines**:

1. **Nextcloud AIO** (All-in-One) for files, sync and collaboration, including **Collabora Online**
   for editing Office documents in the browser.
2. **Paperless-ngx** for document ingestion, OCR, tagging and archival.

"Containers" here is deliberately **runtime-agnostic**: Podman (including rootless Podman with
systemd/Quadlet on Fedora) is a first-class target, Docker is supported, and the project must not
hard-code Docker-specific assumptions into its interface.

## 2. Objectives

Each objective is measurable. A change is only complete when its objective's acceptance criteria
can be demonstrated with a command from the Make interface.

### O1 — One-command, reproducible deployment
- Bring the full stack up from a clean host with `make up` (or a documented two-step bootstrap).
- Idempotent: running `make up` twice changes nothing and does not destroy data.
- Every image is **pinned** (tag + digest) in a version file; upgrades are explicit (`make update`),
  never implicit.
- Tear down with `make down` **without touching data**; destructive deletion requires an explicit
  opt-in (`make clean FORCE=1`).
- All persistent state lives in **host directories bind-mounted into containers** (see O7), so it can
  be inspected, copied and backed up with normal filesystem tooling.
- All containners should be properly named to be unique in the machine they run.

### O2 — Nextcloud AIO with Collabora
- Nextcloud runs as the **AIO mastercontainer** with its managed containers (database, Redis,
  Nextcloud, Apache, etc.).
- Collabora Online is available for `.odt/.docx/.xlsx/.pptx` editing and is reachable through the
  Nextcloud UI with no extra manual configuration beyond `make config` + `make up`.
- This is or internal use.
- Users, groups, quotas, 2FA and app defaults are declared as code/config where AIO allows it, and
  otherwise documented as post-install runbook steps.

### O3 — Paperless-ngx, independently deployable
- Paperless-ngx runs as its own stack (web, worker, broker, database, optional Redis) with persistent
  **host directories bind-mounted** for `media`, `data`, `consume`, `export` and the database.
- It is deployable **on the same host or on another host** than Nextcloud, configured only through
  environment/config files — no code edits.
- Paperless NG is already setup and already is a different project 

### O4 — Nextcloud ⇄ Paperless integration
Both directions must be possible and verifiable:

- **Ingest (Nextcloud → Paperless):** a file dropped into a designated Nextcloud folder is picked up
  by Paperless (consume folder or API) and appears as a document, with tags/metadata applied.
- **Browse (Paperless → Nextcloud):** Paperless documents are discoverable from Nextcloud, either
  through a maintained Nextcloud app that talks to the Paperless API, or through a documented
  external-storage bridge (read-only view of `media/`).
- Integration must work **across machines**: endpoints, ports, TLS and credentials are configuration,
  not hard-coded. Credentials are stored as secrets, never in Git.
- Failure modes are documented and observable (`make smoke`, `make logs`), and a broken integration
  must not take down either service.

### O5 — `make` is the contract
- Every operation a human or agent needs is a Make target: bootstrap, configure, start, stop, status,
  storage map, logs, update, backup, restore, smoke test, lint, deploy to a remote host.
- Targets delegate to scripts in `scripts/`; the Makefile stays thin and self-documenting (`make help`).
- All targeting/configuration is driven by variables (`RUNTIME`, `ENV`, `HOST`, `PROFILE`), so the
  same targets serve local development, single-host production and split-host production.

### O6 — Operations are safe
- Backups: Nextcloud AIO's backup mechanism, plus Paperless `document_exporter`, reading from the
  bind-mounted host directories (`DATA_ROOT`) and writing to a configurable target (local disk, NAS,
  S3). Restore is documented and tested, including engine-managed AIO paths.
- Health: `make ps` and `make smoke` prove the stack is actually serving, not just running.
- Updates and rollbacks follow a documented procedure; backups are taken/verified before updates.
- Secrets never land in Git; generated secrets live in a git-ignored file or in the runtime's secret
  store (Podman secrets / systemd credentials / Docker secrets).

### O7 — Host-bound storage, never opaque volumes
- **Default and required pattern: bind mounts.** Persistent data is a directory on the host
  (`DATA_ROOT`, default `/srv/mroffice`) mounted into the container at a documented path.
  Named/anonymous engine volumes are **not** the storage model.
- Every bind mount is declared in one place and visible via `make storage`, which prints:
  container, host path, container path, mode (`rw`/`ro`), and owner/UID mapping.
- `make init` creates the directories with the correct ownership/permissions/SELinux labels before
  any container starts; `make doctor` verifies them.
- Because data lives on the host, a stack can be recreated from scratch (`make down && make up`)
  without data loss, and data can be moved between machines with `rsync`/`tar`.
- **Documented exception:** Nextcloud AIO creates and owns some internal storage that it does not
  expose as a bind mount (notably the mastercontainer config and its database volume). Those
  locations must be enumerated by `make storage`, included in backups, and explicitly marked as
  engine-managed. `NEXTCLOUD_DATADIR` and any other AIO-supported host-path option must point into
  `DATA_ROOT` so user data is always host-bound. A spike in M2 determines whether the remaining AIO
  internals can be bind-mounted; if not, the workaround is documented and accepted, or AIO is
  revisited (see open questions).
- Never store data in an anonymous volume. If a service only supports volumes, the stack is not
  done: find a bind-mount path or document the gap before merging.

## 3. Non-goals

- Building Nextcloud, Collabora or Paperless from source.
- Forking Nextcloud AIO or reimplementing its container orchestration.
- A custom sync/desktop client or mobile app.
- Mail server, DNS server or certificate authority (we consume existing DNS/TLS).
- Kubernetes. (Plain containers + systemd/compose only.)
- Multi-tenant SaaS features, billing, or per-customer isolation.

## 4. Constraints & principles

1. **Runtime-agnostic, Podman-first.** The primary development and production runtime is Podman on
   Fedora (rootless where possible, Quadlet/systemd for boot persistence). Docker + Compose must
   remain a supported fallback. No shell script may call `docker` directly; it must go through the
   runtime abstraction (`RUNTIME` / helper functions).
2. **Configuration over code.** Hostnames, ports, paths, domains, resource limits and integration
   settings live in `config/` and `.env` files. Nothing environment-specific is committed.
3. **Idempotency.** `make up`, `make config` and `make deploy` can be re-run safely.
4. **Data is sacred and host-bound.** Persistent state is a bind mount from `DATA_ROOT`, never an
   opaque named volume. No target deletes host data directories unless explicitly invoked with
   `FORCE=1` *and* the target name says so. Engine-managed storage is an exception only where the
   upstream project forces it, and must be enumerated, backed up and documented.
5. **Pin everything.** Images by digest, versions in one place. No `latest` in deployed configs.
6. **Works on one machine and on N machines.** Never assume Nextcloud and Paperless share a
   filesystem or a network namespace. Cross-host access goes through explicit, configured endpoints.
7. **Observable by default.** Structured logs, health checks, and a single `make smoke` that fails
   loudly.
8. **Docs are part of the deliverable.** A feature without a runbook entry and a Make target is
   not done.
9. **No hidden state.** Anything a container writes that must survive a restart is a declared host
   directory. `make storage` is the authoritative map; if it is not there, it will be lost.

## 5. Target architecture

```
                        ┌───────────────────────────────┐
   Internet / LAN ──────▶│  TLS termination (AIO Apache  │
                        │  or documented reverse proxy) │
                        └───────────────┬───────────────┘
                                        │
        ┌───────────────────────────────┴───────────────────────────────┐
        │ HOST A (e.g. Fedora + Podman)                                 │
        │                                                               │
        │  nextcloud-aio-mastercontainer (:8080 admin, :443 app)        │
        │   ├── nextcloud-aio-apache                                    │
        │   ├── nextcloud-aio-nextcloud  ── Collabora Online (WOPI)     │
        │   ├── nextcloud-aio-database                                  │
        │   ├── nextcloud-aio-redis                                     │
        │   └── nextcloud-aio-* (talk, backup, etc.)                    │
        │                                                               │
        │  bind mounts under ${DATA_ROOT}/nextcloud/                    │
        │    data/  → Nextcloud data dir (NEXTCLOUD_DATADIR)            │
        │    (AIO internals it cannot bind → documented exception)      │
        └───────────────────────────────┬───────────────────────────────┘
                                        │  HTTPS + API token
                                        │  (or SFTP/SMB bridge to consume/)
        ┌───────────────────────────────┴───────────────────────────────┐
        │ HOST B (may equal HOST A)                                     │
        │                                                               │
        │  paperless-ngx ── paperless-worker ── broker (Redis)          │
        │        └── postgres                                           │
        │  bind mounts under ${DATA_ROOT}/paperless/                    │
        │    media/  data/  consume/  export/  pgdata/                  │
        │                                                               │
        │  optional bridge: sftpgo / Samba / rclone sidecar             │
        └───────────────────────────────────────────────────────────────┘
```

`DATA_ROOT` is a host directory (default `/srv/mroffice`), owned by the project, not inside the repo.
Every persistent path is a subdirectory of it. The only engine-managed storage allowed is what
Nextcloud AIO creates internally; it is reported by `make storage` and covered by backups.

Notes:

- **Collabora placement:** default is AIO's managed Collabora container (simplest, same host).
  An external Collabora on another host is an optional profile; it requires a public Collabora
  domain and mutual reachability for WOPI (`/hosting/discovery`, file URLs).
- **AIO admin UI (`:8080`)** is an installation/management surface. It must never be exposed to the
  internet unauthenticated; restrict it to localhost/VPN or firewall it.
- **Cross-host integration** assumes a private network (WireGuard/Tailscale/VPN) or properly
  authenticated public endpoints. No plaintext credentials over the open internet.

## 6. Integration design (Nextcloud ⇄ Paperless)

The integration is deliberately split into two independent capabilities so either can fail alone.

### 6.1 Ingest — Nextcloud → Paperless

Chosen direction (in order of preference, decided by a spike during M3):

1. **Shared consume drop:** Nextcloud external storage (SMB/SFTP/WebDAV) points at the Paperless
   `consume/` directory, exported by a sidecar (sftpgo/Samba) or a network share. Dropping a file in
   the Nextcloud folder triggers Paperless ingestion. *Works across hosts; no Paperless code needed.*
2. **API push:** a documented script/webhook calls `POST /api/documents/post_document/` with an API
   token. Useful when no shared filesystem is possible.
3. **Native Paperless "consume" mount** of a Nextcloud-backed share — only when both services share a
   host or a supported network filesystem.

### 6.2 Browse — Paperless → Nextcloud

1. **Nextcloud app** that queries the Paperless API (if a maintained app supports the current
   Nextcloud + Paperless versions). Preferred UX: search and open documents from Nextcloud.
2. **External storage bridge** exposing Paperless `media/` (originals + archived PDFs) read-only via
   SFTP/SMB. Always available as a fallback; metadata/search stays in Paperless, with links from
   Nextcloud to the Paperless UI.

Whichever option is adopted, document:

- required API token/scopes and where the secret lives;
- endpoint URL(s) and TLS verification policy (never `--insecure` by default);
- which folders are read-only vs write (consume is write-only in practice);
- expected latency for ingestion (worker polling interval);
- how to revoke/rotate the token.

### 6.3 Identity & access

- Paperless is a separate identity domain. Do not share the Nextcloud admin account.
- Default: dedicated Paperless admin + per-user accounts, or a single shared account behind the VPN
  for small deployments. SSO/OIDC is an optional later milestone, not a requirement.
- Nextcloud admin credentials and Paperless API tokens are generated/collected by `make secrets`
  and never echoed to logs.

## 7. Repository layout (target)

```
.
├── AGENT.md                  # this file — objectives + agent rules
├── Makefile                  # thin, self-documenting entry point
├── make/                     # included fragments: runtime.mk, nextcloud.mk, paperless.mk, ...
├── config/
│   ├── env.example           # documented, secret-free template
│   ├── versions.env          # pinned image tags/digests
│   └── hosts/                # per-host / per-profile settings (no secrets)
├── stacks/
│   ├── nextcloud-aio/        # AIO mastercontainer definition
│   ├── collabora/            # only if the external-Collabora profile is used
│   └── paperless/            # paperless-ngx stack (compose + quadlet variants)
├── quadlet/                  # Podman systemd units (Fedora, boot persistence)
├── compose/                  # Docker/Podman Compose definitions (portable path)
├── scripts/                  # doctor, storage, secrets, smoke, backup, restore, deploy, integration
├── docs/                     # runbooks: install, upgrade, backup/restore, integration, remote hosts
└── tests/                    # smoke + config validation (shell/bats)
```

`DATA_ROOT` is **outside** the repository (default `/srv/mroffice`). The repo contains only code,
config templates and scripts; runtime data is never committed and never lives in the checkout.

The layout is a target, not a mandate: if a different structure serves the objectives better, change
it and update this section. Do not leave two competing ways to deploy the same service.

## 8. The Make interface (contract)

`make help` must list every public target with a one-line description (parsed from `##` comments).
Targets should degrade gracefully: a clear error + `make doctor` hint beats a stack trace.

| Target | Purpose |
| --- | --- |
| `make help` | List targets and current variable values. |
| `make doctor` | Detect runtime (Podman/Docker), versions, ports, DNS/TLS readiness, disk space, SELinux, rootless limits; print actionable fixes. |
| `make init` | Create local config from `config/env.example`, generate secrets, create bind-mount directories under `DATA_ROOT` with correct ownership/permissions. |
| `make config` | Render/validate configuration for the selected profile; fail on missing required values or missing/unwritable data dirs. |
| `make up` | Start the selected stack(s), idempotently, in dependency order. |
| `make down` | Stop containers; keep every bind-mounted host directory untouched. |
| `make restart` | Restart without recreating data. |
| `make ps` / `make status` | Show container + health status for all stacks. |
| `make storage` | Print the authoritative storage map: bind mounts (host → container, mode, owner) and any documented engine-managed locations. |
| `make logs [SERVICE=...]` | Follow logs. |
| `make pull` | Pull pinned images. |
| `make update` | Backup (if configured), pull pinned versions, recreate, run smoke. |
| `make backup` | Nextcloud AIO backup + Paperless export to `BACKUP_TARGET`. |
| `make restore BACKUP=...` | Restore procedure from a named backup; guarded and documented. |
| `make smoke` | End-to-end checks: NC HTTPS 200, Collabora discovery, Paperless API 200, integration probe. |
| `make test` | Config validation + shell lint + integration tests that need no running stack. |
| `make lint` | shellcheck, yamllint, `make -n` dry-runs, secret scan. |
| `make deploy HOST=<ssh-target>` | Deploy/refresh the stack on a remote machine (Podman remote or SSH + systemd). |
| `make paperless-check` | Verify Paperless reachability, token validity, consume path ownership. |
| `make integration-check` | Verify ingest + browse paths end to end. |
| `make clean FORCE=1` | **Destructive.** Remove containers, the selected stack's bind-mounted data under `DATA_ROOT`, and any documented engine-managed storage. Prints the exact paths first. |
| `make dev` | Local development profile (relaxed TLS/domain requirements, debug ports). |

Variables (defaults chosen by `doctor`/profile, overridable per invocation):

```
RUNTIME=podman|docker        # container engine
COMPOSE="podman compose"     # compose provider, only where compose is used
PROFILE=local|single-host|split-host
ENV=dev|prod
HOST=local|<ssh-target>      # for deploy
STACK=all|nextcloud|paperless
DATA_ROOT=/srv/mroffice      # host root for every bind mount (must not be in the repo)
BACKUP_TARGET=...            # path or restic/S3 destination
FORCE=0                      # gates destructive operations
```

Rules for the Makefile:

- Keep it thin: logic lives in `scripts/`, or in included fragments under `make/`.
- Every public target has a `## description` comment.
- No target may require a secret on the command line; read secrets from files/env set by `make init`.
- `make up` and `make deploy` must be safe to re-run.
- Destructive actions print exactly what they will delete and require `FORCE=1`.
- Persistent paths are bind mounts derived from `DATA_ROOT`; no target may create an undeclared named
  volume. Any unavoidable engine-managed storage must be listed by `make storage`.
- New capability ⇒ new target (or a documented extension of an existing one).

## 9. Configuration & secrets

- `.env` is generated and git-ignored. `config/env.example` documents every variable, its default,
  and whether it is required.
- Required inputs at minimum: Nextcloud domain, admin user, TLS mode (AIO Apache vs reverse proxy),
  `DATA_ROOT` and the per-service subdirectories, timezone, Paperless domain/URL, Paperless admin
  user, integration mode.
- `DATA_ROOT` must be an absolute host path outside the repository. `make config` refuses relative
  paths, paths inside the checkout, or paths that resolve outside the expected layout.
- The storage map (host path → container path → mode → owner) lives in one declarative file per
  stack, so `make storage`, `make init` and the compose/Quadlet definitions cannot drift apart.
- Secrets: `NEXTCLOUD_ADMIN_PASSWORD`, `PAPERLESS_ADMIN_PASSWORD`, `PAPERLESS_API_TOKEN`,
  `PAPERLESS_SECRET_KEY`, database passwords, backup credentials.
  - Preferred (Podman): `podman secret` / systemd credentials, referenced by name.
  - Docker: Compose secrets or a root-owned env file with `0600`.
  - Fallback: `config/.secrets.env` with `0600`, git-ignored.
- `make secrets` generates strong random values; it must refuse to overwrite existing secrets without
  an explicit flag. Secrets must never be printed, committed, or baked into images.
- Validate config before starting anything (`make config`).

## 10. Deployment models

### A. Single host, Podman (default for production on Fedora)
- Rootless Podman where AIO allows it; **AIO's mastercontainer needs access to a Docker-compatible
  API socket**. Use the Podman socket (`/run/podman/podman.sock` or rootless equivalent) and record
  the exact caveats found during the M2 spike. If AIO proves incompatible with rootless Podman,
  fall back to rootful Podman systemd units and document why.
- Boot persistence via Quadlet/systemd units (`WantedBy=default.target` or `multi-user.target`).
- All persistent data is bind-mounted from `DATA_ROOT` (except the AIO internals documented in O7)
  with explicit `:Z`/`:z` or `container_file_t` labels; `make doctor` detects SELinux denials and
  ownership mismatches. Rootless mapping must be documented per directory (UID/GID inside the
  container vs on the host).

### B. Single host, Docker
- Compose files under `compose/`, same env contract, same bind-mount layout, same Make targets.
- Compose `volumes:` with a named volume are not allowed for persistent data; use `type: bind`.

### C. Split hosts
- Nextcloud AIO on host A, Paperless on host B (or vice versa).
- Each host has its own `DATA_ROOT` and per-host config under `config/hosts/`.
- `make deploy HOST=...` deploys/refreshes a single host using that config.
- Integration over private network/TLS; independent backup targets; independent upgrade cadence.
- Neither stack may require the other to boot successfully.

### D. Development
- `PROFILE=dev` / `make dev`: local-only, relaxed domain/TLS requirements where the software allows,
  debug ports bound to localhost, disposable bind-mounted dirs under `DATA_ROOT/dev`, fast iteration.
  Dev must never be the default.

## 11. Risks to resolve early (spikes)

| Risk | Why it matters | Mitigation |
| --- | --- | --- |
| AIO + Podman compatibility | AIO is Docker-oriented and drives the container engine via a socket; rootless/rootful differences can break container management. | M2 spike: rootless vs rootful Podman, socket path, SELinux; document supported mode. Fallback: Docker host for AIO. |
| AIO storage cannot be fully bind-mounted | AIO creates and manages some internal storage (mastercontainer config, database) that may not accept host bind mounts; a strict bind-only rule could block AIO. | M2 spike: test `NEXTCLOUD_DATADIR` into `DATA_ROOT` and attempt bind mounts for AIO internals. If impossible, enumerate the engine-managed paths, include them in backups, and treat them as a documented exception — or revisit AIO (see open questions). |
| AIO behind a reverse proxy | AIO expects to own ports 80/443 or a configured `APACHE_PORT`; proxy misconfig breaks WOPI/Talk. | Document a supported proxy profile and test it in `make smoke`. |
| Paperless Nextcloud app maintenance | Unofficial app may lag Nextcloud releases. | Prefer the external-storage bridge as the stable baseline; treat the app as an enhancement. |
| Cross-host WOPI for external Collabora | Collabora must reach Nextcloud and vice versa. | Default to AIO-managed Collabora; external Collabora only with tested DNS/TLS/firewall. |
| Network storage for bind mounts | PostgreSQL and some AIO paths are sensitive to filesystem semantics/permissions; NFS/SMB can corrupt or break them. | Prefer local disks under `DATA_ROOT`; if network storage is required, test restore, lock down ownership, and document constraints per path. |
| Bind-mount ownership/permissions | Rootless containers map UIDs; wrong ownership causes silent write failures and permission errors on the host. | `make init` sets owners explicitly; `make doctor` verifies read/write as the container user; document UID/GID mapping per stack. |
| Backup consistency across hosts | Two independent backups can drift. | Document restore order, run a restore drill, record RPO/RTO. |
| Secret sprawl | Tokens on two machines. | Single `make secrets` flow, rotation runbook, secret scan in `make lint`. |

## 12. Milestones

- **M0 — Skeleton:** `AGENT.md`, `make help`, `make doctor`, layout, lint/test scaffolding.
- **M1 — Paperless alone:** config + stack up locally on Podman and Docker; bind-mounted data dirs under
  `DATA_ROOT`; `make storage` accurate; admin user; smoke.
- **M2 — Nextcloud AIO + Collabora:** domain/TLS, pinned AIO image, bind-mount strategy proven (user data
  host-bound; AIO internals documented), Podman compatibility spike resolved and documented, office
  editing verified in `make smoke`.
- **M3 — Integration:** ingest + browse paths implemented for same-host and cross-host; token handling;
  `make integration-check` green.
- **M4 — Split-host deployment:** per-host config, `make deploy HOST=...`, independent lifecycle.
- **M5 — Operations:** backup/restore drill, update/rollback runbook, health/observability, secret rotation.
- **M6 — Hardening & docs:** firewall guidance, admin UI exposure, rate limits, final runbooks, acceptance
  checklist signed off.

## 13. Definition of done

A change is done when all of the following hold:

1. The behavior is reachable through a documented `make` target (or an existing one is extended).
2. It works on the primary runtime (Podman) and does not break the Docker fallback, or the limitation
   is documented explicitly.
3. `make config`, `make lint`, `make test` pass; `make smoke` passes if services are running.
4. It is idempotent and safe to re-run; destructive behavior is gated by `FORCE=1`.
5. No secrets, hostnames, IPs or personal paths are committed.
6. Persistent state is a declared bind mount under `DATA_ROOT`; no new named volume is introduced.
   Any forced engine-managed storage is listed by `make storage`, backed up and documented.
7. Relevant docs under `docs/` are updated; this file is updated if an objective, constraint or
   interface changed.
8. A short note is added to the change description: what was tested, on which runtime, with which
   versions.

## 14. Working rules for AI agents

- **Start here.** Read this file, then `Makefile`, then `config/env.example`, then the relevant
  `docs/` runbook before editing.
- **Never bypass the Make interface** in docs or tests; if a one-off command is needed, add a target.
- **Do not invent hostnames, domains, IPs, passwords or tokens.** Ask, or use clearly marked
  placeholders in examples.
- **Do not run destructive commands** (`make clean`, host data dir deletion, `podman system prune`,
  database drops) unless the user explicitly requested it.
- **Investigate before deleting.** Unexplained files, host data directories, volumes or config may be
  user data or work in progress.
- **Bind mounts, not volumes.** New persistent paths go under `DATA_ROOT` and must appear in the
  declarative storage map. Do not add a named volume for convenience; if upstream forces one,
  document it and add it to `make storage` and backup.
- **Pin versions.** When adding or bumping an image, update `config/versions.env` (tag + digest) and
  the changelog note; never use `latest`.
- **Respect the runtime abstraction.** No direct `docker`/`podman` calls in scripts; use the helper
  functions/`RUNTIME` variable.
- **Keep secrets out of logs.** Use `set -x` carefully; redact tokens in test output.
- **Prefer small, verifiable steps.** One objective per change; include the command that proves it.
- **Document as you go.** Runbook entries are required for operational behavior, not optional polish.
- **If requirements conflict with this file, stop and ask.** Do not silently change the objectives.

## 15. Open questions (answer before M2/M4)

1. Which host(s) and OS? Is Fedora + rootless Podman the production target, and is rootful acceptable
   for AIO if needed?
2. Domains and DNS: which FQDN for Nextcloud, Collabora (if external) and Paperless? Is a reverse proxy
   already in place (Caddy/Traefik/nginx)?
3. Network between machines: VPN/Tailscale/WireGuard, LAN only, or public endpoints?
4. Is AIO required, or would a plain Nextcloud + Collabora stack be acceptable if AIO proves fragile on
   Podman? (Current objective: AIO.)
5. Identity: standalone accounts, shared account behind VPN, or SSO/OIDC (later)?
6. Expected data size and backup destination (local disk, NAS, S3-compatible, restic repo)?
7. Paperless integration preference: Nextcloud app, external-storage bridge (read-only), consume drop,
   or API push — or a combination?
8. TLS: should AIO terminate TLS itself, or sit behind an existing reverse proxy with certificates?
9. Bind-only storage: where should `DATA_ROOT` live (separate disk, mount point, size)? Is a
   documented exception acceptable for AIO's unavoidable internal storage, or is AIO rejected if it
   cannot be 100% host-bound?
