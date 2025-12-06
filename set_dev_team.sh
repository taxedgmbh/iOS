#!/bin/bash

# Script to set development team for TaxedGmbH_IOS project

PROJECT_FILE="TaxedGmbH_IOS.xcodeproj/project.pbxproj"

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "This script must be run on macOS"
    exit 1
fi

echo "🔧 Setting up development team for TaxedGmbH_IOS..."

# Get the user's Apple ID team (Personal Team)
# This uses the first available team from the system
TEAM_ID=$(security find-identity -v -p codesigning | grep "Apple Development" | head -1 | awk '{print $2}' | cut -d'"' -f1)

if [ -z "$TEAM_ID" ]; then
    echo "⚠️  No development team found. Please:"
    echo "1. Open Xcode"
    echo "2. Go to Xcode > Preferences > Accounts"
    echo "3. Add your Apple ID if not already added"
    echo "4. Download manual profiles if needed"
    exit 1
fi

echo "✅ Found development team: $TEAM_ID"

# Backup the project file
cp "$PROJECT_FILE" "$PROJECT_FILE.backup"
echo "📁 Created backup: $PROJECT_FILE.backup"

# Add development team to the project file
# This is a simplified approach - for production use Xcode
sed -i '' "s/CODE_SIGN_STYLE = Automatic;/CODE_SIGN_STYLE = Automatic;\n\t\t\t\tDEVELOPMENT_TEAM = $TEAM_ID;/" "$PROJECT_FILE"

echo "✅ Development team added to project"
echo ""
echo "Next steps:"
echo "1. Open the project in Xcode"
echo "2. Build and run the project"
echo ""
echo "If you encounter issues, restore from backup:"
echo "  mv $PROJECT_FILE.backup $PROJECT_FILE"