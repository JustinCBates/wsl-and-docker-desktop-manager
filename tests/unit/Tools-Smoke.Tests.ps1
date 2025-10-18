<# Tools smoke tests #>

Describe "Tools smoke" {
    It "run_pssa wrapper should run without error when PSSA not installed" {
        { & 'C:\Users\justi\OneDrive\Desktop\LocalRepos\wsl-and-docker-desktop-manager\tools\run_pssa.ps1' } | Should Not Throw
    }

    It "run_tests_pwsh wrapper should not crash when pwsh not present" {
        { & 'C:\Users\justi\OneDrive\Desktop\LocalRepos\wsl-and-docker-desktop-manager\tools\run_tests_pwsh.ps1' } | Should Not Throw
    }
}
