# Sync skills from this repo (single source of truth) to agent skill directories.
# Usage: pwsh -NoProfile -File sync.ps1 [-Target claude|codex|all]
param([ValidateSet('claude', 'codex', 'all')][string]$Target = 'all')
$ErrorActionPreference = 'Stop'

$repoSkills = Join-Path $PSScriptRoot 'skills'
$dests = @()
if ($Target -in @('claude', 'all')) { $dests += Join-Path $env:USERPROFILE '.claude\skills' }
if ($Target -in @('codex', 'all')) { $dests += Join-Path $env:USERPROFILE '.codex\skills' }

# Category folders exist only in the repo; targets get a flat skill layout.
$skillDirs = Get-ChildItem $repoSkills -Directory | Get-ChildItem -Directory

foreach ($dest in $dests) {
    New-Item -ItemType Directory -Force $dest | Out-Null
    foreach ($skill in $skillDirs) {
        $targetPath = Join-Path $dest $skill.Name
        if (Test-Path $targetPath) { Remove-Item -Recurse -Force $targetPath }
        Copy-Item -Recurse $skill.FullName $targetPath
    }
    Write-Host ("synced {0} skills -> {1}" -f @($skillDirs).Count, $dest)
}

# Claude Code extras: agent definitions ride along with the claude target.
if ($Target -in @('claude', 'all')) {
    $agentSrc = Join-Path $PSScriptRoot 'templates\agents'
    if (Test-Path $agentSrc) {
        $agentDest = Join-Path $env:USERPROFILE '.claude\agents'
        New-Item -ItemType Directory -Force $agentDest | Out-Null
        Copy-Item "$agentSrc\*.md" $agentDest -Force
        Write-Host ("synced agent defs -> {0}" -f $agentDest)
    }
}
