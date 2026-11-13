#!/bin/sh
# SessionStart hook: list the open Triple-A-Crew work items of the current project.
# Silent when there is no .crew/work/index.md or nothing is open. Always exits 0.

input=$(cat 2>/dev/null || true)

cwd=
session_id=
source_kind=
if [ "${HOOKS_NO_JQ:-}" != "1" ] && command -v jq >/dev/null 2>&1; then
  cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)
  session_id=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null || true)
  source_kind=$(printf '%s' "$input" | jq -r '.source // empty' 2>/dev/null || true)
else
  flat=$(printf '%s' "$input" | tr '\n' ' ')
  cwd=$(printf '%s' "$flat" |
    sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' 2>/dev/null || true)
  session_id=$(printf '%s' "$flat" |
    sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' 2>/dev/null || true)
  source_kind=$(printf '%s' "$flat" |
    sed -n 's/.*"source"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' 2>/dev/null || true)
fi

# Silent bookkeeping for definitions-check.sh: remember the agent definitions this session loaded.
# Only a fresh start or a resume loads them; clear and compact keep the earlier stamp.
session_id=$(printf '%s' "$session_id" | tr -c 'A-Za-z0-9_-' '_')
case "$source_kind" in
  startup | resume)
    if [ -n "$session_id" ] && [ -n "${CLAUDE_PLUGIN_ROOT:-}" ]; then
      state_dir=${CLAUDE_PLUGIN_DATA:-${TMPDIR:-/tmp}}
      if mkdir -p "$state_dir" 2>/dev/null; then
        find "$state_dir" -maxdepth 1 -type f -name 'triple-a-crew-*' -mtime +7 -exec rm -f {} + 2>/dev/null || true
        stamp=
        for f in "$CLAUDE_PLUGIN_ROOT"/agents/*.md; do
          [ -f "$f" ] || continue
          sum=$(cksum <"$f" 2>/dev/null | awk '{ print $1 }' || true)
          [ -n "$sum" ] || continue
          stamp="$stamp$(basename "$f" .md) $sum
"
        done
        if [ -n "$stamp" ]; then
          (printf '%s' "$stamp" >"$state_dir/triple-a-crew-defs-$session_id") 2>/dev/null || true
        fi
      fi
    fi
    ;;
esac
[ -n "$cwd" ] || cwd=${CLAUDE_PROJECT_DIR:-}
[ -n "$cwd" ] || cwd=$(pwd)
[ -d "$cwd" ] || exit 0

# Root rule of the organizer: the git root unless it is $HOME, else the working directory.
dir=$cwd
root=
while :; do
  if [ -e "$dir/.git" ]; then
    root=$dir
    break
  fi
  if [ "$dir" = "/" ] || [ "$dir" = "${HOME:-}" ] || [ -z "$dir" ]; then
    break
  fi
  parent=$(dirname "$dir")
  [ "$parent" != "$dir" ] || break
  dir=$parent
done
if [ -z "$root" ] || [ "$root" = "${HOME:-}" ]; then
  root=$cwd
fi
index=
[ -f "$root/.crew/work/index.md" ] && index="$root/.crew/work/index.md"
[ -n "$index" ] || exit 0

items=$(awk '
  /^## / { open = ($0 ~ /^## Open[ \t\r]*$/); next }
  open && $0 !~ /^[ \t\r]*$/ { sub(/\r$/, ""); print }
' "$index" 2>/dev/null || true)
[ -n "$items" ] || exit 0

total=$(printf '%s\n' "$items" | wc -l | tr -d ' ')
echo "Open Triple-A-Crew work items in this project (from .crew/work/index.md):"
printf '%s\n' "$items" | head -n 15 | cut -c1-200
if [ "$total" -gt 15 ]; then
  echo "... and $((total - 15)) more"
fi
exit 0
