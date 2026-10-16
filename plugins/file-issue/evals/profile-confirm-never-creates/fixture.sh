#!/usr/bin/env bash
# Writes a project profile that pins Linear team ACT and turns confirmation off.
set -euo pipefail
mkdir -p .crew
cat > .crew/profile.md <<'PROFILE'
---
issue_tracker:
  tool: linear
  team: ACT
  labels: [follow-up]
  confirm: never
---
PROFILE
