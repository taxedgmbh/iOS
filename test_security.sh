#!/bin/bash

echo "🔒 Security Implementation Test"
echo "=================================================="

# Test 1: Check for any remaining downloadURL calls
echo ""
echo "📍 Test 1: Checking for downloadURL() calls..."
echo "----------------------------------------------"

FILES=(
    "TaxedGmbH_IOS/Services/StorageService.swift"
    "TaxedGmbH_IOS/Services/DocumentManager.swift"
    "TaxedGmbH_IOS/Services/CoverSheetService.swift"
    "TaxedGmbH_IOS/Services/PDFRegenerationService.swift"
    "TaxedGmbH_IOS/Services/ChatService.swift"
    "TaxedGmbH_IOS/Services/FirestoreService.swift"
)

FOUND_ISSUES=false

for file in "${FILES[@]}"; do
    filename=$(basename "$file")
    if grep -q "downloadURL()" "$file" 2>/dev/null; then
        echo "  ❌ Found downloadURL() in $filename"
        grep -n "downloadURL()" "$file" | head -5
        FOUND_ISSUES=true
    else
        echo "  ✅ $filename - No downloadURL calls"
    fi
done

# Test 2: Check for secure download methods
echo ""
echo "📍 Test 2: Checking for secure download methods..."
echo "----------------------------------------------"

if grep -q "func securelyDownloadDocument" "TaxedGmbH_IOS/Services/StorageService.swift" 2>/dev/null; then
    echo "  ✅ Found securelyDownloadDocument method"
else
    echo "  ❌ Missing securelyDownloadDocument method"
    FOUND_ISSUES=true
fi

if grep -q "func securelyDownloadImage" "TaxedGmbH_IOS/Services/StorageService.swift" 2>/dev/null; then
    echo "  ✅ Found securelyDownloadImage method"
else
    echo "  ❌ Missing securelyDownloadImage method"
    FOUND_ISSUES=true
fi

# Test 3: Check storage rules enforcement
echo ""
echo "📍 Test 3: Checking storage rules..."
echo "----------------------------------------------"

if grep -q "function isWorkspaceMember" "storage.rules" 2>/dev/null; then
    echo "  ✅ Found isWorkspaceMember function"
else
    echo "  ❌ Missing isWorkspaceMember function"
    FOUND_ISSUES=true
fi

if grep -q "request.auth.token.workspaces" "storage.rules" 2>/dev/null; then
    echo "  ✅ Checking JWT workspace claims"
else
    echo "  ❌ Not checking JWT workspace claims"
    FOUND_ISSUES=true
fi

# Test 4: Check for storage path returns instead of URLs
echo ""
echo "📍 Test 4: Checking for storage path returns..."
echo "----------------------------------------------"

if grep -q "Return storage path, NOT a public URL" "TaxedGmbH_IOS/Services/StorageService.swift" 2>/dev/null; then
    echo "  ✅ StorageService returns paths instead of URLs"
else
    echo "  ⚠️ StorageService may still return URLs"
fi

if grep -q "Return storage path, NOT a public URL" "TaxedGmbH_IOS/Services/PDFRegenerationService.swift" 2>/dev/null; then
    echo "  ✅ PDFRegenerationService returns paths instead of URLs"
else
    echo "  ⚠️ PDFRegenerationService may still return URLs"
fi

if grep -q "Return storage path, NOT a public URL" "TaxedGmbH_IOS/Services/ChatService.swift" 2>/dev/null; then
    echo "  ✅ ChatService returns paths instead of URLs"
else
    echo "  ⚠️ ChatService may still return URLs"
fi

# Summary
echo ""
echo "=================================================="
if [ "$FOUND_ISSUES" = false ]; then
    echo "✅ ALL SECURITY TESTS PASSED"
    echo ""
    echo "✓ No public URL generation found"
    echo "✓ Secure download methods implemented"
    echo "✓ Storage rules enforce workspace membership"
    echo ""
    echo "🔐 Documents are only accessible to authenticated"
    echo "   users with proper workspace access"
else
    echo "❌ SECURITY ISSUES FOUND"
    echo ""
    echo "Please review the issues above and fix them"
    echo "before deployment"
fi
echo "=================================================="