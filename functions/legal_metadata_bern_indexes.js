/**
 * Legal Metadata for Bern (BE) Canton Tax Indexes (2024)
 * Based on Swiss Federal Tax Law (DBG) and Bern Cantonal Tax Law (StG BE)
 *
 * Each index includes:
 * - Legal_Reference_Canton: Bern cantonal law reference (Art. StG BE)
 * - Legal_Reference_Federal: Swiss federal law reference (Art. DBG)
 * - Rational_Explanation: Detailed explanation in German
 * - Deductibility_Rules: Tax treatment rules
 * - Max_Deductible: Maximum amounts / limits (Bern-specific 2024)
 * - Limitations: Documentation requirements
 *
 * KEY BERN-SPECIFIC LIMITS FOR 2024:
 * - Säule 3a: CHF 7'056 (with 2nd pillar) / CHF 35'280 (without)
 * - Kinderabzug: CHF 8'300 (Kanton/Gemeinde), CHF 6'700 (Bund)
 * - Kinderbetreuung: CHF 16'000 (Kanton/Gemeinde), CHF 25'500 (Bund)
 * - Pauschalabzug Berufskosten: 3% des Nettolohns, min. CHF 2'000, max. CHF 4'000
 * - Fahrkosten: max. CHF 7'000 (Kanton), CHF 3'000 (Bund)
 * - Verpflegung: CHF 15/Tag, max. CHF 3'200/Jahr
 * - Nebenerwerb: 20% pauschal, min. CHF 800, max. CHF 2'400
 */

