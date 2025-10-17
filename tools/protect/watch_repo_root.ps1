<# Wrapper copy of watcher; see tools/watcher/watch_repo_root.ps1 for original #>
& "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)\..\watcher\watch_repo_root.ps1" @Args
