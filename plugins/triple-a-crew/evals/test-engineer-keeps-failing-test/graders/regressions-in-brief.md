---
type: regex
target: trace
match: contains
pattern: '"name":"Agent","input":\{(?=[^\n]*"subagent_type":"triple-a-crew:test-engineer")[^\n]*## Regressions to catch[^\n]*"parent_tool_use_id":null'
---
