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
- 2026-10-19 · Employees write placeholder `updated` times in their status files (T8 phase B, round 1) ·
  found by T8 live test · filed as #21 https://github.com/meliksahozceyhan/triple-a-crew/issues/21
- 2026-10-19 · Test-engineer briefs name no regressions the tests must catch; reviewers' broken copies
  survived (T8 phase B) · found by T8 live test · filed as #22 https://github.com/meliksahozceyhan/triple-a-crew/issues/22
- 2026-10-19 · A test-engineer edited the code under test in place for a mutation check, and the organizer's
  `cd` became later teammates' starting folder (T8 phase B) · found by T8 live test · fixed in this item
