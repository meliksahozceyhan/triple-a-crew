#!/usr/bin/env node
// Local board for the crew: serves a page and GET /api/state on 127.0.0.1.
//
//   node tools/crew-board/server.mjs [--root <dir>] [--port <n>] [--demo] [--no-live]
//
// Reads .crew/work/ of the project. The only things it writes are <item>/live/ and
// <item>/live/.gitignore for open items. For an item listed under Closed it removes the *.log
// files of live/, then the .gitignore and the folder itself when nothing else is left in it.
// See README.md.

import { createHash } from "node:crypto";
import fs from "node:fs";
import http from "node:http";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { parseIndex, parseBoard, parseStatus, parseLive, taskOf } from "./parse.mjs";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const DEFAULT_PORT = 4777;
const MAX_TEXT = 1024 * 1024;
const MAX_LOG = 8 * 1024 * 1024;
const MAX_ROWS = 200; // board rows per item
const MAX_OPEN = 50; // open items; more are left out
const SAFE_NAME = /^[A-Za-z0-9][A-Za-z0-9._-]*$/;

// The page's inline scripts are allowed by hash, computed from the text that is served.
export function pageCsp(page) {
  const hashes = [];
  for (const m of page.matchAll(/<script\b([^>]*)>([\s\S]*?)<\/script\s*>/gi)) {
    if (/\bsrc\s*=/i.test(m[1])) continue;
    hashes.push(`'sha256-${createHash("sha256").update(m[2]).digest("base64")}'`);
  }
  return [
    "default-src 'none'",
    "style-src 'unsafe-inline'",
    `script-src ${hashes.length ? hashes.join(" ") : "'none'"}`,
    "connect-src 'self'",
    "img-src 'self' data:",
    "frame-ancestors 'none'",
    "base-uri 'none'",
    "form-action 'none'",
  ].join("; ");
}

// ---------------------------------------------------------------- files

// Reads at most `max` bytes of a regular file; null when it cannot be read. With `tail`, the
// last `max` bytes, without the partial first line.
function readText(file, max = MAX_TEXT, tail = false) {
  let fd;
  try {
    // lstat first: a FIFO would block open(), and a symbolic link is never followed.
    if (!fs.lstatSync(file).isFile()) return null;
    fd = fs.openSync(file, "r");
    const st = fs.fstatSync(fd);
    if (!st.isFile()) return null;
    const len = Math.min(st.size, max);
    const start = tail ? st.size - len : 0;
    const buf = Buffer.alloc(len);
    let got = 0;
    while (got < len) {
      const n = fs.readSync(fd, buf, got, len - got, start + got);
      if (n <= 0) break;
      got += n;
    }
    let text = buf.subarray(0, got).toString("utf8");
    if (tail && start > 0) {
      const nl = text.indexOf("\n");
      text = nl < 0 ? "" : text.slice(nl + 1);
    }
    return text;
  } catch {
    return null;
  } finally {
    if (fd !== undefined) {
      try {
        fs.closeSync(fd);
      } catch {
        // nothing to do
      }
    }
  }
}

function lstat(p) {
  try {
    return fs.lstatSync(p);
  } catch {
    return null;
  }
}

const isRealDir = (p) => lstat(p)?.isDirectory() === true;

export function findRoot(from) {
  let dir = path.resolve(from);
  for (;;) {
    if (fs.existsSync(path.join(dir, ".crew", "work", "index.md"))) return dir;
    const up = path.dirname(dir);
    if (up === dir) return null;
    dir = up;
  }
}

// ---------------------------------------------------------------- live/ folders

