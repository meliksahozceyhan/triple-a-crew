---
name: onboard
description: Create or refresh a project's Triple-A-Crew profile, `.crew/profile.md`, by inspecting the repository - the stack, the commands that verify a change, where tests live, which files hold conventions, and the issue tracker. Use when the user asks to onboard a project, set a repository up for the crew, or create, update or refresh the project profile, and when another skill needs the profile and the project has none. Asks only what it cannot detect.
---

# Onboard

The profile is the contract between a project and the crew's skills: they read it instead of guessing the
stack. Write facts you can point to, ask only for what you cannot find, and keep it short. It points to
convention files; it never copies them.

The format, field by field, is in [profile-format.md](profile-format.md).

## 1. Find the project and any existing profile

- **Project root:** the git repository root (`git rev-parse --show-toplevel`), otherwise the current working
  directory. Never your home directory.
- If `<root>/.crew/profile.md` exists you are **refreshing** (step 5). Otherwise you are **creating** (step 4).

## 2. Detect

Read files; do not guess. Note where each value came from, because you will show it to the user.

**Stack.** Manifests and lockfiles at the root, and one level down in a monorepo:

| Signal | Means |
|---|---|
| `package.json` with `pnpm-lock.yaml`, `yarn.lock`, `package-lock.json` or `bun.lock(b)` | Node, and the package manager |
| `pnpm-workspace.yaml`, `turbo.json`, `nx.json`, `lerna.json` | JavaScript monorepo tool |
| `pyproject.toml`, `uv.lock`, `poetry.lock`, `requirements*.txt` | Python, and uv / poetry / pip |
| `go.mod`, `go.work` | Go |
| `Cargo.toml` | Rust |
| `pom.xml`, `build.gradle(.kts)` | Java or Kotlin, with Maven or Gradle |
| `Gemfile`, `composer.json`, `*.csproj` / `*.sln`, `mix.exs`, `Package.swift`, `pubspec.yaml` | Ruby, PHP, .NET, Elixir, Swift, Dart |

From the dependencies, add only what changes how work is done: framework, ORM, test runner. Five to eight
entries, not the dependency list.

**Verify commands**, the commands that prove a change is good, from the most trusted source:

1. **CI config:** `.github/workflows/*.yml`, `.gitlab-ci.yml`, `.circleci/config.yml`, `azure-pipelines.yml`,
   `bitbucket-pipelines.yml`. What CI runs on pull requests defines "passing".
2. **Task runners:** `package.json` scripts, `Makefile`, `justfile`, `Taskfile.yml`, `tox.ini`, `noxfile.py`.

List them cheapest first: format check, lint, typecheck, test, and build only if CI gates on it. Write each the
way a person runs it locally from the root (`pnpm lint`, not CI's install-and-cache wrapper). Leave out deploy,
release and anything that needs secrets or live services; mention those in the notes. Do not run the commands
while onboarding unless the user asks: some are slow or need services.

**Tests.** Globs for test files, from the test runner's config (`vitest.config.*`, `jest.config.*`,
`[tool.pytest.ini_options]`, `pytest.ini`) or the language convention (`*_test.go`). Check them against real
files with a glob search.

**Conventions.** Paths, not contents, of files that hold rules for working here. Only those that exist:
`CLAUDE.md` (root and nested), `AGENTS.md`, `.claude/rules/`, `.cursor/rules/`, `.cursorrules`,
`.github/copilot-instructions.md`, `CONTRIBUTING.md`, ADR folders such as `docs/adr/` or `docs/decisions/`.

**Issue tracker.**

1. **Connected tools** that create issues: Linear, GitHub, Jira, GitLab and others. Identify them from tool
   descriptions as well as names.
2. **Git remote:** `git remote get-url origin`, or read `.git/config` if you cannot run commands. GitHub gives
   `tool: github` with `team: owner/repo`; GitLab gives `tool: gitlab` with the project path.
3. **Hints:** issue keys such as `SHOP-123` in branch names or recent commit messages (`git branch -a`,
   `git log --oneline -50`) point to Linear or Jira with that key as the team or project. `.github/ISSUE_TEMPLATE/`
   points to GitHub Issues. Pull request templates often name the tracker.

Several candidates, or only hints: that is a question for step 3. Use `confirm: always` unless the user picks
another level.

**Notes.** A few bullets, only for what the files above do not say: the top-level layout of a monorepo
(`apps/*`, `packages/*`), services the tests need (a database, Redis), generated code that must not be edited
by hand. Never read `.env` files, and never copy secrets, tokens or environment values.

## 3. Ask only what you could not detect

One message, at most four questions, each with your best guess so the user can just confirm. Typical ones:
which tracker and team, when that is unclear; which commands count, when CI and local scripts disagree; the
confirmation level for filing issues. Never ask about something you found.

## 4. Create

Write `<root>/.crew/profile.md` right away with what you detected. It is a local file and easy to change.
Then ask the step 3 questions and update the file with the answers.

If nobody can answer now (you are a subagent, or the session is non-interactive), leave unknown fields out
and list the questions under an `## Open questions` heading in the notes.

Create only the profile: no `.crew/.gitignore` or other files. The profile is meant to be committed.

## 5. Refresh

- Re-detect `stack`, `verify`, `tests` and `conventions`, and update them where the repository has changed.
- Keep what the user owns unless they ask to change it: `issue_tracker`, `organizer`, `models`, and the notes.
- Keep keys you do not recognize exactly as they are.
- Edit the file in place; never rewrite it from scratch.

## 6. Report

Show the profile (when refreshing, only what changed) with each detected value and, in a few words, where it
came from. List any open questions. Suggest committing `.crew/profile.md`.
