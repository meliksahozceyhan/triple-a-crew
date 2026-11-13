#!/usr/bin/env node
// Tests eval graders against saved rows, with no model call.
//
//   node scripts/test-graders.mjs [--root <path>]      check every grader that has rows
//   node scripts/test-graders.mjs --selftest           run only the built-in self-test
//   node scripts/test-graders.mjs harvest <trace.jsonl> <plugin>/<case> [--root <path>] [--force]
//
// Only `regex` graders (trace or final-message target) and `tool_used` graders can be
// checked. Everything else is listed as out of reach. See scripts/grader-rows/README.md.

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

// How a `target: trace` regex sees the session: the rows joined with this string.
// The harness's real joining is not documented; confirm it against a kept trace.
const TRACE_JOIN = "\n";

const TYPES = ["tool_used", "regex", "file_exists", "llm"];
const ROWS_DIR = path.join("scripts", "grader-rows");

// ---------------------------------------------------------------- frontmatter

function parseScalar(raw) {
  const v = raw.trim();
  if (v.startsWith("'")) {
    if (v.length < 2 || !v.endsWith("'")) throw new Error(`unterminated single-quoted string: ${v}`);
    const inner = v.slice(1, -1);
    if (inner.replace(/''/g, "").includes("'")) throw new Error(`lone ' inside single-quoted string: ${v}`);
    return inner.replace(/''/g, "'");
  }
  if (v.startsWith('"')) return JSON.parse(v);
  if (v.startsWith("{")) {
    if (!v.endsWith("}")) throw new Error(`unterminated flow map: ${v}`);
    const out = {};
    const body = v.slice(1, -1).trim();
    if (body === "") return out;
    for (const entry of body.split(/,\s*(?=[A-Za-z_][\w-]*\s*:)/)) {
      const m = /^\s*([A-Za-z_][\w-]*)\s*:\s*(.*)$/.exec(entry);
      if (!m) throw new Error(`bad flow map entry: ${entry}`);
      out[m[1]] = parseScalar(m[2]);
    }
    return out;
  }
  if (/^-?\d+$/.test(v)) return Number(v);
  if (v === "true") return true;
  if (v === "false") return false;
  return v;
}

function parseFrontmatter(text) {
  const lines = text.split(/\r?\n/);
  if (lines[0].trim() !== "---") throw new Error("file does not start with ---");
  const end = lines.findIndex((l, i) => i > 0 && l.trim() === "---");
  if (end < 0) throw new Error("frontmatter is not closed with ---");
  const fm = {};
  for (const line of lines.slice(1, end)) {
    if (line.trim() === "" || line.trim().startsWith("#")) continue;
    const m = /^([A-Za-z_][\w-]*):(?:\s+(.*))?$/.exec(line);
    if (!m) throw new Error(`cannot parse frontmatter line: ${line}`);
    fm[m[1]] = parseScalar(m[2] ?? "");
  }
  return fm;
}

function validateGrader(fm) {
  if (typeof fm.type !== "string") throw new Error("missing type");
  const isInt = (n) => Number.isInteger(n) && n >= 0;
  if (fm.type === "regex") {
    if (typeof fm.pattern !== "string") throw new Error("regex grader needs a pattern");
    const flags = fm.flags ?? "";
    if (typeof flags !== "string" || !/^[dgimsuvy]*$/.test(flags)) throw new Error(`bad flags: ${fm.flags}`);
    if (fm.match !== undefined && !/^(contains|not_contains|count:\d+)$/.test(String(fm.match))) {
      throw new Error(`bad match: ${fm.match}`);
    }
    new RegExp(fm.pattern, flags);
  } else if (fm.type === "tool_used") {
    if (typeof fm.tool !== "string") throw new Error("tool_used grader needs a tool");
    if (fm.input_match !== undefined) new RegExp(String(fm.input_match));
    for (const k of ["min", "max"]) {
      if (fm[k] !== undefined && !isInt(fm[k])) throw new Error(`${k} must be a non-negative integer`);
    }
  }
}

// ------------------------------------------------------------------- loading

