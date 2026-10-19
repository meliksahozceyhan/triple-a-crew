#!/usr/bin/env bash
# orders-cli with a size-L work item at phase review that closes #41 and #42. Both per-task reviews approved,
# but each checked only its own task's acceptance check. The brief has one done-when line for both tickets, as
# #24's did; the criteria are in the issues (mocks/github). The README documents `--since` (#41) and not the
# invalid-date error and its exit code 2 (#42), so one of #42's criteria has no evidence.
set -euo pipefail
# Refuse to run outside a fresh eval sandbox: this script writes files and runs git in the current folder.
if [ -n "$(ls -A . 2>/dev/null)" ]; then
  echo "fixture.sh: refusing to run in a non-empty folder ($PWD); the eval harness runs it in an empty workspace" >&2
  exit 1
fi
git init -q -b main
mkdir -p bin src test data
cat > data/orders.json <<'JSON'
[
  { "id": "A-1001", "placedAt": "2026-01-14T09:12:00Z", "total": "42.00" },
  { "id": "A-1002", "placedAt": "2026-02-28T23:59:00Z", "total": "18.50" },
  { "id": "A-1003", "placedAt": "2026-03-01T00:00:00Z", "total": "7.25" },
  { "id": "A-1004", "placedAt": "2026-03-17T16:40:00Z", "total": "120.00" }
]
JSON
cat > bin/orders.js <<'JS'
#!/usr/bin/env node
import { readFileSync } from "node:fs";

const orders = JSON.parse(readFileSync(new URL("../data/orders.json", import.meta.url), "utf8"));
for (const o of orders) console.log(`${o.id}\t${o.placedAt}\t${o.total}`);
JS
cat > README.md <<'MD'
# orders

Lists the shop's orders from `data/orders.json`, one per line: id, placement time (UTC) and total.

    node bin/orders.js
MD
cat > package.json <<'JSON'
{ "name": "orders-cli", "private": true, "type": "module", "scripts": { "test": "node --test" } }
JSON
cat > test/orders.test.js <<'JS'
import test from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";

const cli = new URL("../bin/orders.js", import.meta.url).pathname;

test("lists every order", () => {
  const out = spawnSync(process.execPath, [cli], { encoding: "utf8" });
  assert.equal(out.status, 0);
  assert.equal(out.stdout.trim().split("\n").length, 4);
});
JS
git add -A && git -c user.email=fixture@example.com -c user.name=fixture commit -q -m "orders-cli before --since"

# The work item's change, uncommitted: T1 (--since filter, README) and T2 (invalid --since exits 2). T2's file
# set included the README, but its acceptance check named only the test, and so did its review.
cat > src/orders.js <<'JS'
// Returns the date unchanged when it is a real calendar date written as YYYY-MM-DD, otherwise null.
export function parseSince(value) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value ?? "")) return null;
  const d = new Date(`${value}T00:00:00Z`);
  return Number.isNaN(d.getTime()) || d.toISOString().slice(0, 10) !== value ? null : value;
}

// Keeps the orders placed on or after `since` (YYYY-MM-DD), comparing UTC dates.
export function filterSince(orders, since) {
  return orders.filter((o) => o.placedAt.slice(0, 10) >= since);
}
JS
cat > bin/orders.js <<'JS'
#!/usr/bin/env node
import { readFileSync } from "node:fs";
import { filterSince, parseSince } from "../src/orders.js";

const args = process.argv.slice(2);
let orders = JSON.parse(readFileSync(new URL("../data/orders.json", import.meta.url), "utf8"));
const at = args.indexOf("--since");
if (at !== -1) {
  const since = parseSince(args[at + 1]);
  if (since === null) {
    console.error(`orders: invalid --since date "${args[at + 1] ?? ""}", expected YYYY-MM-DD`);
    process.exit(2);
  }
  orders = filterSince(orders, since);
}
for (const o of orders) console.log(`${o.id}\t${o.placedAt}\t${o.total}`);
JS
cat > README.md <<'MD'
# orders

Lists the shop's orders from `data/orders.json`, one per line: id, placement time (UTC) and total.

    node bin/orders.js
    node bin/orders.js --since 2026-03-01

`--since YYYY-MM-DD` lists only the orders placed on or after that date, comparing UTC dates.
MD
cat >> test/orders.test.js <<'JS'

test("--since keeps orders placed on or after the date", () => {
  const out = spawnSync(process.execPath, [cli, "--since", "2026-03-01"], { encoding: "utf8" });
  assert.equal(out.status, 0);
  assert.deepEqual(out.stdout.trim().split("\n").map((l) => l.split("\t")[0]), ["A-1003", "A-1004"]);
});

test("an invalid --since exits 2 and names the value", () => {
  for (const bad of ["2026-02-30", "yesterday", ""]) {
    const out = spawnSync(process.execPath, [cli, "--since", bad], { encoding: "utf8" });
    assert.equal(out.status, 2);
    assert.match(out.stderr, /invalid --since date/);
    assert.equal(out.stdout, "");
  }
});
JS

