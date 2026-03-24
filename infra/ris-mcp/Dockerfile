# RIS MCP Server — Streamable HTTP sidecar for AnythingLLM
# Provides access to Austria's Rechtsinformationssystem (RIS) via MCP protocol.
# https://github.com/philrox/ris-mcp-ts

FROM node:20-slim

# Install the RIS MCP server globally
RUN npm install -g ris-mcp-ts@1.1.3 && npm cache clean --force

# Copy healthcheck script
COPY healthcheck.js /usr/local/lib/healthcheck.js

ENV PORT=3000
ENV NODE_ENV=production
EXPOSE 3000

# Run the HTTP (Streamable HTTP) transport entry point
CMD ["node", "/usr/local/lib/node_modules/ris-mcp-ts/dist/http.js"]
