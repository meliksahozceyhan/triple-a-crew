# Decisions

- **2026-10-20 Size M** (text in eight files plus one eval case; the one unknown, whether the Agent tool's
  `effort` reaches plugin agents, is answered by DESIGN.md:457's probe of 2026-10-19 and shown again by the
  new case's trace). The organizer writes T1 and T3; a verifier (haiku) runs the three profile commands
  (step 8); a fresh opus reviewer checks the whole diff against every done-when line.
- **2026-10-20 Rules, not agents.** The user first proposed a task-describer and a model-effort-router agent.
  Rejected: a describer subagent would see less than the organizer, which has the conversation and already
  writes the brief at step 3; a router would turn the tier table (a rule) back into a judgment, and the #30
  Sonnet run showed what model-dependence costs upstream. The user chose the rules route.
- **2026-10-20 Ladder shape: send back → effort up → tier up → ask.** Rung 1 stays the existing send-back:
  it costs no spawn and the employee keeps its context. Rung 2 is a fresh spawn at the same tier with
  effort one step up (effort can't change on a resumed agent). Rung 3 is the existing tier-up, moved one
  miss later. Rung 4 asks the user. Rejected: dropping the send-back (loses context, costs a spawn);
  raising effort and tier together (can't tell which helped, and costs more); an unbounded ladder.
- **2026-10-20 Effort defaults and ceilings:** mechanical `low` (ceiling `medium`), standard `medium`
  (ceiling `high`), critical `high` (ceiling `xhigh`). "One step up" follows `low → medium → high → xhigh`.
  `max` is never climbed to automatically. Rejected: one default for all tiers (loses the "effort before
  tier" order DESIGN asks for).
- **2026-10-20 A re-staffed attempt is `<task><letter>-<role>.md`** (`T1b-engineer.md`): the hook matcher
  `[Tt][0-9]+[a-z]?-(role)` already accepts it, and attempt 1's file stays as the record. Rejected:
  overwriting `T1-engineer.md` (loses the first attempt); a new task id (breaks the plan's task identity).
- **2026-10-20 Board: an Effort column and one row per attempt.** Rejected: attempts only in the State
  text (not readable enough after `/clear`).
- **2026-10-20 One eval case, at miss 2.** It distinguishes the texts by construction: the current text
  prescribes a tier jump there, the new one an effort step. The tier rung and "ask the user" have no case
  (an opus engineer can't be made to fail deterministically); the reviewer checks that text.
- **2026-10-20 Baseline first (T2):** the case must fail on the current text before T3 (README "Earn the
  place"; issue-30 L2).
- **2026-10-21 Plan approved as written** by the user ("Approve the effort-ladder plan as written ... Ask me
  before pushing"). The alternative offered, dropping the send-back rung, was not taken.
- **2026-10-21 T1 done.** The fixture exits 0 in an empty folder; `node --test` there fails exactly
  `quotes a field with a line break`; the only rule word in it is the reviewer's `opus` on the board, which
  is the existing tier table, not the ladder. The five regex graders were probed on real Agent and board
  rows from three kept traces (none match, as they should) and on built variants: the wanted engineer row
  (sonnet, effort high, test name and `T1b-engineer.md` in the brief) passes all three positive graders;
  the old rule's row (opus, no effort) fails `effort-raised-same-tier` and trips `no-tier-jump`; a subagent
  row matches nothing. `board-records-attempt` matches a real board Write only once a `T1b` row is inserted.
  (Corrected after T5: `failures-in-brief` matched on the spawn's description alone, and
  `board-records-attempt` on a `T1b` mention anywhere; both were tightened, see "T5 review".)
- **2026-10-21 T2 baseline: the case fails on the current text, 0.67 ($0.89).** As expected, the old rule
  re-staffed T1 one tier up: an opus engineer with no `effort`, so `effort-raised-same-tier` found nothing
  and `no-tier-jump` found the opus row. The other four graders passed: the old text already chose
  `T1b-engineer.md`, put the line-break failure in the brief, recorded T1b on the board, and the opus
  engineer fixed the test. Those four stay as guards of the bookkeeping; the two that failed carry the rule.
  A first launch failed to load: the prompt's description had a colon followed by a space, which YAML reads
  as a mapping. Fixed by rewording.
- **2026-10-21 T4 verify: 3/3 pass** (haiku verifier, spawned with `effort: low`); `claude plugin validate`
  accepts the agents' new `effort:` line. **T5 review (opus, `effort: high`): changes requested**, two
  must-fix, five should-fix, four nits (team/T5-reviewer.md). Applied:
  - must-fix 1: `failures-in-brief` now needs the failure output itself (`not ok 3 - quotes a field with a
    line break` or `Expected values to be strictly equal`), not the words "line break", which the spawn's
    description alone supplied;
  - must-fix 2: step 8 said a test-engineer's failing test goes back "as a miss"; it now says it is a defect
    for the code task, not a miss, as `staffing.md` and step 7 say;
  - should-fix 3: `board-records-attempt` now needs a `| T1b |` row, not a `T1b` mention in T1's own row;
  - should-fix 4: `staffing.md` says the step 8 recheck is a loop over reviewers: a must-fix traced to a
    task is its miss, but when a recheck asks again and the fix is bigger than size S, step 8's question to
    the user comes before any further rung;
  - should-fix 5: `teams.md` no longer suggests raising the installed agent file's default; the level goes
    in the teammate's brief and on the board;
  - nits 6, 7, 9: "the next letter" in both `staffing.md` and `formats.md`; the board's State cell names
    what was asked for when a setting overrode the model; `## Earlier attempts` also takes a must-fix text.
  Nit 8 (README note that the tier-up and ask-the-user rungs have no case) goes in with T6's results row.
  Per step 8, verify is rerun (T7, verifier) and a fresh reviewer rechecks the fix diff (T8) before T6.
- **2026-10-21 T7 verify rerun: 3/3 pass.** **T8 recheck (opus, `effort: high`): changes requested**, one
  should-fix and one nit left; both must-fixes and the other should-fixes confirmed resolved, no condition
  dropped from `SKILL.md`. The should-fix: `staffing.md` made an exception only for a recheck fix bigger
  than size S, so a size-S recheck fix was both "the organizer makes it" (step 8) and "a miss that climbs"
  (staffing). Step 8's own rule for a second recheck applies: the fix is size S, so the organizer made it
  (`staffing.md`: when a recheck asks again, step 8 decides first) and reran verify itself (3/3 pass); no
  third reviewer. The nit: in team mode the board records effort as asked (`high, asked`), since the call's
  value is unverified for teammates (`teams.md`).
- **2026-10-21 T6, `escalates-effort-before-tier` on the new text: 1.00 ($0.85).** The organizer re-staffed
  T1 as `T1b` on sonnet with `"effort":"high"`, pasted the test output into the brief, wrote a `| T1b |`
  board row, and the engineer fixed the line-break test; the reviewer it then staffed ran on opus with
  `"effort":"high"`, the critical tier's default. So the trace shows `effort` reaching the Agent call, which
  was the item's one unknown.
- **2026-10-21 T6 done:** `medium-fix-end-to-end` 1.00 ($1.25), `verify-staffs-verifier` 1.00 ($1.05).
  Evals for this item: $4.04 in all (baseline $0.89, the three T6 runs $3.15), against the plan's $3.70.
  README nit 8 added with the results note. Every done-when line of `brief.md` now has evidence (T5's and
  T8's tables, T6's scores); the PR waits for the user's OK to push.
