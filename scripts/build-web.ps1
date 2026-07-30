# Build Flutter web locally (same output Render deploys as casevault-web).
param(
    [string]$ApiBase = "https://munshi-api.onrender.com"
)

$ErrorActionPreference = "Stop"
$AppDir = Join-Path $PSScriptRoot "..\app"
Push-Location $AppDir
try {
    Write-Host "API base: $ApiBase" -ForegroundColor Cyan
    flutter pub get
    flutter build web --release "--dart-define=MUNSHI_API_BASE=$ApiBase"
    $out = Join-Path $AppDir "build\web"
    Write-Host ""
    Write-Host "Web build ready: $out" -ForegroundColor Green
    Write-Host "Preview: cd app && flutter run -d chrome --dart-define=MUNSHI_API_BASE=$ApiBase" -ForegroundColor Yellow
}
finally {
    Pop-Location
}
