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
- **2026-10-19 `test-engineer` preloads with the bare name `skills: [test-harden]`.** T1 found that `skills:`
  injects the full skill at subagent start and that a wrong name is skipped silently, but the name format for
  plugin skills is undocumented. A $0.007 haiku test with a throwaway plugin settled it: `skills: [alpha]`
  preloaded the plugin's own skill, `skills: [prob:alpha]` loaded nothing. The agent body also says to read
  `${CLAUDE_PLUGIN_ROOT}/skills/test-harden/SKILL.md` if the rules are not in its context. Rejected: the
  namespaced name (silently does nothing); reading the file only (an extra step every run).
- **2026-10-19 The organizer wrote T6 (eval case) and T7 (docs) itself;** T3 and T5 ran as parallel engineers
  on disjoint files (agents/test-engineer.md; skills/work/).
- **2026-10-19 T8 review fixes (2 must, 9 should, 6 nits).** The verifier runs each command exactly as written,
  alone: a wrapper like `cmd | tail; echo $?` reports `tail`'s 0 on a failing suite (M1), and compound lines
  don't match permission rules (the first eval run was denied, S9). Failing checks are `state: done` (S5).
  The test-engineer's bug-exposing test goes back to the code task as a defect of this item, not a follow-up
  (S6). For size L the test-engineer writes the independent tests, engineers keep their own acceptance tests,
  and a test task depends on its code task (S1, S7). The verifier is staffed for L, and for M with more than
  one verify command (S2). New case `test-engineer-keeps-failing-test` (M2) and a verifier-edits-nothing
  grader (S8). Rejected: `cmd > file 2>&1; echo "exit=$?"` (the reviewer's suggestion; still a compound line).
- **2026-10-19 T8 re-check: ship.** Remaining items fixed: a bug-exposing test doesn't fail the test-engineer's
  task (`state: done`) (R-S3); a profile command that already contains `&&` runs as listed (R-N1); README and
  DESIGN say such a test goes back to the code task (R-N2); both fixtures record the plan go-ahead and the
  verifier fixture commits its base so `git diff` shows the work (R-N3). R-S1 settled: eval traces include
  subagent tool calls (rows carry `parent_tool_use_id`). R-S2 settled as far as it can be: the trace does not
  show injected skill text, so `test-harden-preloaded` only proves the fallback read wasn't needed; the preload
  itself rests on the secret-word test.
- **2026-10-19 T9 organizer suite (before the R fixes): 6 of 7 at 1.00, $3.81.** Both new cases 1.00.
  `starts-work-item-on-large-request` 0.78: the organizer sized the request M (no plan.md, no go-ahead) although
  the mobile app parses the export (public format, so L by the table). It scored 1.00 in all three earlier runs;
  rerunning it twice to tell variance from a regression.
- **2026-10-19 T9 results.** Organizer suite 6/7 (the large-request miss was variance: 2 reruns 1.00); employee
  cases on the final text: verify 0.88 and test-engineer 0.80 (one judge each), then both 1.00 with traces kept.
  The failing judges read the whole run log (~330 KB); the facts they check are in the final reply, so
  `failure-reported` and `defect-goes-back` now judge the final reply. Not rerun after that grader change.
  Eval cost for this work item: about $8.22 ($0.67 + $3.81 + $0.68 + $1.27 + $1.78, plus $0.007 for the
  preload test).
- **2026-10-19 Closed.** Merged in PR #10. `retro.md` written at close; the user accepted every proposal: L1,
  L5 and L6 accepted and applied, L7 filed as #18. The other lessons are filed (#12, #13, #15) or kept.
