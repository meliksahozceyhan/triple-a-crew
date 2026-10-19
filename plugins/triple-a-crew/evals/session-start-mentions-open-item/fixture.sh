#!/usr/bin/env bash
# A small repo with one open crew work item. The SessionStart hook should put it in Claude's context.
set -euo pipefail
# Refuse to run outside a fresh eval sandbox: this script writes files and runs git in the current folder.
if [ -n "$(ls -A . 2>/dev/null)" ]; then
  echo "fixture.sh: refusing to run in a non-empty folder ($PWD); the eval harness runs it in an empty workspace" >&2
  exit 1
fi
git init -q -b main
mkdir -p src .crew/work/csv-export
cat > src/csv.js <<'JS'
export function toCsvRow(fields) {
  return fields.join(",");
}
JS
cat > .crew/work/index.md <<'MD'
# Work items

## Open
- `csv-export` (L) - implement - T2 engineer running - updated 2026-10-19

## Closed
- `orders-limit` (M) - done 2026-10-12
MD
cat > .crew/work/csv-export/board.md <<'MD'
# Board: csv-export

**Phase:** implement · **Updated:** 2026-10-19
MD
