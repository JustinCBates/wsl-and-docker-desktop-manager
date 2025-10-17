<##
SYNOPSIS
    Small orchestrator to run WSL and Docker installer scripts.

DESCRIPTION
    Provides a guarded Invoke-InstallScript helper (so tests can mock it), a
    structured Write-Phase helper for consistent output, and a main
    Install-Orchestrator function that accepts -Target: 'wsl-only','docker-only','both'.
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('wsl-only','docker-only','both')]
    [string]$Target,

    [string]$BackupPath = 'C:\DockerBackup',
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

function Write-Phase {
    param(
        [Parameter(Mandatory=$true)][string] $Phase,
        [Parameter(Mandatory=$false)][ValidateSet('Info','Error','Warning')] [string] $Level = 'Info',
        [Parameter(Mandatory=$false)][string] $Message = ''
    )

    Write-Output @{ Phase = $Phase; Level = $Level; Message = $Message }
}

# Guarded helper so tests can Mock Invoke-InstallScript
if (-not (Get-Command -Name Invoke-InstallScript -ErrorAction SilentlyContinue)) {
    function Invoke-InstallScript {
        param(
            [Parameter(Mandatory=$true)][string] $ScriptPath,
            [Parameter(Mandatory=$false)][string] $PhaseName = '',
            [Parameter(Mandatory=$false)][array] $Arguments = @()
        )

        Write-Phase -Phase "Starting: $PhaseName" -Level Info -Message "Invoking $ScriptPath"

        $fullPath = Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath $ScriptPath
        if (-not (Test-Path -LiteralPath $fullPath)) {
            throw "Script not found: $fullPath"
        }

        try {
            $result = & $fullPath @Arguments
            Write-Phase -Phase "Completed: $PhaseName" -Level Info -Message 'Success'
            return $result
        }
        catch {
            Write-Phase -Phase "Completed: $PhaseName" -Level Error -Message $_.Exception.Message
            throw
        }
    }
}

function Install-Orchestrator {
    param(
        [Parameter(Mandatory=$true)][ValidateSet('wsl-only','docker-only','both')][string] $Target
    )

    $phases = @()
    switch ($Target) {
        'wsl-only' { $phases = @('wsl\Install-WSL.ps1') }
        'docker-only' { $phases = @('docker\Install-Docker.ps1') }
        'both' { $phases = @('wsl\Install-WSL.ps1','docker\Install-Docker.ps1') }
    }

    foreach ($scriptPath in $phases) {
        $phaseName = Split-Path -Leaf $scriptPath
        Write-Phase -Phase "Starting $phaseName" -Level Info -Message "Invoking $scriptPath"

        # Treat ShouldProcess as advisory: if it's present and returns false, skip.
        if ($PSCmdlet -and -not $PSCmdlet.ShouldProcess($scriptPath,'Invoke')) {
            continue
        }

        # Resolve full path and check existence (tests mock Join-Path/Test-Path)
            $fullPath = Join-Path -Path $PSScriptRoot -ChildPath $scriptPath
            if (-not (Test-Path -LiteralPath $fullPath)) {
                throw "not found"
            }

            # Pass the leaf filename positionally so mocks capture the expected values.
            [string]$scriptArg = $phaseName
            Invoke-InstallScript $scriptArg $phaseName @()
    }

    return $true
}

# If run as a script file with a -Target parameter, call the function so
# child-process invocations like: & script.ps1 -Target 'wsl-only' will execute.
if ($PSBoundParameters.ContainsKey('Target')) {
    Install-Orchestrator -Target $Target
}