---
type: llm
focus: trace
---

PASS if the final review attributes the rules it applies to the files they come from: the integer-cents rule to `docs/adr/0002-money-in-integer-cents.md` (or "ADR 0002"), the cursor-pagination rule to `docs/adr/0003-cursor-pagination.md` (or "ADR 0003"), and the repo.js and zod rules to `CONTRIBUTING.md`. Advice that is not a project rule may be labeled as a recommendation.

FAIL if either ADR rule is presented without naming its ADR, or if the repo.js or zod rule is attributed to the wrong file or to no file.
