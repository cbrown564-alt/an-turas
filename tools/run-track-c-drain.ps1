# Resumable Track C drain worker for An Turas (run detached via start-track-c-drain-detached.ps1).
$ErrorActionPreference = 'Stop'
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $RepoRoot

$EnvFile = Join-Path $RepoRoot '.env'
if (Test-Path $EnvFile) {
    Get-Content $EnvFile | ForEach-Object {
        if ($_ -match '^\s*#' -or $_ -notmatch '=') { return }
        $name, $value = $_.Split('=', 2)
        Set-Item -Path "Env:$name" -Value $value
    }
}

$env:ANTURAS_CANONICAL_ROOT = $RepoRoot
$env:ANTURAS_CANONICAL_ALLOW_NON_MAIN = '1'

$LogDir = '/tmp/track-c-drain'
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
$Progress = Join-Path $LogDir 'loop.progress.log'
$Result = Join-Path $LogDir 'loop.result.json'
$PidFile = Join-Path $LogDir 'pwsh-drain.pid'

"---- pwsh drain start $(Get-Date -Format o) pid=$PID ----" | Add-Content -Path $Progress
$PID | Set-Content -Path $PidFile

$Python = Join-Path $RepoRoot 'tools/tts-bakeoff/.venv/bin/python'
$Loop = Join-Path $RepoRoot 'tools/run_track_c_batch_loop.py'

& $Python -u $Loop `
    --canonical-root $RepoRoot `
    --payload-id 'd32.harvest.track-b.2026-08-03' `
    --progress-log $Progress `
    --result-json $Result
$Code = $LASTEXITCODE
"---- pwsh drain end $(Get-Date -Format o) exit=$Code ----" | Add-Content -Path $Progress
exit $Code
