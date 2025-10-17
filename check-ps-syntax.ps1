$ErrorActionPreference = 'Stop'

try {
    $content = Get-Content 'MASTER-REINSTALL.ps1' -Raw
    $errors = $null
    $null = [System.Management.Automation.PSParser]::Tokenize($content, [ref]$errors)
    
    if ($errors) {
        Write-Error "PowerShell syntax errors found:"
        foreach ($syntaxError in $errors) {
            Write-Error "Line $($syntaxError.Token.StartLine): $($syntaxError.Message)"
        }
        exit 1
    } else {
        Write-Output "No PowerShell syntax errors found in MASTER-REINSTALL.ps1"
        exit 0
    }
} catch {
    Write-Error "Error checking syntax: $($_.Exception.Message)"
    exit 1
}