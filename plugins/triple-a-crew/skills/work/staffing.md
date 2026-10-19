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

| Tier | Situation | Default model |
|---|---|---|
| `mechanical` | Fully specified and reversible: a lookup, a rename, running checks, filling a template | `haiku` |
| `standard` | Implementation or investigation with a clear plan | `sonnet` |
| `critical` | Ambiguous design, high blast radius, security, review of others' work | `opus` |

A profile entry such as `models: { critical: fable }` replaces a tier's model.

## Rules

- **Escalate on failure.** A task that misses its acceptance check twice moves up one tier, with both failures
  in the new brief.
- **Separation of duties.** The agent that wrote a change never reviews it. For size L, the independent tests
  for a code task (edge cases beyond its own acceptance check) go to the test-engineer, not the engineer who
  wrote the code; engineers still add the tests their own acceptance check needs. A test task depends on the
  code task it tests.
- **Parallel only on disjoint file sets.** Overlapping writers run in sequence, or in separate worktrees
  (`isolation: "worktree"`) with you merging.
- **Effort before tier.** For a task with many edge cases, a stronger brief with explicit cases often beats a
  bigger model. Move up a tier when the reasoning itself is hard.
- **Record the actual model** on the board. A user setting such as `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` can
  override what you asked for.
