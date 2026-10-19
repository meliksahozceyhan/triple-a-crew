---
type: regex
target: trace
match: contains
flags: i
pattern: '"name":"Agent","input":\{(?=[^\n]*"subagent_type":"triple-a-crew:reviewer")(?=[^\n]*#41)[^\n]*README[^\n]{0,160}?(?:error|exit code)[^\n]*"parent_tool_use_id":null'
---
