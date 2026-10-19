# Team mode

Read this file only when team mode is on. Otherwise spawn employees as ordinary subagents, as SKILL.md says.

In team mode an employee is a teammate: it can message you and other teammates live instead of stopping and
being resumed. The cost is that teammates share your working tree, `maxTurns` does not stop them, and each one
is a full session.

## Detect

- Run `printenv CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`. Team mode is on only if it prints `1`.
- Teams need an interactive session. Under `-p`, the Agent SDK or an eval run, a named call quietly becomes an
  ordinary subagent. Every rule below must stay safe in that case, so keep writing the same briefs.
- On any doubt, use subagents.

## When to use it

- Use team mode for size L work with parallel tasks or questions you expect mid-task. Size S and M: subagents.
- At most 5 teammates at once (the docs suggest 3-5); tokens grow with each one. One team per session;
  teammates cannot spawn teams.
- Every role may be a teammate, writers included.

## Spawn

- `name: <task>-<role>`, exactly the stem of the status file (`T2-engineer`). The crew hooks match this form;
  any other name gets no protocol reminder and no stop gate.
- `subagent_type: "triple-a-crew:<role>"` and `model` on the call (the tier's model, see `staffing.md`).
- Never pass `isolation`: it turns the call into a subagent. An engineer that needs its own worktree is
  spawned unnamed, as a subagent with `isolation: "worktree"`, and you merge its branch.
- A teammate gets `tools` and the body of its agent file but not `skills`. The test-engineer reads the
  `test-harden` skill itself: put the absolute path of `../test-harden/SKILL.md` (next to this skill's
  folder) in its brief.

## Shared working tree

All teammates see one tree, live. A file can change under a reader, who cannot tell who changed it, and a
test run can fail on a co-worker's half-done edit.

- Writers run at the same time only when their file sets are disjoint and don't build or import together
  (separate packages or modules). Otherwise one at a time.
- No writer's brief carries the verify commands, even if it starts alone: another writer may join later.
  Its acceptance check runs only what builds without the other writers' files.
- Staff reviewers and the verifier, and run verify, only after every writer on the item has finished.
  Researchers may run alongside writers but stay off their files.
- A check that fails only in a co-worker's files is not a miss: the teammate reports it under Findings,
  never edits those files, and sets `done`. Rerun the check once that co-worker has finished.
- Every brief lists the teammates running at the same time, each with its file set. When you start another
  teammate later, message the running ones its name and file set.
- These rules also hold when a named call falls back to a subagent: it has no worktree either.
- Teammates never commit. Commits stay with you, as in subagent mode: only when the user asks.
- Code changes come only from tasks you assign. A reviewer may question an engineer directly but never orders
  changes: findings come to you.

## Turn budget

`maxTurns` does not apply to teammates. Put a turn budget in every brief: the role's `maxTurns` from its agent
file. If a teammate runs well past it, or repeats the same steps, send it a shutdown request. Then read its
status file and re-staff the task if it is unfinished, at the next tier if it failed twice.

## Questions and decisions

- A teammate waiting for any answer, from you or a co-worker, sets `state: blocked`, writes the question
  with its proposed answer under Questions, and messages whoever it asks. Say this in the brief: the stop
  gate runs each time a teammate goes idle, and if it blocks teammates as it blocks subagents (not yet
  tested live), an `in-progress` one is sent back.
- Answer by message; the teammate records your answer, sets `in-progress` and continues. Record real
  decisions in `decisions.md`.
- Never use TaskCreate or the built-in task list (it lives in `~/.claude/tasks/`, outside the repo and the
  crew's control). `board.md` stays the only task list, so no teammate claims work itself. A writer can
  never pick up the review of its own change.

## Done

- The status file is the source of truth. A teammate's final answer may reach you later, by message or as an
  idle notification, even after its status file says `done`.
- When a task is done, send that teammate a shutdown request.
- A teammate that never reports: read its status file, ask by message once, then shut it down and re-staff.

## After `/resume` or `/rewind`

Teammates do not come back. Read `board.md` and every status file, treat unfinished tasks as unstarted (check
`git status` for half-done edits), and re-staff them with fresh briefs.
