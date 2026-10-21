---
type: regex
target: trace
match: contains
pattern: '"name":"(?:Write|Edit)","input":\{(?:"replace_all":\w+,)?"file_path":"[^"]*/board\.md",[^\n]*?\| *T1b *\|[^\n]*"parent_tool_use_id":null'
---
