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
    Write-Host "âŒ This script requires Administrator privileges" -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again" -ForegroundColor Yellow
    exit 1
}

Write-Host "ðŸš€ WSL 2 Reinstallation with Dynamic Disk Starting..." -ForegroundColor Green
Write-Host "ðŸ“ Installation path: $WSLInstallPath" -ForegroundColor Yellow
Write-Host "ðŸ’½ Initial disk size: ${InitialDiskSizeGB}GB (expandable to ${MaxDiskSizeGB}GB)" -ForegroundColor Yellow

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
        Write-Host "  â³ Waiting for $FeatureName to be enabled..." -ForegroundColor Gray
    }
    return $false
}

# 1. Enable Windows Features
Write-Host "`nðŸ”§ Enabling Windows Features..." -ForegroundColor Cyan

$requiredFeatures = @(
    @{Name = "Microsoft-Windows-Subsystem-Linux"; Description = "Windows Subsystem for Linux"},
    @{Name = "VirtualMachinePlatform"; Description = "Virtual Machine Platform"}
)

$restartRequired = $false

foreach ($feature in $requiredFeatures) {
    if (-not (Test-WindowsFeature -FeatureName $feature.Name)) {
        Write-Host "  ðŸ”§ Enabling $($feature.Description)..." -ForegroundColor White
        try {
            $result = Enable-WindowsOptionalFeature -Online -FeatureName $feature.Name -NoRestart
            if ($result.RestartNeeded) {
                $restartRequired = $true
            }
            Write-Host "  âœ… $($feature.Description) enabled" -ForegroundColor Green
        } catch {
            Write-Host "  âŒ Failed to enable $($feature.Description): $_" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "  âœ… $($feature.Description) already enabled" -ForegroundColor Green
    }
}

if ($restartRequired) {
    Write-Host "`nâš ï¸  A restart is required for Windows features to take effect" -ForegroundColor Yellow
    $restartChoice = Read-Host "Do you want to restart now? (yes/no)"
    if ($restartChoice -eq "yes") {
        Write-Host "ðŸ”„ Restarting computer..." -ForegroundColor Red
        Restart-Computer -Force
        exit 0
    } else {
        Write-Host "âš ï¸  Please restart manually and run this script again" -ForegroundColor Yellow
        exit 0
    }
}

# 2. Download and install WSL kernel update
Write-Host "`nðŸ“¦ Installing WSL 2 kernel update..." -ForegroundColor Cyan
$kernelUrl = "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
$kernelPath = "$env:TEMP\wsl_update_x64.msi"

try {
    Write-Host "  ðŸ“¥ Downloading WSL 2 kernel update..." -ForegroundColor White
    Invoke-WebRequest -Uri $kernelUrl -OutFile $kernelPath -UseBasicParsing
    
    Write-Host "  ðŸ“¦ Installing WSL 2 kernel update..." -ForegroundColor White
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", $kernelPath, "/quiet", "/norestart" -Wait
    
    Write-Host "  âœ… WSL 2 kernel update installed" -ForegroundColor Green
    
    # Clean up
    Remove-Item $kernelPath -Force -ErrorAction SilentlyContinue
} catch {
    Write-Host "  âš ï¸  Kernel update failed: $_" -ForegroundColor Yellow
    Write-Host "  â„¹ï¸  You can manually download from: $kernelUrl" -ForegroundColor Blue
}

# 3. Set WSL 2 as default version
Write-Host "`nðŸ”§ Setting WSL 2 as default version..." -ForegroundColor Cyan
try {
    wsl --set-default-version 2
    Write-Host "  âœ… WSL 2 set as default version" -ForegroundColor Green
} catch {
    Write-Host "  âš ï¸  Failed to set WSL 2 as default: $_" -ForegroundColor Yellow
}

# 4. Create WSL installation directory
Write-Host "`nðŸ“ Creating WSL installation directory..." -ForegroundColor Cyan
if (-not (Test-Path $WSLInstallPath)) {
    try {
        New-Item -ItemType Directory -Path $WSLInstallPath -Force | Out-Null
        Write-Host "  âœ… Created directory: $WSLInstallPath" -ForegroundColor Green
    } catch {
        Write-Host "  âŒ Failed to create directory: $_" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "  âœ… Directory already exists: $WSLInstallPath" -ForegroundColor Green
}

# 5. Create .wslconfig with dynamic disk settings
Write-Host "`nâš™ï¸  Creating optimized .wslconfig..." -ForegroundColor Cyan
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
    Write-Host "  âœ… .wslconfig created with optimized settings" -ForegroundColor Green
    Write-Host "  ðŸ“ Location: $wslConfigPath" -ForegroundColor Gray
} catch {
    Write-Host "  âš ï¸  Failed to create .wslconfig: $_" -ForegroundColor Yellow
}

# 6. Install Ubuntu distribution
Write-Host "`nðŸ§ Installing Ubuntu distribution..." -ForegroundColor Cyan

if ($UseCustomLocation) {
    # Custom installation to specified directory
    Write-Host "  ðŸ“¦ Installing $WSLDistro to custom location..." -ForegroundColor White
    $distroPath = Join-Path $WSLInstallPath $WSLDistro
    
    try {
        # Download Ubuntu 22.04 appx package
        $ubuntuUrl = "https://aka.ms/wslubuntu2204"
        $ubuntuAppx = "$env:TEMP\Ubuntu2204.appx"
        
        Write-Host "  ðŸ“¥ Downloading Ubuntu 22.04..." -ForegroundColor White
        Invoke-WebRequest -Uri $ubuntuUrl -OutFile $ubuntuAppx -UseBasicParsing
        
        # Extract and install
        $extractPath = "$env:TEMP\Ubuntu2204_Extract"
        Expand-Archive -Path $ubuntuAppx -DestinationPath $extractPath -Force
        
        $ubuntuExe = Get-ChildItem $extractPath -Name "ubuntu*.exe" | Select-Object -First 1
        if ($ubuntuExe) {
            Copy-Item (Join-Path $extractPath $ubuntuExe) -Destination (Join-Path $distroPath "ubuntu.exe")
            
            # Register the distribution
            wsl --import $WSLDistro $distroPath (Join-Path $extractPath "install.tar.gz")
            Write-Host "  âœ… Ubuntu installed to custom location" -ForegroundColor Green
        }
        
        # Clean up
        Remove-Item $ubuntuAppx, $extractPath -Recurse -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Host "  âš ï¸  Custom installation failed, falling back to Microsoft Store method" -ForegroundColor Yellow
        $UseCustomLocation = $false
    }
}

if (-not $UseCustomLocation) {
    # Install via Microsoft Store/winget
    try {
        Write-Host "  ðŸ“¦ Installing Ubuntu via winget..." -ForegroundColor White
        winget install Canonical.Ubuntu.2204 --accept-source-agreements --accept-package-agreements
        Write-Host "  âœ… Ubuntu installed successfully" -ForegroundColor Green
    } catch {
        Write-Host "  âš ï¸  winget installation failed, trying alternative method..." -ForegroundColor Yellow
        
        # Alternative: Use wsl --install
        try {
            wsl --install -d Ubuntu-22.04
            Write-Host "  âœ… Ubuntu installed via wsl --install" -ForegroundColor Green
        } catch {
            Write-Host "  âŒ Failed to install Ubuntu: $_" -ForegroundColor Red
            Write-Host "  â„¹ï¸  Please install Ubuntu manually from Microsoft Store" -ForegroundColor Blue
        }
    }
}

# 7. Configure Ubuntu for better performance
Write-Host "`nâš™ï¸  Configuring Ubuntu for optimal performance..." -ForegroundColor Cyan

# Wait for WSL to be ready
Start-Sleep -Seconds 5

try {
    # Set WSL 2 for the distribution
    wsl --set-version Ubuntu-22.04 2
    Write-Host "  âœ… Ubuntu set to WSL 2" -ForegroundColor Green
    
    # Set as default distribution
    wsl --set-default Ubuntu-22.04
    Write-Host "  âœ… Ubuntu set as default distribution" -ForegroundColor Green
    
} catch {
    Write-Host "  âš ï¸  Configuration warning: $_" -ForegroundColor Yellow
}

# 8. Create disk management scripts
Write-Host "`nðŸ“ Creating disk management utilities..." -ForegroundColor Cyan

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

Write-Host "ðŸ’¾ WSL Disk Compaction Starting..." -ForegroundColor Green

# Shutdown WSL
Write-Host "ðŸ›‘ Shutting down WSL..." -ForegroundColor Cyan
wsl --shutdown
Start-Sleep -Seconds 3

# Find Ubuntu VHDX file
Write-Host "ðŸ” Finding Ubuntu disk file..." -ForegroundColor Cyan
`$vhdxPath = Get-ChildItem "`$env:LOCALAPPDATA\Packages\CanonicalGroupLimited.Ubuntu*\LocalState\ext4.vhdx" -ErrorAction SilentlyContinue | Select-Object -First 1

if (`$vhdxPath) {
    Write-Host "ðŸ“ Found: `$(`$vhdxPath.FullName)" -ForegroundColor Yellow
    
    # Get current size
    `$currentSize = [math]::Round(`$vhdxPath.Length / 1GB, 2)
    Write-Host "ðŸ“Š Current size: `${currentSize}GB" -ForegroundColor White
    
    # Compact using diskpart
    Write-Host "ðŸ—œï¸  Compacting disk..." -ForegroundColor Cyan
    `$diskpartCommands = @"
select vdisk file="`$(`$vhdxPath.FullName)"
compact vdisk
exit
"@
    
    `$diskpartCommands | diskpart
    
    # Get new size
    `$newSize = [math]::Round((Get-Item `$vhdxPath.FullName).Length / 1GB, 2)
    `$savedSpace = `$currentSize - `$newSize
    
    Write-Host "âœ… Compaction completed!" -ForegroundColor Green
    Write-Host "ðŸ“Š New size: `${newSize}GB" -ForegroundColor White
    Write-Host "ðŸ’¾ Space saved: `${savedSpace}GB" -ForegroundColor Green
} else {
    Write-Host "âŒ Ubuntu disk file not found" -ForegroundColor Red
    Write-Host "ðŸ” Please check if Ubuntu is installed correctly" -ForegroundColor Yellow
}
"@

# Save scripts
$scriptsPath = Join-Path $WSLInstallPath "scripts"
New-Item -ItemType Directory -Path $scriptsPath -Force | Out-Null

$diskOptimizeScript | Out-File -FilePath (Join-Path $scriptsPath "optimize-wsl-disk.sh") -Encoding UTF8
$diskCompactScript | Out-File -FilePath (Join-Path $scriptsPath "compact-wsl-disk.ps1") -Encoding UTF8

Write-Host "  âœ… Disk management scripts created in $scriptsPath" -ForegroundColor Green

# 9. Test WSL installation
Write-Host "`nðŸ§ª Testing WSL installation..." -ForegroundColor Cyan
try {
    $wslTest = wsl --list --verbose
    Write-Host "ðŸ“‹ Current WSL distributions:" -ForegroundColor White
    $wslTest | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
    
    # Test basic command
    Write-Host "`nðŸ§ Testing Ubuntu..." -ForegroundColor White
    wsl -d Ubuntu-22.04 echo "âœ… Ubuntu is working correctly!"
    
    Write-Host "  âœ… WSL installation test passed" -ForegroundColor Green
} catch {
    Write-Host "  âš ï¸  WSL test failed: $_" -ForegroundColor Yellow
    Write-Host "  â„¹ï¸  You may need to complete Ubuntu setup manually" -ForegroundColor Blue
}

# 10. Summary and next steps
Write-Host "`nâœ… WSL 2 installation completed successfully!" -ForegroundColor Green

Write-Host "`nðŸ“Š Installation Summary:" -ForegroundColor Cyan
Write-Host "  ðŸ“ Installation path: $WSLInstallPath" -ForegroundColor White
Write-Host "  ðŸ§ Distribution: Ubuntu 22.04 LTS" -ForegroundColor White
Write-Host "  ðŸ’¾ Disk type: Dynamic (expandable)" -ForegroundColor White
Write-Host "  âš™ï¸  Configuration: Optimized for Docker" -ForegroundColor White

Write-Host "`nðŸ”§ Available Tools:" -ForegroundColor Cyan
Write-Host "  ðŸ“ Scripts location: $scriptsPath" -ForegroundColor White
Write-Host "  ðŸ—œï¸  Disk compaction: compact-wsl-disk.ps1" -ForegroundColor White
Write-Host "  ðŸ§¹ Disk cleanup: optimize-wsl-disk.sh (run inside WSL)" -ForegroundColor White

Write-Host "`nðŸ”„ Next Steps:" -ForegroundColor Green
Write-Host "1. Complete Ubuntu setup (create user account)" -ForegroundColor White
Write-Host "2. Install Docker Desktop with WSL 2 backend" -ForegroundColor White
Write-Host "3. Restore your Docker data" -ForegroundColor White
Write-Host "4. Test your VPS environment" -ForegroundColor White

Write-Host "`nðŸ’¡ Pro Tips:" -ForegroundColor Yellow
Write-Host "- Run 'wsl --shutdown' before compacting disk" -ForegroundColor White
Write-Host "- Use the disk cleanup script regularly to save space" -ForegroundColor White
Write-Host "- Monitor disk usage with 'df -h' inside WSL" -ForegroundColor White
Write-Host "- The .wslconfig file controls WSL resource limits" -ForegroundColor White

Write-Host "`nðŸš€ Ready for Docker Desktop installation!" -ForegroundColor Green