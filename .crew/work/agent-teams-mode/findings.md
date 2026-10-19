# Findings

- 2026-10-19 · DESIGN "Two channel modes" says the team task list has file locking; the docs say locking
  covers task claiming only, not file edits · found by T1 researcher · fixed by T2 of this plan
- 2026-10-19 · In team mode the crew hooks skip teammates: SubagentStart/SubagentStop report the teammate's
  name as `agent_type`, which `^triple-a-crew:[a-z-]+$` never matches · found by T3 live test · fix proposed
  as T4b of this plan
- 2026-10-19 · The haiku researcher chained commands again as a teammate (`; echo "exit=$?"`, `| tail`) ·
  found by T3 live test · already tracked as #12