const legalMetadataBern = {
  // ==========================================
  // INCOME INDEXES - Employment
  // ==========================================

  "2.21": {
    Canton: "BE",
    Index: "2.21",
    Tax_Year: 2024,
    Main_Category: "Einkommen",
    Sub_Category: "Unselbständige Erwerbstätigkeit",
    Person: "",
    Description: "Einkünfte aus unselbstständiger Erwerbstätigkeit (Nettolohn)",
    Legal_Reference_Canton: "Art. 22 StG BE",
    Legal_Reference_Federal: "Art. 17 DBG",
    Rational_Explanation: "Alle Einkünfte aus unselbständiger Erwerbstätigkeit sind steuerbar. Dazu gehören der Nettolohn aus Haupt- und Nebenerwerb, Entschädigungen die nicht im Nettolohn enthalten sind (wie Spesenvergütungen ohne Nachweispflicht), sowie Tag- und Sitzungsgelder, Verwaltungsratshonorare und Tantiemen. Der Nettolohn entspricht dem Bruttolohn abzüglich gesetzlicher Arbeitnehmerbeiträge (AHV/IV/EO/ALV).",
    Deductibility_Rules: "Vollumfänglich steuerbar zu 100%. Der Nettolohn gemäss Lohnausweis ist ohne weitere Abzüge als Einkommen zu deklarieren.",
    Max_Deductible: "Nicht zutreffend (Einkommensposition, kein Abzug)",
    Limitations: "Lohnausweis des Arbeitgebers erforderlich. Der deklarierte Betrag muss mit dem Lohnausweis übereinstimmen. Pauschalabzug für Berufsauslagen separat unter Ziffer 6 (3% des Nettolohns, min. CHF 2'000, max. CHF 4'000).",
    Source: "https://www.be.ch/de/start/themen/steuern.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Bern",
    Verification_Status: "verified"
  },

  // ==========================================
  // INCOME INDEXES - Self-Employment
  // ==========================================

  "9210": {
    Canton: "BE",
    Index: "9210",
    Tax_Year: 2024,
    Main_Category: "Einkommen",
    Sub_Category: "Selbständige Erwerbstätigkeit",
    Person: "",
    Description: "Steuerbarer Erfolg aus selbstständiger Erwerbstätigkeit (Kanton)",
    Legal_Reference_Canton: "Art. 23 StG BE",
    Legal_Reference_Federal: "Art. 18 DBG",
    Rational_Explanation: "Der steuerbare Erfolg aus selbstständiger Erwerbstätigkeit umfasst alle Einkünfte aus Geschäftstätigkeit, Handel, Gewerbe oder freiberuflicher Tätigkeit. Er wird durch die Gegenüberstellung der Geschäftserträge und der geschäftsmässig begründeten Aufwendungen ermittelt. Für die kantonale Steuer gelten teilweise andere Bewertungsregeln als für die direkte Bundessteuer.",
    Deductibility_Rules: "Vollumfänglich steuerbar zu 100%. Der Geschäftserfolg wird gemäss kaufmännischer Buchhaltung ermittelt.",
    Max_Deductible: "Nicht zutreffend (Einkommensposition, kein Abzug)",
    Limitations: "Jahresrechnung erforderlich (Erfolgsrechnung und Bilanz). Bei Umsatz über CHF 500'000: Prüfungspflicht durch zugelassenen Revisor. Separate Deklaration für Kanton (9210) und Bund (9220) wegen unterschiedlicher Bewertungsvorschriften.",
    Source: "https://www.be.ch/de/start/themen/steuern.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Bern, Formular 9",
    Verification_Status: "verified"
  },

  "9220": {
    Canton: "BE",
    Index: "9220",
    Tax_Year: 2024,
    Main_Category: "Einkommen",
    Sub_Category: "Selbständige Erwerbstätigkeit",
    Person: "",
    Description: "Steuerbarer Erfolg aus selbstständiger Erwerbstätigkeit (Bund)",
    Legal_Reference_Canton: "Art. 23 StG BE",
    Legal_Reference_Federal: "Art. 18 DBG",
    Rational_Explanation: "Der steuerbare Erfolg aus selbstständiger Erwerbstätigkeit für die direkte Bundessteuer wird nach den Vorschriften des DBG ermittelt. Insbesondere bei der Bewertung von Liegenschaften und bei den Abschreibungssätzen können Unterschiede zur kantonalen Berechnung bestehen.",
    Deductibility_Rules: "Vollumfänglich steuerbar zu 100%. Der Geschäftserfolg wird nach DBG-Vorschriften ermittelt.",
    Max_Deductible: "Nicht zutreffend (Einkommensposition, kein Abzug)",
    Limitations: "Jahresrechnung erforderlich. Separate Deklaration für Bund (9220) und Kanton (9210) wegen unterschiedlicher Bewertungsvorschriften gemäss DBG vs. StG BE.",
    Source: "https://www.estv.admin.ch",
    Source_Document: "Wegleitung zur Steuererklärung 2024 direkte Bundessteuer, Formular 9",
    Verification_Status: "verified"
  },

  "28": {
    Canton: "BE",
    Index: "28",
    Tax_Year: 2024,
    Main_Category: "Vermögen",
    Sub_Category: "Selbständige Erwerbstätigkeit",
    Person: "",
    Description: "Steuerbares Eigenkapital aus selbstständiger Erwerbstätigkeit",
    Legal_Reference_Canton: "Art. 38 Abs. 2 StG BE",
    Legal_Reference_Federal: "Nicht zutreffend (nur Vermögenssteuer kantonal)",
    Rational_Explanation: "Das steuerbare Eigenkapital aus selbstständiger Erwerbstätigkeit entspricht dem Geschäftsvermögen abzüglich der Geschäftsschulden. Es wird auf Basis der Bilanz ermittelt und unterliegt der kantonalen und kommunalen Vermögenssteuer. Die direkte Bundessteuer kennt keine Vermögenssteuer.",
    Deductibility_Rules: "Vermögenssteuer nur auf Ebene Kanton und Gemeinde. Eigenkapital gemäss Bilanz per 31.12. des Steuerjahres.",
    Max_Deductible: "Nicht zutreffend (Vermögensposition, kein Abzug)",
    Limitations: "Bilanz per 31.12. erforderlich. Das Geschäftsvermögen muss klar vom Privatvermögen getrennt sein.",
    Source: "https://www.be.ch/de/start/themen/steuern.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Bern, Formular 9",
    Verification_Status: "verified"
  },

  // ==========================================
  // INCOME INDEXES - Pensions & Social Security
  // ==========================================

  "2.22": {
    Canton: "BE",
    Index: "2.22",
    Tax_Year: 2024,
    Main_Category: "Einkommen",
    Sub_Category: "Vorsorge",
    Person: "",
    Description: "Renten aus AHV/IV und beruflicher Vorsorge",
    Legal_Reference_Canton: "Art. 22 Abs. 1 lit. b StG BE",
    Legal_Reference_Federal: "Art. 22 DBG",
    Rational_Explanation: "Renten und andere wiederkehrende Leistungen aus AHV, IV, beruflicher Vorsorge (2. Säule), Säule 3a, sowie Renten aus Lebensversicherungen und Unfallversicherungen sind vollumfänglich steuerbar. Dies umfasst AHV- und IV-Renten zu 100%, Pensionskassenrenten, SUVA-Renten aus Arbeitsverhältnis, sowie private Renten aus Säule 3a und Leibrenten.",
    Deductibility_Rules: "Vollumfänglich steuerbar zu 100%. Alle Renten sind ohne Abzüge als Einkommen zu deklarieren.",
    Max_Deductible: "Nicht zutreffend (Einkommensposition, kein Abzug)",
    Limitations: "Rentenausweise der Versicherungen und Vorsorgeeinrichtungen erforderlich. Bei Leibrenten: Versicherungsausweis mit Angabe des steuerbaren Rentenanteils.",
    Source: "https://www.be.ch/de/start/themen/steuern.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Bern, Ziffer 2.22",
    Verification_Status: "verified"
  },

  "2.23": {
    Canton: "BE",
    Index: "2.23",
    Tax_Year: 2024,
    Main_Category: "Einkommen",
    Sub_Category: "Vorsorge",
    Person: "",
    Description: "Netto-Leistungen aus Arbeitslosenversicherung und Erwerbsausfallentschädigungen",
    Legal_Reference_Canton: "Art. 22 Abs. 1 lit. c StG BE",
    Legal_Reference_Federal: "Art. 23 DBG",
    Rational_Explanation: "Netto-Leistungen aus der Arbeitslosenversicherung (ALV), Erwerbsausfallentschädigungen (EO), sowie Taggelder aus Kranken-, Invaliden-, Unfall- oder Militärversicherung sind vollumfänglich steuerbar. Der Begriff 'Netto' bedeutet, dass die Leistungen nach Abzug allfälliger Sozialversicherungsbeiträge zu deklarieren sind.",
    Deductibility_Rules: "Vollumfänglich steuerbar zu 100%. Die Netto-Leistungen gemäss Bescheinigung sind als Einkommen zu deklarieren.",
    Max_Deductible: "Nicht zutreffend (Einkommensposition, kein Abzug)",
    Limitations: "Bescheinigung der Arbeitslosenkasse, Ausgleichskasse oder Versicherung erforderlich.",
    Source: "https://www.be.ch/de/start/themen/steuern.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Bern, Ziffer 2.23",
    Verification_Status: "verified"
  },

  // ==========================================
  // INCOME INDEXES - Support & Other
  // ==========================================

  "2.24": {
    Canton: "BE",
    Index: "2.24",
    Tax_Year: 2024,
    Main_Category: "Einkommen",
    Sub_Category: "Übrige Einkünfte",
    Person: "",
    Description: "Erhaltene Unterhaltsbeiträge (Alimente)",
    Legal_Reference_Canton: "Art. 24 lit. b StG BE",
    Legal_Reference_Federal: "Art. 23 lit. f DBG",
    Rational_Explanation: "Erhaltene Unterhaltsbeiträge vom geschiedenen, gerichtlich oder tatsächlich getrennt lebenden Ehegatten oder Partner sind steuerbar, ebenso Unterhaltsbeiträge für minderjährige Kinder. Die Unterhaltsbeiträge sind beim Empfänger als Einkommen steuerbar und beim Zahler als Abzug zugelassen.",
    Deductibility_Rules: "Vollumfänglich steuerbar zu 100%. Alle erhaltenen Unterhaltsbeiträge sind als Einkommen zu deklarieren.",
    Max_Deductible: "Nicht zutreffend (Einkommensposition, kein Abzug)",
    Limitations: "Scheidungsurteil, Trennungsvereinbarung oder gerichtliche Verfügung erforderlich. Nur rechtlich geschuldete Unterhaltsbeiträge sind steuerbar.",
    Source: "https://www.be.ch/de/start/themen/steuern.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Bern, Ziffer 2.24",
    Verification_Status: "verified"
  },

  "2.25": {
    Canton: "BE",
    Index: "2.25",
    Tax_Year: 2024,
    Main_Category: "Einkommen",
    Sub_Category: "Übrige Einkünfte",
    Person: "",
    Description: "Weitere steuerbare Einkünfte",
    Legal_Reference_Canton: "Art. 24 StG BE",
    Legal_Reference_Federal: "Art. 23 DBG",
    Rational_Explanation: "Unter den weiteren steuerbaren Einkünften sind alle Einkünfte zu erfassen, die nicht bereits unter den anderen Ziffern deklariert wurden. Dies können sein: Einkünfte aus gelegentlichen Tätigkeiten, Entschädigungen für Nutzungsrechte, geldwerte Leistungen, oder andere nicht anderweitig erfasste Einkünfte.",
    Deductibility_Rules: "Vollumfänglich steuerbar zu 100%, sofern nicht ausdrücklich steuerfrei.",
    Max_Deductible: "Nicht zutreffend (Einkommensposition, kein Abzug)",
    Limitations: "Belege und Nachweise für die Art und Höhe der Einkünfte erforderlich.",
    Source: "https://www.be.ch/de/start/themen/steuern.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Bern, Ziffer 2.25",
    Verification_Status: "verified"
  },

  // ==========================================
  // INCOME INDEXES - Securities & Investments
  // ==========================================

  "31": {
    Canton: "BE",
    Index: "31",
    Tax_Year: 2024,
    Main_Category: "Einkommen",
    Sub_Category: "Wertschriften und Guthaben",
    Person: "",
    Description: "Wertschriftenerträge und Lotteriegewinne",
    Legal_Reference_Canton: "Art. 24 lit. a StG BE",
    Legal_Reference_Federal: "Art. 20 Abs. 1 lit. a DBG",
    Rational_Explanation: "Wertschriftenerträge umfassen alle Dividenden, Zinsen, Obligationenerträge und ähnliche Einkünfte aus beweglichem Vermögen. Lotteriegewinne ab CHF 1'000 (Grossgewinne ab CHF 1 Mio.) sind einkommensteuerpflichtig. Bei ausländischen Wertschriften ist die ausländische Quellensteuer anzugeben (für Rückforderung).",
    Deductibility_Rules: "Wertschriftenerträge: vollumfänglich steuerbar. Lotteriegewinne: steuerbar mit Pauschalabzug gemäss Wegleitung.",
    Max_Deductible: "Nicht zutreffend (Einkommensposition). Pauschalabzug für Lotteriegewinne siehe Index 52.",
    Limitations: "Bankbescheinigungen über Wertschriftenerträge erforderlich. Ausländische Quellensteuern separat deklarieren. Total aus Formular 3 übertragen.",
    Source: "https://www.be.ch/de/start/themen/steuern.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Bern, Formular 3",
    Verification_Status: "verified"
  },

  "32": {
    Canton: "BE",
    Index: "32",
    Tax_Year: 2024,
    Main_Category: "Vermögen",
    Sub_Category: "Wertschriften und Guthaben",
    Person: "",
    Description: "Wertschriftenvermögen",
    Legal_Reference_Canton: "Art. 38 Abs. 1 StG BE",
    Legal_Reference_Federal: "Nicht zutreffend (nur Vermögenssteuer kantonal)",
    Rational_Explanation: "Das Wertschriftenvermögen umfasst alle Aktien, Obligationen, Anlagefonds, strukturierte Produkte und sonstigen Wertpapiere zum Kurswert per 31.12. des Steuerjahres. Bankguthaben und Kontostände sind zum Nominalwert zu deklarieren.",
    Deductibility_Rules: "Vermögenssteuer nur auf Ebene Kanton und Gemeinde. Bewertung zum Kurswert per 31.12.",
    Max_Deductible: "Nicht zutreffend (Vermögensposition, kein Abzug)",
    Limitations: "Bankbescheinigungen oder Depotauszüge per 31.12. erforderlich. Total aus Formular 3 übertragen.",
    Source: "https://www.be.ch/de/start/themen/steuern.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Bern, Formular 3",
    Verification_Status: "verified"
  },

  // ==========================================
  // WEALTH INDEXES - Other Assets
  // ==========================================

  "4.1": {
    Canton: "BE",
    Index: "4.1",
    Tax_Year: 2024,
    Main_Category: "Vermögen",
    Sub_Category: "Übriges Vermögen",
    Person: "",
    Description: "Weitere Vermögenswerte (Barschaft, Fahrzeuge, usw.)",
    Legal_Reference_Canton: "Art. 38 StG BE",
    Legal_Reference_Federal: "Nicht zutreffend (nur Vermögenssteuer kantonal)",
    Rational_Explanation: "Weitere Vermögenswerte umfassen Bargeld, Edelmetalle, Schmuck, Kunst, Sammlungen, Motorfahrzeuge und sonstige bewegliche Vermögenswerte. Fahrzeuge werden zum Verkehrswert deklariert (bei Neukauf: Kaufpreis minus lineare Abschreibung; bei Gebrauchtkauf: Kaufpreis).",
    Deductibility_Rules: "Vermögenssteuer nur auf Ebene Kanton und Gemeinde. Bewertung zum Verkehrswert per 31.12.",
    Max_Deductible: "Nicht zutreffend (Vermögensposition, kein Abzug)",
    Limitations: "Bei Fahrzeugen: Fahrzeugausweis und Kaufbeleg. Bei Kunst/Sammlungen: Schätzung oder Kaufbeleg. Bargeld: glaubhafte Deklaration.",
    Source: "https://www.be.ch/de/start/themen/steuern.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Bern, Formular 4",
    Verification_Status: "verified"
  },

  "4.2": {
    Canton: "BE",
    Index: "4.2",
    Tax_Year: 2024,
    Main_Category: "Vermögen",
    Sub_Category: "Versicherungen",
    Person: "",
    Description: "Kapital- und Rentenversicherungen, Steuerwert",
    Legal_Reference_Canton: "Art. 38 Abs. 1 StG BE",
    Legal_Reference_Federal: "Nicht zutreffend (nur Vermögenssteuer kantonal)",
    Rational_Explanation: "Kapital- und Rentenversicherungen (3. Säule b und private Lebensversicherungen) werden zum Rückkaufswert besteuert. Der Steuerwert wird von der Versicherungsgesellschaft jährlich bescheinigt und entspricht dem Rückkaufswert per 31.12. des Steuerjahres.",
    Deductibility_Rules: "Vermögenssteuer nur auf Ebene Kanton und Gemeinde. Bewertung zum Rückkaufswert per 31.12.",
    Max_Deductible: "Nicht zutreffend (Vermögensposition, kein Abzug)",
    Limitations: "Steuerwertbescheinigung der Versicherungsgesellschaft per 31.12. erforderlich.",
    Source: "https://www.be.ch/de/start/themen/steuern.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Bern, Formular 4",
    Verification_Status: "verified"
  },

  // ==========================================
  // PROPERTY INDEXES
  // ==========================================

  "7.0": {
    Canton: "BE",
    Index: "7.0",
    Tax_Year: 2024,
    Main_Category: "Vermögen",
    Sub_Category: "Liegenschaften",
    Person: "",
    Description: "Amtlicher Wert der Liegenschaft",
    Legal_Reference_Canton: "Art. 39 StG BE",
    Legal_Reference_Federal: "Nicht zutreffend (nur Vermögenssteuer kantonal)",
    Rational_Explanation: "Liegenschaften (Grundstücke und Gebäude) werden zum amtlichen Wert besteuert. Der amtliche Wert wird von der Gemeinde festgesetzt und entspricht in der Regel dem Verkehrswert. Photovoltaik-Anlagen auf dem Dach erhöhen den Liegenschaftswert.",
    Deductibility_Rules: "Vermögenssteuer auf Basis des amtlichen Werts. Separate Deklaration von Aufdach-Photovoltaik-Anlagen.",
    Max_Deductible: "Nicht zutreffend (Vermögensposition, kein Abzug)",
    Limitations: "Amtliche Bewertung durch Gemeinde. Bei Photovoltaik: separate Angabe erforderlich.",
    Source: "https://www.be.ch/de/start/themen/steuern.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Bern, Formular 7",
    Verification_Status: "verified"
  },

  "7.1": {
    Canton: "BE",
    Index: "7.1",
    Tax_Year: 2024,
    Main_Category: "Einkommen",
    Sub_Category: "Liegenschaften",
    Person: "",
    Description: "Mietwerte und Erträge aus Liegenschaften",
    Legal_Reference_Canton: "Art. 24 lit. c StG BE",
    Legal_Reference_Federal: "Art. 21 DBG",
    Rational_Explanation: "Zu den Liegenschaftserträgen gehören: Mietwert der selbstbewohnten Liegenschaft, Mietwerte aus vermieteten Wohnungen und Häusern, Bruttoerträge aus vermieteten Ferienwohnungen, Erträge aus Vermietung von Geschäftsräumen, Pachtzinsen, Walderträge, Zinsen aus Baurechten und Quellenrechten, sowie Einkünfte aus Photovoltaik-Anlagen (inkl. Einmal- oder Einspeisevergütungen). Der Mietwert kann zwischen Kanton und Bund unterschiedlich sein.",
    Deductibility_Rules: "Vollumfänglich steuerbar zu 100%. Alle Liegenschaftserträge sind als Einkommen zu deklarieren.",
    Max_Deductible: "Nicht zutreffend (Einkommensposition, kein Abzug). Unterhaltskosten separat abziehbar unter 7.2.",
    Limitations: "Bei vermieteten Objekten: Mietverträge erforderlich. Bei Photovoltaik: Abrechnung des Energieversorgers. Separate Angabe für Kanton und Bund bei unterschiedlichen Mietwerten.",
    Source: "https://www.be.ch/de/start/themen/steuern.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Bern, Formular 7",
    Verification_Status: "verified"
  },

  "7.2": {
    Canton: "BE",
    Index: "7.2",
    Tax_Year: 2024,
    Main_Category: "Abzüge",
    Sub_Category: "Liegenschaften",
    Person: "",
    Description: "Liegenschaftskosten und Verwaltungskosten",
    Legal_Reference_Canton: "Art. 27 StG BE",
    Legal_Reference_Federal: "Art. 32 DBG",
    Rational_Explanation: "Von den Liegenschaftserträgen können die Unterhaltskosten abgezogen werden. Dazu gehören: Liegenschaftssteuer, Baurechtzinsen, Pauschalabzug für Abnutzung bei vermieteten Ferienwohnungen, effektive Unterhaltskosten (inkl. nicht verrechnete Kostenüberschüsse aus Vorjahren), sowie Betriebs- und Verwaltungskosten. Alternativ zu den effektiven Kosten kann ein Pauschalabzug geltend gemacht werden.",
    Deductibility_Rules: "Abziehbar: effektive Unterhaltskosten mit Belegen ODER Pauschalabzug (siehe Wegleitung). Nicht abziehbar: wertvermehrende Investitionen.",
    Max_Deductible: "Pauschalabzug gemäss Wegleitung (Prozentsatz des Mietwerts). Effektive Kosten: unbegrenzt mit Belegen.",
    Limitations: "Bei effektiven Kosten: vollständige Belege erforderlich. Wertvermehrende Aufwendungen (Neu-/Umbauten) sind nicht abziehbar. Energiesparende Investitionen: siehe spezielle Regelung in Wegleitung.",
    Source: "https://www.be.ch/de/start/themen/steuern.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Bern, Formular 7",
    Verification_Status: "verified"
  },

  // ==========================================
  // JOINT OWNERSHIP INDEXES
  // ==========================================

  "8.1": {
    Canton: "BE",
    Index: "8.1",
    Tax_Year: 2024,
    Main_Category: "Einkommen",
    Sub_Category: "Selbständige Erwerbstätigkeit",
    Person: "",
    Description: "Kollektiv-, Kommandit- und einfache Gesellschaften",
    Legal_Reference_Canton: "Art. 23 Abs. 3 StG BE",
    Legal_Reference_Federal: "Art. 18 Abs. 2 DBG",
    Rational_Explanation: "Einkünfte aus Kollektiv-, Kommandit- und einfachen Gesellschaften werden anteilsmässig den Gesellschaftern zugerechnet. Die Gesellschaft ist nicht selbst steuerpflichtig (Transparenzprinzip), sondern die Gesellschafter versteuern ihren Anteil am Geschäftserfolg als Einkommen aus selbstständiger Erwerbstätigkeit.",
    Deductibility_Rules: "Steuerbar: anteilsmässiger Geschäftserfolg gemäss Gesellschaftsvertrag und Jahresrechnung.",
    Max_Deductible: "Nicht zutreffend (Einkommensposition, kein Abzug)",
    Limitations: "Jahresrechnung der Gesellschaft erforderlich. Gesellschaftsvertrag mit Gewinnverteilungsschlüssel. Bestätigung der Gesellschaft über Anteil des Gesellschafters.",
    Source: "https://www.be.ch/de/start/themen/steuern.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Bern, Formular 8",
    Verification_Status: "verified"
  },

  "8.2": {
    Canton: "BE",
    Index: "8.2",
    Tax_Year: 2024,
    Main_Category: "Einkommen",
    Sub_Category: "Selbständige Erwerbstätigkeit",
    Person: "",
    Description: "Baugesellschaften und Konsortien",
    Legal_Reference_Canton: "Art. 23 Abs. 3 StG BE",
    Legal_Reference_Federal: "Art. 18 Abs. 2 DBG",
    Rational_Explanation: "Einkünfte aus Baugesellschaften und Konsortien werden anteilsmässig den Beteiligten zugerechnet. Diese temporären Zusammenschlüsse sind steuerlich transparent, d.h. der Erfolg wird direkt bei den Beteiligten besteuert.",
    Deductibility_Rules: "Steuerbar: anteilsmässiger Erfolg aus der Bau-/Konsortialgeschäftstätigkeit.",
    Max_Deductible: "Nicht zutreffend (Einkommensposition, kein Abzug)",
    Limitations: "Erfolgsrechnung der Baugesellschaft/Konsortium erforderlich. Konsortialvertrag mit Beteiligungsverhältnis. Bestätigung über Anteil des Steuerpflichtigen.",
    Source: "https://www.be.ch/de/start/themen/steuern.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Bern, Formular 8",
    Verification_Status: "verified"
  },

  "8.3": {
    Canton: "BE",
    Index: "8.3",
    Tax_Year: 2024,
    Main_Category: "Einkommen",
    Sub_Category: "Selbständige Erwerbstätigkeit",
    Person: "",
    Description: "Erben- und Miteigentümergemeinschaften",
    Legal_Reference_Canton: "Art. 24 StG BE",
    Legal_Reference_Federal: "Art. 20 Abs. 1 lit. c DBG",
    Rational_Explanation: "Einkünfte aus Erben- und Miteigentümergemeinschaften (z.B. Erträge aus gemeinsam gehaltenen Liegenschaften oder Wertschriften) werden anteilsmässig den Beteiligten zugerechnet. Die Gemeinschaft ist nicht selbst steuerpflichtig.",
    Deductibility_Rules: "Steuerbar: anteilsmässiger Ertrag gemäss Erbquote oder Miteigentumsanteil.",
    Max_Deductible: "Nicht zutreffend (Einkommensposition, kein Abzug)",
    Limitations: "Bei Erbengemeinschaften: Erbteilung oder Erbschein mit Erbquoten. Bei Miteigentum: Grundbuchauszug mit Eigentumsanteilen. Erfolgs- oder Ertragsrechnung der Gemeinschaft.",
    Source: "https://www.be.ch/de/start/themen/steuern.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Bern, Formular 8",
    Verification_Status: "verified"
  },

  // ==========================================
  // DEDUCTION INDEXES - Pensions
  // ==========================================

  "1.1": {
    Canton: "BE",
    Index: "1.1",
    Tax_Year: 2024,
    Main_Category: "Abzüge",
    Sub_Category: "Vorsorge",
    Person: "",
    Description: "Beiträge an berufliche Vorsorge und Säule 3a",
    Legal_Reference_Canton: "Art. 31 Abs. 1 lit. d StG BE",
    Legal_Reference_Federal: "Art. 33 Abs. 1 lit. d DBG",
    Rational_Explanation: "Beiträge an die berufliche Vorsorge (Säule 2), die nicht im Nettolohn berücksichtigt sind und nicht als Aufwand verbucht wurden, sowie Beiträge an die gebundene Selbstvorsorge (Säule 3a) gemäss Bescheinigung sind abzugsfähig. Für Säule 3a gelten Maximalbeiträge.",
    Deductibility_Rules: "Vollumfänglich abziehbar bis zu den gesetzlichen Höchstbeträgen.",
    Max_Deductible: "Säule 3a 2024: CHF 7'056 (mit 2. Säule) bzw. CHF 35'280 (ohne 2. Säule, max. 20% des Erwerbseinkommens). Säule 2: gemäss Bescheinigung.",
    Limitations: "Einzahlungsbestätigung der Pensionskasse oder Säule 3a-Institution erforderlich. Säule 3a: nur bei anerkannten Vorsorgestiftungen/Versicherungen.",
    Source: "https://www.be.ch/de/start/themen/steuern.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Bern, Ziffer 1.1",
    Verification_Status: "verified"
  },

  "1.2": {
    Canton: "BE",
    Index: "1.2",
    Tax_Year: 2024,
    Main_Category: "Abzüge",
    Sub_Category: "Vorsorge",
    Person: "",
    Description: "Zweiverdienerabzug",
    Legal_Reference_Canton: "Art. 32 Abs. 2 StG BE",
    Legal_Reference_Federal: "Art. 33 Abs. 2 DBG",
    Rational_Explanation: "Der Zweiverdienerabzug wird bei verheirateten oder in eingetragener Partnerschaft lebenden Paaren gewährt, wenn beide Partner erwerbstätig sind. Der Abzug beträgt einen bestimmten Prozentsatz des niedrigeren Erwerbseinkommens und soll die höhere steuerliche Belastung von Zweitverdienern mildern.",
    Deductibility_Rules: "Abziehbar: Prozentsatz des niedrigeren Erwerbseinkommens gemäss Wegleitung.",
    Max_Deductible: "Gemäss Wegleitung (unterschiedlich für Kanton/Gemeinde und Bund). Automatische Berechnung durch Steuerverwaltung.",
    Limitations: "Beide Partner müssen erwerbstätig sein. Der Abzug wird von der Steuerverwaltung automatisch berechnet und gewährt.",
    Source: "https://www.be.ch/de/start/themen/steuern.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Bern, Ziffer 1.2",
    Verification_Status: "verified"
  },

  // ==========================================
  // DEDUCTION INDEXES - Childcare
  // ==========================================

  "2.1": {
    Canton: "BE",
    Index: "2.1",
    Tax_Year: 2024,
    Main_Category: "Abzüge",
    Sub_Category: "Kinderbetreuung",
    Person: "",
    Description: "Abzug für bezahlte Kinderbetreuungskosten",
    Legal_Reference_Canton: "Art. 31 Abs. 1 lit. e StG BE",
    Legal_Reference_Federal: "Art. 33 Abs. 3 DBG",
    Rational_Explanation: "Kosten für die Drittbetreuung von Kindern unter 14 Jahren (durch Kitas, Tagesfamilien, Krippen, Horte usw.) können abgezogen werden, soweit die Eltern erwerbstätig, ausbildungsbedingt abwesend oder krankheitsbedingt verhindert sind. Seit 2024 wurde der Maximalbetrag auf kantonaler Ebene auf CHF 16'000 erhöht.",
    Deductibility_Rules: "Abziehbar: nachgewiesene Kosten für Drittbetreuung bis zu den Höchstbeträgen.",
    Max_Deductible: "Kanton/Gemeinde BE 2024: CHF 16'000 pro Kind. Direkte Bundessteuer: CHF 25'500 pro Kind (für beide Elternteile zusammen).",
    Limitations: "Rechnung der Betreuungseinrichtung erforderlich. Nur Drittbetreuung abziehbar (nicht Verwandte, ausser in qualifizierter Betreuungseinrichtung). Beide Elternteile müssen erwerbstätig sein.",
    Source: "https://www.be.ch/de/start/themen/steuern.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Bern, Ziffer 2.1; Steuergesetzrevision 2024",
    Verification_Status: "verified"
  },

  "2.3": {
    Canton: "BE",
    Index: "2.3",
    Tax_Year: 2024,
    Main_Category: "Abzüge",
    Sub_Category: "Vorsorge",
    Person: "",
    Description: "Als Nichterwerbstätige/-r bezahlte AHV/IV/EO-Beiträge",
    Legal_Reference_Canton: "Art. 31 Abs. 1 lit. d StG BE",
    Legal_Reference_Federal: "Art. 33 Abs. 1 lit. d DBG",
    Rational_Explanation: "Nichterwerbstätige Personen (z.B. Hausfrauen/Hausmänner ohne Erwerbseinkommen) müssen AHV/IV/EO-Beiträge bezahlen. Diese Beiträge sind vollumfänglich vom steuerbaren Einkommen abziehbar.",
    Deductibility_Rules: "Vollumfänglich abziehbar gemäss Einzahlungsbestätigung.",
    Max_Deductible: "Keine Begrenzung. Abziehbar: effektiv bezahlter Betrag gemäss Bescheinigung.",
    Limitations: "Einzahlungsbestätigung der Ausgleichskasse erforderlich.",
    Source: "https://www.be.ch/de/start/themen/steuern.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Bern, Ziffer 2.3",
    Verification_Status: "verified"
  },

  // ==========================================
  // DEDUCTION INDEXES - Securities
  // ==========================================

  "51": {
    Canton: "BE",
    Index: "51",
    Tax_Year: 2024,
    Main_Category: "Abzüge",
    Sub_Category: "Wertschriften und Guthaben",
    Person: "",
    Description: "Nachweisbare Kosten für Wertschriftenverwaltung",
    Legal_Reference_Canton: "Art. 27 Abs. 1 lit. b StG BE",
    Legal_Reference_Federal: "Art. 32 Abs. 2 DBG",
    Rational_Explanation: "Kosten für die Verwaltung des beweglichen Privatvermögens (Wertschriften) sind abzugsfähig. Dazu gehören Depotgebühren, Verwaltungsgebühren, Courtagen bei Wertschriftenkäufen/-verkäufen, sowie Beratungskosten. Die Kosten müssen nachgewiesen werden.",
    Deductibility_Rules: "Abziehbar: nachgewiesene Verwaltungskosten ohne Begrenzung.",
    Max_Deductible: "Keine Begrenzung. Abziehbar: effektive Kosten mit Belegen.",
    Limitations: "Bankabrechnungen oder Belege über Verwaltungskosten erforderlich. Nur Kosten für Privatvermögen abziehbar (nicht Geschäftsvermögen).",
    Source: "https://www.be.ch/de/start/themen/steuern.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Bern, Formular 3",
    Verification_Status: "verified"
  },

  "52": {
    Canton: "BE",
    Index: "52",
    Tax_Year: 2024,
    Main_Category: "Abzüge",
    Sub_Category: "Wertschriften und Guthaben",
    Person: "",
    Description: "Pauschalabzug für Lotteriegewinne",
    Legal_Reference_Canton: "Art. 27 Abs. 2 StG BE",
    Legal_Reference_Federal: "Art. 32 Abs. 1 DBG",
    Rational_Explanation: "Bei Lotteriegewinnen, Preisgeldern und ähnlichen Einkünften kann ein Pauschalabzug für die Gewinnungskosten (z.B. Kosten für Lose) geltend gemacht werden. Der Pauschalabzug ist in der Wegleitung festgelegt und variiert zwischen Kanton und Bund.",
    Deductibility_Rules: "Pauschalabzug gemäss Wegleitung (Prozentsatz des Gewinns).",
    Max_Deductible: "Pauschalabzug gemäss Wegleitung Kanton Bern (siehe Formular 3).",
    Limitations: "Nachweis des Lotteriegewinns erforderlich. Pauschalabzug ohne Belegpflicht.",
    Source: "https://www.be.ch/de/start/themen/steuern.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Bern, Formular 3",
    Verification_Status: "verified"
  },

  "53": {
    Canton: "BE",
    Index: "53",
    Tax_Year: 2024,
    Main_Category: "Abzüge",
    Sub_Category: "Wertschriften und Guthaben",
    Person: "",
    Description: "Erträge und Vermögen aus Geschäftswertschriften",
    Legal_Reference_Canton: "Art. 23, 38 StG BE",
    Legal_Reference_Federal: "Art. 18 DBG",
    Rational_Explanation: "Falls im Formular 3 (Wertschriften) Erträge und Vermögen aus Geschäftswertschriften enthalten sind, müssen diese hier abgezogen werden, da sie bereits in der Geschäftsbuchhaltung (Formular 9) erfasst wurden. Dies verhindert eine Doppelbesteuerung.",
    Deductibility_Rules: "Abziehbar: alle Geschäftswertschriften-Erträge und -Vermögen, die fälschlicherweise in Formular 3 enthalten sind.",
    Max_Deductible: "Keine Begrenzung. Abzug entspricht dem in Formular 3 enthaltenen Geschäftsanteil.",
    Limitations: "Nachweis durch Geschäftsbuchhaltung (Formular 9). Klare Trennung zwischen Privat- und Geschäftsvermögen erforderlich.",
    Source: "https://www.be.ch/de/start/themen/steuern.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Bern, Formular 3",
    Verification_Status: "verified"
  },

  "54": {
    Canton: "BE",
    Index: "54",
    Tax_Year: 2024,
    Main_Category: "Abzüge",
    Sub_Category: "Wertschriften und Guthaben",
    Person: "",
    Description: "Abzug Teilbesteuerungsverfahren",
    Legal_Reference_Canton: "Art. 25 StG BE",
    Legal_Reference_Federal: "Art. 20 Abs. 1bis DBG",
    Rational_Explanation: "Bei Dividenden aus qualifizierten Beteiligungen (mindestens 10% des Grund- oder Stammkapitals einer Kapitalgesellschaft) gilt das Teilbesteuerungsverfahren. Ein Teil der Dividenden wird von der Einkommenssteuer befreit, um die wirtschaftliche Doppelbelastung zu mildern.",
    Deductibility_Rules: "Abzug gemäss Teilbesteuerungsverfahren (Prozentsatz der qualifizierten Beteiligungserträge).",
    Max_Deductible: "Keine Begrenzung. Abzug entspricht dem reduzierten Steuersatz gemäss Gesetz.",
    Limitations: "Nachweis der qualifizierten Beteiligung erforderlich (mind. 10% Kapitalanteil). Dividendenbescheinigung der Gesellschaft.",
    Source: "https://www.be.ch/de/start/themen/steuern.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Bern, Formular 3",
    Verification_Status: "verified"
  },

  // ==========================================
  // DEDUCTION INDEXES - General
  // ==========================================

  "4.2": {
    Canton: "BE",
    Index: "4.2",
    Tax_Year: 2024,
    Main_Category: "Abzüge",
    Sub_Category: "Versicherungen und Zinsen",
    Person: "",
    Description: "Versicherungsprämien und Zinsen auf Sparkapitalien",
    Legal_Reference_Canton: "Art. 31 Abs. 1 lit. a StG BE",
    Legal_Reference_Federal: "Art. 33 Abs. 1 lit. a-g DBG",
    Rational_Explanation: "Versicherungsprämien für Lebens-, Kranken-, Unfall- und Haftpflichtversicherungen sowie Zinsen auf Sparkapitalien (z.B. Bank-Sparkonto) sind abzugsfähig bis zu gesetzlichen Höchstbeträgen. Die Höchstbeträge sind abhängig vom Familienstand und erhöhen sich pro Kind um CHF 700.",
    Deductibility_Rules: "Abziehbar bis zu den gesetzlichen Höchstbeträgen. Mindestabzug auch ohne Nachweis (kantonal).",
    Max_Deductible: "Gemäss Wegleitung (unterschiedlich für Kanton/Gemeinde und Bund, abhängig von Familienstand). Erhöhung um CHF 700 pro Kind.",
    Limitations: "Versicherungsprämien: Policen oder Jahresrechnungen. Prämienverbilligungen sind abzuziehen. Zinsen: Bankbescheinigung.",
    Source: "https://www.be.ch/de/start/themen/steuern.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Bern, Ziffer 4.2",
    Verification_Status: "verified"
  },

  "4.3": {
    Canton: "BE",
    Index: "4.3",
    Tax_Year: 2024,
    Main_Category: "Schulden",
    Sub_Category: "Schuldzinsen",
    Person: "",
    Description: "Schuldzinsen und Schulden",
    Legal_Reference_Canton: "Art. 27 Abs. 1 lit. a und Art. 40 StG BE",
    Legal_Reference_Federal: "Art. 32 Abs. 1 und Art. 33 Abs. 1 lit. a DBG",
    Rational_Explanation: "Schuldzinsen für private Schulden (z.B. Hypothekarzinsen, Kreditzinsen) sind vom Einkommen abziehbar. Schulden selbst mindern das steuerbare Vermögen. Schuldzinsen für Geschäftsschulden werden in der Geschäftsbuchhaltung erfasst und sind hier nicht zu deklarieren.",
    Deductibility_Rules: "Schuldzinsen: vollumfänglich abziehbar vom Einkommen. Schulden: abziehbar vom Vermögen.",
    Max_Deductible: "Keine Begrenzung. Abziehbar: effektive Schuldzinsen und Schulden mit Belegen.",
    Limitations: "Zinsabrechnungen der Bank oder des Gläubigers erforderlich. Bei Hypotheken: Jahreszinsabrechnung. Schulden: Bestätigung oder Kontoauszug.",
    Source: "https://www.be.ch/de/start/themen/steuern.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Bern, Ziffer 4.3",
    Verification_Status: "verified"
  },

  "4.4": {
    Canton: "BE",
    Index: "4.4",
    Tax_Year: 2024,
    Main_Category: "Abzüge",
    Sub_Category: "Spenden",
    Person: "",
    Description: "Mitgliederbeiträge und Zuwendungen an politische Parteien",
    Legal_Reference_Canton: "Art. 31 Abs. 1 lit. c StG BE",
    Legal_Reference_Federal: "Art. 33 Abs. 1 lit. i DBG",
    Rational_Explanation: "Mitgliederbeiträge, Spenden und Zuwendungen an politische Parteien sind steuerlich abzugsfähig bis zu einem bestimmten Höchstbetrag oder Prozentsatz des Nettoeinkommens. Dies soll die politische Partizipation fördern.",
    Deductibility_Rules: "Abziehbar bis zu gesetzlichen Höchstbeträgen (Prozentsatz des Nettoeinkommens oder Maximalbetrag gemäss Wegleitung).",
    Max_Deductible: "Gemäss Wegleitung Kanton Bern (unterschiedlich für Kanton/Gemeinde und Bund).",
    Limitations: "Einzahlungsbestätigung der politischen Partei erforderlich. Nur anerkannte politische Parteien.",
    Source: "https://www.be.ch/de/start/themen/steuern.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Bern, Ziffer 4.4",
    Verification_Status: "verified"
  },

  // ==========================================
  // DEDUCTION INDEXES - Support & Disability
  // ==========================================

  "5.1": {
    Canton: "BE",
    Index: "5.1",
    Tax_Year: 2024,
    Main_Category: "Abzüge",
    Sub_Category: "Unterhaltsbeiträge",
    Person: "",
    Description: "Bezahlte Unterhaltsbeiträge (Alimente) sowie Renten und dauernde Lasten",
    Legal_Reference_Canton: "Art. 27 Abs. 1 lit. c StG BE",
    Legal_Reference_Federal: "Art. 33 Abs. 1 lit. c DBG",
    Rational_Explanation: "Gesetzlich geschuldete Unterhaltsbeiträge an den geschiedenen, gerichtlich oder tatsächlich getrennt lebenden Ehegatten oder Partner sowie Unterhaltsbeiträge für minderjährige Kinder sind vollumfänglich abziehbar. Auch Rentenleistungen und dauernde Lasten aufgrund gesetzlicher oder gerichtlicher Verpflichtungen sind abzugsfähig.",
    Deductibility_Rules: "Vollumfänglich abziehbar ohne Begrenzung, soweit rechtlich geschuldet und tatsächlich bezahlt.",
    Max_Deductible: "Keine Begrenzung. Abziehbar: effektiv bezahlte Unterhaltsbeiträge gemäss Urteil/Vereinbarung.",
    Limitations: "Scheidungsurteil, Trennungsvereinbarung oder gerichtliche Verfügung erforderlich. Zahlungsnachweise (Bankbelege). Nur rechtlich geschuldete Beiträge abziehbar.",
    Source: "https://www.be.ch/de/start/themen/steuern.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Bern, Ziffer 5.1",
    Verification_Status: "verified"
  },

  "5.5": {
    Canton: "BE",
    Index: "5.5",
    Tax_Year: 2024,
    Main_Category: "Abzüge",
    Sub_Category: "Versicherungen und Zinsen",
    Person: "",
    Description: "Selbst getragene behinderungsbedingte Kosten",
    Legal_Reference_Canton: "Art. 31 Abs. 1 lit. b StG BE",
    Legal_Reference_Federal: "Art. 33 Abs. 1 lit. h DBG",
    Rational_Explanation: "Behinderungsbedingte Kosten, die der Steuerpflichtige selbst trägt (nicht durch Versicherungen oder Dritte gedeckt), sind ohne Begrenzung abziehbar. Dies umfasst z.B. Kosten für Hilfsmittel, behindertengerechte Umbauten, Pflege und Betreuung.",
    Deductibility_Rules: "Vollumfänglich abziehbar ohne Begrenzung, soweit selbst getragen und behinderungsbedingt.",
    Max_Deductible: "Keine Begrenzung. Abziehbar: effektive selbstgetragene Kosten mit Belegen.",
    Limitations: "Ärztliches Zeugnis über Behinderung erforderlich. Belege über die Kosten. Nur selbst getragene Kosten abziehbar (nach Abzug von Versicherungsleistungen).",
    Source: "https://www.be.ch/de/start/themen/steuern.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Bern, Ziffer 5.5",
    Verification_Status: "verified"
  },

  // ==========================================
  // DEDUCTION INDEXES - Professional Expenses
  // ==========================================

  "6.1": {
    Canton: "BE",
    Index: "6.1",
    Tax_Year: 2024,
    Main_Category: "Abzüge",
    Sub_Category: "Berufsauslagen",
    Person: "",
    Description: "Total Fahrkosten",
    Legal_Reference_Canton: "Art. 26 Abs. 1 lit. a StG BE",
    Legal_Reference_Federal: "Art. 26 Abs. 1 lit. a DBG",
    Rational_Explanation: "Fahrkosten zwischen Wohnort und Arbeitsstätte sind abzugsfähig. Es können entweder die effektiven Kosten der öffentlichen Verkehrsmittel oder bei Benutzung des privaten Fahrzeugs ein Pauschalabzug von CHF 0.70 pro Kilometer geltend gemacht werden.",
    Deductibility_Rules: "Abziehbar bis zu den gesetzlichen Höchstbeträgen.",
    Max_Deductible: "Kanton/Gemeinde BE 2024: CHF 7'000. Direkte Bundessteuer: CHF 3'000. Bei ÖV: effektive Kosten ohne Limit.",
    Limitations: "Bei ÖV: Fahrausweise oder GA-Bescheinigung. Bei Privatfahrzeug: Km-Pauschale CHF 0.70, max. CHF 7'000 (Kanton) bzw. CHF 3'000 (Bund). Arbeitsweg muss nachvollziehbar sein.",
    Source: "https://www.be.ch/de/start/themen/steuern.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Bern, Ziffer 6.1",
    Verification_Status: "verified"
  },

  "6.2": {
    Canton: "BE",
    Index: "6.2",
    Tax_Year: 2024,
    Main_Category: "Abzüge",
    Sub_Category: "Berufsauslagen",
    Person: "",
    Description: "Auswärtige Verpflegung",
    Legal_Reference_Canton: "Art. 26 Abs. 1 lit. b StG BE",
    Legal_Reference_Federal: "Art. 26 Abs. 1 lit. b DBG",
    Rational_Explanation: "Mehrkosten für auswärtige Verpflegung sind abzugsfähig, wenn der Arbeitnehmer aus beruflichen Gründen auswärts verpflegt werden muss (z.B. keine Kantine am Arbeitsort, keine Möglichkeit zum Heimkehren über Mittag). Der Pauschalabzug beträgt CHF 15 pro Arbeitstag bzw. CHF 7.50 bei verbilligter Verpflegung.",
    Deductibility_Rules: "Pauschalabzug CHF 15/Tag (oder CHF 7.50 bei Kantine/verbilligter Verpflegung).",
    Max_Deductible: "CHF 3'200 pro Jahr (bei CHF 15/Tag) bzw. CHF 1'600 pro Jahr (bei CHF 7.50/Tag).",
    Limitations: "Auswärtige Verpflegung muss beruflich bedingt sein. Keine Möglichkeit zur Heimkehr über Mittag. Pauschalabzug ohne Belegpflicht.",
    Source: "https://www.be.ch/de/start/themen/steuern.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Bern, Ziffer 6.2",
    Verification_Status: "verified"
  },

  "6.3": {
    Canton: "BE",
    Index: "6.3",
    Tax_Year: 2024,
    Main_Category: "Abzüge",
    Sub_Category: "Berufsauslagen",
    Person: "",
    Description: "Total Kosten Wochenaufenthalt",
    Legal_Reference_Canton: "Art. 26 Abs. 1 lit. c StG BE",
    Legal_Reference_Federal: "Art. 26 Abs. 1 lit. c DBG",
    Rational_Explanation: "Kosten für auswärtigen Wochenaufenthalt am Arbeitsort sind abzugsfähig, wenn aus beruflichen Gründen eine zweite Unterkunft am Arbeitsort notwendig ist und eine tägliche Rückkehr zum Wohnort nicht zumutbar ist. Dies umfasst Miete, Nebenkosten und Verpflegungsmehrkosten.",
    Deductibility_Rules: "Abziehbar: nachgewiesene Kosten für Unterkunft und Verpflegung.",
    Max_Deductible: "Keine gesetzliche Begrenzung, aber Angemessenheitsprüfung durch Steuerverwaltung.",
    Limitations: "Mietvertrag oder Hotelrechnungen erforderlich. Tägliche Rückkehr muss unzumutbar sein (Distanz, Arbeitszeiten). Nur zeitlich befristeter Wochenaufenthalt abziehbar.",
    Source: "https://www.be.ch/de/start/themen/steuern.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Bern, Ziffer 6.3",
    Verification_Status: "verified"
  },

  "6.4": {
    Canton: "BE",
    Index: "6.4",
    Tax_Year: 2024,
    Main_Category: "Abzüge",
    Sub_Category: "Berufsauslagen",
    Person: "",
    Description: "Total übrige Berufskosten",
    Legal_Reference_Canton: "Art. 26 Abs. 1 lit. d StG BE",
    Legal_Reference_Federal: "Art. 26 Abs. 1 lit. d DBG",
    Rational_Explanation: "Übrige Berufskosten umfassen alle weiteren beruflich bedingten Auslagen, die nicht unter die anderen Kategorien fallen. Dazu gehören Mitgliederbeiträge an Berufsverbände, Berufskosten aus Rückgabe von Mitarbeiterbeteiligungen, sowie ein Pauschalabzug von 3% des Nettolohns (min. CHF 2'000, max. CHF 4'000) für allgemeine Berufsauslagen wie Arbeitskleidung, Fachliteratur, etc.",
    Deductibility_Rules: "Pauschalabzug: 3% des Nettolohns, min. CHF 2'000, max. CHF 4'000. Zusätzlich: spezifische Berufskosten mit Nachweis.",
    Max_Deductible: "Pauschalabzug: max. CHF 4'000. Zusätzliche nachgewiesene Kosten ohne Begrenzung.",
    Limitations: "Pauschalabzug ohne Belegpflicht. Spezifische Kosten (Verbandsbeiträge, etc.): Belege erforderlich.",
    Source: "https://www.be.ch/de/start/themen/steuern.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Bern, Ziffer 6.4",
    Verification_Status: "verified"
  },

  "6.5": {
    Canton: "BE",
    Index: "6.5",
    Tax_Year: 2024,
    Main_Category: "Abzüge",
    Sub_Category: "Berufsauslagen",
    Person: "",
    Description: "Berufskosten Nebenerwerb",
    Legal_Reference_Canton: "Art. 26 Abs. 2 StG BE",
    Legal_Reference_Federal: "Art. 26 Abs. 2 DBG",
    Rational_Explanation: "Für Einkünfte aus Nebenerwerb (nebenberufliche Tätigkeit) kann ein Pauschalabzug von 20% der Nebeneinkünfte geltend gemacht werden, mindestens CHF 800, höchstens CHF 2'400. Alternativ können die effektiven Berufskosten des Nebenerwerbs mit Belegen geltend gemacht werden.",
    Deductibility_Rules: "Pauschalabzug: 20% der Nebenerwerbs-Einkünfte, min. CHF 800, max. CHF 2'400. ODER effektive Kosten mit Belegen.",
    Max_Deductible: "Pauschalabzug: max. CHF 2'400. Effektive Kosten: keine Begrenzung mit Belegen.",
    Limitations: "Pauschalabzug ohne Belegpflicht. Bei effektiven Kosten: vollständige Belege erforderlich.",
    Source: "https://www.be.ch/de/start/themen/steuern.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Bern, Ziffer 6.5",
    Verification_Status: "verified"
  },

  "6.6": {
    Canton: "BE",
    Index: "6.6",
    Tax_Year: 2024,
    Main_Category: "Abzüge",
    Sub_Category: "Weiterbildung",
    Person: "",
    Description: "Berufsorientierte Aus- und Weiterbildungskosten",
    Legal_Reference_Canton: "Art. 26 Abs. 1 lit. f StG BE",
    Legal_Reference_Federal: "Art. 33 Abs. 1 lit. j DBG",
    Rational_Explanation: "Kosten für berufsorientierte Aus- und Weiterbildung sind abzugsfähig. Dies umfasst Kosten für Kurse, Seminare, Schulungen und Studiengänge, die direkt mit der aktuellen oder einer angestrebten beruflichen Tätigkeit zusammenhängen. Die Abzugsfähigkeit wurde in den letzten Jahren erweitert.",
    Deductibility_Rules: "Abziehbar: nachgewiesene Kosten für berufsorientierte Aus- und Weiterbildung bis zu gesetzlichen Höchstbeträgen.",
    Max_Deductible: "Gemäss DBG und StG BE: max. CHF 12'000 pro Jahr (für beide Elternteile/Ehegatten zusammen).",
    Limitations: "Kursbestätigungen und Zahlungsbelege erforderlich. Aus-/Weiterbildung muss berufsorientiert sein (direkter Bezug zur Berufstätigkeit).",
    Source: "https://www.be.ch/de/start/themen/steuern.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Bern, Ziffer 6.6",
    Verification_Status: "verified"
  },

  "6.8": {
    Canton: "BE",
    Index: "6.8",
    Tax_Year: 2024,
    Main_Category: "Abzüge",
    Sub_Category: "Berufsauslagen",
    Person: "",
    Description: "Korrektur nettolohnübersteigender Betrag",
    Legal_Reference_Canton: "Art. 26 StG BE",
    Legal_Reference_Federal: "Art. 26 DBG",
    Rational_Explanation: "Die Berufskosten dürfen den Nettolohn nicht übersteigen. Falls die summierten Berufsauslagen höher sind als der Nettolohn, wird eine Korrektur vorgenommen, um sicherzustellen, dass die Berufskosten maximal dem Nettolohn entsprechen. Dies verhindert negative Einkünfte aus unselbstständiger Erwerbstätigkeit.",
    Deductibility_Rules: "Automatische Korrektur durch Steuerverwaltung: Berufskosten werden auf Höhe des Nettolohns begrenzt.",
    Max_Deductible: "Berufskosten maximal in Höhe des Nettolohns.",
    Limitations: "Wird automatisch von der Steuerverwaltung berechnet und angewendet.",
    Source: "https://www.be.ch/de/start/themen/steuern.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Bern, Ziffer 6.8",
    Verification_Status: "verified"
  },

  // ==========================================
  // SOCIAL DEDUCTION INDEXES
  // ==========================================

  "5.3": {
    Canton: "BE",
    Index: "5.3",
    Tax_Year: 2024,
    Main_Category: "Abzüge",
    Sub_Category: "Spenden",
    Person: "",
    Description: "Vergabungen (Spenden)",
    Legal_Reference_Canton: "Art. 32 Abs. 1 lit. d StG BE",
    Legal_Reference_Federal: "Art. 33a DBG",
    Rational_Explanation: "Zuwendungen an steuerbefreite juristische Personen mit Sitz in der Schweiz sowie an Bund, Kantone und Gemeinden sind abzugsfähig. Dies umfasst gemeinnützige, kulturelle und kirchliche Institutionen. Der Abzug ist auf einen bestimmten Prozentsatz des Reineinkommens begrenzt.",
    Deductibility_Rules: "Abziehbar bis zu gesetzlichen Höchstbeträgen (Prozentsatz des Reineinkommens).",
    Max_Deductible: "Kanton BE: bis 20% des Reineinkommens. Bund: mindestens CHF 100, maximal 20% des Reineinkommens.",
    Limitations: "Spendenbestätigung der gemeinnützigen Organisation erforderlich. Organisation muss steuerbefreit sein. Nur freiwillige Zuwendungen abziehbar.",
    Source: "https://www.be.ch/de/start/themen/steuern.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Bern, Ziffer 5.3",
    Verification_Status: "verified"
  },

  "5.4": {
    Canton: "BE",
    Index: "5.4",
    Tax_Year: 2024,
    Main_Category: "Abzüge",
    Sub_Category: "Versicherungen und Zinsen",
    Person: "",
    Description: "Selbst getragene Krankheits- und Unfallkosten",
    Legal_Reference_Canton: "Art. 32 Abs. 1 lit. b StG BE",
    Legal_Reference_Federal: "Art. 33 Abs. 1 lit. h DBG",
    Rational_Explanation: "Krankheits- und Unfallkosten, die selbst getragen werden (nicht durch Versicherungen gedeckt), sind abziehbar, soweit sie zusammen mit anderen vom Reineinkommen abzuziehenden Aufwendungen 5% des Reineinkommens (nach Abzug der allgemeinen Abzüge) übersteigen.",
    Deductibility_Rules: "Abziehbar: selbst getragene Kosten über 5% des Reineinkommens.",
    Max_Deductible: "Keine Begrenzung nach oben. Abziehbar: Betrag über 5%-Schwelle des Reineinkommens.",
    Limitations: "Arztrechnungen, Spitalrechnungen, Apothekenbelege erforderlich. Nur selbst getragene Kosten abziehbar (nach Abzug von Versicherungsleistungen). 5%-Schwelle wird automatisch berechnet.",
    Source: "https://www.be.ch/de/start/themen/steuern.html",
    Source_Document: "Wegleitung zur Steuererklärung 2024 Kanton Bern, Ziffer 5.4",
    Verification_Status: "verified"
  },

};

module.exports = legalMetadataBern;
