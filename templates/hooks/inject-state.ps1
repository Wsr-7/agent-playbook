# SessionStart hook: inject the project's STATE.md (loop state file) into context.
# Stolen with pride from Trellis's session-start injection — forced context beats
# hoping the model remembers to read the file. Silent no-op when no STATE.md exists.
#
# Install (Claude Code): copy this file to ~/.claude/hooks/, then add to
# ~/.claude/settings.json:
#   "hooks": { "SessionStart": [ { "hooks": [ { "type": "command",
#     "command": "pwsh -NoProfile -File <home>/.claude/hooks/inject-state.ps1",
#     "timeout": 10 } ] } ] }
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$candidates = @('STATE.md', '.local\STATE.md', 'docs\STATE.md')
foreach ($rel in $candidates) {
    $p = Join-Path (Get-Location) $rel
    if (Test-Path $p) {
        Write-Output "[project STATE auto-injected from $rel — current loop state; update it when state changes]"
        Get-Content $p -TotalCount 60 | Write-Output
        break
    }
}
exit 0