// Open items get live/ and live/.gitignore. Items listed under Closed (and not also under Open)
// lose their log files; the .gitignore and the folder go only when nothing else is left. Touches
// only a real folder named live directly inside work/<id>/, and no file but *.log and .gitignore.
export function manageLive(root, open, closed) {
  const work = path.join(root, ".crew", "work");
  for (const { id } of open) {
    if (!SAFE_NAME.test(id)) continue;
    const dir = path.join(work, id);
    if (!isRealDir(dir)) continue;
    const live = path.join(dir, "live");
    try {
      const st = lstat(live);
      if (!st) fs.mkdirSync(live);
      else if (!st.isDirectory()) continue;
      const ignore = path.join(live, ".gitignore");
      if (!lstat(ignore)) fs.writeFileSync(ignore, "*\n", { flag: "wx" });
    } catch {
      // read-only project or a race: leave it
    }
  }
  const openIds = new Set(open.map((i) => i.id));
  for (const { id } of closed) {
    if (!SAFE_NAME.test(id) || openIds.has(id)) continue;
    const live = path.join(work, id, "live");
    if (!isRealDir(path.join(work, id)) || !isRealDir(live)) continue;
    try {
      const names = fs.readdirSync(live);
      const logs = names.filter((n) => n.endsWith(".log") && lstat(path.join(live, n))?.isFile());
      const others = names.filter((n) => n !== ".gitignore" && !logs.includes(n));
      for (const n of logs) fs.unlinkSync(path.join(live, n));
      // The .gitignore goes only when the folder is empty without it, so a folder that keeps
      // another file keeps ignoring itself.
      if (others.length === 0) {
        const ignore = path.join(live, ".gitignore");
        if (lstat(ignore)?.isFile()) fs.unlinkSync(ignore);
        if (fs.readdirSync(live).length === 0) fs.rmdirSync(live);
      }
    } catch {
      // leave it
    }
  }
}

// ---------------------------------------------------------------- state