function listDirs(dir) {
  if (!fs.existsSync(dir)) return [];
  return fs.readdirSync(dir, { withFileTypes: true }).filter((d) => d.isDirectory()).map((d) => d.name).sort();
}

function loadGraders(root) {
  const graders = [];
  const errors = [];
  const pluginsDir = path.join(root, "plugins");
  for (const plugin of listDirs(pluginsDir)) {
    const evalsDir = path.join(pluginsDir, plugin, "evals");
    for (const evalCase of listDirs(evalsDir)) {
      const gdir = path.join(evalsDir, evalCase, "graders");
      if (!fs.existsSync(gdir)) continue;
      for (const file of fs.readdirSync(gdir).filter((f) => f.endsWith(".md")).sort()) {
        const id = `${plugin}/${evalCase}/${file.slice(0, -3)}`;
        const full = path.join(gdir, file);
        try {
          const fm = parseFrontmatter(fs.readFileSync(full, "utf8"));
          validateGrader(fm);
          graders.push({ id, plugin, evalCase, name: file.slice(0, -3), file: full, fm });
        } catch (e) {
          errors.push(`cannot parse ${path.relative(root, full)}: ${e.message}`);
        }
      }
    }
  }
  return { graders, errors };
}

function checkability(g) {
  const { type, target } = g.fm;
  if (type === "tool_used") return "checkable";
  if (type === "regex") {
    if (target === undefined || target === "trace" || target === "last_message") return "checkable";
    return typeof target === "object" ? "file target" : `target ${target}`;
  }
  return type;
}

function readRows(file) {
  const rows = [];
  const lines = fs.readFileSync(file, "utf8").split(/\r?\n/);
  lines.forEach((line, i) => {
    if (line.trim() === "") return;
    try {
      JSON.parse(line);
    } catch (e) {
      throw new Error(`${file}:${i + 1}: not valid JSON (${e.message})`);
    }
    rows.push(line);
  });
  return rows;
}

// ------------------------------------------------------------------ verdicts

// The final message: the last row's `result`, else its text blocks, else the raw row.
function finalMessage(rows) {
  if (rows.length === 0) return "";
  const raw = rows[rows.length - 1];
  const obj = JSON.parse(raw);
  if (typeof obj.result === "string") return obj.result;
  const content = obj.message?.content ?? obj.content;
  if (typeof content === "string") return content;
  if (Array.isArray(content)) {
    const texts = content.filter((b) => b && b.type === "text" && typeof b.text === "string").map((b) => b.text);
    if (texts.length) return texts.join("\n");
  }
  return raw;
}

function regexTarget(g, rows) {
  return g.fm.target === "trace" ? rows.join(TRACE_JOIN) : finalMessage(rows);
}

function regexMatches(g, text) {
  const flags = g.fm.flags ?? "";
  const re = new RegExp(g.fm.pattern, flags.includes("g") ? flags : flags + "g");
  return [...text.matchAll(re)];
}

function toolCalls(rows) {
  const calls = [];
  const walk = (node, rowIndex) => {
    if (Array.isArray(node)) return node.forEach((n) => walk(n, rowIndex));
    if (!node || typeof node !== "object") return;
    if (typeof node.name === "string" && node.input && typeof node.input === "object") {
      calls.push({ name: node.name, input: node.input, rowIndex });
      return;
    }
    Object.values(node).forEach((n) => walk(n, rowIndex));
  };
  rows.forEach((r, i) => walk(JSON.parse(r), i));
  return calls;
}

function matchingCalls(g, rows) {
  const im = g.fm.input_match === undefined ? null : new RegExp(String(g.fm.input_match));
  return toolCalls(rows).filter((c) => c.name === g.fm.tool && (!im || im.test(JSON.stringify(c.input))));
}

// Returns "pass" or "fail" for a checkable grader on the given rows.
function verdict(g, rows) {
  if (g.fm.type === "tool_used") {
    const n = matchingCalls(g, rows).length;
    const min = g.fm.min ?? 1;
    return n >= min && (g.fm.max === undefined || n <= g.fm.max) ? "pass" : "fail";
  }
  const found = regexMatches(g, regexTarget(g, rows)).length;
  const match = String(g.fm.match ?? "contains");
  if (match === "not_contains") return found === 0 ? "pass" : "fail";
  if (match.startsWith("count:")) return found === Number(match.slice(6)) ? "pass" : "fail";
  return found > 0 ? "pass" : "fail";
}

