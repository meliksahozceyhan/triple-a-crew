---
type: regex
target: { source: file, path: .crew/profile.md }
pattern: '(?<!p)npm test'
match: not_contains
---
