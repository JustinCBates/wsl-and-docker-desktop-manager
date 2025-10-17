<# Uninstall WSL unit tests #>

$scriptPath = 'C:\Users\justi\OneDrive\Desktop\LocalRepos\wsl-and-docker-desktop-manager\scripts\wsl\Uninstall-WSL.ps1'

Describe "Uninstall-WSL" {
    Context "When WSL present" {
        BeforeAll {
            Mock wsl { return @('Ubuntu-22.04') }
            Mock Remove-Item { return $null }
            . $scriptPath
        }

        It "Should not throw during uninstall helper" {
            { & $scriptPath -BackupPath 'C:\tmp' -Force } | Should Not Throw
        }
    }
}
