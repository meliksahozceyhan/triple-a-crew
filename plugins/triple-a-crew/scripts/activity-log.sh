#!/bin/sh
# PreToolUse hook (matcher: *): append one short line to the live log of a crew employee, so a page can show
# what the employee is doing right now. The line is: UTC time, tool name, short target, separated by tabs.
# Only a crew employee gets a line (agent_type triple-a-crew:* or a T<n>-<role> teammate, and an agent_id),
# and only when the work item has a live/ folder already: <root>/.crew/work/<id>/live/<name>.log, where the
# status file of its brief is <root>/.crew/work/<id>/team/<name>.md. The hook creates no folder and keeps no
# state: it only appends and never reads the log back. It writes nothing when .crew, .crew/work, the work item
# folder or live/ is a symbolic link, or when the log path exists and is not a plain file (a link or a folder).
# A target is the file path (relative to the root when inside it), the program name of a Bash call (at most 30
# characters, counted on the whole word unless it starts with /, ./ or ../; and none when a NAME=value in front
# of it holds anything but plain text), the host of a WebFetch
# url without an @, or a search pattern; never content or a full command.
# It never prints, never refuses a call and always exits 0. On any error or doubt it writes nothing.
# The main session leaves at once, without starting any other program, unless its input holds the text
# "agent_id" (a string or a key of that name, for example a Grep for it): then jq or awk reads the input and
# still no line is written.

# Read stdin with the shell's own read: starting cat costs more than the whole early exit. The input is one
# line of JSON; further lines (a pretty-printed input) are joined.
input=
while IFS= read -r line || [ -n "$line" ]; do
  input="$input$line"
done 2>/dev/null
case "$input" in
  *'"agent_id"'*) ;;
  *) exit 0 ;;
esac

# Bytes, not characters, for ${#x}, awk and every cut below.
LC_ALL=C
export LC_ALL

use_jq=0
if [ "${HOOKS_NO_JQ:-}" != "1" ] && command -v jq >/dev/null 2>&1; then
  use_jq=1
fi
# The no-jq reader walks the whole input: one this long is a pasted file, not a call worth logging.
if [ "$use_jq" = 0 ] && [ "${#input}" -gt 100000 ]; then
  exit 0
fi

