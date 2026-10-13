# One-shot setup for a fresh Windows machine. Installs what is missing
# (git, Node.js, Claude Code CLI), refreshes PATH in this session, clones the
# repo, and runs apply.ps1 with the execution policy bypassed for that one
# process only. No admin shell needed (winget may show its own UAC prompt).
#
# Run in PowerShell:
#   irm https://raw.githubusercontent.com/josh-kum/claude-setup/main/bootstrap.ps1 | iex
#
# Wrapped in a function so `return` ends the script without closing the window
# (a bare `exit` under `| iex` would close the user's PowerShell).

function Invoke-ClaudeSetupBootstrap {
    $ErrorActionPreference = "Stop"
    $repoUrl = "https://github.com/josh-kum/claude-setup.git"
    $repoDir = "$env:USERPROFILE\claude-setup"

    function Update-SessionPath {
        $machine = [Environment]::GetEnvironmentVariable("Path", "Machine")
        $user = [Environment]::GetEnvironmentVariable("Path", "User")
        $env:Path = "$machine;$user"
    }

    function Add-UserPath($dir) {
        $user = [Environment]::GetEnvironmentVariable("Path", "User")
        if (($user -split ";") -notcontains $dir) {
            [Environment]::SetEnvironmentVariable("Path", ($user.TrimEnd(";") + ";" + $dir), "User")
        }
    }

    function Install-WithWinget($id) {
        if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
            Write-Host "winget not available. Install $id manually, then re-run." -ForegroundColor Red
            return $false
        }
        winget install --id $id -e --source winget --accept-package-agreements --accept-source-agreements
        Update-SessionPath
        return $true
    }

    Update-SessionPath

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host "Installing git..."
        [void](Install-WithWinget "Git.Git")
    }
    if (-not (Get-Command npx -ErrorAction SilentlyContinue)) {
        Write-Host "Installing Node.js LTS..."
        [void](Install-WithWinget "OpenJS.NodeJS.LTS")
    }
    if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
        Write-Host "Installing Claude Code CLI (official installer)..."
        Invoke-RestMethod https://claude.ai/install.ps1 | Invoke-Expression
        Add-UserPath "$env:USERPROFILE\.local\bin"
        Update-SessionPath
    }

    foreach ($tool in "git", "npx", "claude") {
        if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
            Write-Host "$tool still not found after install. Open a NEW PowerShell window and run the same command again." -ForegroundColor Yellow
            return
        }
    }

    if (Test-Path "$repoDir\.git") {
        Write-Host "Repo already exists at $repoDir - pulling latest..."
        git -C $repoDir pull
    } else {
        Write-Host "Cloning $repoUrl to $repoDir..."
        git clone $repoUrl $repoDir
    }

    Write-Host "Running apply.ps1..."
    powershell -NoProfile -ExecutionPolicy Bypass -File "$repoDir\apply.ps1"
}

Invoke-ClaudeSetupBootstrap
