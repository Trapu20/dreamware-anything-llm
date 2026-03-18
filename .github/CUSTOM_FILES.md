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
| `.github/copilot-instructions.md` | GitHub Copilot agent instructions (tech stack, conventions, PR checklist) | 2026-03-18 |
| `.github/CODEOWNERS` | Automatic PR review routing for Dreamware-owned files | 2026-03-18 |
| `.github/dependabot.yml` | Automated dependency update configuration | 2026-03-18 |
| `.github/agents/code-reviewer.agent.md` | GitHub Copilot custom agent: expert code reviewer | 2026-03-18 |
| `.github/agents/frontend-developer.agent.md` | GitHub Copilot custom agent: React/Vite frontend developer | 2026-03-18 |
| `.github/agents/backend-architect.agent.md` | GitHub Copilot custom agent: Node.js/Express backend architect | 2026-03-18 |
| `.github/agents/security-engineer.agent.md` | GitHub Copilot custom agent: application security engineer | 2026-03-18 |
| `.github/agents/devops-automator.agent.md` | GitHub Copilot custom agent: CI/CD and infrastructure automation | 2026-03-18 |
| `.github/agents/technical-writer.agent.md` | GitHub Copilot custom agent: developer documentation writer | 2026-03-18 |
| `.github/agents/git-workflow-master.agent.md` | GitHub Copilot custom agent: Git branching and workflow expert | 2026-03-18 |
| `.github/agents/database-optimizer.agent.md` | GitHub Copilot custom agent: Prisma/PostgreSQL database optimizer | 2026-03-18 |
| `.github/agents/software-architect.agent.md` | GitHub Copilot custom agent: software architecture and system design | 2026-03-18 |
| `.github/agents/api-tester.agent.md` | GitHub Copilot custom agent: API testing and validation | 2026-03-18 |
| `.github/agents/accessibility-auditor.agent.md` | GitHub Copilot custom agent: WCAG accessibility auditor | 2026-03-18 |
| `.github/agents/performance-benchmarker.agent.md` | GitHub Copilot custom agent: performance testing and optimization | 2026-03-18 |
| `docker/.env.dreamware.example` | Dreamware-specific env vars documented | 2026-03-14 |
| `infra/docker-compose.test.yml` | Docker Compose for test server (Caddy + app) | 2026-03-14 |
| `infra/docker-compose.production.yml` | Docker Compose for production server (Caddy + app) | 2026-03-14 |
| `infra/Caddyfile.test` | Caddy reverse proxy config for test.dreamware.at | 2026-03-14 |
| `infra/Caddyfile.production` | Caddy reverse proxy config for app.dreamware.at | 2026-03-14 |
| `infra/bootstrap.sh` | One-time server bootstrap script | 2026-03-14 |
| `.github/workflows/promote-to-production.yml` | Manual workflow to fast-forward main to develop, triggering prod deploy | 2026-03-18 |
| `.github/workflows/sync-settings.yml` | Sync AnythingLLM system_settings from test → prod via SSH/sqlite3 | 2026-03-18 |
| `infra/sync-settings.sh` | Helper script: export/import/diff system_settings in a running container | 2026-03-18 |

## Modified Files (upstream files with Dreamware changes)

| File | What changed | Modified |
|------|-------------|----------|
| `.github/workflows/deploy-production.yml` | Added post-deploy drift reminder (DREAMWARE CUSTOM block) | 2026-03-18 |

---

## Conflict-Resolution Notes

When an upstream sync PR shows conflicts in modified files:

1. Check if the conflict is inside a `DREAMWARE CUSTOM` block — if so, keep our version.
2. If upstream changed the surrounding code, merge carefully: apply upstream logic first, then re-apply the custom block.
3. Update this document if the conflict revealed a better way to keep changes additive.
