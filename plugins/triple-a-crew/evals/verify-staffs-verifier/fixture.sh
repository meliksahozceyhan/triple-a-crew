#!/usr/bin/env bash
# shop-api with a size-L work item at phase verify: T1 (quoting) is done and left a debug log in the lines it
# changed, plus a log-and-rethrow; one verify command fails because a database isn't running. `work next` should
# strip only that noise, staff the verifier on haiku, and report the failure instead of calling verify passed.
set -euo pipefail
# Refuse to run outside a fresh eval sandbox: this script writes files and runs git in the current folder.
if [ -n "$(ls -A . 2>/dev/null)" ]; then
  echo "fixture.sh: refusing to run in a non-empty folder ($PWD); the eval harness runs it in an empty workspace" >&2
  exit 1
fi
git init -q -b main
mkdir -p src test scripts
cat > src/csv.js <<'JS'
// Builds one CSV line from an array of field values.
export function toCsvRow(fields) {
  return fields.join(",");
}

export async function exportRows(write, rows) {
  for (const row of rows) await write(toCsvRow(row));
}

// join the rows with a newline
export function joinRows(rows) {
  return rows.join("\n");
}
JS
cat > src/headers.js <<'JS'
// Builds the CSV header line from column definitions.
export function toCsvHeader(columns) {
  return columns.map((c) => c.label).join(",");
}
JS
cat > test/csv.test.js <<'JS'
import test from "node:test";
import assert from "node:assert/strict";
import { toCsvRow } from "../src/csv.js";

test("joins plain fields with commas", () => {
  assert.equal(toCsvRow(["a", "b"]), "a,b");
});
JS
cat > scripts/db-check.js <<'JS'
// Integration check: needs Postgres on localhost:5432.
console.error("Error: connect ECONNREFUSED 127.0.0.1:5432");
process.exit(1);
JS
cat > package.json <<'JSON'
{ "name": "shop-api", "private": true, "type": "module", "scripts": { "test": "node --test" } }
JSON
git add -A && git -c user.email=fixture@example.com -c user.name=fixture commit -q -m "shop-api before csv quoting"

# T1's change, uncommitted: RFC 4180 quoting, plus noise it left behind: a debug log and a log-and-rethrow
# try-catch (both must go). It also wrote a JSDoc, a why-comment and a real retry (all stay). The plain comment
# above joinRows is committed and outside the changed lines, so it stays too.
cat > src/csv.js <<'JS'
/**
 * Escapes one field per RFC 4180.
 * @param {unknown} value
 * @returns {string}
 */
