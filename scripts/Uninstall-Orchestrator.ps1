# Parameters for uninstallation orchestration
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("wsl-only", "docker-only", "both")]
    [string]$Target,
    
    [string]$BackupPath = "C:\DockerBackup",
    [switch]$Force = $false,
    [switch]$SkipBackup = $false
)

# Set error handling
$ErrorActionPreference = "Stop"

function Write-Phase {
    param([string]$Message)
    Write-Output "`nðŸ“‹ $Message" 
}

function Invoke-UninstallScript {
    param(
        [string]$ScriptPath,
        [string]$PhaseName,
        [array]$Arguments = @()
    )
    
    Write-Phase "Starting: $PhaseName"
    
    try {
        $fullPath = Join-Path $PSScriptRoot $ScriptPath
        if (-not (Test-Path $fullPath)) {
            throw "Script not found: $fullPath"
        }
        
        $result = & $fullPath @Arguments
        Write-Output "âœ… $PhaseName completed successfully"
        return $result
    }
    catch {
        Write-Error "âŒ $PhaseName failed: $_"
        throw
    }
}

# Main uninstallation logic
try {
    Write-Phase "Uninstallation Orchestrator Started - Target: $Target"
    
    # Backup first if not skipped - REMOVED
    if (-not $SkipBackup -and ($Target -eq "docker-only" -or $Target -eq "both")) {
        Write-Output "Data backup step removed; please ensure you have external backups if needed."
    }
    
    switch ($Target) {
        "wsl-only" {
            $args = @("-BackupPath", $BackupPath)
            if ($Force) { $args += "-Force" }
            Invoke-UninstallScript -ScriptPath "wsl\Uninstall-WSL.ps1" -PhaseName "WSL Uninstallation" -Arguments $args
        }
        
        "docker-only" {
            $args = @("-BackupPath", $BackupPath)
            if ($Force) { $args += "-Force" }
            Invoke-UninstallScript -ScriptPath "docker\Uninstall-Docker.ps1" -PhaseName "Docker Uninstallation" -Arguments $args
        }
        
        "both" {
            $args = @("-BackupPath", $BackupPath)
            if ($Force) { $args += "-Force" }
            
            # Uninstall Docker first
            Invoke-UninstallScript -ScriptPath "docker\Uninstall-Docker.ps1" -PhaseName "Docker Uninstallation" -Arguments $args
            
            # Then WSL
            Invoke-UninstallScript -ScriptPath "wsl\Uninstall-WSL.ps1" -PhaseName "WSL Uninstallation" -Arguments $args
        }
    }
    
    Write-Phase "Uninstallation orchestration completed successfully"
    exit 0
}
catch {
    Write-Error "Uninstallation orchestration failed: $_"
    exit 1
}