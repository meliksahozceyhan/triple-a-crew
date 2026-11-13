#!/bin/sh
# PreToolUse hook (matcher: Bash): refuse a crew employee's Bash call that chains commands, pipes,
# redirects or uses cd, the rule every brief carries (skills/work/protocol.md, "one plain command per call").
# Exit 0 with no output allows the call; exit 2 with a message on stderr refuses it.
# It only ever looks at crew employees (agent_type triple-a-crew:* or a T<n>-<role> teammate); the main
# session and other plugins' agents are never refused. When unsure, or on any internal error, it allows.

input=$(cat 2>/dev/null || true)
[ -n "$input" ] || exit 0

use_jq=0
if [ "${HOOKS_NO_JQ:-}" != "1" ] && command -v jq >/dev/null 2>&1; then
  use_jq=1
fi
# The no-jq reader walks the input one character at a time, for the main session too (it has to reach the
# end to find no agent_type): input this long is a pasted file, not a call worth guarding.
if [ "$use_jq" = 0 ] && [ "${#input}" -gt 100000 ]; then
  exit 0
fi

# No-jq reader: prints the string value of the first key in $keys (or, with all=1, of every such key, one
# per line). Exit 3 means an escape it cannot decode (\u, \b, \f) or a broken string: the caller is unsure.
jscan='
function ws(p) { while (substr(s, p, 1) ~ /[ \t\r\n]/) p++; return p }
function readstr(p,   c, e) {
  sval = ""
  while (p <= n) {
    c = substr(s, p, 1)
    if (c == "\"") return p + 1
    if (c == "\\") {
      e = substr(s, p + 1, 1); p += 2
      if (e == "n") sval = sval "\n"
      else if (e == "t") sval = sval "\t"
      else if (e == "r") sval = sval "\r"
      else if (e == "\"" || e == "\\" || e == "/") sval = sval e
      else return -1
    } else { sval = sval c; p++ }
  }
  return -1
}
BEGIN { RS = "\001" }
{ s = $0 }
END {
  n = length(s); keys = "," keys ","; i = 1; out = ""
  while (i <= n) {
    if (substr(s, i, 1) != "\"") { i++; continue }
    i = readstr(i + 1)
    if (i < 0) exit 3
    j = ws(i)
    if (substr(s, j, 1) == ":" && index(keys, "," sval ",") > 0) {
      j = ws(j + 1)
      if (substr(s, j, 1) == "\"") {
        i = readstr(j + 1)
        if (i < 0) exit 3
        if (all) { out = out sval "\n"; continue }
        printf "%s", sval
        exit 0
      }
    }
  }
  if (out != "") { printf "%s", out; exit 0 }
  exit 1
}'

# top_field <key>: a string field of the hook input; fails when the input cannot be read reliably
top_field() {
  if [ "$use_jq" = 1 ]; then
    printf '%s' "$input" | jq -r --arg k "$1" '.[$k] | select(type == "string")' 2>/dev/null
  else
    printf '%s' "$input" | awk -v keys="$1" "$jscan" 2>/dev/null
  fi
}

agent_type=$(top_field agent_type) || exit 0
case "$agent_type" in
  '') exit 0 ;;
esac
# A triple-a-crew:<role> type is a crew employee. A T<n>-<role> name (agent-team teammate) is only a crew
# employee when its brief says so, checked below; the role list is the one in hooks/hooks.json.
teammate=0
if printf '%s\n' "$agent_type" | grep -Eq '^triple-a-crew:[a-z-]+$' 2>/dev/null; then
  :
elif printf '%s\n' "$agent_type" |
  grep -Eq '^[Tt][0-9]+[a-z]?-(researcher|engineer|test-engineer|verifier|reviewer)$' 2>/dev/null; then
  teammate=1
else
  exit 0
fi

if [ "$use_jq" = 1 ]; then
  cmd=$(printf '%s' "$input" | jq -r '.tool_input.command | select(type == "string")' 2>/dev/null) || exit 0
else
  cmd=$(printf '%s' "$input" | awk -v keys=command "$jscan" 2>/dev/null) || exit 0
