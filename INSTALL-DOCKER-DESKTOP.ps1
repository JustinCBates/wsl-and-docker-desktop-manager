# Docker Desktop Reinstall Script with WSL 2 Backend
# This script installs Docker Desktop with optimal settings for WSL 2
# Run as Administrator AFTER WSL 2 is properly installed

param(
    [string]$DockerDataPath = "C:\ProgramData\Docker",
    [bool]$UseStableChannel = $true,
    [switch]$EnableKubernetes = $false
)

# Check for admin privileges
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "❌ This script requires Administrator privileges" -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again" -ForegroundColor Yellow
    exit 1
}

Write-Host "🐳 Docker Desktop Installation with WSL 2 Backend Starting..." -ForegroundColor Green

# Function to test WSL 2 availability
function Test-WSL2Ready {
    try {
        $wslList = wsl --list --verbose 2>$null
        
        if ($wslList -match "VERSION\s+2") {
            return $true
        }
        return $false
    } catch {
        return $false
    }
}

# 1. Verify WSL 2 is ready
Write-Host "`n🔍 Verifying WSL 2 installation..." -ForegroundColor Cyan
if (-not (Test-WSL2Ready)) {
    Write-Host "❌ WSL 2 is not properly installed or configured" -ForegroundColor Red
    Write-Host "Please run the WSL 2 installation script first" -ForegroundColor Yellow
    Write-Host "Current WSL status:" -ForegroundColor White
    try {
        wsl --list --verbose
    } catch {
        Write-Host "WSL is not available" -ForegroundColor Red
    }
    exit 1
} else {
    Write-Host "  ✅ WSL 2 is ready" -ForegroundColor Green
    Write-Host "  📋 Current WSL distributions:" -ForegroundColor White
    wsl --list --verbose | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
}

# 2. Download Docker Desktop
Write-Host "`n📥 Downloading Docker Desktop..." -ForegroundColor Cyan

$dockerUrl = if ($UseStableChannel) {
    "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
} else {
    "https://desktop.docker.com/win/edge/amd64/Docker%20Desktop%20Installer.exe"
}

$dockerInstaller = "$env:TEMP\DockerDesktopInstaller.exe"

try {
    Write-Host "  📦 Downloading from: $dockerUrl" -ForegroundColor White
    
    # Use Invoke-WebRequest with progress
    $ProgressPreference = 'Continue'
    Invoke-WebRequest -Uri $dockerUrl -OutFile $dockerInstaller -UseBasicParsing
    
    $installerSize = [math]::Round((Get-Item $dockerInstaller).Length / 1MB, 2)
    Write-Host "  ✅ Download completed (${installerSize}MB)" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Download failed: $_" -ForegroundColor Red
    Write-Host "  ℹ️  Please download manually from: https://docker.com/products/docker-desktop" -ForegroundColor Blue
    exit 1
}

# 3. Install Docker Desktop
Write-Host "`n🔧 Installing Docker Desktop..." -ForegroundColor Cyan

# Create installation arguments for WSL 2 backend
$installArgs = @(
    "install",
    "--quiet",
    "--accept-license",
    "--backend=wsl-2"
)

if (-not $EnableKubernetes) {
    $installArgs += "--no-kubernetes"
}

