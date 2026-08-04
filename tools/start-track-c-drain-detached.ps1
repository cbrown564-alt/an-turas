# Start Track C drain as a detached PowerShell process hosted by screen.
# plain nohup is reaped when the parent Cursor shell exits on this host.
$ErrorActionPreference = 'Stop'
$Pwsh = Join-Path $HOME '.local/powershell/pwsh'
if (-not (Test-Path $Pwsh)) {
    throw "pwsh not found at $Pwsh"
}
$Script = Join-Path $PSScriptRoot 'run-track-c-drain.ps1'
$LogDir = '/tmp/track-c-drain'
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

& /bin/bash -lc @"
screen -S track-c-drain -X quit 2>/dev/null || true
pkill -f run_track_c_batch_loop.py 2>/dev/null || true
pkill -f run-track-c-drain.ps1 2>/dev/null || true
sleep 2
echo \"---- screen+pwsh restart `$(date -u +%Y-%m-%dT%H:%M:%SZ) ----\" >> '$LogDir/loop.progress.log'
screen -dmS track-c-drain '$Pwsh' -NoProfile -NonInteractive -File '$Script'
sleep 2
screen -ls
pgrep -f run-track-c-drain.ps1 > '$LogDir/pwsh-launcher.pid' || true
pgrep -f run_track_c_batch_loop.py > '$LogDir/python-loop.pid' || true
echo started_screen=track-c-drain
echo pwsh_pid=`$(cat '$LogDir/pwsh-launcher.pid' 2>/dev/null | tr '\n' ' ')
"@

Write-Output "progress_log=$LogDir/loop.progress.log"
Write-Output "result_json=$LogDir/loop.result.json"
