#!/bin/sh
# SubagentStart hook: remind a crew employee of the protocol. Always exits 0.

cat >/dev/null 2>&1 || true

cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"SubagentStart","additionalContext":"Triple-A-Crew protocol. Your brief names your status file by absolute path (the Status file line). Create it first thing and keep it current: frontmatter with task, role, model, state (in-progress, blocked, done or failed) and updated; then the sections Progress, Assumptions, Questions, Findings. Reversible unknown: choose, record it under Assumptions, continue. Irreversible or out of scope: set state: blocked, write the question with your proposed answer under Questions, and stop. When finished, set state: done (or failed) and end your reply with these sections, in order: Outcome, Changed, Evidence, Assumptions, Open questions, Findings. Never file issues, start other agents or write under .claude/. If your brief names no status file, ignore this reminder. A stop hook checks your status file and your final report, and will send you back to fix them."}}
JSON
exit 0
