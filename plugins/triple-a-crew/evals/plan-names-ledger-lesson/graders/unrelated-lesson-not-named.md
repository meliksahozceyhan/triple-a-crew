---
type: regex
target: trace
match: not_contains
pattern: '"name":"(?:Write|Edit)","input":\{(?:"replace_all":\w+,)?"file_path":"[^"]*/plan\.md",(?:(?!"name":")[^\n])*?## Lessons that apply\\n(?:(?!"name":")(?!\\n## )[^\n])*?\bL1\b'
---