# No-jq reader. It splits the text at every double quote, so a long string costs one step, and decodes only
# the values it wants. Exit 3: a string it cannot decode reliably, or a broken input.
# Mode f (-v mode=f): prints the nine fields below, one per line, each with its letter in front. A field is
# the first string value of that key, cut to 1000 characters, control characters turned into spaces.
# Mode b: the text of the first line of the first message that starts with **Status file:**, without the marker.
jread='
function endsodd(x) {
  if (substr(x, length(x), 1) != "\\") return 0
  match(x, /\\+$/)
  return RLENGTH % 2
}
function decode(raw,   m, parts, i, t, e, out, h) {
  taint = 0
  gsub(/\\/, "\002", raw)
  m = split(raw, parts, /\002/)
  out = parts[1]
  i = 2
  while (i <= m) {
    t = parts[i]
    if (t == "") {
      out = out "\\"
      i++
      if (i <= m) out = out parts[i]
      i++
      continue
    }
    e = substr(t, 1, 1); t = substr(t, 2)
    if (e == "n") out = out "\n" t
    else if (e == "t") out = out "\t" t
    else if (e == "r") out = out "\r" t
    else if (e == "b" || e == "f") out = out " " t
    else if (e == "\"" || e == "/") out = out e t
    else if (e == "u") {
      h = substr(t, 1, 4)
      if (length(h) < 4) out = out t
      else if (h ~ /^00[01][0-9a-fA-F]$/ || h ~ /^007[fF]$/) out = out " " substr(t, 5)
      else { out = out "\003" substr(t, 5); taint = 1 }
    }
    else { out = out "\003" t; taint = 1 }
    i++
  }
  return out
}
function strend(k,   e) {
  e = k
  while (e < m && endsodd(p[e])) e++
  return e
}
function joined(a, b, lim,   x, j, n) {
  x = p[a]; n = length(x)
  for (j = a + 1; j <= b && n <= lim; j++) { x = x "\"" p[j]; n += length(p[j]) + 1 }
  return x
}
BEGIN {
  want["agent_type"] = "A"; want["agent_id"] = "B"; want["transcript_path"] = "C"; want["tool_name"] = "D"
  want["file_path"] = "E"; want["notebook_path"] = "F"; want["url"] = "G"; want["pattern"] = "H"
  want["command"] = "I"
  # top-level keys sit at depth 1, the keys of tool_input at depth 2
  level["agent_type"] = 1; level["agent_id"] = 1; level["transcript_path"] = 1; level["tool_name"] = 1
  level["file_path"] = 2; level["notebook_path"] = 2; level["url"] = 2; level["pattern"] = 2
  level["command"] = 2
  if (mode == "f") RS = "\001"
}
mode == "f" { s = $0 }
mode == "b" && NR == 1 { s = $0; exit }
END {
  m = split(s, p, /"/)
  k = 1
  depth = 0
  while (k + 1 <= m) {
    t = p[k]
    depth += gsub(/[[{]/, "", t)
    depth -= gsub(/[]}]/, "", t)
    e = strend(k + 1)
    if (e + 1 > m) exit 3
    nextk = e + 1
    if (p[e + 1] ~ /^[ \t\r\n]*:/ && e == k + 1 && p[e + 1] ~ /^[ \t\r\n]*:[ \t\r\n]*$/ && e + 2 <= m) {
      key = p[k + 1]
      if (mode == "f" && (key in want) && !(key in got) && depth == level[key]) {
        e2 = strend(e + 2)
        if (e2 + 1 > m) exit 3
        v = joined(e + 2, e2, 3000)
        if (length(v) > 3000) v = substr(v, 1, 3000)
        v = decode(v)
        if (taint) exit 3
        gsub(/[[:cntrl:]]/, " ", v)
        got[key] = substr(v, 1, 1000)
        nextk = e2 + 1
      } else if (mode == "b" && (key == "content" || key == "text")) {
        e2 = strend(e + 2)
        if (e2 + 1 > m) exit 3
        v = joined(e + 2, e2, 20000)
        if (length(v) > 20000) v = substr(v, 1, 20000)
        v = decode(v)
        nl = split(v, lines, /\n/)
        for (j = 1; j <= nl; j++) {
          line = lines[j]; sub(/\r$/, "", line)
          if (match(line, /^[ \t]*\*\*Status file:\*\*/)) {
            line = substr(line, RLENGTH + 1)
            if (index(line, "\003") > 0) exit 3
            print line
            exit 0
          }
        }
        nextk = e2 + 1
      }
    }
    k = nextk
  }
  if (mode == "f") {
    printf "A%s\nB%s\nC%s\nD%s\n", got["agent_type"], got["agent_id"], got["transcript_path"], got["tool_name"]
    printf "E%s\nF%s\nG%s\nH%s\nI%s\n", got["file_path"], got["notebook_path"], got["url"], got["pattern"], got["command"]
    exit 0
  }
  exit 1
}'

if [ "$use_jq" = 1 ]; then
  fields=$(printf '%s' "$input" | jq -r '
    def c: if type == "string" then .[0:1000] | gsub("[\\x00-\\x1f\\x7f]"; " ") else "" end;
    (.tool_input | if type == "object" then . else {} end) as $i
    | "A" + (.agent_type | c), "B" + (.agent_id | c), "C" + (.transcript_path | c), "D" + (.tool_name | c),
      "E" + ($i.file_path | c), "F" + ($i.notebook_path | c), "G" + ($i.url | c), "H" + ($i.pattern | c),
      "I" + ($i.command | c)' 2>/dev/null) || exit 0
else
  fields=$(printf '%s' "$input" | awk -v mode=f "$jread" 2>/dev/null) || exit 0
fi

agent_type= agent_id= transcript_path= tool= file_path= notebook_path= url= pattern= command=
nl='
'
IFS=$nl
set -f
set -- $fields
unset IFS
# nine fields, each line with its letter in front: a value with a line break in it would shift them
[ $# -eq 9 ] || exit 0
for line; do
  case "$line" in
    A*) agent_type=${line#A} ;;
    B*) agent_id=${line#B} ;;
    C*) transcript_path=${line#C} ;;
    D*) tool=${line#D} ;;
    E*) file_path=${line#E} ;;
    F*) notebook_path=${line#F} ;;
    G*) url=${line#G} ;;
    H*) pattern=${line#H} ;;
    I*) command=${line#I} ;;
  esac
done

# A triple-a-crew:<role> type is a crew employee. A T<n>-<role> name (agent-team teammate) is one only when
# its brief names a status file, which is needed below anyway; the role list is the one in hooks/hooks.json.
[ -n "$tool" ] && [ -n "$agent_id" ] && [ -n "$transcript_path" ] || exit 0
case "$agent_id" in *[!A-Za-z0-9_-]*) exit 0 ;; esac
case "$agent_type" in
  triple-a-crew:?*)
    case "${agent_type#triple-a-crew:}" in *[!a-z-]*) exit 0 ;; esac
    ;;
  [Tt][0-9]*)
    t=${agent_type#?}
    d=${t%%[!0-9]*}
    t=${t#"$d"}
    case "$t" in [a-z]-*) t=${t#?} ;; esac
    case "$t" in
      -researcher | -engineer | -test-engineer | -verifier | -reviewer) ;;
      *) exit 0 ;;
    esac
    ;;
  *) exit 0 ;;
