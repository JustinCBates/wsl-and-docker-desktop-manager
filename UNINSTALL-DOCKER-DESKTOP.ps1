# Docker Desktop Uninstall Script
# This script safely uninstalls Docker Desktop and cleans up residual files
# Run as Administrator

param(
    [switch]$Force = $false,
    [switch]$KeepUserData = $false
)

# Check for admin privileges
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "âŒ This script requires Administrator privileges"
    Write-Warning "Please run PowerShell as Administrator and try again"
    exit 1
}

Write-Information "ðŸ—‘ï¸  Docker Desktop Uninstall Starting..." -Tags Title
Write-Warning "âš ï¸  This will completely remove Docker Desktop from your system"

if (-not $Force) {
    $confirm = Read-Host "Are you sure you want to continue? (yes/no)"
        if ($confirm -ne "yes") {
        Write-Warning "âŒ Uninstall cancelled by user"
        exit 0
    }
}

# Function to stop services safely
function Stop-ServiceSafely {
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$ServiceName)
    try {
        $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($service -and $service.Status -eq "Running") {
            Write-Information "  ðŸ›' Stopping service: $ServiceName..." -Tags Info
            if ($PSCmdlet.ShouldProcess($ServiceName, "Stop service")) {
                Stop-Service -Name $ServiceName -Force
                Write-Information "  âœ… Service $ServiceName stopped" -Tags Success
            }
        }
    } catch {
        Write-Warning "  âš ï¸  Could not stop service $ServiceName`: $_"
    }
}

# Function to remove directory safely
function Remove-DirectorySafely {
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$Path, [string]$Description)
    if (Test-Path $Path) {
        try {
            Write-Information "  ðŸ—'ï¸  Removing $Description..." -Tags Info
            if ($PSCmdlet.ShouldProcess($Path, "Remove directory $Description")) {
                Remove-Item -Path $Path -Recurse -Force
                Write-Information "  âœ… $Description removed" -Tags Success
            }
        } catch {
            Write-Warning "  âš ï¸  Could not remove $Description`: $_"
        }
    }
}

# 1. Stop Docker processes and services
Write-Information "`nðŸ›‘ Stopping Docker processes..." -Tags Phase

# Stop Docker Desktop
try {
    Get-Process "Docker Desktop" -ErrorAction SilentlyContinue | Stop-Process -Force
    Write-Information "  âœ… Docker Desktop process stopped" -Tags Success
} catch {
    Write-Information "  â­ï¸  Docker Desktop process not running" -Tags Info
}

# Stop Docker services
$dockerServices = @("docker", "com.docker.service")
foreach ($service in $dockerServices) {
    Stop-ServiceSafely -ServiceName $service
}

# Stop WSL if requested
Write-Information "`nðŸ”„ Shutting down WSL..." -Tags Phase
try {
    wsl --shutdown
    Write-Information "  âœ… WSL shutdown completed" -Tags Success
} catch {
    Write-Warning "  âš ï¸  WSL shutdown failed: $_"
}

# 2. Uninstall Docker Desktop using Windows Package Manager
Write-Information "`nðŸ“¦ Uninstalling Docker Desktop..." -Tags Phase

# Try winget first
try {
    $wingetResult = winget uninstall "Docker Desktop" --accept-source-agreements
        if ($LASTEXITCODE -eq 0) {
        Write-Information "  âœ… Docker Desktop uninstalled via winget" -Tags Success
    } else {
        throw "winget uninstall failed"
    }
} catch {
    Write-Warning "  âš ï¸  winget uninstall failed, trying alternative methods..."
    
    # Try traditional uninstall
    $uninstallPath = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | 
                    Where-Object { $_.DisplayName -like "*Docker Desktop*" } |
                    Select-Object -ExpandProperty UninstallString -First 1
    
    if ($uninstallPath) {
        try {
            Write-Information "  ðŸ”„ Running Docker Desktop uninstaller..." -Tags Info
            Start-Process -FilePath $uninstallPath -ArgumentList "/S" -Wait
            Write-Information "  âœ… Docker Desktop uninstalled via traditional method" -Tags Success
        } catch {
            Write-Error "  âŒ Traditional uninstall failed: $_"
        }
    } else {
        Write-Warning "  âš ï¸  Docker Desktop uninstaller not found"
    }
}

