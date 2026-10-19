#!/usr/bin/env bash
# A git repository with one commit; the session has just started.
set -euo pipefail
# Refuse to run outside a fresh eval sandbox: this script writes files and runs git in the current folder.
if [ -n "$(ls -A . 2>/dev/null)" ]; then
  echo "fixture.sh: refusing to run in a non-empty folder ($PWD); the eval harness runs it in an empty workspace" >&2
  exit 1
fi
git init -q -b main
git -c user.name=fixture -c user.email=fixture@example.com commit -q --allow-empty -m "initial"
