---
type: regex
target: trace
match: contains
flags: i
pattern: '"name":"(?:Write|Edit)","input":\{(?:"replace_all":\w+,)?"file_path":"[^"]*/plan\.md",[^\n]*?## Done-when coverage[^\n]*"parent_tool_use_id":null'
---
