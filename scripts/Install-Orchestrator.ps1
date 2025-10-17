# Parameters for installation orchestration
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("wsl-only", "docker-only", "both")]
    [string]$Target,
    
    [string]$BackupPath = "C:\DockerBackup",
    [switch]$Force = $false
)

# Set error handling
$ErrorActionPreference = "Stop"

function Write-Phase {
    param([string]$Message)
    Write-Output "`nðŸ“‹ $Message" 
}

function Invoke-InstallScript {
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

# Main installation logic
try {
    Write-Phase "Installation Orchestrator Started - Target: $Target"
    
    switch ($Target) {
        "wsl-only" {
            $args = @()
            if ($Force) { $args += "-Force" }
            Invoke-InstallScript -ScriptPath "wsl\Install-WSL.ps1" -PhaseName "WSL Installation" -Arguments $args
        }
        
        "docker-only" {
            $args = @()
            if ($Force) { $args += "-Force" }
            Invoke-InstallScript -ScriptPath "docker\Install-Docker.ps1" -PhaseName "Docker Installation" -Arguments $args
        }
        
        "both" {
            $args = @()
            if ($Force) { $args += "-Force" }
            
            # Install WSL first
            Invoke-InstallScript -ScriptPath "wsl\Install-WSL.ps1" -PhaseName "WSL Installation" -Arguments $args
            
            # Then Docker
            Invoke-InstallScript -ScriptPath "docker\Install-Docker.ps1" -PhaseName "Docker Installation" -Arguments $args
        }
    }
    
    Write-Phase "Installation orchestration completed successfully"
    exit 0
}
catch {
    Write-Error "Installation orchestration failed: $_"
    exit 1
}