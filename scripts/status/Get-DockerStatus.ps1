param()

# Set error handling
$ErrorActionPreference = "Stop"

function Test-DockerInstalled {
    """
    Check if Docker is installed
    Returns: $true if Docker executable is found and responds, $false otherwise
    """
    try {
        $dockerPath = Get-Command docker.exe -ErrorAction SilentlyContinue
        if ($dockerPath) {
            & docker --version 2>$null | Out-Null
            return $LASTEXITCODE -eq 0
        }
        return $false
    }
    catch {
        return $false
    }
}

function Test-DockerRunning {
    """
    Check if Docker daemon is running
    Returns: $true if Docker daemon is responsive, $false otherwise
    """
    try {
        & docker info 2>$null | Out-Null
        return $LASTEXITCODE -eq 0
    }
    catch {
        return $false
    }
}

function Test-DockerDesktopInstalled {
    """
    Check if Docker Desktop is installed
    Returns: $true if Docker Desktop executable is found, $false otherwise
    """
    try {
        $dockerDesktopPaths = @(
            "${env:ProgramFiles}\Docker\Docker\Docker Desktop.exe",
            "${env:ProgramFiles(x86)}\Docker\Docker\Docker Desktop.exe"
        )
        
        $dockerDesktopPath = $dockerDesktopPaths | Where-Object { Test-Path $_ } | Select-Object -First 1
        return $null -ne $dockerDesktopPath
    }
    catch {
        return $false
    }
}

function Test-DockerWorking {
    """
    Test if Docker is fully functional by running a simple container
    Returns: $true if Docker can run containers successfully, $false otherwise
    """
    try {
        & docker run --rm hello-world 2>$null | Out-Null
        return $LASTEXITCODE -eq 0
    }
    catch {
        return $false
    }
}

function Get-DockerVersion {
    """
    Get Docker version information
    Returns: Hashtable with version details
    """
    try {
        if (Test-DockerInstalled) {
            $versionOutput = & docker --version 2>$null
            if ($LASTEXITCODE -eq 0) {
                return @{
                    Available = $true
                    Version = $versionOutput
                    ClientVersion = ($versionOutput -split ',')[0] -replace 'Docker version ', ''
                }
            }
        }
    }
    catch {
        Write-Verbose "Docker not available: $($_.Exception.Message)"
    }
    
    return @{
        Available = $false
        Version = "Not installed"
        ClientVersion = "N/A"
    }
}

function Get-DockerContainer {
    """
    Get information about Docker containers
    Returns: Hashtable with container counts
    """
    if (-not (Test-DockerRunning)) {
        return @{
            Available = $false
            Running = 0
            Total = 0
            List = @()
        }
    }
    
    try {
        # Get running containers
        $runningContainers = & docker ps --format "{{.Names}}" 2>$null
        $runningCount = if ($runningContainers) { ($runningContainers | Measure-Object).Count } else { 0 }
        
        # Get all containers
        $allContainers = & docker ps -a --format "{{.Names}}" 2>$null
        $totalCount = if ($allContainers) { ($allContainers | Measure-Object).Count } else { 0 }
        
        return @{
            Available = $true
            Running = $runningCount
            Total = $totalCount
            List = if ($allContainers) { $allContainers } else { @() }
        }
    }
    catch {
        return @{
            Available = $false
            Running = 0
            Total = 0
            List = @()
        }
    }
}

function Get-DockerImage {
    """
    Get information about Docker images
    Returns: Hashtable with image information
    """
    if (-not (Test-DockerRunning)) {
        return @{
            Available = $false
            Count = 0
            List = @()
        }
    }
    
    try {
        $images = & docker images --format "{{.Repository}}:{{.Tag}}" 2>$null
        $imageList = if ($images) { $images | Where-Object { $_ -ne "<none>:<none>" } } else { @() }
        $imageCount = if ($imageList) { ($imageList | Measure-Object).Count } else { 0 }
        
        return @{
            Available = $true
            Count = $imageCount
            List = $imageList
        }
    }
    catch {
        return @{
            Available = $false
            Count = 0
            List = @()
        }
    }
}

function Get-DockerVolume {
    """
    Get information about Docker volumes
    Returns: Hashtable with volume information
    """
    if (-not (Test-DockerRunning)) {
        return @{
            Available = $false
            Count = 0
            List = @()
        }
    }
    
    try {
        $volumes = & docker volume ls --format "{{.Name}}" 2>$null
        $volumeCount = if ($volumes) { ($volumes | Measure-Object).Count } else { 0 }
        
        return @{
            Available = $true
            Count = $volumeCount
            List = if ($volumes) { $volumes } else { @() }
        }
    }
    catch {
        return @{
            Available = $false
            Count = 0
            List = @()
        }
    }
}

function Get-DockerStatus {
    """
    Get comprehensive Docker status information
    Returns: Hashtable with complete Docker status
    """
    $status = @{
        Installed = Test-DockerInstalled
        DesktopInstalled = Test-DockerDesktopInstalled
        Running = Test-DockerRunning
        Working = $false
        Version = Get-DockerVersion
        Containers = Get-DockerContainer
        Images = Get-DockerImage
        Volumes = Get-DockerVolume
    }
    
    # Only test if Docker is working if it's running (to avoid long timeouts)
    if ($status.Running) {
        $status.Working = Test-DockerWorking
    }
    
    return $status
}

# Functions are available when script is dot-sourced