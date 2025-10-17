param()

# Set error handling
$ErrorActionPreference = "Stop"

function Test-WSLInstalled {
    """
    Check if WSL is installed and functional
    Returns: $true if WSL is working, $false otherwise
    """
    try {
        & wsl --status 2>$null | Out-Null
        return $LASTEXITCODE -eq 0
    }
    catch {
        return $false
    }
}

function Test-WSLFeatureEnabled {
    """
    Check if WSL Windows feature is enabled
    Returns: $true if enabled, $false otherwise
    """
    try {
        $wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
        return $wslFeature.State -eq "Enabled"
    }
    catch {
        return $false
    }
}

function Test-VirtualMachinePlatformEnabled {
    """
    Check if Virtual Machine Platform feature is enabled
    Returns: $true if enabled, $false otherwise
    """
    try {
        $vmFeature = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
        return $vmFeature.State -eq "Enabled"
    }
    catch {
        return $false
    }
}

function Get-WSLDistributions {
    """
    Get list of installed WSL distributions
    Returns: Array of distribution names
    """
    try {
        $distros = & wsl --list --quiet 2>$null | Where-Object { $_ -and $_.Trim() -ne "" }
        if ($distros) {
            return $distros | ForEach-Object { $_.Trim() }
        }
        return @()
    }
    catch {
        return @()
    }
}

function Get-WSLRunningDistributions {
    """
    Get list of currently running WSL distributions
    Returns: Array of running distribution names
    """
    try {
        $runningDistros = & wsl --list --running --quiet 2>$null
        if ($runningDistros) {
            return $runningDistros | Where-Object { $_ -and $_.Trim() -ne "" } | ForEach-Object { $_.Trim() }
        }
        return @()
    }
    catch {
        return @()
    }
}

function Get-WSLVersion {
    """
    Get WSL version information
    Returns: Hashtable with version details
    """
    try {
        $versionInfo = & wsl --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            return @{
                Available = $true
                Version = $versionInfo -join "`n"
            }
        }
    }
    catch {
        Write-Verbose "Unable to get WSL version details: $($_.Exception.Message)"
    }
    
    # Check if any WSL is available
    if (Test-WSLInstalled) {
        return @{
            Available = $true
            Version = "WSL Available (version unknown)"
        }
    }
    
    return @{
        Available = $false
        Version = "Not installed"
    }
}

function Get-WSLStatus {
    """
    Get comprehensive WSL status information
    Returns: Hashtable with complete WSL status
    """
    $status = @{
        Installed = Test-WSLInstalled
        FeatureEnabled = Test-WSLFeatureEnabled
        VirtualMachinePlatformEnabled = Test-VirtualMachinePlatformEnabled
        Distributions = Get-WSLDistributions
        RunningDistributions = Get-WSLRunningDistributions
        Version = Get-WSLVersion
    }
    
    return $status
}

# Functions are available when script is dot-sourced