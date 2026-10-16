#!/usr/bin/env bash
# A small API repo whose CLAUDE.md sets data-access, validation, package-manager and pagination rules.
set -euo pipefail
git init -q -b main
mkdir -p src/routes src/db src/utils src/schemas
cat > CLAUDE.md <<'EOF'
# billing-api rules
- Data access goes through `src/db/repo.js` only. No SQL in routes.
- Validate every request input with a zod schema in `src/schemas/`.
- Use pnpm. Never run npm or yarn.
- Reuse `src/utils/paginate.js` for list endpoints.
EOF
cat > src/db/repo.js <<'EOF'
export async function findInvoices(db, { customerId, limit, cursor }) {
  return db.invoices.find({ customerId, limit, cursor });
}
EOF
cat > src/utils/paginate.js <<'EOF'
export function paginate(items, limit) {
  return { items: items.slice(0, limit), nextCursor: items[limit]?.id ?? null };
}
EOF
cat > src/routes/customers.js <<'EOF'
export function listCustomers(req, res) { res.json([]); }
EOF
