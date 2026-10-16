---
type: regex
target: { source: file, path: .crew/profile.md }
pattern: '-\s*pnpm (run )?(dev|build|deploy)\b'
match: not_contains
---
