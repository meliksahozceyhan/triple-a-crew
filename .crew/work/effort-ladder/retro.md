# Retro: effort-ladder

**Closed:** 2026-10-21

## What happened
- The plan ran in its order with two additions the organizer's step 8 asked for: after T5 requested changes,
  verify was rerun (T7, verifier) and a fresh reviewer rechecked the fix diff (T8). T8 asked again for one
  clause; it was size S, so the organizer made it and reran verify itself, no third reviewer (board.md;
  decisions.md "T7 verify rerun")
- The baseline (T2) failed as designed, 0.67: the old text re-staffed the twice-missed task one tier up, an
  opus engineer with no `effort`. It also already named `T1b`, pasted the failing output into the brief and
  wrote a `T1b` board row, so four of six graders passed on the old text and stay as guards (decisions.md
  "T2 baseline")
- The first eval launch failed to load: the prompt's `description:` had a colon followed by a space, which
  YAML reads as a mapping; reworded (decisions.md "T2 baseline")
- T1 probed the five regex graders on real rows and on built variants and recorded that every near miss
  failed the grader aimed at it. T5 showed that was wrong for two: `failures-in-brief` matched on the Agent
  call's `description` field ("T1b: fix CSV line-break quoting"), and `board-records-attempt` on a `T1b`
  mention in T1's own row. The built variants had added the wanted text to a reviewer row instead of removing
  it from a real passing row (team/T5-reviewer.md must-fix 1, should-fix 3; decisions.md "T1 done")
- The rule drifted between files inside one change: step 8's new "as a miss" clause made a test-engineer's
  failing test a miss while step 7 and `staffing.md` said it isn't; `staffing.md`'s recheck sentence then
  disagreed with step 8's size-S rule. The organizer had grepped for the old wording, not for the words the
  new rule hinges on (team/T5-reviewer.md must-fix 2, should-fix 4; team/T8-reviewer.md finding 1)
- The first real uses of `effort` at spawn happened in this item: the verifiers at `low`, the reviewers at
  `high`; the new case's trace shows both values reaching the Agent call (decisions.md "T6")
- The T7 verifier (haiku, effort low) said its last `updated` time was "set by hand, not from a fresh
  `date -u` call" (findings.md)
- Evals cost $4.04 against the plan's $3.70; the two extra review rounds cost tokens, not eval money
  (decisions.md "T6 done")

## Lessons
| # | Lesson | Evidence | Repeat of | Goes to | Status |
|---|---|---|---|---|---|
| L1 | A regex on an Agent row also sees the call's `description`; a near miss built by adding text to another row proves nothing, it has to be the real passing row with the wanted text removed | team/T5-reviewer.md must-fix 1, should-fix 3 | issue-30 L3 | `README.md` "Conventions for new skills" | accepted |
| L2 | When a rule is added, the other files drift on the words it hinges on (`miss`, `recheck`), not on the old wording the grep looked for | team/T5-reviewer.md must-fix 2, should-fix 4; team/T8-reviewer.md finding 1 | follow-ups-25-28 L4 | `.crew/profile.md` note | accepted |
| L3 | A `description:` with a colon and a space fails the case's YAML frontmatter and costs a launch | decisions.md "T2 baseline" | | `README.md` Troubleshooting | accepted |
| L4 | A haiku employee wrote its `updated` time by hand and said so; the text rule alone still doesn't hold | findings.md; team/T7-verifier.md "Evidence" | follow-ups-25-28 L1, agent-teams-mode L4, fix-open-issues | https://github.com/meliksahozceyhan/triple-a-crew/issues/32#issuecomment-6310845581 | filed |
| L5 | Step 8's recheck loop ended as written: a second recheck's size-S fix went to the organizer, with no third reviewer | decisions.md "T7 verify rerun" | | `retro.md` only | kept |

## Proposed text
- **L1** (`README.md`, "Conventions for new skills", end of the "Graders match what you mean" bullet): "A regex
  on an Agent row also sees the call's `description`, so a keyword there passes a grader meant for the brief.
  Build the near miss from the real passing row with the wanted text removed, not by adding the text to some
  other row: `failures-in-brief` first matched on the description alone."
- **L2** (`.crew/profile.md`, extend the "A rule here is often stated in several places" note): "When adding a
  rule, grep the other files for the words it hinges on (`effort-ladder`: `miss`, `recheck`), not only for
  the old wording; step 8 and `staffing.md` disagreed twice within one change."
- **L3** (`README.md`, Troubleshooting table, a new row): "| Eval: `prompt.md: invalid YAML frontmatter: YAML
  Parse error` | The `description:` is a plain scalar and contains a colon followed by a space, which YAML
  reads as a mapping. Reword it, or quote the whole value |"
- **L4** (comment on issue #32, as written): "Another instance, 2026-10-21, on haiku this time: a verifier
  reported in its own final report that its last `updated` time was 'set by hand, not from a fresh `date -u`
  call'. The agent file and the brief both named the command. The hook check proposed in this issue would
  have blocked that stop."
