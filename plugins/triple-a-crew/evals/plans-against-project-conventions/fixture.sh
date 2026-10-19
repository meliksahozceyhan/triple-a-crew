#!/usr/bin/env bash
# billing-api: a small ESM Node repo whose rules mostly live outside CLAUDE.md: CONTRIBUTING.md and two ADRs,
# listed as conventions in .crew/profile.md. CLAUDE.md, which Claude Code loads on its own, has only the pnpm rule.
set -euo pipefail
# Refuse to run outside a fresh eval sandbox: this script writes files and runs git in the current folder.
if [ -n "$(ls -A . 2>/dev/null)" ]; then
  echo "fixture.sh: refusing to run in a non-empty folder ($PWD); the eval harness runs it in an empty workspace" >&2
  exit 1
fi
git init -q -b main
mkdir -p .crew src/routes src/db src/utils src/schemas docs/adr test
cat > package.json <<'JSON'
{ "name": "billing-api", "private": true, "type": "module", "scripts": { "test": "node --test" } }
JSON
cat > .crew/profile.md <<'PROFILE'
---
stack: [javascript, node, pnpm]
verify:
  - node --test
tests: ["test/**/*.test.js"]
conventions: [CLAUDE.md, CONTRIBUTING.md, docs/adr/]
organizer: proactive
---
PROFILE
cat > CLAUDE.md <<'MD'
# billing-api
- Use pnpm. Never run npm or yarn.
MD
cat > CONTRIBUTING.md <<'MD'
# Contributing to billing-api

## Code rules
- Data access goes through `src/db/repo.js` only. No SQL in routes.
- Validate every request input with a zod schema in `src/schemas/`.
MD
cat > docs/adr/0002-money-in-integer-cents.md <<'MD'
# ADR 0002: Money stays in integer cents

Status: accepted

Amounts are integers in cents everywhere: storage, services and API responses (`amount_cents`). Never
convert to floats or dollars on the server; clients format for display with `formatCents`.
MD
cat > docs/adr/0003-cursor-pagination.md <<'MD'
# ADR 0003: Cursor pagination for list endpoints

Status: accepted

List endpoints page with an opaque cursor through `src/utils/paginate.js`. No `OFFSET` or page numbers:
offsets skip and repeat rows while invoices are being written.
MD
cat > src/db/repo.js <<'JS'
export async function findInvoices(db, { customerId, limit, cursor }) {
  return db.invoices.find({ customerId, limit, cursor });
}
JS
cat > src/utils/paginate.js <<'JS'
export function paginate(items, limit) {
  return { items: items.slice(0, limit), nextCursor: items[limit]?.id ?? null };
}
JS
cat > src/routes/customers.js <<'JS'
export function listCustomers(req, res) { res.json([]); }
JS
cat > test/customers.test.js <<'JS'
import test from "node:test";
import assert from "node:assert/strict";
import { paginate } from "../src/utils/paginate.js";

test("paginate returns a next cursor when more items remain", () => {
  const page = paginate([{ id: "a" }, { id: "b" }], 1);
  assert.equal(page.nextCursor, "b");
});
JS
git add -A && git -c user.email=fixture@example.com -c user.name=fixture commit -q -m "billing-api baseline"
