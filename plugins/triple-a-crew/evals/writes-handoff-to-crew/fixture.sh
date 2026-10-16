#!/usr/bin/env bash
# A git repository with one commit; the session has just started.
set -euo pipefail
git init -q -b main
git -c user.name=fixture -c user.email=fixture@example.com commit -q --allow-empty -m "initial"
