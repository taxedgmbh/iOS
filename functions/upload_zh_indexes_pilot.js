/**
 * Upload Zürich Tax Index Database - Pilot Phase (Top 10 Indexes)
 *
 * This script uploads sophisticated tax index entries for Canton Zürich
 * to Firebase Firestore with fact-based legal references.
 *
 * Tax Year: 2024
 * Canton: ZH (Zürich)
 * Collection: taxIndexes
 *
 * Run: node upload_zh_indexes_pilot.js
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
const serviceAccount = require('/Users/emanuelflury/Downloads/taxedn8n-68fb68c972c9.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'taxedgmbh',
  databaseId: 'taxedgmbh'
});

const db = admin.firestore();
db.settings({ databaseId: 'taxedgmbh' });

/**
 * Top 10 Priority Tax Indexes for Canton Zürich (2024)
 *
 * Based on official sources:
 * - Wegleitung zur Steuererklärung 2024 Kanton Zürich
 * - Steuergesetz des Kantons Zürich (StG ZH) § 17, § 18, § 22
 * - Bundesgesetz über die direkte Bundessteuer (DBG) Art. 17, 18, 22, 23
 */
const zhIndexes = [
  // ============================================================
  // INDEX 100 - Haupterwerb Person 1
  // ============================================================
  {
    Canton: "ZH",
    Index: "100",
    Tax_Year: 2024,
    Main_Category: "Einkünfte aus unselbständiger Erwerbstätigkeit",
    Sub_Category: "Haupterwerb",
    Person: "Person 1",

    // Legal References (Fact-based)
    Legal_Reference_Canton: "§ 17 Abs. 1 StG ZH",
    Legal_Reference_Federal: "Art. 17 Abs. 1 DBG",

    // Sophisticated Explanations
    Rational_Explanation: "Der Bruttolohn aus dem Haupterwerb umfasst alle Einkünfte aus unselbständiger Erwerbstätigkeit gemäss Lohnausweis. Dies beinhaltet den regulären Lohn sowie sämtliche Nebeneinkünfte wie Gratifikationen, Boni, Provisionen, Zulagen, Naturalleistungen und geldwerte Vorteile aus dem Arbeitsverhältnis. Der Betrag muss vollumfänglich als Einkommen deklariert werden.",

    Deductibility_Rules: "Vollumfänglich steuerbar zu 100%",

    Max_Deductible: "Nicht zutreffend (Einkommensposition)",

    Limitations: "Lohnausweis des Arbeitgebers erforderlich. Der deklarierte Betrag muss mit dem Lohnausweis übereinstimmen. Pauschalabzug für Berufsauslagen: 3% des Nettolohns (min. CHF 2'000, max. CHF 4'000).",

    Calculation_Method: "Bruttolohn gemäss Lohnausweis (Ziffer 1) plus alle Nebeneinkünfte, Gratifikationen und geldwerte Vorteile. Der Betrag entspricht der Summe aller steuerbaren Einkünfte aus dem Arbeitsverhältnis.",

    // Source Documentation
    Source: "https://www.zh.ch/de/steuern-finanzen/steuern/steuererklarung.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Zürich, Seite 8, Ziffer 1.1",
    Last_Updated: admin.firestore.FieldValue.serverTimestamp(),
    Verification_Status: "verified",

    // Field Definitions
    Field1_Name_DE: "Bruttolohn",
    Field1_Type: "currency",
    Field1_Required: true,

    Field2_Name_DE: "Gratifikationen/Boni",
    Field2_Type: "currency",
    Field2_Required: false,

    Field3_Name_DE: "Naturalleistungen",
    Field3_Type: "currency",
    Field3_Required: false,

    Field4_Name_DE: null,
    Field4_Type: null,
    Field4_Required: false,

    Field5_Name_DE: null,
    Field5_Type: null,
    Field5_Required: false,

    // Metadata
    Currency_Required: false,
    FX_Required: false,
    Display_Formula: "Field1 + Field2 + Field3",
    Notes: "Basis: Lohnausweis des Arbeitgebers. Alle Nebeneinkünfte sind steuerbar."
  },

  // ============================================================
  // INDEX 101 - Haupterwerb Person 2
  // ============================================================
  {
    Canton: "ZH",
    Index: "101",
    Tax_Year: 2024,
    Main_Category: "Einkünfte aus unselbständiger Erwerbstätigkeit",
    Sub_Category: "Haupterwerb",
    Person: "Person 2",

    Legal_Reference_Canton: "§ 17 Abs. 1 StG ZH",
    Legal_Reference_Federal: "Art. 17 Abs. 1 DBG",

    Rational_Explanation: "Der Bruttolohn aus dem Haupterwerb umfasst alle Einkünfte aus unselbständiger Erwerbstätigkeit gemäss Lohnausweis. Dies beinhaltet den regulären Lohn sowie sämtliche Nebeneinkünfte wie Gratifikationen, Boni, Provisionen, Zulagen, Naturalleistungen und geldwerte Vorteile aus dem Arbeitsverhältnis. Der Betrag muss vollumfänglich als Einkommen deklariert werden.",

    Deductibility_Rules: "Vollumfänglich steuerbar zu 100%",
    Max_Deductible: "Nicht zutreffend (Einkommensposition)",

    Limitations: "Lohnausweis des Arbeitgebers erforderlich. Der deklarierte Betrag muss mit dem Lohnausweis übereinstimmen. Pauschalabzug für Berufsauslagen: 3% des Nettolohns (min. CHF 2'000, max. CHF 4'000).",

    Calculation_Method: "Bruttolohn gemäss Lohnausweis (Ziffer 1) plus alle Nebeneinkünfte, Gratifikationen und geldwerte Vorteile. Der Betrag entspricht der Summe aller steuerbaren Einkünfte aus dem Arbeitsverhältnis.",

    Source: "https://www.zh.ch/de/steuern-finanzen/steuern/steuererklarung.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Zürich, Seite 8, Ziffer 1.1",
    Last_Updated: admin.firestore.FieldValue.serverTimestamp(),
    Verification_Status: "verified",

    Field1_Name_DE: "Bruttolohn",
    Field1_Type: "currency",
    Field1_Required: true,

    Field2_Name_DE: "Gratifikationen/Boni",
    Field2_Type: "currency",
    Field2_Required: false,

    Field3_Name_DE: "Naturalleistungen",
    Field3_Type: "currency",
    Field3_Required: false,

    Field4_Name_DE: null,
    Field4_Type: null,
    Field4_Required: false,

    Field5_Name_DE: null,
    Field5_Type: null,
    Field5_Required: false,

    Currency_Required: false,
    FX_Required: false,
    Display_Formula: "Field1 + Field2 + Field3",
    Notes: "Basis: Lohnausweis des Arbeitgebers. Alle Nebeneinkünfte sind steuerbar."
  },

  // ============================================================
  // INDEX 102 - Nebenerwerb Person 1
  // ============================================================
  {
    Canton: "ZH",
    Index: "102",
    Tax_Year: 2024,
    Main_Category: "Einkünfte aus unselbständiger Erwerbstätigkeit",
    Sub_Category: "Nebenerwerb",
    Person: "Person 1",

    Legal_Reference_Canton: "§ 17 Abs. 1 StG ZH",
    Legal_Reference_Federal: "Art. 17 Abs. 1 DBG",

    Rational_Explanation: "Einkünfte aus Nebenerwerb umfassen alle Einkommen aus unselbständiger Erwerbstätigkeit, die zusätzlich zum Haupterwerb ausgeübt werden. Dies können regelmässige Nebenbeschäftigungen oder gelegentliche Tätigkeiten sein. Auch Nebenerwerb muss vollumfänglich als Einkommen deklariert werden und wird mit dem Haupterwerb zusammengezählt.",

    Deductibility_Rules: "Vollumfänglich steuerbar zu 100%",
    Max_Deductible: "Nicht zutreffend (Einkommensposition)",

    Limitations: "Lohnausweis oder Bescheinigung des Arbeitgebers erforderlich. Berufsauslagen können pauschal oder effektiv geltend gemacht werden.",

    Calculation_Method: "Bruttolohn gemäss Lohnausweis der Nebenerwerbstätigkeit. Bei mehreren Nebenerwerben: Summe aller Nebeneinkommen.",

    Source: "https://www.zh.ch/de/steuern-finanzen/steuern/steuererklarung.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Zürich, Seite 8, Ziffer 1.2",
    Last_Updated: admin.firestore.FieldValue.serverTimestamp(),
    Verification_Status: "verified",

    Field1_Name_DE: "Bruttolohn Nebenerwerb",
    Field1_Type: "currency",
    Field1_Required: true,

    Field2_Name_DE: null,
    Field2_Type: null,
    Field2_Required: false,

    Field3_Name_DE: null,
    Field3_Type: null,
    Field3_Required: false,

    Field4_Name_DE: null,
    Field4_Type: null,
    Field4_Required: false,

    Field5_Name_DE: null,
    Field5_Type: null,
    Field5_Required: false,

    Currency_Required: false,
    FX_Required: false,
    Display_Formula: "Field1",
    Notes: "Nebenerwerb = zusätzliche Erwerbstätigkeit neben Haupterwerb"
  },

  // ============================================================
  // INDEX 103 - Nebenerwerb Person 2
  // ============================================================
  {
    Canton: "ZH",
    Index: "103",
    Tax_Year: 2024,
    Main_Category: "Einkünfte aus unselbständiger Erwerbstätigkeit",
    Sub_Category: "Nebenerwerb",
    Person: "Person 2",

    Legal_Reference_Canton: "§ 17 Abs. 1 StG ZH",
    Legal_Reference_Federal: "Art. 17 Abs. 1 DBG",

    Rational_Explanation: "Einkünfte aus Nebenerwerb umfassen alle Einkommen aus unselbständiger Erwerbstätigkeit, die zusätzlich zum Haupterwerb ausgeübt werden. Dies können regelmässige Nebenbeschäftigungen oder gelegentliche Tätigkeiten sein. Auch Nebenerwerb muss vollumfänglich als Einkommen deklariert werden und wird mit dem Haupterwerb zusammengezählt.",

    Deductibility_Rules: "Vollumfänglich steuerbar zu 100%",
    Max_Deductible: "Nicht zutreffend (Einkommensposition)",

    Limitations: "Lohnausweis oder Bescheinigung des Arbeitgebers erforderlich. Berufsauslagen können pauschal oder effektiv geltend gemacht werden.",

    Calculation_Method: "Bruttolohn gemäss Lohnausweis der Nebenerwerbstätigkeit. Bei mehreren Nebenerwerben: Summe aller Nebeneinkommen.",

    Source: "https://www.zh.ch/de/steuern-finanzen/steuern/steuererklarung.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Zürich, Seite 8, Ziffer 1.2",
    Last_Updated: admin.firestore.FieldValue.serverTimestamp(),
    Verification_Status: "verified",

    Field1_Name_DE: "Bruttolohn Nebenerwerb",
    Field1_Type: "currency",
    Field1_Required: true,

    Field2_Name_DE: null,
    Field2_Type: null,
    Field2_Required: false,

    Field3_Name_DE: null,
    Field3_Type: null,
    Field3_Required: false,

    Field4_Name_DE: null,
    Field4_Type: null,
    Field4_Required: false,

    Field5_Name_DE: null,
    Field5_Type: null,
    Field5_Required: false,

    Currency_Required: false,
    FX_Required: false,
    Display_Formula: "Field1",
    Notes: "Nebenerwerb = zusätzliche Erwerbstätigkeit neben Haupterwerb"
  },

  // ============================================================
  // INDEX 120 - Selbständig Haupterwerb Person 1
  // ============================================================
  {
    Canton: "ZH",
    Index: "120",
    Tax_Year: 2024,
    Main_Category: "Einkünfte aus selbständiger Erwerbstätigkeit",
    Sub_Category: "Haupterwerb",
    Person: "Person 1",

    Legal_Reference_Canton: "§ 18 Abs. 1 StG ZH",
    Legal_Reference_Federal: "Art. 18 Abs. 1 DBG",

    Rational_Explanation: "Das Nettoeinkommen aus selbständiger Haupterwerbstätigkeit umfasst alle Geschäftserträge abzüglich der geschäftsmässig begründeten Aufwendungen. Selbständigerwerbende sind Einzelfirmeninhaber, Teilhaber von Personengesellschaften und stille Gesellschafter. Das Einkommen wird nach kaufmännischer Buchhaltung ermittelt und im Hilfsblatt A detailliert aufgeführt.",

    Deductibility_Rules: "Vollumfänglich steuerbar zu 100%",
    Max_Deductible: "Nicht zutreffend (Einkommensposition)",

    Limitations: "Hilfsblatt A (Erfolgsrechnung) zwingend erforderlich. Ordnungsgemässe Buchhaltung muss geführt werden. AHV/IV-Beiträge können abgezogen werden (in Hilfsblatt A). Private Anteile (z.B. Privatanteil Auto) müssen ausgeschieden werden.",

    Calculation_Method: "Geschäftserträge minus geschäftsmässig begründete Aufwendungen = Nettoeinkommen. Detaillierte Berechnung im Hilfsblatt A. Basis: Erfolgsrechnung der kaufmännischen Buchhaltung.",

    Source: "https://www.zh.ch/de/steuern-finanzen/steuern/steuererklarung.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Zürich, Seite 9, Ziffer 2.1; Merkblatt zum Hilfsblatt A",
    Last_Updated: admin.firestore.FieldValue.serverTimestamp(),
    Verification_Status: "verified",

    Field1_Name_DE: "Nettoeinkommen",
    Field1_Type: "currency",
    Field1_Required: true,

    Field2_Name_DE: null,
    Field2_Type: null,
    Field2_Required: false,

    Field3_Name_DE: null,
    Field3_Type: null,
    Field3_Required: false,

    Field4_Name_DE: null,
    Field4_Type: null,
    Field4_Required: false,

    Field5_Name_DE: null,
    Field5_Type: null,
    Field5_Required: false,

    Currency_Required: false,
    FX_Required: false,
    Display_Formula: "Field1",
    Notes: "Hilfsblatt A muss ausgefüllt und beigelegt werden. Nettoeinkommen = Ertrag minus Aufwand."
  },

  // ============================================================
  // INDEX 121 - Selbständig Haupterwerb Person 2
  // ============================================================
  {
    Canton: "ZH",
    Index: "121",
    Tax_Year: 2024,
    Main_Category: "Einkünfte aus selbständiger Erwerbstätigkeit",
    Sub_Category: "Haupterwerb",
    Person: "Person 2",

    Legal_Reference_Canton: "§ 18 Abs. 1 StG ZH",
    Legal_Reference_Federal: "Art. 18 Abs. 1 DBG",

    Rational_Explanation: "Das Nettoeinkommen aus selbständiger Haupterwerbstätigkeit umfasst alle Geschäftserträge abzüglich der geschäftsmässig begründeten Aufwendungen. Selbständigerwerbende sind Einzelfirmeninhaber, Teilhaber von Personengesellschaften und stille Gesellschafter. Das Einkommen wird nach kaufmännischer Buchhaltung ermittelt und im Hilfsblatt A detailliert aufgeführt.",

    Deductibility_Rules: "Vollumfänglich steuerbar zu 100%",
    Max_Deductible: "Nicht zutreffend (Einkommensposition)",

    Limitations: "Hilfsblatt A (Erfolgsrechnung) zwingend erforderlich. Ordnungsgemässe Buchhaltung muss geführt werden. AHV/IV-Beiträge können abgezogen werden (in Hilfsblatt A). Private Anteile (z.B. Privatanteil Auto) müssen ausgeschieden werden.",

    Calculation_Method: "Geschäftserträge minus geschäftsmässig begründete Aufwendungen = Nettoeinkommen. Detaillierte Berechnung im Hilfsblatt A. Basis: Erfolgsrechnung der kaufmännischen Buchhaltung.",

    Source: "https://www.zh.ch/de/steuern-finanzen/steuern/steuererklarung.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Zürich, Seite 9, Ziffer 2.1; Merkblatt zum Hilfsblatt A",
    Last_Updated: admin.firestore.FieldValue.serverTimestamp(),
    Verification_Status: "verified",

    Field1_Name_DE: "Nettoeinkommen",
    Field1_Type: "currency",
    Field1_Required: true,

    Field2_Name_DE: null,
    Field2_Type: null,
    Field2_Required: false,

    Field3_Name_DE: null,
    Field3_Type: null,
    Field3_Required: false,

    Field4_Name_DE: null,
    Field4_Type: null,
    Field4_Required: false,

    Field5_Name_DE: null,
    Field5_Type: null,
    Field5_Required: false,

    Currency_Required: false,
    FX_Required: false,
    Display_Formula: "Field1",
    Notes: "Hilfsblatt A muss ausgefüllt und beigelegt werden. Nettoeinkommen = Ertrag minus Aufwand."
  },

  // ============================================================
  // INDEX 130 - AHV/IV Renten Person 1
  // ============================================================
  {
    Canton: "ZH",
    Index: "130",
    Tax_Year: 2024,
    Main_Category: "Einkünfte aus Sozial- und anderen Versicherungen",
    Sub_Category: "AHV- / IV-Renten",
    Person: "Person 1",

    Legal_Reference_Canton: "§ 22 Abs. 1 StG ZH",
    Legal_Reference_Federal: "Art. 22 Abs. 1 DBG",

    Rational_Explanation: "AHV- und IV-Renten (Alters- und Hinterlassenenversicherung sowie Invalidenversicherung) sind vollumfänglich steuerbar und müssen zu 100% als Einkommen deklariert werden. Dies umfasst die ordentlichen Renten der ersten Säule. Ergänzungsleistungen, Hilflosenentschädigungen und Assistenzbeiträge sind hingegen steuerfrei.",

    Deductibility_Rules: "Vollumfänglich steuerbar zu 100%",
    Max_Deductible: "Nicht zutreffend (Einkommensposition)",

    Limitations: "Rentenverfügung oder Jahresmeldung der Ausgleichskasse als Nachweis erforderlich. Nur die ordentliche Rente ist steuerbar. Ergänzungsleistungen (EL), Hilflosenentschädigungen und ähnliche Unterstützungsleistungen sind nicht steuerbar und dürfen nicht deklariert werden.",

    Calculation_Method: "Bruttobetrag der AHV- oder IV-Rente gemäss Rentenverfügung bzw. Jahresmeldung der Ausgleichskasse. Keine Abzüge oder Kürzungen vornehmen - voller Rentenbetrag.",

    Source: "https://www.zh.ch/de/steuern-finanzen/steuern/steuererklarung.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Zürich, Seite 10, Ziffer 3.1; Merkblatt zur Steuerbarkeit von Renten",
    Last_Updated: admin.firestore.FieldValue.serverTimestamp(),
    Verification_Status: "verified",

    Field1_Name_DE: "Rentenbetrag (100%)",
    Field1_Type: "currency",
    Field1_Required: true,

    Field2_Name_DE: null,
    Field2_Type: null,
    Field2_Required: false,

    Field3_Name_DE: null,
    Field3_Type: null,
    Field3_Required: false,

    Field4_Name_DE: null,
    Field4_Type: null,
    Field4_Required: false,

    Field5_Name_DE: null,
    Field5_Type: null,
    Field5_Required: false,

    Currency_Required: false,
    FX_Required: false,
    Display_Formula: "Field1",
    Notes: "AHV/IV-Renten zu 100% steuerbar. Ergänzungsleistungen sind NICHT steuerbar."
  },

  // ============================================================
  // INDEX 131 - AHV/IV Renten Person 2
  // ============================================================
  {
    Canton: "ZH",
    Index: "131",
    Tax_Year: 2024,
    Main_Category: "Einkünfte aus Sozial- und anderen Versicherungen",
    Sub_Category: "AHV- / IV-Renten",
    Person: "Person 2",

    Legal_Reference_Canton: "§ 22 Abs. 1 StG ZH",
    Legal_Reference_Federal: "Art. 22 Abs. 1 DBG",

    Rational_Explanation: "AHV- und IV-Renten (Alters- und Hinterlassenenversicherung sowie Invalidenversicherung) sind vollumfänglich steuerbar und müssen zu 100% als Einkommen deklariert werden. Dies umfasst die ordentlichen Renten der ersten Säule. Ergänzungsleistungen, Hilflosenentschädigungen und Assistenzbeiträge sind hingegen steuerfrei.",

    Deductibility_Rules: "Vollumfänglich steuerbar zu 100%",
    Max_Deductible: "Nicht zutreffend (Einkommensposition)",

    Limitations: "Rentenverfügung oder Jahresmeldung der Ausgleichskasse als Nachweis erforderlich. Nur die ordentliche Rente ist steuerbar. Ergänzungsleistungen (EL), Hilflosenentschädigungen und ähnliche Unterstützungsleistungen sind nicht steuerbar und dürfen nicht deklariert werden.",

    Calculation_Method: "Bruttobetrag der AHV- oder IV-Rente gemäss Rentenverfügung bzw. Jahresmeldung der Ausgleichskasse. Keine Abzüge oder Kürzungen vornehmen - voller Rentenbetrag.",

    Source: "https://www.zh.ch/de/steuern-finanzen/steuern/steuererklarung.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Zürich, Seite 10, Ziffer 3.1; Merkblatt zur Steuerbarkeit von Renten",
    Last_Updated: admin.firestore.FieldValue.serverTimestamp(),
    Verification_Status: "verified",

    Field1_Name_DE: "Rentenbetrag (100%)",
    Field1_Type: "currency",
    Field1_Required: true,

    Field2_Name_DE: null,
    Field2_Type: null,
    Field2_Required: false,

    Field3_Name_DE: null,
    Field3_Type: null,
    Field3_Required: false,

    Field4_Name_DE: null,
    Field4_Type: null,
    Field4_Required: false,

    Field5_Name_DE: null,
    Field5_Type: null,
    Field5_Required: false,

    Currency_Required: false,
    FX_Required: false,
    Display_Formula: "Field1",
    Notes: "AHV/IV-Renten zu 100% steuerbar. Ergänzungsleistungen sind NICHT steuerbar."
  },

  // ============================================================
  // INDEX 140 - Arbeitslosenentschädigung Person 1
  // ============================================================
  {
    Canton: "ZH",
    Index: "140",
    Tax_Year: 2024,
    Main_Category: "Einkünfte aus Sozial- und anderen Versicherungen",
    Sub_Category: "Erwerbsausfallentschädigungen aus Arbeitslosenversicherung",
    Person: "Person 1",

    Legal_Reference_Canton: "§ 22 Abs. 1 StG ZH",
    Legal_Reference_Federal: "Art. 23 lit. a DBG",

    Rational_Explanation: "Arbeitslosenentschädigungen aus der ALV (Arbeitslosenversicherung) sind Ersatzeinkünfte für den Erwerbsausfall und müssen vollumfänglich zu 100% als Einkommen versteuert werden. Dies gilt auch für Kurzarbeitsentschädigungen und Insolvenzentschädigungen. Die Taggelder der Arbeitslosenkasse werden wie reguläres Einkommen behandelt.",

    Deductibility_Rules: "Vollumfänglich steuerbar zu 100%",
    Max_Deductible: "Nicht zutreffend (Einkommensposition)",

    Limitations: "Bescheinigung der Arbeitslosenkasse (ALV) über die erhaltenen Taggelder erforderlich. Stellensuchkosten während der Arbeitslosigkeit können als Gewinnungskosten abgezogen werden. Weiterbildungskosten sind ebenfalls abziehbar.",

    Calculation_Method: "Summe aller erhaltenen Arbeitslosentaggelder gemäss Bescheinigung der Arbeitslosenkasse. Der volle Betrag ohne Abzüge ist zu deklarieren.",

    Source: "https://www.zh.ch/de/steuern-finanzen/steuern/steuererklarung.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Zürich, Seite 10, Ziffer 3.3",
    Last_Updated: admin.firestore.FieldValue.serverTimestamp(),
    Verification_Status: "verified",

    Field1_Name_DE: "Arbeitslosentaggelder",
    Field1_Type: "currency",
    Field1_Required: true,

    Field2_Name_DE: null,
    Field2_Type: null,
    Field2_Required: false,

    Field3_Name_DE: null,
    Field3_Type: null,
    Field3_Required: false,

    Field4_Name_DE: null,
    Field4_Type: null,
    Field4_Required: false,

    Field5_Name_DE: null,
    Field5_Type: null,
    Field5_Required: false,

    Currency_Required: false,
    FX_Required: false,
    Display_Formula: "Field1",
    Notes: "ALV-Taggelder zu 100% steuerbar. Stellensuchkosten sind abziehbar."
  },

  // ============================================================
  // INDEX 141 - Arbeitslosenentschädigung Person 2
  // ============================================================
  {
    Canton: "ZH",
    Index: "141",
    Tax_Year: 2024,
    Main_Category: "Einkünfte aus Sozial- und anderen Versicherungen",
    Sub_Category: "Erwerbsausfallentschädigungen aus Arbeitslosenversicherung",
    Person: "Person 2",

    Legal_Reference_Canton: "§ 22 Abs. 1 StG ZH",
    Legal_Reference_Federal: "Art. 23 lit. a DBG",

    Rational_Explanation: "Arbeitslosenentschädigungen aus der ALV (Arbeitslosenversicherung) sind Ersatzeinkünfte für den Erwerbsausfall und müssen vollumfänglich zu 100% als Einkommen versteuert werden. Dies gilt auch für Kurzarbeitsentschädigungen und Insolvenzentschädigungen. Die Taggelder der Arbeitslosenkasse werden wie reguläres Einkommen behandelt.",

    Deductibility_Rules: "Vollumfänglich steuerbar zu 100%",
    Max_Deductible: "Nicht zutreffend (Einkommensposition)",

    Limitations: "Bescheinigung der Arbeitslosenkasse (ALV) über die erhaltenen Taggelder erforderlich. Stellensuchkosten während der Arbeitslosigkeit können als Gewinnungskosten abgezogen werden. Weiterbildungskosten sind ebenfalls abziehbar.",

    Calculation_Method: "Summe aller erhaltenen Arbeitslosentaggelder gemäss Bescheinigung der Arbeitslosenkasse. Der volle Betrag ohne Abzüge ist zu deklarieren.",

    Source: "https://www.zh.ch/de/steuern-finanzen/steuern/steuererklarung.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Zürich, Seite 10, Ziffer 3.3",
    Last_Updated: admin.firestore.FieldValue.serverTimestamp(),
    Verification_Status: "verified",

    Field1_Name_DE: "Arbeitslosentaggelder",
    Field1_Type: "currency",
    Field1_Required: true,

    Field2_Name_DE: null,
    Field2_Type: null,
    Field2_Required: false,

    Field3_Name_DE: null,
    Field3_Type: null,
    Field3_Required: false,

    Field4_Name_DE: null,
    Field4_Type: null,
    Field4_Required: false,

    Field5_Name_DE: null,
    Field5_Type: null,
    Field5_Required: false,

    Currency_Required: false,
    FX_Required: false,
    Display_Formula: "Field1",
    Notes: "ALV-Taggelder zu 100% steuerbar. Stellensuchkosten sind abziehbar."
  }
];

