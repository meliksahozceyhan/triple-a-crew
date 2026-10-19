---
type: regex
target: trace
match: not_contains
pattern: '"name":"Bash","input":\{"command":"(?:[^"\\''|&;<>]|&(?!&)|\\"[^"]*?\\"|''[^'']*''|\\[^n"])*(?:&&|\|\||;|\||\\n|>|<)'
---
