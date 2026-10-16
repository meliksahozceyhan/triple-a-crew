#!/usr/bin/env bash
# shop-api fixture with an open work item, csv-quoting, waiting for review.
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
mkdir -p .crew/work/csv-quoting/team
cat > .crew/work/index.md <<'EOF'
# Work items

## Open
- `csv-quoting` (M) - review - T1 done, T2 reviewer next - updated 2026-10-15

## Closed
EOF
cat > .crew/work/csv-quoting/brief.md <<'EOF'
# Quote CSV fields per RFC 4180

**Size:** M · **Ticket:** none · **Opened:** 2026-10-15

## What
Quote fields containing commas, quotes or newlines in `toCsvRow` and `toCsvHeader`.

## Done when
- [x] Fields with commas, quotes or newlines are quoted, inner quotes doubled
- [ ] Reviewed
EOF
cat > .crew/work/csv-quoting/plan.md <<'EOF'
# Plan

| Task | Goal | File set | Acceptance check | Role | Tier | Depends on |
|---|---|---|---|---|---|---|
| T1 | Implement RFC 4180 quoting | src/csv.js, src/headers.js, test/csv.test.js | `node --test` passes with new cases | engineer | standard | - |
| T2 | Review T1 | read only | verdict + findings | reviewer | critical | T1 |
EOF
cat > .crew/work/csv-quoting/board.md <<'EOF'
# Board: csv-quoting

**Phase:** review · **Updated:** 2026-10-15T17:40

| Task | Role | Model | State | Status file |
|---|---|---|---|---|
| T1 | engineer | sonnet | done | team/T1-engineer.md |
| T2 | reviewer | opus | todo | |

**Next:** staff T2 reviewer on the T1 diff.
EOF
cat > .crew/work/csv-quoting/team/T1-engineer.md <<'EOF'
---
task: T1
role: engineer
model: sonnet
state: done
updated: 2026-10-15T17:35
---
## Progress
- [x] Quoting in toCsvRow and toCsvHeader
- [x] Tests for comma, quote, newline
EOF
