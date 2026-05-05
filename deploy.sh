#!/bin/bash
# 🚀 럭키비키 일기장 — One-command deployment
# Usage:
#   ./deploy.sh android beta    # → Play Store 내부 테스트
#   ./deploy.sh android deploy  # → Play Store 프로덕션
#   ./deploy.sh ios beta        # → TestFlight
#   ./deploy.sh ios deploy      # → App Store
#   ./deploy.sh all beta        # → 양쪽 모두 베타 배포

set -e

# Homebrew Ruby 를 시스템 Ruby 보다 우선시
export PATH="/opt/homebrew/opt/ruby/bin:/opt/homebrew/lib/ruby/gems/4.0.0/bin:/opt/homebrew/bin:/opt/homebrew/share/flutter/bin:$PATH"
export GEM_HOME="/opt/homebrew/lib/ruby/gems/4.0.0"
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

PLATFORM=${1:-"all"}
LANE=${2:-"beta"}

echo "═══════════════════════════════════════════"
echo "🚀 럭키비키 일기장 Deploy"
echo "  Platform: $PLATFORM"
echo "  Lane:     $LANE"
echo "═══════════════════════════════════════════"

# Flutter clean & get deps
echo "📦 Cleaning and getting dependencies..."
flutter clean
flutter pub get

# Android
if [ "$PLATFORM" = "android" ] || [ "$PLATFORM" = "all" ]; then
  echo ""
  echo "🤖 Android: Running fastlane $LANE..."
  cd android
  bundle exec fastlane "$LANE"
  cd ..
  echo "✅ Android $LANE complete!"
fi

# iOS
if [ "$PLATFORM" = "ios" ] || [ "$PLATFORM" = "all" ]; then
  echo ""
  echo "🍎 iOS: Pod install..."
  cd ios
  pod install --repo-update
  cd ..

  echo "🔨 iOS: Flutter build..."
  flutter build ios --release --no-codesign

  echo "🚀 iOS: Running fastlane $LANE..."
  cd ios
  bundle exec fastlane "$LANE"
  cd ..
  echo "✅ iOS $LANE complete!"
fi

echo ""
echo "═══════════════════════════════════════════"
echo "🎉 Deployment complete!"
echo "═══════════════════════════════════════════"
