# GitHub Copilot Instructions

> These instructions apply to every Copilot coding-agent session in this repository.
> Keep them up-to-date whenever conventions change.

## Project Identity

This is **dreamware-anything-llm** — a managed fork of
[Mintplex-Labs/anything-llm](https://github.com/Mintplex-Labs/anything-llm) maintained by
**Dreamware** (deployed at `test.dreamware.at` / `app.dreamware.at`).

Upstream changes are merged weekly via an automated PR. All Dreamware-specific code is kept
**additive** and clearly marked so upstream merges stay clean.

---

## Repository Layout

```
frontend/      React + Vite SPA (port 3000)
server/        Express API server (port 3001) + Prisma ORM
collector/     Document-processing worker
embed/         Embeddable chat widget
docker/        Docker build context and .env templates
infra/         Compose stacks, Caddyfiles, bootstrap scripts
.devcontainer/ VS Code / Codespaces dev-container definition
.github/       Workflows, templates, and this file
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | React 18, Vite, Tailwind CSS, JavaScript (JSX) |
| Backend | Node 18, Express, Prisma, SQLite (dev) / PostgreSQL (prod) |
| Collector | Node 18, Express, Puppeteer |
| Package manager | **Yarn** everywhere (no npm, no pnpm) |
| Linter | ESLint flat config (`eslint.config.{js,mjs}` in each package) |
| Formatter | Prettier (`.prettierrc` in repo root) |
| Containerisation | Docker; multi-stage `docker/Dockerfile` |
| CI/CD | GitHub Actions (`.github/workflows/`) |
| Reverse proxy | Caddy (TLS auto-managed) |

---

## Branch Strategy

| Branch | Purpose | Deploy |
|--------|---------|--------|
| `main` | Production-ready | `app.dreamware.at` (manual approval) |
| `develop` | Integration | `test.dreamware.at` (auto) |
| `feature/*` | New features | PR → `develop` |
| `upstream-sync/*` | Weekly merge from upstream | PR → `develop` |

**Never push directly to `main` or `develop`.** Always use a PR.

---

## Custom-Code Convention (IMPORTANT)

All Dreamware-specific changes to upstream files **must** be wrapped with markers:

```js
// ===== DREAMWARE CUSTOM BEGIN =====
// ... your code here ...
// ===== DREAMWARE CUSTOM END =====
```

New files that don't exist upstream should be added instead of modifying upstream files
wherever possible.

Every new or modified file must be recorded in **`.github/CUSTOM_FILES.md`**.

---

## Development Workflow

### Bootstrap (first time)

```bash
yarn setup           # install deps, copy .env files, run prisma:setup
```

### Run locally (three terminals)

```bash
yarn dev:server      # Express API → http://localhost:3001
yarn dev:collector   # Collector  → http://localhost:8888
yarn dev:frontend    # Vite SPA   → http://localhost:3000
# or all at once:
yarn dev:all
```

### Lint

```bash
yarn lint            # auto-fix
yarn lint:ci         # check only (used in CI)
```

### Tests

```bash
yarn test            # Jest (server + collector)
```

### Prisma

```bash
yarn prisma:generate   # re-generate client after schema changes
yarn prisma:setup      # migrate + seed (dev)
```

---

## Coding Conventions

- **JavaScript only** — no TypeScript. JSDoc comments for public APIs.
- **ESM** (`"type": "module"`) in server, collector and root; CommonJS in some legacy helpers.
- Import order: external packages first, then internal modules, then relative paths.
- Prefer `async/await` over raw Promises or callbacks.
- Keep functions small and single-purpose.
- Do **not** add `console.log` in production paths; use the existing `winston` logger in
  `server/utils/logger.js`.
- Wrap ALL Dreamware-specific changes in the `DREAMWARE CUSTOM` markers described above.
- Run `yarn lint` from the repo root and commit the result before opening a PR.

---

## Testing Guidelines

- Tests live in `server/utils/__tests__/` and `collector/__tests__/`.
- Test file naming: `<module>.test.js`.
- Use **Jest** with the existing configuration in the root `package.json`.
- Test new behaviour; don't delete or comment out existing tests.

---

## Environment Variables

| File | Purpose |
|------|---------|
| `server/.env.example` | Backend variables |
| `collector/.env.example` | Collector variables |
| `frontend/.env.example` | Frontend variables (VITE_*) |
| `docker/.env.example` | Docker Compose overrides |
| `docker/.env.dreamware.example` | Dreamware-specific additions |

Copy examples with `yarn setup:envs`. **Never commit `.env` files.**

---

## PR Checklist for Agents

Before opening a pull request, verify:

1. `yarn lint` passes with no errors.
2. `yarn test` passes.
3. All new/modified upstream files are tracked in `.github/CUSTOM_FILES.md`.
4. Dreamware-specific blocks are wrapped in `DREAMWARE CUSTOM` markers.
5. No `.env` files or secrets are included in the diff.
6. Docker build succeeds: `docker build -f docker/Dockerfile .`

---

## Upstream Sync

When an `upstream-sync/*` PR opens:

1. Review the diff for breaking API, DB-schema, or env-var changes.
2. Resolve conflicts: keep `DREAMWARE CUSTOM` blocks, apply upstream logic around them.
3. Merge into `develop` → smoke-test → promote to `main`.

```bash
git fetch origin
git checkout upstream-sync/YYYY-MM-DD-42
# resolve conflicts, keeping DREAMWARE CUSTOM blocks
git add .
git commit --amend --no-edit
git push --force-with-lease
```

---

## Security

- Vulnerability reports: see `SECURITY.md`.
- Secrets are stored in GitHub repository/environment secrets — never hardcoded.
- Required secrets: `GH_PAT`, `GHCR_TOKEN`, `HETZNER_SSH_USER`,
  `HETZNER_TEST_HOST`, `HETZNER_TEST_SSH_KEY`, `HETZNER_PROD_HOST`, `HETZNER_PROD_SSH_KEY`.