esac

# The employee's own transcript: its first line is the brief.
brief="${transcript_path%.jsonl}/subagents/agent-$agent_id.jsonl"
[ -f "$brief" ] || exit 0
if [ "$use_jq" = 1 ]; then
  rest=$(jq -rn 'first(input | .message.content
      | if type == "string" then . elif type == "array" then (map(.text? // "") | join("\n")) else empty end
      | split("\n")[] | select(test("^[ \t]*\\*\\*Status file:\\*\\*"))
      | sub("^[ \t]*\\*\\*Status file:\\*\\*"; "") | sub("\r$"; ""))' "$brief" 2>/dev/null) || exit 0
else
  rest=$(awk -v mode=b "$jread" "$brief" 2>/dev/null) || exit 0
fi
[ -n "$rest" ] || exit 0

# parse_status <path>: sets root, id and name when the path is <root>/.crew/work/<id>/team/<name>.md
parse_status() {
  case "$1" in /*.md) ;; *) return 1 ;; esac
  name=${1##*/}
  name=${name%.md}
  dir=${1%/*}
  case "$dir" in */.crew/work/*/team) ;; *) return 1 ;; esac
  dir=${dir%/team}
  id=${dir##*/}
  dir=${dir%/*}
  case "$dir" in */.crew/work) ;; *) return 1 ;; esac
  root=${dir%/.crew/work}
  case "$name" in '' | [!A-Za-z0-9]* | *[!A-Za-z0-9._-]*) return 1 ;; esac
  case "$id" in '' | . | ..) return 1 ;; esac
  [ -n "$root" ]
}
while :; do
  case "$rest" in ' '* | '	'* | '`'*) rest=${rest#?} ;; *) break ;; esac
done
while :; do
  case "$rest" in *' ' | *'	' | *'`') rest=${rest%?} ;; *) break ;; esac
done
if ! parse_status "$rest"; then
  # a path followed by words: take its first word
  first=${rest%%[ 	]*}
  first=${first%'`'}
  parse_status "$first" || exit 0
fi

