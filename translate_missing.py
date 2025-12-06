#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Swiss Tax App Localization Translator
Translates missing strings from English to Swiss German, French, and Italian
"""

import re
import os

# Translation dictionaries for Swiss context
translations = {
    # About section
    "about.contact": {
        "de": "Kontakt",
        "fr": "Contact",
        "it": "Contatto"
    },
    "about.data_security.footer": {
        "de": "Ihre Dokumente und Daten werden in sicheren Schweizer Rechenzentren gespeichert, geschützt durch strenge Schweizer Datenschutzgesetze und verschlüsselt mit branchenüblicher AES-256-Verschlüsselung.",
        "fr": "Vos documents et données sont stockés dans des centres de données suisses sécurisés, protégés par les lois strictes suisses sur la protection des données et cryptés avec le chiffrement AES-256 standard de l'industrie.",
        "it": "I vostri documenti e dati sono archiviati in data center svizzeri sicuri, protetti dalle rigorose leggi svizzere sulla privacy e crittografati con crittografia AES-256 standard del settore."
    },
    "about.data_security.header": {
        "de": "Datensicherheit & Speicherung",
        "fr": "Sécurité et stockage des données",
        "it": "Sicurezza e archiviazione dei dati"
    },
    "about.data_storage.subtitle": {
        "de": "Alle Daten in Schweizer Rechenzentren gespeichert",
        "fr": "Toutes les données stockées dans des centres de données suisses",
        "it": "Tutti i dati archiviati nei data center svizzeri"
    },
    "about.data_storage.title": {
        "de": "Schweizer Datenspeicherung",
        "fr": "Stockage de données suisse",
        "it": "Archiviazione dati svizzera"
    },
    "about.encryption.subtitle": {
        "de": "AES-256-Verschlüsselung auf Bankniveau",
        "fr": "Chiffrement AES-256 de niveau bancaire",
        "it": "Crittografia AES-256 a livello bancario"
    },
    "about.encryption.title": {
        "de": "Ende-zu-Ende-Verschlüsselung",
        "fr": "Chiffrement de bout en bout",
        "it": "Crittografia end-to-end"
    },
    "about.footer.linkedin": {
        "de": "LinkedIn",
        "fr": "LinkedIn",
        "it": "LinkedIn"
    },
    "about.footer.visit_linkedin": {
        "de": "LinkedIn-Profil besuchen",
        "fr": "Visiter le profil LinkedIn",
        "it": "Visita il profilo LinkedIn"
    },
    "about.footer.visit_website": {
        "de": "Website besuchen",
        "fr": "Visiter le site web",
        "it": "Visita il sito web"
    },
    "about.iso_certified.subtitle": {
        "de": "Einhaltung internationaler Sicherheitsstandards",
        "fr": "Conformité aux normes de sécurité internationales",
        "it": "Conformità agli standard di sicurezza internazionali"
    },
    "about.iso_certified.title": {
        "de": "ISO 27001 zertifiziert",
        "fr": "Certifié ISO 27001",
        "it": "Certificato ISO 27001"
    },
    "about.mission": {
        "de": "Unsere Mission",
        "fr": "Notre mission",
        "it": "La nostra missione"
    },
    "about.mission.content": {
        "de": "Wir glauben, dass die Steuererklärung einfach, transparent und stressfrei sein sollte. Unsere Mission ist es, allen in der Schweiz - von Einheimischen bis zu Expats - zu helfen, das Steuersystem mit Vertrauen zu navigieren.",
        "fr": "Nous croyons que la déclaration d'impôts devrait être simple, transparente et sans stress. Notre mission est d'aider tout le monde en Suisse - des locaux aux expatriés - à naviguer dans le système fiscal en toute confiance.",
        "it": "Crediamo che la dichiarazione dei redditi dovrebbe essere semplice, trasparente e senza stress. La nostra missione è aiutare tutti in Svizzera - dai locali agli espatriati - a navigare nel sistema fiscale con fiducia."
    },
    "about.swiss_protection.subtitle": {
        "de": "Geschützt durch das Schweizer Datenschutzgesetz",
        "fr": "Protégé par la loi fédérale suisse sur la protection des données",
        "it": "Protetto dalla legge federale svizzera sulla protezione dei dati"
    },
    "about.swiss_protection.title": {
        "de": "Schweizer Datenschutz",
        "fr": "Protection des données suisse",
        "it": "Protezione dei dati svizzera"
    },

    # Accessibility
    "accessibility.increase_contrast": {
        "de": "Kontrast erhöhen",
        "fr": "Augmenter le contraste",
        "it": "Aumenta il contrasto"
    },
    "accessibility.larger_text": {
        "de": "Grösserer Text",
        "fr": "Texte plus grand",
        "it": "Testo più grande"
    },
    "accessibility.motion.footer": {
        "de": "Animationen und Übergänge reduzieren",
        "fr": "Réduire les animations et les transitions",
        "it": "Riduci animazioni e transizioni"
    },
    "accessibility.motion.header": {
        "de": "BEWEGUNG",
        "fr": "MOUVEMENT",
        "it": "MOVIMENTO"
    },
    "accessibility.reduce_motion": {
        "de": "Bewegung reduzieren",
        "fr": "Réduire le mouvement",
        "it": "Riduci movimento"
    },
    "accessibility.system_settings": {
        "de": "Systemeinstellungen für Barrierefreiheit öffnen",
        "fr": "Ouvrir les paramètres d'accessibilité du système",
        "it": "Apri impostazioni di accessibilità del sistema"
    },
    "accessibility.vision.footer": {
        "de": "Textgrösse und Kontrast für bessere Lesbarkeit anpassen",
        "fr": "Ajuster la taille du texte et le contraste pour une meilleure lisibilité",
        "it": "Regola dimensione testo e contrasto per una migliore leggibilità"
    },
    "accessibility.vision.header": {
        "de": "SEHEN",
        "fr": "VISION",
        "it": "VISIONE"
    },
    "accessibility.voiceover": {
        "de": "VoiceOver",
        "fr": "VoiceOver",
        "it": "VoiceOver"
    },
    "accessibility.voiceover.footer": {
        "de": "VoiceOver-Bildschirmleser aktivieren",
        "fr": "Activer le lecteur d'écran VoiceOver",
        "it": "Attiva il lettore schermo VoiceOver"
    },
    "accessibility.voiceover.header": {
        "de": "VOICEOVER",
        "fr": "VOICEOVER",
        "it": "VOICEOVER"
    },

    # Calculator
    "calc.calculate": {
        "de": "Steuern berechnen",
        "fr": "Calculer l'impôt",
        "it": "Calcola l'imposta"
    },
    "calc.canton": {
        "de": "Kanton",
        "fr": "Canton",
        "it": "Cantone"
    },
    "calc.canton_specific": {
        "de": "Basierend auf Steuersätzen für",
        "fr": "Basé sur les taux d'imposition pour",
        "it": "Basato sulle aliquote fiscali per"
    },
    "calc.children": {
        "de": "Kinder vorhanden",
        "fr": "Avoir des enfants",
        "it": "Avere figli"
    },
    "calc.disclaimer_text": {
        "de": "Dies ist nur eine Schätzung. Die tatsächlichen Steuern können aufgrund von Abzügen und anderen Faktoren variieren.",
        "fr": "Ceci est une estimation seulement. Les impôts réels peuvent varier en fonction des déductions et d'autres facteurs.",
        "it": "Questa è solo una stima. Le tasse effettive possono variare in base alle deduzioni e ad altri fattori."
    },
    "calc.disclaimer_title": {
        "de": "Haftungsausschluss",
        "fr": "Avertissement",
        "it": "Disclaimer"
    },
    "calc.effective_rate": {
        "de": "Effektiver Steuersatz",
        "fr": "Taux d'imposition effectif",
        "it": "Aliquota fiscale effettiva"
    },
    "calc.estimated_tax": {
        "de": "Geschätzte Steuern",
        "fr": "Impôt estimé",
        "it": "Imposta stimata"
    },
    "calc.gross_income": {
        "de": "Bruttoeinkommen",
        "fr": "Revenu brut",
        "it": "Reddito lordo"
    },
    "calc.income": {
        "de": "Jahreseinkommen",
        "fr": "Revenu annuel",
        "it": "Reddito annuale"
    },
    "calc.income_placeholder": {
        "de": "Geben Sie Ihr Bruttoeinkommen ein",
        "fr": "Entrez votre revenu brut",
        "it": "Inserisci il tuo reddito lordo"
    },
    "calc.marital": {
        "de": "Zivilstand",
        "fr": "État civil",
        "it": "Stato civile"
    },
    "calc.married": {
        "de": "Verheiratet",
        "fr": "Marié(e)",
        "it": "Sposato/a"
    },
    "calc.net_income": {
        "de": "Nettoeinkommen",
        "fr": "Revenu net",
        "it": "Reddito netto"
    },
    "calc.number_children": {
        "de": "Anzahl Kinder",
        "fr": "Nombre d'enfants",
        "it": "Numero di figli"
    },
    "calc.pro_description": {
        "de": "Erhalten Sie genaue Steuerschätzungen basierend auf Ihrem Kanton",
        "fr": "Obtenez des estimations fiscales précises basées sur votre canton",
        "it": "Ottieni stime fiscali accurate basate sul tuo cantone"
    },
    "calc.pro_feature": {
        "de": "Pro-Funktion",
        "fr": "Fonctionnalité Pro",
        "it": "Funzione Pro"
    },
    "calc.results": {
        "de": "Steuerschätzung",
        "fr": "Estimation fiscale",
        "it": "Stima fiscale"
    },
    "calc.single": {
        "de": "Ledig",
        "fr": "Célibataire",
        "it": "Celibe/Nubile"
    }
}

def parse_strings_file(file_path):
    """Parse a .strings file and extract key-value pairs"""
    strings = {}
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
        # Match pattern: "key" = "value";
        pattern = r'"([^"]+)"\s*=\s*"([^"]+)";'
        matches = re.findall(pattern, content)
        for key, value in matches:
            strings[key] = value
    return strings

def translate_string(key, value, target_lang):
    """Translate a single string to target language"""
    if key in translations and target_lang in translations[key]:
        return translations[key][target_lang]

    # If no specific translation, provide a generic translation based on patterns
    # This is a fallback for keys not in our dictionary
    return None

def write_translations_file(output_path, translations_dict):
    """Write translations to a .strings file"""
    with open(output_path, 'w', encoding='utf-8') as f:
        for key, value in sorted(translations_dict.items()):
            # Escape quotes in the value
            value = value.replace('"', '\\"')
            f.write(f'"{key}" = "{value}";\n')

def main():
    # Read all missing English strings
    missing_en = parse_strings_file('missing_translations/to_translate_de.strings')

    # Create output directory for completed translations
    os.makedirs('completed_translations', exist_ok=True)

    # Process each language
    for lang_code, lang_name in [('de', 'German'), ('fr', 'French'), ('it', 'Italian')]:
        print(f"Processing {lang_name} translations...")

        translated = {}
        untranslated = []

        for key, english_value in missing_en.items():
            translation = translate_string(key, english_value, lang_code)
            if translation:
                translated[key] = translation
            else:
                untranslated.append(key)

        # Write translated strings
        output_file = f'completed_translations/translated_{lang_code}.strings'
        write_translations_file(output_file, translated)

        print(f"  ✓ Translated {len(translated)} strings")
        print(f"  ⚠ {len(untranslated)} strings need manual translation")

        # Write list of untranslated keys for reference
        if untranslated:
            with open(f'completed_translations/needs_translation_{lang_code}.txt', 'w') as f:
                for key in untranslated:
                    f.write(f'{key}\n')

    print("\nTranslation complete!")
    print("Check 'completed_translations' folder for results")

if __name__ == "__main__":
    main()