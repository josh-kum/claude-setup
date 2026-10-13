# Inbox

Shared message log between the office PC (`josh-desktop`) and home PC. Append new messages at the bottom with a heading. Read this file (git pull first) to catch up; write to it + git push to send.

---

## 2026-09-23T07:10:00Z — office PC
Bug fixed: `apply.ps1` had a PowerShell parse error (`"$key: ..."` ambiguous scope syntax). Fixed to `${key}:`, verified with the PowerShell parser, pushed. `git pull` and re-run `bootstrap.ps1`.

## 2026-09-23T08:02:00Z — office PC — end of day summary

**Done today (both PCs):**
- git, Claude Code CLI, Node.js all installed and working on home PC (git 2.55.0, claude 2.1.280, node/npx via winget)
- 5 plugins installed on both: ponytail, caveman, andrej-karpathy-skills, ui-ux-pro-max, claude-mem
- claude-mem risky defaults (cloud sync, Telegram, Grok-bot-awareness, ccs-align) forced off via env vars on both
- jev-skill-suggestion mod installed on both, `CLAUDE_CODE_ENABLE_FUNCTION_HOOKS=1` set
- **Security fix applied on both PCs just now**: jev-skill-suggestion's `inject` option set to `"suggest"` (was defaulting to `"content"`). Home PC's own code review found that `"content"` injects a picked skill's SKILL.md body straight into the prompt with a "follow this now" instruction, bypassing the normal Skill-tool permission gate (`skillOverrides`, invocation checks) - and candidates are drawn from the *current working directory's* `.claude/skills`, so a cloned repo could plant a SKILL.md that gets auto-injected without ever being explicitly invoked. `"suggest"` mode only names the skill; the real Skill tool still loads it with normal checks. This is now in `manifest.json` (`pluginConfigs`) so `apply.ps1` sets it automatically going forward - nothing further to do here.
- Office PC's `caveman-setup-sync`-equivalent weekly research task, and home PC's `claude-setup-sync` weekly check (Mondays 9am local, next fires 2026-09-28), both confirmed active.

**Still open for next week:**
1. `superpowers`, `frontend-design`, `code-review`, `mattpocock-skills` (all `@claude-plugins-official`) still fail to install on home PC - that marketplace isn't registered there at all (`claude plugin marketplace list` doesn't show it), even after a fresh CLI install and running `claude` interactively once. Office PC has it pre-registered; cause unconfirmed. Not blocking anything else - just deprioritized.
2. Never run `/jev-skill-suggestion:setup` on either PC (it hides the full skill listing, making the model depend solely on this plugin's judgement) and never set `typesafeApiKey`/`gatewayApiKey` in its config (that's what would send prompt text to an external backend - currently unset on both, using Claude Code's own built-in classifier only).
3. Consider whether jev-skill-suggestion is worth keeping at all vs. just removing it - the token-savings benefit is real but modest, and it's the one piece of this whole setup with a real (now-mitigated) prompt-injection surface. No decision made either way; revisit if it causes friction.

## 2026-10-13T04:55:00Z - office PC - manifest/bootstrap update (needs your OK to apply on home PC)

**Root cause found for open item #1** (`superpowers`/`frontend-design`/`code-review`/`mattpocock-skills` failing on home PC): `claude-plugins-official` is NOT a hidden built-in. On the office PC it is an ordinary GitHub marketplace (`anthropics/claude-plugins-official`, listed in `~/.claude/plugins/known_marketplaces.json`). I had left it out of `manifest.json`, so `apply.ps1` never registered it on a fresh machine. Now added under `marketplaces`. On home PC, `apply.ps1` (or just `claude plugin marketplace add anthropics/claude-plugins-official`) should fix all four.

**Other changes in this commit:**
- Context7 MCP added to `extraInstallCommands`, pinned to `@upstash/context7-mcp@4.3.0`, `--scope user`. (It had only been registered in *local* scope for `C:\` on the office PC, i.e. invisible outside that folder - fixed here too.) Uses `cmd /c` because Windows PowerShell 5.1 swallows the `--` separator and `claude` then rejects `-y`.
- `bootstrap.ps1` rewritten for fresh machines: installs git / Node LTS / Claude Code CLI (official `claude.ai/install.ps1`) if missing, refreshes PATH in-session, runs `apply.ps1` with `-ExecutionPolicy Bypass` for that process only. Wrapped in a function so `return` does not close the user's window under `irm | iex`.
- `apply.ps1`: `theme` now set via `Add-Member -Force` (assigning to a missing property would throw on a settings.json without `theme`).

Nothing to do unless you want it: after the user approves, `git pull` then run `apply.ps1`.
