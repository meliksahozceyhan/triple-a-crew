#!/bin/sh
# Model-free tests for the crew hooks. Usage: sh plugins/triple-a-crew/scripts/test-hooks.sh

here=$(cd "$(dirname "$0")" && pwd)
tmp=$(mktemp -d)
CLAUDE_PLUGIN_DATA="$tmp/data"
export CLAUDE_PLUGIN_DATA
trap 'rm -rf "$tmp"' EXIT
fail=0
have_jq=0
command -v jq >/dev/null 2>&1 && have_jq=1
have_py=0
command -v python3 >/dev/null 2>&1 && have_py=1
[ "$have_jq" = 1 ] || echo "note: jq not installed, running the no-jq mode only"
[ "$have_jq" = 1 ] || [ "$have_py" = 1 ] || echo "note: no jq or python3, JSON validity is not checked"

modes="nojq"
[ "$have_jq" = 1 ] && modes="jq nojq"

shell=${HOOK_SH:-sh}
pass() { echo "ok   $1 [$2 $shell]"; }
bad() { echo "FAIL $1 [$2 $shell]: $3"; fail=1; }

valid_json() {
  if [ "$have_jq" = 1 ]; then
    printf '%s' "$1" | jq -e . >/dev/null 2>&1
  elif [ "$have_py" = 1 ]; then
    printf '%s' "$1" | python3 -c 'import json,sys; json.load(sys.stdin)' >/dev/null 2>&1
  else
    return 0
  fi
}

# run <mode> <script> <stdin-file>: sets $out and $rc
run() {
  if [ "$1" = nojq ]; then
    out=$(env HOME="${RUNHOME:-$HOME}" HOOKS_NO_JQ=1 "$shell" "$here/$2" <"$3" 2>/dev/null)
  else
    out=$(env HOME="${RUNHOME:-$HOME}" "$shell" "$here/$2" <"$3" 2>/dev/null)
  fi
  rc=$?
}

# expect_silent <name> <mode>
expect_silent() {
  if [ "$rc" != 0 ]; then bad "$1" "$2" "exit $rc"
  elif [ -n "$out" ]; then bad "$1" "$2" "unexpected output: $out"
  else pass "$1" "$2"; fi
}

# expect_block <name> <mode> <substring>
expect_block() {
  if [ "$rc" != 0 ]; then bad "$1" "$2" "exit $rc"
  elif ! valid_json "$out"; then bad "$1" "$2" "invalid JSON: $out"
  else
    case "$out" in
      '{"decision":"block"'*) ;;
      *) bad "$1" "$2" "not a block: $out"; return ;;
    esac
    case "$out" in
      *"$3"*) pass "$1" "$2" ;;
      *) bad "$1" "$2" "reason lacks '$3': $out" ;;
    esac
  fi
}

# ---- session-start ----
mkproj() { # <dir> <index-body>
  mkdir -p "$1/.crew/work"
  printf '# Work items\n\n%s\n' "$2" >"$1/.crew/work/index.md"
}
stdin_cwd() { printf '{"hook_event_name":"SessionStart","cwd":"%s","source":"startup"}' "$1" >"$tmp/in.json"; }

mkdir -p "$tmp/none"
mkproj "$tmp/two" '## Open
- `alpha` (L) - implement
- `beta` (M) - approved

## Closed
- `gamma` (S) - done'
mkproj "$tmp/many" "## Open
$(i=1; while [ $i -le 30 ]; do echo "- \`item$i\` (S) - open"; i=$((i + 1)); done)

