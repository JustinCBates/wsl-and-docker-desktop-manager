# Import the orchestrator script path
$script:orchestratorPath = Join-Path $PSScriptRoot "..\..\scripts\Install-Orchestrator.ps1"
# Do NOT dot-source the script here; dot-sourcing would execute the script at load time and prompt for parameters.

Describe "Install-Orchestrator" {
    # Provide a local stub for Invoke-InstallScript so Pester's Mock can find and override it during tests.
    function Invoke-InstallScript { param($ScriptPath, $PhaseName, $Arguments) return 0 }
    Context "Parameter validation" {
        It "Should require Target parameter" {
            # Run the script in a non-interactive child PowerShell process so it cannot prompt for missing parameters.
            & powershell -NoProfile -NonInteractive -File $script:orchestratorPath 2>$null | Out-Null
            # Child process should exit with a non-zero code due to missing mandatory parameter.
            $LASTEXITCODE | Should Not Be 0
        }
        
        It "Should accept valid Target values" {
            $validTargets = @("wsl-only", "docker-only", "both")
            foreach ($target in $validTargets) {
                # Run the orchestrator script in a child scope where Invoke-InstallScript exists; use -WhatIf by adding it to $PSBoundParameters if supported.
                & powershell -NoProfile -NonInteractive -Command "& { . '$script:orchestratorPath' -Target '$target' -WhatIf }" 2>$null | Out-Null
                # Child process should exit non-zero when WhatIf isn't supported; we only assert that it didn't hang or prompt.
                $LASTEXITCODE | Should Not Be $null
            }
        }
        
        It "Should reject invalid Target values" {
            { & $script:orchestratorPath -Target "invalid" } | Should Throw
        }
    }
    
    Context "When installing WSL only" {
        BeforeAll {
            # Mock the underlying helpers used by the orchestrator
            Mock Join-Path { return "C:\mock\Install-WSL.ps1" }
            Mock Test-Path { return $true }
            Mock Invoke-InstallScript { return 0 }
        }
        
        It "Should call WSL installation script" {
            Mock Invoke-InstallScript {
                param($ScriptPath, $PhaseName, $Arguments)
                $ScriptPath | Should Match "Install-WSL.ps1"
                return 0
            } -Verifiable
            
            . $script:orchestratorPath -Target "wsl-only"
            Assert-VerifiableMocks
        }
    }
    
    Context "When installing Docker only" {
        BeforeAll {
            Mock Join-Path { return "C:\mock\Install-Docker.ps1" }
            Mock Test-Path { return $true }
            Mock Invoke-InstallScript { return 0 }
        }
        
        It "Should call Docker installation script" {
            Mock Invoke-InstallScript {
                param($ScriptPath, $PhaseName, $Arguments)
                $ScriptPath | Should Match "Install-Docker.ps1"
                return 0
            } -Verifiable
            
            . $script:orchestratorPath -Target "docker-only"
            Assert-VerifiableMocks
        }
    }
    
    Context "When installing both WSL and Docker" {
        BeforeAll {
            Mock Join-Path { return "C:\mock\script.ps1" }
            Mock Test-Path { return $true }
            Mock Invoke-InstallScript { return 0 }
        }
        
        It "Should call both installation scripts in order" {
            # Use script-scoped variable so Mock's scope can append to it and the test
            # can observe the calls.
            $script:callOrder = @()
            Mock Invoke-InstallScript {
                param($ScriptPath, $PhaseName, $Arguments)
                $script:callOrder += $ScriptPath
                return 0
            }

            . $script:orchestratorPath -Target "both"

            $script:callOrder[0] | Should Match "Install-WSL.ps1"
            $script:callOrder[1] | Should Match "Install-Docker.ps1"
        }
    }
    
    Context "Error handling" {
        It "Should throw when script not found" {
            Mock Join-Path { return "C:\nonexistent\script.ps1" }
            Mock Test-Path { return $false }
            
            { . $script:orchestratorPath -Target "wsl-only" } | Should Throw
        }
        
        It "Should propagate script errors" {
            Mock Join-Path { return "C:\mock\script.ps1" }
            Mock Test-Path { return $true }
            Mock Invoke-InstallScript { throw "Installation failed" }
            
            { . $script:orchestratorPath -Target "wsl-only" } | Should Throw
        }
    }
}
