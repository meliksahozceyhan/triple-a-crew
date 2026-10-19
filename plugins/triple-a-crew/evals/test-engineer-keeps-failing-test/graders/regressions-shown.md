---
type: regex
target: trace
match: contains
pattern: '(?:"name":"Bash","input":\{"command":"node --test(?: --[^ "]+)* (?:\\?"?\$\{?TMPDIR|\\?"?/(?![^"]*/home/cwd[/"\\]))[^\n]*"subagent_type":"triple-a-crew:test-engineer"[\s\S]*?){4}'
---
