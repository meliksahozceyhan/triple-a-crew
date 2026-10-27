# Plan

From T1: nothing blocks publishing and no secrets were found in any of the 19 commits. Three things must
change first: the author's email in 13 commits' metadata (a decision, not a fix), Actioner references in
README, DESIGN and the committed work item, and the missing license. Recommended to run last, after the other
roadmap items, so v1.0.0 ships what they add.

| Task | Goal | File set | Acceptance check | Role | Tier | Depends on |
|---|---|---|---|---|---|---|
| T1 | Research versions, installs, Claude chat, exposure audit, license practice, GitHub settings | read only | done: team/T1-researcher.md | researcher | standard | - |
| T2 | Your decisions, asked when this item starts: license (Anthropic's plugin repos use Apache-2.0); the email in history (keep, rewrite, or a fresh public repo); `ACT-` example keys (keep or rename to a neutral key); keep the committed work items; protect `main`; submit to the Anthropic plugin directory | decisions.md | each answered | user | - | T1 |
| T3 | Content cleanup: README (private install paragraph, actioner-new mentions, roadmap row, tier-1 chat claim, "expected warnings" and Updating text, a line for users without a GitHub SSH key: `CLAUDE_CODE_PLUGIN_PREFER_HTTPS=1`), DESIGN (generic migration section, goal line 19 consistent), profile notes about this machine, work item wording | README.md, docs/DESIGN.md, .crew/** | `git grep -i actioner` hits only what T2 kept | engineer | standard | T2 |
| T4 | License file at the root and in each plugin folder (chat zips and the directory read the plugin folder) | LICENSE, plugins/*/LICENSE | files present; README License section | engineer | mechanical | T2 |
| T5 | `version: 1.0.0` in both `plugin.json` files (not in marketplace.json); `claude plugin validate --strict .` passes | plugins/*/.claude-plugin/plugin.json | strict validation passes | engineer | mechanical | T3 |
| T6 | If T2 says rewrite or fresh repo: a written, step-by-step procedure you run (it rewrites every SHA or creates a new repository) | docs or the PR body | procedure reviewed before you run it | organizer | critical | T2 |
| T7 | Read PR #1-#7 titles, bodies and comments for anything not fit to publish | read only | list of edits or "none" | researcher | mechanical | - |
| T8 | Review the full diff | read only | verdict + findings | reviewer | critical | T3, T4, T5 |
| T9 | You make the repository public; then `claude plugin tag --push` in each plugin folder; install from a clean config with the README steps | - | install works; tags `file-issue--v1.0.0`, `triple-a-crew--v1.0.0` exist | user + organizer | - | T8 |
| T10 | One zip per plugin without `evals/`; you upload `file-issue` in Claude chat and report what loads; README chat table updated | README.md | chat result recorded | user + engineer | mechanical | T9 |
| T11 | GitHub: description, topics, private vulnerability reporting (needed by file-issue's security advice), `SECURITY.md` | SECURITY.md | settings on (you click them) | user + engineer | mechanical | T9 |

## Changes on 2026-10-27 (from T2, see decisions.md)
| Task | Change |
|---|---|
| T3 | Split: **T3a** README, DESIGN, `.crew/profile.md`, work-item wording, README License section (engineer, standard); **T3b** rename `ACT-` keys to `SHOP-` across `plugins/**`, mocks and graders in lockstep (engineer, mechanical). Acceptance for T3a: `git grep -i actioner -- README.md docs/DESIGN.md .crew/profile.md` and a grep for this machine's home path give no hits. For T3b: `git grep "ACT-" -- plugins` gives no hits and the `SHOP-` count equals the old `ACT-` count |
| T4 | Only the three LICENSE files (Apache-2.0, verbatim); the README section is T3a's |
| T5 | Runs beside T3a/T3b/T4: its file set is the two `plugin.json` files |
| T6 | Dropped: the history is kept |
| T7 | PRs #1-#36 |
| T11 | Protect `main` (PRs only, no force-push or deletion) and private vulnerability reporting, both after T9; no directory submission |
| T12 (new) | Run once, after T3b: `stays-out-of-read-only-investigation`, `no-fire-already-tracked`, `linear-duplicate-offers-comment`, `linear-confirms-before-creating`, `profile-confirm-never-creates`; all 1.00, cost reported (about $2) |
