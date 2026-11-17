#!/bin/sh
# Model-free tests for the activity log hook. Usage: sh plugins/triple-a-crew/scripts/test-activity-log.sh

here=$(cd "$(dirname "$0")" && pwd)
tmp=$(mktemp -d)
trap 'chmod -R u+rwx "$tmp" 2>/dev/null; rm -rf "$tmp"' EXIT
# The hook keeps no state anywhere: these two folders must stay empty or absent.
CLAUDE_PLUGIN_DATA="$tmp/data"
export CLAUDE_PLUGIN_DATA
mkdir -p "$tmp/tmpdir"
TMPDIR="$tmp/tmpdir"
export TMPDIR
fail=0
have_jq=0
command -v jq >/dev/null 2>&1 && have_jq=1
have_py=0
command -v python3 >/dev/null 2>&1 && have_py=1
[ "$have_jq" = 1 ] || echo "note: jq not installed, running the no-jq mode only"

modes="nojq"
[ "$have_jq" = 1 ] && modes="jq nojq"

shell=${HOOK_SH:-sh}
hook="$here/activity-log.sh"
pass() { echo "ok   $1 [$2 $shell]"; }
bad() { echo "FAIL $1 [$2 $shell]: $3"; fail=1; }

tab=$(printf '\t')
# pad <n> [char]: n letters (x by default)
pad() { awk -v n="$1" -v c="${2:-x}" 'BEGIN { for (i = 0; i < n; i++) printf "%s", c }'; }

# json_str <text>: the text as the inside of a JSON string (newlines become \n)
json_str() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/	/\\t/g' | awk 'NR > 1 { printf "\\n" } { printf "%s", $0 }'
}

repo="$tmp/repo"
live="$repo/.crew/work/w/live"
log="$live/T2-engineer.log"
status="$repo/.crew/work/w/team/T2-engineer.md"
transcript_path="$tmp/proj/session.jsonl"
mkdir -p "$live" "$repo/.crew/work/w/team" "$tmp/proj/session/subagents"

# mkin <agent_type or empty> <agent-id or empty> <tool> <tool_input as JSON>: writes the PreToolUse input
mkin() {
  {
    printf '{"session_id":"s1","transcript_path":"%s","cwd":"%s"' "$transcript_path" "$repo"
    [ -z "$2" ] || printf ',"agent_id":"%s"' "$2"
    [ -z "$1" ] || printf ',"agent_type":"%s"' "$1"
    printf ',"effort":{"level":"low"},"hook_event_name":"PreToolUse","tool_name":"%s","tool_input":%s,"tool_use_id":"t1"}\n' "$3" "$4"
  } >"$tmp/in.json"
}

# brief <agent-id> <text>: the subagent transcript whose first line is the brief
brief() {
  printf '{"isSidechain":true,"type":"user","message":{"role":"user","content":"%s"}}\n{"type":"assistant"}\n' \
    "$(json_str "$2")" >"$tmp/proj/session/subagents/agent-$1.jsonl"
}
# crew_brief <status path>: the brief text every crew brief has
crew_brief() {
  printf '# T2: x\n\n**Work item:** w\n**Status file:** %s\n\n## Goal\nx' "$1"
}

# run <mode> [keep]: sets $out, $err and $rc for the input in $tmp/in.json; starts from an empty log
# unless the second argument is keep
run() {
  [ "${2:-}" = keep ] || rm -f "$log"
  if [ "$1" = nojq ]; then
    out=$(env HOOKS_NO_JQ=1 "$shell" "$hook" <"$tmp/in.json" 2>"$tmp/err")
  else
    out=$(env "$shell" "$hook" <"$tmp/in.json" 2>"$tmp/err")
  fi
  rc=$?
  err=$(cat "$tmp/err")
}

# piped <mode>: like run, with the input coming through a pipe
piped() {
  rm -f "$log"
  if [ "$1" = nojq ]; then
    out=$(cat "$tmp/in.json" | env HOOKS_NO_JQ=1 "$shell" "$hook" 2>"$tmp/err")
  else
    out=$(cat "$tmp/in.json" | env "$shell" "$hook" 2>"$tmp/err")
  fi
  rc=$?
  err=$(cat "$tmp/err")
}

# bg <mode> <input file> <exit code file>: starts a run in the background (use wait afterwards)
bg() {
  (
    if [ "$1" = nojq ]; then
      env HOOKS_NO_JQ=1 "$shell" "$hook" <"$2" >/dev/null 2>&1
    else
      env "$shell" "$hook" <"$2" >/dev/null 2>&1
    fi
    echo $? >"$3"
  ) &
}

iso_time() {
  case "$1" in
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z) return 0 ;;
  esac
  return 1
}

# expect_nothing <name> <mode>: no output, exit 0, no log line
expect_nothing() {
  if [ "$rc" != 0 ]; then bad "$1" "$2" "exit $rc: $err"
  elif [ -n "$out" ] || [ -n "$err" ]; then bad "$1" "$2" "unexpected output: $out $err"
  elif [ -s "$log" ]; then bad "$1" "$2" "wrote: $(cat "$log")"
  else pass "$1" "$2"; fi
}

