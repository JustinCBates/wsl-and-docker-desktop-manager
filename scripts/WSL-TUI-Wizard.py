#!/usr/bin/env python3
"""
WSL & Docker Desktop TUI Wizard
Interactive setup wizard for optimized Docker Desktop and WSL 2 installation
Integrates with MASTER-REINSTALL.ps1 for automated execution
"""

import os
import sys
import subprocess
import json
import argparse
from pathlib import Path
from typing import Dict, Any

def clear_screen():
    """Clear the terminal screen for better UX"""
    os.system('cls' if os.name == 'nt' else 'clear')

# Import system detection module
try:
    from system_detection import detect_system_state, get_installation_options, print_system_status
except ImportError:
    print("⚠️ System detection module not found. Using fallback mode.")
    def detect_system_state():
        return {"overall_state": "unknown"}
    def get_installation_options(state):
        return ["Fresh installation", "Complete reinstall"], "System state unknown"
    def print_system_status(state):
        print("System detection unavailable")

# Import navigation controller
try:
    from navigation_controller import NavigationalTUIWizard, detect_back_navigation
except ImportError:
    print("⚠️ Navigation controller not found. Using basic mode.")
    class NavigationalTUIWizard:
        def __init__(self, engine, layout_name):
            self.engine = engine
            self.layout_name = layout_name
        def execute_with_navigation(self):
            return self.engine.execute_flow(self.layout_name)
    def detect_back_navigation(results):
        return False

def check_admin_privileges():
    """Check if running with administrator privileges"""
    try:
        import ctypes
        return ctypes.windll.shell32.IsUserAnAdmin()
    except:
        return False

def load_existing_config(config_path: str = "wsl_docker_config.json") -> Dict[str, Any]:
    """Load existing configuration if available"""
    config_file = Path(config_path)
    if config_file.exists():
        try:
            with open(config_file, 'r', encoding='utf-8') as f:
                return json.load(f)
        except Exception as e:
            print(f"⚠️ Could not load existing config: {e}")
    return {}

def save_config(config: Dict[str, Any], config_path: str = "wsl_docker_config.json"):
    """Save configuration to file for PowerShell consumption"""
    try:
        with open(config_path, 'w', encoding='utf-8') as f:
            json.dump(config, f, indent=2)
        print(f"✅ Configuration saved to: {config_path}")
        return True
    except Exception as e:
        print(f"❌ Failed to save configuration: {e}")
        return False

def execute_powershell_phase(phase: str, config: Dict[str, Any]) -> bool:
    """Execute PowerShell phase with TUI configuration"""
    try:
        # Build PowerShell command based on configuration
        ps_cmd = ["powershell", "-ExecutionPolicy", "Bypass", "-File", "scripts\\MASTER-REINSTALL.ps1"]
        
        # Add phase
        ps_cmd.extend(["-Phase", phase])
        
        # Add configuration-based parameters
        if config.get('installation', {}).get('backup_location'):
            backup_path = config['installation']['backup_location']
            ps_cmd.extend(["-BackupPath", backup_path])
            
        if config.get('execution', {}).get('confirmed'):
            ps_cmd.append("-AutoConfirm")
            
        if config.get('installation', {}).get('force_reinstall'):
            ps_cmd.append("-Force")
            
        print(f"🚀 Executing: {' '.join(ps_cmd)}")
        
        # Execute PowerShell command
        result = subprocess.run(ps_cmd, capture_output=False)
        return result.returncode == 0
        
    except Exception as e:
        print(f"❌ PowerShell execution failed: {e}")
        return False

