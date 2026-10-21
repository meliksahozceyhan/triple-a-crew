---
type: regex
target: trace
match: contains
pattern: '"name":"Agent","input":\{(?=[^\n]*"subagent_type":"triple-a-crew:engineer")[^\n]*(?:not ok 3 - quotes a field with a line break|Expected values to be strictly equal)[^\n]*"parent_tool_use_id":null'
---