# expect_line <name> <mode> <tool> <target>: exactly one line, in the contract's form
expect_line() {
  if [ "$rc" != 0 ]; then bad "$1" "$2" "exit $rc: $err"; return; fi
  if [ -n "$out" ] || [ -n "$err" ]; then bad "$1" "$2" "unexpected output: $out $err"; return; fi
  if [ ! -s "$log" ]; then bad "$1" "$2" "no line written"; return; fi
  n=$(wc -l <"$log" | tr -d ' ')
  size=$(wc -c <"$log" | tr -d ' ')
  line=$(cat "$log")
  want_size=$(printf '%s\n' "$line" | wc -c | tr -d ' ')
  if [ "$n" != 1 ] || [ "$size" != "$want_size" ]; then bad "$1" "$2" "not exactly one whole line: $n lines, $size bytes"; return; fi
  l_time=${line%%"$tab"*}
  l_rest=${line#*"$tab"}
  l_tool=${l_rest%%"$tab"*}
  l_target=${l_rest#*"$tab"}
  if ! iso_time "$l_time"; then bad "$1" "$2" "time field: $line"
  elif [ "$l_tool" != "$3" ]; then bad "$1" "$2" "tool field '$l_tool', wanted '$3'"
  elif [ "$l_target" != "$4" ]; then bad "$1" "$2" "target field '$l_target', wanted '$4'"
  else pass "$1" "$2"; fi
}

# expect_clean <name> <mode> <text>...: the log does not contain any of the texts
expect_clean() {
  name=$1 mode=$2
  shift 2
  for t in "$@"; do
    if grep -qF -- "$t" "$log" 2>/dev/null; then bad "$name" "$mode" "log contains '$t': $(cat "$log")"; return; fi
  done
  pass "$name" "$mode"
}

emp=triple-a-crew:engineer
# emp_call <mode> <name> <tool> <tool_input> <wanted tool> <wanted target>: a call of the employee
emp_call() {
  mkin $emp a1 "$3" "$4"; run "$1"; expect_line "$2" "$1" "$5" "$6"
}

brief a1 "$(crew_brief "$status")"

for m in $modes; do
  # one line per tool, in the contract's form
  emp_call $m "Read inside the root is relative" Read "{\"file_path\":\"$repo/src/db/orders.js\"}" Read src/db/orders.js
  emp_call $m "Read outside the root as given" Read '{"file_path":"/etc/hosts"}' Read /etc/hosts
  emp_call $m "a folder next to the root is outside it" Read "{\"file_path\":\"$repo-other/x.js\"}" Read "$repo-other/x.js"
  emp_call $m "Edit" Edit "{\"file_path\":\"$repo/src/db/orders.js\",\"old_string\":\"a\",\"new_string\":\"b\",\"replace_all\":false}" Edit src/db/orders.js
  emp_call $m "Write" Write "{\"file_path\":\"$repo/README.md\",\"content\":\"hello\"}" Write README.md
  emp_call $m "NotebookEdit takes notebook_path" NotebookEdit "{\"notebook_path\":\"$repo/n.ipynb\",\"new_source\":\"x\"}" NotebookEdit n.ipynb
  emp_call $m "Bash gives the program name" Bash '{"command":"node --test","description":"d"}' Bash node
  emp_call $m "Bash skips NAME=value words and the folders of the path" Bash '{"command":"A=1 B_2=x /usr/bin/git log"}' Bash git
  emp_call $m "Bash with a relative program path" Bash '{"command":"./scripts/run.sh --all"}' Bash run.sh
  emp_call $m "Bash with a dotted program name" Bash '{"command":"python3.11 x.py"}' Bash python3.11
  emp_call $m "Bash program name of 30 characters is written" Bash "{\"command\":\"/usr/bin/$(pad 30) --flag\"}" Bash "$(pad 30)"
  emp_call $m "Bash program name of 31 characters has no target" Bash "{\"command\":\"/usr/bin/$(pad 31) --flag\"}" Bash ""
  # a word that does not start like a path is measured whole: a token may hold slashes
  emp_call $m "Bash AWS example secret key as the command has no target" Bash \
    '{"command":"wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"}' Bash ""
  expect_clean "Bash AWS example key: not in the log" $m bPxRf wJalr K7MDENG
  emp_call $m "Bash relative path with a slash gives the last component" Bash '{"command":"scripts/run.sh --all"}' Bash run.sh
  emp_call $m "Bash node_modules path gives the last component" Bash '{"command":"node_modules/.bin/eslint ."}' Bash eslint
  emp_call $m "Bash absolute path gives the last component" Bash '{"command":"/usr/local/bin/some-tool -x"}' Bash some-tool
  emp_call $m "Bash ../ path gives the last component" Bash '{"command":"../bin/tool -x"}' Bash tool
  emp_call $m "Bash relative word of 30 characters with a slash is written" Bash "{\"command\":\"$(pad 14)/$(pad 15)\"}" Bash "$(pad 15)"
  emp_call $m "Bash relative word of 31 characters with a slash has no target" Bash "{\"command\":\"$(pad 15)/$(pad 15)\"}" Bash ""
  emp_call $m "Bash 40-character token as the command has no target" Bash \
    '{"command":"ghp_abcdefghijklmnopqrstuvwxyzABCDEFGHIJ"}' Bash ""
  expect_clean "Bash 40-character token: not in the log" $m ghp_ abcdefghij
  # NAME=value words with quotes or substitutions: the blanks inside them must not give a "program"
  emp_call $m "Bash with a double-quoted assignment value of several words" Bash \
    '{"command":"PGPASSWORD=\"my hunter2 pass\" psql -h db"}' Bash ""
  expect_clean "Bash double-quoted assignment: not in the log" $m hunter2 pass psql
  emp_call $m "Bash with a single-quoted assignment value of several words" Bash \
    '{"command":"MSG='"'"'deploy s3cret now'"'"' ./notify"}' Bash ""
  expect_clean "Bash single-quoted assignment: not in the log" $m s3cret deploy notify
  emp_call $m "Bash with a command substitution as an assignment value" Bash \
    '{"command":"X=$(echo hunter2 | base64) ./deploy"}' Bash ""
  expect_clean "Bash substitution assignment: not in the log" $m hunter2 base64
  emp_call $m "Bash with a backtick assignment value of three words" Bash '{"command":"X=`echo hunter2 now` ./deploy"}' Bash ""
  expect_clean "Bash backtick assignment: not in the log" $m hunter2 deploy
  emp_call $m "Bash with a backslash in an assignment value" Bash '{"command":"X=a\\ b ./deploy"}' Bash ""
  emp_call $m "Bash with plain assignment values before a program" Bash \
    '{"command":"A=/x/y B=1,2 C=a:b D= E=1.5%+@- F=h=v node run"}' Bash node
  emp_call $m "Bash with an assignment value holding a ? is unsure" Bash '{"command":"A=x?y node"}' Bash ""
  emp_call $m "Bash token pasted as a command has no target" Bash \
    '{"command":"sk-abc123DEF456ghi789JKL012mno345PQR678stu --flag"}' Bash ""
  emp_call $m "Bash with only assignments has no target" Bash '{"command":"TOKEN=abc123"}' Bash ""
  emp_call $m "Bash with a quoted assignment value is unsure" Bash '{"command":"A=\"x y\" node"}' Bash ""
  emp_call $m "Bash with a quoted program is unsure" Bash '{"command":"\"my tool\" -x"}' Bash ""
  emp_call $m "Bash with a substitution as the program is unsure" Bash '{"command":"$(whoami) -x"}' Bash ""
  emp_call $m "Bash with a chain glued to the program is unsure" Bash '{"command":"ls;rm x"}' Bash ""
  emp_call $m "Bash with leading blanks and a line break" Bash '{"command":"  \n\t git status"}' Bash git
  emp_call $m "Bash with an empty command has no target" Bash '{"command":""}' Bash ""
  emp_call $m "Bash with a program path ending in a slash is unsure" Bash '{"command":"/usr/bin/ x"}' Bash ""
  emp_call $m "WebFetch gives the host" WebFetch '{"url":"https://code.claude.com/docs/en/hooks","prompt":"p"}' WebFetch code.claude.com
  emp_call $m "WebFetch drops port, path, query and fragment" WebFetch \
    '{"url":"https://Example.org:8443/a/b?token=SEC#frag","prompt":"p"}' WebFetch Example.org
  emp_call $m "WebFetch with a user and password has no target" WebFetch \
    '{"url":"https://user:pw@host.test/x","prompt":"p"}' WebFetch ""
  emp_call $m "WebFetch with a slash in the password has no target" WebFetch \
    '{"url":"https://user:pa/ss@host.test/x","prompt":"p"}' WebFetch ""
  expect_clean "WebFetch user info: not in the log" $m user pa ss host.test
  emp_call $m "WebFetch with only a user name has no target" WebFetch '{"url":"https://user@host.test/x"}' WebFetch ""
  emp_call $m "WebFetch with an @ in the query has no target" WebFetch '{"url":"https://host.test/x?mail=a@b.test"}' WebFetch ""
  emp_call $m "WebFetch with only a query after the host" WebFetch '{"url":"http://x.test?key=SEC"}' WebFetch x.test
  emp_call $m "WebFetch with a url without a scheme is unsure" WebFetch '{"url":"x.test/a?key=SEC"}' WebFetch ""
  emp_call $m "WebFetch with an IPv6 host is unsure" WebFetch '{"url":"http://[::1]:80/a"}' WebFetch ""
  emp_call $m "Grep gives the pattern" Grep '{"pattern":"TODO|FIXME","path":"src","output_mode":"content"}' Grep 'TODO|FIXME'
  emp_call $m "Glob gives the pattern" Glob '{"pattern":"**/*.md","path":"docs"}' Glob '**/*.md'
  emp_call $m "Grep pattern is cut to 60 characters" Grep "{\"pattern\":\"$(pad 100)\"}" Grep "$(pad 60)"
  emp_call $m "an MCP tool has its name and no target" mcp__x__y '{"query":"SEC","limit":3}' mcp__x__y ""
  emp_call $m "Agent has its name and no target" Agent '{"description":"d","prompt":"p","subagent_type":"s"}' Agent ""
  emp_call $m "a tool without tool_input" Read '{}' Read ""

  # who is logged
  mkin "" "" Read "{\"file_path\":\"$repo/a.js\"}"; run $m
  expect_nothing "main session (no agent keys) writes nothing" $m
  mkin other:worker a1 Read "{\"file_path\":\"$repo/a.js\"}"; run $m
  expect_nothing "agent of another plugin writes nothing" $m
  mkin Explore a1 Read "{\"file_path\":\"$repo/a.js\"}"; run $m
  expect_nothing "a built-in agent writes nothing" $m
  mkin $emp "" Read "{\"file_path\":\"$repo/a.js\"}"; run $m
  expect_nothing "agent_type without agent_id (a --agent main session) writes nothing" $m
  mkin "" a1 Read "{\"file_path\":\"$repo/a.js\"}"; run $m
  expect_nothing "agent_id without agent_type writes nothing" $m
  mkin triple-a-crew: a1 Read '{}'; run $m
  expect_nothing "bare triple-a-crew: is not an employee" $m
  mkin Triple-A-Crew:engineer a1 Read '{}'; run $m
  expect_nothing "agent type is case-sensitive" $m
  mkin 'triple-a-crew:eng!neer' a1 Read '{}'; run $m
  expect_nothing "a role with odd characters is not an employee" $m
  mkin T2-nosuchrole a1 Read '{}'; run $m
  expect_nothing "teammate with an unknown role writes nothing" $m
  mkin T2-engineer-2 a1 Read '{}'; run $m
  expect_nothing "teammate name with a suffix writes nothing" $m
  mkin $emp 'a/../1' Read '{}'; run $m
  expect_nothing "agent_id with a slash is not used" $m
  # an agent-like pair inside the tool input of a main-session call is not the caller
  mkin "" "" mcp__x__y '{"agent_id":"a1","agent_type":"triple-a-crew:engineer"}'; run $m
  expect_nothing "agent keys inside the tool input are not the caller" $m
  mkin "" "" Write '{"file_path":"x","content":"say \"agent_id\": 1 and \"agent_type\": 2"}'; run $m
  expect_nothing "agent key names inside a string are not the caller" $m

  # teammates (the wrapped brief is the one a teammate gets)
  tm_status="$repo/.crew/work/w/team/T2-engineer.md"
  printf '{"isSidechain":true,"type":"user","message":{"role":"user","content":"<teammate-message teammate_id=\\"team-lead\\" summary=\\"Do **Status file:** /nowhere/wrong.md first\\">\\n# T2: x\\n\\n**Work item:** w\\n**Status file:** %s\\n\\n## Goal\\nx\\n</teammate-message>"}}\n' \
    "$tm_status" >"$tmp/proj/session/subagents/agent-tm1.jsonl"
  mkin T2-engineer tm1 Read "{\"file_path\":\"$repo/a.js\"}"; run $m
  expect_line "teammate T2-engineer with a wrapped crew brief is logged" $m Read a.js
  for name in t10-test-engineer T3b-verifier T1-researcher T4-reviewer; do
    mkin $name tm1 Read "{\"file_path\":\"$repo/a.js\"}"; run $m
    expect_line "teammate $name with a crew brief is logged" $m Read a.js
  done
  brief tm2 '# Review the pull request
Do what you think is right.'
  mkin T2-engineer tm2 Read "{\"file_path\":\"$repo/a.js\"}"; run $m
  expect_nothing "teammate name without a status-file line writes nothing" $m
  brief tm3 'Explain this line: **Status file:** /abs/x.md in the protocol'
  mkin T2-engineer tm3 Read "{\"file_path\":\"$repo/a.js\"}"; run $m
  expect_nothing "status-file marker in the middle of a sentence writes nothing" $m
  mkin T2-engineer tm4 Read "{\"file_path\":\"$repo/a.js\"}"; run $m
  expect_nothing "teammate name with a missing transcript writes nothing" $m

  # the brief and its status-file line
  brief b1 "$(crew_brief "$repo/.crew/work/w/team/T2-engineer.md")"
  mkin $emp b1 Read "{\"file_path\":\"$repo/a.js\"}"; run $m
  expect_line "plain brief" $m Read a.js
  mkin $emp nobrief Read "{\"file_path\":\"$repo/a.js\"}"; run $m
  expect_nothing "missing transcript writes nothing" $m
  printf '' >"$tmp/proj/session/subagents/agent-empty.jsonl"
  mkin $emp empty Read '{}'; run $m
  expect_nothing "empty transcript writes nothing" $m
  printf 'not json\n' >"$tmp/proj/session/subagents/agent-junk.jsonl"
  mkin $emp junk Read '{}'; run $m
  expect_nothing "garbage transcript writes nothing" $m
  brief b2 '# T2: x
Nothing about a file here.'
  mkin $emp b2 Read '{}'; run $m
  expect_nothing "brief without a status-file line writes nothing" $m
  brief b3 "$(printf '# x\n**Status file:** `%s`\n' "$status")"
  mkin $emp b3 Read "{\"file_path\":\"$repo/a.js\"}"; run $m
  expect_line "status path in backticks" $m Read a.js
  brief b4 "$(printf '# x\n   **Status file:**    %s   (yours alone)\n' "$status")"
  mkin $emp b4 Read "{\"file_path\":\"$repo/a.js\"}"; run $m
  expect_line "status path followed by words" $m Read a.js
  brief b5 "$(printf '# x\n**Status file:** %s\n**Status file:** /elsewhere/.crew/work/z/team/other.md\n' "$status")"
  mkin $emp b5 Read "{\"file_path\":\"$repo/a.js\"}"; run $m
  expect_line "the first status-file line wins" $m Read a.js
  printf '{"message":{"role":"user","content":[{"type":"text","text":"# x"},{"type":"text","text":"**Status file:** %s\\n"}]}}\n' \
    "$status" >"$tmp/proj/session/subagents/agent-b6.jsonl"
  mkin $emp b6 Read "{\"file_path\":\"$repo/a.js\"}"; run $m
  expect_line "brief as a list of text parts" $m Read a.js
  printf '{"message":{"content":"# x\\r\\n**Status file:** %s\\r\\n"}}\n' "$status" >"$tmp/proj/session/subagents/agent-b7.jsonl"
  mkin $emp b7 Read "{\"file_path\":\"$repo/a.js\"}"; run $m
  expect_line "brief with Windows line endings" $m Read a.js
  brief b8 "$(crew_brief "$repo/.crew/work/w/team/T2-engineer.txt")"
  mkin $emp b8 Read '{}'; run $m
  expect_nothing "status file that is not .md writes nothing" $m
  brief b9 "$(crew_brief "$repo/team/T2-engineer.md")"
  mkin $emp b9 Read '{}'; run $m
  expect_nothing "status file outside .crew/work/<id>/team/ writes nothing" $m
  brief b10 "$(crew_brief "$repo/.crew/work/w/notes/T2-engineer.md")"
  mkin $emp b10 Read '{}'; run $m
  expect_nothing "status file in another folder of the work item writes nothing" $m
  brief b11 "$(crew_brief "$repo/.crew/work/w/extra/team/T2-engineer.md")"
  mkin $emp b11 Read '{}'; run $m
  expect_nothing "status file one level too deep writes nothing" $m
  brief b12 "$(crew_brief "$repo/.crew/work/team/T2-engineer.md")"
  mkin $emp b12 Read '{}'; run $m
  expect_nothing "status file without a work item folder writes nothing" $m
  brief b13 "$(crew_brief ".crew/work/w/team/T2-engineer.md")"
  mkin $emp b13 Read '{}'; run $m
  expect_nothing "relative status file path writes nothing" $m
  brief b14 "$(crew_brief "$repo/.crew/work/../team/T2-engineer.md")"
  mkin $emp b14 Read '{}'; run $m
  expect_nothing "work item folder named .. writes nothing" $m
  brief b15 "$(crew_brief "$repo/.crew/work/w/team/T2 engineer.md")"
  mkin $emp b15 Read '{}'; run $m
  expect_nothing "status file name with a space writes nothing" $m
  brief b16 "$(crew_brief "/.crew/work/w/team/T2-engineer.md")"
  mkin $emp b16 Read '{}'; run $m
  expect_nothing "no root in front of .crew writes nothing" $m
  brief b17 "$(crew_brief "$repo/.crew/work/w/team/")"
  mkin $emp b17 Read '{}'; run $m
  expect_nothing "status path without a file name writes nothing" $m
  # a log of another employee of the same item, and a root with a space
  mkdir -p "$tmp/my repo/.crew/work/w2/live" "$tmp/my repo/.crew/work/w2/team"
  brief b18 "$(crew_brief "$tmp/my repo/.crew/work/w2/team/T5-verifier.md")"
  mkin $emp b18 Read "{\"file_path\":\"$tmp/my repo/src/a b.js\"}"; run $m
  if [ -s "$tmp/my repo/.crew/work/w2/live/T5-verifier.log" ]; then
    l=$(cat "$tmp/my repo/.crew/work/w2/live/T5-verifier.log")
    case "$l" in
      *"${tab}Read${tab}src/a b.js") pass "root and file with spaces, own log per employee" $m ;;
      *) bad "root and file with spaces" $m "$l" ;;
    esac
    rm -f "$tmp/my repo/.crew/work/w2/live/T5-verifier.log"
  else bad "root and file with spaces" $m "no line written"; fi

  # the live folder is never created, the log file may be
  mkdir -p "$repo/.crew/work/nolive/team"
  brief b19 "$(crew_brief "$repo/.crew/work/nolive/team/T2-engineer.md")"
  mkin $emp b19 Read '{"file_path":"x"}'; run $m
  expect_nothing "employee without a live folder writes nothing" $m
  [ ! -e "$repo/.crew/work/nolive/live" ] && pass "the live folder is not created" $m || bad "the live folder is not created" $m "it exists now"
  : >"$repo/.crew/work/nolive/live"
  mkin $emp b19 Read '{"file_path":"x"}'; run $m
  expect_nothing "a file named live is not a live folder" $m
  rm -f "$repo/.crew/work/nolive/live"

  # symbolic links: nothing is written through them
  outside="$tmp/outside"
  mkdir -p "$outside" "$repo/.crew/work/linked/team" "$repo/.crew/work/linkedlog/live" "$repo/.crew/work/linkedlog/team"
  brief b20 "$(crew_brief "$repo/.crew/work/linked/team/T2-engineer.md")"
  brief b21 "$(crew_brief "$repo/.crew/work/linkedlog/team/T2-engineer.md")"
  rm -f "$repo/.crew/work/linked/live"
  ln -s "$outside" "$repo/.crew/work/linked/live"
  mkin $emp b20 Read '{"file_path":"x"}'; run $m
  expect_nothing "live as a link to a folder outside the item: nothing is written" $m
  if [ -z "$(ls -A "$outside")" ] && [ -z "$(ls -A "$tmp/tmpdir")" ]; then pass "live as a link: the folder behind it stays empty" $m
  else bad "live as a link" $m "wrote: $(ls -A "$outside")"; fi
  rm -f "$repo/.crew/work/linked/live"
  ln -s "$tmp/nowhere" "$repo/.crew/work/linked/live"
  mkin $emp b20 Read '{"file_path":"x"}'; run $m
  expect_nothing "live as a dangling link: nothing is written" $m
  rm -f "$repo/.crew/work/linked/live"
  printf 'keep\n' >"$tmp/outside-file"
  ln -s "$tmp/outside-file" "$repo/.crew/work/linkedlog/live/T2-engineer.log"
  mkin $emp b21 Read '{"file_path":"x"}'; run $m keep
  expect_nothing "log as a link to a file outside: nothing is written" $m
  if [ "$(cat "$tmp/outside-file")" = keep ] && [ -L "$repo/.crew/work/linkedlog/live/T2-engineer.log" ]; then
    pass "log as a link: the file behind it is unchanged" $m
  else bad "log as a link" $m "outside file now: $(cat "$tmp/outside-file")"; fi
  rm -f "$repo/.crew/work/linkedlog/live/T2-engineer.log"
  ln -s "$tmp/not-created" "$repo/.crew/work/linkedlog/live/T2-engineer.log"
  mkin $emp b21 Read '{"file_path":"x"}'; run $m keep
  expect_nothing "log as a dangling link: nothing is written" $m
  [ ! -e "$tmp/not-created" ] && pass "log as a dangling link: the target is not created" $m || bad "dangling link target" $m "created"
  rm -f "$repo/.crew/work/linkedlog/live/T2-engineer.log"
  mkdir "$repo/.crew/work/linkedlog/live/T2-engineer.log"
  mkin $emp b21 Read '{"file_path":"x"}'; run $m keep
  expect_nothing "log path that is a folder: nothing is written" $m
  [ -z "$(ls -A "$repo/.crew/work/linkedlog/live/T2-engineer.log")" ] && pass "log path that is a folder: stays empty" $m || bad "log folder" $m "has files"
  rmdir "$repo/.crew/work/linkedlog/live/T2-engineer.log"
  mkin $emp b21 Read '{"file_path":"x"}'; run $m keep
  [ -s "$repo/.crew/work/linkedlog/live/T2-engineer.log" ] && pass "a plain live folder and log are written after the links are gone" $m || bad "plain log after links" $m "nothing written"
  rm -f "$repo/.crew/work/linkedlog/live/T2-engineer.log"
  # a link higher up: the work item folder, .crew/work, .crew
  rm -rf "$tmp/otheritem" "$tmp/repoB" "$tmp/workreal" "$tmp/repoC" "$tmp/crewreal"
  mkdir -p "$tmp/otheritem/live" "$tmp/otheritem/team" "$tmp/repoB/.crew" "$tmp/workreal/w/live" "$tmp/workreal/w/team" \
    "$tmp/repoC" "$tmp/crewreal/work/w/live" "$tmp/crewreal/work/w/team"
  ln -s "$tmp/otheritem" "$repo/.crew/work/lnk"
  ln -s "$tmp/workreal" "$tmp/repoB/.crew/work"
  ln -s "$tmp/crewreal" "$tmp/repoC/.crew"
  brief b22 "$(crew_brief "$repo/.crew/work/lnk/team/T2-engineer.md")"
  mkin $emp b22 Read '{"file_path":"x"}'; run $m
  expect_nothing "work item folder as a link: nothing is written" $m
  [ -z "$(ls -A "$tmp/otheritem/live")" ] && pass "work item folder as a link: the folder behind it stays empty" $m || bad "item link" $m "wrote: $(ls -A "$tmp/otheritem/live")"
  brief b23 "$(crew_brief "$tmp/repoB/.crew/work/w/team/T2-engineer.md")"
  mkin $emp b23 Read '{"file_path":"x"}'; run $m
  expect_nothing ".crew/work as a link: nothing is written" $m
  [ -z "$(ls -A "$tmp/workreal/w/live")" ] && pass ".crew/work as a link: the folder behind it stays empty" $m || bad "work link" $m "wrote: $(ls -A "$tmp/workreal/w/live")"
  brief b24 "$(crew_brief "$tmp/repoC/.crew/work/w/team/T2-engineer.md")"
  mkin $emp b24 Read '{"file_path":"x"}'; run $m
  expect_nothing ".crew as a link: nothing is written" $m
  [ -z "$(ls -A "$tmp/crewreal/work/w/live")" ] && pass ".crew as a link: the folder behind it stays empty" $m || bad ".crew link" $m "wrote: $(ls -A "$tmp/crewreal/work/w/live")"
  rm -f "$repo/.crew/work/lnk"
  rm -rf "$tmp/repoB" "$tmp/repoC"
  # a status file name must start with a letter or digit
  brief b25 "$(crew_brief "$repo/.crew/work/w/team/..md")"
  mkin $emp b25 Read '{"file_path":"x"}'; run $m
  expect_nothing "status file named ..md writes nothing" $m
  brief b26 "$(crew_brief "$repo/.crew/work/w/team/-rf.md")"
  mkin $emp b26 Read '{"file_path":"x"}'; run $m
  expect_nothing "status file named -rf.md writes nothing" $m
  [ -z "$(ls -A "$live" | grep -v '^T')" ] && pass "no log named from a dot or dash name" $m || bad "odd log names" $m "$(ls -A "$live")"
  brief a1 "$(crew_brief "$status")"
  mkin $emp a1 Read '{"file_path":"x"}'; run $m
  expect_line "the log file is created in an existing live folder" $m Read x
  # appends, never rewrites
  printf 'first line\n' >"$log"
  run $m keep
  if [ "$(sed -n 1p "$log")" = "first line" ] && [ "$(wc -l <"$log" | tr -d ' ')" = 2 ]; then pass "a call appends to the log" $m
  else bad "a call appends to the log" $m "$(cat "$log")"; fi

  # secrets never reach the log
  mkin $emp a1 Bash '{"command":"TOKEN=abc123 curl -H \"Authorization: Bearer abc123\" https://x.test/?key=abc123","description":"d"}'; run $m
  expect_line "Bash secrets: only the program name" $m Bash curl
  expect_clean "Bash secrets: not in the log" $m abc123 Bearer Authorization x.test key
  mkin $emp a1 Write "{\"file_path\":\"$repo/a.txt\",\"content\":\"password=hunter2\\nSECRET-content\"}"; run $m
  expect_line "Write content: only the path" $m Write a.txt
  expect_clean "Write content: not in the log" $m hunter2 SECRET
  mkin $emp a1 Edit "{\"file_path\":\"$repo/a.txt\",\"old_string\":\"OLD-secret\",\"new_string\":\"NEW-secret\"}"; run $m
  expect_clean "Edit strings: not in the log" $m OLD NEW secret
  mkin $emp a1 WebFetch '{"url":"https://api.test/v1/x?api_key=SEC-123&b=2","prompt":"summarize SEC-prompt"}'; run $m
  expect_line "WebFetch query: only the host" $m WebFetch api.test
  expect_clean "WebFetch query and prompt: not in the log" $m SEC api_key v1
  mkin $emp a1 mcp__x__y '{"token":"SEC-mcp"}'; run $m
  expect_clean "MCP arguments: not in the log" $m SEC token

  # tabs, line breaks, control characters
  mkin $emp a1 Read '{"file_path":"/x/a\tb\nc\r\u001bd\u007fe\bf"}'; run $m
  expect_line "control characters in a target become spaces" $m Read '/x/a b c  d e f'
  mkin $emp a1 Grep '{"pattern":"a\tb\n\nc"}'; run $m
  expect_line "tabs and line breaks in a pattern become spaces" $m Grep 'a b  c'
  mkin $emp a1 'mcp__x__y' '{}'; run $m
  expect_line "an MCP tool name is kept" $m mcp__x__y ""
  mkin $emp a1 'odd\tname\nhere' '{}'; run $m
  expect_line "control characters in a tool name become spaces" $m 'odd name here' ""

  # long targets and lines
  mkin $emp a1 Read "{\"file_path\":\"/$(pad 300)\"}"; run $m
  expect_line "a long path is cut to 120 characters" $m Read "/$(pad 119)"
  mkin $emp a1 "mcp__$(pad 300)" '{}'; run $m
  if [ "$rc" = 0 ] && [ -s "$log" ]; then
    size=$(wc -c <"$log" | tr -d ' ')
    [ "$size" = 200 ] && pass "a long line is cut to 200 bytes with its line break" $m || bad "a long line is cut to 200 bytes" $m "$size bytes"
  else bad "a long line is cut to 200 bytes" $m "rc=$rc, nothing written"; fi
  # multi-byte text: cut between characters
  for ch in é 日 😀; do
    mkin $emp a1 Read "{\"file_path\":\"/$(pad 100 "$ch")\"}"; run $m
    size=$(wc -c <"$log" | tr -d ' ')
    chars=$(sed -n 1p "$log" | awk -F"$tab" '{ n = split($3, a, "'"$ch"'"); print n - 1 }')
    ok=1
    [ "$size" -le 200 ] || ok=0
    if command -v iconv >/dev/null 2>&1; then
      iconv -f UTF-8 -t UTF-8 <"$log" >/dev/null 2>&1 || ok=0
    fi
    [ "$chars" -gt 10 ] || ok=0
    [ "$ok" = 1 ] && pass "a long path of $ch is cut between characters ($size bytes)" $m || bad "multi-byte cut ($ch)" $m "$size bytes, $chars characters, $(cat "$log")"
  done

  # input with escapes
  mkin $emp a1 Bash '{"command":"echo \"a\" \\\\ b"}'; run $m
  expect_line "escaped quotes and backslashes in the command" $m Bash echo
  # the pieces of a value split at escaped quotes are joined again
  mkin $emp a1 Read '{"file_path":"/x/a\"b\"c.js"}'; run $m
  expect_line "escaped quotes inside a file path" $m Read '/x/a"b"c.js'
  mkin $emp a1 Read "{\"file_path\":\"/x/$(pad 20 '\\"')END\"}"; run $m
  expect_line "20 escaped quotes followed by text in a file path" $m Read "/x/$(pad 20 '"')END"
  mkin $emp a1 Read "{\"file_path\":\"/x/caf\\u00e9.js\"}"; run $m
  if [ "$m" = nojq ]; then expect_nothing "no-jq: a \\u escape in the path is unsure, nothing written" $m
  else expect_line "jq: a \\u escape in the path is decoded" $m Read /x/café.js; fi
  mkin $emp a1 Write "{\"file_path\":\"$repo/a.js\",\"content\":\"esc \\u001b[0m caf\\u00e9 \\\"agent_id\\\": 1\\n\"}"; run $m
  expect_line "a \\u escape in the content does not matter" $m Write a.js
  mkin $emp a1 Write "{\"content\":\"x\",\"file_path\":\"$repo/a.js\"}"; run $m
  expect_line "file_path after the content" $m Write a.js
  printf '{\n  "agent_id": "a1",\n  "agent_type": "%s",\n  "transcript_path": "%s",\n  "tool_name": "Read",\n  "tool_input": {\n    "file_path": "%s/pretty.js"\n  }\n}\n' \
    "$emp" "$transcript_path" "$repo" >"$tmp/in.json"; run $m
  expect_line "pretty-printed input" $m Read pretty.js
  mkin $emp a1 Read "{\"description\":\"say \\\"file_path\\\": /bad\",\"file_path\":\"$repo/good.js\"}"; run $m
  expect_line "key-like text inside a string is not a key" $m Read good.js

  # big input
  mkin $emp a1 Write "{\"file_path\":\"$repo/big.js\",\"content\":\"$(pad 60000)\"}"; run $m
  expect_line "input of 60000 characters" $m Write big.js
  mkin $emp a1 Write "{\"file_path\":\"$repo/big.js\",\"content\":\"$(pad 150000)\"}"; run $m
  if [ "$m" = nojq ]; then expect_nothing "no-jq: input over 100000 characters is left unread" $m
  else expect_line "jq: input of 150000 characters" $m Write big.js; fi
  mkin $emp a1 Write "{\"file_path\":\"$repo/big.js\",\"content\":\"$(pad 1500000)\"}"; run $m
  if [ "$m" = nojq ]; then expect_nothing "no-jq: input of 1.5 MB is left unread" $m
  else expect_line "jq: input of 1.5 MB" $m Write big.js; fi
  mkin "" "" Write "{\"file_path\":\"x\",\"content\":\"$(pad 150000)\"}"; run $m
  expect_nothing "main session with a 150000-character input writes nothing" $m

  # input through a pipe, as Claude Code sends it (the shell then reads it byte by byte)
  mkin $emp a1 Read "{\"file_path\":\"$repo/a.js\"}"; piped $m
  expect_line "piped input: Read" $m Read a.js
  mkin $emp a1 Bash '{"command":"TOKEN=abc123 curl https://x.test/?key=abc123"}'; piped $m
  expect_line "piped input: Bash" $m Bash curl
  mkin $emp a1 Write "{\"file_path\":\"$repo/big.js\",\"content\":\"$(pad 60000)\"}"; piped $m
  expect_line "piped input of 60000 characters" $m Write big.js
  mkin $emp a1 Write "{\"file_path\":\"$repo/big.js\",\"content\":\"$(pad 150000)\"}"; piped $m
  if [ "$m" = nojq ]; then expect_nothing "piped no-jq: input over 100000 characters is left unread" $m
  else expect_line "piped jq: input of 150000 characters" $m Write big.js; fi
  mkin $emp a1 Read "{\"file_path\":\"$repo/a.js\"}"; printf '%s' "$(cat "$tmp/in.json")" >"$tmp/in-nonl.json"; cp "$tmp/in-nonl.json" "$tmp/in.json"; piped $m
  expect_line "piped input without a final line break" $m Read a.js
  mkin "" "" Write "{\"file_path\":\"x\",\"content\":\"$(pad 150000)\"}"; piped $m
  expect_nothing "piped main session with a 150000-character input writes nothing" $m
  mkin "" "" Read '{"file_path":"x"}'; piped $m
  expect_nothing "piped main session input writes nothing" $m

  # many escaped quotes: still read, still one line
  mkin $emp a1 Bash "{\"command\":\"x$(pad 49000 '\\"')\"}"; piped $m
  expect_line "a command of 49000 escaped quotes" $m Bash ""
  printf '{"message":{"role":"user","content":"# x\\n**Status file:** %s\\n%s"}}\n' "$status" "$(pad 10000 '\\"')" \
    >"$tmp/proj/session/subagents/agent-q1.jsonl"
  mkin $emp q1 Read "{\"file_path\":\"$repo/a.js\"}"; run $m
  expect_line "a brief with 10000 escaped quotes" $m Read a.js

  # unreadable input
  : >"$tmp/in.json"; run $m; expect_nothing "empty input" $m
  rm -f "$log"
  if [ "$m" = nojq ]; then out=$(env HOOKS_NO_JQ=1 "$shell" "$hook" <&- 2>"$tmp/err"); else out=$(env "$shell" "$hook" <&- 2>"$tmp/err"); fi
  rc=$?; err=$(cat "$tmp/err")
  expect_nothing "closed stdin" $m
  echo 'not json "agent_id"' >"$tmp/in.json"; run $m; expect_nothing "malformed input" $m
  echo '{"agent_id":"a1","agent_type":"triple-a-crew:engineer"' >"$tmp/in.json"; run $m; expect_nothing "truncated input" $m
  echo '{}' >"$tmp/in.json"; run $m; expect_nothing "empty object" $m
  echo '["agent_id"]' >"$tmp/in.json"; run $m; expect_nothing "JSON array input" $m
  printf '{"agent_id":"a1","agent_type":"%s","transcript_path":"%s","tool_name":"Read","tool_input":"x"}' "$emp" "$transcript_path" >"$tmp/in.json"; run $m
  expect_line "tool_input that is not an object" $m Read ""
  printf '{"agent_id":"a1","agent_type":"%s","transcript_path":"%s","tool_name":"Read","tool_input":{"file_path":42}}' "$emp" "$transcript_path" >"$tmp/in.json"; run $m
  expect_line "non-string file_path" $m Read ""
  printf '{"agent_id":"a1","agent_type":"%s","transcript_path":"%s","tool_input":{"file_path":"x"}}' "$emp" "$transcript_path" >"$tmp/in.json"; run $m
  expect_nothing "no tool name" $m
  printf '{"agent_id":"a1","agent_type":"%s","tool_name":"Read","tool_input":{"file_path":"x"}}' "$emp" >"$tmp/in.json"; run $m
  expect_nothing "no transcript_path" $m
  printf '{"agent_id":"a1","agent_type":"","transcript_path":"%s","tool_name":"Read"}' "$transcript_path" >"$tmp/in.json"; run $m
  expect_nothing "empty agent_type" $m

  # parallel calls of one employee and of several employees: one whole line per call
  brief a2 "$(crew_brief "$repo/.crew/work/w/team/T3-tester.md")"
  log2="$live/T3-tester.log"
  rm -f "$log" "$log2"
  mkin $emp a1 Read "{\"file_path\":\"$repo/par-one.js\"}"; cp "$tmp/in.json" "$tmp/in-a.json"
  mkin $emp a2 Bash '{"command":"git status"}'; cp "$tmp/in.json" "$tmp/in-b.json"
  i=1
  while [ $i -le 20 ]; do
    bg $m "$tmp/in-a.json" "$tmp/rc-a$i"
    bg $m "$tmp/in-b.json" "$tmp/rc-b$i"
    i=$((i + 1))
  done
  wait
  n1=$(wc -l <"$log" | tr -d ' ')
  n2=$(wc -l <"$log2" | tr -d ' ')
  whole1=$(awk -F"$tab" 'NF == 3 && $2 == "Read" && $3 == "par-one.js" { n++ } END { print n + 0 }' "$log")
  whole2=$(awk -F"$tab" 'NF == 3 && $2 == "Bash" && $3 == "git" { n++ } END { print n + 0 }' "$log2")
  if [ "$n1" = 20 ] && [ "$whole1" = 20 ] && [ "$n2" = 20 ] && [ "$whole2" = 20 ]; then pass "20 parallel calls of each of two employees: 40 whole lines" $m
  else bad "parallel calls" $m "log 1: $n1 lines ($whole1 whole), log 2: $n2 lines ($whole2 whole)"; fi
  rm -f "$log2"

  # independent edge cases (second pass)
  brief a1 "$(crew_brief "$status")"
  # Bash: only the program name, whatever stands in front of it
  emp_call $m "Bash sudo is the program name" Bash '{"command":"sudo rm -rf /x"}' Bash sudo
  emp_call $m "Bash env is the program name" Bash '{"command":"env NAME=value git status"}' Bash env
  emp_call $m "Bash with several NAME=value words" Bash '{"command":"A=1 B=2 C_3=x D4=y git log"}' Bash git
  emp_call $m "Bash with = in a later word" Bash '{"command":"git commit -m a=b"}' Bash git
  emp_call $m "Bash NAME=a=b is one assignment" Bash '{"command":"a=b=c ls"}' Bash ls
  emp_call $m "Bash with a double-quoted program is unsure" Bash '{"command":"\"git\" status"}' Bash ""
  emp_call $m "Bash with a single-quoted program is unsure" Bash "{\"command\":\"'git' status\"}" Bash ""
  emp_call $m "Bash with a subshell is unsure" Bash '{"command":"(cd x && ls)"}' Bash ""
  emp_call $m "Bash with a subshell after blanks is unsure" Bash '{"command":"  ( ls )"}' Bash ""
  emp_call $m "Bash with a backtick program is unsure" Bash '{"command":"`whoami` -x"}' Bash ""
  emp_call $m "Bash with a leading line break" Bash '{"command":"\ngit status"}' Bash git
  emp_call $m "Bash with a line break after the program" Bash '{"command":"ls\nrm x"}' Bash ls
  emp_call $m "Bash with a leading = is unsure" Bash '{"command":"=x ls"}' Bash ""
  emp_call $m "Bash with a digit-first name=value is unsure" Bash '{"command":"1A=x ls"}' Bash ""
  emp_call $m "Bash secret as the only NAME=value has no target" Bash '{"command":"abc123secret=1"}' Bash ""
  expect_clean "Bash secret NAME=value: not in the log" $m abc123secret
  emp_call $m "Bash secret NAME=value before the program" Bash '{"command":"abc123secret=1 curl x"}' Bash curl
  expect_clean "Bash secret NAME=value before the program: not in the log" $m abc123secret
  emp_call $m "Bash with \$TOKEN as the program is unsure" Bash '{"command":"$TOKEN --flag"}' Bash ""
  expect_clean "Bash with \$TOKEN as the program: not in the log" $m TOKEN
  emp_call $m "Bash with \${TOKEN} as the program is unsure" Bash '{"command":"${TOKEN} x"}' Bash ""

  # WebFetch: the host only
  emp_call $m "WebFetch with user and password has no target" WebFetch '{"url":"https://user:hunter2@host.test/x"}' WebFetch ""
  expect_clean "WebFetch with user and password: not in the log" $m hunter2 user host.test
  emp_call $m "WebFetch with a port" WebFetch '{"url":"https://host.test:8080/x?k=SEC"}' WebFetch host.test
  expect_clean "WebFetch with a port: not in the log" $m 8080 SEC
  emp_call $m "WebFetch with a long IPv6 host is unsure" WebFetch '{"url":"https://[2001:db8::1]:8443/x?k=SEC"}' WebFetch ""
  expect_clean "WebFetch with an IPv6 host: not in the log" $m SEC 2001
  emp_call $m "WebFetch with an upper-case scheme" WebFetch '{"url":"HTTPS://Host.Test/x"}' WebFetch Host.Test
  emp_call $m "WebFetch with no path" WebFetch '{"url":"https://host.test"}' WebFetch host.test
  emp_call $m "WebFetch with a fragment" WebFetch '{"url":"https://host.test#frag-SEC"}' WebFetch host.test
  expect_clean "WebFetch with a fragment: not in the log" $m SEC frag
  emp_call $m "WebFetch with user and password and no host is unsure" WebFetch '{"url":"https://user:hunter2@/x"}' WebFetch ""
  expect_clean "WebFetch with user and password and no host: not in the log" $m hunter2
  emp_call $m "WebFetch with a dotted-quad host" WebFetch '{"url":"http://10.0.0.1:3000/a"}' WebFetch 10.0.0.1

  # file paths
  emp_call $m "Read with spaces in the path" Read "{\"file_path\":\"$repo/my dir/a b.js\"}" Read "my dir/a b.js"
  emp_call $m "Read with non-ASCII characters in the path" Read "{\"file_path\":\"$repo/src/café-日本.js\"}" Read "src/café-日本.js"
  emp_call $m "Read of the root itself is given as is" Read "{\"file_path\":\"$repo\"}" Read "$repo"
  emp_call $m "Read of a path sharing only a prefix with the root" Read "{\"file_path\":\"${repo}x/y.js\"}" Read "${repo}x/y.js"
  emp_call $m "Read of a relative path is given as is" Read '{"file_path":"src/a.js"}' Read src/a.js

  # tool names
  mkin $emp a1 "" '{}'; run $m
  expect_nothing "an empty tool name writes nothing" $m
  mkin $emp a1 "$(pad 5000)" '{}'; run $m
  if [ "$rc" = 0 ] && [ -s "$log" ] && [ "$(wc -c <"$log" | tr -d ' ')" = 200 ] && [ "$(wc -l <"$log" | tr -d ' ')" = 1 ]; then
    pass "a 5000-character tool name gives one line of 200 bytes" $m
  else bad "a 5000-character tool name" $m "rc=$rc, $(wc -c <"$log" 2>/dev/null) bytes"; fi
  mkin $emp a1 'a\tb' '{}'; run $m
  expect_line "a tab in a tool name does not add a field" $m 'a b' ""

  # briefs
  brief e1 "$(crew_brief "~/x/.crew/work/w/team/T2-engineer.md")"
  mkin $emp e1 Read '{"file_path":"x"}'; run $m
  expect_nothing "status file with ~/ is not expanded and writes nothing" $m
  brief e2 "$(printf '# x\n**Status file:** `%s` (yours alone)\n' "$status")"
  mkin $emp e2 Read '{"file_path":"x"}'; run $m
  expect_line "status path in backticks followed by words" $m Read x
  brief e3 "$(printf '# x\n**Status file:**\n')"
  mkin $emp e3 Read '{"file_path":"x"}'; run $m
  expect_nothing "status-file line without a path writes nothing" $m
  brief e4 "$(printf '# x\n**Status file:** %s\n' "$repo/.crew/work/w/team/T2-engineer.md/")"
  mkin $emp e4 Read '{"file_path":"x"}'; run $m
  expect_nothing "status path with a trailing slash writes nothing" $m
  brief a1 "$(crew_brief "$status")"

  # live as a symbolic link to a folder outside the item: nothing is written behind it
  mkdir -p "$repo/.crew/work/linked/team" "$tmp/outlive"
  ln -s "$tmp/outlive" "$repo/.crew/work/linked/live"
  brief e5 "$(crew_brief "$repo/.crew/work/linked/team/T2-engineer.md")"
  mkin $emp e5 Read '{"file_path":"x"}'; run $m
  if [ "$rc" != 0 ] || [ -n "$out" ] || [ -n "$err" ]; then bad "live as a symlink: silent, exit 0" $m "rc=$rc out=$out err=$err"
  else pass "live as a symlink: silent, exit 0" $m; fi
  if [ -z "$(ls -A "$tmp/outlive")" ]; then pass "live as a symlink: nothing written behind it" $m
  else bad "live as a symlink: nothing written behind it" $m "wrote: $(ls -A "$tmp/outlive")"; fi
  rm -rf "$repo/.crew/work/linked" "$tmp/outlive"

  # 50 parallel runs of one employee
  rm -f "$log"
  mkin $emp a1 Read "{\"file_path\":\"$repo/par-fifty.js\"}"; cp "$tmp/in.json" "$tmp/in-f.json"
  i=1
  while [ $i -le 50 ]; do
    bg $m "$tmp/in-f.json" "$tmp/rc-f$i"
    i=$((i + 1))
  done
  wait
  nf=$(wc -l <"$log" | tr -d ' ')
  wholef=$(awk -F"$tab" 'NF == 3 && $2 == "Read" && $3 == "par-fifty.js" { n++ } END { print n + 0 }' "$log")
  rcs=$(cat "$tmp"/rc-f* | sort -u | tr '\n' ' ')
  if [ "$nf" = 50 ] && [ "$wholef" = 50 ] && [ "$rcs" = "0 " ]; then pass "50 parallel calls of one employee: 50 whole lines, all exit 0" $m
  else bad "50 parallel calls" $m "$nf lines ($wholef whole), exit codes: $rcs"; fi
  rm -f "$tmp"/rc-f* "$tmp/in-f.json"

  # input that is not an object, or names agent_id in the wrong place
  echo '"agent_id"' >"$tmp/in.json"; run $m; expect_nothing "a JSON string that mentions agent_id" $m
  echo '[{"agent_id":"a1","agent_type":"triple-a-crew:engineer"}]' >"$tmp/in.json"; run $m; expect_nothing "a JSON array of objects" $m
  echo 'null "agent_id"' >"$tmp/in.json"; run $m; expect_nothing "null followed by text" $m
  echo '{"agent_id":"a1"}' >"$tmp/in.json"; run $m; expect_nothing "agent_id alone" $m
  mkin "" "" Read '{"file_path":"x","agent_id":"a1"}'; run $m
  expect_nothing "main session whose arguments mention agent_id" $m
  mkin $emp "" Read '{"file_path":"x","agent_id":"a1"}'; run $m
  expect_nothing "agent_type at the top and agent_id only in tool_input" $m
  mkin $emp "" mcp__x__y '{"agent_id":"a1","transcript_path":"x"}'; run $m
  expect_nothing "agent_id and transcript_path only in tool_input" $m
  # a brief that would be found if the hook went on without an agent_id
  brief "" "$(crew_brief "$status")"
  mkin $emp "" Read '{"file_path":"x"}'; run $m
  expect_nothing "agent_type without agent_id writes nothing even when a matching brief exists" $m
  mkin T2-engineer "" Read '{"file_path":"x"}'; run $m
  expect_nothing "teammate name without agent_id writes nothing even when a matching brief exists" $m
  mkin "" "" Read '{"file_path":"x"}'; run $m
  expect_nothing "main session writes nothing even when a matching brief exists" $m
  mkin "" "" Read '{"file_path":"x","agent_type":"triple-a-crew:engineer"}'; run $m
  expect_nothing "main session with agent_type only in tool_input writes nothing even when a matching brief exists" $m
  rm -f "$tmp/proj/session/subagents/agent-.jsonl"

  # a log folder that cannot be written
  if [ "$(id -u)" != 0 ]; then
    rm -f "$log"
    chmod 555 "$live"
    mkin $emp a1 Read '{"file_path":"x"}'; run $m
    expect_nothing "read-only live folder: silent, exit 0" $m
    [ ! -e "$log" ] && pass "read-only live folder: nothing created" $m || bad "read-only live folder" $m "log exists"
    chmod 755 "$live"
    : >"$log"; chmod 444 "$log"
    run $m keep
    if [ "$rc" = 0 ] && [ -z "$out" ] && [ -z "$err" ] && [ ! -s "$log" ]; then pass "read-only log file: silent, exit 0" $m
    else bad "read-only log file" $m "rc=$rc out=$out err=$err"; fi
    chmod 644 "$log"
  else
    echo "note: running as root, read-only folder tests skipped"
  fi

  # nothing but the log is written anywhere
  if [ -z "$(ls -A "$tmp/tmpdir")" ] && [ ! -e "$tmp/data" ]; then pass "no state file in the temp folder or the plugin data folder" $m
  else bad "no state file" $m "$(ls -A "$tmp/tmpdir") $(ls -A "$tmp/data" 2>/dev/null)"; fi
