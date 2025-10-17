# Parameters available for command-line invocation (used by MVP and other callers)
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

# Set error handling
$ErrorActionPreference = "Stop"

# Set console encoding for proper emoji display
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Import status functions
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
    Write-Information "`nðŸ“‹ $Message" -Tags Phase
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
        $scriptPath = Join-Path $PSScriptRoot "scripts\$ScriptName"
        if (-not (Test-Path $scriptPath)) {
            throw "Script not found: $scriptPath"
        }
        
        $result = & $scriptPath @Arguments
        
        Write-Information "âœ… $PhaseName completed successfully" -Tags Success
        return $result
    }
    catch {
        Write-Error "âŒ $PhaseName failed: $_"
        throw
    }
}

function Show-SystemStatus {
    $systemState = Get-SystemState
    
    Write-Header "Current System Status"
    Write-Output "WSL Status:    " -NoNewline
    if ($systemState.WSLInstalled) {
        Write-Information "âœ… Installed" -Tags Status
    } else {
        Write-Error "âŒ Not Installed"
    }
    
    Write-Output "Docker Status: " -NoNewline
    if ($systemState.DockerInstalled) {
        Write-Information "âœ… Installed" -Tags Status
    } else {
        Write-Error "âŒ Not Installed"
    }
    
    Write-Output "Backup Status: " -NoNewline
    if ($systemState.BackupExists) {
        Write-Information "âœ… Available at $BackupPath" -Tags Status
    } else {
        Write-Warning "âŒ No backup found"
    }
    
    return $systemState
}

