$ErrorActionPreference = 'Stop'

$CoreRemoteName = if ($env:CORE_REMOTE_NAME) { $env:CORE_REMOTE_NAME } else { 'master-core' }
$WpRemoteName = if ($env:WP_REMOTE_NAME) { $env:WP_REMOTE_NAME } else { 'wp-overlay' }
$CoreRemoteUrl = if ($env:CORE_REMOTE_URL) { $env:CORE_REMOTE_URL } else { 'https://github.com/esfih/master-core.git' }
$WpRemoteUrl = if ($env:WP_REMOTE_URL) { $env:WP_REMOTE_URL } else { 'https://github.com/esfih/wp-overlay.git' }
$Branch = if ($env:FOUNDATION_BRANCH) { $env:FOUNDATION_BRANCH } else { 'main' }

function Set-RemoteIfProvided {
    param(
        [string]$Name,
        [string]$Url
    )

    if ([string]::IsNullOrWhiteSpace($Url)) {
        return
    }

    git remote get-url $Name *> $null
    if ($LASTEXITCODE -eq 0) {
        git remote set-url $Name $Url
    } else {
        git remote add $Name $Url
    }
}

function Add-SubtreeIfMissing {
    param(
        [string]$Prefix,
        [string]$Remote,
        [string]$TargetBranch
    )

    if (Test-Path $Prefix) {
        return
    }

    git fetch $Remote $TargetBranch
    git subtree add --prefix $Prefix $Remote $TargetBranch --squash
}

Set-RemoteIfProvided -Name $CoreRemoteName -Url $CoreRemoteUrl
Set-RemoteIfProvided -Name $WpRemoteName -Url $WpRemoteUrl

Add-SubtreeIfMissing -Prefix 'foundation/core' -Remote $CoreRemoteName -TargetBranch $Branch
Add-SubtreeIfMissing -Prefix 'foundation/wp' -Remote $WpRemoteName -TargetBranch $Branch

Write-Host 'Foundation bootstrap complete.'