<# Get-SystemStatus unit tests #>

$scriptPath = 'C:\Users\justi\OneDrive\Desktop\LocalRepos\wsl-and-docker-desktop-manager\scripts\status\Get-SystemStatus.ps1'

Describe "Get-SystemStatus" {
    Context "Basic diagnostics" {
        BeforeAll {
            Mock Get-CimInstance { return @{ Name = 'Test' } }
            . $scriptPath
        }

        It "Get-SystemStatus should return a hashtable" {
            $s = Get-SystemStatus
            $s.GetType().Name | Should Be 'Hashtable'
        }
    }
}
