# Check each closed ticket's acceptance criteria before the PR

**Size:** M · **Tickets:** #30 · **Opened:** 2026-10-19

## What
#30: when a work item closes several tickets and its reviews are split by task or area, no one checks each
ticket's acceptance criteria against the whole result. #24 closed #17, #18 and #22 with criteria unmet, and it
took `review-24-fixes` (PR #29) to fix them. Two gaps, both in the organizer's text today:
- Step 3 asks for "done-when (acceptance criteria)", but not for each ticket's criteria as written. The #24
  brief had one line for eleven tickets: "Every issue's acceptance criteria hold".
- Step 8 staffs a reviewer "per task for size L"; no review covers the whole diff against the brief, and
  nothing says a ticket with an unmet criterion must not be closed by the PR.

## Why
The per-criterion check works when it's done: in `follow-ups-25-28` the reviewer checked #25-#28 one criterion
at a time and found a contradiction the organizer had missed (its retro L3). It should be the rule, not luck.

## Done when
- [ ] #30.1, as written: "The organizer's step 8 or 10 says how closed issues' acceptance criteria are checked
      before the PR."
- [ ] #30.2, as written: "A PR that closes an issue whose criterion has no evidence is flagged before it is
      opened." Shown by a new eval case that fails on the current text and scores 1.00 on the new one.
- [ ] Step 3 has the brief list each ticket's acceptance criteria as written.
- [ ] Profile verify passes; `SKILL.md` stays at most 160 lines with no earlier condition dropped; a reviewer
      approves after checking each line above with evidence; `medium-fix-end-to-end` still scores 1.00.

## Constraints
- README "Conventions for new skills": earn the place (the new case must fail on the current text), one eval
  case per key rule, a fixture that agrees with its own work item, graders tested on real trace rows, run
  every command example.
- Evals: `--runs 1 --ablation none`, `"Bash(date *)"` in `--allow-tools`, `--keep-temp` where a grader
  approximates; report the cost. Fixtures run only in `mktemp -d`.
- `SKILL.md` budget 160 lines: details go to `protocol.md` and the reviewer agent. Trimming must not drop a
  condition (review-24-fixes L2).
- Subagent mode and team mode (`teams.md`) both keep working.

## Edge cases
| Case | In scope? | Covered by |
|---|---|---|
| An item with no ticket | yes | the same check runs on the brief's done-when lines |
| A ticket with no "Acceptance criteria" section | yes | the brief writes the criteria it derives and marks them derived; the user sees them at the go-ahead (L) or in the report (M) |
| A criterion only a later step can show (an eval score, a live test, the user's own test) | yes | the review marks it pending with the task that will show it; the organizer adds the evidence before the PR |
| Evidence the reviewer took from someone else, unchecked | yes | marked "as given" in its table, never counted as checked |
| A ticket the item only partly fixes | yes | the PR says `Refs #N`, not `Closes #N`, with the open criteria named |
| A ticket whose every criterion has evidence | yes | stays `Closes #N`; the case checks this so a blanket "Refs" fails |
| A recheck after fixes (step 8) | yes | the recheck covers the criteria the first review left without evidence |
| Size L with per-task reviews | yes | the last review covers the whole diff against every done-when line |
| Team mode (`teams.md`) | yes | the rule is in step 8 and the reviewer agent, which teammates also read; T4 checks `teams.md` for a conflict |
| The organizer opening the PR itself | no | the organizer reports and the user (or the session) opens the PR; unchanged |
