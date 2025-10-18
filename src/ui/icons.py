"""Centralized emoji/icon palette for the TUI.

This module defines a small palette of emoji and a default mapping
used by the main menu. Keeping icons here makes it easy to adjust
presentation in one place.
"""

# Small palette of useful emoji/icons. Key -> (emoji, human-friendly description)
PALETTE = {
    "whale": ("🐳", "Docker / container-related operations"),
    "rocket": ("🚀", "Install / fresh install"),
    "wrench": ("🔧", "WSL-only installation or tooling"),
    "backup": ("💾", "Backup related operations"),
    "magnify": ("🔍", "Status / inspect"),
    "warning": ("⚠️", "Warning / caution"),
    "cross": ("❌", "Exit / cancel"),
    "sync": ("🔄", "Reset / sync / reinstall"),
    "check": ("✅", "Success / finished"),
    "gear": ("⚙️", "Settings / advanced"),
}


# Default icons used in the top-level main menu. Keys are semantic names used
# by the caller.
MENU_ICONS = {
    "install": PALETTE["rocket"][0],
    "uninstall": PALETTE["sync"][0],
    "status": PALETTE["magnify"][0],
    "backup": PALETTE["backup"][0],
    "exit": PALETTE["cross"][0],
}


def get_icon(name: str) -> str:
    """Return the emoji for a given semantic name or empty string.

    Example: get_icon('install') -> '🚀'
    """
    return MENU_ICONS.get(name, "")


def list_palette() -> list[tuple[str, str, str]]:
    """Return the palette as a list of (key, emoji, description)."""
    return [(k, v[0], v[1]) for k, v in PALETTE.items()]
