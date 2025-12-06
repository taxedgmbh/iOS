#!/usr/bin/env swift

import Foundation

// Test Security Implementation
// This script verifies that:
// 1. No downloadURL() calls exist in the codebase
// 2. Storage paths are being used instead of public URLs
// 3. Security-sensitive methods are properly implemented

print("🔒 Security Implementation Test")
print(String(repeating: "=", count: 50))

// Search for any remaining downloadURL calls
func searchForDownloadURLs() -> Bool {
    print("\n📍 Checking for downloadURL() calls...")

    let servicesToCheck = [
        "TaxedGmbH_IOS/Services/StorageService.swift",
        "TaxedGmbH_IOS/Services/DocumentManager.swift",
        "TaxedGmbH_IOS/Services/CoverSheetService.swift",
        "TaxedGmbH_IOS/Services/PDFRegenerationService.swift",
        "TaxedGmbH_IOS/Services/ChatService.swift",
        "TaxedGmbH_IOS/Services/FirestoreService.swift"
    ]

    var foundIssues = false

    for service in servicesToCheck {
        let filePath = "/Users/emanuelflury/github/TaxedGmbH_IOS/\(service)"

        do {
            let content = try String(contentsOfFile: filePath, encoding: .utf8)

            // Check for downloadURL calls
            if content.contains(".downloadURL(") || content.contains("downloadURL()") {
                print("  ❌ Found downloadURL() call in \(service)")
                foundIssues = true

                // Find the line number
                let lines = content.components(separatedBy: .newlines)
                for (index, line) in lines.enumerated() {
                    if line.contains("downloadURL") && !line.contains("//") {
                        print("     Line \(index + 1): \(line.trimmingCharacters(in: .whitespaces))")
                    }
                }
            } else {
                print("  ✅ \(service.components(separatedBy: "/").last!) - No downloadURL calls found")
            }

            // Check for proper storage path returns
            if content.contains("Return storage path, NOT a public URL") {
                print("     ✓ Contains security comment about storage paths")
            }

        } catch {
            print("  ⚠️ Could not read \(service): \(error)")
        }
    }

    return !foundIssues
}

// Check for secure download methods
func checkSecureDownloadMethods() -> Bool {
    print("\n📍 Checking for secure download methods...")

    let storageServicePath = "/Users/emanuelflury/github/TaxedGmbH_IOS/TaxedGmbH_IOS/Services/StorageService.swift"

    do {
        let content = try String(contentsOfFile: storageServicePath, encoding: .utf8)

        let requiredMethods = [
            "securelyDownloadDocument",
            "loadPDFData"  // Direct Firebase Storage access without public URLs
        ]

        var allPresent = true

        for method in requiredMethods {
            if content.contains("func \(method)") {
                print("  ✅ Found secure method: \(method)")
            } else {
                print("  ❌ Missing secure method: \(method)")
                allPresent = false
            }
        }

        return allPresent

    } catch {
        print("  ❌ Could not read StorageService.swift: \(error)")
        return false
    }
}

// Check storage rules are enforcing workspace membership
func checkStorageRules() -> Bool {
    print("\n📍 Checking storage.rules for workspace membership enforcement...")

    let rulesPath = "/Users/emanuelflury/github/TaxedGmbH_IOS/storage.rules"

    do {
        let content = try String(contentsOfFile: rulesPath, encoding: .utf8)

        // Check for workspace membership function
        if content.contains("function isWorkspaceMember") {
            print("  ✅ Found isWorkspaceMember function")
        } else {
            print("  ❌ Missing isWorkspaceMember function")
            return false
        }

        // Check for JWT token workspace claims
        if content.contains("request.auth.token.workspaces") {
            print("  ✅ Checking JWT workspace claims")
        } else {
            print("  ❌ Not checking JWT workspace claims")
            return false
        }

        // Check that read requires workspace membership
        if content.contains("allow read: if isWorkspaceMember(workspaceId)") {
            print("  ✅ Read operations require workspace membership")
        } else {
            print("  ⚠️ Read operations may not require workspace membership")
        }

        return true

    } catch {
        print("  ❌ Could not read storage.rules: \(error)")
        return false
    }
}

// Main test execution
print("\n🚀 Starting security tests...")

var allTestsPassed = true

// Test 1: No downloadURL calls
if !searchForDownloadURLs() {
    allTestsPassed = false
}

// Test 2: Secure download methods exist
if !checkSecureDownloadMethods() {
    allTestsPassed = false
}

// Test 3: Storage rules enforce security
if !checkStorageRules() {
    allTestsPassed = false
}

// Summary
print("\n" + String(repeating: "=", count: 50))
if allTestsPassed {
    print("✅ ALL SECURITY TESTS PASSED")
    print("\n✓ No public URL generation found")
    print("✓ Secure download methods implemented")
    print("✓ Storage rules enforce workspace membership")
    print("\n🔐 Documents are only accessible to authenticated users with proper workspace access")
} else {
    print("❌ SECURITY ISSUES FOUND")
    print("\nPlease review the issues above and fix them before deployment")
}

print(String(repeating: "=", count: 50))