fi
[ -n "$cmd" ] || exit 0
# The analysis walks the command one character at a time; a command this long is a pasted file or a
# heredoc body, not a chain to catch, so it is allowed unseen.
[ "${#cmd}" -le 20000 ] || exit 0

agent_id=$(top_field agent_id) || agent_id=
agent_id=$(printf '%s' "$agent_id" | tr -c 'A-Za-z0-9_-' '_')
# Without an agent id there is no state for the resend valve below, so a refusal could trap: allow.
[ -n "$agent_id" ] || exit 0
state_dir=${CLAUDE_PLUGIN_DATA:-${TMPDIR:-/tmp}}

# The brief is line 1 of the subagent's own transcript.
transcript_path=$(top_field transcript_path) || transcript_path=
brief=
[ -z "$transcript_path" ] || brief="${transcript_path%.jsonl}/subagents/agent-$agent_id.jsonl"

brief_text() {
  [ -n "$brief" ] && [ -f "$brief" ] || return 1
  first=$(head -n 1 "$brief" 2>/dev/null) || return 1
  [ -n "$first" ] || return 1
  if [ "$use_jq" = 1 ]; then
    printf '%s' "$first" |
      jq -r '.message.content | if type == "string" then . else (map(.text? // "") | join("\n")) end' 2>/dev/null
  else
    printf '%s' "$first" | awk -v keys=content,text -v all=1 "$jscan" 2>/dev/null
  fi
}

text=
text_done=0
load_text() {
  [ "$text_done" = 1 ] && return 0
  text_done=1
  text=$(brief_text) || text=
}

# A teammate-style name proves nothing by itself (a user's own agent team may use such names): guard it
# only when its brief can be read and has the **Status file:** line every crew brief carries.
if [ "$teammate" = 1 ]; then
  load_text
  printf '%s\n' "$text" | grep -Eq '^[[:space:]]*\*\*Status file:\*\*' 2>/dev/null || exit 0
fi

# Walks the command once. Text inside single quotes, double quotes (backslash escapes), after an escaping
# backslash and in comments is ignored. Line 1 lists the constructs found; line 2 is "doc" when the only
# constructs are the documented form: cd "<folder>" && <one plain command>.
analyzer='
function flag(name) {
  if (!(name in seen)) { seen[name] = 1; nflag++; found = found (found == "" ? "" : ", ") name }
}
function endword() {
  if (inword) {
    if (cmdstart) {
      if (word == "cd") { flag("cd as the command word"); ncd++ }
      else if (word == "time") flag("a leading time")
      cmdword = word
      cmdstart = 0
    }
    inword = 0
    word = ""
  }
}
function sep() { endword(); cmdstart = 1; cmdword = ""; wstart = 1 }
BEGIN { RS = "\001" }
{ s = $0 }
END {
  q = sprintf("%c", 39)
  sub(/^[ \t\r\n]+/, "", s); sub(/[ \t\r\n]+$/, "", s)
  n = length(s); cmdstart = 1; wstart = 1; st = 0
  for (i = 1; i <= n; i++) {
    c = substr(s, i, 1); nx = substr(s, i + 1, 1)
    if (st == 1) {
      if (c == q) st = 0
      else if (cmdstart) word = word c
      continue
    }
    if (st == 2) {
      if (c == "\\") { i++; if (cmdstart) word = word nx }
      else if (c == "\"") st = 0
      else {
        if (c == "$" && nx == "?" && cmdword == "echo") flag("echo $?")
        if (cmdstart) word = word c
      }
      continue
    }
    if (c == " " || c == "\t" || c == "\r") { endword(); wstart = 1 }
    else if (c == "\n") { flag("a line break between commands"); sep() }
    else if (c == "\\") { inword = 1; wstart = 0; i++; if (cmdstart && nx != "\n") word = word nx }
    else if (c == q) { st = 1; inword = 1; wstart = 0 }
    else if (c == "\"") { st = 2; inword = 1; wstart = 0 }
    else if (c == "#" && wstart) { while (i < n && substr(s, i + 1, 1) != "\n") i++ }
    else if (c == "&") {
      if (nx == "&") { flag("&&"); nand++; if (nand == 1) andpos = i; i++ }
      else if ((i == 1 || substr(s, i - 1, 1) ~ /[ \t]/) && nx ~ /[ \t]/) flag("a lone &")
      sep()
    }
    else if (c == "|") {
      if (nx == "|") { flag("||"); i++ } else flag("a pipe (|)")
      sep()
    }
    else if (c == ";") { flag(";"); sep() }
    else if (c == ">") {
      endword(); wstart = 1
      if (nx == ">") { flag("redirection (>>)"); i++ }
      else if (nx == "&") { flag("redirection (>&)"); i++ }
      else flag("redirection (>)")
    }
    else if (c == "<") {
      endword(); wstart = 1
      if (nx == "<") { flag("heredoc (<<)"); i++; if (substr(s, i + 1, 1) == "<") i++ }
      else flag("redirection (<)")
    }
    else {
      if (c == "$" && nx == "?" && cmdword == "echo") flag("echo $?")
      inword = 1; wstart = 0
      if (cmdstart) word = word c
    }
  }
  endword()
  if (found == "") exit 0
  print found
  re = "^[ \t]*cd[ \t]+(\"[^\"]*\"|" q "[^" q "]*" q ")[ \t]*$"
  if (nflag == 2 && nand == 1 && ncd == 1 && ("&&" in seen) \
      && substr(s, 1, andpos - 1) ~ re && substr(s, andpos + 2) ~ /[^ \t\r\n]/) print "doc"
}'

