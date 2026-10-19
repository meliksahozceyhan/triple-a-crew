# Decisions

- **2026-10-19 Build `verifier` (haiku, bash, report only).** It changes model and protocol: verify output
  is long and mechanical, so running it on haiku in its own context keeps the organizer's context small and
  costs less. Its protocol (exit codes and failing lines verbatim, never fix) is the safety net against a
  cheap model saying "passed". Rejected: the organizer keeps running verify itself (fine for M, wasteful for
  L with long suites).
- **2026-10-19 Build a thin `test-engineer` that preloads `test-harden`.** The protocol differs from the
  engineer's: tests only, behavior-first, project framework only, and written by someone other than the code's
  author, which catches what the author's own tests share with the code. Rejected: "an engineer whose task is
  tests follows test-harden" (today's staffing note), because nothing makes it happen.
- **2026-10-19 Fold `architect` into `researcher` as a design-question report, staffed at critical tier.**
  Same tools (read only); the model is already chosen per task; only the report differs, the same pattern as
  folding `investigate` (W1). Rejected: a separate opus agent (a fourth read-only role with one report format).
- **2026-10-19 Drop `scribe`.** Issues must be confirmed by the user, which a subagent cannot do, so
  `file-issue` stays in the main session; `handoff` is a skill; PR text needs the conversation. A haiku
  writer saves little and writes worse prose. Rejected: building it for cost only.
- **2026-10-19 Test new roles by starting the organizer at a later phase.** A fixture with a work item already
  at phase `verify` plus `/triple-a-crew:work next` reaches step 8 without the plan go-ahead that a one-turn
  eval cannot give.
- **2026-10-19 Plan approved by the user as written.**
