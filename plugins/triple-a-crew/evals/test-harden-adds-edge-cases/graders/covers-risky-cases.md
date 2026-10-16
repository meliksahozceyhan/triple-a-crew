---
type: llm
focus: { source: file, path: test/collect.test.js }
---

PASS if the test file, beyond the original happy-path test, covers at least three of: a repeated cursor (loop protection), hasMore true with a missing next cursor, the maxPages limit, an empty first page or missing items array, an error thrown by fetchPage propagating. Assertions must be on observable results or thrown errors, not on internal calls.

FAIL if fewer than three are covered, or tests assert internal implementation details.
