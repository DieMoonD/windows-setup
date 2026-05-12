$ErrorActionPreference = "Stop"

$appsUrl = "https://raw.githubusercontent.com/DieMoonD/windows-setup/main/apps.txt"
$tempApps = Join-Path $env:TEMP "windows-setup-apps.txt"

try {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host "winget was not found on this system." -ForegroundColor Red
        Write-Host "Install or repair App Installer, then run the script again." -ForegroundColor Yellow
        exit 1
    }

    Invoke-WebRequest -Uri $appsUrl -OutFile $tempApps

    $apps = Get-Content $tempApps | Where-Object { $_.Trim() -ne "" -and $_ -notmatch '^\s*#' }

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

    Write-Host "`nAll done! Checked, installed, or upgraded apps from apps.txt." -ForegroundColor Cyan
}
finally {
    if (Test-Path $tempApps) {
        Remove-Item $tempApps -Force -ErrorAction SilentlyContinue
    }
}
