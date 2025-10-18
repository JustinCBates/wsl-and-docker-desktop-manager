# delete_local_backup_refs.ps1
# Deletes local backup/* branch refs and associated reflogs, then runs git cleanup
$backs = git for-each-ref --format='%(refname:short)' refs/heads/backup
if ($backs) {
    foreach ($b in $backs) {
        Write-Output "Attempting to delete ref and branch: $b"
        # delete ref, branch, and reflog if present
        git update-ref -d "refs/heads/$b" 2>$null
        git branch -D $b 2>$null
        git reflog delete "refs/heads/$b" 2>$null
    }
} else {
    Write-Output "No local backup branch refs found"
}

Write-Output "Expiring reflogs and running git gc..."
git reflog expire --expire=now --all 2>$null
git gc --prune=now 2>$null

$logPath = Join-Path -Path '.git\logs\refs\heads' -ChildPath 'backup'
if (Test-Path $logPath) {
    try {
        Remove-Item -LiteralPath $logPath -Recurse -Force -ErrorAction Stop
        Write-Output "Removed logs: $logPath"
    } catch {
        Write-Output "Could not remove logs: $logPath - $($_.Exception.Message)"
    }
} else {
    Write-Output "No backup logs path present"
}

Write-Output "Local branches after cleanup:"
git for-each-ref --format='%(refname:short)' refs/heads | Sort-Object