// ---------------------------------------------------------------- check mode

function rowFiles(root, g) {
  const base = path.join(root, ROWS_DIR, g.plugin, g.evalCase, g.name);
  return { pass: `${base}.pass.jsonl`, fail: `${base}.fail.jsonl` };
}

function run(root) {
  const out = [];
  let bad = 0;
  const log = (s) => out.push(s);
  const problem = (s) => {
    bad++;
    log(s);
  };

  const { graders, errors } = loadGraders(root);
  errors.forEach((e) => problem(`ERROR ${e}`));

  const byType = Object.fromEntries(TYPES.map((t) => [t, 0]));
  let checked = 0;
  let noRows = 0;
  const outOfReach = [];
  const known = new Map(graders.map((g) => [g.id, g]));

  for (const g of graders) {
    byType[g.fm.type] = (byType[g.fm.type] ?? 0) + 1;
    const reach = checkability(g);
    if (reach !== "checkable") {
      outOfReach.push(`${g.id} (${reach})`);
      continue;
    }
    const files = rowFiles(root, g);
    const hasPass = fs.existsSync(files.pass);
    const hasFail = fs.existsSync(files.fail);
    if (!hasPass && !hasFail) {
      noRows++;
      log(`no rows ${g.id}`);
      continue;
    }
    if (hasPass !== hasFail) {
      problem(`ERROR ${g.id}: only ${hasPass ? ".pass.jsonl" : ".fail.jsonl"} exists, both files are needed`);
      continue;
    }
    let passRows;
    let failRows;
    try {
      passRows = readRows(files.pass);
      failRows = readRows(files.fail);
    } catch (e) {
      problem(`ERROR ${g.id}: ${e.message}`);
      continue;
    }
    checked++;
    const wrong = [];
    if (verdict(g, passRows) !== "pass") wrong.push(".pass.jsonl rows do not pass the grader");
    if (verdict(g, failRows) !== "fail") wrong.push(".fail.jsonl rows pass the grader (near miss accepted)");
    if (wrong.length) problem(`WRONG ${g.id}: ${wrong.join("; ")}`);
    else log(`ok    ${g.id} (${passRows.length} pass rows, ${failRows.length} fail rows)`);
  }

  // Rows files that name no checkable grader.
  const rowsRoot = path.join(root, ROWS_DIR);
  for (const plugin of listDirs(rowsRoot)) {
    for (const evalCase of listDirs(path.join(rowsRoot, plugin))) {
      const dir = path.join(rowsRoot, plugin, evalCase);
      for (const f of fs.readdirSync(dir).sort()) {
        const m = /^(.+)\.(pass|fail)\.jsonl$/.exec(f);
        if (!m) continue;
        const id = `${plugin}/${evalCase}/${m[1]}`;
        const g = known.get(id);
        if (!g) problem(`ERROR stale rows ${path.join(ROWS_DIR, plugin, evalCase, f)}: no grader ${id}`);
        else if (checkability(g) !== "checkable") {
          problem(`ERROR rows ${path.join(ROWS_DIR, plugin, evalCase, f)}: grader ${id} cannot be checked (${checkability(g)})`);
        }
      }
    }
  }

  log("");
  log(`parsed ${graders.length} graders: ${TYPES.map((t) => `${t} ${byType[t]}`).join(", ")}`);
  log(`checked ${checked}, no rows ${noRows}, out of reach ${outOfReach.length}`);
  if (outOfReach.length) {
    log("out of reach (never checked):");
    outOfReach.forEach((s) => log(`  ${s}`));
  }
  log(bad ? `FAILED: ${bad} problem(s)` : "all checked graders behave");
  return { code: bad ? 1 : 0, out: out.join("\n"), checked, noRows, outOfReach: outOfReach.length, byType };
}

// -------------------------------------------------------------- harvest mode

