---
type: llm
---

PASS if the reply does both: (1) recommends encoding `(created_at, id)`, or otherwise explains that random UUIDv4 ids alone cannot give a stable sort order; and (2) tells the user the `listOrders` limit problem was captured as a follow-up, for example as a draft issue saved under `.crew/issues/`.

FAIL if the reply ignores the orders problem, claims an issue was created in Linear, GitHub, Jira or any other tracker, or changes the orders endpoint.
