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
