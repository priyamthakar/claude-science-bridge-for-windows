# Remove the Windows login task and stop the proxy. Leaves config.json, keys, and logs.
$ErrorActionPreference = "Continue"
. (Join-Path $PSScriptRoot "windows-lib.ps1")

Stop-BridgeProcess
$taskName = Get-BridgeTaskName
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
[Environment]::SetEnvironmentVariable("ANTHROPIC_BASE_URL", $null, "User")
Write-Output "Removed login task $taskName and user ANTHROPIC_BASE_URL."
Write-Output "Left config.json, API keys, tokens, and logs in place."
