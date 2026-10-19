#!/usr/bin/env bash
# A shop with two code paths that each turn SAVE10 into 19% off: the gift-card path applies the coupon twice,
# and card payments stack member pricing on the coupon. Only the issue's comments say which one was reported.
set -euo pipefail
# Refuse to run outside a fresh eval sandbox: this script writes files and runs git in the current folder.
if [ -n "$(ls -A . 2>/dev/null)" ]; then
  echo "fixture.sh: refusing to run in a non-empty folder ($PWD); the eval harness runs it in an empty workspace" >&2
  exit 1
fi
git init -q -b main
mkdir -p src/payments
cat > src/coupons.js <<'EOF'
export function applyCoupon(total, coupon) {
  if (coupon?.code === "SAVE10") return Math.round(total * 0.9);
  return total;
}
EOF
cat > src/cart.js <<'EOF'
import { applyCoupon } from "./coupons.js";

export function cartTotal(cart) {
  const subtotal = cart.items.reduce((sum, i) => sum + i.price * i.qty, 0);
  return applyCoupon(subtotal, cart.coupon);
}
EOF
cat > src/loyalty.js <<'EOF'
// Members get 10% off. Pricing policy: member pricing does not stack with coupons.
export function memberPrice(total, customer) {
  return customer?.isMember ? Math.round(total * 0.9) : total;
}
EOF
cat > src/payments/gift-card.js <<'EOF'
import { cartTotal } from "../cart.js";
import { applyCoupon } from "../coupons.js";

// Gift cards can't be combined with member pricing, so price the order here.
export function giftCardTotal(cart, shipping) {
  return applyCoupon(cartTotal(cart), cart.coupon) + shipping;
}
EOF
cat > src/checkout.js <<'EOF'
import { cartTotal } from "./cart.js";
import { memberPrice } from "./loyalty.js";
import { giftCardTotal } from "./payments/gift-card.js";

export function checkoutTotal(cart, customer, payment, shipping) {
  if (payment.method === "gift_card") return giftCardTotal(cart, shipping);
  return memberPrice(cartTotal(cart), customer) + shipping;
}
EOF
