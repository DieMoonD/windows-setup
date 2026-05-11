# windows-setup/install.ps1
# One-click Windows app installer from GitHub repo

# Exit on error
$ErrorActionPreference = "Stop"

# Check if winget exists
if (!(Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "Installing winget..." -ForegroundColor Yellow
    Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
}

# Read app list
$apps = Get-Content "apps.txt" | Where-Object { $_ -and $_ -notmatch '^#' }

foreach ($app in $apps) {
    Write-Host "`nInstalling: $app" -ForegroundColor Green
    
    # Run winget install with error handling
    $result = winget install --id $app.Split(' ')[0] --exact --silent --accept-source-agreements --accept-package-agreements --force 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Success" -ForegroundColor Green
    } else {
        Write-Host "✗ Failed (continuing...)" -ForegroundColor Yellow
        Write-Host $result -ForegroundColor Red
    }
}

Write-Host "`nAll done! Check apps.txt for your list." -ForegroundColor Cyan