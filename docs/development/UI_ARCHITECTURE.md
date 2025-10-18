# UI Architecture Documentation

## Overview

The WSL & Docker Desktop Manager uses a modular, orchestrator-based UI architecture with centralized UI components, consistent color theming, and proper separation of concerns.

## Architecture Layers

### 1. Entry Point Layer
- **File**: `docker_manager.py`
- **Responsibility**: Application bootstrap, dependency management, path setup
- **Size**: 66 lines (88% reduction from original 550+ lines)
- **Key Functions**:
  - `setup_dependencies()`: Validates Python paths and required packages
  - `main()`: Entry point that delegates to main orchestrator

### 2. Main Orchestrator Layer
- **File**: `src/main_orchestrator.py`
- **Responsibility**: Main menu management and delegation to operation orchestrators
- **Size**: 126 lines of focused main menu logic
- **Key Components**:
  - `MainOrchestrator.show_main_menu()`: Interactive main menu loop
  - Delegation methods: `_handle_install()`, `_handle_uninstall()`, `_handle_status()`, `_handle_backup()`
  - Graceful error handling with fallbacks

### 3. Operation Orchestrator Layer
- **Files**: 
  - `src/install/install_orchestrator.py`
  - `src/uninstall/uninstall_orchestrator.py`
  - `src/status/status_orchestrator.py`
  - `src/backup/backup_orchestrator.py`
- **Responsibility**: Specific operation management with dedicated UI flows
- **Pattern**: Each orchestrator implements `main(interactive=True)` interface

### 4. UI Library Layer
- **File**: `src/ui/ui_library.py`
- **Responsibility**: Centralized UI components with consistent theming
- **Components**:
  - Header rendering with orange color theming
  - Selection menus with icon support
  - Color management system
  - Status display utilities

## UI Component System

### Core UI Functions

#### `render_header(title, icon=None, icon_color=None, title_color=Colors.ORANGE, clear_terminal=True)`
```python
# Renders consistent orange headers across all menus
render_header("System Reset", icon="🔄", icon_color=get_icon_color("🔄"))
```
**Output**:
```
============================================================
🔄 System Reset
============================================================
```

#### `render_selection_menu(title, choices, icon=None, icon_color=None, prompt="Choose an option:")`
```python
# Standardized menu rendering with consistent styling
choice = render_selection_menu(
    title="Installation Options",
    choices=["🚀 Fresh Installation", "🔄 System Reset", "🔙 Back"],
    icon="🚀",
    prompt="Choose installation option:"
)
```

#### `press_enter_to_continue(message="Press Enter to continue...")`
```python
# Consistent user input handling
press_enter_to_continue()
```

### Color System

#### ANSI Color Codes
```python
class Colors:
    ORANGE = '\033[38;5;208m'  # Primary theme color
    GREEN = '\033[38;5;46m'    # Success states
    RED = '\033[38;5;196m'     # Error states
    BLUE = '\033[38;5;33m'     # Information
    YELLOW = '\033[38;5;226m'  # Warnings
    RESET = '\033[0m'          # Reset to default
```

#### Icon Color Mapping
```python
ICON_COLORS = {
    '🐋': Colors.BLUE,      # Docker whale
    '🚀': Colors.GREEN,     # Install operations
    '🔄': Colors.ORANGE,    # Reset/reload operations
    '🔍': Colors.YELLOW,    # Status/search operations
    '💾': Colors.BLUE,      # Backup operations
    # ... more mappings
}
```

### Menu Flow Patterns

#### Standard Menu Flow
1. **Header Rendering**: Orange-colored header with appropriate icon
2. **Choice Presentation**: Questionary-based selection with icons
3. **Action Delegation**: Hand-off to specific operation handlers
4. **Result Display**: Consistent success/error messaging
5. **Navigation Control**: "Press Enter to continue" or return to menu

#### Example Implementation
```python
def _handle_system_reset() -> StepResult:
    """Handle system reset installation."""
    try:
        # Orange header with UI library
        render_header("System Reset", icon="🔄", icon_color=get_icon_color("🔄"))
        
        # Operation logic
        print("Performing system reset...")
        
        # Result display
        print("✅ MOCK: System reset completed")
        press_enter_to_continue()
        
        return StepResult.now(name="system_reset", status="Success", 
                            message="MOCK: System reset completed")
    except Exception as e:
        return StepResult.now(name="system_reset", status="Error", 
                            message=f"System reset failed: {str(e)}")
```