function homeRegexes() {
  const home = os.homedir();
  const escaped = JSON.stringify(home).slice(1, -1);
  return [...new Set([home, escaped])].filter((h) => h.length > 1);
}

function scrubHome(line) {
  let s = line;
  for (const h of homeRegexes()) s = s.split(h).join("$HOME");
  return s;
}

function spanRows(g, rows) {
  if (g.fm.type === "tool_used") {
    const idx = [...new Set(matchingCalls(g, rows).map((c) => c.rowIndex))];
    return idx.sort((a, b) => a - b);
  }
  if (g.fm.target !== "trace") return [rows.length - 1];
  const text = rows.join(TRACE_JOIN);
  const starts = [];
  let off = 0;
  for (const r of rows) {
    starts.push(off);
    off += r.length + TRACE_JOIN.length;
  }
  const rowAt = (pos) => {
    let i = 0;
    while (i + 1 < rows.length && starts[i + 1] <= pos) i++;
    return i;
  };
  let matches = regexMatches(g, text);
  if (!String(g.fm.match ?? "").startsWith("count:")) matches = matches.slice(0, 1);
  const set = new Set();
  for (const m of matches) {
    const from = rowAt(m.index);
    const to = rowAt(Math.max(m.index, m.index + m[0].length - 1));
    for (let i = from; i <= to; i++) set.add(i);
  }
  return [...set].sort((a, b) => a - b);
}

function harvest(root, tracePath, caseId, force) {
  const out = [];
  const [plugin, evalCase] = caseId.split("/");
  if (!plugin || !evalCase || caseId.split("/").length !== 2) {
    return { code: 1, out: "error: case must be <plugin>/<case>" };
  }
  let traceRows;
  try {
    traceRows = readRows(tracePath);
  } catch (e) {
    return { code: 1, out: `error: ${e.message}` };
  }
  const { graders, errors } = loadGraders(root);
  if (errors.length) return { code: 1, out: errors.map((e) => `ERROR ${e}`).join("\n") };
  const mine = graders.filter((g) => g.plugin === plugin && g.evalCase === evalCase);
  if (mine.length === 0) return { code: 1, out: `error: no graders found for ${caseId}` };

  const written = [];
  const skipped = [];
  const notPassing = [];
  const nothing = [];
  const cannot = [];
  let code = 0;

  for (const g of mine) {
    if (checkability(g) !== "checkable") {
      cannot.push(`${g.id} (${checkability(g)})`);
      continue;
    }
    if (verdict(g, traceRows) !== "pass") {
      notPassing.push(g.id);
      continue;
    }
    const isNot = g.fm.type === "regex" && String(g.fm.match ?? "") === "not_contains";
    const wantsNone = g.fm.type === "tool_used" && g.fm.max === 0;
    if (isNot || wantsNone) {
      nothing.push(g.id);
      continue;
    }
    let idx = spanRows(g, traceRows);
    const scrub = (ids) => ids.map((i) => scrubHome(traceRows[i]));
    // A lookahead can need rows after the match: grow the span until the grader still passes.
    let rows = scrub(idx);
    let last = idx[idx.length - 1];
    while (idx.length && verdict(g, rows) !== "pass" && last + 1 < traceRows.length) {
      last++;
      idx = [...idx, last];
      rows = scrub(idx);
    }
    if (idx.length === 0 || verdict(g, rows) !== "pass") {
      rows = traceRows.map(scrubHome);
      if (verdict(g, rows) !== "pass") {
        out.push(`ERROR ${g.id}: rows no longer pass after replacing the home folder; write them by hand`);
        code = 1;
        continue;
      }
    }
    const file = rowFiles(root, g).pass;
    if (fs.existsSync(file) && !force) {
      skipped.push(path.relative(root, file));
      continue;
    }
    fs.mkdirSync(path.dirname(file), { recursive: true });
    fs.writeFileSync(file, rows.join("\n") + "\n");
    written.push(`${path.relative(root, file)} (${rows.length} rows)`);
  }

  const section = (title, items) => {
    if (items.length) {
      out.push(title);
      items.forEach((s) => out.push(`  ${s}`));
    }
  };
  section("written:", written);
  section("kept, file exists (use --force to overwrite):", skipped);
  section("did not pass on this trace (no rows written):", notPassing);
  section("nothing to harvest (the grader wants no match):", nothing);
  section("out of reach:", cannot);
  out.push("");
  out.push("Each .fail.jsonl is made by hand: copy the .pass.jsonl rows and remove the wanted text (for a");
  out.push("not_contains grader, put a real row with the forbidden text there and write the pass rows by hand).");
  return { code, out: out.join("\n") };
}

