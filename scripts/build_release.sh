#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
flutter clean
flutter pub get
flutter build apk --release
mkdir -p releases
cp -f build/app/outputs/flutter-apk/app-release.apk releases/AutoPlayer-release.apk
echo "APK creada: releases/AutoPlayer-release.apk"
