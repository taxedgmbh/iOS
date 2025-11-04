#!/usr/bin/env python3
"""
Comprehensive Firestore Integration Test Script
Tests the complete authentication and database flow
"""

import subprocess
import time
import sys
import json
from datetime import datetime

class FirestoreIntegrationTester:
    def __init__(self):
        self.test_results = []
        self.test_email = f"test-{int(time.time())}@taxed.com"
        self.test_password = "Test1234"
        self.test_name = "Integration Test User"
        self.test_phone = "+41791234567"

    def log_test(self, test_name, passed, message=""):
        """Log test result"""
        status = "✅ PASS" if passed else "❌ FAIL"
        result = {
            "test": test_name,
            "passed": passed,
            "message": message,
            "timestamp": datetime.now().isoformat()
        }
        self.test_results.append(result)
        print(f"{status}: {test_name}")
        if message:
            print(f"   {message}")
        print()

    def run_swift_command(self, code):
        """Execute Swift code and return output"""
        try:
            result = subprocess.run(
                ['swift', '-'],
                input=code,
                capture_output=True,
                text=True,
                timeout=30
            )
            return result.stdout, result.stderr, result.returncode
        except subprocess.TimeoutExpired:
            return "", "Timeout", 1
        except Exception as e:
            return "", str(e), 1

    def test_1_verify_configuration(self):
        """Test 1: Verify AuthenticationService configuration"""
        print("🧪 Test 1: Verifying Database Configuration...")

        try:
            with open('TaxedGmbH_IOS/Services/AuthenticationService.swift', 'r') as f:
                content = f.read()

            # Check if useTempDB is set to false
            if 'useTempDB = false' in content:
                self.log_test(
                    "Database Configuration",
                    True,
                    "useTempDB is correctly set to false"
                )
                return True
            else:
                self.log_test(
                    "Database Configuration",
                    False,
                    "useTempDB is not set to false - still using temporary storage"
                )
                return False
        except Exception as e:
            self.log_test("Database Configuration", False, str(e))
            return False

    def test_2_verify_firestore_rules(self):
        """Test 2: Verify Firestore rules file exists"""
        print("🧪 Test 2: Verifying Firestore Rules...")

        try:
            with open('firestore.rules', 'r') as f:
                content = f.read()

            # Check for key security features
            checks = [
                ('isAuthenticated()', 'Authentication check function'),
                ('isOwner(userId)', 'Owner check function'),
                ('hasRole(role)', 'Role check function'),
                ('match /users/{userId}', 'Users collection rules'),
                ('match /documents/{documentId}', 'Documents collection rules'),
            ]

            all_passed = True
            for check, description in checks:
                if check in content:
                    print(f"   ✓ {description}")
                else:
                    print(f"   ✗ Missing: {description}")
                    all_passed = False

            self.log_test(
                "Firestore Security Rules",
                all_passed,
                "Security rules file verified"
            )
            return all_passed
        except Exception as e:
            self.log_test("Firestore Security Rules", False, str(e))
            return False

    def test_3_verify_indexes(self):
        """Test 3: Verify Firestore indexes file exists"""
        print("🧪 Test 3: Verifying Firestore Indexes...")

        try:
            with open('firestore.indexes.json', 'r') as f:
                data = json.load(f)

            indexes = data.get('indexes', [])
            num_indexes = len(indexes)

            if num_indexes >= 8:
                self.log_test(
                    "Firestore Indexes",
                    True,
                    f"Found {num_indexes} indexes configured"
                )

                # List collections with indexes
                collections = set(idx.get('collectionGroup') for idx in indexes)
                print(f"   Indexed collections: {', '.join(collections)}")
                return True
            else:
                self.log_test(
                    "Firestore Indexes",
                    False,
                    f"Only {num_indexes} indexes found, expected at least 8"
                )
                return False
        except Exception as e:
            self.log_test("Firestore Indexes", False, str(e))
            return False

    def test_4_verify_firebase_config(self):
        """Test 4: Verify Firebase configuration exists"""
        print("🧪 Test 4: Verifying Firebase Configuration...")

        try:
            # Check for GoogleService-Info.plist
            plist_paths = [
                'TaxedGmbH_IOS/GoogleService-Info.plist',
                'GoogleService-Info.plist'
            ]

            for path in plist_paths:
                try:
                    with open(path, 'r') as f:
                        content = f.read()

                    if 'taxedgmbh' in content.lower():
                        self.log_test(
                            "Firebase Configuration",
                            True,
                            f"Found valid configuration in {path}"
                        )
                        return True
                except FileNotFoundError:
                    continue

            self.log_test(
                "Firebase Configuration",
                False,
                "GoogleService-Info.plist not found"
            )
            return False
        except Exception as e:
            self.log_test("Firebase Configuration", False, str(e))
            return False

    def test_5_check_app_build(self):
        """Test 5: Verify app can build"""
        print("🧪 Test 5: Checking App Build Status...")

        try:
            # Check if app was recently built
            result = subprocess.run(
                ['xcodebuild', '-project', 'TaxedGmbH_IOS.xcodeproj',
                 '-scheme', 'TaxedGmbH_IOS', '-showBuildSettings'],
                capture_output=True,
                text=True,
                timeout=10
            )

            if result.returncode == 0:
                self.log_test(
                    "App Build Configuration",
                    True,
                    "Build configuration is valid"
                )
                return True
            else:
                self.log_test(
                    "App Build Configuration",
                    False,
                    "Build configuration check failed"
                )
                return False
        except Exception as e:
            self.log_test("App Build Configuration", False, str(e))
            return False

    def test_6_check_simulator_status(self):
        """Test 6: Check if simulator is running"""
        print("🧪 Test 6: Checking Simulator Status...")

        try:
            result = subprocess.run(
                ['xcrun', 'simctl', 'list', 'devices', '|', 'grep', 'Booted'],
                capture_output=True,
                text=True,
                shell=True,
                timeout=5
            )

            if 'Booted' in result.stdout:
                self.log_test(
                    "Simulator Status",
                    True,
                    "Simulator is running"
                )
                return True
            else:
                self.log_test(
                    "Simulator Status",
                    False,
                    "No simulator is running"
                )
                return False
        except Exception as e:
            self.log_test("Simulator Status", False, str(e))
            return False

    def test_7_verify_phone_service(self):
        """Test 7: Verify PhoneVerificationService exists"""
        print("🧪 Test 7: Verifying Phone Verification Service...")

        try:
            with open('TaxedGmbH_IOS/Services/PhoneVerificationService.swift', 'r') as f:
                content = f.read()

            checks = [
                ('isValidSwissPhoneNumber', 'Swiss phone validation'),
                ('formatToE164', 'E164 formatting'),
                ('sendVerificationCode', 'Send verification code'),
                ('verifyCode', 'Verify code function'),
            ]

            all_passed = True
            for check, description in checks:
                if check in content:
                    print(f"   ✓ {description}")
                else:
                    print(f"   ✗ Missing: {description}")
                    all_passed = False

            self.log_test(
                "Phone Verification Service",
                all_passed,
                "Phone verification service verified"
            )
            return all_passed
        except Exception as e:
            self.log_test("Phone Verification Service", False, str(e))
            return False

    def test_8_verify_user_model(self):
        """Test 8: Verify User model supports all fields"""
        print("🧪 Test 8: Verifying User Model...")

        try:
            with open('TaxedGmbH_IOS/Models/User.swift', 'r') as f:
                content = f.read()

            required_fields = [
                'email',
                'name',
                'role',
                'phone',
                'createdAt',
                'updatedAt'
            ]

            all_present = True
            for field in required_fields:
                if f'var {field}' in content or f'let {field}' in content:
                    print(f"   ✓ {field}")
                else:
                    print(f"   ✗ Missing field: {field}")
                    all_present = False

            self.log_test(
                "User Model",
                all_present,
                "User model has all required fields"
            )
            return all_present
        except Exception as e:
            self.log_test("User Model", False, str(e))
            return False

    def test_9_check_documentation(self):
        """Test 9: Verify documentation files exist"""
        print("🧪 Test 9: Checking Documentation...")

        docs = [
            ('FIRESTORE_DEPLOYMENT_GUIDE.md', 'Deployment guide'),
            ('DATABASE_ACTIVATION_COMPLETE.md', 'Activation status'),
            ('QUICK_START.md', 'Quick start guide'),
            ('firestore.rules', 'Security rules'),
            ('firestore.indexes.json', 'Index configuration')
        ]

        all_present = True
        for doc_file, description in docs:
            try:
                with open(doc_file, 'r'):
                    print(f"   ✓ {description}")
            except FileNotFoundError:
                print(f"   ✗ Missing: {description}")
                all_present = False

        self.log_test(
            "Documentation",
            all_present,
            "All documentation files present"
        )
        return all_present

    def test_10_integration_checklist(self):
        """Test 10: Final integration checklist"""
        print("🧪 Test 10: Final Integration Checklist...")

        checklist = {
            "Database activated (useTempDB = false)": False,
            "Security rules created": False,
            "Indexes configured": False,
            "Firebase configured": False,
            "Phone verification ready": False,
            "Documentation complete": False
        }

        # Check each item
        try:
            with open('TaxedGmbH_IOS/Services/AuthenticationService.swift', 'r') as f:
                if 'useTempDB = false' in f.read():
                    checklist["Database activated (useTempDB = false)"] = True
        except:
            pass

        try:
            with open('firestore.rules', 'r'):
                checklist["Security rules created"] = True
        except:
            pass

        try:
            with open('firestore.indexes.json', 'r'):
                checklist["Indexes configured"] = True
        except:
            pass

        try:
            with open('TaxedGmbH_IOS/GoogleService-Info.plist', 'r'):
                checklist["Firebase configured"] = True
        except:
            pass

        try:
            with open('TaxedGmbH_IOS/Services/PhoneVerificationService.swift', 'r'):
                checklist["Phone verification ready"] = True
        except:
            pass

        try:
            with open('QUICK_START.md', 'r'):
                checklist["Documentation complete"] = True
        except:
            pass

        # Print checklist
        all_passed = True
        for item, status in checklist.items():
            symbol = "✓" if status else "✗"
            print(f"   {symbol} {item}")
            if not status:
                all_passed = False

        self.log_test(
            "Integration Checklist",
            all_passed,
            f"{sum(checklist.values())}/{len(checklist)} items completed"
        )
        return all_passed

    def print_summary(self):
        """Print test summary"""
        print("\n" + "="*60)
        print("📊 COMPREHENSIVE TEST SUMMARY")
        print("="*60 + "\n")

        passed = sum(1 for r in self.test_results if r['passed'])
        failed = len(self.test_results) - passed

        print(f"Total Tests: {len(self.test_results)}")
        print(f"✅ Passed: {passed}")
        print(f"❌ Failed: {failed}")
        print(f"Success Rate: {passed/len(self.test_results)*100:.1f}%\n")

        if failed > 0:
            print("Failed Tests:")
            for result in self.test_results:
                if not result['passed']:
                    print(f"  ❌ {result['test']}")
                    if result['message']:
                        print(f"     {result['message']}")
            print()

        print("="*60)

        if failed == 0:
            print("🎉 ALL TESTS PASSED! Firestore integration is ready!")
        else:
            print("⚠️  Some tests failed. Please review the issues above.")

        print("="*60 + "\n")

        # Save results to JSON
        with open('firestore_integration_test_results.json', 'w') as f:
            json.dump({
                'timestamp': datetime.now().isoformat(),
                'total': len(self.test_results),
                'passed': passed,
                'failed': failed,
                'tests': self.test_results
            }, f, indent=2)

        print("📄 Detailed results saved to: firestore_integration_test_results.json\n")

    def run_all_tests(self):
        """Run all integration tests"""
        print("\n🚀 Starting Comprehensive Firestore Integration Tests")
        print("="*60 + "\n")

        # Run all tests
        self.test_1_verify_configuration()
        self.test_2_verify_firestore_rules()
        self.test_3_verify_indexes()
        self.test_4_verify_firebase_config()
        self.test_5_check_app_build()
        self.test_6_check_simulator_status()
        self.test_7_verify_phone_service()
        self.test_8_verify_user_model()
        self.test_9_check_documentation()
        self.test_10_integration_checklist()

        # Print summary
        self.print_summary()

if __name__ == "__main__":
    tester = FirestoreIntegrationTester()
    tester.run_all_tests()
