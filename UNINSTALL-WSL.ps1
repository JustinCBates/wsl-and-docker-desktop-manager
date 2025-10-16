# WSL Uninstall Script
# This script removes WSL 2 and all distributions to prepare for clean reinstallation
# Run as Administrator

param(
    [switch]$Force = $false,
    [string]$BackupPath = "C:\WSLBackup\$(Get-Date -Format 'yyyy-MM-dd-HHmm')"
)

# Check for admin privileges
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "❌ This script requires Administrator privileges" -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again" -ForegroundColor Yellow
    exit 1
}

Write-Host "🗑️  WSL Complete Uninstall Starting..." -ForegroundColor Red
Write-Host "⚠️  This will remove ALL WSL distributions and data" -ForegroundColor Yellow

if (-not $Force) {
    $confirm = Read-Host "Are you sure you want to continue? This will delete all WSL data! (yes/no)"
    if ($confirm -ne "yes") {
        Write-Host "❌ Uninstall cancelled by user" -ForegroundColor Yellow
        exit 0
    }
}

# Create backup directory
Write-Host "`n📁 Creating backup directory: $BackupPath" -ForegroundColor Cyan
New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null

# 1. List and backup WSL distributions
Write-Host "`n📋 Checking current WSL distributions..." -ForegroundColor Cyan
try {
    $wslList = wsl --list --verbose 2>$null
    if ($wslList) {
        Write-Host "Current WSL distributions:" -ForegroundColor White
        $wslList | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
        
        # Save the list to backup
        $wslList | Out-File -FilePath (Join-Path $BackupPath "wsl-distributions-before-removal.txt") -Encoding UTF8
        
        # Offer to export distributions
        $exportChoice = Read-Host "`nDo you want to export WSL distributions before removal? (yes/no)"
        if ($exportChoice -eq "yes") {
            Write-Host "📦 Exporting WSL distributions..." -ForegroundColor Cyan
            
            # Get distribution names (skip header and parse)
            $distributions = wsl --list --quiet 2>$null | Where-Object { $_ -and $_.Trim() -ne "" }
            
            foreach ($distro in $distributions) {
                $distroName = $distro.Trim()
                if ($distroName) {
                    $exportFile = Join-Path $BackupPath "$distroName.tar"
                    Write-Host "  📦 Exporting $distroName..." -ForegroundColor White
                    try {
                        wsl --export $distroName $exportFile
                        Write-Host "  ✅ $distroName exported successfully" -ForegroundColor Green
                    } catch {
                        Write-Host "  ⚠️  Failed to export $distroName`: $_" -ForegroundColor Yellow
                    }
                }
            }
        }
    } else {
        Write-Host "  ℹ️  No WSL distributions found" -ForegroundColor Blue
    }
} catch {
    Write-Host "  ⚠️  Could not list WSL distributions: $_" -ForegroundColor Yellow
}

# 2. Shutdown WSL
Write-Host "`n🛑 Shutting down WSL..." -ForegroundColor Cyan
try {
    wsl --shutdown
    Start-Sleep -Seconds 3
    Write-Host "  ✅ WSL shutdown completed" -ForegroundColor Green
} catch {
    Write-Host "  ⚠️  WSL shutdown failed: $_" -ForegroundColor Yellow
}

# 3. Unregister all WSL distributions
Write-Host "`n🗑️  Unregistering WSL distributions..." -ForegroundColor Cyan
try {
    $distributions = wsl --list --quiet 2>$null | Where-Object { $_ -and $_.Trim() -ne "" }
    
    if ($distributions) {
        foreach ($distro in $distributions) {
            $distroName = $distro.Trim()
            if ($distroName) {
                Write-Host "  🗑️  Unregistering $distroName..." -ForegroundColor White
                try {
                    wsl --unregister $distroName
                    Write-Host "  ✅ $distroName unregistered successfully" -ForegroundColor Green
                } catch {
                    Write-Host "  ⚠️  Failed to unregister $distroName`: $_" -ForegroundColor Yellow
                }
            }
        }
    } else {
        Write-Host "  ℹ️  No distributions to unregister" -ForegroundColor Blue
    }
} catch {
    Write-Host "  ⚠️  Could not unregister distributions: $_" -ForegroundColor Yellow
}

