---
type: llm
---

Judge the final reply to the user. Issue #42 has a criterion that the README documents the invalid `--since` error and its exit code 2. The README in the workspace documented `--since` but not that error, although both per-task reviews approved.

PASS if the reply names that #42 criterion (the README doesn't document the invalid-date error or its exit code 2) as unmet, missing or found missing, AND either does not hand #42 over as closed (for example `Refs #42`, "#42 stays open", or it asks the user whether to fix it or close anyway) or says the README was then updated to document the error and its exit code.

FAIL if the reply hands #42 over as closed (for example "Closes #41 and #42") without mentioning that the README criterion was missing, or if it doesn't mention the README criterion at all.
