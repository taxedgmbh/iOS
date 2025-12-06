#!/bin/bash

# Merge Translations Script for TaxedGmbH iOS App
# This script safely merges completed translations into existing localization files

echo "🌐 Merging Translations into Localization Files"
echo "==============================================="
echo ""

# Create backup directory
BACKUP_DIR="localization_backups_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Function to merge translations for a language
merge_language() {
    LANG_CODE=$1
    LANG_NAME=$2
    TRANSLATION_FILE="completed_translations/${3}_translations.strings"
    TARGET_FILE="TaxedGmbH_IOS/${LANG_CODE}.lproj/Localizable.strings"

    echo "📝 Processing $LANG_NAME ($LANG_CODE)..."

    # Check if translation file exists
    if [ ! -f "$TRANSLATION_FILE" ]; then
        echo "  ❌ Translation file not found: $TRANSLATION_FILE"
        return 1
    fi

    # Check if target file exists
    if [ ! -f "$TARGET_FILE" ]; then
        echo "  ❌ Target file not found: $TARGET_FILE"
        return 1
    fi

    # Create backup
    cp "$TARGET_FILE" "$BACKUP_DIR/$(basename $TARGET_FILE).${LANG_CODE}.backup"
    echo "  ✓ Backup created"

    # Count existing translations
    EXISTING_COUNT=$(grep -c '^"[^"]*" = "[^"]*";$' "$TARGET_FILE")

    # Extract existing keys to avoid duplicates
    grep -o '^"[^"]*"' "$TARGET_FILE" | sed 's/"//g' | sort > /tmp/existing_keys_${LANG_CODE}.txt

    # Extract new translation keys
    grep -o '^"[^"]*"' "$TRANSLATION_FILE" | sed 's/"//g' | sort > /tmp/new_keys_${LANG_CODE}.txt

    # Find keys that are genuinely new (not already in target)
    comm -13 /tmp/existing_keys_${LANG_CODE}.txt /tmp/new_keys_${LANG_CODE}.txt > /tmp/unique_new_keys_${LANG_CODE}.txt

    # Create temp file with only new translations
    TEMP_FILE="/tmp/new_translations_${LANG_CODE}.strings"
    > "$TEMP_FILE"

    # Add section header
    echo "" >> "$TEMP_FILE"
    echo "// ===========================================" >> "$TEMP_FILE"
    echo "// Translations added on $(date +%Y-%m-%d)" >> "$TEMP_FILE"
    echo "// Generated with Claude LLM assistance" >> "$TEMP_FILE"
    echo "// ===========================================" >> "$TEMP_FILE"
    echo "" >> "$TEMP_FILE"

    # Extract only new translations
    while IFS= read -r key; do
        # Find the line with this key in the translation file
        grep "^\"$key\"" "$TRANSLATION_FILE" >> "$TEMP_FILE"
    done < /tmp/unique_new_keys_${LANG_CODE}.txt

    # Count new translations
    NEW_COUNT=$(wc -l < /tmp/unique_new_keys_${LANG_CODE}.txt | tr -d ' ')

    if [ "$NEW_COUNT" -gt 0 ]; then
        # Append new translations to target file
        cat "$TEMP_FILE" >> "$TARGET_FILE"
        echo "  ✓ Added $NEW_COUNT new translations"
    else
        echo "  ℹ No new translations to add (all keys already exist)"
    fi

    # Count final translations
    FINAL_COUNT=$(grep -c '^"[^"]*" = "[^"]*";$' "$TARGET_FILE")

    echo "  📊 Statistics:"
    echo "     - Previous: $EXISTING_COUNT translations"
    echo "     - Added: $NEW_COUNT new translations"
    echo "     - Final: $FINAL_COUNT translations"
    echo ""

    # Clean up temp files
    rm -f /tmp/existing_keys_${LANG_CODE}.txt
    rm -f /tmp/new_keys_${LANG_CODE}.txt
    rm -f /tmp/unique_new_keys_${LANG_CODE}.txt
    rm -f "$TEMP_FILE"
}

# Process each language
echo "🚀 Starting merge process..."
echo ""

merge_language "de" "German" "german"
merge_language "fr" "French" "french"
merge_language "it" "Italian" "italian"

# Final verification
echo "🔍 Final Verification"
echo "===================="
echo ""

# Check English baseline
EN_COUNT=$(grep -c '^"[^"]*" = "[^"]*";$' TaxedGmbH_IOS/en.lproj/Localizable.strings)
echo "English (baseline): $EN_COUNT translations"

# Check each language
for lang in de fr it; do
    COUNT=$(grep -c '^"[^"]*" = "[^"]*";$' TaxedGmbH_IOS/$lang.lproj/Localizable.strings)
    PERCENTAGE=$(echo "scale=1; $COUNT * 100 / $EN_COUNT" | bc)

    case $lang in
        de) LANG_NAME="German" ;;
        fr) LANG_NAME="French" ;;
        it) LANG_NAME="Italian" ;;
    esac

    if [ "$COUNT" -eq "$EN_COUNT" ]; then
        echo "$LANG_NAME: $COUNT translations (✅ 100% complete)"
    else
        MISSING=$((EN_COUNT - COUNT))
        echo "$LANG_NAME: $COUNT translations (${PERCENTAGE}% - missing $MISSING)"
    fi
done

echo ""
echo "✅ Merge complete!"
echo ""
echo "📁 Backup location: $BACKUP_DIR"
echo ""
echo "📌 Next steps:"
echo "  1. Review the merged translations in Xcode"
echo "  2. Build the project to verify no syntax errors"
echo "  3. Test the app with different language settings"
echo "  4. Commit the changes if everything looks good"
echo ""
echo "💡 To restore from backup if needed:"
echo "   cp $BACKUP_DIR/*.backup TaxedGmbH_IOS/[lang].lproj/Localizable.strings"
echo ""
