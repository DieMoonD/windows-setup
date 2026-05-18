param(
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
    
# === CONFIG: set these to your repo ===
$githubUser   = "DieMoonD"
$githubRepo   = "windows-setup"
$githubBranch = "main"

$githubBaseUrl = "https://raw.githubusercontent.com/$githubUser/$githubRepo/$githubBranch"

# file names in the repo
$remoteFiles = @{
    "default" = "default-apps.txt"
    "dev"     = "dev-apps.txt"
    "tools"   = "tool-apps.txt"
}

# temp folder for downloaded lists
$baseTempFolder = Join-Path $env:TEMP "temp-windows-setup"
if (-not (Test-Path $baseTempFolder)) {
    New-Item -Path $baseTempFolder -ItemType Directory | Out-Null
}

# === Check winget ===
$wingetCMD = Get-Command winget -ErrorAction SilentlyContinue

if (-not $wingetCMD) {
    Write-Host "winget was not found on this system." -ForegroundColor Red
    $answer = Read-Host "Do you want to try to install/fix winget now? (Y/N)"

    if ($answer -match '^[Yy]$') {
        Write-Host "Attempting to fix or install winget..."
        Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
        Write-Host "Done. Please close this window and open a new PowerShell, then run the script again."
        exit
    }
    else {
        Write-Host "OK, skipping winget installation. Exiting..."
        exit
    }
}
else {
    Write-Host "Winget found at $($wingetCMD.Source)" -ForegroundColor Cyan
}

# === Download all three lists from GitHub ===

$downloadedFiles = @{}

foreach ($key in $remoteFiles.Keys) {
    $fileName = $remoteFiles[$key]
    $url      = "$githubBaseUrl/$fileName"
    $outFile  = Join-Path $baseTempFolder $fileName

    Write-Host "Downloading $fileName from $url ..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $url -OutFile $outFile -UseBasicParsing

    $downloadedFiles[$key] = $outFile
}

# === Menu: which of the downloaded lists to use? ===

Write-Host ""
Write-Host "Choose app list:"
Write-Host "1) default-apps"
Write-Host "2) dev-apps"
Write-Host "3) tool-apps"
Write-Host "4) all"

$userInput = Read-Host "Enter numbers (example: 1,3 or 1,2,3). 4 = all"

$listFiles = @()

$selections = $userInput -split ',' | ForEach-Object { $_.Trim() }

foreach ($choice in $selections) {
    switch ($choice) {
        '1' { $listFiles += $downloadedFiles["default"] }
        '2' { $listFiles += $downloadedFiles["dev"] }
        '3' { $listFiles += $downloadedFiles["tools"] }
        '4' {
            $listFiles += $downloadedFiles["default"]
            $listFiles += $downloadedFiles["dev"]
            $listFiles += $downloadedFiles["tools"]
        }
        default {
            Write-Host "Unknown choice: $choice (skipping)" -ForegroundColor Yellow
        }
    }
}

$listFiles = $listFiles | Select-Object -Unique

if ($listFiles.Count -eq 0) {
    Write-Host "No valid lists selected. Exiting." -ForegroundColor Red
    exit 1
}

try {
    foreach ($listFile in $listFiles) {
        if (-not (Test-Path $listFile)) {
            Write-Host "File '$listFile' not found, skipping." -ForegroundColor Yellow
            continue
        }

        Write-Host "`n=== Processing list: $listFile ===" -ForegroundColor Magenta
        $apps = Get-Content -Path $listFile | Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and -not $_.Trim().StartsWith('#') }

        foreach ($app in $apps) {
            if ([string]::IsNullOrWhiteSpace($app)) { continue }

            Write-Host "`nChecking: $app" -ForegroundColor Cyan

            if (-not $DryRun) {
                $installed = winget list --id $app -e --accept-source-agreements 2>$null
            } else {
                Write-Host "[DRY RUN] Would run: winget list --id $app -e --accept-source-agreements" -ForegroundColor DarkGray
                $installed = $null
                $LASTEXITCODE = 1
            }

            if ($LASTEXITCODE -eq 0 -and $installed) {
                Write-Host "Installed already, trying upgrade: $app" -ForegroundColor Yellow

                if (-not $DryRun) {
                    winget upgrade --id $app -e --silent --accept-source-agreements --accept-package-agreements
                } else {
                    Write-Host "[DRY RUN] Would run: winget upgrade --id $app -e --silent --accept-source-agreements --accept-package-agreements" -ForegroundColor DarkGray
                    $LASTEXITCODE = 0
                }
            }
            else {
                Write-Host "Not installed, installing: $app" -ForegroundColor Green

                if (-not $DryRun) {
                    winget install --id $app -e --silent --accept-source-agreements --accept-package-agreements
                } else {
                    Write-Host "[DRY RUN] Would run: winget install --id $app -e --silent --accept-source-agreements --accept-package-agreements" -ForegroundColor DarkGray
                    $LASTEXITCODE = 0
                }
            }

            if ($LASTEXITCODE -eq 0) {
                Write-Host "Done (simulated if DryRun): $app" -ForegroundColor Green
            }
            else {
                Write-Host "Failed (simulated if DryRun): $app" -ForegroundColor Red
            }
        }
    }

    Write-Host "`nAll done! Checked, installed, or upgraded apps" -ForegroundColor Green
}
finally {
    if (Test-Path $baseTempFolder) {
        Remove-Item $baseTempFolder -Recurse -Force -ErrorAction SilentlyContinue
    }
}