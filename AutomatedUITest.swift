#!/usr/bin/env swift

import Foundation
import XCTest

// This script will be used to automate UI interactions
// We'll compile and run this as a standalone test

class AutomatedUITest: XCTestCase {
    let app = XCUIApplication()

    func testNavigateToSignUp() {
        app.launch()

        // Wait for login screen
        let registerButton = app.buttons["Noch kein Konto? Registrieren"]
        XCTAssertTrue(registerButton.waitForExistence(timeout: 5))

        // Tap register
        registerButton.tap()

        // Verify we're on signup screen
        let signUpTitle = app.staticTexts["Konto erstellen"]
        XCTAssertTrue(signUpTitle.waitForExistence(timeout: 3))
    }

    func testSignUpFlow() {
        app.launch()

        // Navigate to sign up
        app.buttons["Noch kein Konto? Registrieren"].tap()

        // Fill in name
        let nameField = app.textFields["Vollständiger Name"]
        nameField.tap()
        nameField.typeText("Test User")

        // Fill in email
        let emailField = app.textFields["E-Mail-Adresse"]
        emailField.tap()
        emailField.typeText("test@example.com")

        // Fill in password
        let passwordField = app.secureTextFields["Passwort"]
        passwordField.tap()
        passwordField.typeText("Test1234")

        // Tap sign up button
        app.buttons["Konto erstellen"].tap()

        // Wait for result
        sleep(5)
    }
}
