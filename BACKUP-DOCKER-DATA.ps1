# Docker Data Backup Script
# Run this BEFORE uninstalling Docker Desktop to preserve your containers, images, and volumes
# This script will backup your VPS environment and other Docker resources

param(
    [string]$BackupPath = "C:\DockerBackup\$(Get-Date -Format 'yyyy-MM-dd-HHmm')",
    [switch]$SkipImages = $false,
    [switch]$SkipVolumes = $false
)

Write-Host "🔄 Docker Data Backup Starting..." -ForegroundColor Green
Write-Host "Backup Location: $BackupPath" -ForegroundColor Yellow

# Create backup directory
New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null

# Check if Docker is running
try {
    docker version | Out-Null
    Write-Host "✅ Docker is running" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker is not running or not accessible" -ForegroundColor Red
    Write-Host "Please start Docker Desktop and try again" -ForegroundColor Yellow
    exit 1
}

# Function to run docker commands with error handling
function Invoke-DockerCommand {
    param([string]$Command)
    try {
        Invoke-Expression $Command
        return $true
    } catch {
        Write-Host "⚠️  Command failed: $Command" -ForegroundColor Yellow
        Write-Host "Error: $_" -ForegroundColor Red
        return $false
    }
}

# 1. Export VPS containers (if they exist)
Write-Host "`n🐳 Backing up VPS containers..." -ForegroundColor Cyan
$vpsContainers = @("ubuntu-vps", "debian-vps", "rocky-vps", "centos-vps", "alpine-vps", "opensuse-vps", "arch-vps", "slackware-vps")

