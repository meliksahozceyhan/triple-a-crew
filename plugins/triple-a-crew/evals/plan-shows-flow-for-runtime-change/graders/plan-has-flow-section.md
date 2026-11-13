---
type: regex
target: trace
match: contains
pattern: '"name":"(?:Write|Edit)","input":\{(?:"replace_all":\w+,)?"file_path":"[^"]*/plan\.md",(?:(?!"name":")[^\n])*?## Flow\\n(?:(?!"name":")(?!```)[^\n])*?```mermaid\\nflowchart(?:(?!```)[^\n])*?(?:\\n|[^\w\n])T\d[^\n]*?"parent_tool_use_id":null'
---
