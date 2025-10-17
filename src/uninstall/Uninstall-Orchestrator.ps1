<#
MOCK — Uninstall-Orchestrator.ps1
This file contains a mock implementation for UI testing only. It does not perform any destructive actions.
The mock function returns a plain descriptive string explaining what the real implementation would do.
#>

function Uninstall-Orchestrator {
	[CmdletBinding()]
	param()

	return "MOCK: Uninstall-Orchestrator would sequence uninstall steps: stop Docker, uninstall Docker Desktop, unregister WSL distributions (requires -Yes). This is a no-op mock."
}

Export-ModuleMember -Function Uninstall-Orchestrator

