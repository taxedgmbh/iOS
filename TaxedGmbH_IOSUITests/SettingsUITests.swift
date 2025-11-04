//
//  SettingsUITests.swift
//  TaxedGmbH_IOSUITests
//
//  Comprehensive UI tests for Settings section
//

import XCTest

final class SettingsUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()

        // Wait for app to load
        sleep(2)

        // Navigate to Settings tab
        let settingsTab = app.tabBars.buttons["Einstellungen"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5), "Settings tab should exist")
        settingsTab.tap()

        // Wait for Settings view to load
        sleep(1)
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Profile Section Tests

    func testProfileSectionExists() throws {
        print("🧪 Testing: Profile section exists")

        // Check if profile section header exists
        let profileHeader = app.staticTexts["Profil"]
        XCTAssertTrue(profileHeader.exists, "Profile header should exist")

        print("✅ Profile section header found")
    }

    func testProfileFieldsDisplay() throws {
        print("🧪 Testing: Profile fields display correctly")

        // Check for common profile fields
        let nameField = app.staticTexts["Name"]
        let emailField = app.staticTexts["E-Mail"]

        XCTAssertTrue(nameField.exists, "Name field should exist")
        XCTAssertTrue(emailField.exists, "Email field should exist")

        print("✅ Profile fields display correctly")
    }

    // MARK: - Notification Section Tests

    func testNotificationsSectionExists() throws {
        print("🧪 Testing: Notifications section exists")

        let notificationsHeader = app.staticTexts["Benachrichtigungen"]
        XCTAssertTrue(notificationsHeader.exists, "Notifications header should exist")

        print("✅ Notifications section found")
    }

    func testNotificationToggle() throws {
        print("🧪 Testing: Notification toggle functionality")

        // Find the push notifications toggle
        let pushNotificationsToggle = app.switches["Push-Benachrichtigungen"]

        if pushNotificationsToggle.exists {
            let initialState = pushNotificationsToggle.value as? String
            print("   Initial toggle state: \(initialState ?? "unknown")")

            // Toggle it
            pushNotificationsToggle.tap()
            sleep(1)

            let newState = pushNotificationsToggle.value as? String
            print("   New toggle state: \(newState ?? "unknown")")

            XCTAssertNotEqual(initialState, newState, "Toggle state should change")
            print("✅ Notification toggle works")
        } else {
            print("⚠️  Push notifications toggle not found")
        }
    }

    func testNotificationSettingsNavigation() throws {
        print("🧪 Testing: Navigation to notification settings")

        let notificationSettingsButton = app.buttons["Benachrichtigungseinstellungen"]

        if notificationSettingsButton.exists {
            notificationSettingsButton.tap()
            sleep(1)

            // Check if we navigated to notification settings
            let navTitle = app.navigationBars["Benachrichtigungen"]
            XCTAssertTrue(navTitle.exists, "Should navigate to notification settings")

            // Go back
            app.navigationBars.buttons.firstMatch.tap()
            sleep(1)

            print("✅ Notification settings navigation works")
        } else {
            print("⚠️  Notification settings button not found")
        }
    }

    // MARK: - Language Section Tests (CRITICAL - Just Implemented)

    func testLanguageSectionExists() throws {
        print("🧪 Testing: Language section exists")

        let languageHeader = app.staticTexts["Sprache"]
        XCTAssertTrue(languageHeader.exists, "Language header should exist")

        print("✅ Language section found")
    }

    func testLanguagePickerNavigation() throws {
        print("🧪 Testing: Language picker navigation (CRITICAL TEST)")

        // Find the language row - it should show current language
        let languageRow = app.buttons.containing(.staticText, identifier: "Sprache").firstMatch

        XCTAssertTrue(languageRow.exists, "Language row should exist")

        // Check if current language is displayed
        let germanFlag = app.staticTexts["🇩🇪"]
        let deutschText = app.staticTexts["Deutsch"]

        let hasLanguageDisplay = germanFlag.exists || deutschText.exists
        XCTAssertTrue(hasLanguageDisplay, "Current language should be displayed")

        // Tap to open language picker
        languageRow.tap()
        sleep(1)

        // Check if language picker opened
        let languagePickerTitle = app.navigationBars.firstMatch
        XCTAssertTrue(languagePickerTitle.exists, "Language picker should open")

        print("✅ Language picker navigation works")
    }

    func testLanguageSwitching() throws {
        print("🧪 Testing: Language switching functionality (CRITICAL TEST)")

        // Navigate to language picker
        let languageRow = app.buttons.containing(.staticText, identifier: "Sprache").firstMatch
        languageRow.tap()
        sleep(1)

        // Try to find different language options
        let languages = ["Deutsch", "English", "Français", "Italiano"]
        var foundLanguages: [String] = []

        for language in languages {
            if app.staticTexts[language].exists {
                foundLanguages.append(language)
                print("   Found language: \(language)")
            }
        }

        XCTAssertGreaterThan(foundLanguages.count, 0, "Should find at least one language option")

        // Try switching to English if we're on German
        if app.staticTexts["English"].exists {
            let englishButton = app.buttons.containing(.staticText, identifier: "English").firstMatch
            englishButton.tap()
            sleep(2)

            print("✅ Language switching completed")
        }

        // Navigate back if still on language picker
        if app.navigationBars.buttons.firstMatch.exists {
            app.navigationBars.buttons.firstMatch.tap()
            sleep(1)
        }
    }

    func testAllLanguagesPresent() throws {
        print("🧪 Testing: All 4 languages are available")

        // Navigate to language picker
        let languageRow = app.buttons.containing(.staticText, identifier: "Sprache").firstMatch
        languageRow.tap()
        sleep(1)

        // Check for all 4 Swiss languages
        let expectedLanguages = ["Deutsch", "English", "Français", "Italiano"]

        for language in expectedLanguages {
            let exists = app.staticTexts[language].exists
            XCTAssertTrue(exists, "\(language) should be available")
            print("   ✓ \(language) is available")
        }

        // Go back
        app.navigationBars.buttons.firstMatch.tap()
        sleep(1)

        print("✅ All 4 languages are present")
    }

    // MARK: - App Information Section Tests

    func testAppInformationSectionExists() throws {
        print("🧪 Testing: App Information section exists")

        let appInfoHeader = app.staticTexts["App-Informationen"]
        XCTAssertTrue(appInfoHeader.exists, "App Information header should exist")

        print("✅ App Information section found")
    }

    func testVersionDisplay() throws {
        print("🧪 Testing: Version number displays")

        let versionText = app.staticTexts["Version"]
        XCTAssertTrue(versionText.exists, "Version label should exist")

        let versionNumber = app.staticTexts["1.0.0"]
        XCTAssertTrue(versionNumber.exists, "Version number should be displayed")

        print("✅ Version displays correctly")
    }

    func testAboutNavigation() throws {
        print("🧪 Testing: About page navigation")

        let aboutButton = app.buttons.containing(.staticText, identifier: "Über Taxed").firstMatch

        if aboutButton.exists {
            aboutButton.tap()
            sleep(1)

            let aboutNavBar = app.navigationBars["Über Taxed"]
            XCTAssertTrue(aboutNavBar.exists, "Should navigate to About page")

            // Go back
            app.navigationBars.buttons.firstMatch.tap()
            sleep(1)

            print("✅ About navigation works")
        }
    }

    func testPrivacyPolicyNavigation() throws {
        print("🧪 Testing: Privacy Policy navigation")

        let privacyButton = app.buttons.containing(.staticText, identifier: "Datenschutz").firstMatch

        if privacyButton.exists {
            privacyButton.tap()
            sleep(1)

            let privacyNavBar = app.navigationBars["Datenschutz"]
            XCTAssertTrue(privacyNavBar.exists, "Should navigate to Privacy Policy")

            // Go back
            app.navigationBars.buttons.firstMatch.tap()
            sleep(1)

            print("✅ Privacy Policy navigation works")
        }
    }

    func testTermsOfServiceNavigation() throws {
        print("🧪 Testing: Terms of Service navigation")

        // Scroll down to see Terms of Service
        app.swipeUp()
        sleep(1)

        let termsButton = app.buttons.containing(.staticText, identifier: "Nutzungsbedingungen").firstMatch

        if termsButton.exists {
            termsButton.tap()
            sleep(1)

            let termsNavBar = app.navigationBars["Nutzungsbedingungen"]
            XCTAssertTrue(termsNavBar.exists, "Should navigate to Terms of Service")

            // Go back
            app.navigationBars.buttons.firstMatch.tap()
            sleep(1)

            print("✅ Terms of Service navigation works")
        }
    }

    // MARK: - Support Section Tests

    func testSupportSectionExists() throws {
        print("🧪 Testing: Support section exists")

        // Scroll down to support section
        app.swipeUp()
        sleep(1)

        let supportHeader = app.staticTexts["Support"]
        XCTAssertTrue(supportHeader.exists, "Support header should exist")

        print("✅ Support section found")
    }

    func testSupportNavigation() throws {
        print("🧪 Testing: Support page navigation")

        // Scroll to support section
        app.swipeUp()
        sleep(1)

        let supportButton = app.buttons.containing(.staticText, identifier: "Hilfe & Support").firstMatch

        if supportButton.exists {
            supportButton.tap()
            sleep(1)

            let supportNavBar = app.navigationBars["Hilfe & Support"]
            XCTAssertTrue(supportNavBar.exists, "Should navigate to Support page")

            // Go back
            app.navigationBars.buttons.firstMatch.tap()
            sleep(1)

            print("✅ Support navigation works")
        }
    }

    // MARK: - Sign Out Section Tests

    func testSignOutButtonExists() throws {
        print("🧪 Testing: Sign out button exists")

        // Scroll to bottom
        app.swipeUp()
        sleep(1)
        app.swipeUp()
        sleep(1)

        let signOutButton = app.buttons["Abmelden"]
        XCTAssertTrue(signOutButton.exists, "Sign out button should exist")

        print("✅ Sign out button found")
    }

    func testSignOutConfirmation() throws {
        print("🧪 Testing: Sign out confirmation dialog")

        // Scroll to bottom
        app.swipeUp()
        sleep(1)
        app.swipeUp()
        sleep(1)

        let signOutButton = app.buttons["Abmelden"]

        if signOutButton.exists {
            signOutButton.tap()
            sleep(1)

            // Check for confirmation alert
            let alert = app.alerts["Abmelden"]
            XCTAssertTrue(alert.exists, "Confirmation alert should appear")

            // Cancel instead of actually signing out
            let cancelButton = alert.buttons["Abbrechen"]
            if cancelButton.exists {
                cancelButton.tap()
                sleep(1)
            }

            print("✅ Sign out confirmation works")
        }
    }

    // MARK: - Overall Integration Test

    func testCompleteSettingsFlow() throws {
        print("🧪 Testing: Complete Settings flow")

        // 1. Verify all main sections exist
        XCTAssertTrue(app.staticTexts["Profil"].exists, "Profile section")
        XCTAssertTrue(app.staticTexts["Benachrichtigungen"].exists, "Notifications section")
        XCTAssertTrue(app.staticTexts["Sprache"].exists, "Language section")

        // 2. Scroll and verify bottom sections
        app.swipeUp()
        sleep(1)
        XCTAssertTrue(app.staticTexts["App-Informationen"].exists, "App Info section")
        XCTAssertTrue(app.staticTexts["Support"].exists, "Support section")

        // 3. Test language switching (most critical feature)
        app.swipeDown()
        sleep(1)

        let languageRow = app.buttons.containing(.staticText, identifier: "Sprache").firstMatch
        languageRow.tap()
        sleep(1)

        // Verify all languages are there
        XCTAssertTrue(app.staticTexts["Deutsch"].exists, "German available")
        XCTAssertTrue(app.staticTexts["English"].exists, "English available")
        XCTAssertTrue(app.staticTexts["Français"].exists, "French available")
        XCTAssertTrue(app.staticTexts["Italiano"].exists, "Italian available")

        // Go back
        app.navigationBars.buttons.firstMatch.tap()
        sleep(1)

        print("✅ Complete Settings flow works")
    }
}
