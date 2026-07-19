# Deterministic review gate — TEMPLATE.
# Copy to <your-repo>/scripts/gate.ps1 and replace the CHECK section with your
# project's real commands. review-worker and ship run this before any
# judgment review; exit 0 = PASS, exit 1 = FAIL.
$repo = Split-Path $PSScriptRoot -Parent
Set-Location $repo
$failures = @()
$warnings = @()

Write-Host "[1/2] project checks..."
# --- CHECK section: replace with your project's build/lint/test commands ---
$out = npm test 2>&1   # e.g. npm test / mvn -q verify / pytest -q
if ($LASTEXITCODE -ne 0) {
    $failures += "project checks failed"
    $out | Select-Object -Last 25 | Write-Host
} else {
    Write-Host "  OK"
}
# ---------------------------------------------------------------------------

Write-Host "[2/2] git state..."
$dirty = git status --porcelain
if ($dirty) {
    $failures += "working tree not clean (commit your checkpoints):`n$($dirty -join "`n")"
} else {
    Write-Host "  clean"
}
git rev-parse --abbrev-ref '@{u}' *> $null
if ($LASTEXITCODE -eq 0) {
    $ahead = git rev-list --count '@{u}..HEAD'
    if ([int]$ahead -gt 0) { $warnings += "$ahead unpushed commit(s) on current branch" }
} else {
    $warnings += "current branch has no upstream"
}

Write-Host ""
$warnings | ForEach-Object { Write-Host "WARN: $_" }
if ($failures) {
    $failures | ForEach-Object { Write-Host "FAIL: $_" }
    Write-Host "GATE: FAIL"
    exit 1
}
Write-Host "GATE: PASS"
exit 0
