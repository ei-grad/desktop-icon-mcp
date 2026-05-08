# Agent Notes

- This repo contains a JS-first desktop-icons MCP server. The MCP entrypoint is `bin/desktop-icon-mcp.js`; PowerShell is only the Windows helper at `scripts/desktop_icon_helper.ps1`.
- Codex loads MCP servers when the session starts. Changes to MCP tool code or tool schemas are not available to the running Codex session until the changes are committed and the Codex session is restarted.
- When changing MCP behavior, commit the change first, then ask the user to restart Codex so the updated server process and schema are loaded.
- Test JS MCP behavior with `npm test`, `node test_optimizer.js`, `node test_tools.js`, and `node smoke_test_js.js`.
- Test live MCP/helper commands outside the sandbox when necessary, for example by piping JSON requests into `scripts/desktop_icon_helper.ps1`; sandboxed one-off runs can fail to see the Explorer desktop host.
- The PowerShell helper must set DPI awareness before Win32 display/ListView calls; otherwise high-DPI desktops can be reported as virtualized 1920x1080 while icon coordinates use the real larger desktop.
- Git index mutations and commits may require outside-sandbox privileges in this workspace. If `git add` or `git commit` fails with `.git/index.lock` permission errors, rerun the same Git command with escalated sandbox permissions.
- Use `src/planner.js` for deterministic layout planning. The legacy `optimize_desktop_islands.js` file is a CLI/module wrapper around that planner.
- Do not commit generated desktop layout JSON files such as `desktop-icons-layout.json` or `desktop-icons-optimized-*.json`; they are local machine state and should remain untracked unless the user explicitly asks otherwise.
