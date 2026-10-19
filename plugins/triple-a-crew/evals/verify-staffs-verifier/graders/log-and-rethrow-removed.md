---
type: regex
target: { source: file, path: src/csv.js }
pattern: 'try \{\s*return fields\.map|toCsvRow failed|console\.error'
match: not_contains
---