# Main execution logic
try {
    Write-Header "WSL and Docker Desktop Manager v2.0"
    
    if (-not (Test-AdminRights)) {
        throw "This script requires administrator privileges. Please run as administrator."
    }
    
    $systemState = Show-SystemStatus
    
    # Execute based on phase
    switch ($Phase) {
        "backup" {
            Write-Header "Backup Docker Data"
            $backupArgs = @("-BackupPath", $BackupPath)
            if ($Force) { $backupArgs += "-Force" }
            Invoke-ScriptPhase -ScriptName "backup\Backup-Data.ps1" -PhaseName "Data Backup" -Arguments $backupArgs
        }
        
        "install-wsl" {
            Write-Header "Install WSL Only"
            $args = @()
            if ($Force) { $args += "-Force" }
            $result = Invoke-ScriptPhase -ScriptName "Install-Orchestrator.ps1" -PhaseName "WSL Installation" -Arguments (@("-Target", "wsl-only") + $args)
            if ($result -eq "restart") { exit 0 }
        }
        
        "install-docker" {
            Write-Header "Install Docker Only"
            $args = @()
            if ($Force) { $args += "-Force" }
            Invoke-ScriptPhase -ScriptName "Install-Orchestrator.ps1" -PhaseName "Docker Installation" -Arguments (@("-Target", "docker-only") + $args)
        }
        
        "install-both" {
            Write-Header "Install WSL and Docker"
            $args = @()
            if ($Force) { $args += "-Force" }
            $result = Invoke-ScriptPhase -ScriptName "Install-Orchestrator.ps1" -PhaseName "WSL and Docker Installation" -Arguments (@("-Target", "both") + $args)
            if ($result -eq "restart") { exit 0 }
        }
        
        "uninstall-wsl" {
            Write-Header "Uninstall WSL Only"
            $args = @("-Target", "wsl-only", "-BackupPath", $BackupPath)
            if ($Force) { $args += "-Force" }
            if ($SkipBackup) { $args += "-SkipBackup" }
            $result = Invoke-ScriptPhase -ScriptName "Uninstall-Orchestrator.ps1" -PhaseName "WSL Uninstallation" -Arguments $args
            if ($result -eq "restart") { exit 0 }
        }
        
        "uninstall-docker" {
            Write-Header "Uninstall Docker Only"
            $args = @("-Target", "docker-only", "-BackupPath", $BackupPath)
            if ($Force) { $args += "-Force" }
            if ($SkipBackup) { $args += "-SkipBackup" }
            Invoke-ScriptPhase -ScriptName "Uninstall-Orchestrator.ps1" -PhaseName "Docker Uninstallation" -Arguments $args
        }
        
        "uninstall-both" {
            Write-Header "Uninstall WSL and Docker"
            $args = @("-Target", "both", "-BackupPath", $BackupPath)
            if ($Force) { $args += "-Force" }
            if ($SkipBackup) { $args += "-SkipBackup" }
            $result = Invoke-ScriptPhase -ScriptName "Uninstall-Orchestrator.ps1" -PhaseName "Complete Uninstallation" -Arguments $args
            if ($result -eq "restart") { exit 0 }
        }
        
        "restore" {
            Write-Header "Restore Docker Data"
            if (-not $systemState.BackupExists) {
                throw "No backup found at $BackupPath"
            }
            $restoreArgs = @("-BackupPath", $BackupPath)
            if ($Force) { $restoreArgs += "-Force" }
            Invoke-ScriptPhase -ScriptName "backup\Restore-Data.ps1" -PhaseName "Data Restore" -Arguments $restoreArgs
        }
        
        "complete-reinstall" {
            Write-Header "Complete Reinstall (Uninstall + Install)"
            
            # Backup first if not skipped and Docker is installed
            if (-not $SkipBackup -and $systemState.DockerInstalled) {
                $backupArgs = @("-BackupPath", $BackupPath)
                if ($Force) { $backupArgs += "-Force" }
                Invoke-ScriptPhase -ScriptName "backup\Backup-Data.ps1" -PhaseName "Data Backup" -Arguments $backupArgs
            }
            
            # Uninstall everything
            $uninstallArgs = @("-Target", "both", "-BackupPath", $BackupPath, "-SkipBackup")
            if ($Force) { $uninstallArgs += "-Force" }
            $result = Invoke-ScriptPhase -ScriptName "Uninstall-Orchestrator.ps1" -PhaseName "Complete Uninstallation" -Arguments $uninstallArgs
            if ($result -eq "restart") { 
                Write-Warning "`nâš ï¸  System restart required. Please restart and run install phase manually."
                exit 0 
            }
            
            # Install everything
            $installArgs = @("-Target", "both")
            if ($Force) { $installArgs += "-Force" }
            $result = Invoke-ScriptPhase -ScriptName "Install-Orchestrator.ps1" -PhaseName "Fresh Installation" -Arguments $installArgs
            if ($result -eq "restart") { exit 0 }
            
            # Restore data if backup exists
            if ($systemState.BackupExists -and -not $SkipBackup) {
                $restoreArgs = @("-BackupPath", $BackupPath)
                if ($Force) { $restoreArgs += "-Force" }
                Invoke-ScriptPhase -ScriptName "backup\Restore-Data.ps1" -PhaseName "Data Restore" -Arguments $restoreArgs
            }
        }
        
        default {
            Write-Error "âŒ Invalid or missing phase parameter"
            Write-Output "`nUsage: .\MASTER-REINSTALL-v2.ps1 [phase] [options]"
            Write-Output "`nAvailable phases:"
            Write-Output "  backup              - Backup Docker data only"
            Write-Output "  install-wsl         - Install WSL only"
            Write-Output "  install-docker      - Install Docker only"
            Write-Output "  install-both        - Install WSL and Docker"
            Write-Output "  uninstall-wsl       - Uninstall WSL only"
            Write-Output "  uninstall-docker    - Uninstall Docker only"
            Write-Output "  uninstall-both      - Uninstall WSL and Docker"
            Write-Output "  restore             - Restore Docker data from backup"
            Write-Output "  complete-reinstall  - Full backup, uninstall, and reinstall"
            Write-Output "`nOptions:"
            Write-Output "  -BackupPath [path]  - Custom backup location (default: C:\DockerBackup)"
            Write-Output "  -SkipBackup         - Skip backup operations"
            Write-Output "  -Force              - Force operations without prompts"
            Write-Output "  -AutoConfirm        - Automatically confirm all prompts"
            exit 1
        }
    }
    
    Write-Header "Operation Completed Successfully"
    Write-Information "ðŸŽ‰ All operations completed successfully!" -Tags Success
    
    exit 0
}
catch {
    Write-Error "`nâŒ Operation failed: $_"
    exit 1
}