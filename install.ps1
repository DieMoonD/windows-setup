$ErrorActionPreference = "Stop"

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "winget was not found on this system." -ForegroundColor Red
    Write-Host "Install or repair App Installer, then run the script again." -ForegroundColor Yellow
    exit 1
}

if (-not (Test-Path ".\apps.txt")) {
    Write-Host "apps.txt was not found in this folder." -ForegroundColor Red
    exit 1
}

$apps = Get-Content ".\apps.txt" | Where-Object { $_.Trim() -ne "" -and $_ -notmatch '^\s*#' }

foreach ($app in $apps) {
    Write-Host "`nChecking: $app" -ForegroundColor Cyan

    $installed = winget list --id $app -e --accept-source-agreements 2>$null

    if ($LASTEXITCODE -eq 0 -and $installed) {
        Write-Host "Installed already, trying upgrade: $app" -ForegroundColor Yellow
        winget upgrade --id $app -e --silent --accept-source-agreements --accept-package-agreements
    }
    else {
        Write-Host "Not installed, installing: $app" -ForegroundColor Green
        winget install --id $app -e --silent --accept-source-agreements --accept-package-agreements
    }

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Done: $app" -ForegroundColor Green
    }
    else {
        Write-Host "Failed: $app" -ForegroundColor Red
    }
}

Write-Host "`nAll done!" -ForegroundColor Cyan
