# Makefile — Dreamware AnythingLLM local development
#
# Usage:
#   make setup    First-time setup (copy envs, install deps, Prisma)
#   make dev      Start support stack + run yarn dev:all
#   make up       Start Docker support stack only
#   make down     Stop Docker support stack
#   make status   Show running services
#   make logs     Tail Docker service logs
#   make seed-mcp Seed RIS MCP config (idempotent)
#   make reset-db Truncate SQLite + re-run Prisma migrate
#   make clean    Stop containers + remove local DB/vector-store

COMPOSE_FILE := infra/docker-compose.dev.yml
STORAGE_DIR  := server/storage
RIS_MCP_URL  := http://localhost:3100/mcp

.PHONY: help setup up down dev seed-mcp logs status reset-db clean

# Default target
help:
	@echo ""
	@echo "  Dreamware AnythingLLM — local dev commands"
	@echo ""
	@echo "  make setup      First-time setup: copy envs, install deps, run Prisma"
	@echo "  make dev        Start support stack + all dev servers (foreground)"
	@echo "  make up         Start Docker support stack (RIS MCP sidecar) in background"
	@echo "  make down       Stop and remove Docker support stack containers"
	@echo "  make seed-mcp   Seed RIS MCP URL into AnythingLLM config (idempotent)"
	@echo "  make logs       Tail Docker support stack logs"
	@echo "  make status     Show Docker container status and port availability"
	@echo "  make reset-db   Truncate SQLite + re-run Prisma migrations"
	@echo "  make clean      Stop containers + delete local DB and vector store"
	@echo ""

# ---------------------------------------------------------------------------
# First-time setup
# ---------------------------------------------------------------------------
setup:
	@echo "==> Copying .env files (skipping existing)..."
	@cp -n frontend/.env.example frontend/.env 2>/dev/null && echo "    Created frontend/.env" || echo "    frontend/.env already exists — skipped"
	@cp -n server/.env.example server/.env.development 2>/dev/null && echo "    Created server/.env.development" || echo "    server/.env.development already exists — skipped"
	@cp -n collector/.env.example collector/.env 2>/dev/null && echo "    Created collector/.env" || echo "    collector/.env already exists — skipped"
	@cp -n docker/.env.example docker/.env 2>/dev/null && echo "    Created docker/.env" || echo "    docker/.env already exists — skipped"
	@echo "==> Installing dependencies..."
	@cd server && yarn --frozen-lockfile
	@cd collector && yarn --frozen-lockfile
	@cd frontend && yarn --frozen-lockfile
	@echo "==> Running Prisma generate + migrate + seed..."
	@yarn prisma:setup
	@echo ""
	@echo "  Setup complete. Run 'make dev' to start the development environment."
	@echo ""

# ---------------------------------------------------------------------------
# Docker support stack (RIS MCP sidecar)
# ---------------------------------------------------------------------------
up:
	@echo "==> Starting Docker support stack..."
	@docker compose -f $(COMPOSE_FILE) up -d --build
	@echo "    RIS MCP sidecar starting on http://localhost:3100"

down:
	@echo "==> Stopping Docker support stack..."
	@docker compose -f $(COMPOSE_FILE) down

logs:
	@docker compose -f $(COMPOSE_FILE) logs -f

status:
	@echo "==> Docker containers:"
	@docker compose -f $(COMPOSE_FILE) ps 2>/dev/null || echo "    (none running)"
	@echo ""
	@echo "==> Port status:"
	@curl -sf http://localhost:3100/health >/dev/null 2>&1 \
	  && echo "    :3100  RIS MCP   UP" \
	  || echo "    :3100  RIS MCP   DOWN"
	@curl -sf http://localhost:3001/api/ping >/dev/null 2>&1 \
	  && echo "    :3001  Server    UP" \
	  || echo "    :3001  Server    DOWN"
	@curl -sf http://localhost:3001 >/dev/null 2>&1 \
	  || curl -sf http://localhost:5173 >/dev/null 2>&1 \
	  && echo "    :5173  Frontend  UP" \
	  || echo "    :5173  Frontend  DOWN"
	@curl -sf http://localhost:3005 >/dev/null 2>&1 \
	  && echo "    :3005  Collector UP" \
	  || echo "    :3005  Collector DOWN"

# ---------------------------------------------------------------------------
# MCP config seeding
# ---------------------------------------------------------------------------
seed-mcp:
	@echo "==> Seeding RIS MCP config..."
	@CONFIG=$(STORAGE_DIR)/plugins/anythingllm_mcp_servers.json; \
	if [ -f "$$CONFIG" ] && command -v jq &>/dev/null; then \
	  CURRENT=$$(jq -r '.mcpServers.ris.url // ""' "$$CONFIG" 2>/dev/null); \
	  if [ "$$CURRENT" != "" ] && [ "$$CURRENT" != "$(RIS_MCP_URL)" ]; then \
	    echo "    Updating RIS MCP URL: $$CURRENT -> $(RIS_MCP_URL)"; \
	    jq --arg url "$(RIS_MCP_URL)" '.mcpServers.ris.url = $$url' "$$CONFIG" > "$$CONFIG.tmp" && mv "$$CONFIG.tmp" "$$CONFIG"; \
	    exit 0; \
	  fi; \
	fi; \
	RIS_MCP_URL=$(RIS_MCP_URL) bash infra/seed-mcp-config.sh $(STORAGE_DIR)

# ---------------------------------------------------------------------------
# Main dev target
# ---------------------------------------------------------------------------
dev: up
	@echo "==> Waiting for RIS MCP sidecar to become healthy (up to 30s)..."
	@for i in $$(seq 1 30); do \
	  curl -sf http://localhost:3100/health >/dev/null 2>&1 && echo "    Sidecar ready." && break; \
	  [ $$i -eq 30 ] && echo "    Warning: sidecar did not become healthy in 30s — continuing anyway."; \
	  sleep 1; \
	done
	@$(MAKE) seed-mcp
	@echo ""
	@echo "  Starting dev servers:"
	@echo "    Server    → http://localhost:3001"
	@echo "    Frontend  → http://localhost:5173"
	@echo "    Collector → http://localhost:3005"
	@echo "    RIS MCP   → http://localhost:3100"
	@echo ""
	yarn dev:all

# ---------------------------------------------------------------------------
# Database management
# ---------------------------------------------------------------------------
reset-db:
	@echo "==> Resetting SQLite database..."
	yarn prisma:reset

# ---------------------------------------------------------------------------
# Clean up local state
# ---------------------------------------------------------------------------
clean: down
	@printf "This will delete %s/anythingllm.db and %s/lancedb. Continue? [y/N] " $(STORAGE_DIR) $(STORAGE_DIR); \
	read ans; \
	case "$$ans" in \
	  [yY]*) \
	    rm -f $(STORAGE_DIR)/anythingllm.db; \
	    rm -rf $(STORAGE_DIR)/lancedb; \
	    echo "    Removed local DB and vector store."; \
	    ;; \
	  *) echo "    Aborted."; ;; \
	esac
