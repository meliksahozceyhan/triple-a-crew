# Retro: issue-30-criteria-check

**Closed:** 2026-10-19

## What happened
- The plan ran in its order: T1 the case, T2 the baseline before T3 the text, then a haiku verifier, an opus
  reviewer and three evals. Two changes: T2 ran twice (the one hardening the plan allowed), and T5's
  should-fixes went in before T6, so T6 tested the final text (board.md; decisions.md "T2 baseline 1",
  "T2 baseline 2", "T4 verify")
- The first fixture's brief already listed each ticket's criteria as written, which is the output the new
  step 3 asks for. The old text scored 1.00 on it: the organizer read the criteria, found #42's README gap
  and had it reviewed (decisions.md "T2 baseline 1")
- Hardened to #24's shape, with one done-when line and the criteria only in a mocked GitHub, the old text
  scored 1.00 again: Opus fetched the issues itself. The case was recorded as a guard, and the user accepted
  the deferral of "fails on the current text" (decisions.md "T2 baseline 2", "The user accepted the deferral")
- A Sonnet run of both texts is in a separate session, with no result yet (session "Test #30's eval case with
  a Sonnet organizer")
- T5 approved with 5 should-fix and 4 nits. Applying the new rule to its own diff, it found three gaps in the
  new protocol text (an accepted deferral against "none is a must-fix", `as given` lines before the PR, the
  recheck's scope) and a grader that also passed a review of the README fix alone (team/T5-reviewer.md
  findings 1-3)
- That grader had been probed on the real reviewer row and three variants (no README, a subagent row, the
  engineer role), but not on the near miss it was meant to reject (decisions.md "T2 baseline 1";
  team/T5-reviewer.md finding 3)
- Fitting the rule into 160 lines took two rewordings elsewhere in `SKILL.md`. A word diff before applying,
  and T5's own line-by-line read, found no condition dropped (team/T5-reviewer.md "Criteria")
- This session had loaded the reviewer agent before T3 changed it, so T5's brief carried the criteria rule in
  full, and the reviewer followed it (team/T5-reviewer.md "Criteria")
- Evals cost $3.52, against the plan's estimate of about $5 (decisions.md "T6 evals")

## Lessons
| # | Lesson | Evidence | Repeat of | Goes to | Status |
|---|---|---|---|---|---|
| L1 | A case for a new rule must hold back the rule's own output; the first fixture's brief already had what step 3 now produces, so the old text passed | decisions.md "T2 baseline 1" | | `README.md` "Conventions for new skills" | accepted |
| L2 | A failure seen at scale (#24: eleven tickets, reviews split by area) didn't reproduce on a small fixture with the default model; whether the case can fail on the current text wasn't settled before the text was built | decisions.md "T2 baseline 2" | retro-skill L3 | `README.md` "Conventions for new skills" | accepted |
| L3 | A regex grader probed only on variants of the passing row also passed the near miss it was meant to reject | team/T5-reviewer.md finding 3 | fix-open-issues L5 | `README.md` "Conventions for new skills" | accepted |
| L4 | The criteria-by-criteria review, applied to its own rule, found three gaps in that rule's text | team/T5-reviewer.md findings 1, 2, 7 | follow-ups-25-28 L3 | `retro.md` only (#30 made it the rule) | kept |
| L5 | An agent file changed mid-session isn't reloaded, so the brief for that role carried the new rule in full | team/T5-reviewer.md | the `/reload-plugins` note in `.crew/profile.md` | `retro.md` only (the profile note covers it) | kept |

## Proposed text
- **L1** (`README.md`, "Conventions for new skills", end of the "Earn the place" bullet): "A case for a new
  rule must hold back the rule's own output: `flags-unmet-ticket-criterion` first gave the organizer a brief
  that already listed each ticket's criteria, which is what the new rule produces, and the old text passed."
- **L2** (same bullet, after L1): "A failure seen at scale or on another model may not reproduce on a small
  fixture with the default model. Before writing the text, settle whether the case can fail on the current
  text; if it can't, say up front that the case will be a guard, or plan the run on a weaker organizer model.
  #30 came from eleven tickets in #24, and its case passed on the old text twice."
- **L3** (`README.md`, "Conventions for new skills", end of the "Graders match what you mean" bullet): "Also
  try the near miss the grader must reject: `whole-diff-review` passed a reviewer briefed on the README fix
  alone, until it also required another ticket's id."
