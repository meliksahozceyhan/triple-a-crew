# Triple-A-Crew

Workflow plugins for Claude Code, kept in one repository and installed into every project.

The plugins hold **process**: how work moves from a problem to a shipped change. Each project keeps its own
**knowledge**: its stack, conventions and commands, in a small profile at `.crew/profile.md`. The long-term
goal is an organizer that runs work like a team lead: it understands the problem, staffs subagents
("employees") on the right models, tracks their state, answers their questions, and files follow-up issues
for anything out of scope.

> **Status: v0, private.** Two plugins ship today: `file-issue` and `triple-a-crew` (with the `onboard`
> skill). The organizer arrives in v1. The full design is in [docs/DESIGN.md](docs/DESIGN.md).

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
│  hooks: session-start summary, subagent status checks        (v2)   │
├─ Tier 2: organization (Claude Code only) ───────────────────────────┤
│  organizer skill · employee agents · .crew/work/ state       (v1)   │
├─ Tier 1: portable skills (Claude Code, Claude chat, Cursor*) ───────┤
│  file-issue · onboard                                         (v0)   │
└─────────────────────────────────────────────────────────────────────┘
   project layer (not in this repo): .crew/profile.md, CLAUDE.md, rules
```

- **Tier 1** skills are a plain `SKILL.md` with reference files. They need no hooks, subagents or work
  folder, so they also load in Claude chat (upload the plugin as a zip under Customize > Plugins).
  \*Cursor support is not verified yet.
- **Tier 2** uses Claude Code features: subagents, model selection, worktrees.
- **Tier 3** hooks only make things faster or more visible; nothing breaks without them.

## Plugins

| Plugin | Skills | What it does | Status |
|---|---|---|---|
| [`file-issue`](plugins/file-issue) | `file-issue` | Turns problems found outside the current task into complete follow-up issues in whatever tracker you use | v0 |
| [`triple-a-crew`](plugins/triple-a-crew) | `onboard` | Writes and refreshes the project profile, `.crew/profile.md`. The organizer joins this plugin in v1 | v0 |

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

Inside a Claude Code session, the same works with `/plugin marketplace add meliksahozceyhan/triple-a-crew`
and `/plugin install file-issue@triple-a-crew`.

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
4. Work as usual. When a problem outside the current task shows up, `file-issue` drafts a follow-up, checks
   for duplicates and asks before creating it.

To file issues in one list at the end of a task instead of one by one, set `confirm: batch` in the
profile.

## The `.crew/` folder

All crew state lives in `.crew/` at the project root:

```
.crew/
  profile.md                   the project contract                     committed
  issues/<date>-<slug>.md      file-issue drafts when no tracker exists  committed
  work/                        organizer work items (v1)
    <id>/brief.md, plan.md, decisions.md, findings.md                    committed
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
| `verify` | detected | the verifier and the verify phase (v1) |
| `tests` | detected | the test engineer (v1) |
| `conventions` | detected | plan review and every employee brief (v1) |
| `issue_tracker` (`tool`, `team`, `labels`, `confirm`) | you, from detected candidates | `file-issue` |
| `organizer` (`proactive` / `manual`) | you | the organizer (v1) |
| `models` (`mechanical`, `standard`, `critical`) | you | the organizer's staffing (v1) |

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
| `file-issue` | `claude plugin eval . --tag trigger no-trigger --allow-tools Write` | 2 trigger, 2 no-trigger, with baseline |
| `file-issue` | `claude plugin eval . --tag mock-tracker --ablation none --scaffold` | 3 mocked-Linear cases, one arm |
| `triple-a-crew` | `claude plugin eval . --scaffold --allow-tools Write Edit` | 2 onboard cases on a fixture repo, 1 no-trigger |

Add `--runs 1 --ablation none --case <name>` to iterate on one case cheaply. Add `--keep-temp` to keep each
run's sandbox, including `out/trace.jsonl` with every tool call.

**How the tracker cases work.** A case's `mocks/<server>/<tool>.md` files become a mocked MCP server named
`<server>`, whose tools are called `mcp__<server>__<tool>`. `_tools.json` carries Linear's real tool
schemas, so the skill has to read schemas the way it would against the real server. Mocks live in each
case, never in a suite-wide `evals/mocks/`: the harness would register those for every case, including the
ones that test the no-tracker path.

**What the suites check:**

