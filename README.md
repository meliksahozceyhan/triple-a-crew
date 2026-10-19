# Triple-A-Crew

Workflow plugins for Claude Code, kept in one repository and installed into every project.

The plugins hold **process**: how work moves from a problem to a shipped change. Each project keeps its own
**knowledge**: its stack, conventions and commands, in a small profile at `.crew/profile.md`. At the center
is an organizer that runs work like a team lead: it understands the problem, staffs subagents ("employees")
on the right models, tracks their state, answers their questions, and files follow-up issues for anything
out of scope.

> **Status: v1, private.** Two plugins: `file-issue`, and `triple-a-crew` with the organizer, three
> employees, `onboard`, and two workflow skills migrated from actioner-new (`test-harden`, `handoff`). The
> full design is in [docs/DESIGN.md](docs/DESIGN.md).

## Contents

- [Why this exists](#why-this-exists)
- [How it is organized](#how-it-is-organized)
- [Plugins](#plugins)
- [Install](#install)
- [Quick start in a project](#quick-start-in-a-project)
- [The `.crew/` folder](#the-crew-folder)
- [Develop](#develop)
- [Evals](#evals)
- [Repository layout](#repository-layout)
- [Roadmap](#roadmap)
- [Conventions for new skills](#conventions-for-new-skills)
- [Troubleshooting](#troubleshooting)

## Why this exists

Workflow skills tend to grow inside one project: a session handoff here, a plan reviewer there, a cleanup
pass, an issue investigator. They get the project's stack rules baked in, so they cannot be reused, and
improvements made in one project never reach the others.

This repository pulls the process out into plugins that every project installs, and moves the
project-specific parts into each project's profile. It is deliberately not a large catalog. A skill earns
its place only when it encodes something Claude would not do by default: a gate, an artifact, a preference
or a protocol.

## How it is organized

```
┌─ Tier 3: automation (Claude Code only) ─────────────────────────────┐
│  hooks: open-items summary, employee protocol, status-file gate     │
├─ Tier 2: organization (Claude Code only) ───────────────────────────┤
│  work (organizer) · 5 employees · handoff                           │
├─ Tier 1: portable skills (Claude Code, Claude chat, Cursor*) ───────┤
│  file-issue · onboard · test-harden                                 │
└─────────────────────────────────────────────────────────────────────┘
   project layer (not in this repo): .crew/profile.md, CLAUDE.md, rules
```

- **Tier 1** skills are a plain `SKILL.md` with reference files. They need no hooks, subagents or work
  folder, so they also load in Claude chat (upload the plugin as a zip under Customize > Plugins).
  \*Cursor support is not verified yet.
- **Tier 2** uses Claude Code features: subagents, model selection, worktrees.
- **Tier 3** hooks only make things faster or more visible; nothing breaks without them.

## Plugins

| Plugin | Skills and agents | What it does |
|---|---|---|
| [`file-issue`](plugins/file-issue) | `file-issue` | Turns problems found outside the current task into complete follow-up issues in whatever tracker you use |
| [`triple-a-crew`](plugins/triple-a-crew) | `work`, `onboard`, `test-harden`, `handoff`; agents `researcher`, `engineer`, `test-engineer`, `verifier`, `reviewer` | The organizer and its employees, the project profile, and the workflow skills they use |

### file-issue

Captures a problem that is outside the current task as an issue someone can act on without the
conversation: in your tracker, without duplicates, and only with your OK.

**When it runs.** Claude uses it on its own when you or it notice a bug, risk, tech debt or missing piece
that will not be fixed in the current change ("not touching it in this PR", "out of scope", "later"). It
also runs when you ask to file, log or ticket something. It stays out of the way when the problem is the
task itself.

**What it does.**

1. **Decides whether the problem deserves an issue:** out of scope, real (backed by evidence), and not a
   two-line fix that belongs in the current change.
2. **Finds the tracker:** the project profile, then connected MCP tools, then `gh` / `glab`, then a local
   draft in `.crew/issues/`.
3. **Gathers context:** location (`path:line`), evidence, impact, and what was being worked on. Secrets
   and personal data are redacted.
4. **Checks for duplicates.** When an open issue already covers the problem, it offers to comment there
   instead.
5. **Drafts the issue from a template:** problem-not-fix title, context, problem, evidence, impact,
   suggested approach, acceptance criteria, links.
6. **Maps the tracker's fields** using only values that exist (teams, labels, issue types). It never
   invents them.
7. **Asks before creating**, even when you asked for the issue. With `confirm: batch` it asks once for a
   list. With `confirm: never` it creates directly.
8. **Creates the issue** and replies with the key and URL.

A security problem in a public repository never becomes a public issue. The skill points you to a private
route instead, such as a security advisory or a confidential issue.

**Trackers.** Each tracker has a reference file in
[`skills/file-issue/trackers/`](plugins/file-issue/skills/file-issue/trackers). Any other tracker works
through its tool schemas alone:

| Tracker | Detected through | Destination |
|---|---|---|
| Linear | MCP tools (`save_issue`, `list_issues`, ...) | team |
| GitHub Issues | MCP tools, or the `gh` CLI with a GitHub remote | `owner/repo` |
| Jira | Atlassian MCP tools | site + project key + issue type |
| GitLab | MCP tools, or the `glab` CLI with a GitLab remote | project path |
| Asana | MCP tools | project (issues are tasks) |
| ClickUp | MCP tools | list |
| Notion | MCP tools, only for an issues database you confirm | database |
| Others (Shortcut, Azure DevOps, YouTrack, monday, Trello, ...) | any MCP tool that creates issues | from the tool's schema |

Tracker tools are identified from their **descriptions** as well as their names, because connector
prefixes are often opaque IDs.

**Example.** You mention in passing that `listOrders` ignores `limit` and times out in prod, then ask a
question about pagination. Claude answers the question, then shows a Linear draft for team Core (ACT):
"Orders endpoint ignores the limit parameter", with labels Bug and follow-up and priority High. It notes
that a search found no duplicates and asks whether to create it.

### triple-a-crew: onboard

Writes `.crew/profile.md`, the contract the crew's skills read instead of guessing a project's setup.

- **Detects** the stack from manifests and lockfiles, and the verify commands from CI first, then task
  runners, cheapest first, without deploy or release steps. It also finds test globs, the files that hold
  conventions (`CLAUDE.md`, `AGENTS.md`, `.claude/rules/`, `.cursor/rules/`, ...), and issue tracker
  candidates from connected tools, the git remote and issue keys in branch names.
- **Asks** only what it cannot detect, at most four questions, each with a suggested answer.
- **Refreshes** on request: it re-detects facts but keeps what you set (tracker, organizer mode, model
  overrides, notes) and any keys it does not know.

Run it with `/triple-a-crew:onboard`, or just say "set this repo up for the crew". A real result from the
eval fixture repo:

```markdown
---
stack: [typescript, pnpm, react, vite, prisma, vitest, eslint]
verify:
  - pnpm lint
  - pnpm typecheck
  - pnpm test
tests: ["src/**/*.test.ts"]
conventions: [CLAUDE.md]
issue_tracker:
  tool: github
  team: acme/shop
  confirm: always
---
- `pnpm build` (Vite) exists but CI does not gate on it.
- `pnpm deploy` runs `fly deploy`. It needs Fly credentials, so the crew never runs it.
```

### triple-a-crew: work (the organizer)

Starts on its own for multi-step requests, or with `/triple-a-crew:work [start <request> | next | status]`.

1. **Sizes the request.**
   - **S** (one spot, no unknowns): it steps aside, and Claude just does the work.
   - **M** (several files, or one unknown): it opens a work item, does most of the work itself, and always
     staffs a reviewer.
   - **L** (several areas, unknowns, or risk, including a file format another system consumes): it opens a
     work item and staffs it fully.
2. **Opens a work item** in `.crew/work/<id>/`, with brief, plan, decisions, findings and board.
3. **Stress-tests before planning.** It lists edge cases (empty and huge inputs, concurrency, partial
   failure, time zones, migrations, backward compatibility) and marks each one in or out of scope.
4. **Plans tasks.** Each task has a file set, an acceptance check, a role and a model tier. For size L it
   checks every task against your convention files, records each rule that changes the plan (with its file)
   in `decisions.md`, maps every done-when line of the brief to a task or a recorded deferral, and asks for
   your go-ahead before any engineer starts.
5. **Staffs employees.** Model choice follows a rule table: `mechanical` work goes to haiku, `standard`
   to sonnet, `critical` to opus.
   - Parallel tasks run only on disjoint file sets.
   - A task escalates one tier after two misses.
   - Whoever writes a change never reviews it, and for size L a test-engineer adds the independent tests.
6. **Tracks progress through status files.** A blocked employee is resumed with the answer and keeps its
   context. You decide anything that is your call.
7. **Verifies and reviews.** It strips debug logs, commented-out code and log-and-rethrow try-catch from the
   lines it changed, runs your profile's verify commands (through the haiku verifier for bigger items), staffs
   a reviewer, and files the findings through `file-issue` in one batch. Crew feedback waits for the retro.
   When a review requests changes, a fresh reviewer rechecks the fix diff once before the item closes.
8. **Closes with a short retro** (sizes M and L): writes `retro.md`, marks problems an earlier item's retro
   already had, and proposes where each lesson should live (a profile note, a convention file, or crew
   feedback for this plugin's repository). It changes nothing until you accept.
9. **Answers status questions** ("where are we on X?") from the board, without starting more work.

A real plan from the eval fixture, for "make the orders CSV export production-ready":

| Task | Goal | Role | Tier |
|---|---|---|---|
| T1 | RFC 4180 field escaping for rows and header | engineer | standard |
| T2 | Streaming `exportOrdersCsv` + `since` filter | engineer | standard |
| T3 | Review T1+T2, focus on mobile compatibility | reviewer | critical |

Its brief listed 12 edge cases. Three of them went to findings as out of scope, among them CSV formula
injection and a `NaN` total.

### The employees

| Agent | Model | Does | Writes |
|---|---|---|---|
| `researcher` | sonnet | Maps code, docs and tickets with `path:line` evidence; for a bug, ranks the likely causes with a confidence and a way to confirm each | only its status file |
| `engineer` | sonnet | Implements one task inside its file set and runs the acceptance check | code in its file set |
| `test-engineer` | sonnet | Writes the tests for a task, never production code, with the `test-harden` rules preloaded; a test that exposes a bug stays failing and goes back to the code task; for risky work it shows each regression the brief lists failing on a broken copy outside the repository | tests in its file set |
| `verifier` | haiku | Runs the profile's verify commands, all of them even after a failure, and reports each exit code and the failing lines verbatim; never fixes | only its status file |
| `reviewer` | opus | Adversarial review of a diff: must-fix, should-fix and nit, each with a failure scenario, written to its status file as it goes | only its status file |

Every employee keeps a status file (`.crew/work/<id>/team/<task>-<role>.md`) and ends with the same report:
outcome, changed files, evidence, assumptions, open questions, findings. It takes the file's `updated` time
from the clock (`date -u`). Employees and the organizer run one plain command per Bash call, with no pipes,
`;`, `&&` or `cd`, so your permission rules match each command. Employees never spawn agents, never file
issues and never write under `.claude/`.

The researcher also answers design questions, staffed on opus, with options, trade-offs and a
recommendation ready for `decisions.md`. There is no separate architect. There is no scribe either: issues go
through `file-issue`, handoffs through the `handoff` skill, and PR text stays with the organizer.

### Hooks

The plugin ships three hooks that keep the organizer and its employees honest. They match only this plugin's
agents (`triple-a-crew:*`, or a [team-mode](#team-mode-experimental-opt-in) teammate named `T<n>-<role>`),
not built-in agents or other plugins' agents, and nothing breaks with hooks turned off. An unrelated
teammate that happens to have such a name gets the reminder, but no stop gate: its brief has no
`**Status file:**` line.

| Hook | Runs when | What it does |
|---|---|---|
| `SessionStart` | a session starts, resumes, clears or compacts | Lists the open work items from `.crew/work/index.md` at the project root (the git root, unless that is your home folder; otherwise the session's folder), at most 15. Prints nothing in projects without one |
| `SubagentStart` | an employee starts | Adds a short reminder of the status-file protocol to the employee's context |
| `SubagentStop` | an employee tries to finish | Sends it back while its status file is missing or not `done`, `blocked` or `failed`, or while a `done` or `failed` reply lacks a report section. It reads the status-file path from the first line of the brief that starts with `**Status file:**` (in the employee's transcript); if that path doesn't exist and doesn't end in `.md`, it stays silent. It sends the same employee back at most 3 times, and a finished employee answering a follow-up question needs no new report |

The scripts are POSIX `sh` and use `jq` when it is installed. Test them without a model call:

```bash
sh plugins/triple-a-crew/scripts/test-hooks.sh
```

### Team mode (experimental, opt-in)

Claude Code's [agent teams](https://code.claude.com/docs/en/agent-teams) let employees run as teammates:
they can message the organizer and each other while they work, and the organizer can steer a running
teammate, instead of each employee working alone until it stops. The organizer uses them only when you turn
the feature on, and only for size L work with parallel tasks or questions worth asking live. Everything else
stays in subagent mode, which is the default.

Turn it on for one project, not everywhere: a named Agent call becomes a teammate in every session that
has the variable, including sessions where you didn't ask for a team. In
`<project>/.claude/settings.local.json`:

```json
{ "env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" } }
```

What changes, from [`teams.md`](plugins/triple-a-crew/skills/work/teams.md):

- Teams need an interactive session. Under `-p`, the Agent SDK and evals, named calls fall back to
  subagents, and the same rules stay safe.
- Each teammate is named after its status file (`T2-engineer`); the hooks match that form, so the protocol
  reminder and the status-file gate still apply.
- Teammates share your working tree, with no worktrees. Writers run together only on files that don't
  build together (separate modules), no writer runs the verify commands, reviewers and the verifier start
  only after every writer is done, every teammate learns who else is running, and teammates never commit
  (the organizer commits only when you ask, as in subagent mode).
- A teammate with a question still sets `blocked`, then gets the answer by message.
- `maxTurns` doesn't stop a teammate, so each brief carries a turn budget and the organizer shuts down a
  teammate that overruns or loops. A teammate gets its agent's tools, model and instructions, but not its
  preloaded skills.
- `board.md` stays the only task list; the built-in team task list is not used. Teammates don't survive
  `/resume`: the organizer re-staffs unfinished tasks from the status files.
- **Cost:** each teammate is a full Claude Code session, so a team uses significantly more tokens than the
  same work done by subagents (the docs give no figure).

Team mode has no eval case, because evals can't start an interactive session. To check it by hand, turn it
on in a scratch repository, start `claude` there, and give the organizer a size-L request with two parallel
tasks. While that session is still open (the team config is deleted when it ends), check that:

- `~/.claude/teams/session-*/config.json` lists the teammates under their `T<n>-<role>` names;
- each crew teammate received the "Triple-A-Crew protocol" reminder at start;
- a teammate that tries to finish without its status file is sent back by the stop gate;
- `board.md` and every status file end complete, and no teammate committed.

### The workflow skills

These came from skills that lived in actioner-new with Actioner's stack rules built in. They now read each
project's rules from its profile and convention files instead.

| Skill | Use it for | Came from |
|---|---|---|
| `test-harden` | Find the risky missing test cases (cursor loops, DST, malformed data, retries, partial failure) and report or add them in the project's own framework | `test-robustness-review` skill + reviewer and filler agents |
| `handoff` | Write, resume or brief from a session handoff, with a facts appendix built from git and the transcript. Writes to `.crew/handoffs/` | `session-handoff` skill |

Three more were migrated and then cut, because plain Claude matched them in the evals: `plan-review` (from
`plan-reinforcer`), `cleanup` (from `post-plan-cleanup`) and `investigate` (from `investigate-linear-issue`).
What they added moved into the organizer and the `researcher`; see [Evals](#evals).

## Install

The repository is private for now, so git on your machine must be able to clone it. An SSH key or
`gh auth login` with git credentials set up is enough.

Add the marketplace:

```bash
claude plugin marketplace add meliksahozceyhan/triple-a-crew
```

Install the plugins:

```bash
claude plugin install triple-a-crew@triple-a-crew
```

```bash
claude plugin install file-issue@triple-a-crew
```

Inside a Claude Code session (2.1.275 or later), one command adds the marketplace and installs a plugin:

```
/plugin install triple-a-crew --marketplace meliksahozceyhan/triple-a-crew
```

The plugins do not depend on each other, so install both: the organizer uses `file-issue` for follow-ups
when it is there, and lists findings for you when it is not.

**Updating.** Auto-update is off by default for marketplaces that are not Anthropic's. The plugins set no
`version` while they are being iterated on, so every commit counts as a new version. Pull the latest with:

```bash
claude plugin marketplace update triple-a-crew
```

```bash
claude plugin update file-issue@triple-a-crew
```

A running session keeps the old version until you run `/reload-plugins`.

**From a local checkout** (edits apply after `/reload-plugins`, no update step needed):

```bash
claude plugin marketplace add ~/workspace/claude-skill-folder
```

## Quick start in a project

1. Install both plugins.
2. Open the project in Claude Code and say **"set this repo up for the crew"**. `onboard` writes
   `.crew/profile.md` and asks up to four questions, such as which tracker and team to use.
3. Commit `.crew/profile.md`.
4. Work as usual.
   - **Bigger work** ("add CSV export with streaming and tests"): the organizer opens a work item, plans it,
     and for size L waits for your go-ahead. Ask "where are we?" at any time.
   - **A problem outside the current task:** `file-issue` drafts a follow-up, checks for duplicates and asks
     before creating it.
   - **Single skills on request:** "harden these tests", "write a handoff".

To file issues in one list at the end of a task instead of one by one, set `confirm: batch` in the
profile.

## The `.crew/` folder

All crew state lives in `.crew/` at the project root:

```
.crew/
  profile.md                   the project contract                     committed
  issues/<date>-<slug>.md      file-issue drafts when no tracker exists  committed
  handoffs/                    session handoffs (ignore themselves)      ignored
  work/                        organizer work items
    <id>/brief.md, plan.md, decisions.md, findings.md, retro.md          committed
    <id>/board.md, team/, handoff.md, index.md                           ignored
```

**Why not `.claude/`?** Claude Code treats `.claude/` as a protected directory. Writes there prompt for
approval in default and accept-edits modes, are denied in don't-ask mode, and allow rules cannot pre-approve
them. An organizer and its employees write state constantly, so the crew uses a folder of its own.

**Profile fields** (full reference in
[profile-format.md](plugins/triple-a-crew/skills/onboard/profile-format.md)):

| Field | Set by | Used by |
|---|---|---|
| `stack` | detected | every skill, as context |
| `verify` | detected | the organizer's verify step |
| `tests` | detected | `test-harden`, engineer briefs |
| `conventions` | detected | the organizer's size-L plan check, `test-harden`, every employee brief |
| `issue_tracker` (`tool`, `team`, `labels`, `confirm`) | you, from detected candidates | `file-issue` |
| `organizer` (`proactive` / `manual`) | you | `work` |
| `models` (`mechanical`, `standard`, `critical`) | you | the organizer's staffing |

## Develop

Load the plugins in place for one session:

```bash
claude --plugin-dir ./plugins/file-issue --plugin-dir ./plugins/triple-a-crew
```

Run `/reload-plugins` after editing a skill. Validate the manifests before committing:

```bash
claude plugin validate .
```

The only expected warnings are the missing `version` fields, left out on purpose while iterating.

Test the hooks without a model call:

```bash
sh plugins/triple-a-crew/scripts/test-hooks.sh
```

Every eval `fixture.sh` refuses to run unless its folder is empty, because it writes files and runs git
there. To try one by hand, run it inside a fresh `mktemp -d` folder.

Do not add `dependencies` between the plugins. A plugin whose dependency is not installed does not load at
all, which breaks `--plugin-dir` and the eval sandbox. See [Troubleshooting](#troubleshooting).

## Evals

Each plugin has a suite under its `evals/` directory, run with `claude plugin eval`. Every run starts a fresh,
isolated, non-interactive Claude Code session with only that plugin loaded, sends a realistic prompt, and
grades what Claude did. Trigger cases also run without the plugin (the baseline), so the report shows what
the plugin adds (`Δ`).

Every run is a real model call on your account. A full run of both suites costs a few dollars at list price.

| Plugin | Command (from the plugin directory) | Cases |
|---|---|---|
| `file-issue` | `claude plugin eval . --tag trigger no-trigger --allow-tools Write` | 3 trigger, 3 no-trigger, with baseline |
| `file-issue` | `claude plugin eval . --tag mock-tracker --ablation none --scaffold` | 3 mocked-Linear cases, one arm |
| `triple-a-crew` | `claude plugin eval . --tag migrated onboard no-trigger --scaffold --allow-tools Write Edit "Bash(node *)" "Bash(git *)"` | 2 migrated-skill cases, 2 onboard, 3 no-trigger, with baseline |
| `triple-a-crew` | `claude plugin eval . --tag organizer --ablation none --scaffold --allow-tools Write Edit "Bash(node *)" "Bash(git *)" "Bash(date *)"` | 8 organizer cases, one arm |
| `triple-a-crew` | `claude plugin eval . --tag hooks --scaffold` | 1 hooks case, with baseline |

Add `--runs 1 --ablation none --case <name>` to iterate on one case cheaply. Add `--keep-temp` to keep each
run's sandbox, including `out/trace.jsonl` with every tool call.

**How the tracker cases work.** A case's `mocks/<server>/<tool>.md` files become a mocked MCP server named
`<server>`, whose tools are called `mcp__<server>__<tool>`. `_tools.json` carries Linear's real tool
schemas, so the skill has to read schemas the way it would against the real server. Mocks live in each
case, never in a suite-wide `evals/mocks/`: the harness would register those for every case, including the
ones that test the no-tracker path.

**What the suites check:**

- `file-issue`: fires on an out-of-scope bug mentioned in passing, in two differently worded cases, and
  saves a local draft in the working directory when no tracker exists; stays out of in-scope fixes,
  questions about trackers, and problems the user says are already tracked; with a mocked Linear, searches
  for duplicates and asks before creating; offers a comment instead of a duplicate; with `confirm: never`,
  creates in the profile's team with its label.
- `onboard`: on a pnpm + Vitest repo with GitHub CI, takes verify commands from CI (no build or deploy),
  finds the test glob and `CLAUDE.md`, reads the GitHub remote from `.git/config` without a shell; on
  refresh, updates stale values but keeps the tracker, organizer mode, unknown keys and notes.
- `work` (organizer), on a small Node fixture with an unquoted CSV export:
  - **Large request:** opens a work item (brief with edge cases, plan, board, index, `.gitignore`) and asks
    for the go-ahead before any engineer starts.
  - **Small request:** stays out.
  - **Read-only investigation** ("investigate ACT-512 before we fix anything", with a mocked Linear): stays
    out, creates no work item and edits nothing, but still reads the issue's comments.
  - **"Where are we?":** answers from the open item's board without starting work.
  - **Verify with the verifier** (`work next` on a size-L item at phase verify): strips only the debug log
    the work added, keeps the comments that were already there, staffs the verifier on haiku, and reports the
    failing database check with its exit code instead of calling verify passed.
  - **Test task with the test-engineer** (`work next` at phase implement): the test-engineer's line-break test
    fails because the code ignores CR and LF; it keeps the test failing, edits nothing under `src/`, and the
    defect goes back to the code task instead of becoming a follow-up issue.
  - **Medium fix, end to end:** fixes the quoting in both writers, runs the verify command, and staffs a
    reviewer on opus that writes its status file.
- Hooks: with one open item in `.crew/work/index.md`, Claude names it without using any tool, because the
  `SessionStart` hook put it in its context. The baseline cannot know.
- Migrated skills, one fixture each:
  - `test-harden` adds risky cursor cases in `node:test`, not another framework.
  - `handoff` writes and finalizes to `.crew/handoffs/`.

**Latest results:** 2026-10-16, Claude Code 2.1.295, default model. The organizer rows were rerun on
2026-10-19 (Claude Code 2.1.299) after the skill cut: one run per case, one arm, $1.69 for the suite.

| Plugin | Case | With plugin | Without | Δ | Runs (with) |
|---|---|---|---|---|---|
| `file-issue` | `implicit-out-of-scope-finding` | 1.00 | 0.00 | +1.00 | 4 |
| `file-issue` | `implicit-finding-in-side-note` | 1.00 | 0.00 | +1.00 | 4 |
| `file-issue` | `explicit-request-no-tracker` | 1.00 | 0.17 | +0.83 | 4 |
| `file-issue` | `no-fire-in-scope-fix` | 1.00 | 1.00 | 0.00 | 3 |
| `file-issue` | `no-fire-tracker-question` | 1.00 | 1.00 | 0.00 | 3 |
| `file-issue` | `no-fire-already-tracked` | 1.00 | 1.00 | 0.00 | 3 |
| `file-issue` | `linear-confirms-before-creating` | 1.00 | one arm | | 3 + 2 |
| `file-issue` | `linear-duplicate-offers-comment` | 1.00 | one arm | | 3 + 2 |
| `file-issue` | `profile-confirm-never-creates` | 1.00 | one arm | | 3 + 2 |
| `triple-a-crew` | `starts-work-item-on-large-request` | 1.00 | one arm | | 2 + 2 + 3 |
| `triple-a-crew` | `stays-out-of-small-request` | 1.00 | 1.00 | 0.00 | 4 + 2 |
| `triple-a-crew` | `stays-out-of-read-only-investigation` | 1.00 | not run | | 1 + 1 |
| `triple-a-crew` | `session-start-mentions-open-item` | 1.00 | 0.80 | +0.20 | 1 |
| `triple-a-crew` | `reports-status-of-open-item` | 1.00 | one arm | | 2 + 2 |
| `triple-a-crew` | `verify-staffs-verifier` | 1.00 | one arm | | 4 (0.86, 1.00, 0.88, 1.00) + 4 (0.92, 0.92, 0.92, 1.00) |
| `triple-a-crew` | `test-engineer-keeps-failing-test` | 1.00 | one arm | | 3 (1.00, 0.80, 1.00) + 2 (0.83, 1.00) |
| `triple-a-crew` | `medium-fix-end-to-end` | 1.00 | one arm | | 1 + 2 + 1 |
| `triple-a-crew` | `plans-against-project-conventions` | 1.00 | one arm | | 1 |
| `triple-a-crew` | `creates-profile-from-repo` | 1.00 | 0.00 | +1.00 | 2 |
| `triple-a-crew` | `refreshes-profile-keeps-user-values` | 1.00 | 1.00 | 0.00 | 2 |
| `triple-a-crew` | `no-fire-setup-question` | 1.00 | 1.00 | 0.00 | 2 |
| `triple-a-crew` | `writes-handoff-to-crew` | 0.97 | 0.25 | +0.72 | 6 |
| `triple-a-crew` | `test-harden-adds-edge-cases` | 1.00 | 0.83 | +0.17 | 3 |

How to read it:

- **No-trigger cases** score 1.00 in both arms by design: they check that the skill stays out of the way.
- **The open-issue fixes (2026-10-19)** added graders for the organizer's newer rules (one plain command per
  call, the organizer running a single verify itself, real timestamps, done-when coverage, regressions in
  risky test briefs, the convention check, the full noise rule). Two first runs missed for reasons the
  traces explained: the `test-engineer` judge varied once, and `verify-staffs-verifier`'s fixture planted
  unused, out-of-plan retry code that the organizer rightly deleted. The fixture now makes the retry part of
  the plan, and both cases scored 1.00.
- **Refresh** has Δ 0: without the plugin, Claude also updates an existing profile correctly. The case
  guards against regressions rather than showing what the plugin adds.
- **A standalone `retro` skill was built and cut** (2026-10-19). On a closed item whose time-zone bug
  appeared only in the git-ignored status files and in an earlier item's retro, plain Claude scored 1.00 like
  the skill: it globbed `.crew/**/*`, read the status files, flagged the repeat, and proposed edits before
  making any. (A first run showed +0.25, but only because two graders matched `profile.md` and `CLAUDE.md` in
  the text of `retro.md`; match `"file_path"` instead.) What remains is the organizer's close step, which
  writes the retro without being asked.
- **`plan-review`, `cleanup` and `investigate` were cut** (2026-10-16 results, cut on 2026-10-19). Their
  first cases gave plain Claude everything it needed (rules in `CLAUDE.md`, a scoped request, a pasted
  report) and scored Δ 0. Sharpened cases that targeted only what each skill claimed to add still showed
  plain Claude matching them on substance:
  - `plan-review` (0.75 in both arms, Δ 0.00): the baseline read `CONTRIBUTING.md` and two ADRs without
    being told to, caught all five rule breaks and cited each file. Only the skill's own output format was
    missing, and it appeared in full in just 1 of 4 runs with the plugin.
  - `cleanup` (1.00 in both arms, Δ 0.00): the baseline stayed in the changed file (Claude Code puts the git
    status in its system prompt), found `.crew/profile.md`, and ran both verify commands. One baseline run
    used Claude Code's built-in `simplify` skill.
  - `investigate` (1.00 vs 0.83, Δ +0.17): the baseline read the issue and its comments from the same
    mocked Linear, ranked the right path first, and caught a second bug. The whole gain was the report
    shape: a confidence and a way to confirm for each cause.

  What they added moved into the organizer: for size L it checks each task against the profile's
  `conventions` files and records every rule that changes the plan, with its file, in `decisions.md`; its
  verify step strips debug logs, commented-out code and log-and-rethrow try-catch from the lines it changed.
  The `researcher` agent now returns a bug's likely causes ranked, each with a confidence and a way to
  confirm. The organizer's description no longer claims read-only requests such as "investigate ACT-123" or
  "review this plan"; plain Claude handles those.
- **`test-harden` and `handoff`** first lost to the baseline or skipped steps: they didn't run the new
  tests, and skipped `finalize`. Both steps are now stated as required. The numbers shown are the runs
  after that fix, against the earlier baseline.
- **Organizer cases** run one arm, except the no-trigger cases `stays-out-of-small-request` and
  `stays-out-of-read-only-investigation`, where the baseline is meaningful.
  `medium-fix-end-to-end` counts its last run only: the first didn't start the organizer (a two-file fix
  reads as size S, so the case now starts it explicitly), and the second failed a grader that could never
  pass on a slash command.
- **The implicit trigger** scored 0.67 in the first full run. The traces showed three separate causes:
  the skill sometimes only offered to file; the draft went to the sandbox's home directory, a git
  repository, instead of the working directory; and the judge saw only the final message, where the answer
  was referenced but not repeated. The skill text and the graders now handle all three.
- The `file-issue` no-trigger cases ran with its current description. Changes made after them touch only
  the skill body, which loads once the skill has fired, so they cannot change whether it fires. The tracker
  cases were rerun twice after those changes.
- **The organizer's description changed on 2026-10-19** (read-only requests stay out). The rerun that day
  (the second and third numbers in "Runs"; the third ran with the hooks) scored 1.00 on all five organizer cases. In
  `stays-out-of-read-only-investigation` Claude read the issue's comments from the mocked Linear without
  starting the organizer, writing or editing anything. In `medium-fix-end-to-end` the fix kept the
  comments that were already in the file, as the noise rule now requires. The suite ran once more the same
  day with the hooks loaded: 5/5 at 1.00 ($1.53), so the stop hook let a reviewer that did its job finish.
- **`verify-staffs-verifier` and `test-engineer-keeps-failing-test`** (2026-10-19, latest runs 1.00). The first
  verifier run failed because the verifier wrapped commands in compound shell lines that permission rules don't
  match; it now runs each command alone. The 0.88 and 0.80 runs failed one judge each that read the whole run
  log (about 330 KB); those two judges now read only the final reply, which carries the facts they check.
- **`session-start-mentions-open-item`** scores 0.80 without the plugin only because its four "no tool used"
  graders pass in both arms. The grader that matters, naming the open item, passed with the hook and failed
  without it.

## Repository layout

```
.
├── .claude-plugin/marketplace.json     marketplace "triple-a-crew" listing both plugins
├── docs/DESIGN.md                      design, decisions and verified Claude Code mechanics
├── plugins/
│   ├── file-issue/
│   │   ├── .claude-plugin/plugin.json
│   │   ├── README.md
│   │   ├── skills/file-issue/
│   │   │   ├── SKILL.md                trigger, flow, rules
│   │   │   ├── template.md             issue body and local-draft format
│   │   │   └── trackers/               linear, github, jira, gitlab, asana, clickup, notion, generic
│   │   └── evals/                      9 cases; tracker cases carry mocks/linear/
│   └── triple-a-crew/
│       ├── .claude-plugin/plugin.json
│       ├── README.md
│       ├── agents/                     researcher, engineer, test-engineer, verifier, reviewer
│       ├── hooks/hooks.json            SessionStart, SubagentStart, SubagentStop
│       ├── scripts/                    the hook scripts (POSIX sh) and test-hooks.sh
│       ├── skills/
│       │   ├── work/                   the organizer: SKILL.md, formats, staffing, protocol
│       │   ├── onboard/                SKILL.md, profile-format.md (the profile contract)
│       │   ├── test-harden/            SKILL.md, examples.md
│       │   └── handoff/                SKILL.md, handoff.mjs (facts from git and the transcript)
│       └── evals/                      14 cases; each fixture.sh scaffolds a sample repo
└── README.md
```

## Roadmap

| Version | Scope |
|---|---|
| **v0** (done) | Marketplace, `file-issue` with tracker reference files and evals, `onboard` with the profile format and evals |
| **v1** (done) | The organizer (`work`): sizing, the `.crew/work/` folder, the status protocol, and three employees: researcher, engineer, reviewer. The actioner-new skills migrated as generic skills: `plan-review`, `cleanup`, `test-harden`, `investigate`, `handoff`. `plan-review`, `cleanup` and `investigate` were cut afterwards and folded into the organizer and the researcher (see [Evals](#evals)) |
| **v2** (done) | The hooks: open-items summary, protocol reminder, status-file gate (`crew-hooks`). `verifier` and `test-engineer`, with the architect folded into the researcher and no scribe (`employees-v2`). A short retro in the organizer's close step, after a standalone `retro` skill was cut for no gain (`retro-skill`) |
| **Next** (planned) | An opt-in agent-teams mode (`agent-teams-mode`, in progress) and a Cursor check (`cursor-check`), each with a live test you run. Each plan is in `.crew/work/<id>/plan.md`. Separately: move actioner-new onto the plugin |
| **Publish** (planned, `publish-v1`) | License, versions and git tags, an exposure audit, make the repository public, test the `file-issue` zip in Claude chat |

The organizer's model choice is a rule table: `mechanical` work goes to haiku, `standard` to sonnet,
`critical` to opus. It escalates one tier after two failed attempts, never lets an agent review its own work,
and runs work in parallel only on disjoint file sets. Details are in [docs/DESIGN.md](docs/DESIGN.md).

## Conventions for new skills

- **Earn the place.** A skill must encode something Claude would not do by default. "Write code" is not a
  skill; "not done until verify passes and the acceptance criteria are checked" is. Measure it against a
  baseline that is stronger than it looks. Plain Claude Code also loads `CLAUDE.md`, sees the git status in
  its system prompt, reads every file of a small fixture, uses the same mocked MCP servers, and has built-in
  skills such as `simplify`. A case shows what a skill adds only if the fixture holds back what plain Claude
  gets anyway. `plan-review`, `cleanup` and `investigate` failed this test and were cut; see the eval notes.
  Run the baseline arm on the case's fixture before building the skill: plain Claude's trace shows what is
  left to add. `retro` was built in full (four tasks, a review) before its baseline matched it.
- **Portable frontmatter.** Tier-1 skills use only `name` and `description`; other fields are Claude Code
  extensions that other hosts may ignore. Put the key use case first and keep the description under 1,024
  characters. If the skill should run without being asked, say so ("use proactively, without waiting to be
  asked") and give example phrases. The `file-issue` evals showed that a softer wording did not fire.
- **Short `SKILL.md`.** Aim for about 150 lines; move details into reference files that load on demand.
- **No state under `.claude/`.** Use `.crew/`.
- **Never invent values.** IDs, labels, team names and commands come from tools or files, or from the user.
- **Run every command example.** Models copy examples literally: a wrong `node --test <dir>` in `protocol.md`
  turned up in a verifier's brief.
- **Probe what the docs leave open.** When a skill depends on a Claude Code mechanic the docs don't settle,
  run a throwaway plugin on haiku in a scratch folder (it costs cents) and record the result with its date in
  DESIGN's Verified mechanics. `crew-hooks` (hook payloads) and `employees-v2` (`skills:` names) both did.
- **Ask before publishing.** Anything that writes to a shared system (issues, comments, messages) confirms
  first unless the profile says otherwise. Local files need no confirmation.
- **Spell out the exceptions to location rules.** "Use the git root" sent drafts to the home directory
  when the home directory itself was a git repository, which is true in the eval sandbox and for anyone who
  keeps dotfiles in git.
- **Ship evals with the skill:** at least one case that should trigger it, one that should not, a near miss
  for each trigger phrase you add, and one case per key rule. Keep mocks per case. When the answer to the
  user's question may come before the skill runs, judge the whole transcript (`focus: trace`), not only the
  last message. But a trace judge sees only the first and last 12 messages of a run, so a fact in the middle
  of a long run goes unseen: judge the final reply when it carries the facts, or use a `regex` grader with
  `target: trace`, which sees every message. A fixture's planted change must agree with its own work item: in
  the plan, used, and correct. Otherwise the organizer rightly changes it, and the case fails for the wrong
  reason (`verify-staffs-verifier` once planted an unused retry the organizer deleted).
- **Graders match what you mean.** A `tool_used` grader's `input_match` is matched against the whole tool
  input, file content included, so a "never writes `profile.md`" check also fails on a write to another file
  that mentions `profile.md`. Anchor a path check on the path: `'"file_path"\s*:\s*"[^"]*profile\.md"'`.
  No grader option limits a check to the main agent; a `regex` grader on the trace can, because main-agent
  rows carry `"parent_tool_use_id":null` and subagent rows carry a tool-use id there. `file_exists` sees only
  files created during the run. Test a regex grader on rows from a real trace, not only on rows you built:
  Edit inputs start with `"replace_all"`, not `"file_path"`.

## Troubleshooting

| Symptom | Cause and fix |
|---|---|
| Plugin does not load; `plugin_errors` shows `dependency-unsatisfied` | A declared dependency is not installed. Remove `dependencies`, or install the dependency first |
| Permission prompt on every write under `.claude/` | `.claude/` is protected in Claude Code. Write crew state to `.crew/` |
| Eval stops after about a second with `partialReason: auth_failed` and $0 cost | The standalone `claude` CLI is not logged in (`claude auth status` shows `loggedIn: false`). A Claude desktop-app session authenticates through the app, not the CLI, so evals started from it fail. Run them from a terminal after `claude auth login` |
| An employee keeps being told to fix its status file | The `SubagentStop` hook found the status file named in its brief, and the file is missing, not final, or the reply lacks a report section. The reason it gives says what to fix. The hook gives up after 3 tries for the same employee |
| No open-items summary at session start | The `SessionStart` hook reads `.crew/work/index.md` at the git root (or the session's folder outside a repository, or when the git root is your home folder) and prints only the `## Open` list. Check that the file exists and has items under `## Open`, then run `sh plugins/triple-a-crew/scripts/test-hooks.sh` |
| Eval: `a plugins entry names the case directory ... or a directory covering them` | Do not list the plugin under test in a case's `plugins:`. Fixture plugins must sit inside the case directory |
| Eval: `outside the containment root` | A case can only load plugins inside the plugin under test, so a sibling plugin cannot be loaded |
| Eval: tracker tools show up in a no-tracker case | Suite-wide `evals/mocks/` applies to every case. Move the mocks into the cases that need them |
| Eval: `Permission to use Write has been denied ... don't ask mode` | Eval runs use don't-ask mode. Grant the tool with `--allow-tools`, and never write under `.claude/` |
| Eval refused: `not a trusted plugin directory` | Run once in a terminal and answer the prompt, or pass `--trust-plugin` for your own plugin |
| Eval: a file lands one level above the working directory and the write is denied | The sandbox's home directory is a git repository with the working directory inside it, so "the git root" is the home directory. Skills must not treat a home-directory git root as the project root |
| Eval: an `llm` grader fails although the answer was given | The default focus is the final message only. Use `focus: trace` when the answer can come earlier in the run, but that judge sees only the first and last 12 messages; for a fact in the middle of a long run, use a `regex` grader with `target: trace` |
| A script fails with `EPERM` reading `~/.claude/projects/...` | The Bash sandbox (on in eval runs, optional in normal sessions) blocks reading Claude Code's config directory. `handoff.mjs` now falls back to git-only facts |
| Eval: "skill fired" fails although the skill clearly ran | The prompt used a slash command, which loads the skill without a `Skill` tool call. Grade the outcome instead |
| Eval: `results directory ... already existed` | Two runs started in the same second. Give each one its own `--output-dir` |
| `--tag` or `--allow-tools` swallow the target | They take lists. Put the target first: `claude plugin eval . --tag a b` |
| Eval: `git` fails with `xcrun_db ... Operation not permitted` and `xcode-select: Failed` | On macOS the eval sandbox blocks the cache file Apple's git shim writes, so every `git` command fails. Claude still gets the git status snapshot in its system prompt. Don't make a case depend on `git diff` output |
| Eval: a `tool_used: Bash` grader passes but the command never ran | `tool_used` counts attempts, including calls denied in don't-ask mode. A compound command such as `node --test; echo $?` does not match `Bash(node *)` and is denied. Check the trace (`--keep-temp`) when it matters |

## License

Private for now. A license will be chosen before the repository is made public.
