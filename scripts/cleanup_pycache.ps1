# cleanup_pycache.ps1
# Removes __pycache__ directories recursively in the repo root
$errors = @()
Get-ChildItem -Path . -Recurse -Directory -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq '__pycache__' } | ForEach-Object {
    try {
        Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction Stop
        Write-Output "Removed: $($_.FullName)"
    } catch {
        Write-Output "Could not remove: $($_.FullName) - $($_.Exception.Message)"
        $errors += $_.FullName
    }
}
if ($errors.Count -gt 0) {
    Write-Output "Some directories could not be removed. Close editors/locks and retry if you want to remove them." 
}
