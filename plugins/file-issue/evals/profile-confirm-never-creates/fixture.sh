#!/usr/bin/env bash
# Writes a project profile that pins Linear team SHOP and turns confirmation off.
set -euo pipefail
# Refuse to run outside a fresh eval sandbox: this script writes files and runs git in the current folder.
if [ -n "$(ls -A . 2>/dev/null)" ]; then
  echo "fixture.sh: refusing to run in a non-empty folder ($PWD); the eval harness runs it in an empty workspace" >&2
  exit 1
fi
mkdir -p .crew
cat > .crew/profile.md <<'PROFILE'
---
issue_tracker:
  tool: linear
  team: SHOP
  labels: [follow-up]
  confirm: never
---
PROFILE
