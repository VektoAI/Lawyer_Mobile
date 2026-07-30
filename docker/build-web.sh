#!/bin/sh
# Bakes MUNSHI_API_BASE into the Flutter web bundle at Docker build time.
set -e
API="${MUNSHI_API_BASE:-https://munshi-api.onrender.com}"
echo "Building Flutter web with MUNSHI_API_BASE=${API}"
flutter build web --release --dart-define=MUNSHI_API_BASE="${API}"
