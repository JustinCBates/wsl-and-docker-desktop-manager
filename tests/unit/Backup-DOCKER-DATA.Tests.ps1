<# Unit tests for Backup-DockerData (minimal test-friendly backup) #>

$scriptPath = Join-Path $PSScriptRoot "..\..\BACKUP-DOCKER-DATA.ps1"

Describe "Backup-Docker-Data MVP" {
    Context "Happy path: containers, images, volumes" {
        BeforeAll {
            Mock docker {
                if ($args -contains 'ps') { return "cont1`ncont2" }
                if ($args -contains 'images') { return "repo1:tag1`nrepo2:tag2" }
                if ($args -contains 'volume') { return "vol1`nvol2" }
            }
            . $scriptPath
        }

        It "returns containers/images/volumes lists" {
            $r = Backup-DockerData -BackupPath 'C:\tmp' 
            $r.Containers | Should Contain 'cont1'
            $r.Images | Should Contain 'repo1:tag1'
            $r.Volumes | Should Contain 'vol1'
            $r.Success | Should Be $true
        }
    }

    Context "Skip images and volumes" {
        BeforeAll { Mock docker { return "ignored" }; . $scriptPath }
        It "respects skip flags" {
            $r = Backup-DockerData -SkipImages -SkipVolumes
            $r.SkippedImages | Should Be $true
            $r.SkippedVolumes | Should Be $true
        }
    }

    Context "docker failure" {
        BeforeAll { Mock docker { throw 'docker error' }; . $scriptPath }
        It "returns Success=false on failure" {
            $r = Backup-DockerData
            $r.Success | Should Be $false
            $r.Messages | Should Not BeNullOrEmpty
        }
    }
}
<#
Unit tests for BACKUP-DOCKER-DATA.ps1 (root-level)
These tests are Pester v3-compatible and mock docker and file-system operations.
#>

$scriptPath = 'C:\Users\justi\OneDrive\Desktop\LocalRepos\wsl-and-docker-desktop-manager\BACKUP-DOCKER-DATA.ps1'

Describe "Backup-Docker-Data Script" {
    Context "When Docker is running and images/volumes exist" {
        BeforeAll {
            Mock docker { return "OK" }
            Mock Test-Path { return $false }
            Mock New-Item { return $null }
            Mock Copy-Item { return $null }
            . $scriptPath
        }

        It "Backup functions should run without throwing" {
            { Backup-DockerImages -BackupDir 'C:\tmp' } | Should Not Throw
            { Backup-DockerVolumes -BackupDir 'C:\tmp' } | Should Not Throw
            { Create-BackupManifest -BackupDir 'C:\tmp' } | Should Not Throw
        }
    }

    Context "When Docker is not running" {
        BeforeAll {
            Mock docker { throw 'docker not found' }
            . $scriptPath
        }

        It "Should handle missing docker gracefully" {
            { Backup-DockerImages -BackupDir 'C:\tmp' } | Should Not Throw
        }
    }
}
