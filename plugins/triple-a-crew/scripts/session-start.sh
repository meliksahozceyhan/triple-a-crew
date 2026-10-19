#!/bin/sh
# SessionStart hook: list the open Triple-A-Crew work items of the current project.
# Silent when there is no .crew/work/index.md or nothing is open. Always exits 0.

input=$(cat 2>/dev/null || true)

cwd=
if [ "${HOOKS_NO_JQ:-}" != "1" ] && command -v jq >/dev/null 2>&1; then
  cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)
else
  cwd=$(printf '%s' "$input" | tr '\n' ' ' |
    sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' 2>/dev/null || true)
fi
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
