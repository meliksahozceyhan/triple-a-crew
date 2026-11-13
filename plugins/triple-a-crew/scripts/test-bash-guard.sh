#!/bin/sh
# Model-free tests for the bash guard hook. Usage: sh plugins/triple-a-crew/scripts/test-bash-guard.sh

here=$(cd "$(dirname "$0")" && pwd)
tmp=$(mktemp -d)
CLAUDE_PLUGIN_DATA="$tmp/data"
export CLAUDE_PLUGIN_DATA
trap 'rm -rf "$tmp"' EXIT
fail=0
have_jq=0
command -v jq >/dev/null 2>&1 && have_jq=1
[ "$have_jq" = 1 ] || echo "note: jq not installed, running the no-jq mode only"

modes="nojq"
[ "$have_jq" = 1 ] && modes="jq nojq"

shell=${HOOK_SH:-sh}
pass() { echo "ok   $1 [$2 $shell]"; }
bad() { echo "FAIL $1 [$2 $shell]: $3"; fail=1; }

# json_str <text>: the text as the inside of a JSON string (newlines become \n)
json_str() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g' | awk 'NR > 1 { printf "\\n" } { printf "%s", $0 }'
}

transcript_path="$tmp/proj/session.jsonl"

# guard_in <agent_type or empty> <command> [agent-id]: writes the PreToolUse input
guard_in() {
  {
    printf '{"session_id":"s1","transcript_path":"%s","cwd":"/x"' "$transcript_path"
    [ -z "${3:-}" ] || printf ',"agent_id":"%s"' "$3"
    [ -z "$1" ] || printf ',"agent_type":"%s"' "$1"
    printf ',"hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"%s","description":"d"},"tool_use_id":"t1"}' "$(json_str "$2")"
  } >"$tmp/in.json"
}

# brief <agent-id> <text>: the subagent transcript whose first line is the brief
brief() {
  mkdir -p "$tmp/proj/session/subagents"
  printf '{"isSidechain":true,"type":"user","message":{"role":"user","content":"%s"}}\n{"type":"assistant"}\n' \
    "$(json_str "$2")" >"$tmp/proj/session/subagents/agent-$1.jsonl"
}

# run <mode>: sets $out, $err and $rc for the input in $tmp/in.json
run() {
  if [ "$1" = nojq ]; then
    out=$(env HOOKS_NO_JQ=1 "$shell" "$here/bash-guard.sh" <"$tmp/in.json" 2>"$tmp/err")
  else
    out=$(env "$shell" "$here/bash-guard.sh" <"$tmp/in.json" 2>"$tmp/err")
  fi
  rc=$?
  err=$(cat "$tmp/err")
}

# expect_silent <name> <mode>
expect_silent() {
  if [ "$rc" != 0 ]; then bad "$1" "$2" "exit $rc: $err"
  elif [ -n "$out" ] || [ -n "$err" ]; then bad "$1" "$2" "unexpected output: $out $err"
  else pass "$1" "$2"; fi
}

# expect_refused <name> <mode> <construct named in the message>
expect_refused() {
  if [ "$rc" != 2 ]; then bad "$1" "$2" "exit $rc, wanted 2"
  elif [ -n "$out" ]; then bad "$1" "$2" "stdout not empty: $out"
  else
    case "$err" in
      *"one plain command per Bash call"*"send it once more unchanged"*) ;;
      *) bad "$1" "$2" "message lacks the rule or the resend hint: $err"; return ;;
    esac
    case "$err" in
      *"contains"*"$3"*) pass "$1" "$2" ;;
      *) bad "$1" "$2" "message does not name '$3': $err" ;;
    esac
  fi
}

# check <mode> <agent-type> <command> <agent-id> <expected: silent or the construct> <name>
check() {
  guard_in "$2" "$3" "$4"; run "$1"
  if [ "$5" = silent ]; then expect_silent "$6" "$1"; else expect_refused "$6" "$1" "$5"; fi
}

