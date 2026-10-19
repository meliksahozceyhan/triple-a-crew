#!/usr/bin/env bash
# The same repo, with an outdated profile from before the move to pnpm and Vitest.
set -euo pipefail
# Refuse to run outside a fresh eval sandbox: this script writes files and runs git in the current folder.
if [ -n "$(ls -A . 2>/dev/null)" ]; then
  echo "fixture.sh: refusing to run in a non-empty folder ($PWD); the eval harness runs it in an empty workspace" >&2
  exit 1
fi
git init -q -b main
git remote add origin https://github.com/acme/shop.git
cat > package.json <<'EOF'
{
  "name": "shop",
  "private": true,
  "packageManager": "pnpm@9.12.0",
  "scripts": {
    "dev": "vite",
    "lint": "eslint .",
    "typecheck": "tsc --noEmit",
    "test": "vitest run",
    "build": "vite build",
    "deploy": "fly deploy"
  },
  "dependencies": { "react": "18.3.1", "@prisma/client": "5.22.0" },
  "devDependencies": { "typescript": "5.6.3", "vitest": "2.1.4", "eslint": "9.14.0", "vite": "5.4.10", "prisma": "5.22.0" }
}
EOF
printf 'lockfileVersion: "9.0"
' > pnpm-lock.yaml
cat > vitest.config.ts <<'EOF'
import { defineConfig } from "vitest/config";
export default defineConfig({ test: { include: ["src/**/*.test.ts"] } });
EOF
mkdir -p src .github/workflows
echo 'export const add = (a: number, b: number) => a + b;' > src/add.ts
cat > src/add.test.ts <<'EOF'
import { test, expect } from "vitest";
import { add } from "./add";
test("add", () => expect(add(1, 2)).toBe(3));
EOF
cat > .github/workflows/ci.yml <<'EOF'
name: ci
on: [pull_request]
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - run: pnpm install --frozen-lockfile
      - run: pnpm lint
      - run: pnpm typecheck
      - run: pnpm test
EOF
cat > CLAUDE.md <<'EOF'
# Shop
Use pnpm. React components live in src/components.
EOF
mkdir -p .crew
cat > .crew/profile.md <<'EOF'
---
stack: [javascript, npm, jest]
verify:
  - npm test
tests: ["test/**/*.spec.js"]
conventions: [CLAUDE.md]
issue_tracker:
  tool: linear
  team: SHOP
  labels: [follow-up]
  confirm: batch
organizer: manual
deploy_window: "Tue-Thu"
---
- Ask Dana before touching billing code.
EOF
