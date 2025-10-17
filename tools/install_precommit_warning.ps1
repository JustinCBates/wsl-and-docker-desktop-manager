param(
    [string]$RepoRoot = (Resolve-Path .).Path
)

$hookPath = Join-Path $RepoRoot '.git\hooks\pre-commit'
$script = @'
#!/usr/bin/env pwsh
& "{repo}\tools\precommit_warning.ps1"
exit 0
'@

$content = $script -f @{repo = $RepoRoot}
Set-Content -Path $hookPath -Value $content -Encoding UTF8
Write-Host "Installed non-blocking pre-commit warning hook to $hookPath"
