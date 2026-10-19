---
type: regex
target: trace
match: not_contains
pattern: '"name":"(?:Write|Edit)","input":\{(?:"replace_all":\w+,)?"file_path":"[^"]*/team/[^"]*",[^\n]*?updated: \d{4}-\d\d-\d\d(?:T00:00:00Z|T\d\d:\d\d(?![:\d]))'
---
