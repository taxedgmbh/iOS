#!/bin/bash

# Export Missing Translations Script for TaxedGmbH iOS App
# This script identifies and exports missing translation keys

echo "🌍 Exporting Missing Translations..."
echo "===================================="

# Create export directory
mkdir -p missing_translations
cd TaxedGmbH_IOS

# Extract all keys from English (base language)
echo "📝 Extracting English keys..."
grep -o '^"[^"]*"' en.lproj/Localizable.strings | sed 's/"//g' | sort > ../missing_translations/en_keys.txt

# Function to find and export missing keys
export_missing() {
    LANG=$1
    LANG_NAME=$2

    echo "🔍 Processing $LANG_NAME ($LANG)..."

    # Extract keys from target language
    grep -o '^"[^"]*"' $LANG.lproj/Localizable.strings | sed 's/"//g' | sort > ../missing_translations/${LANG}_keys.txt

    # Find missing keys
    comm -23 ../missing_translations/en_keys.txt ../missing_translations/${LANG}_keys.txt > ../missing_translations/missing_${LANG}.txt

    # Create a file with missing translations in format ready for translation
    echo "// Missing translations for $LANG_NAME" > ../missing_translations/to_translate_${LANG}.strings
    echo "// Total missing: $(wc -l < ../missing_translations/missing_${LANG}.txt | tr -d ' ') keys" >> ../missing_translations/to_translate_${LANG}.strings
    echo "" >> ../missing_translations/to_translate_${LANG}.strings

    # Extract the English values for missing keys
    while IFS= read -r key; do
        # Find the English value for this key
        grep "^\"$key\"" en.lproj/Localizable.strings >> ../missing_translations/to_translate_${LANG}.strings
    done < ../missing_translations/missing_${LANG}.txt

    COUNT=$(wc -l < ../missing_translations/missing_${LANG}.txt | tr -d ' ')
    echo "   ⚠️  $COUNT missing translations"
}

# Process each language
export_missing "de" "German"
export_missing "fr" "French"
export_missing "it" "Italian"

# Create summary
echo ""
echo "📊 Summary Report"
echo "================"
echo ""
echo "Missing translations by language:"
echo "- German:  $(wc -l < ../missing_translations/missing_de.txt | tr -d ' ') keys"
echo "- French:  $(wc -l < ../missing_translations/missing_fr.txt | tr -d ' ') keys"
echo "- Italian: $(wc -l < ../missing_translations/missing_it.txt | tr -d ' ') keys"
echo ""
echo "✅ Export complete!"
echo ""
echo "📁 Files created in 'missing_translations/' directory:"
echo "  - to_translate_de.strings (German translations needed)"
echo "  - to_translate_fr.strings (French translations needed)"
echo "  - to_translate_it.strings (Italian translations needed)"
echo ""
echo "📌 Next steps:"
echo "  1. Send to_translate_*.strings files to translation service"
echo "  2. Request Swiss-specific translations where applicable"
echo "  3. Merge completed translations back into respective .lproj folders"
echo ""

cd ..