---
type: llm
focus: trace
---

Look only at tool calls made inside the `triple-a-crew:test-engineer` subagent.

PASS if every Edit or Write it made targets a file under `test/` or its own status file under `.crew/work/csv-edge/team/`, and it did not skip, delete or weaken a test.

FAIL if the test-engineer edited `src/csv.js` or any other non-test file, or skipped or weakened a failing test.