/**
 * Upload all indexes to Firestore
 */
async function uploadIndexes() {
  console.log('========================================');
  console.log('Zürich Tax Index Database Upload');
  console.log('========================================');
  console.log(`Project: ${admin.app().options.projectId}`);
  console.log(`Collection: taxIndexes`);
  console.log(`Tax Year: 2024`);
  console.log(`Canton: ZH (Zürich)`);
  console.log(`Indexes to upload: ${zhIndexes.length}`);
  console.log('========================================\n');

  const batch = db.batch();
  let uploadCount = 0;

  for (const entry of zhIndexes) {
    const docId = `${entry.Canton}_${entry.Index}_${entry.Tax_Year}`;
    const docRef = db.collection('taxIndexes').doc(docId);

    batch.set(docRef, entry);
    uploadCount++;

    console.log(`[${uploadCount}/${zhIndexes.length}] Prepared: ${docId} - ${entry.Sub_Category} (${entry.Person || 'N/A'})`);
  }

  try {
    await batch.commit();
    console.log('\n========================================');
    console.log(`SUCCESS: Uploaded ${uploadCount} tax indexes to Firestore`);
    console.log('========================================\n');

    // Print summary
    console.log('UPLOAD SUMMARY:');
    console.log('---------------');
    zhIndexes.forEach((entry, idx) => {
      console.log(`${idx + 1}. Index ${entry.Index}: ${entry.Sub_Category} (${entry.Person || 'N/A'})`);
      console.log(`   Legal Ref: ${entry.Legal_Reference_Canton} | ${entry.Legal_Reference_Federal}`);
      console.log(`   Status: ${entry.Verification_Status}`);
    });

    console.log('\n========================================');
    console.log('Next Steps:');
    console.log('1. Verify data in Firebase Console');
    console.log('2. Test tax index retrieval in iOS app');
    console.log('3. Continue with remaining 85+ indexes');
    console.log('========================================');

  } catch (error) {
    console.error('\nERROR during upload:', error);
    throw error;
  }
}

// Run the upload
uploadIndexes()
  .then(() => {
    console.log('\nUpload completed successfully!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\nUpload failed:', error);
    process.exit(1);
  });
