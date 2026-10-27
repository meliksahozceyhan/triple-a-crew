# Findings

- 2026-10-19 · `docs/DESIGN.md:19` promises "nothing personal or Actioner-specific" while its migration
  section names Actioner's stack · found by T1 researcher · fixed by T3 of this plan
- 2026-10-19 · README tier table says `onboard` and `test-harden` load in Claude chat; they load but need a
  filesystem and shell to work · found by T1 researcher · fixed by T3 of this plan
- 2026-10-19 · `.crew/profile.md` notes describe this machine (credential helper, user-scope install) ·
  found by T1 researcher · decided in T2, edited in T3
- 2026-10-27 · The T3b file list came from `git grep "ACT-"`, which missed the bare Linear team key `ACT` in
  11 more files (three `list_teams` mocks, a fixture, a prompt, two graders, two skill files, a README line,
  `profile-format.md`); the engineer found them and asked. Lesson for the retro: an identifier rename needs a
  word-boundary grep for the bare token too, not only its prefixed form. (team/T3b-engineer.md "Findings")
- 2026-10-27 · PR bodies #1, #2, #3, #4, #6 and #8 carry ten passages that name the previous project or an
  `ACT-` key (no credentials, emails or paths anywhere; every comment array is empty). Editing them is a
  GitHub write: the user decides at T11, with `gh pr edit <n> --body`. (team/T7-researcher.md)
- 2026-10-27 · Claude chat, reviewing the uploaded `file-issue` zip unasked, noted that the plugin's evals mock
  only Linear, so the GitHub, Jira, GitLab, Asana, ClickUp and Notion tracker paths have no case. True: the
  tracker reference files exist, the cases don't. Outside this item; a candidate issue for the plugin
  repository at close. (T10, the user's paste)
