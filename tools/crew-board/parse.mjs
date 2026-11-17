// Pure parsers for the crew's files: text in, data out. No file access, never throws.

export const LIMITS = {
  progressItems: 50,
  progressText: 300,
  questions: 2000,
  logTarget: 200,
  lastCalls: 8,
};

// Every line is clipped, so no regular expression below runs on more than a few thousand characters.
const MAX_LINE = 4000;
const lines = (text) =>
  String(text ?? "")
    .replace(/\r\n?/g, "\n")
    .split("\n")
    .map((l) => (l.length > MAX_LINE ? l.slice(0, MAX_LINE) : l));
const clip = (s, n) => (s.length > n ? s.slice(0, n) : s);

// ---------------------------------------------------------------- index.md

// Items of the "## Open" and "## Closed" lists. Text between the lists is ignored.
export function parseIndex(text) {
  const open = [];
  const closed = [];
  let section = null;
  for (const line of lines(text)) {
    if (/^##(?:\s|$)/.test(line)) {
      const name = /^##[ \t]+(open|closed)[ \t]*$/i.exec(line)?.[1].toLowerCase();
      section = name ?? null;
      continue;
    }
    if (!section) continue;
    const m = /^\s*[-*]\s+`([^`]+)`\s*(?:\(([^)]*)\))?\s*(?:-\s*(.*))?$/.exec(line);
    if (!m) continue;
    const id = m[1].trim();
    const size = (m[2] ?? "").trim();
    const rest = (m[3] ?? "").trim();
    if (section === "open") {
      const summary = rest.replace(/\s*-\s*updated\s+\S+\s*$/, "").trim();
      open.push({ id, size, summary });
    } else {
      closed.push({ id, size, note: rest });
    }
  }
  return { open, closed };
}

// ---------------------------------------------------------------- board.md

function cells(line) {
  const s = line.trim();
  const out = [];
  let cur = "";
  for (let i = s.startsWith("|") ? 1 : 0; i < s.length; i++) {
    if (s[i] === "\\" && s[i + 1] === "|") {
      cur += "|";
      i++;
    } else if (s[i] === "|") {
      out.push(cur.trim());
      cur = "";
    } else {
      cur += s[i];
    }
  }
  if (cur.trim() !== "" || !s.endsWith("|")) out.push(cur.trim());
  return out;
}

// The value of **Name:** on one line, up to the next " · " field; never the next line.
const field = (all, name, stopAtDot = true) => {
  const re = new RegExp(`\\*\\*${name}:\\*\\*[ \\t]*(.*?)[ \\t]*${stopAtDot ? "(?:·|$)" : "$"}`);
  for (const line of all) {
    const m = re.exec(line);
    if (m) return m[1].trim();
  }
  return "";
};

// Phase, updated, next and the rows of the table, read by header name.
export function parseBoard(text) {
  const all = lines(text);
  const out = { phase: "", updated: "", next: "", rows: [] };
  out.phase = field(all, "Phase");
  out.updated = field(all, "Updated");
  out.next = field(all, "Next", false);

  let header = null;
  for (const line of all) {
    const t = line.trim();
    if (!t.startsWith("|")) {
      if (header) break;
      continue;
    }
    const c = cells(t);
    if (!header) {
      const names = c.map((x) => x.toLowerCase());
      if (names.includes("task")) header = names;
      continue;
    }
    if (c.every((x) => /^:?-+:?$/.test(x) || x === "")) continue;
    const get = (name) => {
      const i = header.indexOf(name);
      return i >= 0 && i < c.length ? c[i] : "";
    };
    const id = get("task");
    if (!id) continue;
    out.rows.push({
      id,
      role: get("role"),
      model: get("model"),
      effort: get("effort"),
      boardState: get("state"),
      statusFile: get("status file"),
    });
  }
  return out;
}

// T2, T2b and T2c belong to task T2; any other id is its own task.
export function taskOf(id) {
  const m = /^(T\d+)[a-z]?$/.exec(id);
  return m ? m[1] : id;
}

// ---------------------------------------------------------------- status file

function sections(all) {
  const map = new Map();
  let current = null;
  for (const line of all) {
    const h = /^##\s+(.+?)\s*$/.exec(line);
    if (h) {
      current = h[1].toLowerCase();
      if (!map.has(current)) map.set(current, []);
      continue;
    }
    if (current) map.get(current).push(line);
  }
  return map;
}

function frontmatter(all) {
  const fm = {};
  if (all[0]?.trim() !== "---") return fm;
  for (let i = 1; i < all.length; i++) {
    const line = all[i];
    if (line.trim() === "---" || /^##\s/.test(line)) break;
    const m = /^([A-Za-z_][\w-]*)\s*:\s*(.*)$/.exec(line);
    if (m) fm[m[1].toLowerCase()] = m[2].replace(/\s+#.*$/, "").trim().replace(/^(['"])(.*)\1$/, "$2");
  }
  return fm;
}

export function parseStatus(text) {
  const all = lines(text);
  const fm = frontmatter(all);
  const sec = sections(all);

  const progress = [];
  const items = [];
  let prev = null;
  for (const line of sec.get("progress") ?? []) {
    const m = /^\s*[-*]\s+(?:\[([ xX])\]\s+)?(.*)$/.exec(line);
    if (m) {
      prev = { done: m[1] === undefined ? null : m[1] !== " ", text: m[2].trim() };
      items.push(prev);
    } else if (line.trim() === "") {
      prev = null;
    } else if (prev) {
      prev.text += " " + line.trim();
    }
  }
  for (const it of items.slice(0, LIMITS.progressItems)) {
    progress.push({ done: it.done, text: clip(it.text, LIMITS.progressText) });
  }

  let questions = (sec.get("questions") ?? []).join("\n").trim();
  if (/^none\.?$/i.test(questions)) questions = "";

  return {
    state: fm.state ?? "",
    updated: fm.updated ?? "",
    progress,
    questions: clip(questions, LIMITS.questions),
  };
}

// ---------------------------------------------------------------- live log

const TIME = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/;

// A line still being written (no newline at the end of the text) is skipped, and so is a line
// that does not have the form <UTC time> TAB <tool> TAB <target>.
export function parseLive(text) {
  const s = String(text ?? "");
  const cut = s.lastIndexOf("\n");
  if (cut < 0) return { calls: 0, last: [] };
  let calls = 0;
  const last = [];
  for (const raw of s.slice(0, cut).split("\n")) {
    const line = raw.replace(/\r$/, "");
    const parts = line.split("\t");
    if (parts.length < 2 || !TIME.test(parts[0]) || !/^\S+$/.test(parts[1])) continue;
    calls++;
    last.push({ at: parts[0], tool: parts[1], target: clip(parts.slice(2).join("\t"), LIMITS.logTarget) });
    if (last.length > LIMITS.lastCalls) last.shift();
  }
  return { calls, last };
}
