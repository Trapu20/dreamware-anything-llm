#!/usr/bin/env bash
# seed-mcp-config.sh — Add the RIS MCP server to AnythingLLM's MCP config.
#
# Usage:
#   ./seed-mcp-config.sh [STORAGE_DIR]
#
# Examples:
#   ./seed-mcp-config.sh /data/dreamanything/test/storage
#   ./seed-mcp-config.sh /data/dreamanything/production/storage
#
# This script is idempotent: if the "ris" key already exists in the config
# it will print a message and exit without changes.

set -euo pipefail

STORAGE_DIR="${1:?Usage: $0 <STORAGE_DIR>}"
CONFIG_DIR="${STORAGE_DIR}/plugins"
CONFIG_FILE="${CONFIG_DIR}/anythingllm_mcp_servers.json"

RIS_MCP_URL="${RIS_MCP_URL:-http://ris-mcp:3000/mcp}"

echo "==> Seeding MCP config at ${CONFIG_FILE}"

# Ensure the plugins directory exists
mkdir -p "${CONFIG_DIR}"

# Create the config file if it doesn't exist
if [ ! -f "${CONFIG_FILE}" ]; then
  echo '{"mcpServers":{}}' > "${CONFIG_FILE}"
  echo "    Created new config file"
fi

# Check if jq is available (preferred) or fall back to node
if command -v jq &>/dev/null; then
  # Check if "ris" key already exists
  if jq -e '.mcpServers.ris' "${CONFIG_FILE}" &>/dev/null; then
    echo "    RIS MCP server already configured — skipping."
    exit 0
  fi

  # Merge the RIS server definition into the existing config
  jq --arg url "${RIS_MCP_URL}" \
    '.mcpServers.ris = {
      "url": $url,
      "type": "streamable",
      "anythingllm": {
        "autoStart": true
      }
    }' "${CONFIG_FILE}" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "${CONFIG_FILE}"

elif command -v node &>/dev/null; then
  CONFIG_FILE="${CONFIG_FILE}" RIS_MCP_URL="${RIS_MCP_URL}" node -e "
    const fs = require('fs');
    const configFile = process.env.CONFIG_FILE;
    const risMcpUrl = process.env.RIS_MCP_URL;
    const cfg = JSON.parse(fs.readFileSync(configFile, 'utf8'));
    if (cfg.mcpServers && cfg.mcpServers.ris) {
      console.log('    RIS MCP server already configured — skipping.');
      process.exit(0);
    }
    cfg.mcpServers = cfg.mcpServers || {};
    cfg.mcpServers.ris = {
      url: risMcpUrl,
      type: 'streamable',
      anythingllm: { autoStart: true }
    };
    fs.writeFileSync(configFile, JSON.stringify(cfg, null, 2));
    console.log('    Added RIS MCP server to config.');
  "
else
  echo "ERROR: Neither jq nor node found. Install jq (apt-get install jq) or node to seed MCP config." >&2
  exit 1
fi

echo "==> Done. RIS MCP configured at ${RIS_MCP_URL}"
