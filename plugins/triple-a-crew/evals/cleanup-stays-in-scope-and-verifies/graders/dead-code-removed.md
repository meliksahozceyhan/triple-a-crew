---
type: regex
target: { source: file, path: src/sync.js }
pattern: 'oldResult|legacyFetch'
match: not_contains
---
