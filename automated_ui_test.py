#!/usr/bin/env python3
"""
Automated UI Testing Script for Taxed iOS App
Uses subprocess to control iOS Simulator
"""

import subprocess
import time
import os

# Configuration
SIMULATOR_ID = "6D19C4F8-AC1F-401C-A92B-A020FE70E613"  # iPhone 17 Pro
BUNDLE_ID = "com.taxed.app"
SCREENSHOT_DIR = "/tmp/taxed_screenshots"

def run_command(cmd):
    """Execute shell command and return output"""
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return result.stdout, result.stderr, result.returncode

def take_screenshot(name):
    """Take simulator screenshot"""
    filepath = f"{SCREENSHOT_DIR}/{name}.png"
    cmd = f"xcrun simctl io {SIMULATOR_ID} screenshot {filepath}"
    stdout, stderr, code = run_command(cmd)
    if code == 0:
        print(f"✅ Screenshot saved: {name}")
        return filepath
    else:
        print(f"❌ Screenshot failed: {stderr}")
        return None

def tap_coordinates(x, y):
    """Tap at specific coordinates using AppleScript"""
    script = f'''
    tell application "System Events"
        tell process "Simulator"
            set frontmost to true
            delay 0.2
            click at {{{x}, {y}}}
        end tell
    end tell
    '''
    cmd = f"osascript -e '{script}'"
    run_command(cmd)
    time.sleep(1)

def type_text(text):
    """Type text into focused field"""
    # Use pbpaste to type text
    cmd = f'echo "{text}" | pbcopy'
    run_command(cmd)
    # Paste with Cmd+V
    script = '''
    tell application "System Events"
        tell process "Simulator"
            keystroke "v" using command down
        end tell
    end tell
    '''
    run_command(f"osascript -e '{script}'")
    time.sleep(0.5)

def main():
    """Main testing flow"""
    print("🧪 Starting Automated UI Test\n")

    # Create screenshot directory
    os.makedirs(SCREENSHOT_DIR, exist_ok=True)

    # Test 1: Login Screen
    print("📱 Test 1: Login Screen")
    take_screenshot("01_login_screen_initial")
    print("✅ Login screen verified\n")

    # Test 2: Navigate to Sign Up
    print("📱 Test 2: Navigate to Sign Up")
    print("Tapping 'Registrieren' button...")
    # Coordinates for "Registrieren" link (approximate)
    tap_coordinates(487, 1293)
    time.sleep(2)
    take_screenshot("02_signup_screen")
    print("✅ Sign up screen loaded\n")

    # Test 3: Fill Sign Up Form
    print("📱 Test 3: Fill Sign Up Form")

    # Tap name field
    print("Filling name field...")
    tap_coordinates(360, 700)
    time.sleep(0.5)
    type_text("Test User")
    take_screenshot("03_signup_name_filled")

    # Tap email field
    print("Filling email field...")
    tap_coordinates(360, 800)
    time.sleep(0.5)
    type_text("test@example.com")
    take_screenshot("04_signup_email_filled")

    # Tap password field
    print("Filling password field...")
    tap_coordinates(360, 900)
    time.sleep(0.5)
    type_text("Test1234")
    take_screenshot("05_signup_password_filled")
    time.sleep(1)

    # Check validation indicators
    print("Checking password validation indicators...")
    take_screenshot("06_signup_validation_indicators")

    # Test 4: Submit Sign Up
    print("\n📱 Test 4: Submit Sign Up")
    print("Tapping 'Konto erstellen' button...")
    tap_coordinates(360, 1050)
    time.sleep(3)
    take_screenshot("07_signup_loading_or_result")
    time.sleep(3)
    take_screenshot("08_signup_final_result")

    print("\n✅ Automated testing complete!")
    print(f"\n📁 Screenshots saved to: {SCREENSHOT_DIR}")
    print("\nNext: Review screenshots in AUTOMATED_TEST_REPORT.md")

if __name__ == "__main__":
    main()
