---
type: regex
target: trace
match: not_contains
flags: i
pattern: '"name":"(?:Write|Edit)","input":\{(?:"replace_all":\w+,)?"file_path":"[^"]*/plan\.md",(?:(?!"name":")[^\n])*?\\n(?:#+ )?(?:Current|Final) flow(?:(?!\\n)[^\n]){0,120}(?:\\n){1,3}```mermaid'
---
