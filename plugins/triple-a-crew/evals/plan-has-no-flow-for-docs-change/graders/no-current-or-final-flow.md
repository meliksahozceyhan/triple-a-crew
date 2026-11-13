---
type: regex
target: trace
match: not_contains
flags: i
pattern: '"name":"(?:Write|Edit)","input":\{(?:"replace_all":\w+,)?"file_path":"[^"]*/plan\.md",(?:(?!"name":")[^\n])*?(?:\\n|":")[#>*_\- ]{0,8}(?:Current|Final) flow(?!(?:(?!\\n)[^\n])*?(?:\bnone\b|\bn/a\b|not applicable|nothing))(?:\\"|(?!\\n)[^\n"]){0,120}(?:\\n){1,3}```mermaid'
---
