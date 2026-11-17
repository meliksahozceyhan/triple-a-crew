#!/usr/bin/env node
// Tests of the crew board, with no framework: node tools/crew-board/test.mjs
// One line per check; exits 1 on any failure; the last line says whether all passed.

import assert from "node:assert/strict";
import { execFileSync, spawn } from "node:child_process";
import fs from "node:fs";
import http from "node:http";
import net from "node:net";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { LIMITS, parseBoard, parseIndex, parseLive, parseStatus, taskOf } from "./parse.mjs";
import { createHash } from "node:crypto";
import { findRoot, manageLive, pageCsp, readState, startServer } from "./server.mjs";
import { startDemo } from "./demo.mjs";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const SERVER = path.join(HERE, "server.mjs");
const FIXTURE = path.join(HERE, "fixtures", "project");
const read = (...p) => fs.readFileSync(path.join(FIXTURE, ".crew", "work", ...p), "utf8");

let failed = 0;
async function check(name, fn) {
  try {
    await fn();
    console.log(`ok   ${name}`);
  } catch (err) {
    failed++;
    console.log(`FAIL ${name}: ${String(err.message).split("\n")[0]}`);
  }
}

const temps = [];
function tmp(prefix = "crew-board-test-") {
  const d = fs.mkdtempSync(path.join(os.tmpdir(), prefix));
  temps.push(d);
  return d;
}

// A throwaway copy of the fixture project, so tests may change it.
function copyFixture() {
  const root = path.join(tmp(), "proj-fixture");
  fs.cpSync(FIXTURE, root, { recursive: true });
  return root;
}

function request(port, urlPath, { method = "GET", headers = {} } = {}) {
  return new Promise((resolve, reject) => {
    const req = http.request({ host: "127.0.0.1", port, path: urlPath, method, headers }, (res) => {
      let body = "";
      res.setEncoding("utf8");
      res.on("data", (c) => (body += c));
      res.on("end", () => resolve({ status: res.statusCode, headers: res.headers, body }));
    });
    req.on("error", reject);
    req.end();
  });
}

const getState = async (port) => JSON.parse((await request(port, "/api/state")).body);
const exists = (p) => fs.existsSync(p);

// ================================================================ parsers

await check("index: open and closed lists, free text ignored", () => {
  const { open, closed } = parseIndex(read("index.md"));
  assert.deepEqual(open.map((i) => i.id), ["orders", "legacy", "ghost"]);
  assert.deepEqual(open[0], { id: "orders", size: "L", summary: "implement - T2b engineer running" });
  assert.equal(open[1].summary, "approved, paused by the user on 2026-10-27 - next: the manual test (T2)");
  assert.deepEqual(closed[0], { id: "shipped", size: "M", note: "done 2026-10-12 (PR #4; retro done)" });
  assert.equal(closed.length, 2);
});

await check("index: empty and strange text give empty lists", () => {
  for (const t of ["", "# Work items\n", "## Open\n\n## Closed\n", "no headings\n- `x` (S) - y", null, undefined]) {
    assert.deepEqual(parseIndex(t), { open: [], closed: [] });
  }
});

await check("board: current format, columns by header name", () => {
  const b = parseBoard(read("orders", "board.md"));
  assert.equal(b.phase, "implement");
  assert.equal(b.updated, "2026-11-16T14:05:00Z");
  assert.equal(b.next, "wait for T2b, then staff T3.");
  assert.equal(b.rows.length, 5);
  assert.deepEqual(b.rows[2], {
    id: "T2b", role: "engineer", model: "sonnet", effort: "high", boardState: "in-progress",
    statusFile: "team/T2b-engineer.md",
  });
  assert.equal(b.rows[4].statusFile, "");
});

await check("board: older layout without Effort, Branch field, free paragraph", () => {
  const b = parseBoard(read("legacy", "board.md"));
  assert.equal(b.phase, "done");
  assert.equal(b.updated, "2026-10-19");
  assert.equal(b.rows.length, 4);
  assert.equal(b.rows[0].effort, "");
  assert.equal(b.rows[0].model, "sonnet");
  assert.equal(b.rows[1].statusFile, "team/T3-T4-engineer.md");
});

await check("board: missing fields are empty strings", () => {
  assert.deepEqual(parseBoard("# Board: x\n"), { phase: "", updated: "", next: "", rows: [] });
});

await check("board: half written files never throw", () => {
  const whole = read("orders", "board.md");
  for (let n = 0; n <= whole.length; n += 7) parseBoard(whole.slice(0, n));
  assert.equal(parseBoard("| Task | Ro").rows.length, 0);
  assert.equal(parseBoard("| Task | Role |\n|---|---|\n| T1 | engi").rows[0].role, "engi");
});

await check("task grouping: T2, T2b, T2c share a task", () => {
  assert.deepEqual(["T2", "T2b", "T2c", "T10", "T10b", "deploy", "T2bb"].map(taskOf), [
    "T2", "T2", "T2", "T10", "T10", "deploy", "T2bb",
  ]);
});

await check("status: frontmatter, checkboxes, continuation, questions", () => {
  const s = parseStatus(read("orders", "team", "T2b-engineer.md"));
  assert.equal(s.state, "blocked");
  assert.equal(s.updated, "2026-11-16T14:05:00Z");
  assert.deepEqual(s.progress[0], { done: true, text: "Cursor query" });
  assert.deepEqual(s.progress[1], {
    done: false,
    text: "Test with 200k rows, and a wrapped continuation line that belongs to the same item",
  });
  assert.equal(s.progress.length, 3);
  assert.equal(s.questions, "Keep the old header names or use the API names? Proposed: keep the old ones.");
});

await check("status: HTML and script pass through as plain text", () => {
  const s = parseStatus(read("orders", "team", "T2b-engineer.md"));
  assert.equal(s.progress[2].text, "Show <b>bold</b> and <script>alert(1)</script> as text");
  assert.equal(JSON.parse(JSON.stringify(s)).progress[2].text, s.progress[2].text);
});

await check("status: 'None' and empty questions give an empty string", () => {
  assert.equal(parseStatus(read("orders", "team", "T2-engineer.md")).questions, "");
  assert.equal(parseStatus(read("orders", "team", "T1-researcher.md")).questions, "");
  assert.equal(parseStatus("## Questions\nNone.\n").questions, "");
  assert.equal(parseStatus("## Questions\n\n## Findings\nx").questions, "");
});

await check("status: no frontmatter, plain bullets (done is null), blank line ends an item", () => {
  const s = parseStatus(read("legacy", "team", "T3-T4-engineer.md"));
  assert.equal(s.state, "");
  assert.equal(s.updated, "");
  assert.equal(s.progress.length, 2);
  assert.equal(s.progress[0].done, null);
  assert.equal(
    s.progress[0].text,
    "Read: the first review and the whole fix diff (11 files), the rework notes of two other tasks.",
  );
  assert.ok(!s.progress.some((p) => p.text.includes("Paragraph after")));
});

await check("status: half written and strange input never throws", () => {
  const whole = read("orders", "team", "T2b-engineer.md");
  for (let n = 0; n <= whole.length; n += 5) parseStatus(whole.slice(0, n));
  assert.equal(parseStatus("---\nstate: in-progress\nupda").state, "in-progress");
  assert.deepEqual(parseStatus(""), { state: "", updated: "", progress: [], questions: "" });
});

await check("status: limits on items, text and questions", () => {
  const many = Array.from({ length: 80 }, (_, i) => `- [ ] item ${i}`).join("\n");
  assert.equal(parseStatus(`## Progress\n${many}\n`).progress.length, LIMITS.progressItems);
  assert.equal(parseStatus(`## Progress\n- [x] ${"a".repeat(1000)}\n`).progress[0].text.length, 300);
  assert.equal(parseStatus(`## Questions\n${"q".repeat(5000)}\n`).questions.length, 2000);
});

await check("status: updated in the future or in another form is passed through as text", () => {
  assert.equal(parseStatus("---\nupdated: 2099-01-01T00:00:00Z\n---\n").updated, "2099-01-01T00:00:00Z");
  assert.equal(parseStatus("---\nupdated: yesterday around noon\n---\n").updated, "yesterday around noon");
});

