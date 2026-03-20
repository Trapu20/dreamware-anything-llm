#!/usr/bin/env bash
# =============================================================================
# sync-settings.sh — Sync AnythingLLM system_settings between environments
#
# Copies the system_settings table rows from a SOURCE SQLite database to a
# DESTINATION SQLite database. Designed to run *inside* the Docker container
# (via `docker exec`) or directly on the host if sqlite3 is available.
#
# Usage (run on the destination host, e.g. the prod server):
#
#   # Export from test container:
#   docker exec <test_container> bash /app/sync-settings.sh export \
#     /app/server/storage/anythingllm.db > /tmp/settings.sql
#
#   # Import to prod container:
#   docker cp /tmp/settings.sql <prod_container>:/tmp/settings.sql
#   docker exec <prod_container> bash /app/sync-settings.sh import \
#     /app/server/storage/anythingllm.db /tmp/settings.sql
#
# Excluded labels (secrets / environment-specific values):
#   JWTSecret, AuthToken, MultiUserMode, HasCompletedSetup
# =============================================================================
set -euo pipefail

# ── Labels that must NOT be copied across environments ────────────────────────
# JWTSecret        — per-environment secret; different on test vs prod
# AuthToken        — per-environment access password; different on test vs prod
# MultiUserMode    — environment state (may differ intentionally)
# HasCompletedSetup — onboarding state; should not be reset on prod
#
# NOTE: this list is also hard-coded in .github/workflows/sync-settings.yml
# (the inline SSH script cannot source this file).  Keep both in sync.
EXCLUDED_LABELS="'JWTSecret','AuthToken','MultiUserMode','HasCompletedSetup'"

usage() {
  echo "Usage:"
  echo "  $0 export <db_path>                  — print INSERT statements to stdout"
  echo "  $0 import <db_path> <sql_file>        — apply INSERT statements from file"
  echo "  $0 diff   <src_db>  <dst_db>          — show labels that differ"
  exit 1
}

# ── Validate sqlite3 is available ─────────────────────────────────────────────
if ! command -v sqlite3 &>/dev/null; then
  echo "ERROR: sqlite3 is not installed." >&2
  exit 1
fi

ACTION="${1:-}"
[ -z "$ACTION" ] && usage

# ─────────────────────────────────────────────────────────────────────────────
# export  — dump system_settings rows as portable INSERT OR REPLACE statements
# ─────────────────────────────────────────────────────────────────────────────
cmd_export() {
  local db="${1:?ERROR: db_path required}"
  [ -f "$db" ] || { echo "ERROR: database not found: $db" >&2; exit 1; }

  sqlite3 "$db" <<SQL
SELECT
  'INSERT OR REPLACE INTO system_settings (label, value, createdAt, lastUpdatedAt) VALUES ('
  || quote(label)         || ', '
  || quote(value)         || ', '
  || quote(createdAt)     || ', '
  || quote(lastUpdatedAt) || ');'
FROM system_settings
WHERE label NOT IN (${EXCLUDED_LABELS})
ORDER BY label;
SQL
}

# ─────────────────────────────────────────────────────────────────────────────
# import  — apply an exported SQL file into the destination database
# ─────────────────────────────────────────────────────────────────────────────
cmd_import() {
  local db="${1:?ERROR: db_path required}"
  local sql_file="${2:?ERROR: sql_file required}"

  [ -f "$db" ]       || { echo "ERROR: database not found: $db"       >&2; exit 1; }
  [ -f "$sql_file" ] || { echo "ERROR: sql file not found: $sql_file" >&2; exit 1; }

  # Backup first
  local backup="${db}.backup.$(date +%Y%m%d%H%M%S)"
  cp "$db" "$backup"
  echo "Backed up database to: $backup"

  local rows
  rows=$(grep -c "INSERT OR REPLACE" "$sql_file" || true)
  echo "Applying ${rows} setting(s) from ${sql_file}…"

  sqlite3 "$db" < "$sql_file"
  echo "Import complete."

  # Show the labels that were updated
  echo ""
  echo "Synced labels:"
  grep "INSERT OR REPLACE" "$sql_file" \
    | sed "s/INSERT OR REPLACE INTO system_settings.*VALUES ('\([^']*\)'.*/  - \1/" \
    | sort
}

# ─────────────────────────────────────────────────────────────────────────────
# diff  — compare system_settings between two databases
# ─────────────────────────────────────────────────────────────────────────────
cmd_diff() {
  local src="${1:?ERROR: src_db required}"
  local dst="${2:?ERROR: dst_db required}"

  [ -f "$src" ] || { echo "ERROR: source database not found: $src" >&2; exit 1; }
  [ -f "$dst" ] || { echo "ERROR: dest   database not found: $dst" >&2; exit 1; }

  local src_dump dst_dump
  src_dump=$(cmd_export "$src")
  dst_dump=$(sqlite3 "$dst" <<SQL
SELECT
  'INSERT OR REPLACE INTO system_settings (label, value, createdAt, lastUpdatedAt) VALUES ('
  || quote(label)         || ', '
  || quote(value)         || ', '
  || quote(createdAt)     || ', '
  || quote(lastUpdatedAt) || ');'
FROM system_settings
WHERE label NOT IN (${EXCLUDED_LABELS})
ORDER BY label;
SQL
)

  if [ "$src_dump" = "$dst_dump" ]; then
    echo "✅  No differences in system_settings (excluding secrets)."
    exit 0
  fi

  echo "⚠️  Differences found (src vs dst):"
  diff <(echo "$src_dump") <(echo "$dst_dump") || true
  exit 1
}

# ── Dispatch ──────────────────────────────────────────────────────────────────
case "$ACTION" in
  export) cmd_export "$2" ;;
  import) cmd_import "$2" "${3:-}" ;;
  diff)   cmd_diff   "$2" "${3:-}" ;;
  *)      usage ;;
esac
