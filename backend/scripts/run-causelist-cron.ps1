# Run from repo root after setting secret in backend/.env
# Requires: backend running OR use CLI below without HTTP

$secret = $env:MUNSHI_CRON_SECRET
if (-not $secret) { $secret = $env:MUNSHI_ADMIN_TOKEN }
if (-not $secret) { Write-Error "Set MUNSHI_CRON_SECRET or MUNSHI_ADMIN_TOKEN"; exit 1 }

$base = if ($env:MUNSHI_API_URL) { $env:MUNSHI_API_URL.TrimEnd('/') } else { "http://127.0.0.1:4173" }

Invoke-RestMethod -Method POST -Uri "$base/api/cron/causelist-sync" -Headers @{ "X-Cron-Secret" = $secret } -ContentType "application/json" -Body "{}"
