# Plan

Approved direction (2026-10-19): an **opt-in team mode for every role**. When agent teams are on and the
session is interactive, employees join as teammates who can message the organizer and each other, writers
included. Teammates share the main working directory (a named teammate gets no worktree), so writers need
guardrails: disjoint file sets for writers running at the same time, otherwise one at a time; teammates never
commit (the organizer does); verify runs only after every writer on the work item has finished; a reviewer
may ask an engineer questions directly, but code changes only come from tasks the organizer assigns.
`.crew/work/` files stay the source of truth; subagent mode is unchanged and remains the fallback.

| Task | Goal | File set | Acceptance check | Role | Tier | Depends on |
|---|---|---|---|---|---|---|
| T1 | Research how agent teams work today | read only | done: team/T1-researcher.md | researcher | standard | - |
| T2 | Correct DESIGN "Two channel modes": interactive only; no create-team step (a named `Agent` call becomes a teammate); file locking covers task claiming only; no `/resume` for teammates; a named call with `isolation` runs as a subagent; `skills` not applied to teammates; 3-5 teammates | docs/DESIGN.md | table matches the docs, each row sourced | engineer | mechanical | T1 |
| T3 | Live spike, in an interactive session you start with `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`: spawn a `triple-a-crew:researcher` and a `triple-a-crew:engineer` teammate on named models (the engineer edits one file in a scratch repo); confirm the plugin agent type resolves, the model and `tools` apply, `maxTurns` applies, how a skill can detect team mode (the env var from Bash), whether SubagentStart/SubagentStop hooks fire for teammates (crew-hooks), and whether the desktop app supports teams | scratch repo | findings with evidence in team/T3-*.md | user + organizer | standard | T1 |
| T4 | `skills/work/teams.md`, read only when team mode is detected: detection; every role may be a teammate; the writer guardrails above; spawn with `name: <task>-<role>` (the status file's stem, e.g. `T2-engineer`), the plugin agent type and the model on the call, never `isolation`; every brief names the teammates running at the same time and their files; readers stay off a writer's files until it finishes; a turn budget per brief, enforced with a shutdown request (`maxTurns` does not apply); questions by message to the organizer, still recorded in the status file; no built-in task list (the board stays the only one, and no self-claiming means a writer never picks up its own review); after `/resume`, re-staff unfinished tasks; fall back to subagents on any doubt | plugins/triple-a-crew/skills/work/teams.md (new) | under ~80 lines; every rule traces to T1, T3 or the guardrails | engineer | standard | T3 |
| T4b | The crew hooks also match teammates, whose `agent_type` is their name: SubagentStart and SubagentStop matchers accept `[Tt]<n>[a-z]?-<role>` as well as `triple-a-crew:<role>`; the scripts handle a teammate payload and a brief wrapped in `<teammate-message>` | plugins/triple-a-crew/hooks/hooks.json, plugins/triple-a-crew/scripts/ | `sh plugins/triple-a-crew/scripts/test-hooks.sh` passes under sh and dash with new teammate cases; `claude plugin validate .` passes | engineer | standard | T3 |
| T5 | Organizer step 6: employees are spawned without a `name` (so they stay subagents) unless team mode is detected, then follow teams.md | plugins/triple-a-crew/skills/work/SKILL.md | one or two lines; organizer suite still 1.00 | engineer | mechanical | T4 |
| T6 | Docs: README (how to turn it on, what changes, cost warning), DESIGN "Two channel modes" for the thin mode, and the manual test from T3 as a repeatable check | README.md, plugins/triple-a-crew/README.md, docs/DESIGN.md | a reader can enable and test it | engineer | mechanical | T4, T4b |
| T7 | Review the full diff | read only | verdict + findings | reviewer | critical | T4b, T5, T6 |
| T8 | Organizer suite at --runs 1 (subagent mode unchanged), plus the T3 manual test repeated with the final text, now also checking that a crew teammate gets the protocol reminder and that a stop-gate block keeps it working | read only | suite 1.00; manual test passes | organizer + user | mechanical | T7 |

T2 can go first on its own. T3 needs you to start a session with teams enabled. T4 and T4b run in
parallel (disjoint files); T5 follows T4; T6 follows T4 and T4b.