## UI Consistency Standards

### Header Standards
- **Color**: Orange (#208) for all menu titles
- **Format**: `============================================================`
- **Icon**: Contextually appropriate emoji with color coding
- **Spacing**: Consistent padding and alignment

### Menu Standards
- **Icons**: All menu items have contextual emojis
- **Colors**: Color-coded based on operation type
- **Navigation**: Consistent "Back to Main Menu" options
- **Error Handling**: Graceful fallbacks with user feedback

### Text Standards
- **Success Messages**: Green ✅ prefix
- **Error Messages**: Red ❌ prefix  
- **Warning Messages**: Yellow ⚠️ prefix
- **Information**: Blue ℹ️ prefix

## Orchestrator Integration Pattern

### Standard Orchestrator Interface
```python
def main(dry_run: bool = True, yes: bool = False, log_path: str = None, 
         targets=None, progress_cb=None, interactive: bool = False) -> StepResult:
    """
    Standard orchestrator entry point.
    
    Args:
        interactive: If True, show interactive menu loop
        
    Returns:
        StepResult indicating operation outcome
    """
    if interactive:
        # Interactive menu loop with UI library
        while True:
            choice = render_selection_menu(...)
            # Handle choices and delegate to operation handlers
    else:
        # Non-interactive mode for automation
        pass
```

### Result Handling Pattern
```python
# Each orchestrator returns StepResult objects
result = orchestrator.main(interactive=True)

# Main orchestrator handles results consistently
if result and result.status == "Error":
    print(f"❌ Operation failed: {result.message}")
    input("Press Enter to continue...")
```

## Dependencies and Imports

### UI Library Dependencies
- **questionary**: Interactive menu selections
- **sys/os**: Terminal control and path management
- **pathlib**: File system operations

### Import Pattern
```python
# Standard UI library imports
from ui.ui_library import (
    render_header, 
    render_selection_menu, 
    get_icon_color, 
    press_enter_to_continue
)
from step_result import StepResult
```

## Terminal Compatibility

### ANSI Color Support
- **Windows Terminal**: Full ANSI color support
- **PowerShell**: Basic color support
- **Command Prompt**: Limited color support
- **Fallback**: Graceful degradation without colors

### Cross-Platform Considerations
- **Terminal Clearing**: `os.system('cls' if os.name == 'nt' else 'clear')`
- **Path Handling**: Uses `pathlib.Path` for cross-platform compatibility
- **Color Detection**: Future enhancement for terminal capability detection

## Benefits of Current Architecture

### Maintainability
- **Single Responsibility**: Each file has one clear purpose
- **Centralized UI**: All UI components in one location
- **Consistent Patterns**: Standard interfaces across orchestrators

### Extensibility
- **New Operations**: Easy to add by creating new orchestrators
- **UI Enhancements**: Centralized location for UI improvements
- **Color Themes**: Simple color scheme modifications

### Testing
- **Unit Testing**: Each orchestrator can be tested independently
- **UI Testing**: UI library functions can be tested in isolation
- **Integration Testing**: Clear interfaces between components

### User Experience
- **Consistent Look**: Orange theme throughout application
- **Visual Hierarchy**: Icons and colors guide user attention
- **Clear Navigation**: Intuitive menu flows and back buttons
- **Error Handling**: Friendly error messages with recovery options

## Future Enhancements

### Planned Improvements
1. **Terminal Capability Detection**: Auto-detect color support
2. **Configuration System**: User-customizable color themes
3. **Progress Indicators**: Visual progress bars for long operations
4. **Help System**: Context-sensitive help in menus
5. **Keyboard Shortcuts**: Quick navigation options

### Architecture Scalability
- **Plugin System**: Support for external orchestrator plugins
- **Theme System**: Multiple color theme support
- **Internationalization**: Multi-language support framework
- **Accessibility**: Screen reader and accessibility improvements