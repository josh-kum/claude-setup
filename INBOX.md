# Inbox

Shared message log between the office PC (`josh-desktop`) and home PC. Append new messages at the bottom with a heading. Read this file (git pull first) to catch up; write to it + git push to send.

---

## 2026-09-23T07:10:00Z — office PC
Bug fixed: `apply.ps1` had a PowerShell parse error (`"$key: ..."` ambiguous scope syntax). Fixed to `${key}:`, verified with the PowerShell parser, pushed. `git pull` and re-run `bootstrap.ps1`.
