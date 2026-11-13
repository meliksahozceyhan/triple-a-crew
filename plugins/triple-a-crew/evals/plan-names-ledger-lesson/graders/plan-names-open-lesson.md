---
type: regex
target: trace
match: contains
flags: i
pattern: '"name":"(?:Write|Edit)","input":\{(?:"replace_all":\w+,)?"file_path":"[^"]*/plan\.md",(?:(?!"name":")[^\n])*?## Lessons that apply(?=\\n)(?:(?!"name":")(?!\\n## )[^\n])*?(?:(?:\\n|[^\w\n])L2\b|parameter store)[^\n]*?"parent_tool_use_id":null'
---
