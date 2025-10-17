# Docker Desktop Uninstall Script
# This script safely uninstalls Docker Desktop and cleans up residual files
# Run as Administrator

param(
    [switch]$Force = $false,
    [switch]$KeepUserData = $false
)

# Check for admin privileges
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "âŒ This script requires Administrator privileges" -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again" -ForegroundColor Yellow
    exit 1
}

Write-Host "ðŸ—‘ï¸  Docker Desktop Uninstall Starting..." -ForegroundColor Red
Write-Host "âš ï¸  This will completely remove Docker Desktop from your system" -ForegroundColor Yellow

if (-not $Force) {
    $confirm = Read-Host "Are you sure you want to continue? (yes/no)"
    if ($confirm -ne "yes") {
        Write-Host "âŒ Uninstall cancelled by user" -ForegroundColor Yellow
        exit 0
    }
}

# Function to stop services safely
function Stop-ServiceSafely {
    param([string]$ServiceName)
    try {
        $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($service -and $service.Status -eq "Running") {
            Write-Host "  ðŸ›‘ Stopping service: $ServiceName..." -ForegroundColor White
            Stop-Service -Name $ServiceName -Force
            Write-Host "  âœ… Service $ServiceName stopped" -ForegroundColor Green
        }
    } catch {
        Write-Host "  âš ï¸  Could not stop service $ServiceName`: $_" -ForegroundColor Yellow
    }
}

# Function to remove directory safely
function Remove-DirectorySafely {
    param([string]$Path, [string]$Description)
    if (Test-Path $Path) {
        try {
            Write-Host "  ðŸ—‘ï¸  Removing $Description..." -ForegroundColor White
            Remove-Item -Path $Path -Recurse -Force
            Write-Host "  âœ… $Description removed" -ForegroundColor Green
        } catch {
            Write-Host "  âš ï¸  Could not remove $Description`: $_" -ForegroundColor Yellow
        }
    }
}

# 1. Stop Docker processes and services
Write-Host "`nðŸ›‘ Stopping Docker processes..." -ForegroundColor Cyan

# Stop Docker Desktop
try {
    Get-Process "Docker Desktop" -ErrorAction SilentlyContinue | Stop-Process -Force
    Write-Host "  âœ… Docker Desktop process stopped" -ForegroundColor Green
} catch {
    Write-Host "  â­ï¸  Docker Desktop process not running" -ForegroundColor Gray
}

# Stop Docker services
$dockerServices = @("docker", "com.docker.service")
foreach ($service in $dockerServices) {
    Stop-ServiceSafely -ServiceName $service
}

# Stop WSL if requested
Write-Host "`nðŸ”„ Shutting down WSL..." -ForegroundColor Cyan
try {
    wsl --shutdown
    Write-Host "  âœ… WSL shutdown completed" -ForegroundColor Green
} catch {
    Write-Host "  âš ï¸  WSL shutdown failed: $_" -ForegroundColor Yellow
}

# 2. Uninstall Docker Desktop using Windows Package Manager
Write-Host "`nðŸ“¦ Uninstalling Docker Desktop..." -ForegroundColor Cyan

