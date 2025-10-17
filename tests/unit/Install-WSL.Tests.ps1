<# Install-WSL unit tests #>

$scriptPath = 'C:\Users\justi\OneDrive\Desktop\LocalRepos\wsl-and-docker-desktop-manager\INSTALL-WSL2-DYNAMIC.ps1'

Describe "INSTALL-WSL2-DYNAMIC" {
    Context "Helper functions" {
        BeforeAll {
            Mock Get-WindowsOptionalFeature { @{ State = 'Enabled' } }
            Mock Invoke-WebRequest { return $null }
            . $scriptPath
        }

        It "Test-WindowsFeature should return boolean" {
            (Test-WindowsFeature -FeatureName 'Microsoft-Windows-Subsystem-Linux') | Should Be $true
        }
    }
}
