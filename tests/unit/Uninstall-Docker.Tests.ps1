<# Uninstall Docker unit tests #>

$scriptPath = 'C:\Users\justi\OneDrive\Desktop\LocalRepos\wsl-and-docker-desktop-manager\scripts\docker\Uninstall-Docker.ps1'

Describe "Uninstall-Docker" {
    Context "When Docker installed" {
        BeforeAll {
            Mock Get-Process { return $null }
            Mock Stop-Process { return $null }
            . $scriptPath
        }

        It "Should not throw" {
            { & $scriptPath -Force } | Should Not Throw
        }
    }
}
