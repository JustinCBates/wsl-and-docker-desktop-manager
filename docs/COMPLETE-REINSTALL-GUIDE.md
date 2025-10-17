# 🔄 Complete Docker Desktop & WSL 2 Reinstallation Guide

This guide will help you completely uninstall and reinstall Docker Desktop and WSL 2 with dynamic disk allocation for expandable storage. This process is perfect when you need more storage space for Docker images and containers.

## 🎯 What This Process Accomplishes

- **Removes** Docker Desktop and all associated data
- **Uninstalls** WSL completely with all distributions  
- **Reinstalls** WSL 2 with dynamic disk allocation
- **Configures** optimized storage that can expand as needed
- **Restores** your Docker containers and data
- **Improves** overall performance and storage management

## ⚠️ IMPORTANT: Before You Begin

### Prerequisites
- **Windows 10 version 2004+** or **Windows 11**
- **Administrator privileges** required
- **At least 20GB free space** for the process
- **Stable internet connection** for downloads
- **Time**: Allow 2-3 hours for the complete process

### Backup Requirements
**CRITICAL**: This process will delete ALL Docker and WSL data. Make sure you have:
- ✅ Backed up any important files from WSL distributions
- ✅ Exported any critical Docker containers
- ✅ Noted down any custom configurations
- ✅ Saved any important development work

## 📋 Step-by-Step Process

### Phase 1: Backup Your Data (MANDATORY)
**⏱️ Time Required: 15-30 minutes**

1. **Open PowerShell as Administrator**
   ```powershell
   # Right-click Start button → Windows PowerShell (Admin)
   ```

2. **Run the backup script**
   ```powershell
   NOTE: Backup script `BACKUP-DOCKER-DATA.ps1` has been removed from this repository. Please perform backups using your preferred tooling.
   ```
   
   **Options:**
   - Default: Backs up containers, images, and volumes
   - Skip images: `.\BACKUP-DOCKER-DATA.ps1 -SkipImages`
   - Skip volumes: `.\BACKUP-DOCKER-DATA.ps1 -SkipVolumes`
   - Custom path: `.\BACKUP-DOCKER-DATA.ps1 -BackupPath "D:\MyBackup"`

3. **Verify backup completion**
   - Check that backup folder was created
   - Note the backup path for later restoration
   - Verify important containers were exported

### Phase 2: Uninstall Docker Desktop
**⏱️ Time Required: 10-15 minutes**

1. **Run Docker Desktop uninstall script**
   ```powershell
   .\UNINSTALL-DOCKER-DESKTOP.ps1
   ```

   **Options:**
   - Force uninstall: `.\UNINSTALL-DOCKER-DESKTOP.ps1 -Force`
   - Keep user data: `.\UNINSTALL-DOCKER-DESKTOP.ps1 -KeepUserData`

2. **Wait for completion**
   - Script will stop Docker services
   - Remove all Docker files and folders
   - Clean registry entries
   - May ask about Hyper-V (answer based on your needs)

### Phase 3: Uninstall WSL
**⏱️ Time Required: 10-15 minutes**

1. **Run WSL uninstall script**
   ```powershell
   .\UNINSTALL-WSL.ps1
   ```

   **Options:**
   - Force uninstall: `.\UNINSTALL-WSL.ps1 -Force`
   - Custom backup: `.\UNINSTALL-WSL.ps1 -BackupPath "D:\WSLBackup"`

2. **RESTART your computer**
   ```powershell
   # MANDATORY RESTART - Windows features need to be fully disabled
   Restart-Computer
   ```

### Phase 4: Reinstall WSL 2 with Dynamic Disk
**⏱️ Time Required: 20-30 minutes**

1. **After restart, open PowerShell as Administrator**

2. **Run WSL 2 installation script**
   ```powershell
   .\INSTALL-WSL2-DYNAMIC.ps1
   ```

   **Options:**
   - Custom location: `.\INSTALL-WSL2-DYNAMIC.ps1 -WSLInstallPath "D:\WSL"`
   - Different disk size: `.\INSTALL-WSL2-DYNAMIC.ps1 -MaxDiskSizeGB 200`
   - Different distro: `.\INSTALL-WSL2-DYNAMIC.ps1 -WSLDistro "Ubuntu-20.04"`

3. **Complete Ubuntu setup**
   - Create user account when prompted
   - Set password
   - Wait for initial setup to complete

4. **Test WSL installation**
   ```powershell
   wsl --list --verbose
   wsl echo "WSL is working!"
   ```

### Phase 5: Reinstall Docker Desktop
**⏱️ Time Required: 15-20 minutes**

1. **Run Docker Desktop installation script**
   ```powershell
   .\INSTALL-DOCKER-DESKTOP.ps1
   ```

   **Options:**
   - Enable Kubernetes: `.\INSTALL-DOCKER-DESKTOP.ps1 -EnableKubernetes`
   - Custom data path: `.\INSTALL-DOCKER-DESKTOP.ps1 -DockerDataPath "D:\Docker"`
   - Edge channel: `.\INSTALL-DOCKER-DESKTOP.ps1 -UseStableChannel:$false`

2. **Wait for Docker to start**
   - Script will wait for Docker to become ready
   - May take 5-10 minutes on first startup

3. **Verify installation**
   ```powershell
   docker --version
   docker run hello-world
   ```

### Phase 6: Restore Your Data
**⏱️ Time Required: 10-30 minutes depending on data size**