mkdir -p .crew/work/orders-since/team
cat > .crew/profile.md <<'MD'
---
stack: [javascript, node]
verify:
  - node --test
tests: ["test/**/*.test.js"]
conventions: []
issue_tracker:
  tool: github
  team: acme/orders-cli
organizer: proactive
---
- Cron scripts run `node bin/orders.js` and check its exit code.
MD
printf 'work/index.md\nwork/*/board.md\nwork/*/team/\nwork/*/handoff.md\n' > .crew/.gitignore
cat > .crew/work/index.md <<'MD'
# Work items

## Open
- `orders-since` (L) - review - T3 and T4 approved - updated 2026-10-19

## Closed
MD
cat > .crew/work/orders-since/brief.md <<'MD'
# Filter orders by date, and reject a bad date

**Size:** L · **Tickets:** #41, #42 · **Opened:** 2026-10-19

## What
#41 adds `--since YYYY-MM-DD` to `bin/orders.js`. #42 makes an invalid `--since` fail with exit code 2, which
the nightly cron scripts check for (a public CLI contract, so size L).

## Done when
- [ ] #41 and #42: every acceptance criterion in both issues holds.
- [ ] `node --test` passes; reviewed.

## Edge cases
| Case | In scope? | Covered by |
|---|---|---|
| A date that doesn't exist (2026-02-30) | yes | T2 |
| An empty or missing value after `--since` | yes | T2 |
| An order placed at 00:00 UTC on the date | yes | T1 |
MD
cat > .crew/work/orders-since/plan.md <<'MD'
# Plan

| Task | Goal | File set | Acceptance check | Role | Tier | Depends on |
|---|---|---|---|---|---|---|
| T1 | `--since` filters orders by UTC date; README documents it | src/orders.js, bin/orders.js, test/orders.test.js, README.md | `--since` test passes; README documents `--since` | engineer | standard | - |
| T2 | An invalid `--since` exits 2 with an error naming the value | src/orders.js, bin/orders.js, test/orders.test.js, README.md | invalid-date test passes | engineer | standard | T1 |
| T3 | Review T1 | read only | verdict + findings | reviewer | critical | T1 |
| T4 | Review T2 | read only | verdict + findings | reviewer | critical | T2 |

## Done-when coverage
| Done when | Met by |
|---|---|
| #41 and #42: every acceptance criterion holds | T1 (#41), T2 (#42) |
| `node --test` passes; reviewed | T3, T4 |
MD
cat > .crew/work/orders-since/decisions.md <<'MD'
# Decisions

- **2026-10-19 Size L:** the exit code is a contract the cron scripts consume.
- **2026-10-19 Plan approved by the user.**
- **2026-10-19 T3 approved T1; T4 approved T2.** No must-fix findings.
MD
printf '# Findings\n' > .crew/work/orders-since/findings.md
cat > .crew/work/orders-since/board.md <<'MD'
# Board: orders-since

**Phase:** review · **Updated:** 2026-10-19

| Task | Role | Model | State | Status file |
|---|---|---|---|---|
| T1 | engineer | sonnet | done | team/T1-engineer.md |
| T2 | engineer | sonnet | done | team/T2-engineer.md |
| T3 | reviewer | opus | done (approve) | team/T3-reviewer.md |
| T4 | reviewer | opus | done (approve) | team/T4-reviewer.md |

**Next:** both per-task reviews approved; get it ready for the PR.
MD
cat > .crew/work/orders-since/team/T1-engineer.md <<'MD'
---
task: T1
role: engineer
model: sonnet
state: done
updated: 2026-10-19T09:20:00Z
---
## Progress
- [x] `filterSince` in src/orders.js, wired to `--since` in bin/orders.js
- [x] README documents `--since`
- [x] test: `--since 2026-03-01` keeps A-1003 (placed at 00:00 UTC) and A-1004
MD
cat > .crew/work/orders-since/team/T2-engineer.md <<'MD'
---
task: T2
role: engineer
model: sonnet
state: done
updated: 2026-10-19T09:45:00Z
---
## Progress
- [x] `parseSince` rejects non-dates, impossible dates and an empty value
- [x] bin/orders.js prints `orders: invalid --since date "<value>"` and exits 2
- [x] test: three bad values exit 2 with nothing on stdout
MD
cat > .crew/work/orders-since/team/T3-reviewer.md <<'MD'
---
task: T3
role: reviewer
model: opus
state: done
updated: 2026-10-19T09:35:00Z
---
## Progress
- Checked T1 against its acceptance check: the `--since` test passes; the README documents `--since`.
- The 00:00 UTC edge case is covered by A-1003.
- Verdict: approve.
MD
cat > .crew/work/orders-since/team/T4-reviewer.md <<'MD'
---
task: T4
role: reviewer
model: opus
state: done
updated: 2026-10-19T10:05:00Z
---
## Progress
- Checked T2 against its acceptance check: the invalid-date test passes for `2026-02-30`, `yesterday` and "".
- The error names the bad value and stdout stays empty.
- Verdict: approve.
MD
