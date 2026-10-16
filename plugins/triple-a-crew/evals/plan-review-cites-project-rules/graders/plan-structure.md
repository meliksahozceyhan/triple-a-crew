---
type: llm
focus: trace
---

PASS if the final review returns a rewritten plan with all four parts, under any headings: (a) a stated goal with an observable done condition; (b) a list of constraints or decisions, each naming its source; (c) numbered steps where every step states which earlier steps it depends on (or "none"), and every step that changes code names the file or location it touches; (d) a list of risks or open questions.

FAIL if any of the four parts is missing, if any step lacks a stated dependency, or if a step that changes code names no location.
