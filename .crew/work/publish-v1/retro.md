# Retro: publish-v1

**Closed:** 2026-10-27

## What happened
- Planned on 2026-10-19 and run last, on 2026-10-27, as agreed. The six T2 decisions came first and reshaped
  the plan: T3 split into docs cleanup and the key rename, T4 narrowed to the license files, T6 (history
  rewrite) dropped, T12 (five evals) added (decisions.md "T2", "Plan changes")
- Five employees ran in parallel on disjoint file sets without worktrees, and none collided (board.md)
- T3b's file list came from `git grep "ACT-"`, which missed the bare team key `ACT` in 11 files; the engineer
  found them and asked. The T8 reviewer then found two more in README and DESIGN, which neither T3a's check
  (`actioner`, home path) nor T3b's scope (`plugins/`) covered (findings.md; team/T8-reviewer.md R1, R2)
- T8's must-fix: the README's local-checkout example named the author's folder, `./claude-skill-folder`; a
  clone of the public repository lands in `./triple-a-crew`. The convention "Run every command example"
  covers it; T3a didn't run that one (team/T8-reviewer.md R3)
- Review loop as written: T8 changes requested, the organizer fixed, T14 approved with three nits; verify 3/3
  twice (T13, T15); the five rename-affected evals 1.00 for $0.67 against about $2 planned
- T9: `claude plugin tag --push` would have pushed with git's own credentials, which this machine lacks for
  HTTPS; the tags were created with the command and pushed with the gh helper. A clean-config install worked
  over SSH and, with `CLAUDE_CODE_PLUGIN_PREFER_HTTPS=1`, over HTTPS (decisions.md "T9")
- T10: a plugin zip in Claude chat is a per-conversation skill, not an install; the whole `file-issue` flow
  ran there: trigger on an aside, duplicate search in the connected Linear, a complete draft marked
  unconfirmed, and a stop for confirmation. Chat also reviewed the plugin unasked and noted the evals mock
  only Linear (decisions.md "T10"; findings.md)
- T11 after T9: branch protection and private vulnerability reporting are free-plan features for public
  repositories (decisions.md "T2", "T11")
- T1's full research report (2026-10-19) lived only in its final message; the plan had captured what T2
  needed, so nothing was lost this time. An instance of #37 (team/T1-researcher.md)

## Lessons
| # | Lesson | Evidence | Repeat of | Goes to | Status |
|---|---|---|---|---|---|
| L1 | An identifier rename needs a word-boundary grep for the bare token over the whole tree, and one owner; a prefixed grep plus a scope split at `plugins/` missed 13 files between them | findings.md; team/T8-reviewer.md R1, R2 | effort-ladder L2 (grep for the words a change hinges on) | `.crew/profile.md` note | accepted |
| L2 | An install example used the author's folder name; a stranger's clone is `./triple-a-crew`. The README convention "Run every command example" already covers it and wasn't followed | team/T8-reviewer.md R3 | README "Run every command example" | `retro.md` only (the convention exists) | kept |
| L3 | `claude plugin tag --push` pushes with git's own credentials; here, create the tag with the command and push the ref with the gh helper | decisions.md "T9" | | `.crew/profile.md` note | accepted |
| L4 | In Claude chat a plugin zip is a per-conversation skill, not an install; the `file-issue` flow runs there in full through connectors | decisions.md "T10" | | README tier footnote (this close PR) | accepted |
| L5 | Branch protection and private vulnerability reporting need the repository public on the free plan; order T11 after T9 | decisions.md "T2" | | `retro.md` only | kept |
| L6 | A researcher's full report in its final message only is lost to a later session; the plan saved this item | team/T1-researcher.md | https://github.com/meliksahozceyhan/triple-a-crew/issues/37 | `retro.md` only (#37 is open) | kept |

## Proposed text
- **L1** (`.crew/profile.md` note): "When renaming an identifier, grep the whole tree for the bare token with
  word boundaries (`git grep -n -w -i TOKEN`), not only its prefixed form, and give the rename one owner across
  `plugins/`, README and DESIGN (publish-v1: `ACT-` had 17 hits, the bare `ACT` 13 more)."
- **L3** (`.crew/profile.md` note, after the push line): "`claude plugin tag --push` pushes with git's own
  credentials. Create the tag with `claude plugin tag <plugin folder>` and push `refs/tags/<tag>` with the
  helper line above."
- **Follow-up from findings.md (step 9, through `file-issue`):** "file-issue's evals mock only Linear; the
  GitHub, Jira, GitLab, Asana, ClickUp and Notion tracker paths have no case", in this repository's tracker.
  Status: declined by the user on 2026-10-27 after seeing the draft; recorded in findings.md, not tracked.
