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
- **2026-11-13 F: the worktree rule is removed, not fixed.** P1 showed it does not work as written: a
  worktree-isolated employee is refused when it writes its status file in the main checkout, so the status
  protocol and the stop hook both fail for it. Fixing it needs a hook that finds a status file inside the
  worktree, a merge step for the organizer and a copy step for status files: three new mechanisms for a rule
  that 13 work items never needed. Overlapping writers go in sequence; that is the whole rule now. The probe's
  facts go into DESIGN "Verified mechanics" (F.1), so a later item can bring worktrees back on evidence.
  Rejected: keeping the rule with a fix (see above); keeping it as written (it is wrong). What this item did
  instead: the organizer made one worktree per work item, and parallel engineers edited disjoint files in it
  by absolute path, which kept the main checkout, and the running plugin, untouched.
- **2026-11-13 T6 is the organizer's.** It holds the exact words of all seven rules, and `SKILL.md` needed one
  owner to stay at 160 lines. Step 7's ladder summary now leans on `staffing.md`, and step 10's lesson routing
  moved to `formats.md` ("Goes to"); the reviewer checked that nothing was dropped. Rejected: an engineer at
  critical tier (the brief would have been as long as the edit).
- **2026-11-13 The ledger is seeded with the lessons the retros repeat.** Ten rows have two or more hits,
  counted from the retros' own "Repeat of" chains. L11 has one hit in this repository (its first occurrence
  is behind issue #37) and stays because it now has a mechanism. Rows whose fix is in another open pull
  request (#32, #44, #45, #51) say `open` until that pull request merges; the release pull request updates
  them. Single-hit lessons stay in their retros.
- **2026-11-13 T11 review of the rule text: changes requested, two must-fix, both fixed.** (MF1) `SKILL.md`
  asked the researcher for the current flow "when the plan shows one", which is circular; it now says "when
  the change alters how something runs", as `protocol.md` does. (MF2) The repeat rule read three ways; the one
  wording is now "at two hits while open: a mechanism, or `none:` with the reason; never a retro-only note",
  and "Goes to" allows `retro.md` only for a first-time lesson or a `none:` row. Should-fix, all fixed: a rule
  for when a ledger row stops being `open`; the flow rule for a two-task plan and for "no diagram"; nested
  code fences in `formats.md`; seeding a ledger in a project that already has retros; a stale `handoff.md`
  (deleted after resume); the eval line removed from the generic pull request text; the handoff skill writes
  a missing `handoff.md` first. Nits fixed: where `## Budget` sits, a reviewer with no budget, quoting Mermaid
  labels, the plugin README's flow wording, the path in the final-flow criterion. Each file's own engineer
  made its fixes (rung 1 of the ladder: sent back once); the organizer fixed `SKILL.md`.
- **2026-11-13 Declined: a rule that sets the board's `ship` phase (T11 nit N1).** It costs a line in a file at
  its cap, and the phase list already names the phase.
- **2026-11-13 T11b review of the eval cases and the ledger: changes requested, two must-fix, both fixed by
  T8.** The flow case could fail a correct run (its reply grader needed dependencies nobody asked for) and
  could pass a `plan.md` with no current or final flow. The request now asks for the dependencies, and two
  new graders read `plan.md` for each flow. Ledger: L11 has one hit; rows that wait on another pull request
  say exactly `open`.
- **2026-11-13 The current and final flow do not depend on the number of tasks.** A plan with fewer than three
  tasks has no task graph, but it shows both flows when the change alters how something runs. That is #40.2
  as written; the brief's own edge-case row said "no diagram" and is corrected. Cost: a two-task size M fix
  would need a researcher only for a diagram, so at size M the organizer may draw the current flow itself
  from code it has read, with a `path:line` on every node. Rejected: both flows only at three or more tasks
  (a small change to a request path is exactly where the before and after help most).
- **2026-11-13 T11c recheck: changes requested, one must-fix (the decision above was missing), six
  should-fix, eight nits; every earlier must-fix was fixed.** Fixed in this round: two shapes of a correct
  plan failed the flow graders; "no diagram, no section" is back in step 5; the handoff is deleted only once
  its open questions are in `decisions.md` and its next step is on the board, also in the handoff skill; the
  ledger seed takes every lesson of the old retros; the handoff skill writes a missing `handoff.md` only for
  the item the session worked on. The round is many small text edits across ten files, which is more than
  size S, so step 8 says to ask the user whether to staff a third reviewer.
