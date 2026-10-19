---
type: llm
---

The request asks for: streaming rows instead of one big string, RFC 4180 quoting in both the header and the
rows, a `since` date filter, a format that stays compatible with the mobile app's parser, and tests.

PASS if, where the reply asks for the go-ahead, it shows for each of those outcomes which task meets it, or
says that outcome is deferred (a table or a list is fine). Mobile-app compatibility must be covered or
deferred by name.

FAIL if the reply asks for the go-ahead with only a task list that doesn't map tasks to those outcomes, or if
any of them, mobile-app compatibility in particular, is neither covered nor named as deferred.
