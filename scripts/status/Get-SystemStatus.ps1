param(
    [switch]$ShowDetails = $false,
    [switch]$JsonOutput = $false
)

# Set error handling
$ErrorActionPreference = "Stop"

# Import status modules
. "$PSScriptRoot\Get-WSLStatus.ps1"
. "$PSScriptRoot\Get-DockerStatus.ps1"

function Write-StatusHeader {
    param([string]$Title)
    Write-Output "`n$('=' * 60)"
    Write-Output "  $Title"
    Write-Output "$('=' * 60)"
}

function Write-StatusLine {
    param(
        [string]$Label,
        [string]$Status,
        [string]$Color = "White"
    )
    
    $paddedLabel = $Label.PadRight(25)
    Write-Output "$paddedLabel : $Status"
}

function Format-WSLStatus {
    param($WSLStatus, [switch]$ShowDetails)
    
    Write-StatusHeader "WSL (Windows Subsystem for Linux) Status"
    
    # Basic status
    $installStatus = if ($WSLStatus.Installed) { "✅ Installed and Working" } else { "❌ Not Installed" }
    Write-StatusLine "WSL Status" $installStatus
    
    $featureStatus = if ($WSLStatus.FeatureEnabled) { "✅ Enabled" } else { "❌ Disabled" }
    Write-StatusLine "WSL Feature" $featureStatus
    
    $vmStatus = if ($WSLStatus.VirtualMachinePlatformEnabled) { "✅ Enabled" } else { "❌ Disabled" }
    Write-StatusLine "Virtual Machine Platform" $vmStatus
    
    Write-StatusLine "WSL Version" $WSLStatus.Version.Version
    
    # Distribution information
    if ($WSLStatus.Distributions.Count -gt 0) {
        Write-StatusLine "Installed Distributions" "$($WSLStatus.Distributions.Count) found"
        if ($ShowDetails) {
            foreach ($distro in $WSLStatus.Distributions) {
                Write-Output "    • $distro"
            }
        }
    } else {
        Write-StatusLine "Installed Distributions" "None"
    }
    
    if ($WSLStatus.RunningDistributions.Count -gt 0) {
        Write-StatusLine "Running Distributions" "$($WSLStatus.RunningDistributions.Count) active"
        if ($ShowDetails) {
            foreach ($distro in $WSLStatus.RunningDistributions) {
                Write-Output "    • $distro (running)"
            }
        }
    } else {
        Write-StatusLine "Running Distributions" "None"
    }
}

function Format-DockerStatus {
    param($DockerStatus, [switch]$ShowDetails)
    
    Write-StatusHeader "Docker Desktop Status"
    
    # Basic status
    $installStatus = if ($DockerStatus.Installed) { "✅ Installed" } else { "❌ Not Installed" }
    Write-StatusLine "Docker CLI" $installStatus
    
    $desktopStatus = if ($DockerStatus.DesktopInstalled) { "✅ Installed" } else { "❌ Not Installed" }
    Write-StatusLine "Docker Desktop" $desktopStatus
    
    $runningStatus = if ($DockerStatus.Running) { "✅ Running" } else { "❌ Not Running" }
    Write-StatusLine "Docker Daemon" $runningStatus
    
    if ($DockerStatus.Running) {
        $workingStatus = if ($DockerStatus.Working) { "✅ Working" } else { "⚠️ Issues Detected" }
        Write-StatusLine "Docker Functionality" $workingStatus
    }
    
    Write-StatusLine "Docker Version" $DockerStatus.Version.Version
    
    # Resource information
    if ($DockerStatus.Containers.Available) {
        Write-StatusLine "Containers" "$($DockerStatus.Containers.Running) running / $($DockerStatus.Containers.Total) total"
        if ($ShowDetails -and $DockerStatus.Containers.List.Count -gt 0) {
            foreach ($container in $DockerStatus.Containers.List) {
                Write-Output "    • $container"
            }
        }
    } else {
        Write-StatusLine "Containers" "Not available (Docker not running)"
    }
    
    if ($DockerStatus.Images.Available) {
        Write-StatusLine "Images" "$($DockerStatus.Images.Count) images"
        if ($ShowDetails -and $DockerStatus.Images.List.Count -gt 0) {
            foreach ($image in $DockerStatus.Images.List) {
                Write-Output "    • $image"
            }
        }
    } else {
        Write-StatusLine "Images" "Not available (Docker not running)"
    }
    
    if ($DockerStatus.Volumes.Available) {
        Write-StatusLine "Volumes" "$($DockerStatus.Volumes.Count) volumes"
        if ($ShowDetails -and $DockerStatus.Volumes.List.Count -gt 0) {
            foreach ($volume in $DockerStatus.Volumes.List) {
                Write-Output "    • $volume"
            }
        }
    } else {
        Write-StatusLine "Volumes" "Not available (Docker not running)"
    }
}

function Get-SystemStatus {
    """
    Get comprehensive system status for both WSL and Docker
    Returns: Hashtable with complete system status
    """
    $wslStatus = Get-WSLStatus
    $dockerStatus = Get-DockerStatus
    
    $systemStatus = @{
        WSL = $wslStatus
        Docker = $dockerStatus
        Summary = @{
            WSLReady = $wslStatus.Installed
            DockerReady = $dockerStatus.Installed -and $dockerStatus.Running
            BothReady = $wslStatus.Installed -and $dockerStatus.Installed -and $dockerStatus.Running
            BackupExists = (Test-Path "C:\DockerBackup") -and ((Get-ChildItem "C:\DockerBackup" -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0)
        }
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    return $systemStatus
}

# Main execution
try {
    $systemStatus = Get-SystemStatus
    
    if ($JsonOutput) {
        # Output as JSON for programmatic use
        $systemStatus | ConvertTo-Json -Depth 5
    } else {
        # Human-readable output
        Write-StatusHeader "System Status Report - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        
        Format-WSLStatus -WSLStatus $systemStatus.WSL -ShowDetails:$ShowDetails
        Format-DockerStatus -DockerStatus $systemStatus.Docker -ShowDetails:$ShowDetails
        
        # Summary
        Write-StatusHeader "Summary"
        
        $wslReady = if ($systemStatus.Summary.WSLReady) { "✅ Ready" } else { "❌ Not Ready" }
        Write-StatusLine "WSL Environment" $wslReady
        
        $dockerReady = if ($systemStatus.Summary.DockerReady) { "✅ Ready" } else { "❌ Not Ready" }
        Write-StatusLine "Docker Environment" $dockerReady
        
        $overallStatus = if ($systemStatus.Summary.BothReady) { "✅ Both Ready for Development" } else { "⚠️ Setup Required" }
        Write-StatusLine "Overall Status" $overallStatus
        
        $backupStatus = if ($systemStatus.Summary.BackupExists) { "✅ Available" } else { "❌ No Backup Found" }
        Write-StatusLine "Docker Backup" $backupStatus
        
        Write-Output "`n$('=' * 60)"
    }
    
    # Exit with appropriate code
    if ($systemStatus.Summary.BothReady) {
        exit 0
    } else {
        exit 1
    }
}
catch {
    Write-Error "Status check failed: $_"
    exit 1
}

# Functions are available when script is dot-sourced