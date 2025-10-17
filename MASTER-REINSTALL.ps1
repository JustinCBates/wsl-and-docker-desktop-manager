# Master Docker & WSL Reinstallation Script
# This script orchestrates the complete reinstallation process
# Run as Administrator

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
param(
    [ValidateSet("backup", "uninstall-docker", "uninstall-wsl", "install-wsl", "install-docker", "restore", "all")]
    [string]$Phase = "all",
    [string]$BackupPath = "C:\DockerWSLReinstall\$(Get-Date -Format 'yyyy-MM-dd-HHmm')",
    [switch]$SkipBackup = $false,
    [switch]$AutoConfirm = $false,
    [switch]$Force = $false
)

# Check for admin privileges
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "âŒ This script requires Administrator privileges" -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again" -ForegroundColor Yellow
    exit 1
}

Write-Host "ðŸš€ Docker & WSL Complete Reinstallation Master Script" -ForegroundColor Green
Write-Host "ðŸ“ Working directory: $(Get-Location)" -ForegroundColor Yellow
Write-Host "ðŸ’¾ Backup path: $BackupPath" -ForegroundColor Yellow

# Function to run script with error handling
function Invoke-ScriptPhase {
    param(
        [string]$ScriptName,
        [string]$PhaseName,
        [string[]]$Arguments = @(),
        [switch]$RequireRestart = $false
    )
    
    Write-Host "`nðŸ”„ Starting Phase: $PhaseName" -ForegroundColor Cyan
    Write-Host "ðŸ“œ Script: $ScriptName" -ForegroundColor White
    
    if (-not (Test-Path $ScriptName)) {
        Write-Host "âŒ Script not found: $ScriptName" -ForegroundColor Red
        return $false
    }
    
    try {
        if ($Arguments.Count -gt 0) {
            Write-Host "âš™ï¸  Arguments: $($Arguments -join ' ')" -ForegroundColor Gray
            & ".\$ScriptName" @Arguments
        } else {
            & ".\$ScriptName"
        }
        
        if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
            Write-Host "âš ï¸  Script completed with warnings (exit code: $LASTEXITCODE)" -ForegroundColor Yellow
        } else {
            Write-Host "âœ… Phase completed: $PhaseName" -ForegroundColor Green
        }
        
        if ($RequireRestart) {
            Write-Host "`nðŸ”„ RESTART REQUIRED" -ForegroundColor Red
            Write-Host "Please restart your computer and run this script again with the next phase" -ForegroundColor Yellow
            Write-Host "Next command: .\MASTER-REINSTALL.ps1 -Phase install-wsl" -ForegroundColor White
            return "restart"
        }
        
        return $true
    } catch {
        Write-Host "âŒ Phase failed: $PhaseName" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
        return $false
    }
}

# Function to check system state
function Test-SystemState {
    $state = @{
        DockerInstalled = $false
        WSLInstalled = $false
        WSL2Available = $false
        BackupExists = $false
    }
    
    # Check Docker
    try {
        docker --version | Out-Null
        $state.DockerInstalled = $true
    } catch {}
    
    # Check WSL
    try {
        wsl --list | Out-Null
        $state.WSLInstalled = $true
        
        $wslStatus = wsl --list --verbose 2>$null
        if ($wslStatus -match "VERSION\s+2") {
            $state.WSL2Available = $true
        }
    } catch {}
    
    # Check backup
    if (Test-Path "$BackupPath\*") {
        $state.BackupExists = $true
    }
    
    return $state
}

# Function to display system state
function Show-SystemState {
    param($State)
    
    Write-Host "`nðŸ“Š Current System State:" -ForegroundColor Cyan
    Write-Host "  ðŸ³ Docker Desktop: $(if ($State.DockerInstalled) { 'âœ… Installed' } else { 'âŒ Not Installed' })" -ForegroundColor White
    Write-Host "  ðŸ§ WSL: $(if ($State.WSLInstalled) { 'âœ… Installed' } else { 'âŒ Not Installed' })" -ForegroundColor White
    Write-Host "  ðŸ”§ WSL 2: $(if ($State.WSL2Available) { 'âœ… Available' } else { 'âŒ Not Available' })" -ForegroundColor White
    Write-Host "  ðŸ’¾ Backup: $(if ($State.BackupExists) { 'âœ… Found' } else { 'âŒ Not Found' })" -ForegroundColor White
}

# Main execution logic
$systemState = Test-SystemState
Show-SystemState -State $systemState

