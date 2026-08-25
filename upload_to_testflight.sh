#!/bin/bash
#
# Archive the app and upload it to TestFlight.
#
# The two scripts this replaces both carried literal YOUR_API_KEY /
# YOUR_ISSUER_ID placeholders, so neither had ever run successfully. Credentials
# come from the environment here, and the script refuses to start without them
# rather than failing forty minutes later at the upload step.
#
# Usage:
#   export ASC_ISSUER_ID=<uuid from App Store Connect → Users and Access →
#                          Integrations → App Store Connect API>
#   ./upload_to_testflight.sh
#
# The signing key is expected at ~/.appstoreconnect/private_keys/AuthKey_<ID>.p8
# where <ID> is ASC_KEY_ID. altool finds it there by convention.

set -euo pipefail

PROJECT="TaxedGmbH_IOS.xcodeproj"
SCHEME="TaxedGmbH_IOS"
ARCHIVE="build/TaxedGmbH_IOS.xcarchive"
EXPORT_DIR="build/export"

ASC_KEY_ID="${ASC_KEY_ID:-9RKNQAQ27H}"

if [ -z "${ASC_ISSUER_ID:-}" ]; then
  echo "ASC_ISSUER_ID is not set."
  echo
  echo "  App Store Connect → Users and Access → Integrations → App Store Connect API"
  echo "  Copy the Issuer ID (a UUID) shown above the key list, then:"
  echo "    export ASC_ISSUER_ID=<uuid>"
  exit 1
fi

KEY_PATH="$HOME/.appstoreconnect/private_keys/AuthKey_${ASC_KEY_ID}.p8"
if [ ! -f "$KEY_PATH" ]; then
  echo "No signing key at $KEY_PATH"
  exit 1
fi

echo "==> Archiving (this needs an Apple Distribution certificate; Xcode's"
echo "    automatic signing creates one if the Apple ID has the team role)"
rm -rf "$ARCHIVE" "$EXPORT_DIR"
xcodebuild archive \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE" \
  -allowProvisioningUpdates

echo "==> Exporting for the App Store"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist ExportOptions.plist \
  -allowProvisioningUpdates

IPA=$(find "$EXPORT_DIR" -name '*.ipa' | head -1)
[ -n "$IPA" ] || { echo "No .ipa produced"; exit 1; }

echo "==> Validating before upload"
xcrun altool --validate-app -f "$IPA" -t ios \
  --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"

echo "==> Uploading to TestFlight"
xcrun altool --upload-app -f "$IPA" -t ios \
  --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"

echo
echo "Uploaded. Processing in App Store Connect usually takes 5–15 minutes"
echo "before the build appears in TestFlight."
