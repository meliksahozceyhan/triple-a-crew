# Decisions

- **2026-11-13 Approval phase skipped.** The user saw the three-track plan and said to create the tasks and
  start implementing them, in parallel where possible. Every change still reaches `main` only through a pull
  request the user merges.
- **2026-11-13 Engineers work in this branch's worktree by absolute path, not in worktrees of their own.** P1
  showed that a worktree-isolated employee is refused when it writes its status file in the main checkout,
  and the stop hook then blocks it three times.
- **2026-11-13 Reference files first, `SKILL.md` last.** T3, T4 and T5 own one or a few reference files each
  and run in parallel; T6 then edits `SKILL.md` alone, pointing at text that exists. Every engineer brief
  carries the exact words of each rule, so the copies agree. Rejected: one engineer per change (all seven
  touch `SKILL.md`, so they would run in sequence and each would restate the others' rules).
- **2026-11-13 #37: the report goes into the status file, under `## Report`.** One file per employee stays
  true, and the stop hook reads only the frontmatter and the final message. Rejected: a sibling report file
  (it breaks "one status file per employee" in `formats.md` and DESIGN, and the retro reads "every `team/`
  status file").
- **2026-11-13 #38: the budget is in tool calls: about 30 plus one per changed file, 70 at most.** A 50-file
  review finished in 69 calls; a 40-file review ran out at 83 calls and 60 turns. Above that the organizer
  splits the review. `maxTurns` stays 60: turns are not calls. `teams.md` had the budget in turns; it now
  points to `protocol.md`.
- **2026-11-13 A: the ledger is `.crew/lessons.md`, committed, one row per lesson.** It is part of the durable
  record, like the retros. `Mechanism` is `open`, a mechanism, or `none:` with a reason; the plan step reads
  the open rows. Rejected: an ignored file (lessons would not travel with the repository); a ledger per work
  item (that is the retro, and it is what fails today).
- **2026-11-13 G: the ship step drafts; it does not open.** Opening a pull request stays an explicit step the
  user asks for. "Merged" is said only after a check with the tracker's tool, otherwise "not checked". The
  board gets a `ship` phase, which DESIGN already lists.
- **2026-11-13 H: the work item's `handoff.md` is the one handoff for a paused item.** Resume reads it before
  `board.md`, and it names the files to read first. The `handoff` skill's session handoff points to it.
  Rejected: dropping `handoff.md` in favour of the session handoff (the session handoff is per session and
  ignores itself in git; the item's state belongs with the item).
- **2026-11-13 F: decided after P1; the text is written in T6.** The rule as written does not work: the status
  file cannot be in the main checkout. What does work: the employee takes in the item's branch first, commits
  at the end, and the organizer merges `worktree-agent-<id>`. Open until the hook side is settled: where the
  status file lives for such an employee.
