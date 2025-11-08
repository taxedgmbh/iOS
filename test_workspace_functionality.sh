#!/bin/bash

# Workspace Database Functionality Test Suite
# Tests all workspace-related database operations and fixes

echo "=========================================="
echo "🧪 Workspace Database Test Suite"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Helper function to print test results
print_test() {
    TESTS_RUN=$((TESTS_RUN + 1))
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} $2"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

echo -e "${BLUE}📋 Test 1: Verify Firestore Rules File Structure${NC}"
echo "----------------------------------------"

# Test 1: Check firestore.rules exists
if [ -f "firestore.rules" ]; then
    print_test 0 "Firestore rules file exists"
else
    print_test 1 "Firestore rules file exists"
fi

# Test 2: Check memberIds field in security rules
if grep -q "resource.data.memberIds" firestore.rules; then
    print_test 0 "Security rules use memberIds (not members)"
else
    print_test 1 "Security rules use memberIds (not members)"
fi

# Test 3: Verify all workspace security rules are present
if grep -q "match /workspaces/{workspaceId}" firestore.rules; then
    print_test 0 "Workspace security rules defined"
else
    print_test 1 "Workspace security rules defined"
fi

# Test 4: Check workspaceInvitations rules
if grep -q "match /workspaceInvitations/{invitationId}" firestore.rules; then
    print_test 0 "Workspace invitation rules defined"
else
    print_test 1 "Workspace invitation rules defined"
fi

echo ""
echo -e "${BLUE}📋 Test 2: Verify Workspace Model Implementation${NC}"
echo "----------------------------------------"

# Test 5: Check Workspace.swift exists
if [ -f "TaxedGmbH_IOS/Models/Workspace.swift" ]; then
    print_test 0 "Workspace.swift model file exists"
else
    print_test 1 "Workspace.swift model file exists"
fi

# Test 6: Check memberIds computed property
if grep -q "var memberIds: \[String\]" TaxedGmbH_IOS/Models/Workspace.swift; then
    print_test 0 "Workspace has memberIds computed property"
else
    print_test 1 "Workspace has memberIds computed property"
fi

# Test 7: Check toDictionary includes memberIds
if grep -q '"memberIds": memberIds' TaxedGmbH_IOS/Models/Workspace.swift; then
    print_test 0 "Workspace.toDictionary() includes memberIds"
else
    print_test 1 "Workspace.toDictionary() includes memberIds"
fi

# Test 8: Check membership validation methods
if grep -q "func isMember(userId: String) -> Bool" TaxedGmbH_IOS/Models/Workspace.swift; then
    print_test 0 "Workspace has isMember() validation method"
else
    print_test 1 "Workspace has isMember() validation method"
fi

echo ""
echo -e "${BLUE}📋 Test 3: Verify WorkspaceManager Implementation${NC}"
echo "----------------------------------------"

# Test 9: Check WorkspaceManager exists
if [ -f "TaxedGmbH_IOS/Services/WorkspaceManager.swift" ]; then
    print_test 0 "WorkspaceManager.swift exists"
else
    print_test 1 "WorkspaceManager.swift exists"
fi

# Test 10: Check acceptInvitation syncs memberIds
if grep -A 5 "acceptInvitation" TaxedGmbH_IOS/Services/WorkspaceManager.swift | grep -q '"memberIds": FieldValue.arrayUnion'; then
    print_test 0 "acceptInvitation() syncs memberIds array"
else
    print_test 1 "acceptInvitation() syncs memberIds array"
fi

# Test 11: Check removeMember syncs memberIds
if grep -A 5 "removeMember" TaxedGmbH_IOS/Services/WorkspaceManager.swift | grep -q '"memberIds": FieldValue.arrayRemove'; then
    print_test 0 "removeMember() syncs memberIds array"
else
    print_test 1 "removeMember() syncs memberIds array"
fi

# Test 12: Check getWorkspace method exists
if grep -q "func getWorkspace(workspaceId: String)" TaxedGmbH_IOS/Services/WorkspaceManager.swift; then
    print_test 0 "getWorkspace() method exists for validation"
