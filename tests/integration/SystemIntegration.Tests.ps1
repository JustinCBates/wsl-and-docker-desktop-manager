"# Set project root for tests (do this at top-level instead of BeforeAll to be Pester v3 compatible)"
$script:projectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

Describe "System Status Integration" -Tag "Integration" {
    Context "When checking complete system status" {
        BeforeAll {
            . "$script:projectRoot\scripts\status\Get-SystemStatus.ps1"
        }
        
        It "Should return comprehensive status object" {
            $status = Get-SystemStatus
            $status | Should Not BeNullOrEmpty
            $status.WSL | Should Not BeNullOrEmpty
            $status.Docker | Should Not BeNullOrEmpty
        }
        
        It "Should have valid timestamp" {
            $status = Get-SystemStatus
            $status.Timestamp | Should Not BeNullOrEmpty
            { [DateTime]::Parse($status.Timestamp) } | Should Not Throw
        }
        
        It "Should include OS information" {
            $status = Get-SystemStatus
            $status.OS | Should Not BeNullOrEmpty
        }
    }
}

Describe "WSL Status Integration" -Tag "Integration" {
    Context "When querying actual WSL state" {
        BeforeAll {
            . "$script:projectRoot\scripts\status\Get-WSLStatus.ps1"
        }
        
        It "Should detect WSL installation state" {
            $status = Test-WSLInstalled
            $status.Installed | Should BeOfType [bool]
        }
        
        It "Should handle wsl command execution" {
            { Get-WSLDistribution } | Should Not Throw
        }
        
        It "Should report feature status" {
            { Test-WSLFeatureEnabled } | Should Not Throw
        }
    }
}

Describe "Docker Status Integration" -Tag "Integration" {
    Context "When querying actual Docker state" {
        BeforeAll {
            . "$script:projectRoot\scripts\status\Get-DockerStatus.ps1"
        }
        
        It "Should detect Docker installation state" {
            $status = Test-DockerInstalled
            $status.Available | Should BeOfType [bool]
        }
        
        It "Should handle docker command execution" {
            { Test-DockerRunning } | Should Not Throw
        }
    }
}

Describe "Orchestrator Integration" -Tag "Integration","Slow" {
    Context "When validating orchestrator workflow" {
        It "Should have all required component scripts" {
            $requiredScripts = @(
                "$script:projectRoot\scripts\wsl\Install-WSL.ps1",
                "$script:projectRoot\scripts\docker\Install-Docker.ps1",
                "$script:projectRoot\scripts\status\Get-SystemStatus.ps1",
                "$script:projectRoot\scripts\status\Get-WSLStatus.ps1",
                "$script:projectRoot\scripts\status\Get-DockerStatus.ps1"
            )
            
                foreach ($file in $requiredScripts) {
                    Test-Path $file | Should Be $true -Because "$file should exist"
                }
        }
        
        It "Should have valid PowerShell syntax in all scripts" {
            $allScripts = Get-ChildItem "$script:projectRoot\scripts" -Recurse -Filter *.ps1
            
                foreach ($file in $allScripts) {
                    $content = Get-Content $file.FullName -Raw
                    $errors = $null
                    $null = [System.Management.Automation.PSParser]::Tokenize($content, [ref]$errors)

                    $errors.Count | Should Be 0 -Because "$($file.Name) should have valid syntax"
                }
        }
    }
}

Describe "Python MVP Integration" -Tag "Integration" {
    Context "When validating Python MVP" {
        It "Should have MVP script" {
            $mvpScript = "$script:projectRoot\wsl_docker_manager_mvp.py"
            Test-Path $mvpScript | Should Be $true
        }
        
        It "Should have valid Python syntax" {
            $mvpScript = "$script:projectRoot\wsl_docker_manager_mvp.py"
            { python -m py_compile $mvpScript } | Should Not Throw
        }
        
        It "Should pass linting" {
            $mvpScript = "$script:projectRoot\wsl_docker_manager_mvp.py"
            $result = python -m pylint $mvpScript --score=y 2>&1 | Out-String
            $result | Should Match "rated at 10.00/10"
        }
    }
}
