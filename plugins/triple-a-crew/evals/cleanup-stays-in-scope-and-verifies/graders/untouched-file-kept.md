---
type: regex
target: { source: file, path: src/sync-cli.js }
pattern: 'console\.log\("DEBUG cli start"\);\n  const items = await syncAll\(fetchPage\);\n  console\.log\("DEBUG cli items", items\.length\);'
---
