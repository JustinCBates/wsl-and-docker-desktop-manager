# Chat Session Memory Documentation

## Session Overview
- **Primary Goal**: Create simple MVP Questionary menu system for WSL & Docker Desktop Manager
- **Context**: Multi-repository workspace with 3 projects, focus on WSL/Docker management tools
- **Current Branch**: mvp-questionary (clean baseline)

## Key Requirements Established
1. **Simple MVP Scope**: Use Questionary for basic menu, not complex TUI systems
2. **Core Features Needed**:
   - Fresh Installation (calls MASTER-REINSTALL.ps1)
   - System Reset (calls MASTER-REINSTALL.ps1) 
   - Status Check
   - Exit functionality
3. **Use Microsoft Documented Defaults**: 50% RAM, all processors, Ubuntu 22.04 LTS, autoMemoryReclaim
4. **Integration**: Call existing PowerShell scripts rather than recreate functionality

## Git Workflow Context
- **Current Branch**: mvp-questionary 
- **Previous Issue**: Development work was accidentally lost during git reset operation
- **Learning**: Proper branch management needed to preserve work while creating clean MVP baseline
- **Status**: Clean slate with original PowerShell scripts intact

## Existing PowerShell Scripts (Preserved)
Located in: `C:\Users\justi\OneDrive\Desktop\LocalRepos\wsl-and-docker-desktop-manager`
- `MASTER-REINSTALL.ps1` - Main installation/reset script
- `INSTALL-WSL2-DYNAMIC.ps1` - WSL2 installation
- `INSTALL-DOCKER-DESKTOP.ps1` - Docker Desktop installation
- `UNINSTALL-WSL.ps1` - WSL removal
- `UNINSTALL-DOCKER-DESKTOP.ps1` - Docker Desktop removal
- `BACKUP-DOCKER-DATA.ps1` - REMOVED (backup functionality removed)

## Technical Context
- **Platform**: Windows 11, PowerShell 5.1
- **Dependencies**: Administrator privileges required for PowerShell scripts
- **Python Environment**: Need to set up virtual environment for Questionary
- **Architecture**: Python menu → PowerShell script execution → System operations

## MVP Implementation Plan
1. Set up Python virtual environment
2. Install Questionary package
3. Create simple menu system with 4 options:
   - Fresh Installation
   - System Reset  
   - Status Check
   - Exit
4. Each menu option calls appropriate PowerShell script with documented Microsoft defaults
5. Handle administrator privilege requirements
6. Provide clear user feedback during operations

## User Preferences/Requirements
- **Keep It Simple**: Avoid over-engineering, focus on core use cases
- **Use Existing Code**: Leverage proven PowerShell scripts rather than recreate
- **Proper Git Workflow**: Preserve development work, use branches appropriately
- **Microsoft Standards**: Use documented defaults, not assumptions
- **Clean Exit**: Ensure proper exit functionality (previous TUI had exit issues)

## Current Status
- Clean mvp-questionary branch ready for development
- All original PowerShell scripts intact and functional
- Ready to implement Python Questionary MVP
- Need to set up virtual environment and install dependencies

## Next Steps
1. Create Python virtual environment
2. Install Questionary
3. Implement MVP menu system
4. Test integration with PowerShell scripts
5. Ensure proper exit handling