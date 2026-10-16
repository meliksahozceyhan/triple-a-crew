---
type: llm
---

PASS if the reply identifies, as the primary cause, that `checkoutTotal` in `src/checkout.js` calls `applyCoupon` on a total that `cartTotal` already discounted (so SAVE10 is applied twice: 0.9 × 0.9 = 0.81), cites the file and line or function, gives a confidence, and suggests a next step such as a test or removing the second application.

FAIL if it misses the double application, or only edits code without explaining the cause.
