# WSL Uninstall Script
# This script removes WSL 2 and all distributions to prepare for clean reinstallation
# Run as Administrator

param(
    [switch]$Force = $false,
    [string]$BackupPath = "C:\WSLBackup\$(Get-Date -Format 'yyyy-MM-dd-HHmm')"
)

# Check for admin privileges
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "âŒ This script requires Administrator privileges"
    Write-Warning "Please run PowerShell as Administrator and try again"
    exit 1
}

Write-Information "ðŸ—‘ï¸  WSL Complete Uninstall Starting..." -Tags Title
Write-Warning "âš ï¸  This will remove ALL WSL distributions and data"

if (-not $Force) {
    $confirm = Read-Host "Are you sure you want to continue? This will delete all WSL data! (yes/no)"
        if ($confirm -ne "yes") {
        Write-Warning "âŒ Uninstall cancelled by user"
        exit 0
    }
}

# Create backup directory
Write-Information "`nðŸ“ Creating backup directory: $BackupPath" -Tags Info
New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null

# 1. List and backup WSL distributions
Write-Information "`nðŸ“‹ Checking current WSL distributions..." -Tags Info
try {
    $wslList = wsl --list --verbose 2>$null
    if ($wslList) {
        Write-Information "Current WSL distributions:" -Tags Info
        $wslList | ForEach-Object { Write-Information "  $_" -Tags Info }
        
        # Save the list to backup
        $wslList | Out-File -FilePath (Join-Path $BackupPath "wsl-distributions-before-removal.txt") -Encoding UTF8
        
        # Offer to export distributions
        $exportChoice = Read-Host "`nDo you want to export WSL distributions before removal? (yes/no)"
        if ($exportChoice -eq "yes") {
            Write-Information "ðŸ“¦ Exporting WSL distributions..." -Tags Info
            
            # Get distribution names (skip header and parse)
            $distributions = wsl --list --quiet 2>$null | Where-Object { $_ -and $_.Trim() -ne "" }
            
            foreach ($distro in $distributions) {
                $distroName = $distro.Trim()
                if ($distroName) {
                    $exportFile = Join-Path $BackupPath "$distroName.tar"
                    Write-Information "  ðŸ“¦ Exporting $distroName..." -Tags Info
                    try {
                        wsl --export $distroName $exportFile
                        Write-Information "  âœ… $distroName exported successfully" -Tags Success
                    } catch {
                        Write-Warning "  âš ï¸  Failed to export $distroName`: $_"
                    }
                }
            }
        }
    } else {
        Write-Information "  â„¹ï¸  No WSL distributions found" -Tags Info
    }
} catch {
    Write-Warning "  âš ï¸  Could not list WSL distributions: $_"
}

# 2. Shutdown WSL
Write-Information "`nðŸ›‘ Shutting down WSL..." -Tags Phase
try {
    wsl --shutdown
    Start-Sleep -Seconds 3
    Write-Information "  âœ… WSL shutdown completed" -Tags Success
} catch {
    Write-Warning "  âš ï¸  WSL shutdown failed: $_"
}

# 3. Unregister all WSL distributions
Write-Information "`nðŸ—‘ï¸  Unregistering WSL distributions..." -Tags Phase
try {
    $distributions = wsl --list --quiet 2>$null | Where-Object { $_ -and $_.Trim() -ne "" }
    
    if ($distributions) {
        foreach ($distro in $distributions) {
            $distroName = $distro.Trim()
            if ($distroName) {
                Write-Information "  ðŸ—‘ï¸  Unregistering $distroName..." -Tags Info
                try {
                    wsl --unregister $distroName
                    Write-Information "  âœ… $distroName unregistered successfully" -Tags Success
                } catch {
                    Write-Warning "  âš ï¸  Failed to unregister $distroName`: $_"
                }
            }
        }
    } else {
        Write-Information "  â„¹ï¸  No distributions to unregister" -Tags Info
    }
} catch {
    Write-Warning "  âš ï¸  Could not unregister distributions: $_"
}

# 4. Remove WSL directories
Write-Information "`nðŸ§¹ Cleaning up WSL directories..." -Tags Phase

