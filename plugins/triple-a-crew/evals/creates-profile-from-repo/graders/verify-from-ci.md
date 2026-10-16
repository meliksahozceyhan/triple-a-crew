---
type: regex
target: { source: file, path: .crew/profile.md }
pattern: '-\s*pnpm (run )?lint[\s\S]*-\s*pnpm (run )?typecheck[\s\S]*-\s*pnpm (run )?test'
---
