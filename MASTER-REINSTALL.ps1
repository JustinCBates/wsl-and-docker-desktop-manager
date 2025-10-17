<#
MASTER-REINSTALL.ps1 - Canonical master orchestrator

This single orchestrator lives at the repository root by project policy.
It performs high-level phases (install/uninstall/complete-reinstall) and
delegates detailed work to scripts under `scripts/`.
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
param(
    [Parameter(Position=0)]
    [ValidateSet("backup", "install-wsl", "install-docker", "install-both", "uninstall-wsl", "uninstall-docker", "uninstall-both", "restore", "complete-reinstall")]
    [string]$Phase,
    
    [string]$BackupPath = "C:\DockerBackup",
    [switch]$SkipBackup = $false,
    [switch]$AutoConfirm = $false,
    [switch]$Force = $false
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

. "$PSScriptRoot\scripts\status\Get-SystemStatus.ps1"

function Write-Header {
    param([string]$Title)
    Write-Output "`n" -NoNewline
    Write-Information (("=" * 60)) -Tags Info
    Write-Information ("  $Title") -Tags Title
    Write-Information (("=" * 60)) -Tags Info
    Write-Output ""
}

function Write-Phase {
    param([string]$Message)
    Write-Information "`nPhase: $Message" -Tags Phase
}

function Test-AdminRights {
    return ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-SystemState {
    $systemStatus = Get-SystemStatus
    return @{
        WSLInstalled = $systemStatus.Summary.WSLReady
        DockerInstalled = $systemStatus.Summary.DockerReady
        BackupExists = $systemStatus.Summary.BackupExists
    }
}

function Invoke-ScriptPhase {
    param(
        [string]$ScriptName,
        [string]$PhaseName,
        [array]$Arguments = @()
    )
    Write-Phase "Starting: $PhaseName"
    try {
        # Preferred paths to search for the script. Use file existence checks
        # (System.IO.File) because Test-Path may be mocked in unit tests.
        $candidates = @()
        if ([System.IO.Path]::IsPathRooted($ScriptName)) {
            $candidates += $ScriptName
        } else {
            $candidates += Join-Path $PSScriptRoot "scripts\$ScriptName"
            $candidates += Join-Path $PSScriptRoot $ScriptName
            $candidates += Join-Path (Get-Location) $ScriptName
            $candidates += Join-Path $PSScriptRoot "tests\unit\$ScriptName"
        }

        $scriptPath = $null
        foreach ($candidate in $candidates) {
            if ([System.IO.File]::Exists($candidate)) { $scriptPath = $candidate; break }
        }

        if (-not $scriptPath) {
            throw "Script not found: searched: $($candidates -join '; ')"
        }

        # Invoke the resolved script
        & $scriptPath @Arguments

        Write-Information "$PhaseName completed successfully" -Tags Success
        return $true
    } catch {
        Write-Error "$PhaseName failed: $_"
        throw
    }
}

function Show-SystemStatus {
    $systemState = Get-SystemState
    Write-Header "Current System Status"
    Write-Output "WSL Status:    " -NoNewline
    if ($systemState.WSLInstalled) { Write-Output "Installed" } else { Write-Output "Not Installed" }
    Write-Output "Docker Status: " -NoNewline
    if ($systemState.DockerInstalled) { Write-Output "Installed" } else { Write-Output "Not Installed" }
    Write-Output "Backup Status: " -NoNewline
    if ($systemState.BackupExists) { Write-Output "Available at $BackupPath" } else { Write-Output "No backup found" }
    return $systemState
}

## If this file is dot-sourced (e.g. by unit tests) expose functions only and stop
if ($MyInvocation.InvocationName -eq '.') {
    return
}

try {
    Write-Header "WSL and Docker Desktop Manager"
    if (-not (Test-AdminRights)) { throw "This script requires administrator privileges. Please run as administrator." }
    $systemState = Show-SystemStatus
    switch ($Phase) {
        "backup" {
            Write-Header "Backup Docker Data - REMOVED"
            Write-Information "Backup functionality has been removed from this repository." -Tags Info
        }
        "install-wsl" {
            Write-Header "Install WSL Only"
            $args = @(); if ($Force) { $args += "-Force" }
            $result = Invoke-ScriptPhase -ScriptName "Install-Orchestrator.ps1" -PhaseName "WSL Installation" -Arguments ((@("-Target","wsl-only")) + $args)
            if ($result -eq "restart") { exit 0 }
        }
        "install-docker" {
            Write-Header "Install Docker Only"
            $args = @(); if ($Force) { $args += "-Force" }
            Invoke-ScriptPhase -ScriptName "Install-Orchestrator.ps1" -PhaseName "Docker Installation" -Arguments $args
        }
        "install-both" {
            Write-Header "Install WSL and Docker"
            $args = @(); if ($Force) { $args += "-Force" }
            $result = Invoke-ScriptPhase -ScriptName "Install-Orchestrator.ps1" -PhaseName "WSL and Docker Installation" -Arguments ((@("-Target","both")) + $args)
            if ($result -eq "restart") { exit 0 }
        }
        "uninstall-wsl" {
            Write-Header "Uninstall WSL Only"
            $args = @("-Target","wsl-only","-BackupPath",$BackupPath); if ($Force) { $args += "-Force" }; if ($SkipBackup) { $args += "-SkipBackup" }
            $result = Invoke-ScriptPhase -ScriptName "Uninstall-Orchestrator.ps1" -PhaseName "WSL Uninstallation" -Arguments $args
            if ($result -eq "restart") { exit 0 }
        }
        "uninstall-docker" {
            Write-Header "Uninstall Docker Only"
            $args = @("-Target","docker-only","-BackupPath",$BackupPath); if ($Force) { $args += "-Force" }; if ($SkipBackup) { $args += "-SkipBackup" }
            Invoke-ScriptPhase -ScriptName "Uninstall-Orchestrator.ps1" -PhaseName "Docker Uninstallation" -Arguments $args
        }
        "uninstall-both" {
            Write-Header "Uninstall WSL and Docker"
            $args = @("-Target","both","-BackupPath",$BackupPath); if ($Force) { $args += "-Force" }; if ($SkipBackup) { $args += "-SkipBackup" }
            $result = Invoke-ScriptPhase -ScriptName "Uninstall-Orchestrator.ps1" -PhaseName "Complete Uninstallation" -Arguments $args
            if ($result -eq "restart") { exit 0 }
        }
        "restore" {
            Write-Header "Restore Docker Data - REMOVED"
            Write-Error "Restore functionality has been removed from this repository." 
        }
        "complete-reinstall" {
            Write-Header "Complete Reinstall (Uninstall + Install)"
            $uninstallArgs = @("-Target","both","-BackupPath",$BackupPath,"-SkipBackup"); if ($Force) { $uninstallArgs += "-Force" }
            $result = Invoke-ScriptPhase -ScriptName "Uninstall-Orchestrator.ps1" -PhaseName "Complete Uninstallation" -Arguments $uninstallArgs
            if ($result -eq "restart") { Write-Warning "`nRestart required."; exit 0 }
            $installArgs = @("-Target","both"); if ($Force) { $installArgs += "-Force" }
            $result = Invoke-ScriptPhase -ScriptName "Install-Orchestrator.ps1" -PhaseName "Fresh Installation" -Arguments $installArgs
            if ($result -eq "restart") { exit 0 }
            if ($systemState.BackupExists -and -not $SkipBackup) {
                $restoreArgs = @("-BackupPath", $BackupPath); if ($Force) { $restoreArgs += "-Force" }
                Invoke-ScriptPhase -ScriptName "backup\Restore-Data.ps1" -PhaseName "Data Restore" -Arguments $restoreArgs
            }
        }
        default {
            Write-Error "Invalid or missing phase parameter"
            Write-Output "`nUsage: .\MASTER-REINSTALL.ps1 [phase] [options]"
            exit 1
        }
    }
    Write-Header "Operation Completed Successfully"
    Write-Information "All operations completed successfully!" -Tags Success
    exit 0
} catch {
    Write-Error "Operation failed: $_"
    exit 1
}