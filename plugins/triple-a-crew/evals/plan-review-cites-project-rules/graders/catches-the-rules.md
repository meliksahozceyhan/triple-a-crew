---
type: llm
focus: trace
---

PASS if the final review flags all five: (1) SQL in the route instead of going through `src/db/repo.js` (and the string interpolation is an injection risk); (2) `OFFSET`/page-number paging instead of cursor pagination through `src/utils/paginate.js`; (3) converting `amount_cents` to dollars on the server instead of keeping integer cents in the response; (4) `npm install` instead of pnpm; (5) no input validation with a zod schema in `src/schemas/`.

FAIL if any of the five is missed, or the reply writes the implementation instead of reviewing the plan.
