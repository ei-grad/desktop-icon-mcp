$ErrorActionPreference = "Stop"

$server = Join-Path $PSScriptRoot "desktop_icon_mcp.ps1"
$requests = @(
    '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05"}}',
    '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}'
)

$requests | powershell.exe -NoProfile -ExecutionPolicy Bypass -File $server
