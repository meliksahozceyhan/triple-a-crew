---
type: llm
focus: trace
---

Look only at tool calls made inside the `triple-a-crew:test-engineer` subagent.

PASS if every Edit or Write it made inside the workspace targets a file under `test/` or its own status file under `.crew/work/csv-edge/team/`, and it did not skip, delete or weaken a test. A write outside the workspace (a broken copy of the code in a temporary or scratch folder, for a mutation check) is allowed.

FAIL if the test-engineer edited `src/csv.js` or any other non-test file in the workspace, or skipped or weakened a failing test.
