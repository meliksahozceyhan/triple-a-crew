#!/bin/sh
# PreToolUse hook for the Agent tool: warn the organizer once when the agent file of the crew employee
# it is about to start changed after the session loaded it. Never refuses the call; always exits 0.
# Needs the stamp that session-start.sh writes (triple-a-crew-defs-<session_id>).

input=$(cat 2>/dev/null || true)

if [ "${HOOKS_NO_JQ:-}" != "1" ] && command -v jq >/dev/null 2>&1; then
  session_id=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null || true)
  subagent=$(printf '%s' "$input" | jq -r '.tool_input.subagent_type // empty' 2>/dev/null || true)
else
  flat=$(printf '%s' "$input" | tr '\n' ' ')
  session_id=$(printf '%s' "$flat" |
    sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' 2>/dev/null || true)
  subagent=$(printf '%s' "$flat" |
    sed -n 's/.*"subagent_type"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' 2>/dev/null || true)
fi

role=${subagent#triple-a-crew:}
[ "$role" != "$subagent" ] || exit 0
# A role is a plain file name: nothing else may reach the path below.
case "$role" in
  '' | *[!a-z0-9-]* | -*) exit 0 ;;
esac
session_id=$(printf '%s' "$session_id" | tr -c 'A-Za-z0-9_-' '_')
[ -n "$session_id" ] || exit 0
[ -n "${CLAUDE_PLUGIN_ROOT:-}" ] || exit 0

file="$CLAUDE_PLUGIN_ROOT/agents/$role.md"
[ -f "$file" ] || exit 0
state="${CLAUDE_PLUGIN_DATA:-${TMPDIR:-/tmp}}/triple-a-crew-defs-$session_id"
[ -f "$state" ] || exit 0

recorded=$(awk -v r="$role" '$1 == r { print $2; exit }' "$state" 2>/dev/null || true)
[ -n "$recorded" ] || exit 0
now=$(cksum <"$file" 2>/dev/null | awk '{ print $1 }' || true)
[ -n "$now" ] || exit 0
[ "$now" != "$recorded" ] || exit 0

# Record the new checksum so this change is reported once. Only this role's line changes, and the state
# is read again here, so a parallel call for another role keeps its own update.
(
  tmp="$state.$$"
  if awk -v r="$role" -v s="$now" '$1 == r { $2 = s } { print }' "$state" >"$tmp"; then
    mv "$tmp" "$state"
  else
    rm -f "$tmp"
  fi
) 2>/dev/null || true

printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"%s"}}\n' \
  "Triple-A-Crew: agents/$role.md changed after this session loaded it. Unless /reload-plugins has run since that change, the employee about to start runs on the old definition: ask the user to run /reload-plugins, then staff again. This note is shown once per change."
exit 0
