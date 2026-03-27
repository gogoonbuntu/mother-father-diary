#!/bin/bash
# 🚀 Mother Father Diary — One-command deployment
# Usage:
#   ./deploy.sh android beta    # → Play Store 내부 테스트
#   ./deploy.sh android deploy  # → Play Store 프로덕션
#   ./deploy.sh ios beta        # → TestFlight
#   ./deploy.sh ios deploy      # → App Store
#   ./deploy.sh all beta        # → 양쪽 모두 베타 배포

set -e

PLATFORM=${1:-"all"}
LANE=${2:-"beta"}

echo "═══════════════════════════════════════════"
echo "🚀 Mother Father Diary Deploy"
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
  echo "🍎 iOS: Running fastlane $LANE..."
  cd ios
  pod install --repo-update
  bundle exec fastlane "$LANE"
  cd ..
  echo "✅ iOS $LANE complete!"
fi

echo ""
echo "═══════════════════════════════════════════"
echo "🎉 Deployment complete!"
echo "═══════════════════════════════════════════"
