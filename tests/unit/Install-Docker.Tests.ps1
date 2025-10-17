<# Install-Docker unit tests #>

$scriptPath = 'C:\Users\justi\OneDrive\Desktop\LocalRepos\wsl-and-docker-desktop-manager\INSTALL-DOCKER-DESKTOP.ps1'

Describe "INSTALL-DOCKER-DESKTOP" {
    Context "Test-WSL2Ready" {
        BeforeAll {
            Mock wsl { return "  2" }
            . $scriptPath
        }

        It "Should return boolean from Test-WSL2Ready" {
            (Test-WSL2Ready) | Should Be $true
        }
    }
}