def main():
    """Main entry point for WSL & Docker TUI Wizard"""
    parser = argparse.ArgumentParser(description="WSL & Docker Desktop TUI Wizard")
    parser.add_argument("--interactive", action="store_true", default=True, 
                       help="Run in interactive mode (default)")
    parser.add_argument("--config", default="wsl_docker_config.json",
                       help="Configuration file path")
    parser.add_argument("--execute", action="store_true",
                       help="Execute PowerShell phases after configuration")
    parser.add_argument("--phase", choices=["all", "backup", "uninstall-docker", "uninstall-wsl", "install-wsl", "install-docker", "restore"],
                       default="all", help="Specific phase to execute")
    
    args = parser.parse_args()
    
    # Clear screen for clean startup
    clear_screen()
    
    print("WSL & Docker Desktop TUI Wizard")
    print("=" * 50)
    
    # Check admin privileges for execution
    if args.execute and not check_admin_privileges():
        print("❌ PowerShell execution requires Administrator privileges")
        print("Please run PowerShell as Administrator and try again")
        return 1
    
    # Check TUI installation
    try:
        from tui_form_designer import FlowEngine
        print("✅ TUI Form Designer loaded successfully")
    except ImportError as e:
        print(f"❌ TUI Form Designer not found: {e}")
        print("Please run: python -m pip install tui-form-designer")
        return 1
    
    # Load existing configuration
    existing_config = load_existing_config(args.config)
    if existing_config:
        print(f"📋 Loaded existing configuration from: {args.config}")
        
    # Initialize TUI engine
    layouts_dir = Path("../tui_integration/layouts")
    if not layouts_dir.exists():
        print(f"❌ Layouts directory not found: {layouts_dir}")
        return 1
    
    engine = FlowEngine(flows_dir=str(layouts_dir))
    
    if args.interactive:
        # Execute interactive TUI wizard with main menu loop
        try:
            clear_screen()
            print("🚀 Starting WSL & Docker Manager...")
            print("=" * 40)
            
            while True:
                # Show main menu to choose operation
                try:
                    clear_screen()
                    print("🏠 WSL & Docker Manager - Main Menu")
                    print("=" * 40)
                    menu_results = engine.execute_flow("wsl_main_menu")
                    operation_choice = menu_results.get('operation')
                    
                    # Handle TUI engine cancellation (Ctrl+C returns None)
                    if operation_choice is None:
                        print("\n👋 Goodbye!")
                        return 0
                        
                except KeyboardInterrupt:
                    print("\n👋 Goodbye!")
                    return 0
                except Exception as e:
                    # Handle FlowExecutionError and other TUI engine exceptions
                    if "cancelled" in str(e).lower() or "interrupt" in str(e).lower():
                        print("\n👋 Goodbye!")
                        return 0
                    else:
                        print(f"\n❌ TUI error: {e}")
                        return 1
                
                # Debug output
                print(f"DEBUG: operation_choice = '{operation_choice}'")
                print(f"DEBUG: menu_results = {menu_results}")
                
                # Check for exit first, before any screen clearing
                if operation_choice == "Exit":
                    print("\n👋 Goodbye!")
                    return 0
                
                if operation_choice == "Check current system status":
                    # Clear screen for status check
                    clear_screen()
                    print("🔍 System Status Check")
                    print("=" * 30)
                    
                    # Show current system status first
                    system_state = detect_system_state()
                    print_system_status(system_state)
                    
                    # Run status check flow
                    try:
                        status_results = engine.execute_flow("wsl_status_check")
                        
                        status_choice = status_results.get('status_check', {}).get('confirmed', '')
                        
                        if status_choice == "← Go back to main menu":
                            print("💡 Returning to main menu...")
                            continue
                        elif status_choice == "Yes, run status check":
                            clear_screen()
                            print("🔧 Running System Diagnostics...")
                            print("=" * 35)
                            # Run actual status check
                            print("\n🔧 Running system diagnostics...")
                            try:
                                status_cmd = ["powershell", "-ExecutionPolicy", "Bypass", "-File", "Enhanced-WSL-Manager.ps1", "-Mode", "status"]
                                result = subprocess.run(status_cmd, capture_output=False)
                                
                                if result.returncode == 0:
                                    print("✅ Status check completed successfully")
                                else:
                                    print("⚠️ Status check completed with warnings")
                            except Exception as e:
                                print(f"❌ Status check failed: {e}")
                                
                            print("\n💡 Status check complete - returning to main menu")
                        else:
                            print("❌ Status check cancelled by user")
                    except KeyboardInterrupt:
                        print("\n💡 Returning to main menu...")
                        continue
                        
                elif operation_choice == "Configure WSL & Docker Desktop":
                    # Clear screen for configuration wizard
                    clear_screen()
                    print("⚙️ WSL & Docker Configuration Setup")
                    print("=" * 40)
                    
                    # Run configuration wizard with system detection and navigation
                    try:
                        # Detect and display current system state
                        system_state = detect_system_state()
                        print_system_status(system_state)
                        
                        print("\n🚀 Starting Configuration Wizard...")
                        print("=" * 35)
                        
                        # Create navigational wizard
                        nav_wizard = NavigationalTUIWizard(engine, "wsl_docker_setup_wizard")
                        
                        # Execute with back navigation support
                        results = nav_wizard.execute_with_navigation()
                        
                        # Handle navigation results
                        if results.get("navigation") == "back_to_main_menu":
                            print("💡 Returning to main menu...")
                            continue
                        
                        # Validate user choice against system state
                        user_choice = results.get('installation', {}).get('use_case', '')
                        if user_choice == "← Go back to main menu":
                            print("💡 Returning to main menu...")
                            continue
                            
                        if 'Fresh installation' in user_choice and system_state['overall_state'] == 'both_installed':
                            print("\n⚠️ WARNING: Fresh installation selected but existing installation detected!")
                            print("This may cause conflicts. Consider 'Complete uninstall and reinstall' instead.")
                            
                            confirm = input("Continue anyway? (y/N): ")
                            if confirm.lower() not in ['y', 'yes']:
                                print("💡 Installation cancelled - returning to main menu...")
                                continue
                        
                        # Break out of loop after successful configuration
                        break
                    except KeyboardInterrupt:
                        print("\n💡 Returning to main menu...")
                        continue
                        

                    
                else:
                    print("❌ Invalid operation choice")
                    continue
            
            # Process configuration results
            clear_screen()
            print("\n📊 Configuration Summary:")
            for key, value in results.items():
                print(f"  {key}: {value}")
                
            # Save configuration
            if save_config(results, args.config):
                print("✅ Configuration ready for PowerShell execution")
            else:
                print("❌ Failed to save configuration")
                return 1
                
        except KeyboardInterrupt:
            print("\n❌ User cancelled the wizard")
            return 1
        except Exception as e:
            print(f"\n❌ TUI execution failed: {e}")
            import traceback
            traceback.print_exc()
            return 1
    else:
        # Use existing configuration
        if not existing_config:
            print("❌ No existing configuration found and not running interactively")
            print(f"Run with --interactive to create configuration, or provide config file")
            return 1
        results = existing_config
        print("📋 Using existing configuration")
        
    # Execute PowerShell phases if requested
    if args.execute:
        print(f"\n🔧 Executing PowerShell phase: {args.phase}")
        
        if args.phase == "all":
            # Execute full workflow
            phases = ["backup", "uninstall-docker", "uninstall-wsl", "install-wsl", "install-docker"]
            for phase in phases:
                print(f"\n📋 Executing phase: {phase}")
                if not execute_powershell_phase(phase, results):
                    print(f"❌ Phase {phase} failed")
                    return 1
                print(f"✅ Phase {phase} completed")
        else:
            # Execute single phase
            if not execute_powershell_phase(args.phase, results):
                print(f"❌ Phase {args.phase} failed")
                return 1
            print(f"✅ Phase {args.phase} completed")
            
    else:
        print("\n💡 To execute the configuration:")
        print(f"  python WSL-TUI-Wizard.py --execute --phase {args.phase} --config {args.config}")
        print("\nOr run PowerShell directly:")
        print(f"  .\\MASTER-REINSTALL.ps1 -Phase {args.phase}")
        
    return 0

if __name__ == "__main__":
    sys.exit(main())