// ------------------------------------------------------------------ self-test

function selftest() {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "test-graders-"));
  const assert = (cond, msg) => {
    if (!cond) throw new Error(`self-test failed: ${msg}`);
  };
  const row = (obj) => JSON.stringify(obj);
  const call = (name, input, parent = null) =>
    row({ type: "assistant", parent_tool_use_id: parent, message: { content: [{ type: "tool_use", name, input }] } });
  const final = (text) => row({ type: "result", result: text });
  const grader = (root, id, fm) => {
    const [plugin, evalCase, name] = id.split("/");
    const dir = path.join(root, "plugins", plugin, "evals", evalCase, "graders");
    fs.mkdirSync(dir, { recursive: true });
    fs.writeFileSync(path.join(dir, `${name}.md`), `---\n${fm}\n---\n\nbody\n`);
  };
  const rows = (root, id, kind, lines, tail = "\n") => {
    const [plugin, evalCase, name] = id.split("/");
    const dir = path.join(root, ROWS_DIR, plugin, evalCase);
    fs.mkdirSync(dir, { recursive: true });
    fs.writeFileSync(path.join(dir, `${name}.${kind}.jsonl`), lines.join("\n") + tail);
  };
  const tree = (name) => {
    const root = path.join(tmp, name);
    fs.mkdirSync(root);
    return root;
  };

  try {
    // A healthy tree: every kind of grader, all correct.
    const good = tree("good");
    grader(good, "p/c/quote", "type: regex\ntarget: trace\nmatch: contains\npattern: 'it''s \\w+ \\{2\\}'");
    rows(good, "p/c/quote", "pass", [row({ text: "it's done {2}" })], "\n\n");
    rows(good, "p/c/quote", "fail", [row({ text: "its done {2}" })]);
    grader(good, "p/c/lookbehind", "type: regex\ntarget: trace\nmatch: not_contains\npattern: '(?<!p)npm test[\\s\\S]*x{2}'");
    rows(good, "p/c/lookbehind", "pass", [row({ text: "pnpm test xx" })]);
    rows(good, "p/c/lookbehind", "fail", [row({ text: "npm test\nxx" })]);
    grader(good, "p/c/flagged", "type: regex\ntarget: trace\nflags: i\npattern: 'ERROR'");
    rows(good, "p/c/flagged", "pass", [row({ text: "an error" })]);
    rows(good, "p/c/flagged", "fail", [row({ text: "all fine" })]);
    grader(good, "p/c/final", "type: regex\npattern: 'SHOP-501'");
    rows(good, "p/c/final", "pass", [call("Bash", { command: "ls" }), final("created SHOP-501")]);
    rows(good, "p/c/final", "fail", [final("SHOP-501 was mentioned earlier"), final("created it")]);
    grader(good, "p/c/twice", 'type: regex\ntarget: trace\nmatch: count:2\npattern: \'"name":"Bash"\'');
    rows(good, "p/c/twice", "pass", [call("Bash", { command: "a" }), call("Bash", { command: "b" })]);
    rows(good, "p/c/twice", "fail", [call("Bash", { command: "a" })]);
    grader(good, "p/c/bounded", "type: tool_used\ntool: Write\ninput_match: 'brief\\.md'\nmin: 1\nmax: 2");
    rows(good, "p/c/bounded", "pass", [call("Write", { file_path: "brief.md" }), call("Edit", { file_path: "x" })]);
    rows(good, "p/c/bounded", "fail", [
      call("Write", { file_path: "brief.md" }),
      call("Write", { file_path: "brief.md" }),
      call("Write", { file_path: "brief.md" }),
    ]);
    grader(good, "p/c/never", "type: tool_used\ntool: Skill\nmin: 0\nmax: 0");
    rows(good, "p/c/never", "pass", [call("Bash", { command: "ls" })]);
    rows(good, "p/c/never", "fail", [call("Skill", { skill: "work" })]);
    grader(good, "p/c/norows", "type: tool_used\ntool: Read");
    grader(good, "p/c/file", "type: regex\ntarget: { source: file, path: .crew/profile.md }\npattern: 'x'");
    grader(good, "p/c/exists", "type: file_exists\npath: a.md");
    grader(good, "p/c/judge", "type: llm");

    let r = run(good);
    assert(r.code === 0, `good tree should exit 0:\n${r.out}`);
    assert(r.checked === 7, `expected 7 checked, got ${r.checked}`);
    assert(r.noRows === 1, `expected 1 no-rows, got ${r.noRows}`);
    assert(r.outOfReach === 3, `expected 3 out of reach, got ${r.outOfReach}`);
    assert(/no rows p\/c\/norows/.test(r.out), "no-rows grader must be reported as no rows");

    // A wrong grader: it matches its own near miss.
    const wrong = tree("wrong");
    grader(wrong, "p/c/loose", "type: regex\ntarget: trace\npattern: 'done'");
    rows(wrong, "p/c/loose", "pass", [row({ text: "all done" })]);
    rows(wrong, "p/c/loose", "fail", [row({ text: "not yet done" })]);
    r = run(wrong);
    assert(r.code === 1, "wrong grader must exit 1");
    assert(/WRONG p\/c\/loose/.test(r.out), `wrong grader must be reported as WRONG:\n${r.out}`);
    console.log(r.out.split("\n").find((l) => l.startsWith("WRONG")) + "   <- planted wrong grader, expected");

    // A grader that rejects its own passing row is wrong too.
    const strict = tree("strict");
    grader(strict, "p/c/strict", "type: regex\ntarget: trace\npattern: 'zzz'");
    rows(strict, "p/c/strict", "pass", [row({ text: "all done" })]);
    rows(strict, "p/c/strict", "fail", [row({ text: "nothing" })]);
    assert(run(strict).code === 1, "grader failing its pass rows must exit 1");

    // Invalid JSON on a line.
    const badJson = tree("badjson");
    grader(badJson, "p/c/g", "type: regex\ntarget: trace\npattern: 'a'");
    rows(badJson, "p/c/g", "pass", [row({ a: 1 }), "{not json"]);
    rows(badJson, "p/c/g", "fail", [row({ b: 1 })]);
    r = run(badJson);
    assert(r.code === 1 && /pass\.jsonl:2: not valid JSON/.test(r.out), `bad JSON must be a clear error:\n${r.out}`);

    // Stale rows for a renamed case; one file only; unparseable grader.
    const stale = tree("stale");
    grader(stale, "p/new/g", "type: regex\ntarget: trace\npattern: 'a'");
    rows(stale, "p/old/g", "pass", [row({ a: 1 })]);
    r = run(stale);
    assert(r.code === 1 && /stale rows/.test(r.out), `stale rows must exit 1:\n${r.out}`);
    const single = tree("single");
    grader(single, "p/c/g", "type: regex\ntarget: trace\npattern: 'a'");
    rows(single, "p/c/g", "pass", [row({ a: 1 })]);
    r = run(single);
    assert(r.code === 1 && /only \.pass\.jsonl exists/.test(r.out), `one file must exit 1:\n${r.out}`);
    const unparsable = tree("unparsable");
    grader(unparsable, "p/c/g", "type: regex\npattern: 'it's broken'");
    r = run(unparsable);
    assert(r.code === 1 && /cannot parse/.test(r.out), `unparseable grader must exit 1:\n${r.out}`);

    // Harvest: rows are scrubbed of the home folder, minimal, and then pass check mode.
    const hv = tree("harvest");
    grader(hv, "p/c/wrote", "type: tool_used\ntool: Write\ninput_match: 'brief\\.md'");
    grader(hv, "p/c/said", "type: regex\ntarget: trace\npattern: 'alpha[\\s\\S]*omega'");
    grader(hv, "p/c/lookahead", "type: regex\ntarget: trace\npattern: 'start(?=[\\s\\S]*\"parent_tool_use_id\":null)'");
    grader(hv, "p/c/absent", "type: regex\ntarget: trace\nmatch: not_contains\npattern: 'forbidden'");
    grader(hv, "p/c/missing", "type: tool_used\ntool: Edit");
    const home = os.homedir();
    const trace = path.join(tmp, "trace.jsonl");
    fs.writeFileSync(
      trace,
      [
        row({ text: "noise" }),
        call("Write", { file_path: `${home}/proj/brief.md` }),
        row({ text: "alpha" }),
        row({ text: "middle" }),
        row({ text: "omega" }),
        row({ text: "start", parent_tool_use_id: "toolu_1" }),
        row({ text: "later", parent_tool_use_id: null }),
        row({ text: "tail" }),
      ].join("\n") + "\n",
    );
    r = harvest(hv, trace, "p/c", false);
    assert(r.code === 0, `harvest should exit 0:\n${r.out}`);
    const pass = (n) => fs.readFileSync(path.join(hv, ROWS_DIR, "p", "c", `${n}.pass.jsonl`), "utf8");
    assert(!pass("wrote").includes(home) && pass("wrote").includes("$HOME/proj/brief.md"), "home path must become $HOME");
    assert(pass("wrote").trim().split("\n").length === 1, "tool_used harvest keeps only the matching row");
    assert(pass("said").trim().split("\n").length === 3, "regex harvest keeps the rows the match spans");
    assert(pass("lookahead").trim().split("\n").length === 2, "regex harvest grows to satisfy a lookahead");
    assert(/did not pass[\s\S]*p\/c\/missing/.test(r.out), "grader that fails on the trace must be listed");
    assert(/nothing to harvest[\s\S]*p\/c\/absent/.test(r.out), "not_contains grader must be listed as nothing to harvest");
    assert(/made by hand/.test(r.out), "harvest must remind about .fail.jsonl");
    fs.writeFileSync(path.join(hv, ROWS_DIR, "p", "c", "wrote.pass.jsonl"), "{}\n");
    r = harvest(hv, trace, "p/c", false);
    assert(fs.readFileSync(path.join(hv, ROWS_DIR, "p", "c", "wrote.pass.jsonl"), "utf8") === "{}\n", "no overwrite without --force");
    harvest(hv, trace, "p/c", true);
    assert(pass("wrote").includes("$HOME"), "--force overwrites");
    rows(hv, "p/c/wrote", "fail", [row({ text: "no brief" })]);
    rows(hv, "p/c/said", "fail", [row({ text: "alpha" })]);
    rows(hv, "p/c/lookahead", "fail", [row({ text: "start" })]);
    r = run(hv);
    assert(/ok    p\/c\/wrote/.test(r.out), `harvested rows must pass check mode:\n${r.out}`);
    assert(r.code === 0, `harvested rows must pass check mode:\n${r.out}`);
    assert(r.noRows === 2, "ungenerated graders stay 'no rows'");
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
  console.log("self-test passed");
}

// ------------------------------------------------------------------------ main

function main(argv) {
  const args = [];
  let root = process.cwd();
  let force = false;
  let only = false;
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === "--root") root = path.resolve(argv[++i] ?? "");
    else if (argv[i] === "--force") force = true;
    else if (argv[i] === "--selftest") only = true;
    else args.push(argv[i]);
  }
  if (only || args[0] !== "harvest") {
    try {
      selftest();
    } catch (e) {
      console.error(e.message);
      return 1;
    }
  }
  if (only) return 0;
  if (args[0] === "harvest") {
    if (args.length !== 3) {
      console.error("usage: test-graders.mjs harvest <trace.jsonl> <plugin>/<case> [--root <path>] [--force]");
      return 1;
    }
    const r = harvest(root, path.resolve(args[1]), args[2], force);
    console.log(r.out);
    return r.code;
  }
  if (args.length) {
    console.error(`unknown argument: ${args[0]}`);
    return 1;
  }
  const r = run(root);
  console.log(r.out);
  return r.code;
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  process.exitCode = main(process.argv.slice(2));
}
