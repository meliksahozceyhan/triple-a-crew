#!/usr/bin/env bash
# textkit: a small ESM Node library with three modules, a stale README that still shows the removed
# `parse(text, true)` call, and a short CONTRIBUTING.md. The request is to fix the docs only.
set -euo pipefail
# Refuse to run outside a fresh eval sandbox: this script writes files and runs git in the current folder.
if [ -n "$(ls -A . 2>/dev/null)" ]; then
  echo "fixture.sh: refusing to run in a non-empty folder ($PWD); the eval harness runs it in an empty workspace" >&2
  exit 1
fi
git init -q -b main
mkdir -p .crew src test
cat > package.json <<'JSON'
{ "name": "textkit", "private": true, "type": "module", "scripts": { "test": "node --test" } }
JSON
cat > CLAUDE.md <<'MD'
# textkit
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
cat > README.md <<'MD'
# textkit

Small helpers for turning `key=value` text into objects and back.

## Install

    npm install textkit
    npm run build

## Usage

    import { parse } from "textkit/parser";
    const settings = parse("a=1\nb=2", true);

`parse` used to take a second argument that turned values into numbers. See the source for the rest.
MD
cat > CONTRIBUTING.md <<'MD'
# Contributing

Open a pull request against `main`. Keep changes small and add a test for each behavior you change.
MD
cat > src/parser.js <<'JS'
/**
 * Parses `key=value` lines into an object. Blank lines and lines starting with `#` are skipped. A later
 * key replaces an earlier one. Values stay strings.
 * @param {string} text
 * @returns {Record<string, string>}
 */
export function parse(text) {
  const result = {};
  for (const line of text.split("\n")) {
    const trimmed = line.trim();
    if (trimmed === "" || trimmed.startsWith("#")) continue;
    const at = trimmed.indexOf("=");
    if (at === -1) throw new Error(`textkit: no "=" in line: ${trimmed}`);
    result[trimmed.slice(0, at).trim()] = trimmed.slice(at + 1).trim();
  }
  return result;
}
JS
cat > src/formatter.js <<'JS'
/**
 * Formats an object as `key=value` lines, sorted by key, with a trailing newline.
 * @param {Record<string, string | number>} settings
 * @returns {string}
 */
export function format(settings) {
  return Object.keys(settings)
    .sort()
    .map((key) => `${key}=${settings[key]}`)
    .join("\n") + "\n";
}
JS
cat > src/cache.js <<'JS'
/**
 * Creates a small in-memory cache whose entries expire after `ttlMs` milliseconds.
 * @param {number} ttlMs
 * @param {() => number} [now] clock, for tests; defaults to `Date.now`
 */
export function createCache(ttlMs, now = Date.now) {
  const entries = new Map();
  return {
    set(key, value) {
      entries.set(key, { value, expires: now() + ttlMs });
    },
    get(key) {
      const entry = entries.get(key);
      if (!entry) return undefined;
      if (entry.expires <= now()) {
        entries.delete(key);
        return undefined;
      }
      return entry.value;
    },
  };
}
JS
cat > test/parser.test.js <<'JS'
import test from "node:test";
import assert from "node:assert/strict";
import { parse } from "../src/parser.js";

test("parses key=value lines and skips comments", () => {
  assert.deepEqual(parse("# note\na=1\n\nb = 2"), { a: "1", b: "2" });
});
JS
cat > test/formatter.test.js <<'JS'
import test from "node:test";
import assert from "node:assert/strict";
import { format } from "../src/formatter.js";

test("sorts keys and ends with a newline", () => {
  assert.equal(format({ b: 2, a: 1 }), "a=1\nb=2\n");
});
JS
cat > test/cache.test.js <<'JS'
import test from "node:test";
import assert from "node:assert/strict";
import { createCache } from "../src/cache.js";

test("an entry expires after the ttl", () => {
  let time = 0;
  const cache = createCache(100, () => time);
  cache.set("a", 1);
  time = 99;
  assert.equal(cache.get("a"), 1);
  time = 100;
  assert.equal(cache.get("a"), undefined);
});
JS
git add -A && git -c user.email=fixture@example.com -c user.name=fixture commit -q -m "textkit baseline"
