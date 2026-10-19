# Plan

From T1: all three hooks are feasible. The subagent hook input has no prompt field, so a hook cannot read
the brief directly; the employee's own transcript (`agent_transcript_path`) starts with the brief, which names
the status file. Matchers can target `triple-a-crew:*` agents only. `node` is not guaranteed, so scripts are
POSIX `sh`.

| Task | Goal | File set | Acceptance check | Role | Tier | Depends on |
|---|---|---|---|---|---|---|
| T1 | Research the hook API | read only | done: team/T1-researcher.md | researcher | standard | - |
| T2 | Spike: a throwaway plugin whose hooks dump stdin for SessionStart, SubagentStart and SubagentStop, run once with a haiku subagent in a scratch folder; confirm the real fields, that `agent_transcript_path` line 1 holds the brief, and whether the stop-hook block cap applies to SubagentStop | scratch folder outside the repo | a payload sample per event in the status file | engineer | mechanical | T1 |
| T3 | `session-start.sh`: read `cwd` from stdin (jq if present, sed fallback) or `$CLAUDE_PROJECT_DIR`; print the Open list of `.crew/work/index.md`, capped at about 15 lines; print nothing and exit 0 without `.crew/` | plugins/triple-a-crew/scripts/session-start.sh | fixture tests: with, without, and with a huge index | engineer | standard | T2 |
| T4 | `subagent-start.sh`: inject a short protocol (status file first, final states, report sections) as `additionalContext`, well under 10,000 characters; no path (the brief has it) | plugins/triple-a-crew/scripts/subagent-start.sh | fixture test: valid JSON, under 2,000 characters | engineer | standard | T2 |
| T5 | `subagent-stop.sh`: resolve the status file from the brief on line 1 of `agent_transcript_path`; if unresolved, allow the stop. Block with a specific reason when the file is missing, `state` is not `done`/`blocked`/`failed`, or (for done/failed) `last_assistant_message` lacks the six report headings; the reason says how to write a minimal `failed` file | plugins/triple-a-crew/scripts/subagent-stop.sh | fixture tests: each failure blocks with its reason; unresolved path allows; valid file allows | engineer | standard | T2 |
| T6 | `hooks/hooks.json` with the top-level `hooks` key, matchers `startup\|resume\|clear\|compact` and `^triple-a-crew:[a-z-]+$`, quoted `"${CLAUDE_PLUGIN_ROOT}"`; a model-free test runner added to the profile's `verify` | plugins/triple-a-crew/hooks/hooks.json, plugins/triple-a-crew/scripts/test-hooks.sh, .crew/profile.md | `claude plugin validate .` passes; `sh plugins/triple-a-crew/scripts/test-hooks.sh` passes | engineer | standard | T3, T4, T5 |
| T7 | Eval `session-start-mentions-open-item`: a scaffolded `.crew/work/index.md` with one open item; Claude names it in its first answer | plugins/triple-a-crew/evals/session-start-mentions-open-item/ | passes at --runs 1 | engineer | standard | T6 |
| T8 | Docs: DESIGN "Enforcement through hooks" (the report check reads the final message, not the status file), tier diagram, Verified mechanics rows; README tier 3 and Troubleshooting (shell profile output breaking hook JSON) | README.md, plugins/triple-a-crew/README.md, docs/DESIGN.md | rows sourced to the hooks docs | engineer | mechanical | T6 |
| T9 | Review the full diff, focusing on never trapping an employee and never touching non-crew agents | read only | verdict + findings | reviewer | critical | T7, T8 |
| T10 | Run the organizer suite and the new case at --runs 1, report cost | read only | all 1.00 | organizer | mechanical | T9 |

T3, T4 and T5 run in parallel after T2 (separate files).
