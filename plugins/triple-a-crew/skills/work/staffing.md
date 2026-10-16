# Staffing

## Roles

| Role | Agent | Does | Default tier | Writes code |
|---|---|---|---|---|
| researcher | `triple-a-crew:researcher` | Maps code, docs and tickets; answers "where and how does X work" | standard | no |
| engineer | `triple-a-crew:engineer` | Implements one task from the plan and checks it | standard | yes |
| reviewer | `triple-a-crew:reviewer` | Fresh-context, adversarial review of a diff | critical | no |

Architect, test engineer, verifier and scribe roles come later. Until then, do that work yourself: design
options in `decisions.md`, verify commands in step 8, issues through `file-issue`.

Point employees at the crew skills' methods in their briefs:

- A researcher investigating a bug returns the report sections of the `investigate` skill (issue snapshot,
  relevant code, flow walkthrough, likely causes, next steps).
- An engineer whose task is tests follows the `test-harden` rules: the project's framework, behavior-first,
  the edge-case catalog.

## Tiers

Model choice is a rule, not a mood. Judge each task on ambiguity (is the outcome fully specified?), blast
radius (data, security, money, public API, migrations), novelty (has this codebase done it before?),
reversibility (can a mistake be undone cheaply?) and size.

| Tier | Situation | Default model |
|---|---|---|
| `mechanical` | Fully specified and reversible: a lookup, a rename, running checks, filling a template | `haiku` |
| `standard` | Implementation or investigation with a clear plan | `sonnet` |
| `critical` | Ambiguous design, high blast radius, security, review of others' work | `opus` |

A profile entry such as `models: { critical: fable }` replaces a tier's model.

## Rules

- **Escalate on failure.** A task that misses its acceptance check twice moves up one tier, with both failures
  in the new brief.
- **Separation of duties.** The agent that wrote a change never reviews it.
- **Parallel only on disjoint file sets.** Overlapping writers run in sequence, or in separate worktrees
  (`isolation: "worktree"`) with you merging.
- **Effort before tier.** For a task with many edge cases, a stronger brief with explicit cases often beats a
  bigger model. Move up a tier when the reasoning itself is hard.
- **Record the actual model** on the board. A user setting such as `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` can
  override what you asked for.
