"""UI Library for consistent terminal interface components.

This module provides reusable UI components for headers, formatting, and display.
"""
import os


class Colors:
    """ANSI color codes for terminal text formatting."""
    # Text colors
    BLACK = '\033[30m'
    RED = '\033[31m'
    GREEN = '\033[32m'
    YELLOW = '\033[33m'
    BLUE = '\033[34m'
    MAGENTA = '\033[35m'
    CYAN = '\033[36m'
    WHITE = '\033[37m'
    
    # Bright colors
    BRIGHT_BLACK = '\033[90m'
    BRIGHT_RED = '\033[91m'
    BRIGHT_GREEN = '\033[92m'
    BRIGHT_YELLOW = '\033[93m'
    BRIGHT_BLUE = '\033[94m'
    BRIGHT_MAGENTA = '\033[95m'
    BRIGHT_CYAN = '\033[96m'
    BRIGHT_WHITE = '\033[97m'
    
    # Special colors (often used for emojis in terminals)
    ORANGE = '\033[38;5;208m'  # 256-color orange
    
    # Formatting
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
    RESET = '\033[0m'  # Reset to default


def colorize_text(text: str, color: str = None, bold: bool = False) -> str:
    """Apply color and formatting to text.
    
    Args:
        text: The text to colorize
        color: Color code from Colors class (optional)
        bold: Whether to make text bold
        
    Returns:
        Formatted text with ANSI codes
    """
    if not color and not bold:
        return text
    
    result = ""
    if bold:
        result += Colors.BOLD
    if color:
        result += color
    result += text + Colors.RESET
    
    return result


def render_header(title: str, width: int = 60, border_char: str = "=", 
                 clear_terminal: bool = True, icon: str = None, 
                 icon_color: str = None, title_color: str = Colors.ORANGE) -> None:
    """Render a consistent header with optional icon and colors.
    
    Args:
        title: The header title text
        width: Width of the header border (default: 60)
        border_char: Character to use for border (default: "=")
        clear_terminal: Whether to clear terminal before rendering
        icon: Optional icon/emoji to include before title
        icon_color: Color for the icon (from Colors class)
        title_color: Color for the title text (from Colors class)
    """
    if clear_terminal:
        os.system('cls' if os.name == 'nt' else 'clear')
    
    # Render top border
    print("\n" + border_char * width)
    
    # Prepare title with optional icon
    if icon:
        # Apply colors to icon and title separately, then combine
        colored_icon = colorize_text(icon, icon_color) if icon_color else icon
        colored_title = colorize_text(title, title_color) if title_color else title
        display_title = f"{colored_icon} {colored_title}"
    else:
        # Apply color to title only
        display_title = colorize_text(title, title_color) if title_color else title
    
    # Render title
    print(display_title)
    
    # Render bottom border
    print(border_char * width)


def render_section_header(title: str, width: int = 50, border_char: str = "-") -> None:
    """Render a smaller section header within content.
    
    Args:
        title: The section title
        width: Width of the border
        border_char: Character for the border
    """
    print(f"\n{title}")
    print(border_char * width)


def render_status_line(label: str, status: str, message: str = None, 
                      status_color: str = None) -> None:
    """Render a consistent status line.
    
    Args:
        label: Status label (e.g., "WSL Status")
        status: Status value (e.g., "Success", "Error")
        message: Optional detailed message
        status_color: Color for the status value
    """
    colored_status = colorize_text(status, status_color, bold=True) if status_color else status
    
    if message:
        print(f"📋 {label}: {colored_status}")
        print(f"   Message: {message}")
    else:
        print(f"📋 {label}: {colored_status}")


def get_status_color(status: str) -> str:
    """Get appropriate color for a status value.
    
    Args:
        status: Status string (Success, Error, Failed, etc.)
        
    Returns:
        Appropriate color code
    """
    status_lower = status.lower()
    if status_lower in ['success', 'ok', 'healthy']:
        return Colors.GREEN
    elif status_lower in ['error', 'failed', 'critical']:
        return Colors.RED
    elif status_lower in ['warning', 'skipped']:
        return Colors.YELLOW
    elif status_lower in ['cancelled']:
        return Colors.CYAN
    else:
        return None


def render_selection_menu(title: str, choices: list, icon: str = None, 
                         icon_color: str = None, prompt: str = None) -> str:
    """Render a consistent selection menu with header and return user choice.
    
    Args:
        title: Menu title (e.g., "Installation Options")
        choices: List of choice strings
        icon: Optional icon for the header
        icon_color: Color for the header icon
        prompt: Custom prompt text (default: "Choose an option:")
        
    Returns:
        Selected choice string or None if cancelled
    """
    try:
        import questionary  # type: ignore
        
        # Render header for the menu
        render_header(title, icon=icon, icon_color=icon_color)
        
        # Use custom prompt or default
        menu_prompt = prompt or "Choose an option:"
        
        # Show selection menu
        choice = questionary.select(
            menu_prompt,
            choices=choices
        ).ask()
        
        return choice
        
    except ImportError:
        print("Questionary not available - falling back to basic input")
        return None
    except Exception:
        return None


def press_enter_to_continue(message: str = "Press Enter to continue...") -> None:
    """Show a consistent 'press enter' prompt.
    
    Args:
        message: Custom message (optional)
    """
    print()
    input(message)


# Icon color mappings for common operations
ICON_COLORS = {
    '🚀': Colors.ORANGE,     # Install/Launch
    '🔄': Colors.BLUE,       # Reset/Reload 
    '🔍': Colors.CYAN,       # Status/Search
    '💾': Colors.GREEN,      # Backup/Save
    '🐳': Colors.BLUE,       # Docker
    '🐧': Colors.ORANGE,     # WSL/Linux
    '📊': Colors.MAGENTA,    # Reports/Analytics
    '⚙️': Colors.YELLOW,     # Configuration
    '🗑️': Colors.RED,        # Delete/Remove
    '📦': Colors.BROWN if hasattr(Colors, 'BROWN') else Colors.YELLOW,  # Containers
    '🗂️': Colors.CYAN,       # Files/Volumes
}


def get_icon_color(icon: str) -> str:
    """Get the appropriate color for a given icon.
    
    Args:
        icon: The icon/emoji character
        
    Returns:
        Color code for the icon, or None if no mapping
    """
    return ICON_COLORS.get(icon, None)


if __name__ == '__main__':
    # Demo of the UI library functions
    print("UI Library Demo")
    print("=" * 30)
    
    # Test header rendering
    render_header("Test Header", icon="🔍", icon_color=Colors.CYAN, clear_terminal=False)
    
    # Test status lines
    render_status_line("Test Status", "Success", "Everything is working", Colors.GREEN)
    render_status_line("Another Status", "Error", "Something went wrong", Colors.RED)
    
    # Test section header
    render_section_header("Section Details")
    print("Some content here...")
    
    press_enter_to_continue()