# 3. Clean up Docker directories
Write-Information "`nðŸ§¹ Cleaning up Docker directories..." -Tags Phase

$cleanupPaths = @(
    @{Path = "$env:ProgramFiles\Docker"; Description = "Docker Program Files"},
    @{Path = "$env:ProgramData\Docker"; Description = "Docker Program Data"},
    @{Path = "$env:ProgramData\DockerDesktop"; Description = "Docker Desktop Data"}
)

if (-not $KeepUserData) {
    $cleanupPaths += @(
        @{Path = "$env:APPDATA\Docker"; Description = "Docker User AppData"},
        @{Path = "$env:LOCALAPPDATA\Docker"; Description = "Docker Local AppData"},
        @{Path = "$env:USERPROFILE\.docker"; Description = "Docker User Config"}
    )
}

foreach ($item in $cleanupPaths) {
    Remove-DirectorySafely -Path $item.Path -Description $item.Description
}

# 4. Remove Docker from PATH
Write-Information "`nðŸ›¤ï¸  Cleaning up PATH environment..." -Tags Phase
try {
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
    $dockerPaths = @("$env:ProgramFiles\Docker\Docker\resources\bin")
    
    foreach ($dockerPath in $dockerPaths) {
        if ($currentPath -like "*$dockerPath*") {
            $newPath = $currentPath -replace [regex]::Escape(";$dockerPath"), ""
            $newPath = $newPath -replace [regex]::Escape("$dockerPath;"), ""
            $newPath = $newPath -replace [regex]::Escape($dockerPath), ""
            [Environment]::SetEnvironmentVariable("PATH", $newPath, "Machine")
            Write-Information "  âœ… Removed Docker from system PATH" -Tags Success
        }
    }
} catch {
    Write-Warning "  âš ï¸  Could not clean PATH: $_"
}

# 5. Remove Docker registry entries
Write-Information "`nðŸ“‹ Cleaning up registry entries..." -Tags Phase
$registryPaths = @(
    "HKLM:\SOFTWARE\Docker Inc.",
    "HKCU:\SOFTWARE\Docker Inc."
)

foreach ($regPath in $registryPaths) {
    if (Test-Path $regPath) {
        try {
            Remove-Item -Path $regPath -Recurse -Force
            Write-Information "  âœ… Removed registry entry: $regPath" -Tags Success
        } catch {
            Write-Warning "  âš ï¸  Could not remove registry entry $regPath`: $_"
        }
    }
}

# 6. Clean up Windows Features (if needed)
Write-Information "`nðŸ”§ Checking Windows Features..." -Tags Phase
try {
    $hyperV = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All
    if ($hyperV.State -eq "Enabled") {
        Write-Information "  â„¹ï¸  Hyper-V is still enabled (may be needed for other applications)" -Tags Info
        $disableHyperV = Read-Host "  Do you want to disable Hyper-V? (yes/no)"
        if ($disableHyperV -eq "yes") {
            Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -NoRestart
            Write-Information "  âœ… Hyper-V disabled (restart required)" -Tags Success
        }
    }
} catch {
    Write-Warning "  âš ï¸  Could not check Hyper-V status: $_"
}

# 7. Summary and next steps
Write-Information "`nâœ… Docker Desktop uninstall completed!" -Tags Success

if (-not $KeepUserData) {
    Write-Warning "ðŸ—‘ï¸  All Docker data and configurations removed"
} else {
    Write-Information "ðŸ’¾ User data preserved as requested" -Tags Info
}

Write-Information "`nðŸ”„ Next steps:" -Tags Info
Write-Information "1. Restart your computer if Hyper-V was disabled" -Tags Info
Write-Information "2. Run the WSL uninstall script next" -Tags Info
Write-Information "3. Then reinstall WSL 2 with dynamic disk configuration" -Tags Info

Write-Warning "`nâš ï¸  Important:"
Write-Information "- Some registry entries may require a restart to be fully cleared" -Tags Info
Write-Information "- Check Task Manager to ensure no Docker processes remain" -Tags Info
Write-Information "- Your Docker backup is safe and ready for restoration" -Tags Info