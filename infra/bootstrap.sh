#!/usr/bin/env bash
# =============================================================================
# bootstrap.sh — One-time server setup for Dreamware AnythingLLM
# Run as root on a fresh Ubuntu 22.04 Hetzner server.
#
# Usage:
#   ENV=test  bash bootstrap.sh
#   ENV=production bash bootstrap.sh
# =============================================================================
set -euo pipefail

ENV="${ENV:-test}"

if [[ "$ENV" != "test" && "$ENV" != "production" ]]; then
  echo "ERROR: ENV must be 'test' or 'production'"
  exit 1
fi

echo "==> Bootstrapping $ENV server..."

# ── Docker ────────────────────────────────────────────────────────────────────
echo "==> Installing Docker..."
if ! command -v docker &>/dev/null; then
  curl -fsSL https://get.docker.com | sh
  apt-get install -y docker-compose-plugin
  systemctl enable --now docker
else
  echo "  Docker already installed — skipping."
fi

# ── Directory structure ───────────────────────────────────────────────────────
echo "==> Creating directories..."
mkdir -p "/opt/dreamanything/$ENV"
mkdir -p "/data/dreamanything/$ENV/storage"

# ── Firewall ──────────────────────────────────────────────────────────────────
echo "==> Configuring UFW firewall..."
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 443/udp   # HTTP/3 (QUIC) for Caddy
ufw --force enable

# ── Deploy SSH key ─────────────────────────────────────────────────────────────
KEY_PATH="$HOME/.ssh/github_actions_deploy"
if [[ ! -f "$KEY_PATH" ]]; then
  echo "==> Generating deploy SSH key..."
  ssh-keygen -t ed25519 -f "$KEY_PATH" -N "" -C "github-actions-deploy-$ENV"
  cat "$KEY_PATH.pub" >> "$HOME/.ssh/authorized_keys"
  chmod 600 "$HOME/.ssh/authorized_keys"
  echo ""
  echo "======================================================================="
  echo "  Add this PRIVATE key as GitHub Secret: HETZNER_${ENV^^}_SSH_KEY"
  echo "======================================================================="
  cat "$KEY_PATH"
  echo "======================================================================="
else
  echo "  Deploy key already exists at $KEY_PATH — skipping."
  echo ""
  echo "  Existing public key (already in authorized_keys):"
  cat "$KEY_PATH.pub"
fi

# ── Copy compose + Caddyfile ──────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

COMPOSE_SRC="$SCRIPT_DIR/docker-compose.$ENV.yml"
COMPOSE_DEST="/opt/dreamanything/$ENV/docker-compose.yml"
if [[ -f "$COMPOSE_SRC" ]]; then
  cp "$COMPOSE_SRC" "$COMPOSE_DEST"
  echo "==> Copied docker-compose.$ENV.yml → $COMPOSE_DEST"
else
  echo "  WARNING: $COMPOSE_SRC not found. Copy manually to $COMPOSE_DEST"
fi

CADDY_SRC="$SCRIPT_DIR/Caddyfile.$ENV"
CADDY_DEST="/opt/dreamanything/$ENV/Caddyfile"
if [[ -f "$CADDY_SRC" ]]; then
  cp "$CADDY_SRC" "$CADDY_DEST"
  echo "==> Copied Caddyfile.$ENV → $CADDY_DEST"
else
  echo "  WARNING: $CADDY_SRC not found. Copy manually to $CADDY_DEST"
fi

echo ""
echo "======================================================================="
echo "  Bootstrap complete for ENV=$ENV"
echo ""
echo "  Next steps:"
echo "  1. Create /opt/dreamanything/$ENV/.env"
echo "     (copy docker/.env.dreamware.example from the repo and fill in values)"
echo "  2. Log in to GHCR:"
echo "     echo \$GHCR_TOKEN | docker login ghcr.io -u trapu20 --password-stdin"
echo "  3. Add GitHub Secrets (SSH key printed above)"
echo "  4. Start the stack:"
echo "     cd /opt/dreamanything/$ENV && docker compose up -d"
echo "======================================================================="
# storage permissions: chown -R 1000:1000 /data/dreamanything/{env}/storage
