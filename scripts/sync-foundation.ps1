$ErrorActionPreference = 'Stop'

$CoreRemote = if ($env:CORE_REMOTE) { $env:CORE_REMOTE } else { 'master-core' }
$WpRemote = if ($env:WP_REMOTE) { $env:WP_REMOTE } else { 'wp-overlay' }
$Branch = if ($env:FOUNDATION_BRANCH) { $env:FOUNDATION_BRANCH } else { 'main' }

git fetch $CoreRemote $Branch
git fetch $WpRemote $Branch
git subtree pull --prefix foundation/core $CoreRemote $Branch --squash
git subtree pull --prefix foundation/wp $WpRemote $Branch --squash