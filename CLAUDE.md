# CLAUDE.md

This file provides context to Claude Code and AI agents working in this repository.

## What this repo is

A managed fork of [`Mintplex-Labs/anything-llm`](https://github.com/Mintplex-Labs/anything-llm) maintained by Dreamware.
Upstream changes are merged weekly via an automated PR. Custom Dreamware code is kept additive and clearly marked.

## Remotes

```bash
origin    git@github.com:Trapu20/dreamware-anything-llm.git   # our fork
upstream  https://github.com/Mintplex-Labs/anything-llm.git   # upstream (push disabled)
```

## Branch Strategy

| Branch | Purpose | Deploys to |
|--------|---------|-----------|
| `main` | Production-ready code | `app.dreamware.at` (manual approval required) |
| `develop` | Integration branch | `test.dreamware.at` (automatic) |
| `feature/*` | New features | — (PR into `develop`) |
| `upstream-sync/*` | Weekly upstream merge | — (PR into `develop`) |

**Never push directly to `main` or `develop`** — always use PRs.

## Servers

| | Test | Production |
|---|---|---|
| Domain | `test.dreamware.at` | `app.dreamware.at` |
| IP | `46.224.83.46` | `116.203.122.202` |
| Hetzner type | CX22 | CX32 |
| Compose path | `/opt/dreamanything/test/` | `/opt/dreamanything/production/` |
| Storage | `/data/dreamanything/test/storage` | `/data/dreamanything/production/storage` |
| Reverse proxy | Caddy (auto TLS) | Caddy (auto TLS) |

## CI/CD Workflows

| File | Trigger | What it does |
|------|---------|-------------|
| `_docker-build-push.yml` | (reusable) | Builds image, pushes to `ghcr.io/trapu20/dreamware-anything-llm` |
| `deploy-test.yml` | push to `develop` | Build `:develop` image → SSH deploy to test server |
| `deploy-production.yml` | push to `main` | Build `:latest` image → manual approval → SSH deploy to prod |
| `promote-to-production.yml` | manual | Fast-forward `main` to `develop`, waits for prod deploy, optionally syncs settings |
| `sync-settings.yml` | manual / callable | Sync `system_settings` table from test → prod SQLite DB |
| `upstream-sync.yml` | Monday 08:00 UTC + manual | Opens a PR merging `upstream/master` into `develop` |

## Custom Code Convention

All Dreamware-specific changes must be kept **additive** where possible (new files over in-place edits).
When upstream files must be modified, wrap changes with markers:

```js
// ===== DREAMWARE CUSTOM BEGIN =====
// ... custom code ...
// ===== DREAMWARE CUSTOM END =====
```

All deviations from upstream are tracked in `.github/CUSTOM_FILES.md` — **keep it up to date**.

## Upstream Sync Process

When a `upstream-sync/*` PR opens:
1. Review the diff — look for breaking changes to APIs, DB schema, env vars
2. If there are conflict markers, resolve them manually: keep `DREAMWARE CUSTOM` blocks, apply upstream logic around them
3. Merge into `develop` → test → then promote to `main`

```bash
# To resolve conflicts locally:
git fetch origin && git checkout upstream-sync/YYYY-MM-DD-42
# resolve conflicts, keep DREAMWARE CUSTOM blocks
git add . && git commit --amend --no-edit
git push --force-with-lease origin upstream-sync/YYYY-MM-DD-42
```

## Infrastructure Setup

To bootstrap a new server from scratch:

```bash
# On the Hetzner server (Ubuntu 22.04):
curl -fsSL https://raw.githubusercontent.com/Trapu20/dreamware-anything-llm/develop/infra/bootstrap.sh | ENV=test bash
# or ENV=production

# Then manually download compose + Caddyfile:
curl -fsSL https://raw.githubusercontent.com/Trapu20/dreamware-anything-llm/develop/infra/docker-compose.test.yml \
  -o /opt/dreamanything/test/docker-compose.yml
curl -fsSL https://raw.githubusercontent.com/Trapu20/dreamware-anything-llm/develop/infra/Caddyfile.test \
  -o /opt/dreamanything/test/Caddyfile
```

**Known gotcha:** storage directory must be owned by UID 1000 (container user `anythingllm`):
```bash
chown -R 1000:1000 /data/dreamanything/{env}/storage
```

## GitHub Secrets Required

| Secret | Scope | Purpose |
|--------|-------|---------|
| `GH_PAT` | Repo | Fine-grained PAT — create upstream-sync PRs |
| `GHCR_TOKEN` | Repo | Classic PAT `write:packages` — push Docker images |
| `HETZNER_SSH_USER` | Repo | SSH user on Hetzner (`root`) |
| `HETZNER_TEST_HOST` | Environment: test | Test server IP |
| `HETZNER_TEST_SSH_KEY` | Environment: test | Private SSH key for test server |
| `HETZNER_PROD_HOST` | Environment: production | Production server IP |
| `HETZNER_PROD_SSH_KEY` | Environment: production | Private SSH key for production server |

## Key Files

```
.github/
├── workflows/
│   ├── _docker-build-push.yml      # reusable Docker build/push
│   ├── upstream-sync.yml           # weekly upstream sync
│   ├── deploy-test.yml             # develop → test server
│   ├── deploy-production.yml       # main → prod server (approval gate)
│   ├── promote-to-production.yml   # manual: ff main→develop + optional settings sync
│   └── sync-settings.yml           # manual/callable: sync system_settings test→prod
└── CUSTOM_FILES.md                 # living list of all Dreamware deviations
infra/
├── docker-compose.test.yml         # test server stack
├── docker-compose.production.yml   # production server stack
├── Caddyfile.test                  # Caddy config for test.dreamware.at
├── Caddyfile.production            # Caddy config for app.dreamware.at
├── bootstrap.sh                    # one-time server setup
└── sync-settings.sh                # export/import/diff system_settings helper
docker/
└── .env.dreamware.example          # env vars template (never commit .env)
```
