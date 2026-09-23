# Reconciles this machine's Claude Code setup against manifest.json.
# Run manually, or from the weekly scheduled task. Idempotent - safe to re-run.

$ErrorActionPreference = "Stop"
$repoDir = $PSScriptRoot
$manifest = Get-Content "$repoDir\manifest.json" -Raw | ConvertFrom-Json
$markerPath = "$env:USERPROFILE\.claude-setup-applied.json"
$settingsPath = "$env:USERPROFILE\.claude\settings.json"

$lastApplied = if (Test-Path $markerPath) { (Get-Content $markerPath -Raw | ConvertFrom-Json).updated } else { $null }
if ($lastApplied -and ([datetime]$lastApplied -ge [datetime]$manifest.updated)) {
    Write-Host "Already up to date (manifest: $($manifest.updated))."
    exit 0
}

$settings = if (Test-Path $settingsPath) { Get-Content $settingsPath -Raw | ConvertFrom-Json } else { [PSCustomObject]@{} }
if (-not $settings.enabledPlugins) { $settings | Add-Member -NotePropertyName enabledPlugins -NotePropertyValue ([PSCustomObject]@{}) }
if (-not $settings.extraKnownMarketplaces) { $settings | Add-Member -NotePropertyName extraKnownMarketplaces -NotePropertyValue ([PSCustomObject]@{}) }

# Marketplaces
foreach ($name in $manifest.marketplaces.PSObject.Properties.Name) {
    if (-not $settings.extraKnownMarketplaces.PSObject.Properties[$name]) {
        $repo = $manifest.marketplaces.$name.source.repo
        Write-Host "Adding marketplace: $name ($repo)"
        claude plugin marketplace add $repo
    }
}

# Plugins to install
foreach ($p in $manifest.plugins) {
    $installed = $settings.enabledPlugins.PSObject.Properties[$p] -and $settings.enabledPlugins.$p -eq $true
    if (-not $installed) {
        Write-Host "Installing plugin: $p"
        claude plugin install $p
    }
}

# Plugins to keep disabled (only touch if present and currently true)
foreach ($p in $manifest.disabledPlugins) {
    if ($settings.enabledPlugins.PSObject.Properties[$p] -and $settings.enabledPlugins.$p -eq $true) {
        Write-Host "Disabling plugin: $p"
        $settings.enabledPlugins.$p = $false
    }
}

# Version drift check (the plugin CLI has no ref-pinning flag, so this is
# detect-and-warn, not enforce)
foreach ($key in $manifest.expectedVersions.PSObject.Properties.Name) {
    if ($key -eq "note") { continue }
    $installedDir = "$env:USERPROFILE\.claude\plugins\cache\$key"
    if (Test-Path $installedDir) {
        $actual = (Get-ChildItem $installedDir -Directory | Select-Object -First 1).Name
        $expected = $manifest.expectedVersions.$key
        if ($actual -and $actual -ne $expected) {
            Write-Warning "$key: installed $actual, manifest expects $expected (upstream moved - review before trusting new behavior)"
        }
    }
}

# Extra install commands (mods installed outside the plugin marketplace system)
foreach ($cmd in $manifest.extraInstallCommands) {
    Write-Host "Running: $cmd"
    Invoke-Expression $cmd
}

# Env vars (user scope, persistent)
foreach ($name in $manifest.envVars.PSObject.Properties.Name) {
    $want = $manifest.envVars.$name
    $have = [Environment]::GetEnvironmentVariable($name, "User")
    if ($have -ne $want) {
        Write-Host "Setting env var: $name=$want"
        [Environment]::SetEnvironmentVariable($name, $want, "User")
    }
}

# Re-read settings.json fresh (plugin installs above may have modified it) and merge our fields
$settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
foreach ($p in $manifest.disabledPlugins) {
    if ($settings.enabledPlugins.PSObject.Properties[$p]) { $settings.enabledPlugins.$p = $false }
}
$settings.theme = $manifest.theme

# statusLine: resolve the actual installed caveman version instead of hardcoding one
$statuslineScript = Get-ChildItem "$env:USERPROFILE\.claude\plugins\cache\caveman\caveman\*\src\hooks\caveman-statusline.ps1" -ErrorAction SilentlyContinue |
    Sort-Object FullName -Descending | Select-Object -First 1
if ($statuslineScript) {
    $cmd = $manifest.statusLine.commandTemplate.Replace("{CAVEMAN_STATUSLINE_PATH}", $statuslineScript.FullName)
    $settings | Add-Member -NotePropertyName statusLine -NotePropertyValue ([PSCustomObject]@{ type = "command"; command = $cmd }) -Force
}

$settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding utf8

[PSCustomObject]@{ updated = $manifest.updated } | ConvertTo-Json | Set-Content $markerPath -Encoding utf8
Write-Host "Done. Restart Claude Code / open a new terminal for env vars to take effect."