done

# the main session starts no other program: a PATH with marker stubs for jq, awk, date and cat
stubs="$tmp/stubs"
marker="$tmp/stub-marker"
rm -rf "$stubs" "$marker"
mkdir -p "$stubs"
for prog in jq awk date cat; do
  printf '#!/bin/sh\necho %s >>"%s"\nexit 0\n' "$prog" "$marker" >"$stubs/$prog"
  chmod +x "$stubs/$prog"
done
shell_path=$(command -v "$shell")
# Any other program is "not found" on this PATH and the shell says so on stderr: stdout and stderr must be empty.
mkin "" "" Read "{\"file_path\":\"$repo/a.js\"}"
PATH="$stubs" "$shell_path" "$hook" <"$tmp/in.json" >"$tmp/s3-out" 2>"$tmp/s3-err"
if [ ! -e "$marker" ] && [ ! -s "$tmp/s3-out" ] && [ ! -s "$tmp/s3-err" ]; then pass "main session input: no program is started" -
else bad "main session input: no program is started" - "started: $(cat "$marker" 2>/dev/null) $(cat "$tmp/s3-out" "$tmp/s3-err")"; fi
mkin "" "" Read "{\"file_path\":\"$repo/a.js\"}"
printf '%s' "$(cat "$tmp/in.json")" | PATH="$stubs" "$shell_path" "$hook" >"$tmp/s3-out" 2>"$tmp/s3-err"
if [ ! -e "$marker" ] && [ ! -s "$tmp/s3-out" ] && [ ! -s "$tmp/s3-err" ]; then pass "main session input through a pipe: no program is started" -
else bad "main session input through a pipe: no program is started" - "started: $(cat "$marker" 2>/dev/null) $(cat "$tmp/s3-out" "$tmp/s3-err")"; fi
mkin $emp a1 Read "{\"file_path\":\"$repo/a.js\"}"
PATH="$stubs" "$shell_path" "$hook" <"$tmp/in.json" >/dev/null 2>&1
if [ -e "$marker" ]; then pass "control: an employee input does start programs from the stub PATH" -
else bad "control: the stub PATH is used" - "no stub was started"; fi

