# Decisions

- **2026-10-19 Size M** (text in four files plus one eval case, one unknown: whether the current text already
  passes the case). The organizer writes T1 and T3 itself; a verifier (haiku) runs verify, because the profile
  lists three commands (step 8; `follow-ups-25-28` ran them itself); a fresh opus reviewer checks the diff.
- **2026-10-19 The check is a reviewer's, not the organizer's alone.** The last review gets every done-when
  line and reports evidence for each. Rejected: the organizer builds the table itself (it missed the step 8
  contradiction that `follow-ups-25-28`'s reviewer found, and it wrote or directed the work); a new
  "criteria checker" role (a sixth employee for one table).
- **2026-10-19 Size L adds one whole-diff review after the per-task ones.** That costs one more opus review
  per L item. Rejected: widening the last per-task review to the whole diff (its brief and its status file are
  about one task, so the whole-diff check would be a side job, the shape that ran out of turns in
  `follow-ups-25-28`).
- **2026-10-19 An open criterion means `Refs #N`, not `Closes #N`,** unless the user accepts the deferral
  and says to close. This is the practice from #24 (`Refs #14` until proven).
- **2026-10-19 `SKILL.md` stays at most 160 lines:** the rule goes into steps 3 and 8 in place, and its
  details into `protocol.md` and the reviewer agent. Rejected: raising the budget.
- **2026-10-19 Baseline first (T2):** the case must fail on the current text before T3 changes it (README
  "Earn the place").
- **2026-10-19 Plan approved as written** by the user, along with all three `follow-ups-25-28` retro proposals
  (L1 filed as #32; the L4 and L5 profile notes ride on this branch).
- **2026-10-19 T2 baseline 1: the case passed on the current text, 1.00 ($0.70).** With each ticket's
  criteria written in the brief, the organizer read them, read the README, found #42's gap itself, fixed the
  README, and staffed a fresh opus reviewer to check every done-when line. So the current step 8 plus criteria
  in the brief already catch it, which points at step 3 as #24's real gap: its brief had one line for eleven
  tickets. Hardened once, as the plan allows: the brief now has one #24-style line ("every acceptance
  criterion in both issues holds"), the criteria are only in the issues, served by a mocked GitHub
  `list_issues`, and the profile names the tracker. The whole-diff-review regex was probed on the real
  reviewer row from that run (match), and on three variants of it: no README, a subagent row, and the
  engineer role (no match each).
- **2026-10-19 T2 baseline 2 (hardened): passed again on the current text, 1.00 ($0.70).** The organizer
  read the brief's single line, fetched both issues from the mocked `list_issues`, found #42's README gap,
  fixed the README, and staffed an opus reviewer with both issues' criteria. So on a small fixture with the
  default model (Opus 5.5), the current text already checks ticket criteria; #24's miss happened at scale
  (eleven tickets, a large diff, reviews split by area), which a cheap fixture doesn't reproduce. Per the
  plan, the case is recorded as a guard, not as the proof of a gain, and T3 goes ahead: the text change
  writes down what the baseline did by itself, so a weaker organizer model or a bigger item doesn't depend
  on luck. Open done-when line: #30.2's "fails on the current text" has no evidence; it is a deferral for the
  user to accept or reject (with `Refs #30` if not accepted). Total T2 cost $1.40.
- **2026-10-19 T4 verify: 3/3 pass** (haiku verifier). **T5 review: approve**, no must-fix, five should-fix
  and four nits (team/T5-reviewer.md). Fixed:
  - 1: `reviewer.md` exempts a deferral the user accepted from "none is a must-fix";
  - 2: `as given` lines get evidence before the PR, like `pending`;
  - 3: the whole-diff-review regex also needs `#41` (all criteria listed); it matches the hardened run's
    reviewer row and rejects its three variants. It no longer matches the first run's row, whose brief only
    pointed at `brief.md`;
  - 5: derived lines are named in the final report (`protocol.md`);
  - 6: criterion numbering defined (`#41.2` is #41's second);
  - 7: a recheck also gets every line whose files the fixes touched;
  - 8: the README's mock paragraph names GitHub's `list_issues` and why a list is mocked, not `get_issue`.

  Finding 4 (the README must say the case passed on the old text) goes in with T6's results row. Skipped 9
  (the judge trusts a reply that says the README was fixed): checking the file would need a second grader
  that fails on the `Refs` path, and a false claim of an edit is unlikely. After the fixes, verify was rerun
  (3/3 pass) and `SKILL.md` is still 160 lines. The review approved, so step 8 needs no recheck.
- **2026-10-19 T6 evals on the new text, all 1.00:** `flags-unmet-ticket-criterion` $0.91,
  `medium-fix-end-to-end` $0.80, `starts-work-item-on-large-request` $0.41. In the new case the organizer
  copied both issues' criteria into `brief.md`, gave the last reviewer a numbered `## Criteria` list with the
  four evidence kinds, marked its `node --test` line derived and named it in the report. Evals in all: $3.52.
  The README notes that the case is a guard (T5 finding 4).
- **2026-10-19 #30's own criteria are met; the brief's extra line is not.** #30.1 and #30.2, as written,
  have evidence (T5's table and T6). The brief's addition "fails on the current text" has none and can't get
  any on this fixture. It is the item's own line, so by the new rule the PR can say `Closes #30` if the user
  accepts that deferral, and `Refs #30` otherwise.
- **2026-10-19 The user accepted the deferral:** "Push issue-30-criteria-check and open its PR against main
  with Closes #30. I accept the guard-only eval as a deferral." Whether a Sonnet organizer tells the two
  texts apart is being checked in a separate session.
