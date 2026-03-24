# RIS MCP Server Integration

> **Austrian Legal Information System (Rechtsinformationssystem)** — Access Austria's
> official legal database through AnythingLLM agents via MCP (Model Context Protocol).

This integration runs the [ris-mcp-ts](https://github.com/philrox/ris-mcp-ts)
MCP server as a sidecar container alongside AnythingLLM, connected via
Streamable HTTP transport over the Docker internal network.

## What It Does

Once configured, your AnythingLLM agents can:

- Search Austrian federal laws (ABGB, StGB, UGB, …)
- Search state/provincial laws for all 9 provinces
- Find court decisions from 11 court types
- Browse Federal and State Law Gazettes
- Retrieve full legal document texts by ID
- Track document change history

**No API key required** — uses Austria's open government data API.

## Architecture

```
┌─────────────────────┐      Streamable HTTP       ┌─────────────────────┐
│   AnythingLLM App   │ ──── http://ris-mcp:3000 ──│  RIS MCP Sidecar    │
│   (port 3001)       │           /mcp              │  (node:20-slim)     │
└─────────────────────┘                             └─────────────────────┘
         │                                                    │
         │  ← Caddy reverse proxy                            │  → data.bka.gv.at
         │                                                    │    (RIS OGD API)
    ┌─────────┐
    │  Caddy  │ ← HTTPS (443)
    └─────────┘
```

Both containers share a Docker network. The RIS MCP sidecar is **not exposed**
to the public internet — only AnythingLLM can reach it.

## Quick Start

### 1. Deploy the sidecar (already in docker-compose)

The `ris-mcp` service is included in both `docker-compose.test.yml` and
`docker-compose.production.yml`. The image is built in CI and pushed to GHCR
(`ghcr.io/trapu20/dreamware-anything-llm:ris-mcp`). When you deploy, it is
pulled and started automatically alongside the main app.

### 2. Configure AnythingLLM to connect

**Option A — Seed script (recommended for first setup):**

```bash
# On the server, install jq if not present
apt-get install -y jq

# Run the seed script
curl -fsSL https://raw.githubusercontent.com/Trapu20/dreamware-anything-llm/develop/infra/seed-mcp-config.sh | \
  bash -s /data/dreamanything/test/storage
```

This creates or updates `storage/plugins/anythingllm_mcp_servers.json` with:

```json
{
  "mcpServers": {
    "ris": {
      "url": "http://ris-mcp:3000/mcp",
      "type": "streamable",
      "anythingllm": {
        "autoStart": true
      }
    }
  }
}
```

**Option B — Admin Panel UI:**

1. Log in as admin at `https://test.dreamware.at`
2. Go to **Settings → Agents → MCP Servers**
3. Add a new server with:
   - **Name:** `ris`
   - **URL:** `http://ris-mcp:3000/mcp`
   - **Type:** `streamable`
4. Enable auto-start

### 3. Restart AnythingLLM (or reload MCP servers)

```bash
# Either restart the whole stack:
cd /opt/dreamanything/test
docker compose up -d --build

# Or reload MCP servers from the admin panel (Settings → Agents → MCP Servers → Refresh)
```

### 4. Verify

Check the RIS MCP sidecar health:

```bash
docker compose exec ris-mcp node -e "fetch('http://localhost:3000/health').then(r=>r.json()).then(console.log)"
```

Expected output:
```json
{"status":"ok","service":"ris-mcp","activeSessions":0}
```

In AnythingLLM, go to **Settings → Agents → MCP Servers** — the `ris` server
should show as connected with 12 available tools.

## Available Tools

| Tool | Description |
|------|-------------|
| `ris_bundesrecht` | Search federal laws (ABGB, StGB, UGB, etc.) |
| `ris_landesrecht` | Search state/provincial laws (all 9 provinces) |
| `ris_judikatur` | Search court decisions (11 court types) |
| `ris_bundesgesetzblatt` | Search Federal Law Gazettes (BGBl I/II/III) |
| `ris_landesgesetzblatt` | Search State Law Gazettes (LGBl) |
| `ris_regierungsvorlagen` | Search government bills |
| `ris_dokument` | Retrieve full document text by ID or URL |
| `ris_bezirke` | Search district authority announcements |
| `ris_gemeinden` | Search municipal law and regulations |
| `ris_sonstige` | Search miscellaneous legal collections |
| `ris_history` | Track document change history |
| `ris_verordnungen` | Search state ordinance gazettes |

## Example Prompts

Once an agent workspace has the RIS tools enabled:

> "What does Austrian law say about tenancy rights?"

> "Find Constitutional Court decisions on freedom of expression."

> "Show me §1295 of the ABGB (Austrian Civil Code)."

> "What laws about climate protection were published in 2024?"

## Troubleshooting

**RIS MCP server fails to start:**
```bash
docker compose logs ris-mcp
```

**AnythingLLM can't connect to RIS MCP:**
- Verify both containers are on the same Docker network
- Check that `ris-mcp` resolves: `docker compose exec app ping -c1 ris-mcp`
- Confirm the URL in config is `http://ris-mcp:3000/mcp` (not `localhost`)

**Tools not appearing in agent:**
- Go to Admin → Agents → MCP Servers → click Refresh
- Check that `autoStart` is `true` in the config
- Verify the server shows "success" status (not "failed")

## Updating

To update the RIS MCP server version, edit `infra/ris-mcp/Dockerfile` and
change the version number in the `npm install` command:

```dockerfile
RUN npm install -g ris-mcp-ts@<NEW_VERSION> && npm cache clean --force
```

Then rebuild:
```bash
docker compose up -d --build ris-mcp
```

## References

- [ris-mcp-ts on GitHub](https://github.com/philrox/ris-mcp-ts)
- [ris-mcp-ts on npm](https://www.npmjs.com/package/ris-mcp-ts)
- [RIS Open Government Data API](https://data.bka.gv.at/ris/api/v2.6/)
- [AnythingLLM MCP Documentation](https://docs.anythingllm.com/mcp-compatibility/docker)
