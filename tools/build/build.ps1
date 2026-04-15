param(
    [switch]$Run,
    [switch]$Test,
    [switch]$WithFortran
)

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$zig = Get-Command zig -ErrorAction SilentlyContinue

if (-not $zig) {
    Write-Error "zig is not installed. Install Zig and rerun this script."
    exit 1
}

if ($WithFortran) {
    $gfortran = Get-Command gfortran -ErrorAction SilentlyContinue
    if (-not $gfortran) {
        Write-Error "gfortran is not installed. Install gfortran or omit -WithFortran."
        exit 1
    }

    $artifactsDir = Join-Path $repoRoot "artifacts"
    New-Item -ItemType Directory -Force -Path $artifactsDir | Out-Null

    & gfortran -c (Join-Path $repoRoot "kernel\fortran\scheduler\round_robin.f90") -J $artifactsDir -o (Join-Path $artifactsDir "round_robin.o")
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    & gfortran -c (Join-Path $repoRoot "runtime\fortran_min\aurora_runtime.f90") -J $artifactsDir -o (Join-Path $artifactsDir "aurora_runtime.o")
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

Push-Location $repoRoot
try {
    if ($Test) {
        & zig build test
        exit $LASTEXITCODE
    }

    if ($Run) {
        & zig build run
        exit $LASTEXITCODE
    }

    & zig build
    exit $LASTEXITCODE
}
finally {
    Pop-Location
}

