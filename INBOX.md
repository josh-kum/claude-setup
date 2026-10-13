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

## 2026-10-13T05:15:00Z - office PC - third PC setup result + version review

**Third PC (set up via the chat-driven checklist, not the scripts):** done. Reported versions: ponytail 5.2.0, caveman 3.2.0, ui-ux-pro-max 2.15.0, claude-mem 13.37.0. claude-mem cloud fields (`CLOUD_SYNC_TOKEN/USER_ID/HUB_URL`, `PRO_TRIAL_STATE`, `PRO_MEMORY_KEY`, `TELEGRAM_BOT_TOKEN`) verified empty there; Telegram / Grok-bot x2 / CCS-align env vars verified `false`; theme applied. Did not run `npx claude-mem install` or sign into claude-mem's hosted account.

**Version review (those 4 versions == upstream `origin/main` on 2026-10-13):** diffed the previously vetted commit against `origin/main` for each plugin. ui-ux-pro-max: only a version string. ponytail 5.x: hooks changed a lot; added code has no network/exec/eval; new `ponytail-map.js` builds a local function map from `git ls-files` and injects up to ~2000 chars into context each session. caveman 3.x: no network/exec/eval added in hooks or plugin.json. claude-mem 13.37: the 4 feature flags still exist; **hook bundles are minified and were NOT fully reviewed**.

**Correction to earlier note:** `CLAUDE_MEM_ONLINE_OPTIN=false` is only the *installer* flag that skips claude-mem's hosted sign-in (`npx claude-mem install`); it is not a runtime guard. The real guard is the `CLOUD_SYNC_*` / `PRO_*` fields staying empty. Never run that installer or sign into the hosted account.

**manifest.json:** `expectedVersions` now records the versions above (the office PC itself still runs the older ones: ponytail 4.10.0, caveman 2.7.0, ui-ux-pro-max 2.13.0, claude-mem 13.25.3, so its `apply.ps1` will warn about drift until it is updated). Whether to update the office PC to match is the user's decision.
