# Agent Notes

- This repo contains a local desktop-icons MCP server in `desktop_icon_mcp.ps1`.
- Codex loads MCP servers when the session starts. Changes to MCP tool code or tool schemas are not available to the running Codex session until the changes are committed and the Codex session is restarted.
- When changing MCP behavior, commit the change first, then ask the user to restart Codex so the updated server process and schema are loaded.
- Use `optimize_desktop_islands.js` for deterministic layout planning. It turns abstract placement preferences into a saved layout JSON; applying that layout is a separate MCP restore step.
