# Remaining employees: architect, test engineer, verifier, scribe

**Size:** L · **Ticket:** none (roadmap, W2 of the v1 handoff) · **Opened:** 2026-10-19

## What
The design (`docs/DESIGN.md`, "Employees") names seven roles; three exist (`researcher`, `engineer`,
`reviewer`). Decide for each of the other four whether it earns a place, and plan the ones that do:

- **architect:** options and trade-offs for ambiguous or cross-cutting work (opus, read-only).
- **test engineer:** finds missing high-risk cases and adds tests (sonnet, edit and bash).
- **verifier:** runs the profile's verify commands and reports facts, never fixes (haiku, bash).
- **scribe:** issues, handoffs, PR text, status reports (haiku, write).

## Why
`staffing.md` says "Architect, test engineer, verifier and scribe roles come later. Until then, do that work
yourself." The organizer does all four jobs in the main session today. A role is worth adding only if it
changes model, tools or protocol in a way that pays (DESIGN: "Roles stay few"), and W1 showed that pieces
plain Claude already does well get cut (README "Earn the place").

## Done when
- [ ] Each of the four roles is built, folded into an existing role, or dropped, with the reason in
      `decisions.md`.
- [ ] Each built role has an agent file under `plugins/triple-a-crew/agents/`, a row in `staffing.md`, a
      place in the organizer's steps, and at least one eval case.
- [ ] `claude plugin validate .` passes; the organizer suite and the new cases score 1.00 at `--runs 1`.
- [ ] READMEs and DESIGN list the roles that ship.

## Constraints
- Conventions (profile): README "Conventions for new skills", `docs/DESIGN.md` (Employees, Staffing policy,
  Communication protocol).
- Employees never spawn agents, never file issues, never write under `.claude/`, and write only their status
  file plus, for writers, their file set.
- Model aliases only (`haiku`, `sonnet`, `opus`); the profile's `models:` overrides a tier.
- Evals cost real usage: `--runs 1`, report the cost.

## Edge cases
| Case | In scope? | Covered by |
|---|---|---|
| A new agent's description makes Claude pick it for an ordinary user request | yes | each agent keeps "Use only when the organizer briefs it" |
| Verifier on haiku reports "passed" when a command failed | yes | verifier quotes exit codes and failing lines verbatim; eval with one failing command |
| Verify commands need secrets or live services | yes | verifier runs only the profile's `verify` list and reports a missing service as a fact |
| Huge test output floods the organizer's context | yes | verifier returns a condensed report; the reason the role exists |
| Test engineer writes tests for code it wrote itself | yes | staffing rule: tests come from a different employee than the code |
| Test engineer adds a second test framework | yes | it follows `test-harden` (project framework only) |
| Scribe drafts an issue it cannot confirm (subagents cannot ask the user) | yes | decision on scribe |
| Architect duplicates what the organizer (often opus) already reasons about | yes | decision on architect |
| `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` overrides the tier | no, already handled | board records the actual model |
