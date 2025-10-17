<#
Run Pester tests under PowerShell 7 and ensure Pester 5 is available.
Usage: pwsh -File tools\run_tests_pwsh.ps1
#>

param(
    [string]$TestsPath = "tests"
)

try {
    if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) {
        Write-Error "PowerShell 7 (pwsh) not found. Please install it from https://aka.ms/powershell and re-run this script."
        exit 2
    }

    pwsh -NoProfile -Command {
        if (-not (Get-Module -ListAvailable Pester)) {
            Install-Module -Name Pester -Force -Scope CurrentUser -WarningAction SilentlyContinue
        }
        Import-Module Pester -Force
        Invoke-Pester -Script "$using:TestsPath" -PassThru
    }
} catch {
    Write-Error "Failed to run tests under pwsh: $_"
    exit 1
}
