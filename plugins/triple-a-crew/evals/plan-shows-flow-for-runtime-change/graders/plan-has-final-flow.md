---
type: regex
target: trace
match: contains
flags: i
pattern: '"name":"(?:Write|Edit)","input":\{(?:"replace_all":\w+,)?"file_path":"[^"]*/plan\.md",(?:(?!"name":")[^\n])*?\\n[#>*_\- ]{0,8}Final flow(?:(?!\\n)[^\n]){0,120}(?:\\n){1,3}```mermaid[^\n]*?"parent_tool_use_id":null'
---
