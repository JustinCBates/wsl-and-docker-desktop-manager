param(
    [string]$RepoPath = (Resolve-Path ..).ProviderPath,
    [string]$BackupFile = "acl-backup.acl",
    [switch]$DryRun
)

Write-Host "Restoring ACLs for: $RepoPath from backup: $BackupFile" -ForegroundColor Cyan
if (-not (Test-Path $RepoPath)) { Write-Error "Repo path not found: $RepoPath"; exit 2 }
if (-not (Test-Path $BackupFile)) { Write-Error "Backup file not found: $BackupFile"; exit 2 }

if ($DryRun) {
    Write-Host "DRYRUN: icacls \"$RepoPath\" /restore \"$BackupFile\""
} else {
    icacls "$RepoPath" /restore "$BackupFile"
    Write-Host "ACLs restored." -ForegroundColor Green
}
