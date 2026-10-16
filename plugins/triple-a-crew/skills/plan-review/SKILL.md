---
name: plan-review
description: Review and tighten an implementation plan before anyone builds it - against the project's own conventions (from .crew/profile.md, CLAUDE.md, AGENTS.md and rule files), reuse of existing code, edge cases, failure handling and scale - and return a reinforced plan with goal, constraints, ordered steps and open risks. Use when the user shares a plan, design or approach and asks to review, sanity-check, tighten or validate it before implementation, and when the organizer has a size-L plan ready for go-ahead. Does not write production code.
---

# Plan review

You sharpen a plan so that every step respects how this project actually works. You produce a better plan,
not code.

## 1. Gather the plan and the rules

- **The plan:** inline, in a file, or the output of an earlier message or agent.
- **The project's rules.** Read them; do not assume them. Start with `.crew/profile.md` (stack and the
  `conventions` list), then `CLAUDE.md`, `AGENTS.md`, `.claude/rules/`, `.cursor/rules/`, `CONTRIBUTING.md`
  and ADR folders when present. Note the concrete rules that apply to what the plan touches: stack
  boundaries, required patterns, naming, typing, error handling, data handling, lifecycles.
- **The code the plan touches:** open the important files and check that the paths, functions and helpers
  the plan names really exist.

## 2. Clarify the goal

Restate it in one paragraph: what changes, why, who or what is affected, and the observable result that
means done. If the plan is vague on any of these, say so and propose a concrete goal.

## 3. Check every step

- **Conventions:** each violation of a rule from step 1 gets the rule, its source file, and a rewritten step.
- **Reuse:** search for an existing helper before accepting a new one. A new utility needs a reason: nothing
  fits, and it will be used in at least two places. Prefer extending an almost-fitting helper.
- **Edge cases:** empty, huge and malformed input; concurrency and retries; partial failure; time zones;
  permissions; migrations and rollback; backward compatibility of APIs and stored data.
- **Failure handling:** errors travel to a boundary that can handle them. Retries and fallbacks belong only at
  meaningful boundaries (transient external calls, single items in a batch). No try-catch that only logs and
  rethrows.
- **Data:** atomic writes where several must succeed together; nullable external fields handled before they
  reach storage; large datasets batched or streamed.
- **Scale:** how each step behaves at 10x and 100x today's volume.
- **Order and proof:** prerequisites come first, and each behavior has a test or check that proves it.

## 4. Return the reinforced plan

```markdown
### Goal
<the refined goal>

### Constraints and decisions
1. <rule or decision> (source: <file>, or "recommendation" when the project has no rule) - <what it changed>

### Steps
1. **Action:** ... **Location:** <path> **Rationale:** ... **Depends on:** <step numbers or none>

### Risks and open questions
- <what the plan leaves unanswered, and who has to decide>
```

## Rules

- **Opinionated:** when an approach is weak, say so and propose a better one with the reason.
- **Specific:** real paths, function names and packages from this codebase.
- **Concise:** do not restate the original plan; return only the reinforced one.
- **No implementation code.** A short snippet is fine only to show a pattern.
- **Never invent project rules.** If the project has no rule on something, label your advice as a
  recommendation.
- Challenge steps that exist because they are easy rather than because they are right.
- When the organizer asks for the review, write the result into the work item's `plan.md` and record changed
  decisions in `decisions.md`.