# a field list that is not nine lines long (a line break that survived in a value) writes nothing
# The reader of each mode is replaced by a stub that prints the list: jq (called with the program that starts
# with "A" +) and awk (called with mode=f); every other call goes to the real program.
stubs2="$tmp/stubs2"
rm -rf "$stubs2"
mkdir -p "$stubs2"
realawk=$(command -v awk)
cat >"$stubs2/awk" <<EOF
#!/bin/sh
case "\$*" in
  *mode=f*) cat "$tmp/stub-fields" ;;
  *) exec "$realawk" "\$@" ;;
esac
EOF
chmod +x "$stubs2/awk"
if [ "$have_jq" = 1 ]; then
  realjq=$(command -v jq)
  cat >"$stubs2/jq" <<EOF
#!/bin/sh
case "\$*" in
  *'"A" +'*) cat "$tmp/stub-fields" ;;
  *) exec "$realjq" "\$@" ;;
esac
EOF
  chmod +x "$stubs2/jq"
fi
mkin $emp a1 Read "{\"file_path\":\"$repo/a.js\"}"
for m in $modes; do
  for variant in nine ten eight; do
    case "$variant" in
      nine) extra='' ; missing='' ;;
      ten) extra='EFake' ; missing='' ;;
      eight) extra='' ; missing=1 ;;
    esac
    {
      printf 'Atriple-a-crew:engineer\nBa1\nC%s\nDRead\nEx\nF\nG\nH\n' "$transcript_path"
      [ -n "$missing" ] || printf 'I\n'
      [ -z "$extra" ] || printf '%s\n' "$extra"
    } >"$tmp/stub-fields"
    rm -f "$log"
    if [ "$m" = nojq ]; then
      out=$(PATH="$stubs2:$PATH" HOOKS_NO_JQ=1 "$shell_path" "$hook" <"$tmp/in.json" 2>"$tmp/err"); rc=$?
    else
      out=$(PATH="$stubs2:$PATH" "$shell_path" "$hook" <"$tmp/in.json" 2>"$tmp/err"); rc=$?
    fi
    err=$(cat "$tmp/err")
    if [ "$variant" = nine ]; then expect_line "field list of nine lines is used (control)" $m Read x
    else expect_nothing "field list of $variant lines writes nothing" $m; fi
  done
