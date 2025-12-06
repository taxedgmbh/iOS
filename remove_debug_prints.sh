#!/bin/bash

# Script to remove debug print statements from Swift files
echo "🧹 Removing debug print statements from Swift files..."

# Files with debug prints that need cleaning
files=(
    "TaxedGmbH_IOS/Services/AuthenticationService.swift"
    "TaxedGmbH_IOS/Services/WorkspaceManager.swift"
    "TaxedGmbH_IOS/Services/ClaimsService.swift"
    "TaxedGmbH_IOS/Services/TaxFormFieldService.swift"
    "TaxedGmbH_IOS/Services/PDFRegenerationService.swift"
    "TaxedGmbH_IOS/Views/Documents/DocumentUploadView.swift"
)

# Remove lines containing debug print statements
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "Processing $file..."

        # Create backup
        cp "$file" "$file.backup"

        # Remove lines with debug prints (🔍 prefix)
        sed -i '' '/print("🔍/d' "$file"

        # Remove authentication debug block
        sed -i '' '/print("🔍 ========== USER AUTHENTICATION DEBUG =========="/,/print("=================================================")/d' "$file"

        # Remove workspace debug block
        sed -i '' '/print("🔍 =============== WORKSPACE LOADING DEBUG ==============="/,/print("===============================================")/d' "$file"

        # Remove other debug prints
        sed -i '' '/print("✅ User data loaded successfully from Firestore Enterprise:/d' "$file"
        sed -i '' '/print("   Firebase Auth UID:/d' "$file"
        sed -i '' '/print("   User Model ID:/d' "$file"
        sed -i '' '/print("   Email:/d' "$file"
        sed -i '' '/print("   Name:/d' "$file"
        sed -i '' '/print("   IDs Match:/d' "$file"
        sed -i '' '/print("   ⚠️ WARNING: Firebase Auth UID does not match User.id!")/d' "$file"
        sed -i '' '/print("   This will cause permission errors in Firebase Storage!")/d' "$file"
        sed -i '' '/print("🔐 Workspace claims updated on login/d' "$file"
        sed -i '' '/print("⚠️ Failed to update workspace claims:/d' "$file"

        echo "✅ Cleaned $file"
    fi
done

echo "🎉 Debug print statements removed successfully!"
echo "Note: Backup files created with .backup extension"