# 4. Remove WSL directories
Write-Host "`n🧹 Cleaning up WSL directories..." -ForegroundColor Cyan

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
                    Write-Host "  🗑️  Removing $($item.Description): $($path.Name)..." -ForegroundColor White
                    Remove-Item -Path $path.FullName -Recurse -Force
                    Write-Host "  ✅ $($path.Name) removed" -ForegroundColor Green
                } catch {
                    Write-Host "  ⚠️  Could not remove $($path.Name): $_" -ForegroundColor Yellow
                }
            }
        }
    } else {
        if (Test-Path $item.Path) {
            try {
                Write-Host "  🗑️  Removing $($item.Description)..." -ForegroundColor White
                if ($item.Path.EndsWith('.wslconfig')) {
                    # Backup .wslconfig before removing
                    Copy-Item $item.Path -Destination (Join-Path $BackupPath ".wslconfig.backup")
                }
                Remove-Item -Path $item.Path -Recurse -Force
                Write-Host "  ✅ $($item.Description) removed" -ForegroundColor Green
            } catch {
                Write-Host "  ⚠️  Could not remove $($item.Description): $_" -ForegroundColor Yellow
            }
        }
    }
}

# 5. Disable WSL Windows Features
Write-Host "`n🔧 Disabling WSL Windows Features..." -ForegroundColor Cyan

$wslFeatures = @(
    "Microsoft-Windows-Subsystem-Linux",
    "VirtualMachinePlatform"
)

foreach ($feature in $wslFeatures) {
    try {
        $featureStatus = Get-WindowsOptionalFeature -Online -FeatureName $feature
        if ($featureStatus.State -eq "Enabled") {
            Write-Host "  🔧 Disabling $feature..." -ForegroundColor White
            Disable-WindowsOptionalFeature -Online -FeatureName $feature -NoRestart
            Write-Host "  ✅ $feature disabled" -ForegroundColor Green
        } else {
            Write-Host "  ⏭️  $feature already disabled" -ForegroundColor Gray
        }
    } catch {
        Write-Host "  ⚠️  Could not disable $feature`: $_" -ForegroundColor Yellow
    }
}

# 6. Clean up registry entries
Write-Host "`n📋 Cleaning up WSL registry entries..." -ForegroundColor Cyan
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
            
            Write-Host "  🗑️  Removing registry: $regPath..." -ForegroundColor White
            Remove-Item -Path $regPath -Recurse -Force
            Write-Host "  ✅ Registry entry removed" -ForegroundColor Green
        } catch {
            Write-Host "  ⚠️  Could not remove registry entry $regPath`: $_" -ForegroundColor Yellow
        }
    }
}

# 7. Create restoration info
Write-Host "`n📝 Creating restoration information..." -ForegroundColor Cyan
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
Write-Host "`n✅ WSL uninstall completed!" -ForegroundColor Green
Write-Host "📁 Backup location: $BackupPath" -ForegroundColor Yellow

Write-Host "`n🔄 Next steps:" -ForegroundColor Green
Write-Host "1. RESTART your computer (required for feature changes)" -ForegroundColor White
Write-Host "2. After restart, run the WSL 2 reinstallation script" -ForegroundColor White
Write-Host "3. Configure WSL 2 with dynamic disk allocation" -ForegroundColor White

Write-Host "`n⚠️  Important:" -ForegroundColor Yellow
Write-Host "- A restart is REQUIRED for Windows features to be fully disabled" -ForegroundColor White
Write-Host "- Keep the backup folder safe until WSL is successfully reinstalled" -ForegroundColor White
Write-Host "- The next script will reinstall WSL 2 with improved disk management" -ForegroundColor White

Write-Host "`n🔄 Restart required - please restart your computer before continuing" -ForegroundColor Red