param(
    [string]$RepoPath = (Resolve-Path ..).ProviderPath,
    [string]$BackupFile = "acl-backup.acl",
    [string]$AllowPrincipal = "$env:USERDOMAIN\$env:USERNAME",
    [switch]$DryRun
)

Write-Host "Locking repo ACL at: $RepoPath" -ForegroundColor Cyan
if (-not (Test-Path $RepoPath)) { Write-Error "Repo path not found: $RepoPath"; exit 2 }

# Save current ACLs
Write-Host "Backing up current ACLs to $BackupFile"
if ($DryRun) {
    Write-Host "DRYRUN: icacls \"$RepoPath\" /save \"$BackupFile\" /t"
} else {
    icacls "$RepoPath" /save "$BackupFile" /t | Out-Null
}

# Remove inheritance and remove inherited ACEs
Write-Host "Removing inheritance and inherited ACEs (requires admin)"
if ($DryRun) {
    Write-Host "DRYRUN: Get-Acl -Path $RepoPath; Set-Acl -Path $RepoPath -AclObject <modified-acl>"
} else {
    $acl = Get-Acl -Path $RepoPath
    $acl.SetAccessRuleProtection($true, $false)
    Set-Acl -Path $RepoPath -AclObject $acl
}

# Grant full control to the allow principal (propagate to children)
Write-Host "Granting FullControl to $AllowPrincipal"
if ($DryRun) {
    Write-Host "DRYRUN: icacls \"$RepoPath\" /grant \"${AllowPrincipal}:(OI)(CI)F\""
} else {
    icacls "$RepoPath" /grant "${AllowPrincipal}:(OI)(CI)F" | Out-Null
}

Write-Host "Lock applied. To restore previous ACLs run unlock_repo_acl.ps1 with the backup file." -ForegroundColor Green
