$ErrorActionPreference = "Stop"

node (Join-Path $PSScriptRoot "smoke_test_js.js")