# Try winget first
try {
    $wingetResult = winget uninstall "Docker Desktop" --accept-source-agreements
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  âœ… Docker Desktop uninstalled via winget" -ForegroundColor Green
    } else {
        throw "winget uninstall failed"
    }
} catch {
    Write-Host "  âš ï¸  winget uninstall failed, trying alternative methods..." -ForegroundColor Yellow
    
    # Try traditional uninstall
    $uninstallPath = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | 
                    Where-Object { $_.DisplayName -like "*Docker Desktop*" } |
                    Select-Object -ExpandProperty UninstallString -First 1
    
    if ($uninstallPath) {
        try {
            Write-Host "  ðŸ”„ Running Docker Desktop uninstaller..." -ForegroundColor White
            Start-Process -FilePath $uninstallPath -ArgumentList "/S" -Wait
            Write-Host "  âœ… Docker Desktop uninstalled via traditional method" -ForegroundColor Green
        } catch {
            Write-Host "  âŒ Traditional uninstall failed: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "  âš ï¸  Docker Desktop uninstaller not found" -ForegroundColor Yellow
    }
}

# 3. Clean up Docker directories
Write-Host "`nðŸ§¹ Cleaning up Docker directories..." -ForegroundColor Cyan

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
Write-Host "`nðŸ›¤ï¸  Cleaning up PATH environment..." -ForegroundColor Cyan
try {
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
    $dockerPaths = @("$env:ProgramFiles\Docker\Docker\resources\bin")
    
    foreach ($dockerPath in $dockerPaths) {
        if ($currentPath -like "*$dockerPath*") {
            $newPath = $currentPath -replace [regex]::Escape(";$dockerPath"), ""
            $newPath = $newPath -replace [regex]::Escape("$dockerPath;"), ""
            $newPath = $newPath -replace [regex]::Escape($dockerPath), ""
            [Environment]::SetEnvironmentVariable("PATH", $newPath, "Machine")
            Write-Host "  âœ… Removed Docker from system PATH" -ForegroundColor Green
        }
    }
} catch {
    Write-Host "  âš ï¸  Could not clean PATH: $_" -ForegroundColor Yellow
}

# 5. Remove Docker registry entries
Write-Host "`nðŸ“‹ Cleaning up registry entries..." -ForegroundColor Cyan
$registryPaths = @(
    "HKLM:\SOFTWARE\Docker Inc.",
    "HKCU:\SOFTWARE\Docker Inc."
)

foreach ($regPath in $registryPaths) {
    if (Test-Path $regPath) {
        try {
            Remove-Item -Path $regPath -Recurse -Force
            Write-Host "  âœ… Removed registry entry: $regPath" -ForegroundColor Green
        } catch {
            Write-Host "  âš ï¸  Could not remove registry entry $regPath`: $_" -ForegroundColor Yellow
        }
    }
}

# 6. Clean up Windows Features (if needed)
Write-Host "`nðŸ”§ Checking Windows Features..." -ForegroundColor Cyan
try {
    $hyperV = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All
    if ($hyperV.State -eq "Enabled") {
        Write-Host "  â„¹ï¸  Hyper-V is still enabled (may be needed for other applications)" -ForegroundColor Blue
        $disableHyperV = Read-Host "  Do you want to disable Hyper-V? (yes/no)"
        if ($disableHyperV -eq "yes") {
            Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -NoRestart
            Write-Host "  âœ… Hyper-V disabled (restart required)" -ForegroundColor Green
        }
    }
} catch {
    Write-Host "  âš ï¸  Could not check Hyper-V status: $_" -ForegroundColor Yellow
}

# 7. Summary and next steps
Write-Host "`nâœ… Docker Desktop uninstall completed!" -ForegroundColor Green

if (-not $KeepUserData) {
    Write-Host "ðŸ—‘ï¸  All Docker data and configurations removed" -ForegroundColor Yellow
} else {
    Write-Host "ðŸ’¾ User data preserved as requested" -ForegroundColor Blue
}

Write-Host "`nðŸ”„ Next steps:" -ForegroundColor Green
Write-Host "1. Restart your computer if Hyper-V was disabled" -ForegroundColor White
Write-Host "2. Run the WSL uninstall script next" -ForegroundColor White
Write-Host "3. Then reinstall WSL 2 with dynamic disk configuration" -ForegroundColor White

Write-Host "`nâš ï¸  Important:" -ForegroundColor Yellow
Write-Host "- Some registry entries may require a restart to be fully cleared" -ForegroundColor White
Write-Host "- Check Task Manager to ensure no Docker processes remain" -ForegroundColor White
Write-Host "- Your Docker backup is safe and ready for restoration" -ForegroundColor White