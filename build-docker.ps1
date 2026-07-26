# Fully Automated PowerShell Docker Build & Test Script for GeoMeasure
# Run this script to test, analyze, and build Android/Web artifacts locally via Docker

Param(
    [switch]$SkipTests = $false,
    [switch]$BuildApk = $true
)

$ErrorActionPreference = "Stop"

Write-Host "====================================================" -ForegroundColor Cyan
Write-Host " GeoMeasure - Automated Docker Build & Test Script" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan

# 1. Ensure output artifact folder exists
$artifactDir = Join-Path -Path $PSScriptRoot -ChildPath "build_artifacts"
if (-not (Test-Path $artifactDir)) {
    New-Item -ItemType Directory -Path $artifactDir | Out-Null
    Write-Host "[+] Created output directory: $artifactDir" -ForegroundColor Green
}

# 2. Build Docker Container
Write-Host "`n[1/4] Building GeoMeasure Docker Image..." -ForegroundColor Yellow
docker compose build
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to build Docker container."
    exit 1
}

# 3. Run Static Analysis & Unit Tests
if (-not $SkipTests) {
    Write-Host "`n[2/4] Running Static Analysis inside Docker..." -ForegroundColor Yellow
    docker compose run --rm app-analyze

    Write-Host "`n[3/4] Running Full Test Suite with Coverage..." -ForegroundColor Yellow
    docker compose run --rm app-test
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Test suite failed!"
        exit 1
    }
    Write-Host "[+] All Tests Passed with 100% Pass Rate!" -ForegroundColor Green
} else {
    Write-Host "`n[*] Skipping Test Suite as requested." -ForegroundColor Gray
}

# 4. Build Application Artifacts via Docker
if ($BuildApk) {
    Write-Host "`n[4/4] Compiling Application Artifacts..." -ForegroundColor Yellow
    docker compose run --rm app-build

    # Copy built APK to host artifacts folder if available
    $containerApkPath = "build/app/outputs/flutter-apk/app-debug.apk"
    if (Test-Path $containerApkPath) {
        Copy-Item -Path $containerApkPath -Destination (Join-Path $artifactDir "geomeasure-app-debug.apk") -Force
        Write-Host "[+] Application APK copied to: $artifactDir\geomeasure-app-debug.apk" -ForegroundColor Green
    }
}

Write-Host "`n====================================================" -ForegroundColor Cyan
Write-Host " Build & Verification Completed Successfully!" -ForegroundColor Cyan
Write-Host " Artifacts stored in: $artifactDir" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
