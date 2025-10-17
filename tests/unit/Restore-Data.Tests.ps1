<# Restore-Data unit tests #>

$scriptPath = 'C:\Users\justi\OneDrive\Desktop\LocalRepos\wsl-and-docker-desktop-manager\scripts\backup\Restore-Data.ps1'

Describe "Restore-Data Script" {
    Context "When backup is valid" {
        BeforeAll {
            Mock Test-Path { return $true }
            Mock Get-ChildItem { return @() }
            Mock docker { return "OK" }
            . $scriptPath
        }

        It "Should run restore functions without throwing" {
            { Restore-DockerImage -BackupDir 'C:\tmp' } | Should Not Throw
            { Restore-DockerVolume -BackupDir 'C:\tmp' } | Should Not Throw
            { Restore-DockerConfig -BackupDir 'C:\tmp' } | Should Not Throw
        }
    }
}
