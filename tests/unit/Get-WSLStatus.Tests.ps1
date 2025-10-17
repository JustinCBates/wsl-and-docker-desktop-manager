BeforeAll {
    # Import the status module
    $statusModulePath = Join-Path $PSScriptRoot "..\..\scripts\status\Get-WSLStatus.ps1"
    . $statusModulePath
}

Describe "Get-WSLStatus" {
    Context "When WSL is not installed" {
        BeforeAll {
            Mock wsl { throw "wsl command not found" }
        }
        
        It "Should return WSL as not installed" {
            $result = Test-WSLInstalled
            $result.Installed | Should -Be $false
        }
    }
    
    Context "When WSL is installed" {
        BeforeAll {
            Mock wsl {
                if ($args -contains "--version") {
                    return @"
WSL version: 2.0.9.0
Kernel version: 5.15.133.1
WSLg version: 1.0.59
"@
                }
                elseif ($args -contains "--list") {
                    return @"
Windows Subsystem for Linux Distributions:
Ubuntu-22.04 (Default)
docker-desktop
docker-desktop-data
"@
                }
            }
            $global:LASTEXITCODE = 0
        }
        
        It "Should detect WSL installation" {
            $result = Test-WSLInstalled
            $result.Installed | Should -Be $true
        }
        
        It "Should parse version information" {
            $result = Test-WSLInstalled
            $result.Version | Should -Match "2.0.9.0"
        }
    }
}

Describe "Get-WSLDistribution" {
    Context "When distributions are installed" {
        BeforeAll {
            Mock wsl {
                return @"
  Ubuntu-22.04
  docker-desktop
  docker-desktop-data
"@
            }
        }
        
        It "Should return list of distributions" {
            $result = Get-WSLDistribution
            $result | Should -Not -BeNullOrEmpty
        }
        
        It "Should parse distribution names correctly" {
            $result = Get-WSLDistribution
            $result | Should -Contain "Ubuntu-22.04"
        }
    }
    
    Context "When no distributions are installed" {
        BeforeAll {
            Mock wsl { return "" }
        }
        
        It "Should handle no distributions gracefully" {
            { Get-WSLDistribution } | Should -Not -Throw
        }
    }
}

Describe "Get-WSLRunningDistribution" {
    Context "When distributions are running" {
        BeforeAll {
            Mock wsl {
                return @"
  NAME                   STATE
  Ubuntu-22.04           Running
  docker-desktop         Running
  docker-desktop-data    Stopped
"@
            }
        }
        
        It "Should return only running distributions" {
            $result = Get-WSLRunningDistribution
            $result | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "Test-WSLFeatureEnabled" {
    Context "When checking Windows features" {
        BeforeAll {
            Mock Get-WindowsOptionalFeature {
                return @{
                    FeatureName = "Microsoft-Windows-Subsystem-Linux"
                    State = "Enabled"
                }
            }
        }
        
        It "Should detect enabled WSL feature" {
            $result = Test-WSLFeatureEnabled
            $result | Should -Be $true
        }
    }
    
    Context "When WSL feature is disabled" {
        BeforeAll {
            Mock Get-WindowsOptionalFeature {
                return @{
                    FeatureName = "Microsoft-Windows-Subsystem-Linux"
                    State = "Disabled"
                }
            }
        }
        
        It "Should detect disabled WSL feature" {
            $result = Test-WSLFeatureEnabled
            $result | Should -Be $false
        }
    }
}
