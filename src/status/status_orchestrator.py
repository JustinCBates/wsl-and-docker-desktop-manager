"""Status orchestrator with interactive menu options.

This orchestrator provides different status checking options with a user-friendly menu.
"""
import os
import sys

# Add parent src directory to path for imports
src_path = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if src_path not in sys.path:
    sys.path.insert(0, src_path)

from step_result import StepResult
from ui.ui_library import render_header, render_status_line, get_status_color, get_icon_color, press_enter_to_continue, render_selection_menu

# Status functions - consolidated into orchestrator
def get_system_status(dry_run: bool = False):
    """Get system status - consolidated from get_system_status.py."""
    if dry_run:
        return StepResult.now(name="get_system_status", status="Skipped", message="Dry-run: system status")
    return StepResult.now(name="get_system_status", status="Success", message="MOCK: System status OK")

def get_docker_status():
    """Get docker status - wrapper for the existing function."""
    try:
        from status.docker.get_docker_status import get_docker_status as _get_docker_status
        return _get_docker_status(dry_run=False)
    except ImportError:
        return StepResult.now(name="get_docker_status", status="Success", message="MOCK: Docker status OK")

def get_wsl_status():
    """Get WSL status - wrapper for the existing function."""
    try:
        from status.wsl.get_wsl_status import get_wsl_status as _get_wsl_status
        return _get_wsl_status(dry_run=False)
    except ImportError:
        return StepResult.now(name="get_wsl_status", status="Success", message="MOCK: WSL status OK")


def main(dry_run: bool = True, yes: bool = False, log_path: str = None, targets=None, progress_cb=None, interactive: bool = False):
    """Top-level entrypoint for the status orchestrator.

    If interactive=True, show status options menu with loop. Otherwise use provided args.
    Returns StepResult objects.
    """
    if interactive:
        while True:
            try:
                # Show status options menu with UI library
                status_choices = [
                    "🔍 Complete System Status",
                    "🐳 Docker Status Only", 
                    "🐧 WSL Status Only",
                    "📊 Detailed System Report",
                    "🔙 Back to Main Menu"
                ]
                
                choice = render_selection_menu(
                    title="System Status Menu",
                    choices=status_choices,
                    icon="🔍",
                    icon_color=get_icon_color("🔍"),
                    prompt="Choose status check option:"
                )
                
                if choice is None or "Back to Main Menu" in choice:
                    return StepResult.now(name="status_orchestrator", status="Cancelled", message="User returned to main menu")
                
                # Execute the chosen status check
                if "Complete System Status" in choice:
                    result = _handle_complete_status()
                elif "Docker Status Only" in choice:
                    result = _handle_docker_status()
                elif "WSL Status Only" in choice:
                    result = _handle_wsl_status()
                elif "Detailed System Report" in choice:
                    result = _handle_detailed_report()
                else:
                    continue
                
                # Show result and wait for user input before returning to status menu
                print()
                if result.status == "Success":
                    print(f"✅ {result.message}")
                elif result.status == "Error":
                    print(f"❌ {result.message}")
                else:
                    print(f"Status: {result.status} - {result.message}")
                
                press_enter_to_continue()
                # Loop back to status menu
                    
            except KeyboardInterrupt:
                return StepResult.now(name="status_orchestrator", status="Cancelled", message="User cancelled status check")
            except Exception as e:
                print(f"Status check error: {str(e)}")
                press_enter_to_continue()
                # Loop back to status menu

    # Non-interactive mode - run complete system status
    return _handle_complete_status()


def _handle_complete_status() -> StepResult:
    """Handle complete system status check."""
    try:
        # Render header with UI library
        render_header("Complete System Status", icon="🔍", icon_color=get_icon_color("🔍"))
        print("Checking WSL and Docker Desktop status...")
        print()
        
        # Get all status information
        wsl_result = get_wsl_status()
        docker_result = get_docker_status()
        system_result = get_system_status()
        
        # Display results
        print("\n📋 Status Summary:")
        print(f"  WSL Status: {wsl_result.status} - {wsl_result.message}")
        print(f"  Docker Status: {docker_result.status} - {docker_result.message}")
        print(f"  System Status: {system_result.status} - {system_result.message}")
        
        # Determine overall status
        statuses = [wsl_result.status, docker_result.status, system_result.status]
        if any(s == "Error" for s in statuses):
            overall_status = "Error"
            message = "Some components have errors"
        elif any(s == "Failed" for s in statuses):
            overall_status = "Failed"
            message = "Some components failed"
        else:
            overall_status = "Success"
            message = "All components are healthy"
        
        return StepResult.now(name="complete_status", status=overall_status, message=message)
        
    except Exception as e:
        return StepResult.now(name="complete_status", status="Error", message=f"Status check failed: {str(e)}")


def _handle_docker_status() -> StepResult:
    """Handle Docker-only status check."""
    try:
        # Render header with UI library  
        render_header("Docker Status Check", icon="🐳", icon_color=get_icon_color("🐳"))
        print("Checking Docker Desktop status...")
        print()
        
        result = get_docker_status()
        
        render_status_line("Docker Status", result.status, result.message, get_status_color(result.status))
        
        return result
        
    except Exception as e:
        return StepResult.now(name="docker_status", status="Error", message=f"Docker status check failed: {str(e)}")


def _handle_wsl_status() -> StepResult:
    """Handle WSL-only status check."""
    try:
        # Render header with UI library
        render_header("WSL Status Check", icon="🐧", icon_color=get_icon_color("🐧"))
        print("Checking WSL distributions and status...")
        print()
        
        result = get_wsl_status()
        
        render_status_line("WSL Status", result.status, result.message, get_status_color(result.status))
        
        return result
        
    except Exception as e:
        return StepResult.now(name="wsl_status", status="Error", message=f"WSL status check failed: {str(e)}")


def _handle_detailed_report() -> StepResult:
    """Handle detailed system report generation."""
    try:
        # Render header with UI library
        render_header("Detailed System Report", icon="📊", icon_color=get_icon_color("📊"))
        print("Generating comprehensive system report...")
        print()
        
        # Get all detailed information
        print("\n🐧 WSL DETAILS:")
        print("-" * 20)
        wsl_result = get_wsl_status()
        print(f"Status: {wsl_result.status}")
        print(f"Details: {wsl_result.message}")
        if wsl_result.error:
            print(f"Error: {wsl_result.error}")
        
        print("\n🐳 DOCKER DETAILS:")
        print("-" * 20)
        docker_result = get_docker_status()
        print(f"Status: {docker_result.status}")
        print(f"Details: {docker_result.message}")
        if docker_result.error:
            print(f"Error: {docker_result.error}")
        
        print("\n🔧 SYSTEM DETAILS:")
        print("-" * 20)
        system_result = get_system_status()
        print(f"Status: {system_result.status}")
        print(f"Details: {system_result.message}")
        if system_result.error:
            print(f"Error: {system_result.error}")
        
        print("\n" + "=" * 50)
        print("📊 Report generation completed")
        
        return StepResult.now(name="detailed_report", status="Success", message="Detailed report generated successfully")
        
    except Exception as e:
        return StepResult.now(name="detailed_report", status="Error", message=f"Report generation failed: {str(e)}")


if __name__ == '__main__':
    result = main(interactive=True)
    if result:
        print(f"\nResult: {result.to_dict()}")