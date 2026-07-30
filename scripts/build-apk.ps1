# Build Android APK locally (APK is not hosted on Render — sideload or Play Store).
param(
    [string]$ApiBase = "https://munshi-api.onrender.com",
    [ValidateSet("debug", "release")]
    [string]$Mode = "debug"
)

$ErrorActionPreference = "Stop"
$AppDir = Join-Path $PSScriptRoot "..\app"
Push-Location $AppDir
try {
    Write-Host "API base: $ApiBase" -ForegroundColor Cyan
    flutter pub get
    flutter build apk "--$Mode" "--dart-define=MUNSHI_API_BASE=$ApiBase"
    if ($LASTEXITCODE -ne 0) { throw "flutter build apk failed with exit code $LASTEXITCODE" }
    $apk = Join-Path $AppDir "build\app\outputs\flutter-apk\app-$Mode.apk"
    if (-not (Test-Path $apk)) { throw "APK not found at $apk" }
    Write-Host ""
    Write-Host "APK ready: $apk" -ForegroundColor Green
    Write-Host "Install: adb install `"$apk`"" -ForegroundColor Yellow
}
finally {
    Pop-Location
}
