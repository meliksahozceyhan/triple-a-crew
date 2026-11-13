---
type: llm
---

Judge the final reply to the user: the message that asks for the go-ahead.

The request changes how the orders export runs: today the route loads every order, builds the whole file as
one string, then sends it; it must stream the rows instead.

PASS if the reply shows all three of these as diagrams (Mermaid or an equivalent drawing, not only prose):

1. A task graph: the plan's tasks (T1, T2, ...) as nodes, with arrows between them.
2. The current flow of the export, drawn from how it runs today (load all orders, build the string, send it,
   or the same steps in other words).
3. The final flow of the export after the change, in which the new or changed nodes are marked (a colour, a
   class, a legend, "new" or "changed" labels). The marking must single out some nodes; a legend that marks
   every node, or a final flow with no marks, does not count.

FAIL if any of the three is missing, if the current flow and the final flow are one and the same drawing, or
if the reply only describes the flow in sentences. A task graph alone, without the current and final flow, is
a FAIL.
