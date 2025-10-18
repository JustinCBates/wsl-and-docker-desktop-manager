# List local branches that are ahead of their upstream
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\find_ahead_branches.ps1

git fetch --all --prune
$heads = git for-each-ref --format='%(refname:short) %(upstream:short)' refs/heads
foreach ($line in $heads) {
    $parts = $line -split '\s+',2
    $name = $parts[0]
    $up = if ($parts.Length -gt 1) { $parts[1] } else { '' }
    if ($up -ne '') {
        $counts = git rev-list --left-right --count $up...$name 2>$null
        if ($counts -and $counts -ne '') {
            $c = $counts -split '\s+'
            $behind = [int]$c[0]
            $ahead = [int]$c[1]
            if ($ahead -gt 0) {
                Write-Output "$name $ahead $behind"
            }
        }
    }
}
