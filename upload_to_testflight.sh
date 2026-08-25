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
# The same key and issuer are already installed for the tagalogue.tv project on
# this machine, so the issuer can be read from there rather than looked up:
#
#   export ASC_ISSUER_ID=$(python3 -c "import json,os; print(json.load(open(
#     os.path.expanduser('~/Documents/tagalogue.tv/credentials/asc.json')))['issuerId'])")
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

# The same API key drives provisioning, not just the upload. That is why this
# needs no Apple ID signed into Xcode: the key creates the distribution
# certificate and profile itself. `-allowProvisioningUpdates` on its own would
# require an interactive Xcode account, which this build machine does not have.
AUTH=(-allowProvisioningUpdates
      -authenticationKeyPath "$KEY_PATH"
      -authenticationKeyID "$ASC_KEY_ID"
      -authenticationKeyIssuerID "$ASC_ISSUER_ID")

echo "==> Archiving (the API key mints the distribution certificate if the"
echo "    team does not have one yet)"
rm -rf "$ARCHIVE" "$EXPORT_DIR"
xcodebuild archive \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE" \
  "${AUTH[@]}"

# ExportOptions.plist sets `destination = upload`, so THIS STEP UPLOADS.
# It analyses the package, submits it, and reports "Upload succeeded" — there
# is no .ipa left on disk afterwards and no separate altool call to make. An
# earlier version of this script looked for the .ipa and failed after the
# upload had already succeeded, which reads alarmingly like the opposite.
echo "==> Exporting and uploading to App Store Connect"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist ExportOptions.plist \
  "${AUTH[@]}"

echo
echo "Uploaded. Processing usually completes within a few minutes."
echo
echo "Export compliance is answered by INFOPLIST_KEY_ITSAppUsesNonExemptEncryption"
echo "in the project. Without it, App Store Connect holds the build back from"
echo "testers without saying so anywhere obvious."
