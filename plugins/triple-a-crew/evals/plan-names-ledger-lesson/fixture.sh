#!/usr/bin/env bash
# pay-hooks: a small ESM Node repo that sends payment webhooks once, with its settings read from process.env,
# and a lessons ledger (.crew/lessons.md) with two open lessons: L2 applies to the request (a new setting
# must also be added to staging's parameter store, which nothing in the code shows), L1 does not.
set -euo pipefail
# Refuse to run outside a fresh eval sandbox: this script writes files and runs git in the current folder.
if [ -n "$(ls -A . 2>/dev/null)" ]; then
  echo "fixture.sh: refusing to run in a non-empty folder ($PWD); the eval harness runs it in an empty workspace" >&2
  exit 1
fi
git init -q -b main
mkdir -p .crew src/webhooks src/payments test
cat > package.json <<'JSON'
{ "name": "pay-hooks", "private": true, "type": "module", "scripts": { "test": "node --test" } }
JSON
cat > CLAUDE.md <<'MD'
# pay-hooks
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
cat > .crew/lessons.md <<'MD'
# Lessons

| Id | Lesson | Hits | Items | Mechanism |
|---|---|---|---|---|
| L1 | The export test depends on the machine's locale | 1 | csv-export | open |
| L2 | A new setting that exists only in the app's config reaches staging as its default: staging reads `/staging/pay-hooks/*` from the parameter store, which the platform team fills from a ticket | 1 | refund-hook | open |
MD
cat > src/config.js <<'JS'
// Settings come from the environment; the defaults apply when a variable is unset.
export const config = {
  webhookTimeoutMs: Number(process.env.WEBHOOK_TIMEOUT_MS ?? 5000),
};
JS
cat > src/webhooks/send.js <<'JS'
import { config } from "../config.js";

// Delivers one payment event to the partner. The partner treats a repeated Idempotency-Key as one payment.
export async function sendWebhook(url, event, fetchFn = fetch) {
  const res = await fetchFn(url, {
    method: "POST",
    headers: { "content-type": "application/json", "idempotency-key": event.id },
    body: JSON.stringify(event),
    signal: AbortSignal.timeout(config.webhookTimeoutMs),
  });
  if (!res.ok) throw new Error(`webhook failed with status ${res.status}`);
  return res.status;
}
JS
cat > src/payments/capture.js <<'JS'
import { sendWebhook } from "../webhooks/send.js";

// Captures a payment, then tells the partner about it.
export async function capturePayment(payment, partnerUrl) {
  const captured = { ...payment, status: "captured" };
  await sendWebhook(partnerUrl, { id: `evt_${payment.id}`, type: "payment.captured", data: captured });
  return captured;
}
JS
cat > test/send.test.js <<'JS'
import test from "node:test";
import assert from "node:assert/strict";
import { sendWebhook } from "../src/webhooks/send.js";

test("sends the event with its id as the idempotency key", async () => {
  let seen;
  const fakeFetch = async (url, options) => {
    seen = options;
    return { ok: true, status: 200 };
  };
  await sendWebhook("https://partner.example/hook", { id: "evt_1" }, fakeFetch);
  assert.equal(seen.headers["idempotency-key"], "evt_1");
});
JS
git add -A && git -c user.email=fixture@example.com -c user.name=fixture commit -q -m "pay-hooks baseline"
