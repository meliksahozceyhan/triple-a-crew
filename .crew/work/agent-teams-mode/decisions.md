# Decisions

- **2026-10-19 Opt-in team mode for every role, writers included (your choice; the organizer had
  recommended waiting, then read-only roles only).** Gain: live questions, and a reviewer can question the
  engineer directly. Because a named teammate gets no worktree, writers share the working directory, so the
  organizer adds guardrails: writers at the same time only on disjoint file sets, otherwise one at a time;
  teammates never commit; verify only after all writers finish; code changes only through tasks the organizer
  assigns. The research risks stay true: much higher token use, no `/resume` for teammates, experimental
  status, no eval coverage (a manual test replaces the eval). Rejected: read-only roles only (the
  organizer's revised proposal); waiting.
- **2026-10-19 Spawn employees without a `name` outside team mode.** With
  `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` set globally, a named `Agent` call launches a teammate; unnamed
  calls keep subagent mode predictable.
- **2026-10-19 Don't use the built-in task list.** It lives in `~/.claude/tasks/`, outside the repo, and lets
  teammates self-claim, which could hand a reviewer its own work. The board stays the only task list.
- **2026-10-19 Team-mode rules live in `skills/work/teams.md`,** loaded only when team mode is detected, so
  the organizer's SKILL.md stays short and the experimental part is easy to change or remove.
- **2026-10-19 Plan approved by the user with writers as teammates.**
- **2026-10-19 T2 done by the organizer, with the README roadmap row.** The table had to be checked against
  the docs, and the engineer has no WebFetch, so the organizer fetched the agent-teams and subagent-names
  pages and rewrote DESIGN "Two channel modes" with a sourced row each for start, employees, working
  directory, questions, task list, hooks and limits. The README roadmap gained a done `v2` row; DESIGN's v2
  phase says the same. T7 reviews this with the rest of the diff. Rejected: an engineer on T2 (a doc check it
  cannot do), a researcher plus an engineer (two hand-offs for one table).
- **2026-10-19 The docs already answer part of T3.** A plugin agent type can be a teammate; the model the
  spawn prompt names wins over the definition's; `tools` and the body apply; `skills` does not (so the
  test-engineer's `test-harden` preload won't happen as a teammate, and its fallback read is what covers
  it); a named call with `isolation` stays a subagent; `-p`, SDK and eval runs never spawn teammates. Still
  open for the live test: `maxTurns`, whether SubagentStart/SubagentStop fire for teammates, the plugin
  agents in practice, detection from a skill, and the desktop app. The test enables teams only in a scratch
  folder's `.claude/settings.local.json`, so other sessions keep subagent mode.