- `file-issue`: fires on an out-of-scope bug mentioned in passing and saves a local draft when no tracker
  exists; stays out of in-scope fixes and questions about trackers; with a mocked Linear, searches for
  duplicates and asks before creating; offers a comment instead of a duplicate; with `confirm: never`,
  creates in the profile's team with its label.
- `onboard`: on a pnpm + Vitest repo with GitHub CI, takes verify commands from CI (no build or deploy),
  finds the test glob and `CLAUDE.md`, reads the GitHub remote from `.git/config` without a shell; on
  refresh, updates stale values but keeps the tracker, organizer mode, unknown keys and notes.

<!-- EVAL-RESULTS -->

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
│   │   └── evals/                      7 cases; tracker cases carry mocks/linear/
│   └── triple-a-crew/
│       ├── .claude-plugin/plugin.json
│       ├── README.md
│       ├── skills/onboard/
│       │   ├── SKILL.md
│       │   └── profile-format.md       the profile contract
│       └── evals/                      3 cases; fixture.sh scaffolds a sample repo
└── README.md
```

## Roadmap

| Version | Scope |
|---|---|
| **v0** (now) | Marketplace, `file-issue` with tracker reference files and evals, `onboard` with the profile format and evals |
| **v1** | The organizer: proactive start with sizing (small requests are left alone), the `.crew/work/` folder, the status protocol, and three employees: researcher, engineer, reviewer. Evals for the trigger |
| **v2** | Remaining employees (architect, test engineer, verifier, scribe), `plan-review`, `cleanup`, `test-harden`, `handoff`, `retro`, hooks, agent-teams mode, a Cursor check |
| **Publish** | License, versions and git tags, make the repository public, test the plugin zip in Claude chat |

The organizer's model choice is a rule table: `mechanical` work goes to haiku, `standard` to sonnet,
`critical` to opus. It escalates one tier after two failed attempts, never lets an agent review its own work,
and runs work in parallel only on disjoint file sets. Details are in [docs/DESIGN.md](docs/DESIGN.md).

## Conventions for new skills

- **Earn the place.** A skill must encode something Claude would not do by default. "Write code" is not a
  skill; "not done until verify passes and the acceptance criteria are checked" is.
- **Portable frontmatter.** Tier-1 skills use only `name` and `description`; other fields are Claude Code
  extensions that other hosts may ignore. Put the key use case first and keep the description under 1,024
  characters. If the skill should run without being asked, say so ("use proactively, without waiting to be
  asked") and give example phrases. The `file-issue` evals showed that a softer wording did not fire.
- **Short `SKILL.md`.** Aim for about 150 lines; move details into reference files that load on demand.
- **No state under `.claude/`.** Use `.crew/`.
- **Never invent values.** IDs, labels, team names and commands come from tools or files, or from the user.
- **Ask before publishing.** Anything that writes to a shared system (issues, comments, messages) confirms
  first unless the profile says otherwise. Local files need no confirmation.
- **Ship evals with the skill:** at least one case that should trigger it, one that should not, and one per
  key rule. Keep mocks per case.

## Troubleshooting

| Symptom | Cause and fix |
|---|---|
| Plugin does not load; `plugin_errors` shows `dependency-unsatisfied` | A declared dependency is not installed. Remove `dependencies`, or install the dependency first |
| Permission prompt on every write under `.claude/` | `.claude/` is protected in Claude Code. Write crew state to `.crew/` |
| Eval: `a plugins entry names the case directory ... or a directory covering them` | Do not list the plugin under test in a case's `plugins:`. Fixture plugins must sit inside the case directory |
| Eval: `outside the containment root` | A case can only load plugins inside the plugin under test, so a sibling plugin cannot be loaded |
| Eval: tracker tools show up in a no-tracker case | Suite-wide `evals/mocks/` applies to every case. Move the mocks into the cases that need them |
| Eval: `Permission to use Write has been denied ... don't ask mode` | Eval runs use don't-ask mode. Grant the tool with `--allow-tools`, and never write under `.claude/` |
| Eval refused: `not a trusted plugin directory` | Run once in a terminal and answer the prompt, or pass `--trust-plugin` for your own plugin |
| Eval: `results directory ... already existed` | Two runs started in the same second. Give each one its own `--output-dir` |
| `--tag` or `--allow-tools` swallow the target | They take lists. Put the target first: `claude plugin eval . --tag a b` |

## License

Private for now. A license will be chosen before the repository is made public.
