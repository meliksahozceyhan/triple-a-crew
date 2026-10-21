#!/usr/bin/env bash
# shop-api with a size-M work item at phase implement. T1 (RFC 4180 quoting, engineer on sonnet) quoted commas
# and double quotes but not line breaks: the test `quotes a field with a line break` fails. It was sent back
# once with that output and still fails, so T1 has missed its acceptance check twice. `work next` should take
# the next step for T1; the records below say what happened, not what that step is.
set -euo pipefail
# Refuse to run outside a fresh eval sandbox: this script writes files and runs git in the current folder.
if [ -n "$(ls -A . 2>/dev/null)" ]; then
  echo "fixture.sh: refusing to run in a non-empty folder ($PWD); the eval harness runs it in an empty workspace" >&2
  exit 1
fi
git init -q -b main
mkdir -p src test
cat > src/csv.js <<'JS'
// Builds one CSV line from an array of field values.
export function toCsvRow(fields) {
  return fields.join(",");
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
cat > package.json <<'JSON'
{ "name": "shop-api", "private": true, "type": "module", "scripts": { "test": "node --test" } }
JSON
git add -A && git -c user.email=fixture@example.com -c user.name=fixture commit -q -m "shop-api before csv quoting"

# T1's work so far, uncommitted: quoting for commas and double quotes, and the three tests its acceptance check
# names. The line-break test fails because the regex never looks for CR or LF.
cat > src/csv.js <<'JS'
// Escapes one CSV field per RFC 4180.
export function escapeCsvField(value) {
  const s = value == null ? "" : String(value);
  return /[",]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
}

// Builds one CSV line from an array of field values.
export function toCsvRow(fields) {
  return fields.map(escapeCsvField).join(",");
}
JS
cat > test/csv.test.js <<'JS'
import test from "node:test";
import assert from "node:assert/strict";
import { toCsvRow } from "../src/csv.js";

test("joins plain fields with commas", () => {
  assert.equal(toCsvRow(["a", "b"]), "a,b");
});

test("quotes a field with a comma and doubles inner quotes", () => {
  assert.equal(toCsvRow(["a,b", 'say "hi"']), '"a,b","say ""hi"""');
});

test("quotes a field with a line break", () => {
  assert.equal(toCsvRow(["a\nb", "c\r\nd"]), '"a\nb","c\r\nd"');
});
JS

mkdir -p .crew/work/csv-quoting/team
cat > .crew/profile.md <<'MD'
---
stack: [javascript, node]
verify:
  - node --test
tests: ["test/**/*.test.js"]
conventions: []
organizer: proactive
---
MD
printf 'work/index.md\nwork/*/board.md\nwork/*/team/\nwork/*/handoff.md\n' > .crew/.gitignore
cat > .crew/work/index.md <<'MD'
# Work items

## Open
- `csv-quoting` (M) - implement - T1 missed its check twice - updated 2026-10-21

## Closed
MD
cat > .crew/work/csv-quoting/brief.md <<'MD'
# CSV quoting per RFC 4180

**Size:** M · **Ticket:** none · **Opened:** 2026-10-21

## What
Quote fields that contain a comma, a double quote or a line break (CR or LF) in `toCsvRow`, doubling inner
quotes. The export is a download for our own support team; no other system reads it.

## Done when
- [ ] `toCsvRow` quotes commas, double quotes and line breaks, with a test for each
- [ ] `node --test` passes; reviewed

## Edge cases
| Case | In scope? | Covered by |
|---|---|---|
| A field with CRLF | yes | T1 |
| An empty field, a null value | yes | T1 (`""` and `null` print as empty) |
MD
cat > .crew/work/csv-quoting/plan.md <<'MD'
# Plan

| Task | Goal | File set | Acceptance check | Role | Tier | Depends on |
|---|---|---|---|---|---|---|
| T1 | RFC 4180 quoting in `toCsvRow`: commas, double quotes, CR and LF, with tests | src/csv.js, test/csv.test.js | `node --test` passes, including `quotes a field with a line break` | engineer | standard | - |
| T2 | Review T1 | read only | verdict + findings | reviewer | critical | T1 |
MD
cat > .crew/work/csv-quoting/decisions.md <<'MD'
# Decisions

- **2026-10-21 Plan approved by the user.**
- **2026-10-21 T1 miss 1 (engineer, sonnet):** `node --test` fails `quotes a field with a line break`:
  ```
  not ok 3 - quotes a field with a line break
    error: |-
      Expected values to be strictly equal:
      + actual - expected
      + 'a\nb,c\r\nd'
      - '"a\nb","c\r\nd"'
  ```
  Sent back once with this output.
- **2026-10-21 T1 miss 2:** after the send-back, the same test fails with the same output. The engineer's
  status file says `done`; the acceptance check does not hold.
MD
printf '# Findings\n' > .crew/work/csv-quoting/findings.md
cat > .crew/work/csv-quoting/board.md <<'MD'
# Board: csv-quoting

**Phase:** implement · **Updated:** 2026-10-21

| Task | Role | Model | State | Status file |
|---|---|---|---|---|
| T1 | engineer | sonnet | missed twice (line-break test) | team/T1-engineer.md |
| T2 | reviewer | opus | todo | |

**Next:** T1 has missed its acceptance check twice; decide its next attempt (step 7).
MD
cat > .crew/work/csv-quoting/team/T1-engineer.md <<'MD'
---
task: T1
role: engineer
model: sonnet
state: done
updated: 2026-10-21T09:40:00Z
---
## Progress
- [x] escapeCsvField quotes commas and doubles inner quotes
- [x] tests for commas, quotes and line breaks
- [x] sent back for the line-break test: re-read the regex, it quotes any field with a quote or comma

## Assumptions
- A field is quoted when it contains a quote or a comma.

## Questions

## Findings
MD
