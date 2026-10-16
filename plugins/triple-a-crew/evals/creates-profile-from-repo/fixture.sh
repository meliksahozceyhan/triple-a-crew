#!/usr/bin/env bash
# A small pnpm + Vitest + Prisma repo with GitHub CI and a GitHub remote.
set -euo pipefail
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