emp=triple-a-crew:engineer
for m in $modes; do
  # each mode keeps its own state, so the same agent ids can be reused
  CLAUDE_PLUGIN_DATA="$tmp/data-$m"

  # who is guarded
  check $m "" 'a && b' main1 silent "main session (no agent_type) may chain"
  guard_in "" 'a && b' ""; run $m; expect_silent "main session without any agent fields may chain" $m
  check $m other:worker 'a && b' o1 silent "agent of another plugin may chain"
  check $m triple-a-crew: 'a && b' o2 silent "bare triple-a-crew: is not an employee"
  check $m Triple-A-Crew:engineer 'a && b' o3 silent "agent type is case-sensitive"
  check $m T2-nosuchrole 'a && b' o4 silent "teammate with an unknown role may chain"
  check $m $emp 'git -C /x status' p1 silent "employee plain command"
  check $m T2-engineer 'echo a && echo b' tm1 '&&' "teammate T2-engineer is guarded"
  check $m t10-test-engineer 'a | b' tm2 'pipe' "teammate t10-test-engineer is guarded"
  check $m T3b-verifier 'a ; b' tm3 ';' "teammate T3b-verifier is guarded"

  # refused constructs
  check $m $emp 'echo a && echo b' r1 '&&' "refuses &&"
  check $m $emp 'a || b' r2 '||' "refuses ||"
  check $m $emp 'a ; b' r3 ';' "refuses ;"
  check $m $emp 'a;b' r3b ';' "refuses ; without spaces"
  check $m $emp 'a | b' r4 'pipe' "refuses a pipe"
  check $m $emp 'a|b' r4b 'pipe' "refuses a pipe without spaces"
  check $m $emp 'a > f' r5 'redirection' "refuses >"
  check $m $emp 'a >> f' r5b 'redirection (>>)' "refuses >>"
  check $m $emp 'a < f' r5c 'redirection (<)' "refuses <"
  check $m $emp 'a 2>&1' r5d 'redirection (>&)' "refuses 2>&1"
  check $m $emp 'a 2>/dev/null' r5e 'redirection' "refuses 2>/dev/null"
  check $m $emp 'cat <<EOF
hello
EOF' r5f 'heredoc' "refuses a heredoc"
  check $m $emp 'cd /x' r6 'cd as the command word' "refuses cd"
  check $m $emp 'time ls' r7 'leading time' "refuses a leading time"
  check $m $emp 'echo $?' r8 'echo $?' "refuses echo \$?"
  check $m $emp 'echo "$?"' r8b 'echo $?' "refuses echo \"\$?\""
  check $m $emp 'ls
pwd' r9 'line break' "refuses a two-line command"
  check $m $emp 'cd "web" && pnpm test | tail' r10 '|' "refuses a pipe added to the documented form"
  check $m $emp 'cd "web" && cd "x" && ls' r11 'cd as the command word' "refuses two cd commands"
  check $m $emp 'ls "a b" && pwd' r12 '&&' "refuses && after a quoted word"

  # text that is not syntax
  check $m $emp 'grep "a && b" file' q1 silent "double-quoted && is text"
  check $m $emp 'git commit -m "x; y"' q2 silent "double-quoted ; is text"
  check $m $emp "grep -E 'a|b' file" q3 silent "single-quoted | is text"
  check $m $emp 'echo "a > b"' q4 silent "double-quoted > is text"
  check $m $emp "echo 'a && b > c ; d'" q5 silent "single-quoted chain is text"
  check $m $emp 'echo "say \"a && b\" now"' q6 silent "escaped quotes stay inside the string"
  check $m $emp 'git commit -m "first line
