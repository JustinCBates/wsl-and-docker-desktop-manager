param(
    [switch]$Force = $false
)

# Set error handling
$ErrorActionPreference = "Stop"

function Write-Phase {
    param([string]$Message)
    Write-Output "`n📋 WSL Install: $Message"
}

function Test-AdminRights {
    return ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Enable-WSLFeatures {
    Write-Phase "Enabling WSL and Virtual Machine Platform features"
    
    try {
        # Enable WSL feature
        $wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
        if ($wslFeature.State -ne "Enabled") {
            Write-Output "Enabling WSL feature..."
            Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
        }
        
        # Enable Virtual Machine Platform
        $vmFeature = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
        if ($vmFeature.State -ne "Enabled") {
            Write-Output "Enabling Virtual Machine Platform..."
            Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
        }
        
        Write-Output "✅ WSL features enabled"
        return $true
    }
    catch {
        Write-Error "❌ Failed to enable WSL features: $_"
        throw
    }
}

function Install-WSLKernel {
    Write-Phase "Installing WSL2 Kernel Update"
    
    try {
        $kernelUrl = "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
        $kernelPath = "$env:TEMP\wsl_update_x64.msi"
        
        Write-Output "Downloading WSL2 kernel update..."
        Invoke-WebRequest -Uri $kernelUrl -OutFile $kernelPath
        
        Write-Output "Installing WSL2 kernel update..."
        Start-Process msiexec -ArgumentList "/i `"$kernelPath`" /quiet /norestart" -Wait
        
        # Clean up
        Remove-Item $kernelPath -Force
        
        Write-Output "✅ WSL2 kernel installed"
    }
    catch {
        Write-Error "❌ Failed to install WSL2 kernel: $_"
        throw
    }
}

function Set-WSLVersion {
    Write-Phase "Setting WSL default version to 2"
    
    try {
        & wsl --set-default-version 2
        Write-Output "✅ WSL default version set to 2"
    }
    catch {
        Write-Warning "Could not set WSL default version (this is normal if no distributions are installed yet)"
    }
}

# Main installation logic
try {
    Write-Phase "WSL Installation Started"
    
    if (-not (Test-AdminRights)) {
        throw "This script requires administrator privileges"
    }
    
    # Check if WSL is already installed and working
    $wslInstalled = $false
    try {
        $wslVersion = & wsl --status 2>$null
        $wslInstalled = $LASTEXITCODE -eq 0
    }
    catch {
        $wslInstalled = $false
    }
    
    if ($wslInstalled -and -not $Force) {
        Write-Output "✅ WSL is already installed and working"
        exit 0
    }
    
    # Enable features
    $featuresEnabled = Enable-WSLFeatures
    
    # Install kernel update
    Install-WSLKernel
    
    # Set default version
    Set-WSLVersion
    
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
        $restartRequired = $featuresEnabled
    }
    
    if ($restartRequired) {
        Write-Output "`n⚠️  A restart is required to complete WSL installation"
        Write-Output "Please restart your computer and run this script again if needed"
        return "restart"
    }
    
    Write-Phase "WSL installation completed successfully"
    exit 0
}
catch {
    Write-Error "WSL installation failed: $_"
    exit 1
}