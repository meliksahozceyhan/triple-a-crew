# Findings
- 2026-10-19 · The T1 researcher, staffed after the plugin reload, still wrote an invented `updated` time
  (`20:30:00Z`, later than the file's last change) although `agents/researcher.md` now says to take it from
  `date -u`; #21's rule is not always followed by sonnet employees · found by T4 reviewer · not filed