1. **Navigate to your backup folder**
   ```powershell
   cd "C:\DockerBackup\[your-backup-date]"
   ```

2. **Run the restoration script**
   ```powershell
   .\RESTORE-DOCKER-DATA.ps1
   ```

3. **Test your VPS environment**
   ```powershell
   cd "c:\Users\justi\OneDrive\Desktop\LocalRepos\devcontainer_server_docker"
   .\START-WINDOWS.bat
   ```

## 🔧 Configuration Details

### WSL 2 Dynamic Disk Benefits
- **Expandable storage**: Starts small, grows as needed
- **Better performance**: WSL 2 is faster than WSL 1
- **Improved integration**: Better Docker compatibility
- **Resource efficiency**: Uses only needed disk space

### Optimized Docker Settings
- **WSL 2 backend**: Better performance than Hyper-V
- **Memory allocation**: 4GB (adjustable)
- **CPU cores**: 2 (adjustable)
- **Disk size**: 60GB expandable
- **Build cache management**: Automatic cleanup

### Storage Locations
- **WSL**: `C:\WSL\` (or your custom path)
- **Docker data**: `C:\ProgramData\Docker`
- **User settings**: `%APPDATA%\Docker`

## 🚨 Troubleshooting

### Common Issues and Solutions

#### "WSL 2 kernel not found"
```powershell
# Download and install WSL 2 kernel manually
Invoke-WebRequest -Uri "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi" -OutFile "$env:TEMP\wsl_update_x64.msi"
Start-Process msiexec.exe -ArgumentList "/i", "$env:TEMP\wsl_update_x64.msi", "/quiet" -Wait
```

#### "Docker Desktop won't start"
```powershell
# Reset Docker to factory defaults
"C:\Program Files\Docker\Docker\Docker Desktop.exe" --factory-reset
```

#### "WSL installation fails"
```powershell
# Enable Windows features manually
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
Restart-Computer
```

#### "Hyper-V conflicts"
```powershell
# Disable Hyper-V if needed
Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All
Restart-Computer
```

### Performance Issues

#### Docker is slow
- Increase memory allocation in Docker settings
- Move Docker data to faster drive (SSD)
- Enable hardware acceleration in BIOS

#### WSL is slow
- Check .wslconfig memory allocation
- Ensure WSL 2 (not WSL 1) is being used
- Consider moving WSL to faster drive

#### Disk space issues
```powershell
# Run cleanup scripts regularly
.\DOCKER-CLEANUP.ps1
.\compact-wsl-disk.ps1  # In WSL scripts folder
```

## 📊 Monitoring and Maintenance

### Regular Maintenance Tasks

#### Weekly
```powershell
# Clean up Docker resources
.\DOCKER-CLEANUP.ps1

# Check system status
.\DOCKER-MONITOR.ps1
```

#### Monthly
```powershell
# Compact WSL disk
wsl --shutdown
# Then run: .\compact-wsl-disk.ps1

# Update Docker Desktop
winget upgrade Docker.DockerDesktop
```

### Monitoring Commands
```powershell
# Check Docker disk usage
docker system df

# Check WSL disk usage
wsl df -h

# Monitor container resources
docker stats

# Check WSL memory usage
wsl cat /proc/meminfo
```

## 💡 Pro Tips

### Performance Optimization
1. **Allocate sufficient RAM**: 4-8GB for Docker in .wslconfig
2. **Use SSD**: Move WSL and Docker data to SSD if possible
3. **Regular cleanup**: Run cleanup scripts weekly
4. **Monitor resources**: Check disk and memory usage regularly

### Storage Management
1. **Compact regularly**: Use compact-wsl-disk.ps1 monthly
2. **Clean build cache**: Use `docker builder prune` after large builds
3. **Remove unused images**: Use `docker image prune` regularly
4. **Use .dockerignore**: Reduce build context size

### Development Workflow
1. **Use volumes**: For persistent data in containers
2. **Multi-stage builds**: Reduce final image size
3. **Layer caching**: Optimize Dockerfile layer order
4. **Health checks**: Add health checks to containers

## ✅ Success Verification

After completing all phases, verify everything works:

### ✔️ WSL 2 Check
```powershell
wsl --status
wsl --list --verbose  # Should show VERSION 2
wsl echo "Hello from WSL!"
```

### ✔️ Docker Check
```powershell
docker --version
docker info | findstr "WSL"  # Should show WSL backend
docker run --rm hello-world
```

### ✔️ VPS Environment Check
```powershell
cd "c:\Users\justi\OneDrive\Desktop\LocalRepos\devcontainer_server_docker"
python advanced-launcher.py --help
.\START-WINDOWS.bat
```

### ✔️ Storage Check
```powershell
# Check WSL disk is dynamic
wsl df -h /
# Check Docker storage
docker system df
```

## 🎉 Congratulations!

If all checks pass, you now have:
- ✅ **Clean WSL 2 installation** with dynamic disk
- ✅ **Optimized Docker Desktop** with WSL 2 backend  
- ✅ **Expandable storage** that grows as needed
- ✅ **Better performance** than the previous setup
- ✅ **All your data restored** and ready to use

Your VPS testing environment should now have much better storage management and performance!

## 🆘 Need Help?

If you encounter issues:
1. **Check the troubleshooting section** above
2. **Review script output** for specific error messages
3. **Verify prerequisites** are met
4. **Try manual installation** if scripts fail
5. **Check Windows Update** for latest features

Remember: This process completely rebuilds your Docker and WSL environment, so it may take time but will give you the best possible setup for long-term use.