#!/bin/sh
# Model-free tests for session-start.sh (definition stamp) and definitions-check.sh.
# Usage: sh plugins/triple-a-crew/scripts/test-definitions-check.sh

here=$(cd "$(dirname "$0")" && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fail=0
have_jq=0
command -v jq >/dev/null 2>&1 && have_jq=1
have_py=0
command -v python3 >/dev/null 2>&1 && have_py=1
[ "$have_jq" = 1 ] || echo "note: jq not installed, running the no-jq mode only"

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

# run <mode> <script> <stdin-file>: sets $out and $rc; uses $root and $data
run() {
  if [ "$1" = nojq ]; then
    out=$(env HOOKS_NO_JQ=1 CLAUDE_PLUGIN_ROOT="$root" CLAUDE_PLUGIN_DATA="$data" "$shell" "$here/$2" <"$3" 2>/dev/null)
  else
    out=$(env CLAUDE_PLUGIN_ROOT="$root" CLAUDE_PLUGIN_DATA="$data" "$shell" "$here/$2" <"$3" 2>/dev/null)
  fi
  rc=$?
}

expect_silent() {
  if [ "$rc" != 0 ]; then bad "$1" "$2" "exit $rc"
  elif [ -n "$out" ]; then bad "$1" "$2" "unexpected output: $out"
  else pass "$1" "$2"; fi
}

# expect_warn <name> <mode> <role>
expect_warn() {
  if [ "$rc" != 0 ]; then bad "$1" "$2" "exit $rc"
  elif ! valid_json "$out"; then bad "$1" "$2" "invalid JSON: $out"
  else
    want="{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"additionalContext\":\"Triple-A-Crew: agents/$3.md changed after this session loaded it. Unless /reload-plugins has run since that change, the employee about to start runs on the old definition: ask the user to run /reload-plugins, then staff again. This note is shown once per change.\"}}"
    if [ "$out" = "$want" ]; then pass "$1" "$2"; else bad "$1" "$2" "not the warning for $3: $out"; fi
  fi
}

start_in() { # <session> <source>
  printf '{"hook_event_name":"SessionStart","session_id":"%s","source":"%s","cwd":"%s"}' "$1" "$2" "$tmp/nowhere" >"$tmp/in.json"
}
agent_in() { # <session> <subagent_type>
  printf '{"hook_event_name":"PreToolUse","session_id":"%s","tool_name":"Agent","tool_input":{"subagent_type":"%s","prompt":"x"}}' "$1" "$2" >"$tmp/in.json"
}

mkdir -p "$tmp/nowhere"
n=0
for m in $modes; do
  n=$((n + 1))
  root="$tmp/root$n"
  data="$tmp/data$n"
  mkdir -p "$root/agents"
  printf 'engineer v1\n' >"$root/agents/engineer.md"
  printf 'reviewer v1\n' >"$root/agents/reviewer.md"
  s="sess$n"
  state="$data/triple-a-crew-defs-$s"

  # session-start: silent, writes one line per agent
  start_in "$s" startup; run $m session-start.sh "$tmp/in.json"
  expect_silent "session-start: stamp is silent" $m
  lines=$(wc -l <"$state" 2>/dev/null | tr -d ' ')
  [ "$lines" = 2 ] && pass "session-start: one stamp line per agent" $m || bad "session-start: stamp" $m "lines=$lines"

  agent_in "$s" triple-a-crew:engineer; run $m definitions-check.sh "$tmp/in.json"
  expect_silent "check: nothing changed" $m

  printf 'engineer v2\n' >"$root/agents/engineer.md"
  run $m definitions-check.sh "$tmp/in.json"
  expect_warn "check: changed file is reported" $m engineer
  run $m definitions-check.sh "$tmp/in.json"
  expect_silent "check: same change reported once" $m
  agent_in "$s" triple-a-crew:reviewer; run $m definitions-check.sh "$tmp/in.json"
  expect_silent "check: unchanged role stays silent" $m

  printf 'engineer v3 longer\n' >"$root/agents/engineer.md"
  agent_in "$s" triple-a-crew:engineer; run $m definitions-check.sh "$tmp/in.json"
  expect_warn "check: second change reported again" $m engineer
  case "$out" in *reviewer*) bad "check: names only the changed file" $m "$out" ;; *) pass "check: names only the changed file" $m ;; esac

  # clear and compact keep the stamp; startup and resume replace it
  printf 'engineer v4\n' >"$root/agents/engineer.md"
  for src in clear compact; do
    start_in "$s" $src; run $m session-start.sh "$tmp/in.json"
    expect_silent "session-start: $src prints nothing" $m
  done
  agent_in "$s" triple-a-crew:engineer; run $m definitions-check.sh "$tmp/in.json"
  expect_warn "check: stamp survives clear and compact" $m engineer
  printf 'engineer v5\n' >"$root/agents/engineer.md"
  start_in "$s" resume; run $m session-start.sh "$tmp/in.json"
  run $m definitions-check.sh "$tmp/in.json"
  expect_silent "check: resume stamps the current files" $m

  # two roles changed, checked one after the other: each is reported once
  printf 'engineer v5b\n' >"$root/agents/engineer.md"
  printf 'reviewer v2\n' >"$root/agents/reviewer.md"
  agent_in "$s" triple-a-crew:engineer; run $m definitions-check.sh "$tmp/in.json"
  expect_warn "check: two changed roles, first reported" $m engineer
  agent_in "$s" triple-a-crew:reviewer; run $m definitions-check.sh "$tmp/in.json"
  expect_warn "check: two changed roles, second reported" $m reviewer
  agent_in "$s" triple-a-crew:engineer; run $m definitions-check.sh "$tmp/in.json"
  expect_silent "check: two changed roles, first not repeated" $m
  agent_in "$s" triple-a-crew:reviewer; run $m definitions-check.sh "$tmp/in.json"
  expect_silent "check: two changed roles, second not repeated" $m
  lines=$(wc -l <"$state" | tr -d ' ')
  [ "$lines" = 2 ] && pass "check: state keeps one line per role" $m || bad "check: state lines" $m "lines=$lines"

  # silent cases
  printf 'engineer v6\n' >"$root/agents/engineer.md"
  agent_in "$s" triple-a-crew:nosuchrole; run $m definitions-check.sh "$tmp/in.json"
  expect_silent "check: unknown role" $m
  agent_in "$s" general-purpose; run $m definitions-check.sh "$tmp/in.json"
  expect_silent "check: non-crew subagent_type" $m
  agent_in "$s" "triple-a-crew:../x"; run $m definitions-check.sh "$tmp/in.json"
  expect_silent "check: role with a path is ignored" $m
  agent_in "other$n" triple-a-crew:engineer; run $m definitions-check.sh "$tmp/in.json"
  expect_silent "check: no state file for this session" $m
  printf '{"tool_input":{"subagent_type":"triple-a-crew:engineer"}}' >"$tmp/in.json"
  run $m definitions-check.sh "$tmp/in.json"
  expect_silent "check: no session_id" $m
  echo 'not json' >"$tmp/in.json"; run $m definitions-check.sh "$tmp/in.json"
  expect_silent "check: garbage stdin" $m
  : >"$tmp/in.json"; run $m definitions-check.sh "$tmp/in.json"
  expect_silent "check: empty stdin" $m

  # session-start without session_id writes nothing
  printf '{"source":"startup","cwd":"%s"}' "$tmp/nowhere" >"$tmp/in.json"
  before=$(ls "$data" | wc -l | tr -d ' ')
  run $m session-start.sh "$tmp/in.json"
  after=$(ls "$data" | wc -l | tr -d ' ')
  [ "$before" = "$after" ] && [ -z "$out" ] && pass "session-start: no session_id writes no stamp" $m || bad "session-start: no session_id" $m "files $before -> $after out=$out"

  # output of session-start with an open work item is unchanged by the stamp
  mkdir -p "$tmp/proj$n/.git" "$tmp/proj$n/.crew/work"
  printf '# Work items\n\n## Open\n- `alpha` (S) - open\n' >"$tmp/proj$n/.crew/work/index.md"
  printf '{"session_id":"%s","source":"startup","cwd":"%s"}' "p$n" "$tmp/proj$n" >"$tmp/in.json"
  run $m session-start.sh "$tmp/in.json"
  expected="Open Triple-A-Crew work items in this project (from .crew/work/index.md):
