#!/bin/bash
set -e

if [ -f "build/web/index.html" ]; then
  echo "==> Production Flutter web build already exists in build/web."
  echo "==> Deploying existing production assets directly to Vercel..."
  exit 0
fi

echo "==> No pre-existing build/web found. Setting up Flutter SDK..."
git clone https://github.com/flutter/flutter.git --depth 1 -b stable flutter-sdk
export PATH="$PATH:$(pwd)/flutter-sdk/bin"

echo "==> Flutter version:"
flutter --version

echo "==> Building Flutter Web Release..."
flutter pub get
flutter build web --release

echo "==> Flutter web build completed successfully!"