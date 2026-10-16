---
type: llm
focus: trace
---

PASS if the final report names, as the primary (top-ranked) cause, that `giftCardTotal` in `src/payments/gift-card.js` calls `applyCoupon` on a total that `cartTotal` already discounted, so SAVE10 is applied twice (0.9 × 0.9 = 0.81), AND it supports that ranking with facts from the issue's comments: the repro was a guest (non-member) account paying with a gift card, card payments were fine, or the coupons.js rollback did not help.

FAIL if the primary cause is something else, if the report ranks causes without using any of those comment facts, or if it changes code instead of reporting.
