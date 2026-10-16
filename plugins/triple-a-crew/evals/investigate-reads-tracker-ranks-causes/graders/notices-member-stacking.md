---
type: llm
focus: trace
---

PASS if the final report points out, as an alternative cause or a separate finding, that card payments stack member pricing on top of the coupon (`memberPrice` in `src/loyalty.js`, called from `checkoutTotal` in `src/checkout.js`) against the "does not stack" policy, so members using SAVE10 by card would also get 19% off.

FAIL if the member-pricing stacking is not mentioned.
