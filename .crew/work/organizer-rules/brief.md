# Organizer rules: reports, budgets, flowcharts, a lessons ledger, a ship step, one handoff, worktrees

**Size:** L · **Tickets:** #37, #38, #40, #50 (A: lessons ledger), #47 (F: worktree rule), #48 (G: ship step),
#49 (H: one handoff) · **Opened:** 2026-11-13

## What
Seven changes to the organizer's text and its reference files:

1. A researcher's full report stays on disk (#37).
2. Every reviewer brief carries a tool-call budget (#38).
3. Plans show flowcharts (#40).
4. A lessons ledger that the plan step reads (issue A).
5. The worktree rule is proven by a live probe, then fixed or removed (issue F).
6. A ship step drafts the pull request text from the record (issue G).
7. One handoff for a paused work item instead of two (issue H).

## Why
The crew has a good retro loop and a weak fix loop: 25 lesson rows across 11 retros repeat an earlier lesson.
The reviewer ran out of turns in 4 items, a researcher's report was lost or nearly lost in 2, and the worktree
rule has never been used. Long text plans are hard to follow at the approval step. The organizer writes
pull request text by hand although the work item holds every input.

## Done when
- [ ] #37.1 (derived) A researcher's full report is on disk before it finishes, and its final message points
      to it.
- [ ] #37.2 (derived) The organizer's brief template for researchers says so.
- [ ] #37.3 (derived) The handoff skill lists report files under what to read first.
- [ ] #38.1 (derived) Every reviewer brief carries a tool-call budget sized to the diff, and says that running
      tests counts against it.
- [ ] #38.2 (derived) The reviewer keeps its last turns for the final report: near the budget it stops,
      records what is still open, and reports.
- [ ] #38.3 (derived) A reviewer brief lists a few exact test commands instead of "you may run related tests".
- [ ] #40.1 `formats.md` shows a `plan.md` with a Mermaid task graph and a before/after pair with new or
      changed nodes marked, plus the rule for when each appears.
- [ ] #40.2 `SKILL.md` step 5 says: task graph for size M and L plans with 3+ tasks; before/after only when
      the change alters a runtime flow; no Flow section otherwise; about 12 nodes per diagram at most.
- [ ] #40.3 The size L approval message includes the diagrams.
- [ ] #40.4 Current-flow nodes cite `path:line`, written by the researcher.
- [ ] #40.5 The final review reports the code against the final flow like a done-when line (met, or a
      must-fix with evidence).
- [ ] #40.6 New eval case: a size L request that changes a runtime flow produces a `plan.md` whose task graph
      edges match the "Depends on" column and that has a before/after pair.
- [ ] #40.7 New eval case: a docs-only change produces no before/after flow.
- [ ] #40.8 The profile's `verify` commands pass, including `claude plugin validate .`.
- [ ] A.1 The close step adds each lesson to one ledger file per project, or raises the count of the lesson it
      repeats.
- [ ] A.2 The plan step reads the ledger, and the plan names the open lessons that apply to it.
- [ ] A.3 A lesson with two or more hits is not closed as "retro only": the retro proposes a mechanism, or
      records why there is none.
- [ ] A.4 `formats.md` documents the ledger, and an eval case shows a planted ledger lesson named in a plan.
- [ ] F.1 A live probe records in DESIGN "Verified mechanics" what an `isolation: "worktree"` employee can do:
      write its status file in the main checkout, commit, and take in another branch.
- [ ] F.2 The worktree rule says how the organizer brings the work back, in every file that states it; or the
      rule is removed from every file.
- [ ] G.1 At close the organizer drafts the pull request text from the record: what changed, how it was
      verified, who did what, `Closes` or `Refs` per ticket, and what was left out on purpose.
- [ ] G.2 It says a pull request is merged only after checking the pull request's state.
- [ ] G.3 `formats.md` shows the shape of the pull request text.
- [ ] H.1 A paused work item has one handoff; the other place points to it.
- [ ] H.2 Resume reads it, and it names the status and report files to read first.
- [ ] H.3 The `writes-handoff-to-crew` case still scores 1.00.
- [ ] I.1 (derived) `SKILL.md` stays near the 150-line convention with no rule dropped: every sentence removed
      from it is in a reference file.
- [ ] I.2 (derived) Each changed rule reads the same in every file that states it, checked with a grep for the
      words it hinges on.
- [ ] I.3 (derived) The organizer eval cases the changes touch score 1.00, one run each, cost reported.

#37 and #38 have no acceptance list of their own, so their lines are derived from each issue's suggested fix.
The A, F, G and H lines are the criteria of #50, #47, #48 and #49, as written (filed 2026-11-13).

## Constraints
- Short `SKILL.md`: about 150 lines, now 160. Details move to reference files, and no condition is trimmed
  away (README "Conventions for new skills"; `review-24-fixes` lost one that way).
- A rule is stated in several files. When one changes, grep the others for the words it hinges on
  (`.crew/profile.md`).
- Ship evals with the skill. A case for a new rule holds back the rule's own output, and it is settled
  beforehand whether the case can fail on the current text (README "Conventions for new skills").
- Ask before publishing: the pull request text is a draft, and opening the pull request stays an explicit
  step.
- State lives under `.crew/`, never `.claude/`.
- No version bump in this item. The main checkout stays on `main`; every edit happens in a worktree.

## Edge cases
| Case | In scope? | Covered by |
|---|---|---|
| A project with no retros yet (empty ledger) | yes | A.2: nothing to name |
| A ledger with hundreds of lines | yes | plan: the plan step reads open lessons only |
| Two items closing at once, both appending | yes | append-only lines, one writer (the organizer) |
| Eleven existing retros with slightly different tables | yes | seeded once in this item; malformed rows fixed by hand |
| Ledger committed or ignored | yes | decisions.md |
| A plan with fewer than 3 tasks, or a docs-only change | yes | #40.2, #40.7: no diagram |
| A flow with more than about 12 nodes | yes | #40.2: split it |
| Mermaid source read where it does not render | yes | #40.3: the approval message shows it; the source stays readable |
| A wrong current-flow diagram | yes | #40.4: `path:line` on every node |
| A diff too large for any reviewer budget | yes | #38.1: the organizer splits the review |
| The stop hook and a longer status file or a sibling report file | yes | #37.1, from T1's check of the hook |
| A tracker without a CLI to check a merge | yes | G.2: it says "not checked", never "merged" |
| A `handoff.md` written by the current version | yes | H.2: old files still resume |
| Team mode (`teams.md`) wording of the same rules | yes | I.2 |
| Cursor and Claude chat | no | tier 2 text only; tier 1 skills do not change |
