---
type: regex
target: { source: file, path: src/sync.js }
pattern: 'catch \(err\) \{\s*console\.error\(err\);\s*throw err;'
match: not_contains
---
