# Security

These plugins run inside Claude Code with the permissions of the session that loads them. They read and write
files under the project's `.crew/` folder, run the shell commands their skills describe, and, through
`file-issue`, create issues in a tracker you have connected. They store no credentials of their own.

## Reporting a vulnerability

Please do not open a public issue for a security problem. Use GitHub's private vulnerability reporting on
this repository instead: **Security → Report a vulnerability**. You will get a reply within a week. Fixes
ship as a new plugin version and a tagged release (`<plugin>--v<version>`), so updating with
`claude plugin marketplace update triple-a-crew` and `claude plugin update <plugin>@triple-a-crew` picks them up.

## Scope

In scope: anything in `plugins/` that could make a skill or agent act outside what its text says, leak data
from the project it runs in, or write outside `.crew/` and the files a task names. Out of scope: the behaviour
of Claude Code itself and of the trackers the plugins talk to.