await check("live log: whole lines counted, 8 newest, oldest first, bad lines skipped", () => {
  const l = parseLive(read("orders", "live", "T2b-engineer.log"));
  assert.equal(l.calls, 10);
  assert.equal(l.last.length, 8);
  assert.deepEqual(l.last[0], { at: "2026-11-16T14:05:03Z", tool: "Bash", target: "" });
  assert.deepEqual(l.last[7], { at: "2026-11-16T14:05:10Z", tool: "Bash", target: "node" });
});

await check("live log: a line still being written is skipped and not counted", () => {
  assert.deepEqual(parseLive("2026-11-16T14:05:12Z\tEdit\tsrc/a.js"), { calls: 0, last: [] });
  assert.equal(parseLive("2026-11-16T14:05:12Z\tEdit\tsrc/a.js\n2026-11-16T14:05:13Z\tBa").calls, 1);
  assert.deepEqual(parseLive(""), { calls: 0, last: [] });
});

await check("live log: wrong forms are skipped, long target is cut", () => {
  const text = [
    "garbage", "2026-11-16 14:05:12\tEdit\tx", "2026-11-16T14:05:12Z", "2026-11-16T14:05:12Z\t\tx",
    `2026-11-16T14:05:12Z\tRead\t${"t".repeat(500)}`, "",
  ].join("\n");
  const l = parseLive(text);
  assert.equal(l.calls, 1);
  assert.equal(l.last[0].target.length, 200);
});

await check("parsers accept null, numbers and objects without throwing", () => {
  for (const bad of [null, undefined, 5, {}, []]) {
    parseIndex(bad); parseBoard(bad); parseStatus(bad); parseLive(bad);
  }
});

// ================================================================ state and server

await check("findRoot: nearest folder with .crew/work/index.md, or null", () => {
  const root = copyFixture();
  fs.mkdirSync(path.join(root, "a", "b"), { recursive: true });
  assert.equal(findRoot(path.join(root, "a", "b")), root);
  assert.equal(findRoot(tmp()), null);
});

const root = copyFixture();
const board = await startServer({ root, port: 0, live: true });
const port = board.port;

await check("server: /api/state has the contract's shape for the fixture", async () => {
  const res = await request(port, "/api/state");
  assert.equal(res.status, 200);
  assert.match(res.headers["content-type"], /^application\/json/);
  const s = JSON.parse(res.body);
  assert.equal(s.project, "proj-fixture");
  assert.match(s.now, /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/);
  assert.deepEqual(s.open.map((i) => i.id), ["orders", "legacy", "ghost"]);
  assert.deepEqual(s.closed, [
    { id: "shipped", size: "M", note: "done 2026-10-12 (PR #4; retro done)" },
    { id: "retired", size: "S", note: "done 2026-10-01" },
  ]);
  const o = s.open[0];
  assert.deepEqual(
    [o.size, o.summary, o.phase, o.updated, o.next],
    ["L", "implement - T2b engineer running", "implement", "2026-11-16T14:05:00Z", "wait for T2b, then staff T3."],
  );
  assert.deepEqual(o.tasks.map((t) => t.task), ["T1", "T2", "T3", "T4"]);
  assert.ok(!res.body.includes(root), "the full path must not be served");
});

await check("server: re-staffed attempts are grouped, with status and live", async () => {
  const s = await getState(port);
  const t2 = s.open[0].tasks[1];
  assert.deepEqual(t2.attempts.map((a) => a.id), ["T2", "T2b"]);
  const b = t2.attempts[1];
  assert.deepEqual([b.role, b.model, b.effort, b.boardState], ["engineer", "sonnet", "high", "in-progress"]);
  assert.equal(b.status.state, "blocked");
  assert.equal(b.status.progress.length, 3);
  assert.equal(b.live.calls, 10);
  assert.equal(b.live.last.length, 8);
  assert.equal(t2.attempts[0].live, null);
});

await check("server: a row without a status file yet has status null", async () => {
  const s = await getState(port);
  const [t3, t4] = [s.open[0].tasks[2].attempts[0], s.open[0].tasks[3].attempts[0]];
  assert.equal(t3.status, null);
  assert.equal(t4.status, null);
  assert.equal(t3.live, null);
});

await check("server: no live log at all gives live null, the rest works", async () => {
  const s = await getState(port);
  const t1 = s.open[0].tasks[0].attempts[0];
  assert.equal(t1.live, null);
  assert.equal(t1.status.state, "done");
});

await check("server: older board layout gives effort '' and rows sharing a status file", async () => {
  const s = await getState(port);
  const legacy = s.open[1];
  assert.deepEqual(legacy.tasks.map((t) => t.task), ["T1", "T3", "T4", "T7"]);
  assert.equal(legacy.tasks[0].attempts[0].effort, "");
  assert.equal(legacy.tasks[1].attempts[0].status.progress.length, 2);
  assert.equal(legacy.tasks[2].attempts[0].status.progress.length, 2);
  assert.equal(legacy.tasks[3].attempts[0].status, null);
});

await check("server: an open item without a folder has empty tasks and no folder is made", async () => {
  const s = await getState(port);
  assert.deepEqual(s.open[2], { id: "ghost", size: "S", summary: "plan", phase: "", updated: "", next: "", tasks: [] });
  assert.ok(!exists(path.join(root, ".crew", "work", "ghost")));
  assert.ok(!exists(path.join(root, ".crew", "work", "retired")));
});

await check("server: refuses POST (405), foreign Host (403), other paths (404)", async () => {
  assert.equal((await request(port, "/api/state", { method: "POST" })).status, 405);
  assert.equal((await request(port, "/", { method: "DELETE" })).status, 405);
  assert.equal((await request(port, "/api/state", { method: "HEAD" })).status, 405);
  assert.equal((await request(port, "/api/state", { headers: { Host: "evil.example" } })).status, 403);
  assert.equal((await request(port, "/api/state", { headers: { Host: `evil.example:${port}` } })).status, 403);
  assert.equal((await request(port, "/api/state", { headers: { Host: `localhost:${port}` } })).status, 200);
  assert.equal((await request(port, "/../../etc/passwd")).status, 404);
  assert.equal((await request(port, "/api/state/x")).status, 404);
  assert.equal((await request(port, "/index.html")).status, 404);
  assert.equal((await request(port, "/server.mjs")).status, 404);
  assert.equal((await request(port, "/%2e%2e/%2e%2e/etc/passwd")).status, 404);
  assert.equal((await request(port, "/api/state?x=1")).status, 200);
});

