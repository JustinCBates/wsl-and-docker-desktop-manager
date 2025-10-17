param(
    [switch]$Force = $false
)

# Set error handling
$ErrorActionPreference = "Stop"

function Write-Phase {
    param([string]$Message)
    Write-Output "`n📋 Docker Install: $Message"
}

# Import Docker status functions
. "$PSScriptRoot\..\status\Get-DockerStatus.ps1"

function Test-AdminRights {
    return ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Install-DockerDesktop {
    Write-Phase "Installing Docker Desktop"
    
    try {
        # Download Docker Desktop installer
        $dockerUrl = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
        $installerPath = "$env:TEMP\DockerDesktopInstaller.exe"
        
        Write-Output "Downloading Docker Desktop installer..."
        Invoke-WebRequest -Uri $dockerUrl -OutFile $installerPath -UseBasicParsing
        
        Write-Output "Installing Docker Desktop (this may take several minutes)..."
        $installArgs = @(
            "install",
            "--quiet",
            "--accept-license"
        )
        
        $process = Start-Process -FilePath $installerPath -ArgumentList $installArgs -Wait -PassThru
        
        if ($process.ExitCode -ne 0) {
            throw "Docker Desktop installation failed with exit code: $($process.ExitCode)"
        }
        
        # Clean up installer
        Remove-Item $installerPath -Force
        
        Write-Output "✅ Docker Desktop installed successfully"
    }
    catch {
        Write-Error "❌ Failed to install Docker Desktop: $_"
        throw
    }
}

function Start-DockerDesktop {
    Write-Phase "Starting Docker Desktop"
    
    try {
        # Find Docker Desktop executable
        $dockerDesktopPaths = @(
            "${env:ProgramFiles}\Docker\Docker\Docker Desktop.exe",
            "${env:ProgramFiles(x86)}\Docker\Docker\Docker Desktop.exe"
        )
        
        $dockerDesktopPath = $dockerDesktopPaths | Where-Object { Test-Path $_ } | Select-Object -First 1
        
        if (-not $dockerDesktopPath) {
            throw "Docker Desktop executable not found"
        }
        
        Write-Output "Starting Docker Desktop..."
        Start-Process -FilePath $dockerDesktopPath
        
        # Wait for Docker to be ready
        Write-Output "Waiting for Docker to be ready..."
        $timeout = 120 # 2 minutes
        $elapsed = 0
        
        do {
            Start-Sleep -Seconds 5
            $elapsed += 5
            
            try {
                & docker version 2>$null | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    Write-Output "✅ Docker is ready"
                    return
                }
            }
            catch {
                # Continue waiting
            }
            
            if ($elapsed % 30 -eq 0) {
                Write-Output "Still waiting for Docker to start... ($elapsed/$timeout seconds)"
            }
        } while ($elapsed -lt $timeout)
        
        throw "Docker failed to start within $timeout seconds"
    }
    catch {
        Write-Error "❌ Failed to start Docker Desktop: $_"
        throw
    }
}

function Test-DockerWorkingWithOutput {
    Write-Phase "Testing Docker installation"
    
    try {
        Write-Output "Running Docker test..."
        $result = Test-DockerWorking
        
        if ($result) {
            Write-Output "✅ Docker is working correctly"
        } else {
            Write-Warning "Docker test failed"
        }
        
        return $result
    }
    catch {
        Write-Warning "Docker test failed: $_"
        return $false
    }
}

# Main installation logic
try {
    Write-Phase "Docker Installation Started"
    
    if (-not (Test-AdminRights)) {
        throw "This script requires administrator privileges"
    }
    
    # Check if Docker is already installed and working
    if ((Test-DockerInstalled) -and -not $Force) {
        Write-Output "Docker is already installed. Testing functionality..."
        if (Test-DockerWorkingWithOutput) {
            Write-Output "✅ Docker is already installed and working"
            exit 0
        } else {
            Write-Output "Docker is installed but not working properly. Continuing with installation..."
        }
    }
    
    # Install Docker Desktop
    Install-DockerDesktop
    
    # Start Docker Desktop
    Start-DockerDesktop
    
    # Test installation
    Test-DockerWorkingWithOutput
    
    Write-Phase "Docker installation completed successfully"
    Write-Output "`n🐳 Docker Desktop has been installed and is ready to use!"
    Write-Output "You can now use Docker commands or the Docker Desktop GUI."
    
    exit 0
}
catch {
    Write-Error "Docker installation failed: $_"
    exit 1
}