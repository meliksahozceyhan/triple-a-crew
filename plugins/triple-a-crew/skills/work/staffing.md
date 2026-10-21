# Staffing

## Roles

| Role | Agent | Does | Default tier | Writes code |
|---|---|---|---|---|
| researcher | `triple-a-crew:researcher` | Maps code, docs and tickets; answers "where and how does X work" | standard | no |
| engineer | `triple-a-crew:engineer` | Implements one task from the plan and checks it | standard | yes |
| test-engineer | `triple-a-crew:test-engineer` | Writes the tests for a task, never production code | standard | tests only |
| verifier | `triple-a-crew:verifier` | Runs the profile's verify commands and reports exact results | mechanical | no |
| reviewer | `triple-a-crew:reviewer` | Fresh-context, adversarial review of a diff | critical | no |

There is no separate architect: design questions go to a researcher at critical tier, which returns its
design-question report. There is no scribe: issues go through `file-issue`, handoffs through the `handoff`
skill, and PR text stays with you, because you have the conversation.

Point employees at the crew's methods in their briefs:

- A researcher investigating a bug returns ranked likely causes (the format is in its agent file). Paste the
  report and all its comments into the brief: researchers have no tracker connectors.
- Test tasks go to the test-engineer, which has the `test-harden` rules preloaded. For risky work, list 3-5
  concrete regressions in its brief under "Regressions to catch" (protocol.md).
- A design question goes to a researcher at critical tier.

## Tiers

Model choice is a rule, not a mood. Judge each task on ambiguity (is the outcome fully specified?), blast
radius (data, security, money, public API including a file format another system consumes, migrations),
novelty (has this codebase done it before?), reversibility (can a mistake be undone cheaply?) and size.

| Tier | Situation | Default model | Effort (ceiling) |
|---|---|---|---|
| `mechanical` | Fully specified and reversible: a lookup, a rename, running checks, filling a template | `haiku` | `low` (`medium`) |
| `standard` | Implementation or investigation with a clear plan | `sonnet` | `medium` (`high`) |
| `critical` | Ambiguous design, high blast radius, security, review of others' work | `opus` | `high` (`xhigh`) |

Pass both at spawn: `model: <alias>` and `effort: <level>`; each agent file carries its role's default, and the
spawn value wins. A profile entry such as `models: { critical: fable }` replaces a tier's model. Effort steps
are `low → medium → high → xhigh`; the ladder below stops at a tier's ceiling and never climbs to `max`.

## Rules

- **The ladder.** A miss is a failed acceptance check, or a verify failure or reviewer must-fix traced to the
  task. Not a miss: a `flaky` verify result, a `blocked` question (answer it and resume), or a test-engineer's
  failing test that exposes a bug in the code (the defect goes to the code task). One rung per miss:
  1. send the same employee back once with what is missing (`SendMessage`; it keeps its context);
  2. re-staff at the same tier with effort one step up, as `<task>b-<role>` with its own status file;
  3. re-staff one tier up at that tier's default effort, as the next letter (`<task>c-<role>`);
  4. ask the user.
  Skip a rung with nowhere to go (effort already at the tier's ceiling; no tier above critical). Every re-staff
  brief carries every earlier failure verbatim (protocol.md), and the board gets one row per attempt
  (formats.md). The review recheck in SKILL.md step 8 is a loop over reviewers, not over this ladder: a
  must-fix traced to a task is that task's miss and climbs here, but when a recheck asks again, step 8 decides
  first (a size-S fix you make yourself; a bigger one goes to the user) before any further rung.
- **Separation of duties.** The agent that wrote a change never reviews it. For size L, the independent tests
  for a code task (edge cases beyond its own acceptance check) go to the test-engineer, not the engineer who
  wrote the code; engineers still add the tests their own acceptance check needs. A test task depends on the
  code task it tests.
- **Parallel only on disjoint file sets.** Overlapping writers run in sequence, or in separate worktrees
  (`isolation: "worktree"`) with you merging.
- **Effort before tier.** For a task with many edge cases, a stronger brief with explicit cases often beats a
  bigger model, and the ladder raises effort before the model for the same reason. Move up a tier when the
  reasoning itself is hard.
- **Record the actual model and effort** on the board. A user setting such as
  `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` can override the model you asked for; record what ran, and a tier up
  as both asked and run.
