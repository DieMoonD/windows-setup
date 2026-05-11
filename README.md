# Windows Setup

A small GitHub repo for reinstalling the apps needed on a fresh Windows machine.

## What this repo does

This repo keeps a simple list of apps in `apps.txt` and installs them with `winget` through `install.ps1`.

## Files

- `apps.txt` — app IDs to install, one per line
- `install.ps1` — PowerShell script that reads `apps.txt` and installs the apps
- `README.md` — instructions for using and updating this repo

## How to use

### Run locally

Open PowerShell in this folder and run:

```powershell
.\install.ps1
```

### Run from GitHub

Use the raw PowerShell script URL:

```powershell
irm https://raw.githubusercontent.com/DieMoonD/windows-setup/main/install.ps1 | iex
```

## How to add apps

Find the package ID:

```powershell
winget search steam
```

Example result:

```text
Steam    Valve.Steam
```

Then add it to `apps.txt`:

```text
Valve.Steam
```

## apps.txt format

Use one app per line:

```text
Microsoft.VisualStudioCode
Git.Git
Mozilla.Firefox
Valve.Steam
```

Comments are allowed with `#`:

```text
# Core apps
Microsoft.VisualStudioCode
Git.Git

# Browser
Mozilla.Firefox

# Gaming
Valve.Steam
```

## How to update the repo

After editing files:

```powershell
git add .
git commit -m "Update app list"
git push
```
