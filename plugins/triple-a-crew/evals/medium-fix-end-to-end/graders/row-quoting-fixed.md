---
type: llm
focus: { source: file, path: src/csv.js }
---

PASS if `toCsvRow` wraps a field in double quotes when it contains a comma, a double quote, a carriage return or a line feed, and doubles every double quote inside such a field. Leaving other fields unquoted is fine.

FAIL if any of those cases is not handled.
