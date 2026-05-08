# Agent Notes

- This repo contains a local desktop-icons MCP server in `desktop_icon_mcp.ps1`.
- Codex loads MCP servers when the session starts. Changes to MCP tool code or tool schemas are not available to the running Codex session until the changes are committed and the Codex session is restarted.
- When changing MCP behavior, commit the change first, then ask the user to restart Codex so the updated server process and schema are loaded.
- Test MCP server commands outside the sandbox when necessary, for example with `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\smoke_test.ps1` or by piping JSON-RPC requests into `desktop_icon_mcp.ps1`; sandboxed one-off runs can fail to see the Explorer desktop host.
- Run optimizer tests with `node test_optimizer.js` after changing layout planning logic.
- Git index mutations and commits may require outside-sandbox privileges in this workspace. If `git add` or `git commit` fails with `.git/index.lock` permission errors, rerun the same Git command with escalated sandbox permissions.
- Use `optimize_desktop_islands.js` for deterministic layout planning. It turns abstract placement preferences into a saved layout JSON; applying that layout is a separate MCP restore step.
- Do not commit generated desktop layout JSON files such as `desktop-icons-layout.json` or `desktop-icons-optimized-*.json`; they are local machine state and should remain untracked unless the user explicitly asks otherwise.
