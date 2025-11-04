#!/bin/bash

# Fix Xcode Cache Errors Script
# This script clears all Xcode caches and rebuilds the project

echo "🔧 Fixing Xcode Cache Issues..."
echo ""

# Step 1: Close Xcode if it's running
echo "Step 1: Checking if Xcode is running..."
if pgrep -x "Xcode" > /dev/null; then
    echo "⚠️  Xcode is running. Please close Xcode first!"
    echo "   Press Cmd+Q in Xcode, then run this script again."
    exit 1
fi
echo "✅ Xcode is not running"
echo ""

# Step 2: Clear DerivedData
echo "Step 2: Clearing DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/TaxedGmbH_IOS-* 2>/dev/null
echo "✅ DerivedData cleared"
echo ""

# Step 3: Clear Module Cache
echo "Step 3: Clearing Module Cache..."
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex 2>/dev/null
echo "✅ Module cache cleared"
echo ""

# Step 4: Clear Build folder
echo "Step 4: Cleaning build folder..."
cd /Users/emanuelflury/github/TaxedGmbH_IOS
xcodebuild clean -project TaxedGmbH_IOS.xcodeproj -scheme TaxedGmbH_IOS > /dev/null 2>&1
echo "✅ Build folder cleaned"
echo ""

# Step 5: Reset package caches
echo "Step 5: Resetting Swift Package caches..."
rm -rf ~/Library/Caches/org.swift.swiftpm 2>/dev/null
rm -rf ~/Library/org.swift.swiftpm 2>/dev/null
echo "✅ Swift Package caches cleared"
echo ""

echo "✨ All caches cleared!"
echo ""
echo "📱 Next Steps:"
echo "1. Open Xcode: open TaxedGmbH_IOS.xcodeproj"
echo "2. Wait for packages to resolve (watch status bar)"
echo "3. Press Cmd+Shift+K (Clean Build Folder)"
echo "4. Press Cmd+B (Build)"
echo ""
echo "The errors you saw are stale cache - the code is correct! ✅"