- \`alpha\` (S) - open"
  [ "$out" = "$expected" ] && pass "session-start: work item list unchanged" $m || bad "session-start: list" $m "$out"

  # an unwritable state folder never fails a hook (skipped as root, where chmod has no effect)
  if [ "$(id -u)" != 0 ]; then
    ro="$tmp/ro$n"; mkdir -p "$ro"; chmod 555 "$ro"
    saved=$data; data="$ro/sub"
    start_in "ro$n" startup; run $m session-start.sh "$tmp/in.json"
    expect_silent "session-start: unwritable state folder" $m
    printf '{"session_id":"ro%s","source":"startup","cwd":"%s"}' "$n" "$tmp/proj$n" >"$tmp/in.json"
    run $m session-start.sh "$tmp/in.json"
    [ "$rc" = 0 ] && [ "$out" = "$expected" ] && pass "session-start: unwritable state folder keeps its output" $m || bad "session-start: unwritable" $m "rc=$rc out=$out"
    agent_in "ro$n" triple-a-crew:engineer; run $m definitions-check.sh "$tmp/in.json"
    expect_silent "check: unwritable state folder" $m
    # a state file that cannot be rewritten: warning still printed, exit 0
    data=$saved
    start_in "$s" startup; run $m session-start.sh "$tmp/in.json"
    printf 'engineer v7\n' >"$root/agents/engineer.md"
    chmod 555 "$data"; chmod 444 "$state"
    agent_in "$s" triple-a-crew:engineer; run $m definitions-check.sh "$tmp/in.json"
    expect_warn "check: unwritable state still warns and exits 0" $m engineer
    chmod 755 "$data"; chmod 644 "$state"; chmod 755 "$ro"
  fi
done

# Repeat everything under dash (the default /bin/sh on Debian and Ubuntu) when it is installed.
if [ -z "${HOOK_SH:-}" ] && command -v dash >/dev/null 2>&1; then
  HOOK_SH=dash sh "$0" || fail=1
fi
if [ -z "${HOOK_SH:-}" ]; then
  if [ "$fail" = 0 ]; then echo "all definitions check tests passed"; else echo "definitions check tests FAILED"; fi
fi
exit "$fail"