live="$root/.crew/work/$id/live"
# Nothing is written through a symbolic link: not at .crew, .crew/work, the work item folder or live.
[ ! -L "$root/.crew" ] && [ ! -L "$root/.crew/work" ] && [ ! -L "$root/.crew/work/$id" ] || exit 0
[ -d "$live" ] && [ ! -L "$live" ] || exit 0
log="$live/$name.log"
# The log is a plain file or does not exist yet: a link (to a file the project does not own) or a folder is not written.
[ ! -L "$log" ] || exit 0
[ ! -e "$log" ] || [ -f "$log" ] || exit 0

# cut_to <characters> <bytes> <text>: sets cut to the text cut to at most that many characters and bytes,
# never inside a UTF-8 character. Only text longer than the limit costs a program.
cut_to() {
  cut=$3
  [ "${#cut}" -gt "$1" ] || return 0
  cut=$(printf '%s' "$3" | awk -v maxc="$1" -v maxb="$2" '
    BEGIN { for (i = 128; i < 192; i++) cont[sprintf("%c", i)] = 1 }
    {
      s = $0; n = length(s); chars = 0; keep = 0; i = 1
      while (i <= n) {
        j = i + 1
        while (j <= n && (substr(s, j, 1) in cont)) j++
        if (chars + 1 > maxc || j - 1 > maxb) break
        chars++; keep = j - 1; i = j
      }
      print substr(s, 1, keep)
    }' 2>/dev/null) || exit 0
}

target=
case "$tool" in
  Read | Edit | Write | NotebookEdit)
    if [ "$tool" = NotebookEdit ]; then target=$notebook_path; else target=$file_path; fi
    case "$target" in "$root"/*) target=${target#"$root"/} ;; esac
    ;;
  Bash)
    # the program name only: the first word that is not NAME=value, in its last path component. The command
    # is split at blanks without any notion of quotes, so a NAME=value whose value is not plain text (it may
    # hold quotes or a substitution, and blanks) ends the search: no target.
    prog=
    set -f
    set -- $command
    for w; do
      case "$w" in
        *=*)
          var=${w%%=*}
          case "$var" in
            '' | [0-9]* | *[!A-Za-z0-9_]*) ;;
            *)
              case "${w#*=}" in *[!A-Za-z0-9_./:@%+,=-]*) break ;; esac
              continue
              ;;
          esac
          ;;
      esac
      prog=$w
      break
    done
    case "$prog" in
      '' | *[!A-Za-z0-9._/-]*) ;;
      *)
        target=${prog##*/}
        # A longer name is more likely a pasted token than a program. A word that does not start like a path
        # (/, ./, ../) is measured whole: a token may hold slashes.
        case "$prog" in
          /* | ./* | ../*) ;;
          *) [ "${#prog}" -le 30 ] || target= ;;
        esac
        [ "${#target}" -le 30 ] || target=
        ;;
    esac
    ;;
  WebFetch)
    # the host only: no scheme, user, port, path or query. A url with an @ anywhere may carry a user name
    # and password (a / in the password would hide the @ from a host cut), so it gets no target.
    scheme=${url%%://*}
    if [ "$scheme" != "$url" ]; then
      case "$url" in *@*) scheme= ;; esac
      case "$scheme" in
        '' | [!A-Za-z]* | *[!A-Za-z0-9+.-]*) ;;
        *)
          host=${url#*://}
          host=${host%%[/?#]*}
          host=${host%%:*}
          case "$host" in
            '' | *[!A-Za-z0-9.-]*) ;;
            *) target=$host ;;
          esac
          ;;
      esac
    fi
    ;;
  Grep | Glob)
    cut_to 60 1000 "$pattern"
    target=$cut
    ;;
esac
cut_to 120 1000 "$target"
target=$cut

ts=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null) || exit 0
[ -n "$ts" ] || exit 0
tab='	'
body="$ts$tab$tool$tab$target"
# the whole line is at most 200 bytes, its line break included
cut_to 199 199 "$body"
body=$cut
[ -n "$body" ] || exit 0

# One write per line, so lines of parallel calls do not mix.
{ printf '%s\n' "$body" >>"$log"; } 2>/dev/null || :
exit 0