function readAttempt(dir, row) {
  const named = row.statusFile.replace(/`/g, "").trim();
  let rel = null;
  if (named) {
    const m = /(?:^|[\s/])team\/([A-Za-z0-9][A-Za-z0-9._-]*)\.md$/.exec(named);
    if (m) rel = m[1];
  } else if (SAFE_NAME.test(`${row.id}-${row.role}`)) {
    rel = `${row.id}-${row.role}`;
  }

  let status = null;
  if (rel) {
    const text = readText(path.join(dir, "team", `${rel}.md`));
    if (text !== null) status = parseStatus(text);
  }

  let live = null;
  const logName = rel ?? (SAFE_NAME.test(`${row.id}-${row.role}`) ? `${row.id}-${row.role}` : null);
  const liveDir = path.join(dir, "live");
  if (logName && isRealDir(liveDir)) {
    const text = readText(path.join(liveDir, `${logName}.log`), MAX_LOG, true);
    if (text !== null) live = parseLive(text);
  }

  return {
    id: row.id,
    role: row.role,
    model: row.model,
    effort: row.effort,
    boardState: row.boardState,
    status,
    live,
  };
}

function readItem(work, item) {
  const out = { id: item.id, size: item.size, summary: item.summary, phase: "", updated: "", next: "", tasks: [] };
  if (!SAFE_NAME.test(item.id)) return out;
  const dir = path.join(work, item.id);
  const text = readText(path.join(dir, "board.md"));
  if (text === null) return out;
  const board = parseBoard(text);
  out.phase = board.phase;
  out.updated = board.updated;
  out.next = board.next;
  const byTask = new Map();
  for (const row of board.rows.slice(0, MAX_ROWS)) {
    const key = taskOf(row.id);
    if (!byTask.has(key)) {
      const entry = { task: key, attempts: [] };
      byTask.set(key, entry);
      out.tasks.push(entry);
    }
    byTask.get(key).attempts.push(readAttempt(dir, row));
  }
  return out;
}

export function readState(root, { live = true, cwd = process.cwd() } = {}) {
  const state = {
    project: path.basename(root ?? cwd),
    now: new Date().toISOString().replace(/\.\d+Z$/, "Z"),
    open: [],
    closed: [],
  };
  if (!root) return state;
  const work = path.join(root, ".crew", "work");
  const { open, closed } = parseIndex(readText(path.join(work, "index.md")) ?? "");
  if (live) manageLive(root, open, closed);
  state.open = open.slice(0, MAX_OPEN).map((item) => readItem(work, item));
  state.closed = closed.map(({ id, size, note }) => ({ id, size, note }));
  return state;
}

// ---------------------------------------------------------------- http

function send(res, status, type, body, extra = {}) {
  res.writeHead(status, {
    "Content-Type": type,
    "Cache-Control": "no-store",
    "X-Content-Type-Options": "nosniff",
    ...extra,
  });
  res.end(body);
}

const text = (res, status, msg, extra) => send(res, status, "text/plain; charset=utf-8", msg + "\n", extra);

// Starts the board. Resolves to { server, port, close } once it listens on 127.0.0.1.
export function startServer({ root, port = DEFAULT_PORT, live = true } = {}) {
  const server = http.createServer((req, res) => {
    const listening = server.address().port;
    const host = String(req.headers.host ?? "").toLowerCase();
    const bare = listening === 80 && (host === "127.0.0.1" || host === "localhost"); // browsers drop :80
    if (!bare && host !== `127.0.0.1:${listening}` && host !== `localhost:${listening}`) {
      return text(res, 403, "forbidden");
    }
    if (req.method !== "GET") return text(res, 405, "method not allowed", { Allow: "GET" });
    const target = String(req.url ?? "");
    const pathname = target.split(/[?#]/, 1)[0];
    if (pathname === "/api/state") {
      let body;
      try {
        body = JSON.stringify(readState(root, { live }));
      } catch {
        return text(res, 500, "could not read the crew files");
      }
      return send(res, 200, "application/json; charset=utf-8", body);
    }
    if (pathname === "/") {
      const page = readText(path.join(HERE, "index.html"));
      if (page === null) return text(res, 200, "crew-board: the page is not installed yet; see /api/state");
      return send(res, 200, "text/html; charset=utf-8", page, { "Content-Security-Policy": pageCsp(page) });
    }
    return text(res, 404, "not found");
  });

  return new Promise((resolve, reject) => {
    server.once("error", reject);
    server.listen(port, "127.0.0.1", () => {
      server.removeListener("error", reject);
      server.on("error", (err) => process.stderr.write(`crew-board: server error: ${err.message}\n`));
      if (live && root) {
        const { open, closed } = parseIndex(readText(path.join(root, ".crew", "work", "index.md")) ?? "");
        manageLive(root, open, closed);
      }
      resolve({
        server,
        port: server.address().port,
        close: () => new Promise((done) => {
          server.close(() => done());
          server.closeAllConnections();
        }),
      });
    });
  });
}

// ---------------------------------------------------------------- command line

function parseArgs(argv) {
  const opts = { root: null, port: DEFAULT_PORT, demo: false, live: true };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--demo") opts.demo = true;
    else if (a === "--no-live") opts.live = false;
    else if (a === "--root" && i + 1 < argv.length) opts.root = argv[++i];
    else if (a === "--port" && i + 1 < argv.length) {
      const raw = argv[++i];
      const n = Number(raw);
      if (!/^\d+$/.test(raw) || n > 65535) return { error: `--port needs a number from 0 to 65535` };
      opts.port = n;
    } else return { error: `unknown or incomplete argument: ${a}` };
  }
  return opts;
}

async function main() {
  const opts = parseArgs(process.argv.slice(2));
  if (opts.error) {
    process.stderr.write(
      `crew-board: ${opts.error}\nusage: node server.mjs [--root <dir>] [--port <n>] [--demo] [--no-live]\n`,
    );
    process.exit(2);
  }

  let demo = null;
  let root;
  if (opts.demo) {
    const { startDemo } = await import("./demo.mjs");
    demo = startDemo();
    root = demo.root;
  } else {
    root = opts.root ? path.resolve(opts.root) : findRoot(process.cwd());
  }

  if (root && !fs.existsSync(path.join(root, ".crew", "work", "index.md"))) {
    process.stderr.write(`crew-board: warning: no .crew/work/index.md in ${root}; the lists will be empty\n`);
  }

  let board;
  try {
    board = await startServer({ root, port: opts.port, live: opts.live });
  } catch (err) {
    demo?.stop();
    if (err.code === "EADDRINUSE") {
      process.stderr.write(`crew-board: port ${opts.port} is already in use; pick another one with --port <n>\n`);
    } else {
      process.stderr.write(`crew-board: could not start: ${err.message}\n`);
    }
    process.exit(1);
  }

  const name = path.basename(root ?? process.cwd());
  process.stdout.write(`crew-board: http://127.0.0.1:${board.port} (project ${name})\n`);

  const stop = async () => {
    demo?.stop();
    await board.close();
    process.exit(0);
  };
  process.on("SIGINT", stop);
  process.on("SIGTERM", stop);
  process.on("SIGHUP", stop);
}

const isMain = () => {
  try {
    return process.argv[1] && import.meta.url === pathToFileURL(fs.realpathSync(process.argv[1])).href;
  } catch {
    return false;
  }
};

if (isMain()) main();
