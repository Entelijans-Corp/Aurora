param(
    [switch]$Run,
    [switch]$Test
)

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$wslRepoRoot = "/mnt/" + $repoRoot.Substring(0, 1).ToLower() + $repoRoot.Substring(2).Replace("\", "/")

if ($Test) {
    wsl bash -lc "cd '$wslRepoRoot' && zig build test"
    exit $LASTEXITCODE
}

if ($Run) {
    wsl bash -lc "cd '$wslRepoRoot' && zig build run"
    exit $LASTEXITCODE
}

wsl bash -lc "cd '$wslRepoRoot' && zig build"
exit $LASTEXITCODE
