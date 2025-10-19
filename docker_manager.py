#!/usr/bin/env python3
"""
WSL & Docker Desktop Manager - MVP Entry Point
Handles dependencies and delegates to the main orchestrator.
"""

import os
import sys
from pathlib import Path

def setup_dependencies():
    """Set up Python path and check dependencies."""
    # Add src directory to path for imports
    src_path = os.path.join(os.path.dirname(__file__), 'src')
    if src_path not in sys.path:
        sys.path.insert(0, src_path)

    # Check required dependencies
    try:
        import questionary
    except ImportError:
        print("❌ Error: questionary library not found!")
        print("Please install dependencies: pip install questionary")
        return False
    
    return True

def main():
    """Main entry point."""
    try:
        # Setup dependencies and paths
        if not setup_dependencies():
            input("Press Enter to exit...")
            sys.exit(1)

        # Import and run the main orchestrator
        from main_orchestrator import main as main_orchestrator_main
        result = main_orchestrator_main(interactive=True)
        
        # Handle exit based on result
        if result and result.status == "Error":
            print(f"❌ Application error: {result.message}")
            sys.exit(1)
            
    except KeyboardInterrupt:
        print("\n👋 Goodbye!")
        sys.exit(0)
    except ImportError as e:
        print(f"❌ Import error: {e}")
        print("Please ensure all required modules are installed.")
        input("Press Enter to exit...")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        input("Press Enter to exit...")
        sys.exit(1)

    # Clean exit
    sys.exit(0)


if __name__ == "__main__":
    main()


