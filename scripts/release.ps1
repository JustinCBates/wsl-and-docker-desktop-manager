<#
Helper PowerShell script to build a local wheel and open the GitHub release creation page
for manual, token-free uploads. Intended for maintainers.

Usage:
  ./scripts/release.ps1 [-OpenRelease]

Options:
  -OpenRelease: If specified, will open the default browser to the new GitHub release page
    (requires `git remote get-url origin` to return an https URL).
#>
param(
    [switch]$OpenRelease
)

Write-Host "Building wheel locally..."
python -m pip install --upgrade pip build | Write-Host
python -m build --wheel --no-isolation | Write-Host

$dist = Get-ChildItem -Path dist -Filter "*.whl" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $dist) {
    Write-Error "No wheel found in ./dist. Build failed or no wheel produced."
    exit 1
}

Write-Host "Built wheel: $($dist.Name)"

if ($OpenRelease) {
    try {
        $remote = git remote get-url origin 2>&1
        if ($LASTEXITCODE -ne 0) { throw "Unable to get origin URL" }
        # Convert git@github.com:owner/repo.git to https://github.com/owner/repo
        $url = $remote.Trim()
        if ($url -match '^git@github.com:(.+)\.git$') {
            $url = "https://github.com/" + $matches[1]
        } elseif ($url -match '^https://github.com/.+\.git$') {
            $url = $url -replace '\.git$',''
        }
        $releaseUrl = "$url/releases/new"
        Write-Host "Opening release page: $releaseUrl"
        Start-Process $releaseUrl
    } catch {
        Write-Warning "Couldn't open release page: $_"
    }
}

Write-Host "Release helper complete. Attach the wheel $($dist.FullName) to a new GitHub release for token-free distribution."