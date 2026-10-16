#!/usr/bin/env bash
# A cursor-pagination helper with guards for repeated cursors, missing cursors and page limits, tested only on the happy path.
set -euo pipefail
git init -q -b main
mkdir -p src test
cat > package.json <<'EOF'
{ "name": "pager", "private": true, "type": "module", "scripts": { "test": "node --test" } }
EOF
cat > CLAUDE.md <<'EOF'
# pager
Tests use node:test and node:assert. No other test libraries.
EOF
cat > src/collect.js <<'EOF'
// Collects all items from a cursor-paginated source.
export async function collectPages(fetchPage, { maxPages = 1000 } = {}) {
  const items = [];
  const seen = new Set();
  let cursor = null;
  for (let page = 0; page < maxPages; page += 1) {
    const res = await fetchPage(cursor);
    items.push(...(res.items ?? []));
    if (!res.hasMore) return items;
    if (!res.next) throw new Error("hasMore is true but no next cursor");
    if (seen.has(res.next)) throw new Error(`repeated cursor ${res.next}`);
    seen.add(res.next);
    cursor = res.next;
  }
  throw new Error(`stopped after ${maxPages} pages`);
}
EOF
cat > test/collect.test.js <<'EOF'
import test from "node:test";
import assert from "node:assert/strict";
import { collectPages } from "../src/collect.js";

test("collects two pages", async () => {
  const pages = { null: { items: [1], hasMore: true, next: "b" }, b: { items: [2], hasMore: false } };
  assert.deepEqual(await collectPages(async (c) => pages[c]), [1, 2]);
});
EOF