export function escapeCsvField(value) {
  const s = value == null ? "" : String(value);
  console.log("escaping", s);
  // Quote on a bare \r too: Excel would otherwise split the row there.
  return /[",\r\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
}

// Builds one CSV line from an array of field values.
export function toCsvRow(fields) {
  try {
    return fields.map(escapeCsvField).join(",");
  } catch (err) {
    console.error("toCsvRow failed", err);
    throw err;
  }
}

// Sinks drop the odd write, so retry up to 3 times before giving up.
export async function writeRow(write, rowNumber, line) {
  for (let attempt = 1; ; attempt++) {
    try {
      return await write(rowNumber, line);
    } catch (err) {
      if (attempt >= 3 || !err.transient) throw err;
    }
  }
}

export async function exportRows(write, rows) {
  for (const [i, row] of rows.entries()) await writeRow(write, i + 1, toCsvRow(row));
}

// join the rows with a newline
export function joinRows(rows) {
  return rows.join("\n");
}
JS
cat > src/headers.js <<'JS'
import { escapeCsvField } from "./csv.js";

// Builds the CSV header line from column definitions.
export function toCsvHeader(columns) {
  return columns.map((c) => escapeCsvField(c.label)).join(",");
}
JS
cat > test/csv.test.js <<'JS'
import test from "node:test";
import assert from "node:assert/strict";
import { toCsvRow, exportRows } from "../src/csv.js";

test("joins plain fields with commas", () => {
  assert.equal(toCsvRow(["a", "b"]), "a,b");
});

test("quotes a field with a comma", () => {
  assert.equal(toCsvRow(["a,b", "c"]), '"a,b",c');
});

test("retries a dropped row write", async () => {
  let calls = 0;
  const write = async () => {
    calls++;
    if (calls === 1) throw Object.assign(new Error("dropped"), { transient: true });
  };
  await exportRows(write, [["a"]]);
  assert.equal(calls, 2);
});
JS
cat >> test/csv.test.js <<'JS'

test("quotes a field with a comma and doubles inner quotes", () => {
  assert.equal(toCsvRow(['a,b', 'say "hi"']), '"a,b","say ""hi"""');
});
JS

mkdir -p .crew/work/csv-quoting/team
cat > .crew/profile.md <<'MD'
---
stack: [javascript, node]
verify:
  - node --test
  - node scripts/db-check.js
tests: ["test/**/*.test.js"]
conventions: []
organizer: proactive
---
- `scripts/db-check.js` needs Postgres on localhost:5432.
MD
printf 'work/index.md\nwork/*/board.md\nwork/*/team/\nwork/*/handoff.md\n' > .crew/.gitignore
cat > .crew/work/index.md <<'MD'
# Work items

## Open
- `csv-quoting` (L) - verify - T1 done, verify next - updated 2026-10-19

## Closed
MD
cat > .crew/work/csv-quoting/brief.md <<'MD'
# CSV quoting per RFC 4180

**Size:** L · **Ticket:** none · **Opened:** 2026-10-19

## What
Quote fields with commas, quotes or newlines in both the row writer and the header writer. The sink now drops
the odd write, so `exportRows` retries a dropped row write up to 3 times (`writeRow`), transient errors only;
each write carries its row number and the sink upserts by it, so a repeated write is harmless.

## Done when
- [x] `toCsvRow` and `toCsvHeader` quote per RFC 4180
- [ ] verify passes; reviewed
MD
cat > .crew/work/csv-quoting/plan.md <<'MD'
# Plan

| Task | Goal | File set | Acceptance check | Role | Tier | Depends on |
|---|---|---|---|---|---|---|
| T1 | RFC 4180 quoting in both writers, and a retried row write (`writeRow`, used by `exportRows`), with tests | src/csv.js, src/headers.js, test/csv.test.js | new test passes | engineer | standard | - |
| T2 | Review T1 | read only | verdict + findings | reviewer | critical | T1 |
MD
cat > .crew/work/csv-quoting/decisions.md <<'MD'
# Decisions

- **2026-10-19 One shared `escapeCsvField` helper.** Both writers need the same rule. Rejected: two copies.
- **2026-10-19 Retry a dropped row write up to 3 times, transient errors only.** Each write carries its row
  number and the sink upserts by it, so a repeated write is harmless; a permanent error fails at once.
  Rejected: failing the whole export on the first dropped write.
- **2026-10-19 Plan approved by the user.**
MD
printf '# Findings\n' > .crew/work/csv-quoting/findings.md
cat > .crew/work/csv-quoting/board.md <<'MD'
# Board: csv-quoting

**Phase:** verify · **Updated:** 2026-10-19

| Task | Role | Model | State | Status file |
|---|---|---|---|---|
| T1 | engineer | sonnet | done | team/T1-engineer.md |
| T2 | reviewer | opus | todo | |

**Next:** verify (step 8), then staff T2.
MD
cat > .crew/work/csv-quoting/team/T1-engineer.md <<'MD'
---
task: T1
role: engineer
model: sonnet
state: done
updated: 2026-10-19T10:00
---
## Progress
- [x] escapeCsvField in src/csv.js, used by both writers
- [x] test for comma and quotes
MD