analysis=$(printf '%s' "$cmd" | awk "$analyzer" 2>/dev/null) || exit 0
found=$(printf '%s\n' "$analysis" | sed -n 1p)
doc=$(printf '%s\n' "$analysis" | sed -n 2p)
[ -n "$found" ] || exit 0

# The resend valve, so this hook never traps an employee: every refused command is remembered as an empty
# marker file named after the agent and the command's checksum and length, and the same command sent again
# runs and removes its marker. One file per refusal means no read-modify-write, so hook runs of parallel
# Bash calls cannot lose each other's refusals; allowed calls leave the markers alone.
sum=$(printf '%s' "$cmd" | cksum 2>/dev/null) || exit 0
marker="$state_dir/triple-a-crew-bash-$agent_id-$(printf '%s' "$sum" | tr ' ' '-')"
if [ -e "$marker" ]; then
  # If another run took the marker first, rm has nothing to do and the command runs all the same.
  rm -f "$marker" 2>/dev/null
  exit 0
fi

# Exception: the brief lists this exact command.
load_text
brief_readable=0
if [ -n "$text" ]; then
  brief_readable=1
  printf '%s' "$text" |
    CMD="$cmd" awk 'BEGIN { RS = "\001"; c = ENVIRON["CMD"] } { s = $0 } END { exit (c != "" && index(s, c) > 0) ? 0 : 1 }' 2>/dev/null
  # 0: the brief lists it; 1: it does not; anything else is an internal error
  case $? in
    1) ;;
    *) exit 0 ;;
  esac
fi

# Without a readable brief only the documented form is allowed.
if [ "$brief_readable" = 0 ] && [ "$doc" = doc ]; then
  exit 0
fi

# Remember the refusal. If that is impossible the resend valve cannot work, so allow instead.
mkdir -p "$state_dir" 2>/dev/null
( : >"$marker" ) 2>/dev/null || exit 0
# Markers older than a week belong to finished work.
find "$state_dir" -maxdepth 1 -type f -name 'triple-a-crew-*' -mtime +7 -exec rm -f {} + 2>/dev/null || true

{
  printf '%s\n' "Bash call refused by the Triple-A-Crew bash guard: the command contains $found."
  printf '%s\n' "Rule: one plain command per Bash call (no &&, ||, ;, a lone &, pipes, redirections, line breaks between commands, cd, a leading time or echo \$?), so the user's permission rules match the command and the exit code is the command's own. Use absolute paths, or the tool's own folder flag such as git -C <dir>. A command your brief lists is allowed exactly as written."
  printf '%s\n' "If you need exactly this command, send it once more unchanged and it will run."
} >&2
exit 2