## Closed
- \`old\` - done"
mkproj "$tmp/empty" '## Open

## Closed
- `gamma` - done'
mkdir -p "$tmp/two/src/deep" "$tmp/two/.git" "$tmp/many/.git" "$tmp/empty/.git"

mkproj "$tmp/outer" '## Open
- `outeritem` - open'
mkdir -p "$tmp/outer/inner/sub" "$tmp/outer/inner/.git"
mkproj "$tmp/home" '## Open
- `homeitem` - open'
mkdir -p "$tmp/home/other/sub" "$tmp/home/other/.git" "$tmp/home/plain"
mkproj "$tmp/home/proj" '## Open
- `projitem` - open'
mkdir -p "$tmp/home/proj/sub" "$tmp/home/proj/.git"
mkproj "$tmp/long" "## Open
- $(awk 'BEGIN { for (i = 0; i < 20000; i++) printf "x" }')"
mkdir -p "$tmp/long/.git"

for m in $modes; do
  stdin_cwd "$tmp/none"; run $m session-start.sh "$tmp/in.json"
  expect_silent "session-start: no .crew" $m

  stdin_cwd "$tmp/two"; run $m session-start.sh "$tmp/in.json"
  case "$out" in
    *"Open Triple-A-Crew work items"*alpha*beta*) case "$out" in *gamma*) bad "session-start: two open" $m "closed item listed" ;; *) pass "session-start: two open, closed hidden" $m ;; esac ;;
    *) bad "session-start: two open" $m "output: $out" ;;
  esac

  stdin_cwd "$tmp/many"; run $m session-start.sh "$tmp/in.json"
  lines=$(printf '%s\n' "$out" | wc -l | tr -d ' ')
  case "$out" in
    *item15*) case "$out" in *item16*) bad "session-start: cap" $m "item16 listed" ;; *"... and 15 more") [ "$lines" = 17 ] && pass "session-start: 30 items capped at 15" $m || bad "session-start: cap" $m "$lines lines" ;; *) bad "session-start: cap" $m "no more-line: $out" ;; esac ;;
    *) bad "session-start: cap" $m "item15 missing" ;;
  esac

  stdin_cwd "$tmp/two/src/deep"; run $m session-start.sh "$tmp/in.json"
  case "$out" in *alpha*) pass "session-start: subfolder cwd finds root" $m ;; *) bad "session-start: subfolder" $m "output: $out" ;; esac

  stdin_cwd "$tmp/empty"; run $m session-start.sh "$tmp/in.json"
  expect_silent "session-start: empty Open section" $m

  # R2: Windows line endings
  mkdir -p "$tmp/crlf/.git" "$tmp/crlf/.crew/work"
  printf '# Work items\r\n\r\n## Open\r\n- `delta` (M) - implement\r\n\r\n## Closed\r\n- `eps` (S) - done\r\n' >"$tmp/crlf/.crew/work/index.md"
  stdin_cwd "$tmp/crlf"; run $m session-start.sh "$tmp/in.json"
  case "$out" in
    *"$(printf '\r')"*) bad "session-start: CRLF index" $m "carriage return in output" ;;
    *delta*) case "$out" in *eps*) bad "session-start: CRLF index" $m "closed item listed" ;; *) pass "session-start: CRLF index" $m ;; esac ;;
    *) bad "session-start: CRLF index" $m "output: $out" ;;
  esac

  # nested repo under a project with .crew: only the inner repo's own index counts
  stdin_cwd "$tmp/outer/inner/sub"; run $m session-start.sh "$tmp/in.json"
  expect_silent "session-start: git root below an outer .crew is not crossed" $m

  # $HOME boundary
  stdin_cwd "$tmp/home/other/sub"; RUNHOME="$tmp/home" run $m session-start.sh "$tmp/in.json"
  expect_silent "session-start: index in HOME is not shown for a project below it" $m
  stdin_cwd "$tmp/home/plain"; RUNHOME="$tmp/home" run $m session-start.sh "$tmp/in.json"
  expect_silent "session-start: no git root below HOME reads only cwd" $m
  stdin_cwd "$tmp/home"; RUNHOME="$tmp/home" run $m session-start.sh "$tmp/in.json"
  case "$out" in *homeitem*) pass "session-start: cwd is HOME reads HOME's index" $m ;; *) bad "session-start: HOME cwd" $m "output: $out" ;; esac
  stdin_cwd "$tmp/home/proj/sub"; RUNHOME="$tmp/home" run $m session-start.sh "$tmp/in.json"
  case "$out" in *projitem*) pass "session-start: git root below HOME is used" $m ;; *) bad "session-start: git root" $m "output: $out" ;; esac

  stdin_cwd "$tmp/long"; run $m session-start.sh "$tmp/in.json"
  longest=$(printf '%s\n' "$out" | awk '{ if (length($0) > m) m = length($0) } END { print m + 0 }')
  [ "$longest" -le 200 ] && pass "session-start: long lines cut to 200" $m || bad "session-start: long line" $m "$longest characters"

  echo 'not json' >"$tmp/in.json"; run $m session-start.sh "$tmp/in.json"
  [ "$rc" = 0 ] && pass "session-start: garbage stdin exits 0" $m || bad "session-start: garbage" $m "exit $rc"
done

# ---- subagent-start ----
for m in $modes; do
  echo '{"hook_event_name":"SubagentStart","agent_type":"triple-a-crew:engineer"}' >"$tmp/in.json"
  run $m subagent-start.sh "$tmp/in.json"
  if [ "$rc" != 0 ] || ! valid_json "$out"; then
    bad "subagent-start: valid JSON" $m "rc=$rc out=$out"
  elif [ "${#out}" -ge 1500 ]; then
    bad "subagent-start: size" $m "${#out} characters"
  else
    case "$out" in
      *"names no status file"*'"additionalContext"'*|*'"additionalContext"'*"names no status file"*) pass "subagent-start: valid JSON, ${#out} characters" $m ;;
      *) bad "subagent-start" $m "no additionalContext" ;;
    esac
  fi
  echo 'not json' >"$tmp/in.json"; run $m subagent-start.sh "$tmp/in.json"
  [ "$rc" = 0 ] && pass "subagent-start: garbage stdin exits 0" $m || bad "subagent-start: garbage" $m "exit $rc"
done

# ---- subagent-stop ----
full='## Outcome\nok\n## Changed\nx\n## Evidence\nx\n## Assumptions\nx\n## Open questions\nnone\n## Findings\nnone'
part='Done, all good.'

# transcript <name> <json-escaped path or empty>
transcript() {
  if [ -n "$2" ]; then
    printf '{"isSidechain":true,"type":"user","message":{"role":"user","content":"# T1: x\\n\\n**Work item:** w\\n**Status file:** `%s`\\n\\n## Goal\\nx"}}\n' "$2" >"$tmp/$1.jsonl"
  else
    printf '{"isSidechain":true,"type":"user","message":{"role":"user","content":"# T1: x\\n\\n## Goal\\nx"}}\n' >"$tmp/$1.jsonl"
  fi
}
statusfile() { # <path> <state-line>
  printf -- '---\ntask: T1\nrole: engineer\nmodel: sonnet\n%s\nupdated: 2026-10-19\n---\n## Progress\n' "$2" >"$1"
}
stop_in() { # <transcript-name> <message> [agent-id]
  printf '{"hook_event_name":"SubagentStop","agent_id":"%s","agent_transcript_path":"%s","last_assistant_message":"%s","stop_hook_active":false}' "${3:-}" "$tmp/$1.jsonl" "$2" >"$tmp/in.json"
}

for m in $modes; do
  # no transcript file
  printf '{"agent_transcript_path":"%s/missing.jsonl","last_assistant_message":"x"}' "$tmp" >"$tmp/in.json"
  run $m subagent-stop.sh "$tmp/in.json"; expect_silent "subagent-stop: no transcript" $m

  transcript nostatus ""; stop_in nostatus "$part"
  run $m subagent-stop.sh "$tmp/in.json"; expect_silent "subagent-stop: brief without status line" $m

  transcript t1 "$tmp/s1.md"; rm -f "$tmp/s1.md"; stop_in t1 "$part"
  run $m subagent-stop.sh "$tmp/in.json"; expect_block "subagent-stop: missing file blocks" $m "$tmp/s1.md"
  case "$out" in *"state: failed"*) pass "subagent-stop: missing-file reason explains state: failed" $m ;; *) bad "subagent-stop: failed hint" $m "$out" ;; esac

  statusfile "$tmp/s1.md" "state: in-progress   # in-progress | blocked | done | failed"
  run $m subagent-stop.sh "$tmp/in.json"; expect_block "subagent-stop: in-progress blocks" $m "not final"

  statusfile "$tmp/s1.md" "state: done"
  run $m subagent-stop.sh "$tmp/in.json"; expect_block "subagent-stop: done without headings blocks" $m "Open questions"

  stop_in t1 "$full"
  run $m subagent-stop.sh "$tmp/in.json"; expect_silent "subagent-stop: done with all six headings" $m

  statusfile "$tmp/s1.md" "state: done   # finished"
  run $m subagent-stop.sh "$tmp/in.json"; expect_silent "subagent-stop: done with trailing comment" $m

  statusfile "$tmp/s1.md" "state: failed"; stop_in t1 "$part"
  run $m subagent-stop.sh "$tmp/in.json"; expect_block "subagent-stop: failed without headings blocks" $m "Outcome"

  statusfile "$tmp/s1.md" "state: blocked"
  run $m subagent-stop.sh "$tmp/in.json"; expect_silent "subagent-stop: blocked needs no report" $m

  # double quote in the path: the reason must stay valid JSON
  transcript tq "$tmp/q\\\"uote.md"; stop_in tq "$part"
  run $m subagent-stop.sh "$tmp/in.json"
  if [ "$rc" != 0 ]; then
    bad "subagent-stop: quote in path" $m "rc=$rc"
  elif [ -n "$out" ]; then
    valid_json "$out" || bad "subagent-stop: quote in path" $m "invalid JSON: $out"
    case "$out" in '{"decision":"block"'*) pass "subagent-stop: quote in path keeps JSON valid" $m ;; *) bad "subagent-stop: quote" $m "$out" ;; esac
  elif [ "$m" = nojq ]; then
    pass "subagent-stop: quote in path, truncated path is not trapped" $m
  else
    bad "subagent-stop: quote in path" $m "no block"
  fi
  echo 'not json' >"$tmp/in.json"; run $m subagent-stop.sh "$tmp/in.json"
  [ "$rc" = 0 ] && [ -z "$out" ] && pass "subagent-stop: garbage stdin exits 0" $m || bad "subagent-stop: garbage" $m "rc=$rc out=$out"
done

# raw status line text: brief_line <name> <text after the marker>
brief_line() {
  printf '{"isSidechain":true,"type":"user","message":{"role":"user","content":"# T1: x\\n\\n**Status file:** %s\\n\\n## Goal\\nx"}}\n' "$2" >"$tmp/$1.jsonl"
}

mkdir -p "$tmp/with space"
for m in $modes; do
  sp="$tmp/with space/s.md"
  brief_line tsp "$sp"; stop_in tsp "$full"
  statusfile "$sp" "state: done"
  run $m subagent-stop.sh "$tmp/in.json"; expect_silent "subagent-stop: path with space, file present" $m
  rm -f "$sp"
  run $m subagent-stop.sh "$tmp/in.json"; expect_block "subagent-stop: path with space, file missing names full path" $m "$sp"

  tp="$tmp/trail.md"
  brief_line ttr "$tp -- write hello to x"; stop_in ttr "$full"
  statusfile "$tp" "state: done"
  run $m subagent-stop.sh "$tmp/in.json"; expect_silent "subagent-stop: trailing text, file present" $m
  rm -f "$tp"
  run $m subagent-stop.sh "$tmp/in.json"
  expect_block "subagent-stop: trailing text, file missing names the path" $m "Your status file does not exist: $tp."

  brief_line tnp "see below"; stop_in tnp "$full"
  run $m subagent-stop.sh "$tmp/in.json"; expect_silent "subagent-stop: status text is not a path" $m
done

# ---- review fixes ----
for m in $modes; do
  sf="$tmp/real-$m.md"; statusfile "$sf" "state: done"

  # M1: the real header comes first, a later line quotes the protocol example
  printf '{"message":{"role":"user","content":"# T1\\n\\n**Status file:** %s\\n\\n## Context\\n- protocol: **Status file:** /abs/path/to/repo/.crew/work/x/team/T2-engineer.md\\n"}}\n' "$sf" >"$tmp/m1.jsonl"
  stop_in m1 "$full"; run $m subagent-stop.sh "$tmp/in.json"
  expect_silent "subagent-stop: first Status file line wins over a quoted example" $m

  # M1: marker only mid-sentence
  printf '{"message":{"role":"user","content":"Explain the line **Status file:** /abs/repo/.crew/work/x/team/T2-engineer.md in protocol.md"}}\n' >"$tmp/m1b.jsonl"
  stop_in m1b "$part"; run $m subagent-stop.sh "$tmp/in.json"
  expect_silent "subagent-stop: marker mid-sentence is ignored" $m

  # M2: no last_assistant_message key
  transcript m2 "$sf"
  printf '{"hook_event_name":"SubagentStop","agent_transcript_path":"%s"}' "$tmp/m2.jsonl" >"$tmp/in.json"
  run $m subagent-stop.sh "$tmp/in.json"
  expect_silent "subagent-stop: missing last_assistant_message skips the report check" $m

  # S1: at most 3 blocks per agent, counter removed afterwards
  sg="$tmp/guard-$m.md"; statusfile "$sg" "state: in-progress"
  transcript g "$sg"; stop_in g "$part" "guard$m"
  run $m subagent-stop.sh "$tmp/in.json"; expect_block "subagent-stop: guard block 1" $m "not final"
  run $m subagent-stop.sh "$tmp/in.json"; expect_block "subagent-stop: guard block 2" $m "not final"
  run $m subagent-stop.sh "$tmp/in.json"; expect_block "subagent-stop: guard block 3" $m "not final"
  run $m subagent-stop.sh "$tmp/in.json"; expect_silent "subagent-stop: guard allows the 4th stop" $m
  [ ! -e "$tmp/data/triple-a-crew-stop-guard$m" ] && pass "subagent-stop: guard counter deleted after allowing" $m || bad "subagent-stop: guard counter" $m "still present"

  # S1: counter deleted when the hook allows the stop
  run $m subagent-stop.sh "$tmp/in.json" >/dev/null
  [ -e "$tmp/data/triple-a-crew-stop-guard$m" ] || bad "subagent-stop: counter written" $m "missing"
  statusfile "$sg" "state: blocked"; run $m subagent-stop.sh "$tmp/in.json"
  [ -z "$out" ] && [ ! -e "$tmp/data/triple-a-crew-stop-guard$m" ] && pass "subagent-stop: counter deleted on allow" $m || bad "subagent-stop: counter on allow" $m "out=$out"

  # S2: a finished employee answering a follow-up
  sd="$tmp/follow-$m.md"; statusfile "$sd" "state: done"
  transcript fu "$sd"
  stop_in fu "$part" "follow$m"; run $m subagent-stop.sh "$tmp/in.json"
  expect_block "subagent-stop: no marker yet, short reply blocks" $m "Outcome"
  stop_in fu "$full" "follow$m"; run $m subagent-stop.sh "$tmp/in.json"
  expect_silent "subagent-stop: complete report allowed" $m
  [ -e "$tmp/data/triple-a-crew-done-follow$m" ] && pass "subagent-stop: done marker written" $m || bad "subagent-stop: marker" $m "missing"
  stop_in fu "Because the cap is 9." "follow$m"; run $m subagent-stop.sh "$tmp/in.json"
  expect_silent "subagent-stop: follow-up answer needs no report" $m
  statusfile "$sd" "state: in-progress"
  run $m subagent-stop.sh "$tmp/in.json"; expect_block "subagent-stop: follow-up still needs a final state" $m "not final"
  [ ! -e "$tmp/data/triple-a-crew-done-follow$m" ] && pass "subagent-stop: non-final state forgets the done marker" $m || bad "subagent-stop: R4 marker" $m "still there"
  rm -f "$sd"
  run $m subagent-stop.sh "$tmp/in.json"; expect_block "subagent-stop: follow-up still needs the file" $m "does not exist"

  # R3: old counters and markers are pruned
  touch -t 202001010000 "$tmp/data/triple-a-crew-done-ancient$m"
  stop_in fu "$full" "prune$m"; statusfile "$sd" "state: done"; run $m subagent-stop.sh "$tmp/in.json"
  [ ! -e "$tmp/data/triple-a-crew-done-ancient$m" ] && pass "subagent-stop: week-old state files pruned" $m || bad "subagent-stop: prune" $m "old marker kept"

  # R1: an unwritable data folder never turns into a block (skipped as root, where chmod has no effect)
  if [ "$(id -u)" != 0 ]; then
    mkdir -p "$tmp/ro-$m"; chmod 555 "$tmp/ro-$m"
    stop_in fu "$full" "ro$m"
    CLAUDE_PLUGIN_DATA="$tmp/ro-$m"; run $m subagent-stop.sh "$tmp/in.json"; CLAUDE_PLUGIN_DATA="$tmp/data"
    expect_silent "subagent-stop: unwritable data folder, good employee allowed" $m
    statusfile "$sd" "state: in-progress"
    CLAUDE_PLUGIN_DATA="$tmp/ro-$m"; run $m subagent-stop.sh "$tmp/in.json"; CLAUDE_PLUGIN_DATA="$tmp/data"
    expect_block "subagent-stop: unwritable data folder still blocks a real problem" $m "not final"
    chmod 755 "$tmp/ro-$m"
  fi

  # S3: ~/ expands to $HOME
  mkdir -p "$tmp/home"; statusfile "$tmp/home/tilde-$m.md" "state: done"
  brief_line tt "~/tilde-$m.md"; stop_in tt "$full"
  RUNHOME="$tmp/home" run $m subagent-stop.sh "$tmp/in.json"
  expect_silent "subagent-stop: ~/ path expands to HOME" $m

  # N1: quoted state, no frontmatter
  transcript n1 "$sf"; stop_in n1 "$full"
  statusfile "$sf" 'state: "done"'; run $m subagent-stop.sh "$tmp/in.json"
  expect_silent "subagent-stop: double-quoted state" $m
  statusfile "$sf" "state: 'done'"; run $m subagent-stop.sh "$tmp/in.json"
  expect_silent "subagent-stop: single-quoted state" $m
  printf '# no frontmatter\n' >"$sf"; run $m subagent-stop.sh "$tmp/in.json"
  expect_block "subagent-stop: no frontmatter gets a clear reason" $m "has no state: line in a frontmatter block (--- lines at the top)"
done

# ---- teammates: matcher and wrapped brief ----
# The matcher is read from hooks.json itself, so an edit there cannot drift from the test.
hooks_json="$here/../hooks/hooks.json"
for ev in SubagentStart SubagentStop; do
  rx=$(awk -v ev="\"$ev\"" '
    index($0, ev) { on = 1 }
    on && /"matcher"/ { sub(/^[^:]*: *"/, ""); sub(/",? *$/, ""); print; exit }
  ' "$hooks_json")
  [ -n "$rx" ] || { bad "$ev matcher" - "not found in hooks.json"; continue; }
  for name in triple-a-crew:engineer triple-a-crew:test-engineer T2-engineer T4b-test-engineer T10-researcher t1-researcher T3-verifier T5c-reviewer; do
    if printf '%s\n' "$name" | grep -Eq -- "$rx"; then pass "$ev matcher accepts $name" -
    else bad "$ev matcher accepts $name" - "rejected by $rx"; fi
  done
  # Every agent file is a role the teammate half must list; a new agent fails here until it is added.
  for f in "$here"/../agents/*.md; do
    role=$(sed -n 's/^name: *//p' "$f" | head -n 1)
    [ -n "$role" ] || continue
    if printf '%s\n' "T1-$role" | grep -Eq -- "$rx"; then pass "$ev matcher covers agent $role" -
    else bad "$ev matcher covers agent $role" - "add $role to the teammate roles in hooks.json"; fi
  done
  for name in probe general-purpose Explore "" T2-nosuchrole T-engineer T2-Engineer T2ab-engineer T2-engineer-2 xT2-engineer triple-a-crew: Triple-A-Crew:engineer; do
    if printf '%s\n' "$name" | grep -Eq -- "$rx"; then bad "$ev matcher ignores '$name'" - "accepted by $rx"
    else pass "$ev matcher ignores '$name'" -; fi
  done
done

# A teammate's first line wraps the brief in <teammate-message ...>; the summary may quote the marker.
# tm_transcript <name> <status path>
tm_transcript() {
  printf '{"isSidechain":true,"type":"user","message":{"role":"user","content":"<teammate-message teammate_id=\\"team-lead\\" summary=\\"Do **Status file:** /nowhere/wrong.md first\\">\\n# T2: x\\n\\n**Work item:** w\\n**Status file:** %s\\n\\n## Goal\\nx\\n</teammate-message>"}}\n' "$2" >"$tmp/$1.jsonl"
}
tm_stop_in() { # <transcript-name> <message> <agent-id>
  printf '{"hook_event_name":"SubagentStop","agent_id":"%s","agent_type":"T2-engineer","agent_transcript_path":"%s","last_assistant_message":"%s","stop_hook_active":false}' "$3" "$tmp/$1.jsonl" "$2" >"$tmp/in.json"
}

for m in $modes; do
  tf="$tmp/team-$m.md"; rm -f "$tf"
  tm_transcript tm "$tf"; tm_stop_in tm "$full" "tm$m"
  run $m subagent-stop.sh "$tmp/in.json"
  expect_block "subagent-stop: teammate, missing file blocks" $m "Your status file does not exist: $tf."

  statusfile "$tf" "state: done"
  run $m subagent-stop.sh "$tmp/in.json"
  expect_silent "subagent-stop: teammate, done with full report" $m

  tm_stop_in tm "$part" "tmb$m"
  run $m subagent-stop.sh "$tmp/in.json"
  expect_block "subagent-stop: teammate, done without report blocks" $m "Open questions"

  # internal helper event: empty agent_type and no brief to read
  printf '{"hook_event_name":"SubagentStop","agent_id":"h%s","agent_type":"","agent_transcript_path":"%s/none.jsonl","last_assistant_message":"x"}' "$m" "$tmp" >"$tmp/in.json"
  run $m subagent-stop.sh "$tmp/in.json"; expect_silent "subagent-stop: helper event with empty agent_type" $m
done

# Repeat everything under dash (the default /bin/sh on Debian and Ubuntu) when it is installed:
# it is stricter than macOS sh, for example a failed redirection on a special builtin exits the script.
if [ -z "${HOOK_SH:-}" ] && command -v dash >/dev/null 2>&1; then
  HOOK_SH=dash sh "$0" || fail=1
fi
if [ -z "${HOOK_SH:-}" ]; then
  if [ "$fail" = 0 ]; then echo "all hook tests passed"; else echo "hook tests FAILED"; fi
fi
exit "$fail"
