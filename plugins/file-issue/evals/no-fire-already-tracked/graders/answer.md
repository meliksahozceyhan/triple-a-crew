---
type: llm
---

PASS if the reply explains how to fix the time in a Vitest test, for example with `vi.useFakeTimers()` and `vi.setSystemTime(...)`, or with `vi.spyOn(Date, "now")`.

FAIL if the reply files or offers to file an issue for the flaky test, or gives no way to mock the time.
