#!/usr/bin/env bash
# A committed repo plus an uncommitted implementation with debug logs, commented-out code and a log-and-rethrow
# try-catch, next to JSDoc, a why-comment and a real retry. A committed file the change did not touch has debug
# logs too and must stay as it is. The profile's verify list has a lint script that package.json does not mention.
set -euo pipefail
git init -q -b main
mkdir -p src test scripts .crew .github/workflows
cat > package.json <<'EOF'
{ "name": "sync", "private": true, "type": "module", "scripts": { "test": "node --test" } }
EOF
cat > src/sync.js <<'EOF'
export async function syncAll(fetchPage) {
  return [];
}
EOF
cat > .crew/profile.md <<'EOF'
---
stack: [javascript, node]
verify:
  - node --test
  - node scripts/lint.mjs
tests: ["test/**/*.test.js"]
---
EOF
cat > .github/workflows/ci.yml <<'EOF'
name: ci
on: [pull_request]
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: node --test
      - run: node scripts/lint.mjs
EOF
cat > scripts/lint.mjs <<'EOF'
// Fails on debugger statements and trailing whitespace in src/.
import { readdirSync, readFileSync } from "node:fs";
let problems = 0;
for (const name of readdirSync("src")) {
  readFileSync(`src/${name}`, "utf8").split("\n").forEach((line, i) => {
    if (/\bdebugger\b/.test(line) || /[ \t]+$/.test(line)) {
      console.error(`src/${name}:${i + 1}: ${line.trim() || "(trailing whitespace)"}`);
      problems += 1;
    }
  });
}
if (problems) process.exit(1);
console.log("lint ok");
EOF
cat > src/sync-cli.js <<'EOF'
import { syncAll } from "./sync.js";

export async function main(fetchPage) {
  console.log("DEBUG cli start");
  const items = await syncAll(fetchPage);
  console.log("DEBUG cli items", items.length);
  return items;
}
EOF
cat > test/sync.test.js <<'EOF'
import test from "node:test";
import assert from "node:assert/strict";
import { syncAll } from "../src/sync.js";

test("collects every page", async () => {
  const pages = { null: { items: [1, 2], next: "b" }, b: { items: [3], next: null } };
  assert.deepEqual(await syncAll(async (c) => pages[c]), [1, 2, 3]);
});

test("retries a transient failure", async () => {
  let calls = 0;
  const fetchPage = async () => {
    calls += 1;
    if (calls === 1) throw Object.assign(new Error("busy"), { status: 429 });
    return { items: [7], next: null };
  };
  assert.deepEqual(await syncAll(fetchPage), [7]);
});
EOF
git -c user.name=fixture -c user.email=fixture@example.com add -A
git -c user.name=fixture -c user.email=fixture@example.com commit -q -m "initial"
# The implementation that was just written, full of leftovers (uncommitted).
cat > src/sync.js <<'EOF'
/**
 * Fetches every page from the source and returns all items in order.
 * @param {(cursor: string|null) => Promise<{items: unknown[], next: string|null}>} fetchPage
 */
export async function syncAll(fetchPage) {
  console.log("DEBUG syncAll start");
  const items = [];
  let cursor = null;
  // loop over the pages
  do {
    // const oldResult = await legacyFetch(cursor);
    // items.push(...oldResult);
    const page = await fetchWithRetry(fetchPage, cursor);
    console.log("DEBUG got page", cursor, page.items.length);
    items.push(...page.items);
    cursor = page.next;
  } while (cursor);
  try {
    return items;
  } catch (err) {
    console.error(err);
    throw err;
  }
}

// The source rate-limits bursts with 429s, so retry those with backoff instead of failing the whole sync.
async function fetchWithRetry(fetchPage, cursor) {
  for (let attempt = 1; ; attempt += 1) {
    try {
      return await fetchPage(cursor);
    } catch (err) {
      if (err.status !== 429 || attempt >= 3) throw err;
      await new Promise((r) => setTimeout(r, 10 * attempt));
    }
  }
}
EOF
