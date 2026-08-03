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
    if ($Mode -eq "release" -and ($ApiBase -match '127\.0\.0\.1|localhost|10\.0\.2\.2')) {
        throw "Release APK cannot use a local API URL ($ApiBase). Use your Render URL, e.g. https://munshi-api.onrender.com"
    }
    Write-Host "API base: $ApiBase" -ForegroundColor Cyan
    flutter pub get
    flutter build apk "--$Mode" "--dart-define=MUNSHI_API_BASE=$ApiBase"
    if ($LASTEXITCODE -ne 0) { throw "flutter build apk failed with exit code $LASTEXITCODE" }
    $apk = Join-Path $AppDir "build\app\outputs\flutter-apk\app-$Mode.apk"
    if (-not (Test-Path $apk)) { throw "APK not found at $apk" }
    Write-Host ""
    Write-Host "APK ready: $apk" -ForegroundColor Green
    Write-Host "Install: adb install -r `"$apk`"" -ForegroundColor Yellow
}
finally {
    Pop-Location
}
