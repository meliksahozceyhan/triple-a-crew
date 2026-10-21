---
type: regex
target: trace
match: contains
pattern: '"name":"Agent","input":\{(?=[^\n]*"subagent_type":"triple-a-crew:engineer")(?=[^\n]*"model":"sonnet")(?=[^\n]*"effort":"high")[^\n]*"parent_tool_use_id":null'
---