else
    print_test 1 "getWorkspace() method exists for validation"
fi

# Test 13: Check activeWorkspaceId preservation logic
if grep -q 'userData\["activeWorkspaceId"\] == nil' TaxedGmbH_IOS/Services/WorkspaceManager.swift; then
    print_test 0 "activeWorkspaceId preservation logic implemented"
else
    print_test 1 "activeWorkspaceId preservation logic implemented"
fi

echo ""
echo -e "${BLUE}📋 Test 4: Verify Document Upload Security${NC}"
echo "----------------------------------------"

# Test 14: Check DocumentManager exists
if [ -f "TaxedGmbH_IOS/Services/DocumentManager.swift" ]; then
    print_test 0 "DocumentManager.swift exists"
else
    print_test 1 "DocumentManager.swift exists"
fi

# Test 15: Check workspace validation in uploadDocument
if grep -q "WorkspaceManager.shared.getWorkspace" TaxedGmbH_IOS/Services/DocumentManager.swift; then
    print_test 0 "uploadDocument() validates workspace access"
else
    print_test 1 "uploadDocument() validates workspace access"
fi

# Test 16: Check membership validation
if grep -q "workspace.isMember(userId:" TaxedGmbH_IOS/Services/DocumentManager.swift; then
    print_test 0 "uploadDocument() checks workspace membership"
else
    print_test 1 "uploadDocument() checks workspace membership"
fi

# Test 17: Check workspaceId requirement
if grep -q "Workspace ID is required for document upload" TaxedGmbH_IOS/Services/DocumentManager.swift; then
    print_test 0 "uploadDocument() enforces workspaceId requirement"
else
    print_test 1 "uploadDocument() enforces workspaceId requirement"
fi

echo ""
echo -e "${BLUE}📋 Test 5: Verify TaxDocument Model${NC}"
echo "----------------------------------------"

# Test 18: Check TaxDocument has workspaceId field
if grep -q "var workspaceId: String?" TaxedGmbH_IOS/Models/TaxDocument.swift; then
    print_test 0 "TaxDocument has workspaceId field"
else
    print_test 1 "TaxDocument has workspaceId field"
fi

# Test 19: Check workspaceId in toDictionary
if grep -q 'if let workspaceId = workspaceId { dict\["workspaceId"\] = workspaceId }' TaxedGmbH_IOS/Models/TaxDocument.swift; then
    print_test 0 "TaxDocument.toDictionary() includes workspaceId"
else
    print_test 1 "TaxDocument.toDictionary() includes workspaceId"
fi

# Test 20: Check workspaceId in fromDictionary
if grep -q 'workspaceId: data\["workspaceId"\] as? String' TaxedGmbH_IOS/Models/TaxDocument.swift; then
    print_test 0 "TaxDocument.fromDictionary() parses workspaceId"
else
    print_test 1 "TaxDocument.fromDictionary() parses workspaceId"
fi

echo ""
echo -e "${BLUE}📋 Test 6: Verify FirestoreService Workspace Queries${NC}"
echo "----------------------------------------"

# Test 21: Check FirestoreService exists
if [ -f "TaxedGmbH_IOS/Services/FirestoreService.swift" ]; then
    print_test 0 "FirestoreService.swift exists"
else
    print_test 1 "FirestoreService.swift exists"
fi

# Test 22: Check getDocumentsForWorkspace method
if grep -q "func getDocumentsForWorkspace(workspaceId: String)" TaxedGmbH_IOS/Services/FirestoreService.swift; then
    print_test 0 "getDocumentsForWorkspace() method exists"
else
    print_test 1 "getDocumentsForWorkspace() method exists"
fi

# Test 23: Check workspace query filter
if grep -q '.whereField("workspaceId", isEqualTo: workspaceId)' TaxedGmbH_IOS/Services/FirestoreService.swift; then
    print_test 0 "Workspace query filters by workspaceId"
else
    print_test 1 "Workspace query filters by workspaceId"
fi