foreach ($container in $vpsContainers) {
    if (docker ps -a --format "{{.Names}}" | Select-String -Pattern "^$container$") {
        Write-Host "  📦 Exporting $container..." -ForegroundColor White
        $exportPath = Join-Path $BackupPath "$container.tar"
        if (Invoke-DockerCommand "docker export $container -o `"$exportPath`"") {
            Write-Host "  ✅ $container exported successfully" -ForegroundColor Green
        }
    } else {
        Write-Host "  ⏭️  $container not found, skipping" -ForegroundColor Gray
    }
}

# 2. Save Docker images (optional, can be large)
if (-not $SkipImages) {
    Write-Host "`n🖼️  Backing up Docker images..." -ForegroundColor Cyan
    $images = docker images --format "{{.Repository}}:{{.Tag}}" | Where-Object { $_ -notmatch "<none>" }
    
    if ($images) {
        $imagesPath = Join-Path $BackupPath "images"
        New-Item -ItemType Directory -Path $imagesPath -Force | Out-Null
        
        foreach ($image in $images) {
            $safeImageName = $image -replace "[:/]", "_"
            $imagePath = Join-Path $imagesPath "$safeImageName.tar"
            Write-Host "  🖼️  Saving $image..." -ForegroundColor White
            if (Invoke-DockerCommand "docker save -o `"$imagePath`" $image") {
                Write-Host "  ✅ $image saved successfully" -ForegroundColor Green
            }
        }
    }
} else {
    Write-Host "`n⏭️  Skipping Docker images backup (use -SkipImages $false to include)" -ForegroundColor Gray
}

# 3. Backup Docker volumes
if (-not $SkipVolumes) {
    Write-Host "`n💾 Backing up Docker volumes..." -ForegroundColor Cyan
    $volumes = docker volume ls --format "{{.Name}}"
    
    if ($volumes) {
        $volumesPath = Join-Path $BackupPath "volumes"
        New-Item -ItemType Directory -Path $volumesPath -Force | Out-Null
        
        foreach ($volume in $volumes) {
            Write-Host "  💾 Backing up volume: $volume..." -ForegroundColor White
            $volumeBackupPath = Join-Path $volumesPath "$volume.tar"
            
            # Create a temporary container to backup the volume
            $tempContainer = "backup-temp-$(Get-Random)"
            $dockerCommand = "docker run --rm -v ${volume}:/data -v `"$volumesPath`":/backup alpine tar czf /backup/$volume.tar.gz -C /data ."
            
            if (Invoke-DockerCommand $dockerCommand) {
                Write-Host "  ✅ Volume $volume backed up successfully" -ForegroundColor Green
            }
        }
    }
} else {
    Write-Host "`n⏭️  Skipping Docker volumes backup (use -SkipVolumes $false to include)" -ForegroundColor Gray
}

# 4. Export Docker Compose configuration
Write-Host "`n📋 Backing up Docker Compose configuration..." -ForegroundColor Cyan
$composeFile = "docker-compose.yml"
if (Test-Path $composeFile) {
    Copy-Item $composeFile -Destination (Join-Path $BackupPath "docker-compose.yml")
    Write-Host "  ✅ Docker Compose file backed up" -ForegroundColor Green
} else {
    Write-Host "  ⏭️  Docker Compose file not found" -ForegroundColor Gray
}

# 5. Save current Docker info
Write-Host "`n📊 Saving Docker system information..." -ForegroundColor Cyan
docker system df > (Join-Path $BackupPath "docker-system-info.txt")
docker version > (Join-Path $BackupPath "docker-version.txt")
docker info > (Join-Path $BackupPath "docker-info.txt")

# 6. Create restoration script
Write-Host "`n📝 Creating restoration script..." -ForegroundColor Cyan
$restoreScript = @"
# Docker Data Restoration Script
# Run this AFTER reinstalling Docker Desktop to restore your data

Write-Host "🔄 Docker Data Restoration Starting..." -ForegroundColor Green

# Restore VPS containers
Write-Host "🐳 Restoring VPS containers..." -ForegroundColor Cyan
Get-ChildItem "$BackupPath\*.tar" | ForEach-Object {
    `$containerName = `$_.BaseName
    Write-Host "  📦 Importing `$containerName..." -ForegroundColor White
    docker import `$_.FullName `$containerName`:restored
    Write-Host "  ✅ `$containerName imported successfully" -ForegroundColor Green
}

# Restore Docker images
if (Test-Path "$BackupPath\images") {
    Write-Host "🖼️  Restoring Docker images..." -ForegroundColor Cyan
    Get-ChildItem "$BackupPath\images\*.tar" | ForEach-Object {
        Write-Host "  🖼️  Loading `$(`$_.BaseName)..." -ForegroundColor White
        docker load -i `$_.FullName
        Write-Host "  ✅ Image loaded successfully" -ForegroundColor Green
    }
}

# Restore Docker volumes
if (Test-Path "$BackupPath\volumes") {
    Write-Host "💾 Restoring Docker volumes..." -ForegroundColor Cyan
    Get-ChildItem "$BackupPath\volumes\*.tar.gz" | ForEach-Object {
        `$volumeName = `$_.BaseName -replace "\.tar$", ""
        Write-Host "  💾 Restoring volume: `$volumeName..." -ForegroundColor White
        docker volume create `$volumeName
        docker run --rm -v `$volumeName`:/data -v "`$(`$_.DirectoryName)`":/backup alpine tar xzf /backup/`$(`$_.Name) -C /data
        Write-Host "  ✅ Volume `$volumeName restored successfully" -ForegroundColor Green
    }
}

Write-Host "✅ Docker data restoration completed!" -ForegroundColor Green
Write-Host "You can now restart your VPS environment." -ForegroundColor Yellow
"@

$restoreScript | Out-File -FilePath (Join-Path $BackupPath "RESTORE-DOCKER-DATA.ps1") -Encoding UTF8

# Summary
Write-Host "`n✅ Backup completed successfully!" -ForegroundColor Green
Write-Host "📁 Backup location: $BackupPath" -ForegroundColor Yellow
Write-Host "📝 Restoration script created: $(Join-Path $BackupPath 'RESTORE-DOCKER-DATA.ps1')" -ForegroundColor Yellow

$backupSize = (Get-ChildItem $BackupPath -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
Write-Host "💾 Total backup size: $([math]::Round($backupSize, 2)) MB" -ForegroundColor Cyan

Write-Host "`n🔄 Next steps:" -ForegroundColor Green
Write-Host "1. Keep this backup safe until after reinstallation" -ForegroundColor White
Write-Host "2. Run the uninstall scripts when ready" -ForegroundColor White
Write-Host "3. Use RESTORE-DOCKER-DATA.ps1 after reinstalling Docker" -ForegroundColor White