if ($Phase -eq "all" -and -not $AutoConfirm) {
    Write-Host "`nâš ï¸  COMPLETE REINSTALLATION WARNING" -ForegroundColor Red
    Write-Host "This will completely remove and reinstall Docker Desktop and WSL 2" -ForegroundColor Yellow
    Write-Host "ALL Docker containers, images, and WSL distributions will be deleted!" -ForegroundColor Yellow
    
    $confirm = Read-Host "`nAre you absolutely sure you want to continue? (type 'YES' to confirm)"
    if ($confirm -ne "YES") {
        Write-Host "âŒ Operation cancelled" -ForegroundColor Yellow
        exit 0
    }
}

# Execute phases based on selection
switch ($Phase) {
    "backup" {
        Write-Host "`nðŸ“‹ Phase: Backup Only" -ForegroundColor Green
        
        if ($systemState.DockerInstalled) {
            $backupArgs = @("-BackupPath", $BackupPath)
            if ($Force) { $backupArgs += "-Force" }
            
            $result = Invoke-ScriptPhase -ScriptName "BACKUP-DOCKER-DATA.ps1" -PhaseName "Docker Data Backup" -Arguments $backupArgs
            if ($result -eq $false) {
                Write-Host "âŒ Backup failed, aborting" -ForegroundColor Red
                exit 1
            }
        } else {
            Write-Host "â„¹ï¸  Docker not installed, skipping backup" -ForegroundColor Blue
        }
    }
    
    "uninstall-docker" {
        Write-Host "`nðŸ“‹ Phase: Uninstall Docker Only" -ForegroundColor Green
        
        if ($systemState.DockerInstalled) {
            $uninstallArgs = @()
            if ($Force) { $uninstallArgs += "-Force" }
            
            $result = Invoke-ScriptPhase -ScriptName "UNINSTALL-DOCKER-DESKTOP.ps1" -PhaseName "Docker Desktop Uninstall" -Arguments $uninstallArgs
        } else {
            Write-Host "â„¹ï¸  Docker not installed, skipping uninstall" -ForegroundColor Blue
        }
    }
    
    "uninstall-wsl" {
        Write-Host "`nðŸ“‹ Phase: Uninstall WSL Only" -ForegroundColor Green
        
        if ($systemState.WSLInstalled) {
            $uninstallArgs = @("-BackupPath", $BackupPath)
            if ($Force) { $uninstallArgs += "-Force" }
            
            $result = Invoke-ScriptPhase -ScriptName "UNINSTALL-WSL.ps1" -PhaseName "WSL Uninstall" -Arguments $uninstallArgs -RequireRestart
            if ($result -eq "restart") {
                exit 0
            }
        } else {
            Write-Host "â„¹ï¸  WSL not installed, skipping uninstall" -ForegroundColor Blue
        }
    }
    
    "install-wsl" {
        Write-Host "`nðŸ“‹ Phase: Install WSL 2 Only" -ForegroundColor Green
        $result = Invoke-ScriptPhase -ScriptName "INSTALL-WSL2-DYNAMIC.ps1" -PhaseName "WSL 2 Installation"
        if ($result -eq "restart") {
            exit 0
        }
    }
    
    "install-docker" {
        Write-Host "`nðŸ“‹ Phase: Install Docker Only" -ForegroundColor Green
        $result = Invoke-ScriptPhase -ScriptName "INSTALL-DOCKER-DESKTOP.ps1" -PhaseName "Docker Desktop Installation"
    }
    
    "restore" {
        Write-Host "`nðŸ“‹ Phase: Restore Data Only" -ForegroundColor Green
        
        if ($systemState.BackupExists -or (Test-Path "C:\DockerBackup\*")) {
            # Find most recent backup if no specific path provided
            if (-not (Test-Path "$BackupPath\*")) {
                $latestBackup = Get-ChildItem "C:\DockerBackup" -Directory | Sort-Object CreationTime -Descending | Select-Object -First 1
                if ($latestBackup) {
                    $BackupPath = $latestBackup.FullName
                    Write-Host "ðŸ“ Using latest backup: $BackupPath" -ForegroundColor Yellow
                }
            }
            
            if (Test-Path "$BackupPath\RESTORE-DOCKER-DATA.ps1") {
                & "$BackupPath\RESTORE-DOCKER-DATA.ps1"
            } else {
                Write-Host "âŒ Restore script not found in backup" -ForegroundColor Red
            }
        } else {
            Write-Host "âŒ No backup found for restoration" -ForegroundColor Red
        }
    }
    
    "all" {
        Write-Host "`nðŸ“‹ Phase: Complete Reinstallation" -ForegroundColor Green
        
        # Phase 1: Backup (if Docker exists and backup not skipped)
        if ($systemState.DockerInstalled -and -not $SkipBackup) {
            Write-Host "`nðŸ”¹ Step 1/6: Backup Docker Data" -ForegroundColor Magenta
            $backupArgs = @("-BackupPath", $BackupPath)
            $result = Invoke-ScriptPhase -ScriptName "BACKUP-DOCKER-DATA.ps1" -PhaseName "Docker Data Backup" -Arguments $backupArgs
            if ($result -eq $false) {
                Write-Host "âŒ Backup failed, aborting reinstallation" -ForegroundColor Red
                exit 1
            }
        } else {
            Write-Host "`nðŸ”¹ Step 1/6: Backup Docker Data - SKIPPED" -ForegroundColor Gray
        }
        
        # Phase 2: Uninstall Docker
        if ($systemState.DockerInstalled) {
            Write-Host "`nðŸ”¹ Step 2/6: Uninstall Docker Desktop" -ForegroundColor Magenta
            $result = Invoke-ScriptPhase -ScriptName "UNINSTALL-DOCKER-DESKTOP.ps1" -PhaseName "Docker Desktop Uninstall" -Arguments @("-Force")
        } else {
            Write-Host "`nðŸ”¹ Step 2/6: Uninstall Docker Desktop - SKIPPED" -ForegroundColor Gray
        }
        
        # Phase 3: Uninstall WSL
        if ($systemState.WSLInstalled) {
            Write-Host "`nðŸ”¹ Step 3/6: Uninstall WSL" -ForegroundColor Magenta
            $result = Invoke-ScriptPhase -ScriptName "UNINSTALL-WSL.ps1" -PhaseName "WSL Uninstall" -Arguments @("-Force", "-BackupPath", $BackupPath) -RequireRestart
            if ($result -eq "restart") {
                Write-Host "`nðŸ“ Restart required. After restart, run:" -ForegroundColor Yellow
                Write-Host ".\MASTER-REINSTALL.ps1 -Phase install-wsl -BackupPath `"$BackupPath`"" -ForegroundColor White
                exit 0
            }
        } else {
            Write-Host "`nðŸ”¹ Step 3/6: Uninstall WSL - SKIPPED" -ForegroundColor Gray
        }
        
        # Phase 4: Install WSL 2
        Write-Host "`nðŸ”¹ Step 4/6: Install WSL 2 with Dynamic Disk" -ForegroundColor Magenta
        $result = Invoke-ScriptPhase -ScriptName "INSTALL-WSL2-DYNAMIC.ps1" -PhaseName "WSL 2 Installation"
        if ($result -eq $false) {
            Write-Host "âŒ WSL 2 installation failed, aborting" -ForegroundColor Red
            exit 1
        }
        
        # Phase 5: Install Docker Desktop
        Write-Host "`nðŸ”¹ Step 5/6: Install Docker Desktop" -ForegroundColor Magenta
        $result = Invoke-ScriptPhase -ScriptName "INSTALL-DOCKER-DESKTOP.ps1" -PhaseName "Docker Desktop Installation"
        if ($result -eq $false) {
            Write-Host "âŒ Docker Desktop installation failed" -ForegroundColor Red
        }
        
        # Phase 6: Restore data (if backup exists)
        if (-not $SkipBackup -and (Test-Path "$BackupPath\RESTORE-DOCKER-DATA.ps1")) {
            Write-Host "`nðŸ”¹ Step 6/6: Restore Docker Data" -ForegroundColor Magenta
            & "$BackupPath\RESTORE-DOCKER-DATA.ps1"
        } else {
            Write-Host "`nðŸ”¹ Step 6/6: Restore Docker Data - SKIPPED" -ForegroundColor Gray
        }
        
        # Final verification
        Write-Host "`nðŸ§ª Final System Verification" -ForegroundColor Cyan
        $newSystemState = Test-SystemState
        Show-SystemState -State $newSystemState
        
        if ($newSystemState.DockerInstalled -and $newSystemState.WSL2Available) {
            Write-Host "`nðŸŽ‰ Complete reinstallation successful!" -ForegroundColor Green
            Write-Host "ðŸš€ Your system is ready for optimized Docker and WSL 2 usage" -ForegroundColor Green
        } else {
            Write-Host "`nâš ï¸  Reinstallation completed with warnings" -ForegroundColor Yellow
            Write-Host "Please check individual installation logs" -ForegroundColor Yellow
        }
    }
}

Write-Host "`nâœ… Master script execution completed!" -ForegroundColor Green
Write-Host "ðŸ“– For detailed information, see: COMPLETE-REINSTALL-GUIDE.md" -ForegroundColor Blue