await check("server: no-store and nosniff on every answer; CSP on the page", async () => {
  for (const p of ["/api/state", "/", "/nope"]) {
    const r = await request(port, p);
    assert.equal(r.headers["cache-control"], "no-store", p);
    assert.equal(r.headers["x-content-type-options"], "nosniff", p);
  }
  const r = await request(port, "/");
  assert.equal(r.status, 200);
  if (exists(path.join(HERE, "index.html"))) {
    assert.match(r.headers["content-type"], /^text\/html/);
    assert.match(r.headers["content-security-policy"], /^default-src 'none'; style-src 'unsafe-inline'; script-src 'sha256-/);
  } else {
    assert.match(r.body, /\/api\/state/);
  }
});

await check("live folders: open items get live/ with .gitignore '*'", () => {
  const work = path.join(root, ".crew", "work");
  assert.equal(fs.readFileSync(path.join(work, "legacy", "live", ".gitignore"), "utf8"), "*\n");
  assert.equal(fs.readFileSync(path.join(work, "orders", "live", ".gitignore"), "utf8"), "*\n");
  assert.ok(exists(path.join(work, "orders", "live", "T2b-engineer.log")));
});

await check("live folders: a closed item loses *.log and .gitignore, keeps other files and the folder", () => {
  const live = path.join(root, ".crew", "work", "shipped", "live");
  assert.ok(!exists(path.join(live, "a.log")));
  assert.ok(exists(path.join(live, "notes.txt")));
});

await check("live folders: an item that closes while running moves to closed and loses live/", async () => {
  const work = path.join(root, ".crew", "work");
  fs.writeFileSync(
    path.join(work, "index.md"),
    "# Work items\n\n## Open\n- `legacy` (M) - x - updated 2026-10-27\n\n## Closed\n- `orders` (L) - done 2026-11-16\n",
  );
  const s = await getState(port);
  assert.deepEqual(s.open.map((i) => i.id), ["legacy"]);
  assert.deepEqual(s.closed.map((i) => i.id), ["orders"]);
  assert.ok(!exists(path.join(work, "orders", "live")));
  assert.ok(exists(path.join(work, "orders", "board.md")), "the item's other files stay");
  assert.deepEqual(Object.keys(s.closed[0]).sort(), ["id", "note", "size"]);
});

await check("server: a half-written board gives an empty task list, not an error", async () => {
  const work = path.join(root, ".crew", "work");
  fs.writeFileSync(path.join(work, "legacy", "board.md"), "# Board: legacy\n\n**Phase:** impl\n\n| Task | Ro");
  const r = await request(port, "/api/state");
  assert.equal(r.status, 200);
  const l = JSON.parse(r.body).open[0];
  assert.deepEqual([l.phase, l.tasks], ["impl", []]);
});

await board.close();

await check("project without .crew/work or with an empty index: empty lists, no error", async () => {
  const bare = tmp();
  const withEmpty = tmp();
  fs.mkdirSync(path.join(withEmpty, ".crew", "work"), { recursive: true });
  fs.writeFileSync(path.join(withEmpty, ".crew", "work", "index.md"), "");
  for (const r of [bare, withEmpty, null]) {
    const b = await startServer({ root: r, port: 0 });
    try {
      const s = await getState(b.port);
      assert.deepEqual([s.open, s.closed], [[], []]);
    } finally {
      await b.close();
    }
  }
  assert.equal(readState(null, { cwd: bare }).project, path.basename(bare));
  assert.ok(!exists(path.join(bare, ".crew")), "nothing is created in a project without crew files");
});

await check("--no-live: no live/ folder is created and none is removed", async () => {
  const r = copyFixture();
  const b = await startServer({ root: r, port: 0, live: false });
  try {
    await getState(b.port);
  } finally {
    await b.close();
  }
  const work = path.join(r, ".crew", "work");
  assert.ok(!exists(path.join(work, "legacy", "live")));
  assert.ok(!exists(path.join(work, "orders", "live", ".gitignore")));
  assert.ok(exists(path.join(work, "shipped", "live", "a.log")));
});

await check("live folders: symlinks and files named live, and foreign files, are left alone", () => {
  const r = tmp();
  const work = path.join(r, ".crew", "work");
  const outside = path.join(r, "outside");
  fs.mkdirSync(outside);
  fs.writeFileSync(path.join(outside, "x.log"), "keep\n");
  for (const id of ["a", "b", "c", "d"]) fs.mkdirSync(path.join(work, id), { recursive: true });
  fs.symlinkSync(outside, path.join(work, "a", "live"));
  fs.writeFileSync(path.join(work, "b", "live"), "a file\n");
  fs.symlinkSync(outside, path.join(work, "c", "live"));
  fs.mkdirSync(path.join(work, "d", "live"));
  fs.writeFileSync(path.join(work, "d", "live", "x.log"), "log\n");
  fs.symlinkSync(path.join(outside, "x.log"), path.join(work, "d", "live", "link.log"));
  fs.writeFileSync(path.join(work, "d", "live", "keep.md"), "keep\n");
  fs.writeFileSync(path.join(work, "index.md"), "## Open\n- `a` (S) - x\n- `b` (S) - y\n\n## Closed\n- `c` (S) - done\n- `d` (S) - done\n");
  const { open, closed } = parseIndex(fs.readFileSync(path.join(work, "index.md"), "utf8"));
  manageLive(r, open, closed);
  assert.deepEqual(fs.readdirSync(outside), ["x.log"], "nothing is written through the symlink");
  assert.ok(fs.lstatSync(path.join(work, "a", "live")).isSymbolicLink());
  assert.equal(fs.readFileSync(path.join(work, "b", "live"), "utf8"), "a file\n");
  assert.ok(fs.lstatSync(path.join(work, "c", "live")).isSymbolicLink());
  assert.equal(fs.readFileSync(path.join(outside, "x.log"), "utf8"), "keep\n");
  assert.ok(!exists(path.join(work, "d", "live", "x.log")));
  assert.ok(fs.lstatSync(path.join(work, "d", "live", "link.log")).isSymbolicLink(), "a symlink named *.log stays");
  assert.ok(exists(path.join(work, "d", "live", "keep.md")));
});

await check("live folders: an empty live/ of a closed item is removed", () => {
  const r = tmp();
  const work = path.join(r, ".crew", "work");
  fs.mkdirSync(path.join(work, "z", "live"), { recursive: true });
  fs.writeFileSync(path.join(work, "z", "live", ".gitignore"), "*\n");
  fs.writeFileSync(path.join(work, "z", "live", "T1-engineer.log"), "x\n");
  manageLive(r, [], [{ id: "z" }, { id: "../z" }]);
  assert.ok(!exists(path.join(work, "z", "live")));
  assert.ok(exists(path.join(work, "z")));
});

function runServer(args, env = {}) {
  const child = spawn(process.execPath, [SERVER, ...args], { stdio: ["ignore", "pipe", "pipe"], env: { ...process.env, ...env } });
  const out = { stdout: "", stderr: "", child };
  child.stdout.on("data", (c) => (out.stdout += c));
  child.stderr.on("data", (c) => (out.stderr += c));
  out.exit = new Promise((resolve) => child.on("exit", (code, signal) => resolve({ code, signal })));
  return out;
}

const until = async (fn, ms = 8000) => {
  const end = Date.now() + ms;
  while (Date.now() < end) {
    const v = await fn();
    if (v) return v;
    await new Promise((r) => setTimeout(r, 50));
  }
  throw new Error("timed out");
};

await check("port in use: one clear line naming --port, exit code 1", async () => {
  const busy = net.createServer();
  await new Promise((resolve) => busy.listen(0, "127.0.0.1", resolve));
  const p = busy.address().port;
  try {
    const run = runServer(["--root", FIXTURE, "--no-live", "--port", String(p)]);
    const { code } = await run.exit;
    assert.equal(code, 1);
    assert.match(run.stderr, /port \d+ is already in use.*--port/);
    assert.equal(run.stderr.trim().split("\n").length, 1);
    assert.equal(run.stdout, "");
  } finally {
    busy.close();
  }
});

await check("command line: start line on stdout, serves the fixture, stops on SIGTERM", async () => {
  const run = runServer(["--root", FIXTURE, "--no-live", "--port", "0"]);
  try {
    await until(() => /\n/.test(run.stdout));
    const m = /^crew-board: http:\/\/127\.0\.0\.1:(\d+) \(project project\)\n$/.exec(run.stdout);
    assert.ok(m, run.stdout);
    const s = await getState(Number(m[1]));
    assert.equal(s.open.length, 3);
  } finally {
    run.child.kill("SIGTERM");
  }
  assert.equal((await run.exit).code, 0);
});

await check("command line: a bad flag is refused with a usage line", async () => {
  const run = runServer(["--port", "abc"]);
  assert.equal((await run.exit).code, 2);
  assert.match(run.stderr, /--port/);
});

await check("demo: writes real formats, the parser reads them, stop removes the folder", () => {
  const demo = startDemo();
  try {
    const s = readState(demo.root, { live: false });
    assert.equal(s.project, "shop-demo");
    assert.equal(s.open.length, 1);
    assert.equal(s.closed.length, 2);
    const attempts = s.open[0].tasks.flatMap((t) => t.attempts);
    assert.ok(attempts.length >= 5 && attempts.length <= 6);
    assert.ok(attempts.some((a) => a.id === "T2b"));
    assert.ok(attempts.find((a) => a.id === "T1").status.progress.length > 0);
  } finally {
    demo.stop();
  }
  assert.ok(!exists(demo.root));
});

await check("demo: the server changes between two fetches and the temp folder is gone after SIGINT", async () => {
  // The demo gets its own temp folder, so another demo on this machine cannot disturb the count.
  const mine = tmp();
  const run = runServer(["--demo", "--port", "0"], { TMPDIR: mine, TMP: mine, TEMP: mine });
  const created = [];
  try {
    await until(() => /\n/.test(run.stdout));
    const m = /127\.0\.0\.1:(\d+) \(project shop-demo\)/.exec(run.stdout);
    assert.ok(m, run.stdout);
    created.push(...fs.readdirSync(mine));
    assert.equal(created.length, 1);
    assert.ok(created[0].startsWith("crew-board-demo-"));
    const first = JSON.stringify((await getState(Number(m[1]))).open);
    await new Promise((r) => setTimeout(r, 3000));
    const second = JSON.stringify((await getState(Number(m[1]))).open);
    assert.notEqual(first, second);
  } finally {
    run.child.kill("SIGINT");
  }
  await run.exit;
  assert.ok(!exists(path.join(mine, created[0])));
});

// ================================================================ edge cases, second pass

const BOARD_HEAD = "| Task | Role | Model | Effort | State | Status file |\n|---|---|---|---|---|---|\n";

// A throwaway project: index.md text, and files as { "<id>/board.md": text, ... } under .crew/work.
function makeProject(index, files = {}) {
  const r = path.join(tmp(), "proj-edge");
  const w = path.join(r, ".crew", "work");
  fs.mkdirSync(w, { recursive: true });
  fs.writeFileSync(path.join(w, "index.md"), index);
  for (const [rel, text] of Object.entries(files)) {
    fs.mkdirSync(path.dirname(path.join(w, rel)), { recursive: true });
    fs.writeFileSync(path.join(w, rel), text);
  }
  return r;
}

// Sends the text as it is on a new connection; resolves to the status code (0 when none came back).
function rawRequest(port, text) {
  return new Promise((resolve) => {
    let data = "";
    const s = net.connect(port, "127.0.0.1");
    s.setTimeout(4000, () => s.destroy());
    s.on("data", (c) => (data += c));
    s.on("error", () => {});
    s.on("close", () => resolve(Number(/^HTTP\/\d\.\d (\d+)/.exec(data)?.[1] ?? 0)));
    s.write(text);
  });
}

// ---- index and board

await check("index: Windows line endings and a heading in upper case", () => {
  const { open, closed } = parseIndex(
    "# Work items\r\n\r\n## OPEN\r\n- `a` (S) - plan - updated 2026-10-01\r\n\r\n## Closed\r\n- `b` (M) - done 2026-10-02\r\n",
  );
  assert.deepEqual(open, [{ id: "a", size: "S", summary: "plan" }]);
  assert.deepEqual(closed, [{ id: "b", size: "M", note: "done 2026-10-02" }]);
});

await check("board: Windows line endings", () => {
  const b = parseBoard(
    "# Board: x\r\n\r\n**Phase:** implement · **Updated:** 2026-11-16T14:05:00Z\r\n\r\n" +
      BOARD_HEAD.replace(/\n/g, "\r\n") +
      "| T1 | engineer | sonnet | high | done | team/T1-engineer.md |\r\n\r\n**Next:** staff T2.\r\n",
  );
  assert.equal(b.phase, "implement");
  assert.equal(b.updated, "2026-11-16T14:05:00Z");
  assert.equal(b.next, "staff T2.");
  assert.equal(b.rows.length, 1);
  assert.deepEqual(b.rows[0], {
    id: "T1", role: "engineer", model: "sonnet", effort: "high", boardState: "done", statusFile: "team/T1-engineer.md",
  });
});

await check("board: an escaped pipe stays inside its cell", () => {
  const b = parseBoard(BOARD_HEAD + "| T2 | engineer | sonnet | high | missed \\| twice | team/T2-engineer.md |\n");
  assert.equal(b.rows.length, 1);
  assert.equal(b.rows[0].statusFile, "team/T2-engineer.md");
  assert.match(b.rows[0].boardState, /missed.*twice/);
});

await check("board: a row with fewer cells than the header gives empty strings", () => {
  const b = parseBoard(BOARD_HEAD + "| T1 | engineer |\n| T2 |\n");
  assert.deepEqual(b.rows, [
    { id: "T1", role: "engineer", model: "", effort: "", boardState: "", statusFile: "" },
    { id: "T2", role: "", model: "", effort: "", boardState: "", statusFile: "" },
  ]);
});

await check("board: a row with more cells than the header is read by header name", () => {
  const b = parseBoard(BOARD_HEAD + "| T1 | engineer | sonnet | high | done | team/T1-engineer.md | extra | more |\n");
  assert.equal(b.rows[0].statusFile, "team/T1-engineer.md");
});

await check("board: two tables, a table without a Task column first, and two Task tables", () => {
  const other = "| Name | Value |\n|---|---|\n| a | 1 |\n\n";
  const second = parseBoard(other + BOARD_HEAD + "| T1 | engineer | s | h | done | |\n");
  assert.deepEqual(second.rows.map((r) => r.id), ["T1"]);
  const two = parseBoard(
    BOARD_HEAD + "| T1 | engineer | s | h | done | |\n\n" + BOARD_HEAD + "| T9 | reviewer | s | h | todo | |\n",
  );
  assert.equal(two.rows[0].id, "T1");
  assert.ok(!two.rows.some((r) => r.id === "Task"), "the second header is not a row");
});

await check("board: header in another letter case and in another column order", () => {
  const b = parseBoard("| TASK | ROLE | Status File | STATE |\n|---|---|---|---|\n| T1 | engineer | team/T1-engineer.md | done |\n");
  assert.deepEqual(b.rows[0], {
    id: "T1", role: "engineer", model: "", effort: "", boardState: "done", statusFile: "team/T1-engineer.md",
  });
});

// ---- status file

await check("status: Windows line endings", () => {
  const s = parseStatus(
    "---\r\ntask: T1\r\nstate: done\r\nupdated: 2026-11-16T14:05:00Z\r\n---\r\n## Progress\r\n- [x] a\r\n- [ ] b\r\n## Questions\r\nNone.\r\n",
  );
  assert.deepEqual(s, {
    state: "done",
    updated: "2026-11-16T14:05:00Z",
    progress: [{ done: true, text: "a" }, { done: false, text: "b" }],
    questions: "",
  });
});

await check("status: quoted state, and the template's trailing comment", () => {
  assert.equal(parseStatus('---\nstate: "done"\n---\n').state, "done");
  assert.equal(parseStatus("---\nstate: 'blocked'\n---\n").state, "blocked");
  assert.equal(parseStatus("---\nstate: in-progress   # in-progress | blocked | done | failed\n---\n").state, "in-progress");
});

await check("status: nested list items under a progress item keep the parent's text and lose nothing", () => {
  const s = parseStatus("## Progress\n- [x] parent step\n  - child one\n  - [ ] child two\n- [ ] next\n");
  assert.equal(s.progress[0].text, "parent step");
  assert.equal(s.progress[0].done, true);
  const all = s.progress.map((p) => p.text).join("|");
  assert.ok(all.includes("child one") && all.includes("child two") && all.includes("next"), all);
});

await check("status: '## Progress' twice does not lose the first one and does not throw", () => {
  const s = parseStatus("## Progress\n- [x] first\n\n## Findings\nx\n\n## Progress\n- [ ] again\n");
  assert.ok(s.progress.some((p) => p.text === "first"));
  assert.ok(s.progress.length <= LIMITS.progressItems);
});

await check("status: a 1 MB body is read within the limits", () => {
  const big = "x".repeat(1024 * 1024);
  const one = parseStatus(`---\nstate: done\n---\n## Progress\n- [ ] ${big}\n## Questions\n${big}\n`);
  assert.equal(one.state, "done");
  assert.equal(one.progress[0].text.length, LIMITS.progressText);
  assert.equal(one.questions.length, LIMITS.questions);
  const many = parseStatus("## Progress\n" + "- [ ] y\n".repeat(150000));
  assert.equal(many.progress.length, LIMITS.progressItems);
});

// ---- live log

await check("live log: Windows line endings", () => {
  const l = parseLive("2026-11-16T14:05:12Z\tEdit\tsrc/a.js\r\n2026-11-16T14:05:13Z\tBash\tnode\r\n");
  assert.equal(l.calls, 2);
  assert.deepEqual(l.last[0], { at: "2026-11-16T14:05:12Z", tool: "Edit", target: "src/a.js" });
  assert.deepEqual(l.last[1], { at: "2026-11-16T14:05:13Z", tool: "Bash", target: "node" });
});

await check("live log: a line of two fields counts with an empty target", () => {
  assert.deepEqual(parseLive("2026-11-16T14:05:12Z\tAgent\n"), {
    calls: 1,
    last: [{ at: "2026-11-16T14:05:12Z", tool: "Agent", target: "" }],
  });
});

await check("live log: a time not in the contract's form is skipped", () => {
  for (const t of [
    "2026-11-16T14:05:12+01:00", "2026-11-16T14:05:12.5Z", "2026-11-16T14:05:12", "26-11-16T14:05:12Z",
    " 2026-11-16T14:05:12Z", "2026-11-16T14:05:12Z ", "2026-11-16t14:05:12z", "yesterday",
  ]) {
    assert.deepEqual(parseLive(`${t}\tEdit\tx\n`), { calls: 0, last: [] }, JSON.stringify(t));
  }
});

await check("live log: 10,000 lines are all counted and only the 8 newest come back, oldest first", () => {
  const rows = [];
  for (let i = 0; i < 10000; i++) {
    const s = String(i % 60).padStart(2, "0");
    rows.push(`2026-11-16T14:05:${s}Z\tRead\tf${i}.js`);
  }
  const l = parseLive(rows.join("\n") + "\n");
  assert.equal(l.calls, 10000);
  assert.deepEqual(l.last.map((c) => c.target), Array.from({ length: 8 }, (_, i) => `f${9992 + i}.js`));
});

// ---- the server and its files

await check("server: a 3 MB status file is cut, the frontmatter and the first items still arrive", async () => {
  const bigStatus = "---\nstate: done\nupdated: 2026-11-16T14:05:00Z\n---\n## Progress\n" + "- [ ] step\n".repeat(300000);
  const r = makeProject("## Open\n- `w` (S) - x\n", {
    "w/board.md": BOARD_HEAD + "| T1 | engineer | s | h | done | team/T1-engineer.md |\n",
    "w/team/T1-engineer.md": bigStatus,
  });
  const b = await startServer({ root: r, port: 0 });
  try {
    const res = await request(b.port, "/api/state");
    assert.equal(res.status, 200);
    const a = JSON.parse(res.body).open[0].tasks[0].attempts[0];
    assert.equal(a.status.state, "done");
    assert.equal(a.status.progress.length, LIMITS.progressItems);
  } finally {
    await b.close();
  }
});

await check("server: a live log over 8 MB gives the newest calls and the server stays up", async () => {
  const line = (i) => `2026-11-16T14:05:${String(i % 60).padStart(2, "0")}Z\tRead\tsrc/file-${i}.js\n`;
  const total = 200000;
  let text = "";
  for (let i = 0; i < total; i++) text += line(i);
  assert.ok(text.length > 8 * 1024 * 1024);
  const r = makeProject("## Open\n- `w` (S) - x\n", {
    "w/board.md": BOARD_HEAD + "| T1 | engineer | s | h | in-progress | team/T1-engineer.md |\n",
    "w/live/T1-engineer.log": text,
  });
  const b = await startServer({ root: r, port: 0 });
  try {
    const live = (await getState(b.port)).open[0].tasks[0].attempts[0].live;
    assert.ok(live.calls > 0 && live.calls <= total);
    assert.equal(live.last.length, 8);
    assert.equal(live.last[7].target, `src/file-${total - 1}.js`);
    assert.ok(live.last.every((c) => /^src\/file-\d+\.js$/.test(c.target)), "no cut line comes back");
  } finally {
    await b.close();
  }
});

await check("server: 500 closed items answer, and no closed item's folder is read but live/", async () => {
  const files = { "cur/board.md": BOARD_HEAD + "| T1 | engineer | s | h | todo | |\n" };
  let index = "## Open\n- `cur` (S) - x\n\n## Closed\n";
  for (let i = 0; i < 500; i++) {
    index += `- \`c${i}\` (S) - done 2026-10-01\n`;
    files[`c${i}/board.md`] = BOARD_HEAD + "| T1 | engineer | s | h | done | team/T1-engineer.md |\n";
    files[`c${i}/team/T1-engineer.md`] = "---\nstate: done\n---\n";
    if (i % 50 === 0) files[`c${i}/live/T1-engineer.log`] = "2026-11-16T14:05:12Z\tRead\tx\n";
  }
  const r = makeProject(index, files);
  const work = path.join(r, ".crew", "work");
  const b = await startServer({ root: r, port: 0 });
  const seen = [];
  const names = ["openSync", "readFileSync", "readdirSync", "statSync", "lstatSync", "existsSync", "opendirSync", "readlinkSync"];
  const originals = names.map((n) => fs[n]);
  names.forEach((n, i) => {
    fs[n] = (p, ...rest) => {
      if (typeof p === "string") seen.push(p);
      return originals[i].call(fs, p, ...rest);
    };
  });
  let s;
  try {
    s = await getState(b.port);
  } finally {
    names.forEach((n, i) => (fs[n] = originals[i]));
    await b.close();
  }
  assert.equal(s.closed.length, 500);
  assert.equal(s.open.length, 1);
  const stray = seen.filter((p) => {
    const m = /[\\/]work[\\/](c\d+)(?:[\\/](.*))?$/.exec(p);
    return m && p.startsWith(work) && m[2] !== undefined && m[2] !== "live" && !m[2].startsWith("live/");
  });
  assert.deepEqual(stray, [], "a closed item's file was read");
  assert.ok(!exists(path.join(work, "c0", "live")), "the live/ cleanup still ran");
});

await check("server: item ids that are not safe names are listed, and nothing on disk is touched for them", () => {
  const abs = path.join(tmp(), "abs-item");
  const r = makeProject(
    [
      "## Open",
      "- `../x` (S) - up",
      `- \`${abs}\` (S) - absolute`,
      "- `a/b` (S) - slash",
      "- `a\\b` (S) - backslash",
      "- `.hidden` (S) - dot",
      "- `..` (S) - dots",
      "",
      "## Closed",
      "- `../y` (S) - done",
      "- `a/c` (S) - done",
      `- \`${abs}-closed\` (S) - done`,
      "",
    ].join("\n"),
    {
      "../x/board.md": "**Phase:** LEAK\n\n" + BOARD_HEAD + "| T1 | engineer | s | h | todo | |\n",
      "../y/live/T1-engineer.log": "2026-11-16T14:05:12Z\tRead\tx\n",
      "a/b/board.md": "**Phase:** LEAK\n",
      "a/c/live/T1-engineer.log": "2026-11-16T14:05:12Z\tRead\tx\n",
      ".hidden/board.md": "**Phase:** LEAK\n",
    },
  );
  const work = path.join(r, ".crew", "work");
  const absWork = path.join(work, abs);
  fs.mkdirSync(path.join(absWork, "live"), { recursive: true });
  fs.writeFileSync(path.join(absWork, "live", "T1-engineer.log"), "2026-11-16T14:05:12Z\tRead\tx\n");
  fs.mkdirSync(path.join(work, `${abs}-closed`, "live"), { recursive: true });
  fs.writeFileSync(path.join(work, `${abs}-closed`, "live", "T1-engineer.log"), "2026-11-16T14:05:12Z\tRead\tx\n");
  const before = (d) => fs.readdirSync(d).sort().join(",");
  const snap = [path.join(r, ".crew"), work, path.join(work, "a"), path.join(work, "a", "b"), path.join(work, ".hidden"), path.join(r, ".crew", "x")];
  const was = snap.map(before);
  const s = readState(r);
  assert.deepEqual(s.open.map((i) => i.id), ["../x", abs, "a/b", "a\\b", ".hidden", ".."]);
  for (const item of s.open) assert.deepEqual([item.phase, item.tasks], ["", []], item.id);
  assert.deepEqual(s.closed.map((i) => i.id), ["../y", "a/c", `${abs}-closed`]);
  assert.deepEqual(snap.map(before), was, "no folder gained or lost an entry");
  assert.ok(!exists(path.join(r, ".crew", "x", "live")));
  assert.ok(!exists(path.join(r, ".crew", "live")));
  assert.ok(!exists(path.join(work, "a", "b", "live")));
  assert.ok(!exists(path.join(work, ".hidden", "live")));
  assert.ok(exists(path.join(absWork, "live")), "no live/ made or removed for an absolute id");
  assert.ok(exists(path.join(r, ".crew", "y", "live", "T1-engineer.log")));
  assert.ok(exists(path.join(work, "a", "c", "live", "T1-engineer.log")));
  assert.ok(exists(path.join(work, `${abs}-closed`, "live", "T1-engineer.log")));
});

await check("server: status file and log names that climb out of the item are not read", async () => {
  const r = makeProject("## Open\n- `w` (S) - x\n", {
    "w/board.md": [
      BOARD_HEAD.trimEnd(),
      "| T1 | engineer | s | h | done | ../../secret.md |",
      "| T2 | engineer | s | h | done | /etc/passwd |",
      "| T3 | engineer | s | h | done | team/../secret.md |",
      "| T4 | engineer | s | h | done | team/a/b.md |",
      "| a/../../secret | x | s | h | done | |",
      "| T6 | ../secret | s | h | done | |",
      "",
    ].join("\n"),
    "secret.md": "---\nstate: TOPSECRET\n---\n## Progress\n- [ ] TOPSECRET\n",
    "w/secret-x.md": "---\nstate: TOPSECRET\n---\n",
    "w/team/a/b.md": "---\nstate: TOPSECRET\n---\n",
  });
  fs.writeFileSync(path.join(r, ".crew", "secret.md"), "---\nstate: TOPSECRET\n---\n");
  const b = await startServer({ root: r, port: 0 });
  try {
    const res = await request(b.port, "/api/state");
    assert.equal(res.status, 200);
    assert.ok(!res.body.includes("TOPSECRET"));
    const attempts = JSON.parse(res.body).open[0].tasks.flatMap((t) => t.attempts);
    assert.equal(attempts.length, 6);
    for (const a of attempts) assert.equal(a.status, null, a.id);
  } finally {
    await b.close();
  }
});

await check("live folders: an open item keeps its logs, files and live/; a closed one loses only *.log and .gitignore files", async () => {
  const log = "2026-11-16T14:05:12Z\tRead\tx\n";
  const r = makeProject("## Open\n- `o` (S) - x\n- `p` (S) - y\n\n## Closed\n- `c` (S) - done\n- `d` (S) - done\n", {
    "o/board.md": BOARD_HEAD,
    "o/live/T1-engineer.log": log,
    "o/live/other.md": "keep\n",
    "p/board.md": BOARD_HEAD,
    "c/live/x.log": log,
    "c/live/.gitignore": "*\n",
    "c/live/keep.txt": "keep\n",
    "c/live/T1.log.bak": "keep\n",
    "c/live/log": "keep\n",
    "c/live/sub/inner.log": "keep\n",
    "c/live/dir.log/inner": "keep\n",
    "d/live/.gitignore/inner": "keep\n",
  });
  const work = path.join(r, ".crew", "work");
  const b = await startServer({ root: r, port: 0 });
  try {
    for (let i = 0; i < 3; i++) await getState(b.port);
  } finally {
    await b.close();
  }
  assert.equal(fs.readFileSync(path.join(work, "o", "live", "T1-engineer.log"), "utf8"), log);
  assert.ok(exists(path.join(work, "o", "live", "other.md")));
  assert.equal(fs.readFileSync(path.join(work, "p", "live", ".gitignore"), "utf8"), "*\n", "open item: live/ with only .gitignore stays");
  assert.ok(!exists(path.join(work, "c", "live", "x.log")));
  assert.ok(exists(path.join(work, "c", "live", ".gitignore")), "the folder holds other files, so it keeps ignoring itself");
  for (const keep of ["keep.txt", "T1.log.bak", "log", "sub/inner.log", "dir.log/inner"]) {
    assert.ok(exists(path.join(work, "c", "live", keep)), keep);
  }
  assert.ok(exists(path.join(work, "d", "live", ".gitignore", "inner")), "a folder named .gitignore is left alone");
});

// ---- requests

const edge = await startServer({ root: copyFixture(), port: 0, live: false });
const ep = edge.port;

await check("requests: OPTIONS, PUT, PATCH, TRACE and a method with odd letters give 405", async () => {
  for (const method of ["OPTIONS", "PUT", "PATCH", "TRACE", "PROPFIND"]) {
    const r = await request(ep, "/api/state", { method }).catch((e) => ({ status: `error ${e.code}` }));
    assert.equal(r.status, 405, method);
  }
  const o = await request(ep, "/api/state", { method: "OPTIONS" });
  assert.equal(o.headers.allow, "GET");
  assert.ok(!("access-control-allow-origin" in o.headers), "no CORS header");
});

await check("requests: a wrong Host is refused even for a wrong method or an unknown path", async () => {
  assert.equal((await request(ep, "/api/state", { method: "POST", headers: { Host: "evil.test" } })).status, 403);
  assert.equal((await request(ep, "/nope", { headers: { Host: "evil.test" } })).status, 403);
  assert.equal((await request(ep, "/", { headers: { Host: "evil.test" } })).status, 403);
});

await check("requests: no Host header is refused", async () => {
  assert.equal(await rawRequest(ep, "GET /api/state HTTP/1.0\r\n\r\n"), 403);
  assert.equal(await rawRequest(ep, "GET / HTTP/1.0\r\n\r\n"), 403);
  assert.equal(await rawRequest(ep, "GET /api/state HTTP/1.0\r\nHost:\r\n\r\n"), 403, "an empty Host");
  assert.equal(await rawRequest(ep, `GET /api/state HTTP/1.0\r\nHost: 127.0.0.1:${ep}\r\n\r\n`), 200);
});

await check("requests: a Host with another port, no port, or more than the right text is refused", async () => {
  const bad = [
    `127.0.0.1:${ep + 1}`, "127.0.0.1:1", "127.0.0.1", "localhost", `localhost:${ep + 1}`,
    `127.0.0.1:${ep}.evil.test`, `localhost:${ep}.evil.test`, `127.0.0.1:${ep}0`, `127.0.0.1:${ep}x`,
    `evil.test@127.0.0.1:${ep}`, `127.0.0.1:${ep}@evil.test`, `evil.test:${ep}`, `127.0.0.1.evil.test:${ep}`,
    `[::1]:${ep}`, `0.0.0.0:${ep}`, `127.0.0.2:${ep}`,
  ];
  for (const host of bad) {
    const r = await request(ep, "/api/state", { headers: { Host: host } });
    assert.equal(r.status, 403, JSON.stringify(host));
    assert.ok(!r.body.includes("proj-fixture"), "no state is served");
  }
  for (const host of [`127.0.0.1:${ep}`, `localhost:${ep}`, `LOCALHOST:${ep}`]) {
    assert.equal((await request(ep, "/api/state", { headers: { Host: host } })).status, 200, host);
  }
});

await check("requests: /?gallery is the page, /api/state?x=1 is the state, //api/state and long paths are not served", async () => {
  const page = await request(ep, "/");
  const withQuery = await request(ep, "/?gallery");
  assert.equal(withQuery.status, 200);
  assert.equal(withQuery.body, page.body);
  assert.equal((await request(ep, "/?gallery=1&x=%00")).status, 200);
  const q = await request(ep, "/api/state?x=1&y=%00");
  assert.equal(q.status, 200);
  assert.equal(JSON.parse(q.body).project, "proj-fixture");
  assert.equal((await request(ep, "/api/state#frag")).status, 200);
  assert.equal((await request(ep, "//api/state")).status, 404);
  assert.equal((await request(ep, "/api//state")).status, 404);
  assert.equal((await request(ep, "/api/state/")).status, 404);
  assert.equal((await request(ep, "/API/STATE")).status, 404);
  assert.equal((await request(ep, "/" + "a".repeat(8000))).status, 404);
  const huge = await request(ep, "/" + "a".repeat(200000)).catch(() => ({ status: 0 }));
  assert.ok([0, 404, 414, 431].includes(huge.status), `status ${huge.status}`);
  assert.equal((await request(ep, "/api/state")).status, 200, "still serving after the long path");
});

await check("requests: odd request targets do not crash the server", async () => {
  for (const target of ["*", "http://evil.test/api/state", "/%", "/%zz", "/api/state%00", "/é", "\\api\\state"]) {
    const code = await rawRequest(ep, `GET ${target.replace(/[^\x21-\x7e]/g, "")} HTTP/1.0\r\nHost: 127.0.0.1:${ep}\r\n\r\n`);
    // "/é" loses its non-ASCII letter in the filter above and becomes "/", the page.
    const allowed = target === "/é" ? [200] : [0, 400, 404];
    assert.ok(allowed.includes(code), `${target}: ${code}`);
  }
  assert.equal((await request(ep, "/api/state")).status, 200);
});

await edge.close();

// ---- follow-up: open and closed at once, request targets

await check("an id under both Open and Closed is never cleaned up", async () => {
  const r = makeProject("## Open\n- `both` (S) - x\n\n## Closed\n- `both` (S) - done 2026-10-01\n", {
    "both/board.md": BOARD_HEAD + "| T1 | engineer | s | h | in-progress | team/T1-engineer.md |\n",
    "both/live/T1-engineer.log": "2026-11-16T14:05:12Z\tEdit\tsrc/a.js\n",
    "both/live/.gitignore": "*\n",
  });
  const b = await startServer({ root: r, port: 0 });
  try {
    for (let i = 0; i < 2; i++) {
      const s = await getState(b.port);
      assert.equal(s.open[0].tasks[0].attempts[0].live.calls, 1);
    }
  } finally {
    await b.close();
  }
  const live = path.join(r, ".crew", "work", "both", "live");
  assert.ok(exists(path.join(live, "T1-engineer.log")));
  assert.equal(fs.readFileSync(path.join(live, ".gitignore"), "utf8"), "*\n");
});

await check("request targets: only / and /api/state, decided on the raw target", async () => {
  const b = await startServer({ root: null, port: 0 });
  const host = `127.0.0.1:${b.port}`;
  const get = (target) => rawRequest(b.port, `GET ${target} HTTP/1.1\r\nHost: ${host}\r\nConnection: close\r\n\r\n`);
  try {
    for (const t of ["//evil.test/api/state", "//api/state", "http://evil.test/api/state", "/api/state/", "//"]) {
      assert.equal(await get(t), 404, t);
    }
    assert.equal(await get("/?gallery"), 200);
    assert.equal(await get("/api/state?x=1"), 200);
    assert.equal(await get("/api/state"), 200);
  } finally {
    await b.close();
  }
});

// ---- review fixes

const LONG = " ".repeat(200000);

await check("a line of 200,000 spaces cannot stall the parsers (status, board, index)", () => {
  const t0 = Date.now();
  const s = parseStatus(`---\nstate: a${LONG}b\n---\n## x${LONG}y\n## Progress\n- [ ] a${LONG}b\n`);
  assert.equal(s.state.startsWith("a"), true);
  const b = parseBoard(`**Phase:** a${LONG}b · **Updated:** x\n${BOARD_HEAD}| T1 | e${LONG}x | s | h | d | |\n`);
  assert.equal(b.rows[0].id, "T1");
  const i = parseIndex(`## Open\n- \`a\`${LONG}b\n- \`c\` (S)${LONG}- x${LONG}y\n## Closed${LONG}x\n`);
  assert.ok(Array.isArray(i.open));
  assert.ok(Date.now() - t0 < 2000, `took ${Date.now() - t0} ms`);
});

await check("board: **Phase:** or **Next:** at the end of a line does not take the next line", () => {
  const b = parseBoard("**Phase:**\n\n**Updated:** 2026-11-16T14:05:00Z\n**Next:**\n| Task | Role |\n|---|---|\n| T1 | e |\n");
  assert.deepEqual([b.phase, b.updated, b.next], ["", "2026-11-16T14:05:00Z", ""]);
});

await check("board: a separator row of single dashes is not a task row", () => {
  const b = parseBoard("| Task | Role |\n|-|-|\n| T1 | engineer |\n");
  assert.deepEqual(b.rows.map((r) => r.id), ["T1"]);
});

await check("status file cell: a longer path or backticks around team/<name>.md is accepted", async () => {
  const r = makeProject("## Open\n- `w` (S) - x\n", {
    "w/board.md":
      BOARD_HEAD +
      "| T1 | engineer | s | h | done | `team/T1-engineer.md` |\n" +
      "| T2 | engineer | s | h | done | .crew/work/w/team/T2-engineer.md |\n" +
      "| T3 | engineer | s | h | done | ../../team/T3-engineer.md |\n" +
      "| T4 | engineer | s | h | done | xteam/T4-engineer.md |\n",
    "w/team/T1-engineer.md": "---\nstate: done\n---\n",
    "w/team/T2-engineer.md": "---\nstate: done\n---\n",
    "w/team/T3-engineer.md": "---\nstate: done\n---\n",
    "w/team/T4-engineer.md": "---\nstate: done\n---\n",
  });
  const s = readState(r, { live: false });
  assert.deepEqual(
    s.open[0].tasks.map((t) => t.attempts[0].status?.state ?? null),
    ["done", "done", "done", null],
  );
});

await check("index: only the headings Open and Closed count, in any letter case with spaces around", () => {
  const { open, closed } = parseIndex(
    "## Closed ideas\n- `x` (S) - not closed\n## open  \n- `a` (S) - y\n##  CLOSED\n- `b` (S) - done\n## Open items\n- `z` (S) - no\n",
  );
  assert.deepEqual(open.map((i) => i.id), ["a"]);
  assert.deepEqual(closed.map((i) => i.id), ["b"]);
});

await check("a status file or log that is a symbolic link is not read", async () => {
  const r = makeProject("## Open\n- `w` (S) - x\n", {
    "w/board.md": BOARD_HEAD + "| T1 | engineer | s | h | done | team/T1-engineer.md |\n",
    "outside/notes.md": "---\nstate: done\n---\n## Progress\n- [x] secret\n",
    "outside/notes.log": "2026-11-16T14:05:12Z\tEdit\tsecret\n",
    "w/live/.gitignore": "*\n",
  });
  const work = path.join(r, ".crew", "work");
  fs.mkdirSync(path.join(work, "w", "team"));
  fs.symlinkSync(path.join(work, "outside", "notes.md"), path.join(work, "w", "team", "T1-engineer.md"));
  fs.symlinkSync(path.join(work, "outside", "notes.log"), path.join(work, "w", "live", "T1-engineer.log"));
  const a = readState(r, { live: false }).open[0].tasks[0].attempts[0];
  assert.equal(a.status, null);
  assert.equal(a.live, null);
});

await check("a FIFO named like a status file or log does not hang the server", async (t) => {
  const r = makeProject("## Open\n- `w` (S) - x\n", {
    "w/board.md": BOARD_HEAD + "| T1 | engineer | s | h | done | team/T1-engineer.md |\n",
    "w/live/.gitignore": "*\n",
  });
  const work = path.join(r, ".crew", "work", "w");
  fs.mkdirSync(path.join(work, "team"));
  try {
    execFileSync("mkfifo", [path.join(work, "team", "T1-engineer.md")]);
    execFileSync("mkfifo", [path.join(work, "live", "T1-engineer.log")]);
  } catch {
    console.log("note: mkfifo is not available; the FIFO check is skipped");
    return;
  }
  const run = runServer(["--root", r, "--no-live", "--port", "0"]);
  try {
    await until(() => /\n/.test(run.stdout));
    const port = Number(/127\.0\.0\.1:(\d+)/.exec(run.stdout)[1]);
    const res = await Promise.race([
      request(port, "/api/state"),
      new Promise((_, no) => setTimeout(() => no(new Error("the server hangs on a FIFO")), 4000)),
    ]);
    const a = JSON.parse(res.body).open[0].tasks[0].attempts[0];
    assert.equal(a.status, null);
    assert.equal(a.live, null);
  } finally {
    run.child.kill("SIGKILL");
  }
});

await check("closed item: .gitignore goes only when the folder is empty without it", () => {
  const r = makeProject("## Closed\n- `a` (S) - done\n- `b` (S) - done\n", {
    "a/live/.gitignore": "*\n",
    "a/live/x.log": "x\n",
    "a/live/other.txt": "keep\n",
    "b/live/.gitignore": "*\n",
    "b/live/x.log": "x\n",
  });
  readState(r);
  const work = path.join(r, ".crew", "work");
  assert.deepEqual(fs.readdirSync(path.join(work, "a", "live")).sort(), [".gitignore", "other.txt"]);
  assert.ok(!exists(path.join(work, "b", "live")));
});

await check("CSP: inline scripts by hash, no unsafe-inline for scripts, frame and form rules", async () => {
  const one = (s) => `'sha256-${createHash("sha256").update(s).digest("base64")}'`;
  const unit = pageCsp("<html><script>a()</script><script src=\"x.js\"></script><script type=\"module\">\nb()\n</script></html>");
  assert.ok(unit.includes(`script-src ${one("a()")} ${one("\nb()\n")};`), unit);
  assert.ok(pageCsp("<p>no script</p>").includes("script-src 'none';"));
  const b = await startServer({ root: null, port: 0 });
  try {
    const res = await request(b.port, "/");
    const csp = res.headers["content-security-policy"];
    const blocks = [];
    let from = 0;
    for (;;) {
      const open = res.body.indexOf("<script", from);
      if (open < 0) break;
      const start = res.body.indexOf(">", open) + 1;
      const end = res.body.indexOf("</script>", start);
      blocks.push(res.body.slice(start, end));
      from = end;
    }
    assert.ok(blocks.length >= 1, "the page has an inline script");
    const scriptSrc = /script-src ([^;]*)/.exec(csp)[1];
    assert.deepEqual(scriptSrc.split(" "), blocks.map(one));
    assert.ok(!scriptSrc.includes("unsafe-inline"));
    for (const part of ["frame-ancestors 'none'", "base-uri 'none'", "form-action 'none'", "style-src 'unsafe-inline'"]) {
      assert.ok(csp.includes(part), part);
    }
  } finally {
    await b.close();
  }
});

await check("page: text only (innerHTML twice, no other way to write markup or code)", () => {
  const page = fs.readFileSync(path.join(HERE, "index.html"), "utf8");
  assert.equal(page.split("innerHTML").length - 1, 2, "innerHTML count");
  for (const bad of ["insertAdjacentHTML", "outerHTML", "document.write", "eval(", "new Function", 'setTimeout("', "href =", "src ="]) {
    assert.ok(!page.includes(bad), bad);
  }
  assert.ok(!/\son[a-z]+\s*=/i.test(page.replace(/<script[\s\S]*?<\/script>/gi, "")), "an inline event handler would be blocked by the CSP");
});

await check("page: the direction-mark filter removes exactly the twelve direction marks, and no file here holds one", () => {
  // The twelve characters of Unicode's Bidi_Control set.
  const isMark = (c) => c === 0x061c || (c >= 0x200e && c <= 0x200f) || (c >= 0x202a && c <= 0x202e) || (c >= 0x2066 && c <= 0x2069);
  // An editing tool can turn an escape into the character itself, in any file: scan them all.
  const found = [];
  for (const name of fs.readdirSync(HERE)) {
    if (!/\.(mjs|html|md)$/.test(name)) continue;
    for (const ch of fs.readFileSync(path.join(HERE, name), "utf8")) {
      if (isMark(ch.codePointAt(0))) found.push(name + " U+" + ch.codePointAt(0).toString(16));
    }
  }
  assert.deepEqual(found, [], "invisible direction marks in a file");
  const page = fs.readFileSync(path.join(HERE, "index.html"), "utf8");
  const m = page.match(/var DIRECTION_MARKS = (new RegExp\([^\n]*\));/);
  assert.ok(m, "the filter line");
  const filter = Function("return " + m[1])();
  // Run the page's own filter on every code point of the basic plane: it must remove the marks and nothing else.
  const removed = [];
  const wanted = [];
  for (let c = 0; c <= 0xffff; c++) {
    if (isMark(c)) wanted.push(c);
    if (String.fromCharCode(c).replace(filter, "") === "") removed.push(c);
  }
  assert.deepEqual(removed, wanted, "the set the filter removes");
  assert.equal(wanted.length, 12);
  assert.equal("T2b-engineer".replace(filter, ""), "T2b-engineer", "a hyphen is not a direction mark");
});

await check("live folders: an item folder that is a symbolic link gets no live/", () => {
  const r = makeProject("## Open\n- `w` (S) - x\n");
  const work = path.join(r, ".crew", "work");
  const outside = path.join(tmp(), "elsewhere");
  fs.mkdirSync(outside);
  fs.symlinkSync(outside, path.join(work, "w"));
  readState(r);
  assert.deepEqual(fs.readdirSync(outside), []);
});

await check("a read-only project still answers, and nothing is changed", async () => {
  if (typeof process.getuid === "function" && process.getuid() === 0) {
    console.log("note: running as root; the read-only check is skipped");
    return;
  }
  const r = makeProject("## Open\n- `w` (S) - x\n", { "w/board.md": BOARD_HEAD + "| T1 | e | s | h | todo | |\n" });
  const work = path.join(r, ".crew", "work");
  fs.chmodSync(path.join(work, "w"), 0o555);
  const b = await startServer({ root: r, port: 0 });
  try {
    const s = await getState(b.port);
    assert.equal(s.open[0].tasks.length, 1);
    assert.ok(!exists(path.join(work, "w", "live")));
  } finally {
    await b.close();
    fs.chmodSync(path.join(work, "w"), 0o755);
  }
});

await check("--root without .crew/work/index.md: one warning on stderr, the server still starts", async () => {
  const empty = tmp();
  const run = runServer(["--root", empty, "--no-live", "--port", "0"]);
  try {
    await until(() => /\n/.test(run.stdout));
    assert.match(run.stdout, /^crew-board: http:\/\/127\.0\.0\.1:\d+ \(project crew-board-test-/);
    assert.equal(run.stderr.trim().split("\n").length, 1);
    assert.match(run.stderr, /warning.*index\.md/);
  } finally {
    run.child.kill("SIGTERM");
  }
  await run.exit;
});

await check("a server error after listening is printed, not thrown", async () => {
  const b = await startServer({ root: null, port: 0 });
  const write = process.stderr.write;
  let printed = "";
  process.stderr.write = (c) => ((printed += c), true);
  try {
    b.server.emit("error", new Error("boom"));
  } finally {
    process.stderr.write = write;
    await b.close();
  }
  assert.match(printed, /server error: boom/);
});

await check("--port: an empty, non-numeric, negative or too large port is refused with the usage line", async () => {
  for (const bad of ["", "abc", "-1", "70000", "1.5", "0x10"]) {
    const run = runServer(["--port", bad]);
    assert.equal((await run.exit).code, 2, JSON.stringify(bad));
    assert.match(run.stderr, /--port needs a number/);
  }
});

await check("caps: 200 rows per board and 50 open items, the rest left out", () => {
  const rows = Array.from({ length: 250 }, (_, i) => `| T${i} | e | s | h | todo | |`).join("\n");
  const index = "## Open\n" + Array.from({ length: 60 }, (_, i) => `- \`i${i}\` (S) - x`).join("\n") + "\n";
  const r = makeProject(index, { "i0/board.md": BOARD_HEAD + rows + "\n" });
  const s = readState(r, { live: false });
  assert.equal(s.open.length, 50);
  assert.equal(s.open[0].tasks.length, 200);
});

await check("demo: SIGHUP removes the temp folder too", async () => {
  const mine = tmp();
  const run = runServer(["--demo", "--port", "0"], { TMPDIR: mine, TMP: mine, TEMP: mine });
  const created = [];
  try {
    await until(() => /\n/.test(run.stdout));
    created.push(...fs.readdirSync(mine));
    assert.equal(created.length, 1);
  } finally {
    run.child.kill("SIGHUP");
  }
  await run.exit;
  assert.ok(!exists(path.join(mine, created[0])));
});

for (const d of temps) fs.rmSync(d, { recursive: true, force: true });

if (failed > 0) {
  console.log(`FAILED: ${failed} crew-board check${failed === 1 ? "" : "s"} failed`);
  process.exit(1);
}
console.log("all crew-board tests passed");
