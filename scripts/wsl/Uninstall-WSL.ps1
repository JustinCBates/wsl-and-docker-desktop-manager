# Parameters for WSL uninstallation
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
param(
    [string]$BackupPath = "C:\DockerBackup",
    [switch]$Force = $false
)

# Set error handling
$ErrorActionPreference = "Stop"

# Import WSL status functions
. "$PSScriptRoot\..\status\Get-WSLStatus.ps1"

function Write-Phase {
    param([string]$Message)
    Write-Output "`n📋 WSL Uninstall: $Message"
}

function Test-AdminRights {
    return ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Stop-WSLDistributions {
    Write-Phase "Stopping all WSL distributions"
    
    try {
        # Get all running distributions
        $runningDistros = & wsl --list --running --quiet 2>$null
        
        if ($runningDistros -and $runningDistros.Count -gt 0) {
            Write-Output "Shutting down WSL distributions..."
            & wsl --shutdown
            Start-Sleep -Seconds 3
            Write-Output "✅ WSL distributions stopped"
        } else {
            Write-Output "No running WSL distributions found"
        }
    }
    catch {
        Write-Warning "Could not stop WSL distributions: $_"
    }
}

function Remove-WSLDistributions {
    Write-Phase "Unregistering WSL distributions"
    
    try {
        $distros = & wsl --list --quiet 2>$null | Where-Object { $_ -and $_.Trim() -ne "" }
        
        if ($distros -and $distros.Count -gt 0) {
            foreach ($distro in $distros) {
                $distroName = $distro.Trim()
                if ($distroName) {
                    Write-Output "Unregistering distribution: $distroName"
                    & wsl --unregister $distroName
                }
            }
            Write-Output "✅ WSL distributions unregistered"
        } else {
            Write-Output "No WSL distributions found to remove"
        }
    }
    catch {
        Write-Warning "Error removing WSL distributions: $_"
    }
}

function Disable-WSLFeatures {
    Write-Phase "Disabling WSL features"
    
    try {
        # Disable WSL feature
        $wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
        if ($wslFeature.State -eq "Enabled") {
            Write-Output "Disabling WSL feature..."
            Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
        }
        
        # Disable Virtual Machine Platform
        $vmFeature = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
        if ($vmFeature.State -eq "Enabled") {
            Write-Output "Disabling Virtual Machine Platform..."
            Disable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
        }
        
        Write-Output "✅ WSL features disabled"
        return $true
    }
    catch {
        Write-Error "❌ Failed to disable WSL features: $_"
        throw
    }
}

function Remove-WSLFiles {
    Write-Phase "Cleaning up WSL files"
    
    try {
        $wslPaths = @(
            "$env:USERPROFILE\.wslconfig",
            "$env:LOCALAPPDATA\Packages\Microsoft.WindowsSubsystemForLinux_*",
            "$env:LOCALAPPDATA\lxss"
        )
        
        foreach ($path in $wslPaths) {
            if (Test-Path $path) {
                Write-Output "Removing: $path"
                Remove-Item $path -Recurse -Force
            }
        }
        
        Write-Output "✅ WSL files cleaned up"
    }
    catch {
        Write-Warning "Some WSL files could not be removed: $_"
    }
}

# Main uninstallation logic
try {
    Write-Phase "WSL Uninstallation Started"
    
    if (-not (Test-AdminRights)) {
        throw "This script requires administrator privileges"
    }
    
    # Check if WSL is installed
    if (-not (Test-WSLInstalled) -and -not $Force) {
        Write-Output "✅ WSL is not installed"
        exit 0
    }
    
    # Stop all WSL processes
    Stop-WSLDistributions
    
    # Remove distributions
    Remove-WSLDistributions
    
    # Disable features
    $featuresDisabled = Disable-WSLFeatures
    
    # Clean up files
    Remove-WSLFiles
    
    # Check if restart is needed
    $restartRequired = $false
    try {
        $wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
        $vmFeature = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
        
        if ($wslFeature.RestartRequired -or $vmFeature.RestartRequired) {
            $restartRequired = $true
        }
    }
    catch {
        # If we can't check, assume restart might be needed
        $restartRequired = $featuresDisabled
    }
    
    if ($restartRequired) {
        Write-Output "`n⚠️  A restart is required to complete WSL uninstallation"
        Write-Output "Please restart your computer to complete the process"
        return "restart"
    }
    
    Write-Phase "WSL uninstallation completed successfully"
    exit 0
}
catch {
    Write-Error "WSL uninstallation failed: $_"
    exit 1
}