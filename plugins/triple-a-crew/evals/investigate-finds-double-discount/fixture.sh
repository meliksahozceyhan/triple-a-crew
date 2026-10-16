#!/usr/bin/env bash
# A cart where checkout applies the coupon a second time on top of the cart total.
set -euo pipefail
git init -q -b main
mkdir -p src
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
cat > src/checkout.js <<'EOF'
import { cartTotal } from "./cart.js";
import { applyCoupon } from "./coupons.js";

export function checkoutTotal(cart, shipping) {
  const total = cartTotal(cart);
  // Coupons apply to the order total.
  return applyCoupon(total, cart.coupon) + shipping;
}
EOF
