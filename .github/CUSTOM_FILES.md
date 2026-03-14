# CUSTOM_FILES.md — Living Document

This file tracks every deviation from upstream `Mintplex-Labs/anything-llm`.
Update this document whenever you add, modify, or remove a custom file.

## Convention

All custom changes must be marked in-file where possible:

```js
// ===== DREAMWARE CUSTOM BEGIN =====
// ... custom code ...
// ===== DREAMWARE CUSTOM END =====
```

New files that don't exist upstream are listed under **Added Files**.
Upstream files with modifications are listed under **Modified Files**.

---

## Added Files (not in upstream)

| File | Purpose | Added |
|------|---------|-------|
| `.github/workflows/_docker-build-push.yml` | Reusable Docker build/push workflow | 2026-03-14 |
| `.github/workflows/upstream-sync.yml` | Weekly upstream sync PR automation | 2026-03-14 |
| `.github/workflows/deploy-test.yml` | Auto-deploy develop branch → test server | 2026-03-14 |
| `.github/workflows/deploy-production.yml` | Manual-approval deploy main → prod server | 2026-03-14 |
| `.github/CUSTOM_FILES.md` | This file | 2026-03-14 |
| `docker/.env.dreamware.example` | Dreamware-specific env vars documented | 2026-03-14 |
| `infra/docker-compose.test.yml` | Docker Compose for test server (Caddy + app) | 2026-03-14 |
| `infra/docker-compose.production.yml` | Docker Compose for production server (Caddy + app) | 2026-03-14 |
| `infra/Caddyfile.test` | Caddy reverse proxy config for test.dreamware.at | 2026-03-14 |
| `infra/Caddyfile.production` | Caddy reverse proxy config for app.dreamware.at | 2026-03-14 |
| `infra/bootstrap.sh` | One-time server bootstrap script | 2026-03-14 |

## Modified Files (upstream files with Dreamware changes)

| File | What changed | Modified |
|------|-------------|----------|
| _(none yet)_ | | |

---

## Conflict-Resolution Notes

When an upstream sync PR shows conflicts in modified files:

1. Check if the conflict is inside a `DREAMWARE CUSTOM` block — if so, keep our version.
2. If upstream changed the surrounding code, merge carefully: apply upstream logic first, then re-apply the custom block.
3. Update this document if the conflict revealed a better way to keep changes additive.
