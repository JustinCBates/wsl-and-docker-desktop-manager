<#
  Non-blocking pre-commit warning hook: warns if a staged commit would add new top-level directories.
  Returns exit code 0 (does not prevent commit).
#>
param()

$repo = (Get-Location).Path
$allow = @('src','docs','tools','tests','.github','.vscode')

$diff = git diff --cached --name-status | ForEach-Object { $_.Trim() }
foreach ($line in $diff) {
    if ($line -match '^A\s+(.+)$') {
        $file = $Matches[1]
        if ($file -match '[\\/]') {
            $top = $file -replace '\\','/' -split '/', 2 | Select-Object -First 1
            if (-not ($allow -contains $top)) {
                Write-Host "WARNING: this commit adds top-level directory: $top" -ForegroundColor Yellow
            }
        }
    }
}

exit 0