- **2026-10-19 T3 results (live test, `team/T3-organizer.md`).** Teams form from named calls, and a plugin
  agent's model (from the call), `tools` and body apply. Three results change the plan. (1) SubagentStart
  and SubagentStop fire for teammates, but `agent_type` is the teammate's name, so the crew matcher
  `^triple-a-crew:[a-z-]+$` skips them: no protocol reminder and no stop gate in team mode. Line 1 of a
  teammate's transcript still holds the brief (inside a `<teammate-message>` tag) with the `**Status
  file:**` line. (2) `maxTurns` does not apply to in-process teammates (the probe made 7 tool calls with
  `maxTurns: 3`). (3) Teammates share one working tree live: the researcher saw the engineer's edit mid-run
  and could not tell who made it.
- **2026-10-19 Proposed plan change (waiting for the user).** T4's teams.md adds: name each teammate after its
  status file (`T2-engineer`), tell every teammate who else runs at the same time and on which files, keep
  readers off a writer's files until it finishes, and give each brief a turn budget the organizer enforces
  (shutdown request) since `maxTurns` is gone. New T4b: the crew hooks also match those names
  (`^T[0-9]+[a-z]?-(researcher|engineer|test-engineer|verifier|reviewer)$`), with test cases for a teammate
  payload and the `<teammate-message>` wrapper. T8's manual test then checks that a teammate gets the
  reminder and that a stop-gate block keeps it working (untested so far). Rejected: gating through
  `TeammateIdle`, whose payload has no transcript path or final message; accepting team mode without the
  gate (status files would go unchecked exactly where turns are uncapped).
- **2026-10-19 Plan change approved by the user as written.** T4 gains the naming, co-worker, reader,
  turn-budget and resume rules; T4b makes the crew hooks match teammate names; T8 checks both live.
- **2026-10-19 T5 done by the organizer while T4 and T4b ran** (SKILL.md is in neither file set): step 6
  spawns with no `name`, and reads `teams.md` when `printenv CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` prints
  `1`. Two lines; SKILL.md is 156 lines.
- **2026-10-19 T4, T4b and T6 results.** T4 (sonnet): `skills/work/teams.md`, 68 lines, rules 1-11. It adds
  "ask a silent teammate once, then shut it down and re-staff", which the organizer kept. T4b (sonnet): both
  subagent matchers accept `[Tt]<n>[letter]-<role>`; the scripts needed no change; new cases in
  `test-hooks.sh` read the regex from `hooks.json`. The organizer also ran the stop hook on the real T3
  teammate payload: allowed with the status file present, blocked with the right path when it was moved
  away. T6 was done by the organizer (README "Team mode", hook wording in both READMEs and DESIGN, DESIGN's
  Verified mechanics Hooks row) since it needed T3's details. Open for T7: the lead cannot count a teammate's
  turns, so "runs well past its budget" is a judgment call.
- **2026-10-19 T7 review: changes requested** (`team/T7-reviewer.md`, git-ignored): 1 must-fix, 4 should-fix,
  7 nits, all applied by the organizer. M1: parallel writers share the tree, and the engineer runs the
  brief's verify commands, so a co-worker's half-done edit fails them; their briefs now carry no verify
  commands and an acceptance check on their own files only. S1: commits only when the user asks, as in
  subagent mode. S2: running teammates are told when another one starts. S3: the test-engineer's brief gets
  the absolute path to test-harden. S4: `test-hooks.sh` fails when an agent file is missing from the
  teammate roles (checked with a throwaway `designer` agent). Nits: no invented cost figure, "at most 5",
  "never touched" corrected, TeammateIdle is the only team hook seen live, the reminder repeats on every new
  message, a teammate with a question sets `blocked` (the stop gate runs at every idle), and the manual
  check runs before the session ends. Also from its open question: step 6 runs `printenv` only for size L,
  so M items gain no Bash call or prompt. For T8: whether `printenv` prompts in default mode, and whether it
  sees the variable set only in `settings.local.json`.
- **2026-10-19 T7b recheck: changes requested** (`team/T7b-reviewer.md`, git-ignored). Eleven of the twelve
  T7 findings were resolved; M1 only partly: a writer briefed alone kept its verify commands when a second
  writer joined (F1), a writer's own test still compiles a co-worker's files in the same package (F2), and a
  per-task reviewer ran tests mid-edit (F3). Instead of patching each case, the organizer rewrote the rule
  around one principle: nothing runs tests or verify while a writer is mid-edit. Parallel writers only on
  files that don't build or import together; no writer brief ever carries the verify commands; reviewers
  and the verifier start after every writer has finished; a check failing only in a co-worker's files is
  not a miss. Also F4 (the coverage test reads `name:` from each agent file and no longer lists a plausible
  future role among the ignored names; checked with a `designer` agent and a README in `agents/`) and F5
  (a teammate waiting on any answer, also from a co-worker, sets `blocked`; the gate's effect on teammates is
  stated as untested). Rejected: serial writers only (drops the parallelism the user chose).
- **2026-10-19 T7c recheck of the rule rewrite: ship** (`team/T7c-reviewer.md`, git-ignored). F1-F5 resolved; no
  must-fix. Its should-fixes and nits applied: every writer brief tells the writer itself to run only its
  acceptance check, even when `CLAUDE.md` asks for a full run (N1); a writer is sent back to fix a finding
  only when no reviewer or verifier is running (N2); the organizer reruns a co-worker-blocked check itself
  and sends a failure to the task whose files fail (N3); reviewers send questions to the organizer (N4);
  researchers run no tests alongside writers (N5); the coverage test accepts a quoted `name:` and fails when
  `agents/` holds no agent (N6, both probed); the organizer tells the user when an approved plan's parallel
  writers must run one at a time (N7). Not done: moving the team-mode check into step 5's planning, which
  would put team-mode text into SKILL.md for every L item; N7's note covers the gap.
