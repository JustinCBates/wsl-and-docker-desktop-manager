$ErrorActionPreference = 'Stop'

try {
    $content = Get-Content 'MASTER-REINSTALL.ps1' -Raw
    $errors = $null
    $null = [System.Management.Automation.PSParser]::Tokenize($content, [ref]$errors)
    
    if ($errors) {
        Write-Host "PowerShell syntax errors found:" -ForegroundColor Red
        foreach ($syntaxError in $errors) {
            Write-Host "Line $($syntaxError.Token.StartLine): $($syntaxError.Message)" -ForegroundColor Red
        }
        exit 1
    } else {
        Write-Host "No PowerShell syntax errors found in MASTER-REINSTALL.ps1" -ForegroundColor Green
        exit 0
    }
} catch {
    Write-Host "Error checking syntax: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}