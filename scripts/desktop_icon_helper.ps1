$ErrorActionPreference = "Stop"

[Console]::InputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
$OutputEncoding = [Console]::OutputEncoding

$script:DesktopIconMcpNoLoop = $true
. (Join-Path $PSScriptRoot "..\desktop_icon_mcp.ps1")

function New-HelperResult($Result) {
    [ordered]@{ ok = $true; result = $Result }
}

function New-HelperError([string]$Message) {
    [ordered]@{ ok = $false; error = $Message }
}

function Invoke-HelperCommand([string]$Command, $Arguments) {
    if ($null -eq $Arguments) { $Arguments = [pscustomobject]@{} }
    switch ($Command) {
        "list_icons" {
            return @{ icons = [DesktopIcons]::List() }
        }
        "describe_grid" {
            $hwnd = [DesktopIcons]::FindDesktopListView()
            return (New-DesktopIconGrid $hwnd $Arguments)
        }
        "diagnose_host" {
            return @{ windows = [DesktopIcons]::DiagnoseDesktopHosts() }
        }
        "list_displays" {
            return @{ displays = [DesktopIcons]::Displays() }
        }
        "list_screenshot_formats" {
            return (Get-DesktopScreenshotFormats)
        }
        "capture_screenshot" {
            return (Invoke-DesktopScreenshot $Arguments)
        }
        "move_icon" {
            $hwnd = [DesktopIcons]::FindDesktopListView()
            $indexArg = Get-ArgValue $Arguments "index" -1
            $nameArg = Get-ArgValue $Arguments "name" $null
            $index = [DesktopIcons]::ResolveIndex($hwnd, [int]$indexArg, [string]$nameArg)
            $x = [int](Get-ArgValue $Arguments "x")
            $y = [int](Get-ArgValue $Arguments "y")
            [DesktopIcons]::Move($hwnd, $index, $x, $y)
            return @{ ok = $true; icon = @{ index = $index; name = [DesktopIcons]::GetText($hwnd, $index); x = $x; y = $y } }
        }
        "set_snap_to_grid" {
            $hwnd = [DesktopIcons]::FindDesktopListView()
            $enabled = Get-BoolArg $Arguments "enabled" $true
            [DesktopIcons]::SetSnapToGrid($hwnd, $enabled)
            return @{ ok = $true; enabled = $enabled }
        }
        "get_layout_snapshot" {
            $hwnd = [DesktopIcons]::FindDesktopListView()
            return (New-DesktopLayoutSnapshot $hwnd)
        }
        "apply_layout" {
            $hwnd = [DesktopIcons]::FindDesktopListView()
            $icons = @((Get-ArgValue $Arguments "icons" @()))
            $useIndex = Get-BoolArg $Arguments "use_index" $false
            return (Invoke-DesktopIconPlacement $hwnd $icons $Arguments $useIndex)
        }
        "get_styles" {
            $hwnd = [DesktopIcons]::FindDesktopListView()
            return @{ auto_arrange = [DesktopIcons]::AutoArrange($hwnd); snap_to_grid = [DesktopIcons]::SnapToGrid($hwnd) }
        }
        "set_auto_arrange" {
            $hwnd = [DesktopIcons]::FindDesktopListView()
            $enabled = Get-BoolArg $Arguments "enabled" $false
            [DesktopIcons]::SetAutoArrange($hwnd, $enabled)
            return @{ ok = $true; enabled = $enabled }
        }
        default {
            throw "Unknown helper command: $Command"
        }
    }
}

try {
    $raw = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($raw)) { throw "Expected JSON request on stdin." }
    $request = $raw | ConvertFrom-Json
    $result = Invoke-HelperCommand ([string]$request.command) $request.args
    $response = New-HelperResult $result
} catch {
    $response = New-HelperError $_.Exception.Message
}

[Console]::Out.WriteLine(($response | ConvertTo-Json -Depth 50 -Compress))
