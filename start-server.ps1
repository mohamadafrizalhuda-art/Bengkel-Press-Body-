$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$healthUrl = 'http://localhost:3000/api/health'

try {
    Invoke-RestMethod -Uri $healthUrl -TimeoutSec 2 | Out-Null
    exit 0
} catch {
    # Start the local API proxy if it is not already listening.
}

$node = Get-Command node.exe -ErrorAction Stop
$stdout = Join-Path $projectRoot 'backend\server.log'
$stderr = Join-Path $projectRoot 'backend\server-error.log'
Start-Process -FilePath $node.Source -ArgumentList 'backend/app.js' -WorkingDirectory $projectRoot -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr
