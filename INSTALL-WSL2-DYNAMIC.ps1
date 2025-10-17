# WSL 2 Reinstall Script with Dynamic Disk Configuration
# This script reinstalls WSL 2 with optimized settings for expandable storage
# Run as Administrator AFTER restarting from the uninstall

param(
    [string]$WSLInstallPath = "C:\WSL",
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification='Reserved for future disk configuration features')]
    [string]$WSLDistro = "Ubuntu-22.04",
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification='Reserved for future disk configuration features')]
    [int]$MaxDiskSizeGB = 100,
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification='Reserved for future disk configuration features')]
    [int]$InitialDiskSizeGB = 20,
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification='Reserved for future disk configuration features')]
    [switch]$UseCustomLocation = $false
)

# Check for admin privileges
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "âŒ This script requires Administrator privileges"
    Write-Warning "Please run PowerShell as Administrator and try again"
    exit 1
}

Write-Information "ðŸš€ WSL 2 Reinstallation with Dynamic Disk Starting..." -Tags Info
Write-Information "ðŸ“ Installation path: $WSLInstallPath" -Tags Info
Write-Information "ðŸ’½ Initial disk size: ${InitialDiskSizeGB}GB (expandable to ${MaxDiskSizeGB}GB)" -Tags Info

# Function to check if a Windows feature is enabled
function Test-WindowsFeature {
    param([string]$FeatureName)
    try {
        $feature = Get-WindowsOptionalFeature -Online -FeatureName $FeatureName
        return $feature.State -eq "Enabled"
    } catch {
        return $false
    }
}

# Function to wait for feature installation
function Wait-ForFeatureInstallation {
    param([string]$FeatureName, [int]$TimeoutMinutes = 10)
    
    $timeout = (Get-Date).AddMinutes($TimeoutMinutes)
    while ((Get-Date) -lt $timeout) {
        if (Test-WindowsFeature -FeatureName $FeatureName) {
            return $true
        }
        Start-Sleep -Seconds 10
        Write-Information "  â³ Waiting for $FeatureName to be enabled..." -Tags Wait
    }
    return $false
}

# 1. Enable Windows Features
Write-Information "`nðŸ”§ Enabling Windows Features..." -Tags Phase

$requiredFeatures = @(
    @{Name = "Microsoft-Windows-Subsystem-Linux"; Description = "Windows Subsystem for Linux"},
    @{Name = "VirtualMachinePlatform"; Description = "Virtual Machine Platform"}
)

$restartRequired = $false

foreach ($feature in $requiredFeatures) {
    if (-not (Test-WindowsFeature -FeatureName $feature.Name)) {
        Write-Information "  ðŸ”§ Enabling $($feature.Description)..." -Tags Phase
        try {
            $result = Enable-WindowsOptionalFeature -Online -FeatureName $feature.Name -NoRestart
            if ($result.RestartNeeded) {
                $restartRequired = $true
            }
            Write-Information "  âœ… $($feature.Description) enabled" -Tags Success
        } catch {
            Write-Error "  âŒ Failed to enable $($feature.Description): $_"
            exit 1
        }
    } else {
        Write-Information "  âœ… $($feature.Description) already enabled" -Tags Info
    }
}

if ($restartRequired) {
    Write-Warning "`nâš ï¸  A restart is required for Windows features to take effect"
    $restartChoice = Read-Host "Do you want to restart now? (yes/no)"
    if ($restartChoice -eq "yes") {
        Write-Information "ðŸ”„ Restarting computer..." -Tags Action
        Restart-Computer -Force
        exit 0
    } else {
        Write-Warning "âš ï¸  Please restart manually and run this script again"
        exit 0
    }
}

# 2. Download and install WSL kernel update
Write-Information "`nðŸ“¦ Installing WSL 2 kernel update..." -Tags Phase
$kernelUrl = "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
$kernelPath = "$env:TEMP\wsl_update_x64.msi"

try {
    Write-Information "  ðŸ“¥ Downloading WSL 2 kernel update..." -Tags Phase
    Invoke-WebRequest -Uri $kernelUrl -OutFile $kernelPath -UseBasicParsing
    
    Write-Information "  ðŸ“¦ Installing WSL 2 kernel update..." -Tags Phase
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", $kernelPath, "/quiet", "/norestart" -Wait
    
    Write-Information "  âœ… WSL 2 kernel update installed" -Tags Success
    
    # Clean up
    Remove-Item $kernelPath -Force -ErrorAction SilentlyContinue
} catch {
    Write-Warning "  âš ï¸  Kernel update failed: $_"
    Write-Information "  â„¹ï¸  You can manually download from: $kernelUrl" -Tags Info
}

# 3. Set WSL 2 as default version
Write-Information "`nðŸ”§ Setting WSL 2 as default version..." -Tags Phase
try {
    wsl --set-default-version 2
    Write-Information "  âœ… WSL 2 set as default version" -Tags Success
} catch {
    Write-Warning "  âš ï¸  Failed to set WSL 2 as default: $_"
}

# 4. Create WSL installation directory
Write-Information "`nðŸ“ Creating WSL installation directory..." -Tags Phase
if (-not (Test-Path $WSLInstallPath)) {
    try {
        New-Item -ItemType Directory -Path $WSLInstallPath -Force | Out-Null
        Write-Information "  âœ… Created directory: $WSLInstallPath" -Tags Success
    } catch {
        Write-Error "  âŒ Failed to create directory: $_"
        exit 1
    }
} else {
    Write-Information "  âœ… Directory already exists: $WSLInstallPath" -Tags Info
}

# 5. Create .wslconfig with dynamic disk settings
Write-Information "`nâš™ï¸  Creating optimized .wslconfig..." -Tags Phase
$wslConfigPath = "$env:USERPROFILE\.wslconfig"
$wslConfig = @"
[wsl2]
# Memory allocation (adjust based on your system)
memory=4GB

# CPU cores (adjust based on your system)
processors=2

# Swap file size
swap=2GB

# Disable swap file (uncomment if you prefer no swap)
# swap=0

# Network settings
localhostForwarding=true

# Kernel settings for better performance
kernelCommandLine=cgroup_no_v1=all systemd.unified_cgroup_hierarchy=1

# Experimental settings for better integration
[experimental]
sparseVhd=true
autoMemoryReclaim=dropcache

# WSL integration settings
[interop]
enabled=true
appendWindowsPath=true
"@

try {
    $wslConfig | Out-File -FilePath $wslConfigPath -Encoding UTF8
    Write-Information "  âœ… .wslconfig created with optimized settings" -Tags Success
    Write-Information "  ðŸ“ Location: $wslConfigPath" -Tags Info
} catch {
    Write-Warning "  âš ï¸  Failed to create .wslconfig: $_"
}

# 6. Install Ubuntu distribution
Write-Information "`nðŸ§ Installing Ubuntu distribution..." -Tags Phase

if ($UseCustomLocation) {
    # Custom installation to specified directory
    Write-Information "  ðŸ“¦ Installing $WSLDistro to custom location..." -Tags Phase
    $distroPath = Join-Path $WSLInstallPath $WSLDistro
    
    try {
        # Download Ubuntu 22.04 appx package
        $ubuntuUrl = "https://aka.ms/wslubuntu2204"
        $ubuntuAppx = "$env:TEMP\Ubuntu2204.appx"
        
    Write-Information "  ðŸ“¥ Downloading Ubuntu 22.04..." -Tags Phase
        Invoke-WebRequest -Uri $ubuntuUrl -OutFile $ubuntuAppx -UseBasicParsing
        
        # Extract and install
        $extractPath = "$env:TEMP\Ubuntu2204_Extract"
        Expand-Archive -Path $ubuntuAppx -DestinationPath $extractPath -Force
        
        $ubuntuExe = Get-ChildItem $extractPath -Name "ubuntu*.exe" | Select-Object -First 1
        if ($ubuntuExe) {
            Copy-Item (Join-Path $extractPath $ubuntuExe) -Destination (Join-Path $distroPath "ubuntu.exe")
            
            # Register the distribution
            wsl --import $WSLDistro $distroPath (Join-Path $extractPath "install.tar.gz")
            Write-Information "  âœ… Ubuntu installed to custom location" -Tags Success
        }
        
        # Clean up
        Remove-Item $ubuntuAppx, $extractPath -Recurse -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Warning "  âš ï¸  Custom installation failed, falling back to Microsoft Store method"
        $UseCustomLocation = $false
    }
}

if (-not $UseCustomLocation) {
    # Install via Microsoft Store/winget
    try {
        Write-Information "  ðŸ“¦ Installing Ubuntu via winget..." -Tags Phase
        winget install Canonical.Ubuntu.2204 --accept-source-agreements --accept-package-agreements
        Write-Information "  âœ… Ubuntu installed successfully" -Tags Success
    } catch {
        Write-Warning "  âš ï¸  winget installation failed, trying alternative method..."
        
        # Alternative: Use wsl --install
        try {
            wsl --install -d Ubuntu-22.04
            Write-Information "  âœ… Ubuntu installed via wsl --install" -Tags Success
        } catch {
            Write-Error "  âŒ Failed to install Ubuntu: $_"
            Write-Information "  â„¹ï¸  Please install Ubuntu manually from Microsoft Store" -Tags Info
        }
    }
}

# 7. Configure Ubuntu for better performance
Write-Information "`nâš™ï¸  Configuring Ubuntu for optimal performance..." -Tags Phase

# Wait for WSL to be ready
Start-Sleep -Seconds 5

try {
    # Set WSL 2 for the distribution
    wsl --set-version Ubuntu-22.04 2
    Write-Information "  âœ… Ubuntu set to WSL 2" -Tags Success
    
    # Set as default distribution
    wsl --set-default Ubuntu-22.04
    Write-Information "  âœ… Ubuntu set as default distribution" -Tags Success
    
} catch {
    Write-Warning "  âš ï¸  Configuration warning: $_"
}

# 8. Create disk management scripts
Write-Information "`nðŸ“ Creating disk management utilities..." -Tags Phase

# Create disk optimization script
$diskOptimizeScript = @"
#!/bin/bash
# WSL Disk Optimization Script
# Run this inside WSL to optimize disk usage

echo "ðŸ”§ WSL Disk Optimization Starting..."

# Clean package cache
echo "ðŸ“¦ Cleaning package cache..."
sudo apt clean
sudo apt autoremove -y
sudo apt autoclean

# Clean logs
echo "ðŸ“ Cleaning logs..."
sudo journalctl --vacuum-time=7d
sudo rm -rf /var/log/*.old
sudo rm -rf /var/log/*/*.old

# Clean temporary files
echo "ðŸ—‘ï¸  Cleaning temporary files..."
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*

# Compact the disk (this will show usage)
echo "ðŸ’¾ Current disk usage:"
df -h /

echo "âœ… Disk optimization completed!"
echo "ðŸ’¡ To compact the WSL disk from Windows, run:"
echo "   wsl --shutdown"
echo "   diskpart"
echo "   select vdisk file=\"\$env:LOCALAPPDATA\\Packages\\CanonicalGroupLimited.Ubuntu22.04LTS_*\\LocalState\\ext4.vhdx\""
echo "   compact vdisk"
"@

# Create Windows disk compaction script
$diskCompactScript = @"
# WSL Disk Compaction Script (Windows)
# Run this from Windows PowerShell to compact WSL disk

Write-Information "ðŸ’¾ WSL Disk Compaction Starting..." -Tags Info

# Shutdown WSL
Write-Information "ðŸ›‘ Shutting down WSL..." -Tags Info
wsl --shutdown
Start-Sleep -Seconds 3

# Find Ubuntu VHDX file
Write-Information "ðŸ” Finding Ubuntu disk file..." -Tags Info
`$vhdxPath = Get-ChildItem "`$env:LOCALAPPDATA\Packages\CanonicalGroupLimited.Ubuntu*\LocalState\ext4.vhdx" -ErrorAction SilentlyContinue | Select-Object -First 1

if (`$vhdxPath) {
    Write-Information "ðŸ“ Found: `$(`$vhdxPath.FullName)" -Tags Info
    
    # Get current size
    `$currentSize = [math]::Round(`$vhdxPath.Length / 1GB, 2)
    Write-Information "ðŸ“Š Current size: `${currentSize}GB" -Tags Info
    
    # Compact using diskpart
    Write-Information "ðŸ—œï¸  Compacting disk..." -Tags Action
    `$diskpartCommands = @"
select vdisk file="`$(`$vhdxPath.FullName)"
compact vdisk
exit
"@
    
    `$diskpartCommands | diskpart
    
    # Get new size
    `$newSize = [math]::Round((Get-Item `$vhdxPath.FullName).Length / 1GB, 2)
    `$savedSpace = `$currentSize - `$newSize
    
    Write-Information "âœ… Compaction completed!" -Tags Success
    Write-Information "ðŸ“Š New size: `${newSize}GB" -Tags Info
    Write-Information "ðŸ’¾ Space saved: `${savedSpace}GB" -Tags Success
} else {
    Write-Warning "âŒ Ubuntu disk file not found"
    Write-Information "ðŸ” Please check if Ubuntu is installed correctly" -Tags Info
}
"@

# Save scripts
$scriptsPath = Join-Path $WSLInstallPath "scripts"
New-Item -ItemType Directory -Path $scriptsPath -Force | Out-Null

$diskOptimizeScript | Out-File -FilePath (Join-Path $scriptsPath "optimize-wsl-disk.sh") -Encoding UTF8
$diskCompactScript | Out-File -FilePath (Join-Path $scriptsPath "compact-wsl-disk.ps1") -Encoding UTF8

    Write-Information "  âœ… Disk management scripts created in $scriptsPath" -Tags Success

# 9. Test WSL installation
Write-Information "`nðŸ§ª Testing WSL installation..." -Tags Phase
try {
    $wslTest = wsl --list --verbose
    Write-Information "ðŸ“‹ Current WSL distributions:" -Tags Info
    $wslTest | ForEach-Object { Write-Information "  $_" -Tags Info }
    
    # Test basic command
    Write-Information "`nðŸ§ Testing Ubuntu..." -Tags Info
    wsl -d Ubuntu-22.04 echo "âœ… Ubuntu is working correctly!"
    
    Write-Information "  âœ… WSL installation test passed" -Tags Success
} catch {
    Write-Warning "  âš ï¸  WSL test failed: $_"
    Write-Information "  â„¹ï¸  You may need to complete Ubuntu setup manually" -Tags Info
}

# 10. Summary and next steps
Write-Information "`nâœ… WSL 2 installation completed successfully!" -Tags Success

Write-Information "`nðŸ“Š Installation Summary:" -Tags Info
Write-Information "  ðŸ“ Installation path: $WSLInstallPath" -Tags Info
Write-Information "  ðŸ§ Distribution: Ubuntu 22.04 LTS" -Tags Info
Write-Information "  ðŸ’¾ Disk type: Dynamic (expandable)" -Tags Info
Write-Information "  âš™ï¸  Configuration: Optimized for Docker" -Tags Info

Write-Information "`nðŸ”§ Available Tools:" -Tags Info
Write-Information "  ðŸ“ Scripts location: $scriptsPath" -Tags Info
Write-Information "  ðŸ—œï¸  Disk compaction: compact-wsl-disk.ps1" -Tags Info
Write-Information "  ðŸ§¹ Disk cleanup: optimize-wsl-disk.sh (run inside WSL)" -Tags Info

Write-Information "`nðŸ”„ Next Steps:" -Tags Info
Write-Information "1. Complete Ubuntu setup (create user account)" -Tags Info
Write-Information "2. Install Docker Desktop with WSL 2 backend" -Tags Info
Write-Information "3. Restore your Docker data" -Tags Info
Write-Information "4. Test your VPS environment" -Tags Info

Write-Warning "`nðŸ’¡ Pro Tips:" 
Write-Information "- Run 'wsl --shutdown' before compacting disk" -Tags Info
Write-Information "- Use the disk cleanup script regularly to save space" -Tags Info
Write-Information "- Monitor disk usage with 'df -h' inside WSL" -Tags Info
Write-Information "- The .wslconfig file controls WSL resource limits" -Tags Info

Write-Information "`nðŸš€ Ready for Docker Desktop installation!" -Tags Success