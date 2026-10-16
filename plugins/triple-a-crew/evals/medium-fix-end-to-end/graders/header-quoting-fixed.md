---
type: llm
focus: { source: file, path: src/headers.js }
---

PASS if `toCsvHeader` applies RFC 4180 quoting to labels (quotes a label containing a comma, double quote, CR or LF, and doubles inner quotes), either itself or by calling a shared quoting helper.

FAIL if labels are still joined without quoting.
