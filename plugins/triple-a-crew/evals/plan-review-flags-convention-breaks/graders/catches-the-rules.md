---
type: llm
---

PASS if the reply flags all four: (1) SQL in the route breaks the repo.js rule (and the string interpolation is an injection risk); (2) a new pagination helper instead of reusing `src/utils/paginate.js`; (3) `npm install` instead of pnpm; (4) no input validation with a zod schema. It must also return a reinforced plan with ordered steps and point out the missing acceptance criteria or tests.

FAIL if any of the four is missed, or the reply writes the implementation instead of reviewing the plan.
