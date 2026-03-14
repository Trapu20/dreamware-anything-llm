#!/usr/bin/env bash
# =============================================================================
# bootstrap.sh — One-time server setup for Dreamware AnythingLLM
# Run as root on a fresh Ubuntu 22.04 Hetzner server.
#
# Usage:
#   ENV=test  bash bootstrap.sh    # for test server
#   ENV=production bash bootstrap.sh  # for production server
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
mkdir -p "/opt/dreamanything/$ENV/nginx/certs"
mkdir -p "/data/dreamanything/$ENV/storage"

# ── Firewall ──────────────────────────────────────────────────────────────────
echo "==> Configuring UFW firewall..."
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
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
  echo "  Add this PRIVATE key as a GitHub Secret:"
  echo "  Secret name: HETZNER_${ENV^^}_SSH_KEY"
  echo "======================================================================="
  cat "$KEY_PATH"
  echo "======================================================================="
else
  echo "  Deploy key already exists at $KEY_PATH — skipping."
fi

# ── Copy compose file ─────────────────────────────────────────────────────────
COMPOSE_SRC="$(dirname "$0")/docker-compose.$ENV.yml"
COMPOSE_DEST="/opt/dreamanything/$ENV/docker-compose.yml"
if [[ -f "$COMPOSE_SRC" ]]; then
  cp "$COMPOSE_SRC" "$COMPOSE_DEST"
  echo "==> Copied docker-compose.$ENV.yml → $COMPOSE_DEST"
else
  echo "  WARNING: $COMPOSE_SRC not found. Copy it manually to $COMPOSE_DEST"
fi

# ── Copy nginx config ─────────────────────────────────────────────────────────
NGINX_SRC="$(dirname "$0")/nginx/nginx.conf"
NGINX_DEST="/opt/dreamanything/$ENV/nginx/nginx.conf"
if [[ -f "$NGINX_SRC" ]]; then
  cp "$NGINX_SRC" "$NGINX_DEST"
  echo "==> Copied nginx.conf → $NGINX_DEST"
fi

echo ""
echo "======================================================================="
echo "  Bootstrap complete for ENV=$ENV"
echo ""
echo "  Next steps:"
echo "  1. Copy .env.dreamware.example → /opt/dreamanything/$ENV/.env"
echo "     and fill in all values (JWT_SECRET, API keys, etc.)"
echo "  2. Add TLS certs to /opt/dreamanything/$ENV/nginx/certs/"
echo "     (use certbot or copy existing certs)"
echo "  3. Log in to GHCR on this server:"
echo "     echo \$GHCR_TOKEN | docker login ghcr.io -u YOUR_ORG --password-stdin"
echo "  4. Add GitHub Secrets (see output above for SSH key)"
echo "======================================================================="
