# Decisions

- **2026-10-19 Scripts in POSIX `sh`, `jq` optional.** The docs guarantee neither `node` nor `jq`; `node` here
  comes from nvm, which a GUI-launched app may not have on PATH. Rejected: `node` (fails silently for some
  users), `python3` (same problem).
- **2026-10-19 SubagentStart injects the protocol only.** Its input has no prompt and the transcript may not
  exist yet, so it cannot know the status-file path; the brief already names it. Rejected: deriving the path
  from a scan at start time (races with parallel employees).
- **2026-10-19 SubagentStop never blocks when it cannot resolve the status file.** A parsing failure must
  never trap an employee; the hook is a strong nudge (the docs cap consecutive blocks), not a guarantee.
  Rejected: blocking on "no status file found" (would trap employees started by hand).
- **2026-10-19 The report check reads the final message, not the status file.** The protocol puts the final
  report in the employee's reply; DESIGN says otherwise and gets corrected in T8.
- **2026-10-19 Spike before building.** The subagent payload fields were read from summarized docs; a
  ten-minute dump of real stdin settles them before three scripts depend on them.
- **2026-10-19 Match `^triple-a-crew:[a-z-]+$`.** Covers roles added later (`verifier`, `test-engineer`)
  without editing hooks.json. Rejected: listing roles (silently misses new ones).
- **2026-10-19 Plan approved by the user as written.**
- **2026-10-19 Spike confirmed the design (T2, Claude Code 2.1.299, $0.03).** SubagentStart gets no prompt and
  no transcript path, so it injects the protocol only. SubagentStop's `agent_transcript_path` line 1 holds the
  brief with `**Status file:**`, and the payload has `last_assistant_message` for the report check.
  `additionalContext` from SubagentStart reached the subagent; SessionStart plain stdout reached the main
  session (with a `SessionStart:startup hook success:` prefix). A block was obeyed; with blocks that ask for
  no tool call, Claude Code ended the subagent after 9 consecutive blocks (`stop_hook_active` true from the
  second). Matchers on `^spike:probe$` never fired for Explore. No plan change.
- **2026-10-19 One engineer for T3-T6 instead of three in parallel.** The three scripts share JSON parsing
  (jq with a sed fallback) and one test runner; splitting them would mean overlapping file sets or duplicated
  helpers. Rejected: parallel engineers on T3, T4, T5.
- **2026-10-19 The organizer wrote T7 (eval case) and T8 (docs) itself** while T3-T6 ran; their files are
  disjoint from the engineer's, and the reviewer covers them.
- **2026-10-19 Status-file path resolution: full rest of line, then first token, `.md` rule.** The first
  version cut paths at a space without jq and misread briefs with text after the path, both of which would
  block an employee that did everything right. Now: use the rest of the line if it exists, else its first
  token; if neither exists, block only when one of them ends in `.md`; otherwise stay silent.
- **2026-10-19 T9 review fixes.** The stop hook reads only the first line that starts with `**Status file:**`
  (a quoted example elsewhere in a brief caused a permanent block), skips the report check when the payload has
  no `last_assistant_message`, keeps its own cap of 3 blocks per `agent_id` (a counter under
  `${CLAUDE_PLUGIN_DATA}` or `$TMPDIR`) instead of relying on Claude Code's end after 9, writes a done marker so
  a finished employee answering a follow-up question needs no new report, and expands `~/`. Session start
  follows the organizer's root rule instead of walking up past git roots. The eval forbids Read, Glob, Grep
  and Skill so it measures only the hook. Rejected: trusting the 9-block end seen once in the spike.
- **2026-10-19 T9 re-check fixes (R1-R5), done by the organizer.** R1: on dash a failed redirection on the
  special builtin `:` exits the script with 2, which blocks; braces don't help, so the marker uses `touch` and
  the counter a subshell. The test runner now repeats every case under dash when it is installed (220 cases:
  110 under `sh`, 110 under dash), and a copy with the old line fails there. R2 CRLF index, R3 prune state
  files older than 7 days, R4 a non-final state forgets the done marker, R5 DESIGN states the 9-block end as
  a spike observation.
- **2026-10-19 T10 evals (before R1-R5, which the model-free tests cover):** `session-start-mentions-open-item`
  1.00 with the plugin, 0.80 without (the name-the-item grader failed without the hook; the four no-tool
  graders pass in both arms); organizer suite with hooks loaded 5/5 at 1.00. Cost $1.63. Not rerun after the
  R fixes, to keep cost down.
- **2026-10-19 Closed.** Merged in PR #9. `retro.md` written at close; the user accepted every proposal: L3
  accepted and applied. The other lessons are filed (#14) or kept.