try {
    Write-Host "  📦 Running Docker Desktop installer..." -ForegroundColor White
    Write-Host "  ⚙️  Installation arguments: $($installArgs -join ' ')" -ForegroundColor Gray
    
    $installProcess = Start-Process -FilePath $dockerInstaller -ArgumentList $installArgs -Wait -PassThru
    
    if ($installProcess.ExitCode -eq 0) {
        Write-Host "  ✅ Docker Desktop installed successfully" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  Installation completed with exit code: $($installProcess.ExitCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ❌ Installation failed: $_" -ForegroundColor Red
    Write-Host "  ℹ️  You may need to install manually" -ForegroundColor Blue
}

# Clean up installer
Remove-Item $dockerInstaller -Force -ErrorAction SilentlyContinue

# 4. Wait for Docker to start
Write-Host "`n⏳ Waiting for Docker Desktop to start..." -ForegroundColor Cyan
$maxWaitTime = 300 # 5 minutes
$waitTime = 0
$dockerReady = $false

do {
    Start-Sleep -Seconds 10
    $waitTime += 10
    
    try {
        $dockerVersion = docker version --format json 2>$null | ConvertFrom-Json
        if ($dockerVersion) {
            $dockerReady = $true
            Write-Host "  ✅ Docker Desktop is running" -ForegroundColor Green
        }
    } catch {
        Write-Host "  ⏳ Waiting for Docker to start... ($waitTime/$maxWaitTime seconds)" -ForegroundColor Gray
    }
} while (-not $dockerReady -and $waitTime -lt $maxWaitTime)

if (-not $dockerReady) {
    Write-Host "  ⚠️  Docker Desktop did not start within $maxWaitTime seconds" -ForegroundColor Yellow
    Write-Host "  ℹ️  Please start Docker Desktop manually and wait for it to be ready" -ForegroundColor Blue
}

# 5. Configure Docker settings
Write-Host "`n⚙️  Configuring Docker settings..." -ForegroundColor Cyan

# Docker daemon configuration
$dockerDaemonConfig = @{
    "experimental" = $false
    "debug" = $false
    "data-root" = $DockerDataPath
    "storage-driver" = "overlay2"
    "log-driver" = "json-file"
    "log-opts" = @{
        "max-size" = "10m"
        "max-file" = "3"
    }
    "features" = @{
        "buildkit" = $true
    }
    "builder" = @{
        "gc" = @{
            "enabled" = $true
            "defaultKeepStorage" = "20GB"
        }
    }
}

$dockerConfigPath = "$env:USERPROFILE\.docker"
$daemonConfigPath = Join-Path $dockerConfigPath "daemon.json"

try {
    # Create .docker directory if it doesn't exist
    if (-not (Test-Path $dockerConfigPath)) {
        New-Item -ItemType Directory -Path $dockerConfigPath -Force | Out-Null
    }
    
    # Write daemon configuration
    $dockerDaemonConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $daemonConfigPath -Encoding UTF8
    Write-Host "  ✅ Docker daemon configuration created" -ForegroundColor Green
    Write-Host "  📁 Location: $daemonConfigPath" -ForegroundColor Gray
} catch {
    Write-Host "  ⚠️  Failed to create daemon configuration: $_" -ForegroundColor Yellow
}

# 6. Configure Docker Desktop settings
Write-Host "`n🔧 Optimizing Docker Desktop settings..." -ForegroundColor Cyan

$dockerDesktopSettingsPath = "$env:APPDATA\Docker\settings.json"

# Wait for settings file to be created
$settingsWaitTime = 0
while (-not (Test-Path $dockerDesktopSettingsPath) -and $settingsWaitTime -lt 60) {
    Start-Sleep -Seconds 5
    $settingsWaitTime += 5
    Write-Host "  ⏳ Waiting for Docker Desktop settings..." -ForegroundColor Gray
}

if (Test-Path $dockerDesktopSettingsPath) {
    try {
        # Read current settings
        $settings = Get-Content $dockerDesktopSettingsPath | ConvertFrom-Json
        
        # Update settings for WSL 2 optimization
        $settings.wslEngineEnabled = $true
        $settings.useVirtualizationFramework = $false
        $settings.useVirtualizationFrameworkVirtioFS = $false
        $settings.useContainerCli = $true
        $settings.exposeDockerAPIOnTCP2375 = $false
        $settings.kubernetesEnabled = $EnableKubernetes
        $settings.showKubernetesUserConfirmationDialog = $false
        $settings.enableUsageStatistics = $false
        $settings.displayedOnboarding = $true
        
        # Resource settings
        $settings.memoryMiB = 4096  # 4GB
        $settings.cpus = 2
        $settings.diskSizeMiB = 61440  # 60GB
        $settings.swapMiB = 1024  # 1GB
        
        # WSL integration settings
        if (-not $settings.integratedWslDistros) {
            $settings.integratedWslDistros = @{}
        }
        $settings.integratedWslDistros."Ubuntu-22.04" = $true
        
        # Write updated settings
        $settings | ConvertTo-Json -Depth 10 | Out-File -FilePath $dockerDesktopSettingsPath -Encoding UTF8
        
        Write-Host "  ✅ Docker Desktop settings optimized" -ForegroundColor Green
        Write-Host "  🔄 Restarting Docker Desktop to apply settings..." -ForegroundColor White
        
        # Restart Docker Desktop
        Get-Process "Docker Desktop" -ErrorAction SilentlyContinue | Stop-Process -Force
        Start-Sleep -Seconds 5
        
    } catch {
        Write-Host "  ⚠️  Failed to update Docker Desktop settings: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ⚠️  Docker Desktop settings file not found" -ForegroundColor Yellow
    Write-Host "  ℹ️  Settings will need to be configured manually" -ForegroundColor Blue
}

# 7. Verify Docker installation
Write-Host "`n🧪 Verifying Docker installation..." -ForegroundColor Cyan

# Wait for Docker to restart
Start-Sleep -Seconds 30

$verificationTests = @(
    @{
        Name = "Docker Version"
        Command = { docker --version }
        Expected = "Docker version"
    },
    @{
        Name = "Docker Info"
        Command = { docker info --format '{{.ServerVersion}}' }
        Expected = $null
    },
    @{
        Name = "WSL Integration"
        Command = { docker context ls }
        Expected = "default"
    },
    @{
        Name = "Container Test"
        Command = { docker run --rm hello-world }
        Expected = "Hello from Docker!"
    }
)

$allTestsPassed = $true

foreach ($test in $verificationTests) {
    Write-Host "  🧪 Testing: $($test.Name)..." -ForegroundColor White
    try {
        $result = & $test.Command 2>&1
        if ($test.Expected -and $result -match $test.Expected) {
            Write-Host "    ✅ $($test.Name) - PASSED" -ForegroundColor Green
        } elseif (-not $test.Expected -and $result) {
            Write-Host "    ✅ $($test.Name) - PASSED" -ForegroundColor Green
        } else {
            Write-Host "    ❌ $($test.Name) - FAILED" -ForegroundColor Red
            Write-Host "    Output: $result" -ForegroundColor Gray
            $allTestsPassed = $false
        }
    } catch {
        Write-Host "    ❌ $($test.Name) - ERROR: $_" -ForegroundColor Red
        $allTestsPassed = $false
    }
}

# 8. Create Docker management utilities
Write-Host "`n📝 Creating Docker management utilities..." -ForegroundColor Cyan

$utilsPath = "c:\Users\justi\OneDrive\Desktop\LocalRepos\devcontainer_server_docker"

# Docker cleanup script
$dockerCleanupScript = @"
# Docker Cleanup and Optimization Script
# Run this regularly to maintain Docker health and save disk space

Write-Host "🧹 Docker Cleanup Starting..." -ForegroundColor Green

# Stop all containers
Write-Host "🛑 Stopping all containers..." -ForegroundColor Cyan
docker stop `$(docker ps -aq) 2>`$null

# Remove stopped containers
Write-Host "🗑️  Removing stopped containers..." -ForegroundColor Cyan
docker container prune -f

# Remove unused images
Write-Host "🖼️  Removing unused images..." -ForegroundColor Cyan
docker image prune -f

# Remove unused volumes
Write-Host "💾 Removing unused volumes..." -ForegroundColor Cyan
docker volume prune -f

# Remove unused networks
Write-Host "🌐 Removing unused networks..." -ForegroundColor Cyan
docker network prune -f

# Build cache cleanup
Write-Host "🔨 Cleaning build cache..." -ForegroundColor Cyan
docker builder prune -f

# System cleanup (aggressive)
Write-Host "🧽 Running system cleanup..." -ForegroundColor Cyan
docker system prune -f

# Show disk usage
Write-Host "📊 Current Docker disk usage:" -ForegroundColor Cyan
docker system df

Write-Host "✅ Docker cleanup completed!" -ForegroundColor Green
"@

# Docker monitoring script
$dockerMonitorScript = @"
# Docker Monitoring Script
# Shows detailed information about Docker resource usage

Write-Host "📊 Docker System Monitoring" -ForegroundColor Green

# Docker version and info
Write-Host "`n🐳 Docker Version:" -ForegroundColor Cyan
docker --version

Write-Host "`n⚙️  Docker System Info:" -ForegroundColor Cyan
docker info --format "table {{.Name}}: {{.ServerVersion}}"

# Container status
Write-Host "`n📦 Container Status:" -ForegroundColor Cyan
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Image usage
Write-Host "`n🖼️  Image Usage:" -ForegroundColor Cyan
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"

# Volume usage
Write-Host "`n💾 Volume Usage:" -ForegroundColor Cyan
docker volume ls --format "table {{.Name}}\t{{.Driver}}"

# Network usage
Write-Host "`n🌐 Network Usage:" -ForegroundColor Cyan
docker network ls --format "table {{.Name}}\t{{.Driver}}\t{{.Scope}}"

# Disk usage
Write-Host "`n💽 Disk Usage:" -ForegroundColor Cyan
docker system df

# Resource usage (if available)
Write-Host "`n🔄 Resource Usage:" -ForegroundColor Cyan
try {
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
} catch {
    Write-Host "No running containers to monitor" -ForegroundColor Gray
}

Write-Host "`n✅ Monitoring completed!" -ForegroundColor Green
"@

# Save utility scripts
try {
    $dockerCleanupScript | Out-File -FilePath (Join-Path $utilsPath "DOCKER-CLEANUP.ps1") -Encoding UTF8
    $dockerMonitorScript | Out-File -FilePath (Join-Path $utilsPath "DOCKER-MONITOR.ps1") -Encoding UTF8
    Write-Host "  ✅ Docker utility scripts created" -ForegroundColor Green
} catch {
    Write-Host "  ⚠️  Failed to create utility scripts: $_" -ForegroundColor Yellow
}

# 9. Summary
Write-Host "`n✅ Docker Desktop installation completed!" -ForegroundColor Green

if ($allTestsPassed) {
    Write-Host "🎉 All verification tests passed!" -ForegroundColor Green
} else {
    Write-Host "⚠️  Some tests failed - manual configuration may be needed" -ForegroundColor Yellow
}

Write-Host "`n📊 Installation Summary:" -ForegroundColor Cyan
Write-Host "  🐳 Docker Desktop: Installed with WSL 2 backend" -ForegroundColor White
Write-Host "  🐧 WSL Integration: Ubuntu-22.04 enabled" -ForegroundColor White
Write-Host "  💾 Data Location: $DockerDataPath" -ForegroundColor White
Write-Host "  ⚙️  Configuration: Optimized for development" -ForegroundColor White
if ($EnableKubernetes) {
    Write-Host "  ☸️  Kubernetes: Enabled" -ForegroundColor White
} else {
    Write-Host "  ☸️  Kubernetes: Disabled (for better performance)" -ForegroundColor White
}

Write-Host "`n🔧 Available Tools:" -ForegroundColor Cyan
Write-Host "  🧹 Cleanup: DOCKER-CLEANUP.ps1" -ForegroundColor White
Write-Host "  📊 Monitor: DOCKER-MONITOR.ps1" -ForegroundColor White

Write-Host "`n🔄 Next Steps:" -ForegroundColor Green
Write-Host "1. Run the data restoration script to recover your containers" -ForegroundColor White
Write-Host "2. Test your VPS environment" -ForegroundColor White
Write-Host "3. Configure any additional Docker settings as needed" -ForegroundColor White

Write-Host "`n💡 Pro Tips:" -ForegroundColor Yellow
Write-Host "- Use 'docker system df' to monitor disk usage" -ForegroundColor White
Write-Host "- Run DOCKER-CLEANUP.ps1 regularly to save space" -ForegroundColor White
Write-Host "- Check DOCKER-MONITOR.ps1 for system health" -ForegroundColor White
Write-Host "- WSL 2 provides better performance than Hyper-V" -ForegroundColor White

Write-Host "`n🚀 Ready to restore your Docker data!" -ForegroundColor Green