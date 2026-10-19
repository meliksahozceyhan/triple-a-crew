---
type: regex
target: trace
match: contains
pattern: '"name":"(?:Write|Edit)","input":\{(?:"replace_all":\w+,)?"file_path":"[^"]*/decisions\.md"[^\n]*(?:0003-cursor-pagination|adr/0003)'
---
