---
type: llm
focus: trace
---

PASS if the final report weighs at least two candidate causes for the reported bug (a cause it rules out counts), and gives each candidate both an explicit confidence (high/medium/low, a percentage, or "ruled out") and a concrete way to confirm or rule it out (a specific test, input, repro or log). Separate findings about other bugs, such as an "also noticed" list, are not candidate causes and need neither.

FAIL if only one candidate cause is weighed, or if any candidate cause lacks an explicit confidence or a concrete way to confirm it.
