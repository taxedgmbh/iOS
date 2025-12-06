#!/usr/bin/env python3
import re
import sys

def parse_strings_file(filepath):
    """Parse a .strings file and return a dictionary of key-value pairs."""
    strings_dict = {}
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Match pattern: "key" = "value";
    pattern = r'"([^"]+)"\s*=\s*"([^"]*(?:\\.[^"]*)*)"\s*;'
    matches = re.findall(pattern, content, re.MULTILINE)

    for key, value in matches:
        strings_dict[key] = value

    return strings_dict

def find_missing_keys(english_file, target_file, target_lang):
    """Find keys that exist in English but not in target language."""
    english_strings = parse_strings_file(english_file)
    target_strings = parse_strings_file(target_file)

    missing_keys = []
    for key in english_strings:
        if key not in target_strings:
            missing_keys.append((key, english_strings[key]))

    return missing_keys

def write_missing_translations(missing_keys, output_file, lang_name):
    """Write missing translations to a file."""
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(f"// Missing translations for {lang_name}\n")
        f.write(f"// Total: {len(missing_keys)} strings\n\n")

        for key, english_value in sorted(missing_keys):
            f.write(f'"{key}" = "{english_value}";\n')

# File paths
base_path = "/Users/emanuelflury/github/TaxedGmbH_IOS/TaxedGmbH_IOS"
english_file = f"{base_path}/en.lproj/Localizable.strings"
german_file = f"{base_path}/de.lproj/Localizable.strings"
french_file = f"{base_path}/fr.lproj/Localizable.strings"
italian_file = f"{base_path}/it.lproj/Localizable.strings"

# Find missing translations
print("Analyzing localization files...")
missing_de = find_missing_keys(english_file, german_file, "German")
missing_fr = find_missing_keys(english_file, french_file, "French")
missing_it = find_missing_keys(english_file, italian_file, "Italian")

# Write to files
write_missing_translations(missing_de, f"{base_path}/missing_de.strings", "Swiss German")
write_missing_translations(missing_fr, f"{base_path}/missing_fr.strings", "Swiss French")
write_missing_translations(missing_it, f"{base_path}/missing_it.strings", "Swiss Italian")

print(f"\nMissing translations:")
print(f"  German: {len(missing_de)} strings")
print(f"  French: {len(missing_fr)} strings")
print(f"  Italian: {len(missing_it)} strings")
print(f"\nOutput files created in {base_path}/")
