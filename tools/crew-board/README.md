# crew-board

A small local server that shows what the crew is doing: the open work items, each employee with its todo
list, its state and its latest tool calls. It reads the files the crew already writes under `.crew/work/`.
Node standard library only, no install step. It needs Node 18 or newer (developed on Node 22).

## Run

```
node tools/crew-board/server.mjs [--root <dir>] [--port <n>] [--demo] [--no-live]
```

It prints one line, `crew-board: http://127.0.0.1:4777 (project <name>)`; open that address in a browser.
Stop it with Ctrl-C.

| Flag | Meaning |
|---|---|
| `--root <dir>` | The project folder. Default: the nearest folder at or above the current one with `.crew/work/index.md`. With none, the server still starts and reports empty lists. |
| `--port <n>` | Port, default 4777. If it is in use, the server prints one line naming `--port` on stderr and exits with code 1. |
| `--demo` | Ignores the project and serves a throwaway project in the system temp folder whose files change on a timer (a cycle of about a minute: boxes get ticked, one employee is blocked with a question, one misses and is re-staffed as `T2b`, one finishes). The folder is removed when the server stops (Ctrl-C, SIGTERM or SIGHUP); a hard kill (SIGKILL) leaves `crew-board-demo-*` in the temp folder. |
| `--no-live` | Never creates or removes anything in the project (see "What it writes"). |

The server listens on `127.0.0.1` only, but there is no login: any process or user on the same machine can
read `/api/state` (progress text, questions and the targets of tool calls). Without `--no-live`, running it on
a folder (the test fixtures included) creates and removes `live/` content there as described below. Routes: `GET /` (the page, `index.html` next to the script),
`GET /api/state`. Everything else answers 404, any method but `GET` answers 405, and a `Host` header that is
not `127.0.0.1:<port>` or `localhost:<port>` answers 403. No request path is ever mapped to a file. Every
answer carries `Cache-Control: no-store` and `X-Content-Type-Options: nosniff`; the page also carries a
Content-Security-Policy that allows the page's inline script only by its `sha256-` hash (computed when the
page is served) and sets `frame-ancestors`, `base-uri` and `form-action` to `'none'`.

Open `http://127.0.0.1:<port>/?gallery` to see every character in every mood (working, busy, quiet,
blocked, done, missed, waiting). The gallery is built in the page and asks the server for nothing.

A character is "working" for 20 seconds after its last tool call started. The log records when a call
starts, never when it ends, so after that the page says "busy" and shows the last call and when it started:
it cannot tell a long-running command from thinking. After 3 minutes without a call or a status update it
says "quiet".

## What it reads

Fresh on every request, nothing cached:

- `.crew/work/index.md`: the `## Open` and `## Closed` lists.
- `.crew/work/<id>/board.md` of each open item: phase, updated, next and the table, read by column name (an
  older board without `Effort` gives `effort: ""`).
- `.crew/work/<id>/team/<task>-<role>.md`: the status files named by the board, or the default name when the
  cell is empty (frontmatter `state` and `updated`, the lists under `## Progress`, the text under
  `## Questions`).
- `.crew/work/<id>/live/<name>.log`: one line per tool call, `<UTC time> TAB <tool> TAB <target>`, appended by
  the plugin's hook. A last line without a newline (still being written) and lines of any other form are
  skipped. Only the last 8 MB of a log are read.

Only regular files are read: a status file, log or board that is a symbolic link, a FIFO or a folder is
skipped (`status: null`, `live: null`). Each line is cut to 4000 characters before it is parsed.

Closed items are listed by name from the index only; their folders are not read. A file that cannot be read
or parsed is skipped; the server never stops on one.

## What it writes and removes

Unless `--no-live` is given, at start and on each state read:

- For each open item whose folder exists: creates `.crew/work/<id>/live/` and `live/.gitignore` containing
  `*`, when they are missing.
- For each item listed under `## Closed` (and not also under `## Open`) that still has a `live/` folder:
  deletes the `*.log` files; deletes the `.gitignore` only when the folder is empty without it, and then
  removes the folder. A `live/` that holds another file keeps that file and its `.gitignore`. An id that is
  in no list is never touched (an index read while half written must not wipe every item's logs).

It touches only a real folder named `live` directly inside `.crew/work/<id>/` (a symlink or a file of that
name is left alone), and never deletes any other file.

## `GET /api/state`

```json
{
  "project": "my-project",
  "now": "2026-11-16T14:05:33Z",
  "open": [
    {
      "id": "csv-export", "size": "L", "summary": "implement - T3 engineer running",
      "phase": "implement", "updated": "2026-10-16T14:05:00Z", "next": "wait for T2b, then staff T3",
      "tasks": [
        {
          "task": "T2",
          "attempts": [
            {
              "id": "T2b", "role": "engineer", "model": "sonnet", "effort": "high",
              "boardState": "in-progress",
              "status": {
                "state": "in-progress", "updated": "2026-10-16T14:05:00Z",
                "progress": [{ "done": true, "text": "Cursor query" }, { "done": false, "text": "Test with 200k rows" }],
                "questions": ""
              },
              "live": {
                "calls": 23,
                "last": [{ "at": "2026-11-16T14:05:12Z", "tool": "Edit", "target": "src/db/orders.js" }]
              }
            }
          ]
        }
      ]
    }
  ],
  "closed": [{ "id": "orders-limit", "size": "M", "note": "done 2026-10-12" }]
}
```

- `project` is the folder's name only. `now` is the server's UTC time.
- Rows whose id is `T<n>` plus an optional letter (`T2`, `T2b`) are grouped under one `task`; any other id is
  its own task. `attempts` are in board order.
- `phase`, `updated` and `next` are `""` when missing; an open item without a folder or board has
  `tasks: []`. Dates are passed through as text.
- `status` is `null` when the row names no status file and `team/<id>-<role>.md` does not exist, or when the
  file cannot be read. `done` in `progress` is `true`, `false`, or `null` for a plain bullet. `questions` is
  `""` when empty or "None".
- `live` is `null` when there is no log file; `last` holds at most the 8 newest lines, oldest first.
- Limits: 50 open items and 200 board rows per item (the rest are left out), 50 progress items per attempt, 300 characters per progress text, 2000 of questions, 200 per log
  target. Text is passed through as is, HTML included: show it as text.

## Tests

```
node tools/crew-board/test.mjs
```

Prints one line per check and ends with `all crew-board tests passed`; exits 1 otherwise. The fixtures are in
`tools/crew-board/fixtures/`; tests that change files work on a temporary copy.