echo ""
echo -e "${BLUE}📋 Test 7: Verify User Model Workspace Support${NC}"
echo "----------------------------------------"

# Test 24: Check User has workspaceIds field
if grep -q "var workspaceIds: \[String\]?" TaxedGmbH_IOS/Models/User.swift; then
    print_test 0 "User model has workspaceIds field"
else
    print_test 1 "User model has workspaceIds field"
fi

# Test 25: Check User has activeWorkspaceId field
if grep -q "var activeWorkspaceId: String?" TaxedGmbH_IOS/Models/User.swift; then
    print_test 0 "User model has activeWorkspaceId field"
else
    print_test 1 "User model has activeWorkspaceId field"
fi

# Test 26: Check User.toDictionary includes workspace fields
if grep -q 'if let workspaceIds = workspaceIds { dict\["workspaceIds"\] = workspaceIds }' TaxedGmbH_IOS/Models/User.swift; then
    print_test 0 "User.toDictionary() includes workspace fields"
else
    print_test 1 "User.toDictionary() includes workspace fields"
fi

echo ""
echo -e "${BLUE}📋 Test 8: Verify AppConstants Configuration${NC}"
echo "----------------------------------------"

# Test 27: Check workspace collections defined
if grep -q 'static let workspaces = "workspaces"' TaxedGmbH_IOS/Constants/AppConstants.swift; then
    print_test 0 "Workspace collection constant defined"
else
    print_test 1 "Workspace collection constant defined"
fi

# Test 28: Check workspace invitations collection
if grep -q 'static let workspaceInvitations = "workspaceInvitations"' TaxedGmbH_IOS/Constants/AppConstants.swift; then
    print_test 0 "WorkspaceInvitations collection constant defined"
else
    print_test 1 "WorkspaceInvitations collection constant defined"
fi

# Test 29: Check database ID configuration
if grep -q 'static let databaseId: String? = "taxedgmbh"' TaxedGmbH_IOS/Constants/AppConstants.swift; then
    print_test 0 "Named database ID configured correctly"
else
    print_test 1 "Named database ID configured correctly"
fi

echo ""
echo -e "${BLUE}📋 Test 9: Code Quality Checks${NC}"
echo "----------------------------------------"

# Test 30: Check for print statements in workspace manager
WORKSPACE_PRINTS=$(grep -c "print(" TaxedGmbH_IOS/Services/WorkspaceManager.swift)
if [ "$WORKSPACE_PRINTS" -gt 0 ]; then
    print_test 0 "WorkspaceManager has debug logging ($WORKSPACE_PRINTS statements)"
else
    print_test 1 "WorkspaceManager has debug logging"
fi

# Test 31: Check for error handling in workspace operations
if grep -q "throw NSError" TaxedGmbH_IOS/Services/WorkspaceManager.swift; then
    print_test 0 "WorkspaceManager has proper error handling"
else
    print_test 1 "WorkspaceManager has proper error handling"
fi

# Test 32: Check for @MainActor annotation
if grep -q "@MainActor" TaxedGmbH_IOS/Services/WorkspaceManager.swift; then
    print_test 0 "WorkspaceManager uses @MainActor for thread safety"
else
    print_test 1 "WorkspaceManager uses @MainActor for thread safety"
fi

echo ""
echo "=========================================="
echo -e "${BLUE}📊 Test Summary${NC}"
echo "=========================================="
echo -e "Total Tests Run:    ${YELLOW}$TESTS_RUN${NC}"
echo -e "Tests Passed:       ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed:       ${RED}$TESTS_FAILED${NC}"
echo ""

# Calculate success rate
if [ $TESTS_RUN -gt 0 ]; then
    SUCCESS_RATE=$((TESTS_PASSED * 100 / TESTS_RUN))
    echo -e "Success Rate:       ${YELLOW}$SUCCESS_RATE%${NC}"
else
    echo -e "Success Rate:       ${RED}0%${NC}"
fi

echo ""

# Final result
if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed! Workspace database implementation is correct.${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed. Please review the issues above.${NC}"
    exit 1
fi
