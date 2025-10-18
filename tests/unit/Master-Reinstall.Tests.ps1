<# Master reinstaller helper unit tests #>

$scriptPath = 'C:\Users\justi\OneDrive\Desktop\LocalRepos\wsl-and-docker-desktop-manager\MASTER-REINSTALL.ps1'

Describe "Master Reinstaller Helpers" {
    Context "Invoke-ScriptPhase" {
        BeforeAll {
            Mock Test-Path { return $true }
            Mock docker { return 'OK' }
            . $scriptPath
        }

        It "Invoke-ScriptPhase returns true for an existing dummy script and errors for missing ones" {
            # Create a temporary dummy script to simulate existing script
            $tmp = Join-Path $PSScriptRoot 'tmp-dummy-script.ps1'
            "Write-Output 'hello'" | Out-File -FilePath $tmp -Encoding UTF8
            try {
                (Invoke-ScriptPhase -ScriptName (Split-Path $tmp -Leaf) -PhaseName 'Dummy' -Arguments @()) | Should Not BeNullOrEmpty
            } finally {
                Remove-Item $tmp -Force -ErrorAction SilentlyContinue
            }

            # Ensure missing script causes an error
            { Invoke-ScriptPhase -ScriptName 'NON_EXISTENT_SCRIPT.ps1' -PhaseName 'Missing' } | Should Throw
        }
    }
}