done

# hooks.json registers the hook for every tool
hooks_json="$here/../hooks/hooks.json"
if [ ! -f "$hooks_json" ]; then
  bad "hooks.json has a PreToolUse entry with matcher * for activity-log.sh" - "no $hooks_json"
elif [ "$have_jq" = 1 ]; then
  jq -e . "$hooks_json" >/dev/null 2>&1 && pass "hooks.json is valid JSON" - || bad "hooks.json is valid JSON" - "jq cannot read it"
  if jq -e '[.hooks.PreToolUse[] | select(.matcher == "*") | .hooks[] | select(.type == "command" and (.command | contains("scripts/activity-log.sh")))] | length == 1' "$hooks_json" >/dev/null 2>&1; then
    pass "hooks.json has a PreToolUse entry with matcher * for activity-log.sh" -
  else bad "hooks.json has a PreToolUse entry with matcher * for activity-log.sh" - "not found"; fi
  if jq -e '[.hooks.PreToolUse[] | select(.matcher == "*") | .hooks[] | .timeout] | all(. != null and . > 0)' "$hooks_json" >/dev/null 2>&1; then
    pass "the matcher * entry has a timeout" -
  else bad "the matcher * entry has a timeout" - "missing"; fi
  jq -e '[.hooks.PreToolUse[] | .matcher] | contains(["Bash", "Agent", "*"])' "$hooks_json" >/dev/null 2>&1 &&
    pass "the Bash and Agent entries are still there" - || bad "the Bash and Agent entries are still there" - "changed"
