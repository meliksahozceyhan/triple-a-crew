#!/usr/bin/env bash
# orders-api: a small ESM Node repo whose CSV export loads every order and builds one string in memory. It holds
# no diagram, no flow description and no .crew/work folder; the request is to stream the rows instead.
set -euo pipefail
# Refuse to run outside a fresh eval sandbox: this script writes files and runs git in the current folder.
if [ -n "$(ls -A . 2>/dev/null)" ]; then
  echo "fixture.sh: refusing to run in a non-empty folder ($PWD); the eval harness runs it in an empty workspace" >&2
  exit 1
fi
git init -q -b main
mkdir -p .crew src/routes src/db src/export test
cat > package.json <<'JSON'
{ "name": "orders-api", "private": true, "type": "module", "scripts": { "test": "node --test" } }
JSON
cat > CLAUDE.md <<'MD'
# orders-api
ESM only, no dependencies. Tests use node:test (`node --test`).
MD
cat > .crew/profile.md <<'PROFILE'
---
stack: [javascript, node]
verify:
  - node --test
tests: ["test/**/*.test.js"]
conventions: [CLAUDE.md]
organizer: proactive
---
PROFILE
cat > src/db/client.js <<'JS'
// In-memory stand-in for the database client: `query` returns every row, `cursor` yields them one at a time.
export function createDb(orders) {
  return {
    async query() {
      return orders.slice(0);
    },
    async *cursor() {
      for (const order of orders) yield order;
    },
  };
}
JS
cat > src/db/orders.js <<'JS'
// Loads the orders for the export.
export async function loadOrders(db) {
  return db.query("SELECT id, customer, total_cents, created_at FROM orders ORDER BY id");
}
JS
cat > src/export/csv.js <<'JS'
const HEADER = "id,customer,total,created";

function toRow(order) {
  const total = (order.total_cents / 100).toFixed(2);
  return [order.id, order.customer, total, order.created_at].join(",");
}

// Builds the whole export file as one string. Lines end with CRLF, as the mobile app expects.
export function buildCsv(orders) {
  const lines = [HEADER, ...orders.map(toRow)];
  return lines.join("\r\n") + "\r\n";
}
JS
cat > src/routes/orders.js <<'JS'
import { loadOrders } from "../db/orders.js";
import { buildCsv } from "../export/csv.js";

// GET /orders/export
export async function exportOrders(db, res) {
  const orders = await loadOrders(db);
  const csv = buildCsv(orders);
  res.setHeader("Content-Type", "text/csv");
  res.send(csv);
}
JS
cat > test/export.test.js <<'JS'
import test from "node:test";
import assert from "node:assert/strict";
import { buildCsv } from "../src/export/csv.js";

test("builds a header and one CRLF-terminated line per order", () => {
  const csv = buildCsv([{ id: 1, customer: "Ada", total_cents: 1250, created_at: "2026-01-02" }]);
  assert.equal(csv, "id,customer,total,created\r\n1,Ada,12.50,2026-01-02\r\n");
});
JS
git add -A && git -c user.email=fixture@example.com -c user.name=fixture commit -q -m "orders-api baseline"
