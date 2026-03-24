#!/usr/bin/env node
// Healthcheck for the RIS MCP sidecar container.
// Exits 0 if healthy, 1 otherwise.

const port = process.env.PORT || 3000;

fetch(`http://localhost:${port}/health`)
  .then((r) => {
    if (!r.ok) process.exit(1);
  })
  .catch(() => process.exit(1));
