# Parameters for backup operations
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
param(
    [string]$BackupPath = "C:\DockerBackup",
    [switch]$Force = $false
)

# Set error handling
$ErrorActionPreference = "Stop"

function Write-Phase {
    param([string]$Message)
    Write-Output "`nðŸ“‹ Backup: $Message"
}

function Test-DockerRunning {
    try {
        & docker info 2>$null | Out-Null
        return $LASTEXITCODE -eq 0
    }
    catch {
        return $false
    }
}

function Stop-DockerContainers {
    Write-Phase "Stopping Docker containers"
    
    try {
        $runningContainers = & docker ps -q 2>$null
        if ($runningContainers) {
            Write-Output "Stopping running containers..."
            & docker stop $runningContainers
            Write-Output "âœ… Containers stopped"
        } else {
            Write-Output "No running containers found"
        }
    }
    catch {
        Write-Warning "Error stopping containers: $_"
    }
}

function Backup-DockerImages {
    param([string]$BackupDir)
    
    Write-Phase "Backing up Docker images"
    
    try {
        $imagesBackupPath = Join-Path $BackupDir "images"
        if (-not (Test-Path $imagesBackupPath)) {
            New-Item -Path $imagesBackupPath -ItemType Directory -Force | Out-Null
        }
        
        $images = & docker images --format "{{.Repository}}:{{.Tag}}" 2>$null
        if ($images) {
            $imageList = $images | Where-Object { $_ -ne "<none>:<none>" }
            
            if ($imageList) {
                Write-Output "Found $($imageList.Count) images to backup"
                $imageListFile = Join-Path $imagesBackupPath "image-list.txt"
                $imageList | Out-File -FilePath $imageListFile -Encoding UTF8
                
                foreach ($image in $imageList) {
                    $safeImageName = $image -replace '[/\\:*?"<>|]', '_'
                    $imagePath = Join-Path $imagesBackupPath "$safeImageName.tar"
                    
                    Write-Output "Backing up image: $image"
                    & docker save -o $imagePath $image
                    
                    if ($LASTEXITCODE -ne 0) {
                        Write-Warning "Failed to backup image: $image"
                    }
                }
                Write-Output "âœ… Docker images backed up"
            } else {
                Write-Output "No Docker images found to backup"
            }
        } else {
            Write-Output "No Docker images found"
        }
    }
    catch {
        Write-Warning "Error backing up Docker images: $_"
    }
}

function Backup-DockerVolumes {
    param([string]$BackupDir)
    
    Write-Phase "Backing up Docker volumes"
    
    try {
        $volumesBackupPath = Join-Path $BackupDir "volumes"
        if (-not (Test-Path $volumesBackupPath)) {
            New-Item -Path $volumesBackupPath -ItemType Directory -Force | Out-Null
        }
        
        $volumes = & docker volume ls --format "{{.Name}}" 2>$null
        if ($volumes) {
            Write-Output "Found $($volumes.Count) volumes to backup"
            
            foreach ($volume in $volumes) {
                $volumePath = Join-Path $volumesBackupPath "$volume.tar"
                
                Write-Output "Backing up volume: $volume"
                
                # Create a temporary container to backup the volume
                & docker run --rm -v "${volume}:/data" -v "${volumesBackupPath}:/backup" alpine tar -czf "/backup/$volume.tar" -C /data .
                
                if ($LASTEXITCODE -ne 0) {
                    Write-Warning "Failed to backup volume: $volume"
                }
            }
            Write-Output "âœ… Docker volumes backed up"
        } else {
            Write-Output "No Docker volumes found to backup"
        }
    }
    catch {
        Write-Warning "Error backing up Docker volumes: $_"
    }
}

function Backup-DockerConfigs {
    param([string]$BackupDir)
    
    Write-Phase "Backing up Docker configuration"
    
    try {
        $configBackupPath = Join-Path $BackupDir "config"
        if (-not (Test-Path $configBackupPath)) {
            New-Item -Path $configBackupPath -ItemType Directory -Force | Out-Null
        }
        
        # Backup Docker daemon configuration
        $dockerConfigPath = "$env:USERPROFILE\.docker"
        if (Test-Path $dockerConfigPath) {
            Write-Output "Backing up Docker user configuration..."
            Copy-Item $dockerConfigPath (Join-Path $configBackupPath "docker-user-config") -Recurse -Force
        }
        
        # Backup Docker Desktop settings
        $dockerDesktopConfig = "$env:APPDATA\Docker"
        if (Test-Path $dockerDesktopConfig) {
            Write-Output "Backing up Docker Desktop configuration..."
            Copy-Item $dockerDesktopConfig (Join-Path $configBackupPath "docker-desktop-config") -Recurse -Force
        }
        
        # Export Docker context
        $contextFile = Join-Path $configBackupPath "docker-contexts.json"
        & docker context ls --format json 2>$null | Out-File -FilePath $contextFile -Encoding UTF8
        
        Write-Output "âœ… Docker configuration backed up"
    }
    catch {
        Write-Warning "Error backing up Docker configuration: $_"
    }
}

function Create-BackupManifest {
    param([string]$BackupDir)
    
    try {
        $manifest = @{
            BackupDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            BackupPath = $BackupDir
            DockerVersion = & docker --version 2>$null
            SystemInfo = @{
                ComputerName = $env:COMPUTERNAME
                UserName = $env:USERNAME
                OSVersion = [System.Environment]::OSVersion.VersionString
            }
        }
        
        $manifestPath = Join-Path $BackupDir "backup-manifest.json"
        $manifest | ConvertTo-Json -Depth 3 | Out-File -FilePath $manifestPath -Encoding UTF8
        
        Write-Output "âœ… Backup manifest created"
    }
    catch {
        Write-Warning "Error creating backup manifest: $_"
    }
}

# Main backup logic
try {
    Write-Phase "Docker Data Backup Started"
    
    # Create backup directory
    if (-not (Test-Path $BackupPath)) {
        Write-Output "Creating backup directory: $BackupPath"
        New-Item -Path $BackupPath -ItemType Directory -Force | Out-Null
    } elseif (-not $Force) {
        $existingFiles = Get-ChildItem $BackupPath -ErrorAction SilentlyContinue
        if ($existingFiles) {
            throw "Backup directory already exists and contains files. Use -Force to overwrite."
        }
    }
    
    # Check if Docker is running
    if (-not (Test-DockerRunning)) {
        throw "Docker is not running. Please start Docker Desktop and try again."
    }
    
    # Stop containers gracefully
    Stop-DockerContainers
    
    # Backup Docker images
    Backup-DockerImages -BackupDir $BackupPath
    
    # Backup Docker volumes
    Backup-DockerVolumes -BackupDir $BackupPath
    
    # Backup Docker configurations
    Backup-DockerConfigs -BackupDir $BackupPath
    
    # Create backup manifest
    Create-BackupManifest -BackupDir $BackupPath
    
    $backupSize = (Get-ChildItem $BackupPath -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
    
    Write-Phase "Docker data backup completed successfully"
    Write-Output "ðŸ“ Backup location: $BackupPath"
    Write-Output "ðŸ’¾ Backup size: $([math]::Round($backupSize, 2)) MB"
    Write-Output "`nYour Docker data has been safely backed up and can be restored later."
    
    exit 0
}
catch {
    Write-Error "Docker backup failed: $_"
    exit 1
}