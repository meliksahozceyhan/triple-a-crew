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
