---
type: regex
target: trace
match: not_contains
flags: i
pattern: '"name":"(?:Write|Edit)","input":\{(?:"replace_all":\w+,)?"file_path":"[^"]*/plan\.md",(?:(?!"name":")[^\n])*?## Lessons that apply(?=\\n)(?:(?!"name":")(?!\\n## )[^\n])*?(?:(?:\\n|[^\w\n])L1\b|machine.s locale|export test)'
---