second line"' q7 silent "line break inside double quotes is text"
  check $m $emp 'find . -name x -exec ls {} \;' q8 silent "escaped ; is text"
  check $m $emp 'ls # a && b' q9 silent "comment is text"
  check $m $emp 'curl "https://x/?a=1&b=2"' q10 silent "& in a quoted URL"
  check $m $emp "echo '\$?'" q11 silent "single-quoted \$? is text"
  check $m $emp 'ls "a;b" && pwd; ls' q12 ';' "a real ; after quoted text is found"
  check $m $emp 'echo "it'"'"'s" && ls' q13 '&&' "an apostrophe inside double quotes does not hide a chain"
  check $m $emp 'cd' q14 'cd as the command word' "bare cd is refused"
  check $m $emp 'grep cd file' q15 silent "cd as an argument is fine"
  check $m $emp 'git -C /x log --since=time' q16 silent "time as part of an argument is fine"
  check $m $emp 'echo hello' q17 silent "echo without \$? is fine"

  # exception: the brief lists the command
  brief b1 '# T1: x
Run `cd "web" && pnpm test` as written.'
  check $m $emp 'cd "web" && pnpm test' b1 silent "brief lists the command: allowed"
  check $m $emp 'cd "web" && pnpm lint' b1 '&&' "brief does not list this command: refused"
  brief b2 'Run: cd /tmp/copy && bundle exec rspec | head
and also: ls > out.txt'
  check $m $emp 'cd /tmp/copy && bundle exec rspec | head' b2 silent "brief lists a pipe command"
  check $m $emp 'ls > out.txt' b2 silent "brief lists a redirect command"
  check $m $emp 'ls > other.txt' b2 'redirection' "brief lists a different redirect: refused"
  check $m $emp 'cd "web" && pnpm test' b2 '&&' "readable brief without the documented form: refused"
  brief b3 'two lines:
ls
pwd'
  check $m $emp 'ls
pwd' b3 silent "brief lists a multi-line command"
  brief b4 '<teammate-message teammate_id="lead">
