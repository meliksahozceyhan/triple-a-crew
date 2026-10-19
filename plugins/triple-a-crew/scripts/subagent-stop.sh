#!/bin/sh
# SubagentStop hook: keep a crew employee running until its status file and final report are in order.
# Prints nothing (lets the employee end) unless something is wrong. Always exits 0.
# Our own guard: at most 3 blocks per agent_id, then the stop is allowed.

input=$(cat 2>/dev/null || true)

use_jq=0
if [ "${HOOKS_NO_JQ:-}" != "1" ] && command -v jq >/dev/null 2>&1; then
  use_jq=1
fi

flat=$(printf '%s' "$input" | tr '\n' ' ')

if [ "$use_jq" = 1 ]; then
  transcript=$(printf '%s' "$input" | jq -r '.agent_transcript_path // empty' 2>/dev/null || true)
  agent_id=$(printf '%s' "$input" | jq -r '.agent_id // empty' 2>/dev/null || true)
else
  transcript=$(printf '%s' "$flat" |
    sed -n 's/.*"agent_transcript_path" *: *"\([^"]*\)".*/\1/p' 2>/dev/null || true)
  agent_id=$(printf '%s' "$flat" |
    sed -n 's/.*"agent_id" *: *"\([^"]*\)".*/\1/p' 2>/dev/null || true)
fi

counter=
marker=
agent_id=$(printf '%s' "$agent_id" | tr -c 'A-Za-z0-9_-' '_')
if [ -n "$agent_id" ]; then
  state_dir=${CLAUDE_PLUGIN_DATA:-${TMPDIR:-/tmp}}
  if mkdir -p "$state_dir" 2>/dev/null; then
    counter="$state_dir/triple-a-crew-stop-$agent_id"
    marker="$state_dir/triple-a-crew-done-$agent_id"
    # Counters and done markers older than a week belong to finished work.
    find "$state_dir" -maxdepth 1 -type f -name 'triple-a-crew-*' -mtime +7 -exec rm -f {} + 2>/dev/null || true
  fi
fi

allow() {
  [ -z "$counter" ] || rm -f "$counter" 2>/dev/null
  exit 0
}

# Rework after a finished report needs a new report.
forget_done() {
  [ -z "$marker" ] || rm -f "$marker" 2>/dev/null
}

[ -n "$transcript" ] && [ -f "$transcript" ] || allow

first=$(head -n 1 "$transcript" 2>/dev/null || true)
[ -n "$first" ] || allow

# The first line of the brief that starts with the marker names the status file.
pick_marker_line() {
  awk 'match($0, /^[ \t]*\*\*Status file:\*\*/) { print substr($0, RLENGTH + 1); exit }'
}
if [ "$use_jq" = 1 ]; then
  rest=$(printf '%s' "$first" |
    jq -r '.message.content | if type == "string" then . else (map(.text? // "") | join("\n")) end' 2>/dev/null |
    tr -d '\r' | pick_marker_line || true)
else
  rest=$(printf '%s' "$first" |
    awk '{ gsub(/"content":"/, "\n"); gsub(/"text":"/, "\n"); gsub(/\\n/, "\n"); print }' |
    pick_marker_line | sed 's/[\\"].*//' || true)
fi

# A: the rest of the line, trimmed. B: its first whitespace-delimited token.
trim() { printf '%s' "$1" | sed 's/^[ 	`]*//; s/[ 	`]*$//'; }
expand_home() {
  case "$1" in
    "~/"*) printf '%s' "$HOME/${1#\~/}" ;;
    *) printf '%s' "$1" ;;
  esac
}
a=$(expand_home "$(trim "$rest")")
[ -n "$a" ] || allow
b=$(expand_home "$(trim "$(printf '%s' "$a" | awk '{ print $1 }')")")

if [ -f "$a" ]; then
  path=$a
elif [ -f "$b" ]; then
  path=$b
else
  case "$b" in
    *.md) path=$b ;;
    *) case "$a" in
         *.md) path=$a ;;
         *) allow ;;
       esac ;;
  esac
fi

block() {
  if [ -n "$counter" ]; then
    n=$(cat "$counter" 2>/dev/null || echo 0)
    case "$n" in '' | *[!0-9]*) n=0 ;; esac
    if [ "$n" -ge 3 ]; then
      allow
    fi
    (echo $((n + 1)) >"$counter") 2>/dev/null || true
  fi
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g' | {
    IFS= read -r escaped || true
    printf '{"decision":"block","reason":"%s"}\n' "$escaped"
  }
  exit 0
}

minimal="To finish without completing the task, write the file with this content: a frontmatter block (--- lines) containing task, role, model, state: failed and updated, followed by a line ## Progress and one line saying why you could not do the task. Then end your reply with the final report."

if [ ! -f "$path" ]; then
  forget_done
  block "Your status file does not exist: $path. Create it now (frontmatter with task, role, model, state, updated; sections Progress, Assumptions, Questions, Findings) and keep it current. $minimal"
fi

state=$(awk '
  NR == 1 && $0 !~ /^---/ { exit }
  NR > 1 && /^---/ { exit }
  /^state:/ { sub(/^state:[ \t]*/, ""); sub(/[ \t]*#.*/, ""); sub(/[ \t\r]+$/, ""); print; exit }
' "$path" 2>/dev/null || true)
state=$(printf '%s' "$state" | sed "s/^[\"']//; s/[\"']\$//")

case "$state" in
  blocked) allow ;;
  done | failed) ;;
  '') forget_done; block "Your status file $path has no state: line in a frontmatter block (--- lines at the top). Add one, set to done, blocked or failed, and update the updated field. If you could not do the task, set state: failed. $minimal" ;;
  *) forget_done; block "Your status file $path has state: '$state', which is not final. Set the frontmatter state to done, blocked or failed and update the updated field. If you could not do the task, set state: failed. $minimal" ;;
esac

# A finished employee answering a follow-up needs no new report.
if [ -n "$marker" ] && [ -f "$marker" ]; then
  allow
fi

has_message=0
if [ "$use_jq" = 1 ]; then
  if printf '%s' "$input" | jq -e 'has("last_assistant_message")' >/dev/null 2>&1; then
    has_message=1
    message=$(printf '%s' "$input" | jq -r '.last_assistant_message // ""' 2>/dev/null || true)
  fi
else
  case "$flat" in
    *'"last_assistant_message"'*)
      has_message=1
      message=$(printf '%s' "$flat" | sed -n 's/.*"last_assistant_message"//p' 2>/dev/null || true)
      ;;
  esac
fi
[ "$has_message" = 1 ] || allow

missing=
for heading in "Outcome" "Changed" "Evidence" "Assumptions" "Open questions" "Findings"; do
  if ! printf '%s' "$message" | grep -qi -F "$heading"; then
    missing="${missing:+$missing, }$heading"
  fi
done
if [ -n "$missing" ]; then
  block "Your status file $path says state: $state, but your final reply lacks these sections: $missing. End your reply with all six sections, in order: Outcome, Changed, Evidence, Assumptions, Open questions, Findings."
fi
[ -z "$marker" ] || touch "$marker" 2>/dev/null || true
allow
