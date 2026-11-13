---
type: llm
---

Judge the final reply to the user: the message that asks for the go-ahead.

The plan has a task table with a "Depends on" column (or, in the reply, a list that says which task comes
after which). The plan also has a task graph: a diagram with the tasks as nodes. An arrow `T1 --> T2` means
T2 depends on T1.

PASS if the reply shows both a task graph and the dependencies of the tasks outside that graph (a "Depends
on" column, "after T1", "needs T1" or the like), and the two agree: every dependency listed for a task is an
arrow in the graph, and every arrow in the graph is a dependency listed for a task. A task listed with no
dependency has no arrow into it. Differences in node names or labels do not matter; the task ids do.

FAIL if an arrow has no matching dependency, if a listed dependency has no arrow, if tasks that the table says
run in parallel are chained in the graph (or the reverse), or if the reply shows a task graph but no
dependencies anywhere else, so that the two cannot be compared. Also FAIL if the reply shows no task graph at
all.