Run: a | b
</teammate-message>'
  check $m T2-engineer 'a | b' b4 silent "brief wrapped in a teammate message"

  # exception: the brief cannot be read
  check $m $emp 'cd "web" && pnpm test' u1 silent "no brief: documented form is allowed"
  check $m $emp "cd 'web dir' && pnpm test" u1b silent "no brief: single-quoted folder is allowed"
  check $m $emp 'echo a && echo b' u2 '&&' "no brief: other chain is refused"
  check $m $emp 'cd web && pnpm test' u3 '&&' "no brief: unquoted folder is refused"
  check $m $emp 'cd "web" && pnpm test; ls' u4 ';' "no brief: documented form plus ; is refused"
  check $m $emp 'cd "web"' u5 'cd as the command word' "no brief: cd alone is refused"
  check $m $emp 'cd "web" &&' u6 '&&' "no brief: documented form without a command is refused"
  mkdir -p "$tmp/proj/session/subagents"
  : >"$tmp/proj/session/subagents/agent-u7.jsonl"
  check $m $emp 'cd "web" && pnpm test' u7 silent "empty brief file counts as unreadable"
  printf 'not json\n' >"$tmp/proj/session/subagents/agent-u8.jsonl"
  check $m $emp 'cd "web" && pnpm test' u8 silent "garbage brief counts as unreadable"
  check $m $emp 'echo a && echo b' u8 '&&' "garbage brief: other chain refused"

  # the resend valve
  check $m $emp 'echo a && echo b' v1 '&&' "valve: first send refused"
  check $m $emp 'echo a && echo b' v1 silent "valve: the same command sent again runs"
  check $m $emp 'echo a && echo b' v1 '&&' "valve: a third send is refused again"
  check $m $emp 'echo a && echo b' v1 silent "valve: and the fourth runs again"
  check $m $emp 'x | y' v2 'pipe' "valve: other agent starts clean"
  check $m $emp 'x | z' v2 'pipe' "valve: a different command is refused"
  check $m $emp 'x | y' v2 'pipe' "valve: the earlier command does not run after a different refusal"
  check $m $emp 'x | y' v2 silent "valve: only the last refusal is remembered"
  check $m $emp 'x | y' v3 'pipe' "valve: refused"
  check $m $emp 'ls' v3 silent "valve: a plain command in between"
  check $m $emp 'x | y' v3 'pipe' "valve: a plain command in between clears the remembered refusal"
  check $m $emp 'x | y' v5 'pipe' "valve: another agent's first send is refused though others sent it"

  # prune of old state
  old="$CLAUDE_PLUGIN_DATA/triple-a-crew-bash-ancient"
  touch -t 202001010000 "$old"
  check $m $emp 'x | y' pr1 'pipe' "prune: a refusal runs the prune"
  [ ! -e "$old" ] && pass "prune: week-old state file removed" $m || bad "prune: week-old state file" $m "still present"

  # the data folder is unusable: a refusal could never be retried, so the call is allowed
  keep=$CLAUDE_PLUGIN_DATA
  CLAUDE_PLUGIN_DATA="$tmp/not-a-dir"; : >"$tmp/not-a-dir"
  check $m $emp 'echo a && echo b' w1 silent "unwritable state folder: allowed, not trapped"
  CLAUDE_PLUGIN_DATA=$keep

  # unreadable input
  : >"$tmp/in.json"; run $m; expect_silent "empty input" $m
  echo 'not json' >"$tmp/in.json"; run $m; expect_silent "malformed input" $m
  echo '{"agent_type":"triple-a-crew:engineer"' >"$tmp/in.json"; run $m; expect_silent "truncated input" $m
  echo '{}' >"$tmp/in.json"; run $m; expect_silent "empty object" $m
  echo '[1,2]' >"$tmp/in.json"; run $m; expect_silent "JSON array input" $m
  printf '{"agent_type":"%s","agent_id":"e1","tool_input":{}}' "$emp" >"$tmp/in.json"; run $m
  expect_silent "employee without a command" $m
  printf '{"agent_type":"%s","agent_id":"e2","tool_input":{"command":42}}' "$emp" >"$tmp/in.json"; run $m
  expect_silent "non-string command" $m
  printf '{"agent_type":"%s","tool_input":{"command":"a && b"}}' "$emp" >"$tmp/in.json"; run $m
  expect_silent "employee without agent_id is not refused (no resend valve possible)" $m
  printf '{"agent_type":"","agent_id":"e3","tool_input":{"command":"a && b"}}' >"$tmp/in.json"; run $m
  expect_silent "empty agent_type" $m
  printf '{"agent_type":"%s","agent_id":"e4","tool_input":{"command":""}}' "$emp" >"$tmp/in.json"; run $m
  expect_silent "empty command" $m

  # JSON escapes the no-jq reader cannot decode: it is unsure and allows, jq refuses
  printf '{"agent_type":"%s","agent_id":"j1","tool_input":{"command":"echo caf\\u00e9 && ls"}}' "$emp" >"$tmp/in.json"; run $m
  if [ "$m" = nojq ]; then expect_silent "no-jq: \\u escape in the command is unsure, allowed" $m
  else expect_refused "jq: \\u escape in the command is decoded and refused" $m '&&'; fi
  printf '{"agent_type":"%s","agent_id":"j2","tool_input":{"command":"echo \\"a\\" && ls\\tx"}}' "$emp" >"$tmp/in.json"; run $m
  expect_refused "escaped quotes and tabs in the JSON are decoded" $m '&&'
  printf '{"tool_input":{"description":"\\"command\\": a && b"},"agent_type":"%s","agent_id":"j3"}' "$emp" >"$tmp/in.json"; run $m
  expect_silent "a quoted word command inside another field is not the command" $m
  printf '{"agent_type":"%s","agent_id":"j4","tool_input":{"description":"say \\"agent_type\\": x","command":"ls"}}' "$emp" >"$tmp/in.json"; run $m
  expect_silent "key-like text inside a string value is not a key" $m
done

# Repeat everything under dash (the default /bin/sh on Debian and Ubuntu) when it is installed.
if [ -z "${HOOK_SH:-}" ] && command -v dash >/dev/null 2>&1; then
  HOOK_SH=dash sh "$0" || fail=1
fi
if [ -z "${HOOK_SH:-}" ]; then
  if [ "$fail" = 0 ]; then echo "all bash guard tests passed"; else echo "bash guard tests FAILED"; fi
fi
exit "$fail"
