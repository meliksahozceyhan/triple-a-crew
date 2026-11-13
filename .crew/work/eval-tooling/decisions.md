# Decisions

- **2026-11-13 Approval phase skipped.** The user saw the three-track plan and said to create the tasks and
  start implementing them, in parallel where possible. Every change still reaches `main` only through a pull
  request the user merges.
- **2026-11-13 Engineers work in this branch's worktree by absolute path, not in worktrees of their own.** See
  `hook-guards/decisions.md`: a worktree-isolated employee cannot write its status file in the main checkout.
- **2026-11-13 A Node script, not POSIX sh.** Grader patterns are JavaScript regexes with lookbehind,
  `[\s\S]` and counted groups, which `grep -E` lacks, and the frontmatter's `''` escapes need a real parser.
  `node` is already used by `verify`. Rejected: sh like `test-hooks.sh` (it is sh only because hooks run as
  `sh <script>`).
- **2026-11-13 The script and its rows live in a new top-level `scripts/` folder.** They test both plugins and
  are not shipped in either, so no version bump is involved. Rows sit in `scripts/grader-rows/<plugin>/<case>/`,
  not inside the case folders: nothing says the eval harness ignores an unknown folder in a case. Rejected:
  `plugins/triple-a-crew/scripts/` (shipped to users, and it would cover only one plugin).
- **2026-11-13 Two row files per grader, named for the expected verdict:** `<grader>.pass.jsonl` and
  `<grader>.fail.jsonl`. A grader with no rows is reported as "no rows" and never counts as a pass. Rows are
  added as cases get run with `--keep-temp`; this item seeds the first ones from one cheap run.
- **2026-11-13 Out of reach, on purpose:** `llm` and `file_exists` graders, and `regex` graders that read a
  workspace file. They are listed, not checked.