$wslPaths = @(
    @{Path = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsSubsystemForLinux_8wekyb3d8bbwe"; Description = "WSL Package Data"},
    @{Path = "$env:LOCALAPPDATA\Packages\CanonicalGroupLimited.Ubuntu*"; Description = "Ubuntu Packages"},
    @{Path = "$env:LOCALAPPDATA\Packages\TheDebianProject.DebianGNULinux*"; Description = "Debian Packages"},
    @{Path = "$env:LOCALAPPDATA\lxss"; Description = "Legacy WSL Data"},
    @{Path = "$env:USERPROFILE\.wslconfig"; Description = "WSL User Config"}
)

foreach ($item in $wslPaths) {
    if ($item.Path -like "*`**") {
        # Handle wildcard paths
        $matchingPaths = Get-ChildItem -Path ($item.Path -replace '\*.*$', '') -Directory -ErrorAction SilentlyContinue | 
                        Where-Object { $_.Name -like ($item.Path.Split('\')[-1]) }
        
        foreach ($path in $matchingPaths) {
            if (Test-Path $path.FullName) {
                try {
                    Write-Information "  ðŸ—‘ï¸  Removing $($item.Description): $($path.Name)..." -Tags Info
                    Remove-Item -Path $path.FullName -Recurse -Force
                    Write-Information "  âœ… $($path.Name) removed" -Tags Success
                } catch {
                    Write-Warning "  âš ï¸  Could not remove $($path.Name): $_"
                }
            }
        }
    } else {
        if (Test-Path $item.Path) {
            try {
                Write-Information "  ðŸ—‘ï¸  Removing $($item.Description)..." -Tags Info
                if ($item.Path.EndsWith('.wslconfig')) {
                    # Backup .wslconfig before removing
                    Copy-Item $item.Path -Destination (Join-Path $BackupPath ".wslconfig.backup")
                }
                Remove-Item -Path $item.Path -Recurse -Force
                Write-Information "  âœ… $($item.Description) removed" -Tags Success
            } catch {
                Write-Warning "  âš ï¸  Could not remove $($item.Description): $_"
            }
        }
    }
}

# 5. Disable WSL Windows Features
Write-Information "`nðŸ”§ Disabling WSL Windows Features..." -Tags Phase

$wslFeatures = @(
    "Microsoft-Windows-Subsystem-Linux",
    "VirtualMachinePlatform"
)

foreach ($feature in $wslFeatures) {
    try {
        $featureStatus = Get-WindowsOptionalFeature -Online -FeatureName $feature
        if ($featureStatus.State -eq "Enabled") {
            Write-Information "  ðŸ”§ Disabling $feature..." -Tags Info
            Disable-WindowsOptionalFeature -Online -FeatureName $feature -NoRestart
            Write-Information "  âœ… $feature disabled" -Tags Success
        } else {
            Write-Information "  â­ï¸  $feature already disabled" -Tags Info
        }
    } catch {
        Write-Warning "  âš ï¸  Could not disable $feature`: $_"
    }
}

# 6. Clean up registry entries
Write-Information "`nðŸ“‹ Cleaning up WSL registry entries..." -Tags Info
$registryPaths = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss"
)

foreach ($regPath in $registryPaths) {
    if (Test-Path $regPath) {
        try {
            # Backup registry before removal
            $regBackupFile = Join-Path $BackupPath "$($regPath.Replace(':', '').Replace('\', '_')).reg"
            reg export $regPath.Replace('HKCU:', 'HKEY_CURRENT_USER').Replace('HKLM:', 'HKEY_LOCAL_MACHINE') $regBackupFile /y 2>$null
            
            Write-Information "  ðŸ—‘ï¸  Removing registry: $regPath..." -Tags Info
            Remove-Item -Path $regPath -Recurse -Force
            Write-Information "  âœ… Registry entry removed" -Tags Success
        } catch {
            Write-Warning "  âš ï¸  Could not remove registry entry $regPath`: $_"
        }
    }
}

# 7. Create restoration info
Write-Information "`nðŸ“ Creating restoration information..." -Tags Info
$restorationInfo = @"
# WSL Restoration Information
# Generated on: $(Get-Date)

## Exported Distributions
The following distributions were exported before removal:
$(if (Test-Path "$BackupPath\*.tar") { 
    Get-ChildItem "$BackupPath\*.tar" | ForEach-Object { "- $($_.BaseName)" }
} else { 
    "- No distributions were exported" 
})

## Configuration Backup
$( if (Test-Path "$BackupPath\.wslconfig.backup") { "- .wslconfig backed up" } else { "- No .wslconfig found" } )

## Registry Backups
$(Get-ChildItem "$BackupPath\*.reg" -ErrorAction SilentlyContinue | ForEach-Object { "- $($_.Name)" })

## Restoration Commands
To restore distributions after WSL reinstallation:

# Import distributions:
$(if (Test-Path "$BackupPath\*.tar") { 
    Get-ChildItem "$BackupPath\*.tar" | ForEach-Object { 
        "wsl --import $($_.BaseName) C:\WSL\$($_.BaseName) `"$($_.FullName)`""
    }
} else { 
    "# No distributions to restore" 
})

# Restore .wslconfig:
$( if (Test-Path "$BackupPath\.wslconfig.backup") { 
    "Copy-Item `"$BackupPath\.wslconfig.backup`" `"$env:USERPROFILE\.wslconfig`""
} else { 
    "# No .wslconfig to restore" 
})
"@

$restorationInfo | Out-File -FilePath (Join-Path $BackupPath "RESTORATION-INFO.txt") -Encoding UTF8

# 8. Summary
Write-Information "`nâœ… WSL uninstall completed!" -Tags Success
Write-Information "ðŸ“ Backup location: $BackupPath" -Tags Info

Write-Information "`nðŸ”„ Next steps:" -Tags Info
Write-Information "1. RESTART your computer (required for feature changes)" -Tags Info
Write-Information "2. After restart, run the WSL 2 reinstallation script" -Tags Info
Write-Information "3. Configure WSL 2 with dynamic disk allocation" -Tags Info

Write-Warning "`nâš ï¸  Important:"
Write-Information "- A restart is REQUIRED for Windows features to be fully disabled" -Tags Info
Write-Information "- Keep the backup folder safe until WSL is successfully reinstalled" -Tags Info
Write-Information "- The next script will reinstall WSL 2 with improved disk management" -Tags Info

Write-Warning "`nðŸ”„ Restart required - please restart your computer before continuing"