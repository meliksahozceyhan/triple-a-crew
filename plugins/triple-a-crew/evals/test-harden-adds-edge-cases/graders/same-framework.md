---
type: regex
target: { source: file, path: test/collect.test.js }
pattern: 'vitest|jest|mocha|chai'
match: not_contains
---
