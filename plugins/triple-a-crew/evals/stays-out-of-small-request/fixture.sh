#!/usr/bin/env bash
# shop-api fixture.
set -euo pipefail
git init -q -b main
cat > package.json <<'EOF'
{ "name": "shop-api", "private": true, "type": "module", "scripts": { "test": "node --test" } }
EOF
mkdir -p src/routes test .crew
cat > src/csv.js <<'EOF'
// Builds one CSV line from an array of field values.
export function toCsvRow(fields) {
  return fields.join(",");
}
EOF
cat > src/headers.js <<'EOF'
// Builds the CSV header line from column definitions.
export function toCsvHeader(columns) {
  return columns.map((c) => c.label).join(",");
}
EOF
cat > src/util.js <<'EOF'
export function fmt(cents) {
  return (cents / 100).toFixed(2);
}
EOF
cat > src/routes/orders.js <<'EOF'
import { toCsvRow } from "../csv.js";
import { toCsvHeader } from "../headers.js";
import { fmt } from "../util.js";

const COLUMNS = [
  { key: "id", label: "ID" },
  { key: "customer", label: "Customer" },
  { key: "note", label: "Note" },
  { key: "total", label: "Total" },
];

export function listOrders(db, query = {}) {
  return db.orders.slice(0);
}

export function exportOrdersCsv(db) {
  const lines = [toCsvHeader(COLUMNS)];
  for (const order of db.orders) {
    lines.push(toCsvRow(COLUMNS.map((c) => (c.key === "total" ? fmt(order.total) : String(order[c.key] ?? "")))));
  }
  return lines.join("
");
}
EOF
cat > test/csv.test.js <<'EOF'
import test from "node:test";
import assert from "node:assert/strict";
import { toCsvRow } from "../src/csv.js";

test("joins plain fields with commas", () => {
  assert.equal(toCsvRow(["a", "b"]), "a,b");
});
EOF
cat > CLAUDE.md <<'EOF'
# shop-api
ESM only, no dependencies. Keep functions pure. Tests use node:test (`node --test`).
EOF
cat > .crew/profile.md <<'EOF'
---
stack: [javascript, node]
verify:
  - node --test
tests: ["test/**/*.test.js"]
conventions: [CLAUDE.md]
organizer: proactive
---
EOF

