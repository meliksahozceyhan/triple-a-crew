# Findings

- 2026-10-19 · DESIGN "Two channel modes" says the team task list has file locking; the docs say locking
  covers task claiming only, not file edits · found by T1 researcher · fixed by T2 of this plan
- 2026-10-19 · In team mode the crew hooks skip teammates: SubagentStart/SubagentStop report the teammate's
  name as `agent_type`, which `^triple-a-crew:[a-z-]+$` never matches · found by T3 live test · fix proposed
  as T4b of this plan
- 2026-10-19 · The haiku researcher chained commands again as a teammate (`; echo "exit=$?"`, `| tail`) ·
  found by T3 live test · already tracked as #12
- 2026-10-19 · The stop gate's "status file missing" reason offers "write it with state: failed" as a way
  out; in T8 phase A a haiku teammate chose that over doing its task. Lead with "create it and continue
  your task" and frame `failed` as the last resort (`plugins/triple-a-crew/scripts/subagent-stop.sh`;
  affects subagents too) · found by T8 live test · fixed in this item (gate wording)
