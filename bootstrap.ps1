# One-shot setup for a fresh machine that already has Claude Code installed
# but no plugins/config yet. Handles: missing git, missing clone, first apply.
#
# Run with:
#   irm https://raw.githubusercontent.com/josh-kum/claude-setup/main/bootstrap.ps1 | iex
# or download this file and run it locally.

$ErrorActionPreference = "Stop"
$repoUrl = "https://github.com/josh-kum/claude-setup.git"
$repoDir = "$env:USERPROFILE\claude-setup"

if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Host "Claude Code CLI not found. Install it first: https://code.claude.com/docs" -ForegroundColor Red
    exit 1
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "git not found - installing via winget..."
        winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
        Write-Host "git installed. Close and reopen this terminal, then re-run bootstrap.ps1." -ForegroundColor Yellow
        exit 0
    } else {
        Write-Host "git not found and winget unavailable. Install Git manually: https://git-scm.com/downloads" -ForegroundColor Red
        exit 1
    }
}

if (Test-Path $repoDir) {
    Write-Host "Repo already exists at $repoDir - pulling latest..."
    Push-Location $repoDir
    git pull
    Pop-Location
} else {
    Write-Host "Cloning $repoUrl to $repoDir..."
    git clone $repoUrl $repoDir
}

Write-Host "Running apply.ps1..."
& "$repoDir\apply.ps1"
