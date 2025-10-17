<#
MANAGER.ps1 - Single root UI manager (canonical)

This file is the single entrypoint in the repository root. It provides a
simple navigable text UI and mocked placeholder functions where the real
install/uninstall/backup/restore logic will be implemented later. The goal is
to let the team implement functionality one unit at a time while keeping the
root UI stable and testable.

Behavior:
- Interactive menu driven UI (Read-Host). Use 'q' to quit.
- Each menu option calls a mocked placeholder function that emits a
  structured hashtable via Write-Phase and returns success.
- No calls to external scripts or destructive actions are performed here.
#>

param(
    [switch]$NonInteractive,
    [string]$Choice
)

$ErrorActionPreference = 'Stop'

function Write-Phase {
    param(
        [Parameter(Mandatory=$true)][string]$Phase,
        [Parameter(Mandatory=$false)][ValidateSet('Info','Success','Warning','Error')] [string]$Level = 'Info',
        [Parameter(Mandatory=$false)][string]$Message = ''
    )
    Write-Output @{ Phase = $Phase; Level = $Level; Message = $Message }
}

# Mocked placeholders - safe, non-destructive
function Mock-Install-WSL {
    Write-Phase -Phase 'Install-WSL' -Level Info -Message 'MOCK: Install WSL called'
    return $true
}

function Mock-Install-Docker {
    Write-Phase -Phase 'Install-Docker' -Level Info -Message 'MOCK: Install Docker called'
    return $true
}

function Mock-Uninstall-WSL {
    Write-Phase -Phase 'Uninstall-WSL' -Level Info -Message 'MOCK: Uninstall WSL called'
    return $true
}

function Mock-Uninstall-Docker {
    Write-Phase -Phase 'Uninstall-Docker' -Level Info -Message 'MOCK: Uninstall Docker called'
    return $true
}

function Mock-Backup-DockerData {
    Write-Phase -Phase 'Backup-Docker' -Level Info -Message 'MOCK: Backup called'
    return @{ Success = $true; Items = @() }
}

function Mock-Restore-DockerData {
    Write-Phase -Phase 'Restore-Docker' -Level Info -Message 'MOCK: Restore called'
    return @{ Success = $true }
}

function Show-Menu {
    Clear-Host
    Write-Output "=== MANAGER - UI (mocked) ==="
    Write-Output "1) Install WSL"
    Write-Output "2) Install Docker"
    Write-Output "3) Uninstall WSL"
    Write-Output "4) Uninstall Docker"
    Write-Output "5) Backup Docker Data"
    Write-Output "6) Restore Docker Data"
    Write-Output "q) Quit"
}

function Handle-Choice {
    param([string]$c)
    switch ($c) {
        '1' { Mock-Install-WSL }
        '2' { Mock-Install-Docker }
        '3' { Mock-Uninstall-WSL }
        '4' { Mock-Uninstall-Docker }
        '5' { Mock-Backup-DockerData }
        '6' { Mock-Restore-DockerData }
        default { Write-Phase -Phase 'UI' -Level Warning -Message "Unknown choice: $c" }
    }
}

if ($NonInteractive) {
    if (-not $Choice) { throw 'NonInteractive requires -Choice' }
    Handle-Choice -c $Choice | Format-List
    return
}

while ($true) {
    Show-Menu
    $sel = Read-Host 'Select an option'
    if ($sel -in 'q','Q','quit','exit') { break }
    $result = Handle-Choice -c $sel
    "`nResult:"
    $result | Format-List
    Write-Host "`nPress Enter to continue..." -NoNewline
    [void] (Read-Host '')
}

Write-Phase -Phase 'Manager' -Level Success -Message 'Exiting MANAGER UI'