elif [ "$have_py" = 1 ]; then
  if python3 -c '
import json, sys
d = json.load(open(sys.argv[1]))
e = [h for x in d["hooks"]["PreToolUse"] if x.get("matcher") == "*" for h in x["hooks"] if "scripts/activity-log.sh" in h["command"]]
sys.exit(0 if len(e) == 1 else 1)' "$hooks_json" >/dev/null 2>&1; then
    pass "hooks.json is valid JSON with a PreToolUse entry with matcher * for activity-log.sh" -
  else bad "hooks.json entry for activity-log.sh" - "not valid or not found"; fi
else
  if grep -q '"matcher": "\*"' "$hooks_json" && grep -q 'scripts/activity-log.sh' "$hooks_json"; then
    pass "hooks.json names activity-log.sh under matcher * (text check only)" -
  else bad "hooks.json names activity-log.sh under matcher *" - "not found"; fi
fi

# the hook's role list covers every role of the SubagentStart matcher in hooks.json
roles=$(awk -v ev='"SubagentStart"' '
  index($0, ev) { on = 1 }
  on && /"matcher"/ { sub(/^[^:]*: *"/, ""); sub(/",? *$/, ""); print; exit }
' "$hooks_json" 2>/dev/null | sed -n 's/.*\[Tt\]\[0-9\]+\[a-z\]?-(\([^)]*\)).*/\1/p' | tr '|' ' ')
if [ -z "$roles" ]; then
  bad "matcher roles" - "no roles read from $hooks_json"
else
  m=nojq
  for role in $roles; do
    mkin "T1-$role" tm1 Read "{\"file_path\":\"$repo/a.js\"}"; run $m
    expect_line "hooks.json role $role: T1-$role with a crew brief is logged" $m Read a.js
    mkin "triple-a-crew:$role" a1 Read "{\"file_path\":\"$repo/a.js\"}"; run $m
    expect_line "hooks.json role $role: triple-a-crew:$role is logged" $m Read a.js
  done
fi

# Repeat everything under dash (the default /bin/sh on Debian and Ubuntu) when it is installed.
if [ -z "${HOOK_SH:-}" ] && command -v dash >/dev/null 2>&1; then
  HOOK_SH=dash sh "$0" || fail=1
fi
if [ -z "${HOOK_SH:-}" ]; then
  if [ "$fail" = 0 ]; then echo "all activity log tests passed"; else echo "activity log tests FAILED"; fi
fi
exit "$fail"
