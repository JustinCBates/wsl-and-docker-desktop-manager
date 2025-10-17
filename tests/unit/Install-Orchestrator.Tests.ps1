BeforeAll {
    # Import the orchestrator
    $script:orchestratorPath = Join-Path $PSScriptRoot "..\..\scripts\Install-Orchestrator.ps1"
}

Describe "Install-Orchestrator" {
    Context "Parameter validation" {
        It "Should require Target parameter" {
            { & $script:orchestratorPath } | Should -Throw
        }
        
        It "Should accept valid Target values" {
            $validTargets = @("wsl-only", "docker-only", "both")
            foreach ($target in $validTargets) {
                { & $script:orchestratorPath -Target $target -WhatIf } | Should -Not -Throw
            }
        }
        
        It "Should reject invalid Target values" {
            { & $script:orchestratorPath -Target "invalid" } | Should -Throw
        }
    }
    
    Context "When installing WSL only" {
        BeforeAll {
            Mock Join-Path { return "C:\mock\Install-WSL.ps1" }
            Mock Test-Path { return $true }
            Mock & { return 0 }
        }
        
        It "Should call WSL installation script" {
            Mock & {
                param($scriptPath)
                $scriptPath | Should -Match "Install-WSL.ps1"
                return 0
            } -Verifiable
            
            & $script:orchestratorPath -Target "wsl-only" -WhatIf
            Should -InvokeVerifiable
        }
    }
    
    Context "When installing Docker only" {
        BeforeAll {
            Mock Join-Path { return "C:\mock\Install-Docker.ps1" }
            Mock Test-Path { return $true }
        }
        
        It "Should call Docker installation script" {
            Mock & {
                param($scriptPath)
                $scriptPath | Should -Match "Install-Docker.ps1"
                return 0
            } -Verifiable
            
            & $script:orchestratorPath -Target "docker-only" -WhatIf
            Should -InvokeVerifiable
        }
    }
    
    Context "When installing both WSL and Docker" {
        BeforeAll {
            Mock Join-Path { return "C:\mock\script.ps1" }
            Mock Test-Path { return $true }
        }
        
        It "Should call both installation scripts in order" {
            $callOrder = @()
            Mock & {
                param($scriptPath)
                $callOrder += $scriptPath
                return 0
            }
            
            & $script:orchestratorPath -Target "both" -WhatIf
            
            $callOrder[0] | Should -Match "Install-WSL.ps1"
            $callOrder[1] | Should -Match "Install-Docker.ps1"
        }
    }
    
    Context "Error handling" {
        It "Should throw when script not found" {
            Mock Join-Path { return "C:\nonexistent\script.ps1" }
            Mock Test-Path { return $false }
            
            { & $script:orchestratorPath -Target "wsl-only" } | Should -Throw "*not found*"
        }
        
        It "Should propagate script errors" {
            Mock Join-Path { return "C:\mock\script.ps1" }
            Mock Test-Path { return $true }
            Mock & { throw "Installation failed" }
            
            { & $script:orchestratorPath -Target "wsl-only" } | Should -Throw
        }
    }
}
