//
//  TaxFormFieldSeedData.swift
//  TaxedGmbH_IOS
//
//  Seed data for tax form field mappings based on official Wegleitungen
//  Sources: ZH Wegleitung 2024, ZG Wegleitung 2024, BS Wegleitung 2024
//

import Foundation

struct TaxFormFieldSeedData {

    /// Generate all seed data for ZH, ZG, BS, and SO cantons
    static func generateAllFields() -> [TaxFormField] {
        var fields: [TaxFormField] = []

        fields.append(contentsOf: generateZurichFields())
        fields.append(contentsOf: generateZugFields())
        fields.append(contentsOf: generateBaselFields())
        fields.append(contentsOf: generateSolothurnFields())

        return fields
    }

    // MARK: - Zürich (ZH) Fields

    static func generateZurichFields() -> [TaxFormField] {
        return [
            // INCOME FIELDS (Einkommen)

            // Ziffer 1.x - Employment Income
            TaxFormField.zurichField(
                fieldNumber: "1.1",
                taxCategoryType: .salary,
                mainCategory: .einkommen,
                category: .unselbstaendigeErwerbstaetigkeit,
                descriptionDe: "Nettolohn aus unselbständiger Erwerbstätigkeit",
                descriptionEn: "Net salary from employment",
                descriptionFr: "Salaire net d'une activité lucrative dépendante",
                descriptionIt: "Salario netto da attività lucrativa dipendente",
                pageNumber: 2,
                sortOrder: 10,
                isRequired: false
            ),

            TaxFormField.zurichField(
                fieldNumber: "1.2",
                taxCategoryType: .bonus,
                mainCategory: .einkommen,
                category: .unselbstaendigeErwerbstaetigkeit,
                subcategory: "Nebenerwerb",
                descriptionDe: "Nebenerwerb (z.B. Bonuszahlungen, Trinkgelder)",
                descriptionEn: "Side income (e.g., bonuses, tips)",
                descriptionFr: "Revenus accessoires (p. ex. primes, pourboires)",
                descriptionIt: "Redditi accessori (ad es. bonus, mance)",
                pageNumber: 2,
                sortOrder: 20,
                isRequired: false
            ),

            // Ziffer 2 - Self-Employment
            TaxFormField.zurichField(
                fieldNumber: "2",
                taxCategoryType: .freelance,
                mainCategory: .einkommen,
                category: .selbstaendigeErwerbstaetigkeit,
                descriptionDe: "Einkommen aus selbständiger Erwerbstätigkeit",
                descriptionEn: "Income from self-employment",
                descriptionFr: "Revenu d'une activité lucrative indépendante",
                descriptionIt: "Reddito da attività lucrativa indipendente",
                pageNumber: 2,
                sortOrder: 30,
                isRequired: false
            ),

            // Ziffer 3.x - Other Income
            TaxFormField.zurichField(
                fieldNumber: "3.3",
                taxCategoryType: .unemploymentBenefits,
                mainCategory: .einkommen,
                category: .uebrigeEinkuenfte,
                subcategory: "Arbeitslosenentschädigung",
                descriptionDe: "Erwerbsausfallentschädigungen aus Arbeitslosenversicherung",
                descriptionEn: "Unemployment insurance benefits",
                descriptionFr: "Indemnités de l'assurance-chômage",
                descriptionIt: "Indennità dell'assicurazione disoccupazione",
                pageNumber: 2,
                sortOrder: 40,
                isRequired: false
            ),

            TaxFormField.zurichField(
                fieldNumber: "3.4",
                taxCategoryType: .childAllowance,
                mainCategory: .einkommen,
                category: .uebrigeEinkuenfte,
                subcategory: "Familienzulagen",
                descriptionDe: "Familienzulagen und ähnliche Bezüge",
                descriptionEn: "Family allowances and similar benefits",
                descriptionFr: "Allocations familiales et prestations similaires",
                descriptionIt: "Assegni familiari e prestazioni simili",
                pageNumber: 2,
                sortOrder: 50,
                isRequired: false
            ),

            // Ziffer 4.x - Investment Income
            TaxFormField.zurichField(
                fieldNumber: "4",
                taxCategoryType: .investment,
                mainCategory: .einkommen,
                category: .wertschriftenUndGuthaben,
                descriptionDe: "Einkünfte aus beweglichem Vermögen (Zinsen, Dividenden)",
                descriptionEn: "Income from movable assets (interest, dividends)",
                descriptionFr: "Revenus de la fortune mobilière (intérêts, dividendes)",
                descriptionIt: "Redditi della sostanza mobiliare (interessi, dividendi)",
                pageNumber: 2,
                sortOrder: 60,
                isRequired: false
            ),

            // Ziffer 5.x - Capital Payments
            TaxFormField.zurichField(
                fieldNumber: "5.5",
                taxCategoryType: .pillar3a,
                mainCategory: .einkommen,
                category: .vorsorge,
                subcategory: "Kapitalabfindungen",
                descriptionDe: "Kapitalleistungen aus Vorsorge (Säule 3a)",
                descriptionEn: "Capital payments from pillar 3a",
                descriptionFr: "Versements en capital du pilier 3a",
                descriptionIt: "Prestazioni in capitale dal pilastro 3a",
                pageNumber: 2,
                sortOrder: 70,
                isRequired: false
            ),

            // Ziffer 6.x - Pension Income
            TaxFormField.zurichField(
                fieldNumber: "6",
                taxCategoryType: .pension,
                mainCategory: .einkommen,
                category: .vorsorge,
                descriptionDe: "Renten und andere wiederkehrende Leistungen",
                descriptionEn: "Pensions and other recurring benefits",
                descriptionFr: "Rentes et autres prestations périodiques",
                descriptionIt: "Rendite e altre prestazioni periodiche",
                pageNumber: 2,
                sortOrder: 80,
                isRequired: false
            ),

            // Ziffer 7.x - Rental Income
            TaxFormField.zurichField(
                fieldNumber: "7",
                taxCategoryType: .rental,
                mainCategory: .einkommen,
                category: .liegenschaften,
                descriptionDe: "Einkünfte aus unbeweglichem Vermögen (Miete, Pacht)",
                descriptionEn: "Income from real estate (rent, lease)",
                descriptionFr: "Revenus immobiliers (loyer, fermage)",
                descriptionIt: "Redditi immobiliari (pigione, affitto)",
                pageNumber: 2,
                sortOrder: 90,
                isRequired: false
            ),

            // DEDUCTION FIELDS (Abzüge)

            // Ziffer 11.x - Professional Expenses
            TaxFormField.zurichField(
                fieldNumber: "11.1",
                taxCategoryType: .professionalExpenses,
                mainCategory: .abzuege,
                category: .berufsauslagen,
                subcategory: "Person 1",
                descriptionDe: "Berufsauslagen Person 1 (gemäss Formular)",
                descriptionEn: "Professional expenses person 1 (per form)",
                descriptionFr: "Frais professionnels personne 1 (selon formulaire)",
                descriptionIt: "Spese professionali persona 1 (secondo modulo)",
                pageNumber: 3,
                sortOrder: 110,
                isRequired: false
            ),

            TaxFormField.zurichField(
                fieldNumber: "11.2",
                taxCategoryType: .professionalExpenses,
                mainCategory: .abzuege,
                category: .berufsauslagen,
                subcategory: "Person 2",
                descriptionDe: "Berufsauslagen Person 2 (gemäss Formular)",
                descriptionEn: "Professional expenses person 2 (per form)",
                descriptionFr: "Frais professionnels personne 2 (selon formulaire)",
                descriptionIt: "Spese professionali persona 2 (secondo modulo)",
                pageNumber: 3,
                sortOrder: 120,
                isRequired: false
            ),

            // Ziffer 12 - Interest on Debts
            TaxFormField.zurichField(
                fieldNumber: "12",
                taxCategoryType: .loanInterest,
                mainCategory: .abzuege,
                category: .schuldzinsen,
                descriptionDe: "Schuldzinsen (gemäss Schuldenverzeichnis)",
                descriptionEn: "Interest on debts (per debt schedule)",
                descriptionFr: "Intérêts passifs (selon liste des dettes)",
                descriptionIt: "Interessi passivi (secondo elenco dei debiti)",
                pageNumber: 3,
                sortOrder: 130,
                isRequired: false
            ),

            // Ziffer 13 - Alimony
            TaxFormField.zurichField(
                fieldNumber: "13",
                taxCategoryType: .alimony,
                mainCategory: .abzuege,
                category: .unterhalt,
                descriptionDe: "Unterhaltsbeiträge und Rentenleistungen",
                descriptionEn: "Alimony and annuity payments",
                descriptionFr: "Contributions d'entretien et rentes versées",
                descriptionIt: "Contributi di mantenimento e rendite versate",
                pageNumber: 3,
                sortOrder: 140,
                isRequired: false
            ),

            // Ziffer 14 - Pillar 3a Contributions
            TaxFormField.zurichField(
                fieldNumber: "14",
                taxCategoryType: .pillar3a,
                mainCategory: .abzuege,
                category: .versicherungen,
                subcategory: "Säule 3a",
                descriptionDe: "Beiträge an anerkannte Formen der Selbstvorsorge (Säule 3a)",
                descriptionEn: "Contributions to pillar 3a",
                descriptionFr: "Cotisations au pilier 3a",
                descriptionIt: "Contributi al pilastro 3a",
                pageNumber: 3,
                sortOrder: 150,
                isRequired: false
            ),

            // Ziffer 15 - Insurance Premiums
            TaxFormField.zurichField(
                fieldNumber: "15",
                taxCategoryType: .healthInsurance,
                mainCategory: .abzuege,
                category: .versicherungen,
                descriptionDe: "Versicherungsprämien und Sparzinsen (gemäss Formular)",
                descriptionEn: "Insurance premiums and savings interest (per form)",
                descriptionFr: "Primes d'assurance et intérêts d'épargne (selon formulaire)",
                descriptionIt: "Premi assicurativi e interessi di risparmio (secondo modulo)",
                pageNumber: 3,
                sortOrder: 160,
                isRequired: false
            ),

            // Ziffer 16.x - Education Costs
            TaxFormField.zurichField(
                fieldNumber: "16.2",
                taxCategoryType: .educationExpenses,
                mainCategory: .abzuege,
                category: .weiterbildung,
                descriptionDe: "Berufsorientierte Aus- und Weiterbildungskosten",
                descriptionEn: "Professional education and training costs",
                descriptionFr: "Frais de formation et de perfectionnement professionnels",
                descriptionIt: "Spese di formazione e perfezionamento professionale",
                pageNumber: 3,
                sortOrder: 170,
                isRequired: false
            ),

            // Ziffer 17 - Donations
            TaxFormField.zurichField(
                fieldNumber: "17",
                taxCategoryType: .donations,
                mainCategory: .abzuege,
                category: .spenden,
                descriptionDe: "Spenden und Zuwendungen",
                descriptionEn: "Donations and contributions",
                descriptionFr: "Dons et libéralités",
                descriptionIt: "Donazioni e liberalità",
                pageNumber: 3,
                sortOrder: 180,
                isRequired: false
            ),

            // Ziffer 18 - Childcare Costs
            TaxFormField.zurichField(
                fieldNumber: "18",
                taxCategoryType: .childcare,
                mainCategory: .abzuege,
                category: .kinderbetreuung,
                descriptionDe: "Kinderbetreuungskosten durch Dritte",
                descriptionEn: "Third-party childcare costs",
                descriptionFr: "Frais de garde d'enfants par des tiers",
                descriptionIt: "Spese di custodia di figli da parte di terzi",
                pageNumber: 3,
                sortOrder: 190,
                isRequired: false
            ),

            // WEALTH FIELDS (Vermögen)

            TaxFormField.zurichField(
                fieldNumber: "20",
                taxCategoryType: .securities,
                mainCategory: .vermoegen,
                category: .wertpapiere,
                descriptionDe: "Wertschriften und Guthaben (gemäss Verzeichnis)",
                descriptionEn: "Securities and credit balances (per schedule)",
                descriptionFr: "Titres et avoirs (selon liste)",
                descriptionIt: "Titoli e averi (secondo elenco)",
                pageNumber: 4,
                sortOrder: 200,
                isRequired: false
            ),

            TaxFormField.zurichField(
                fieldNumber: "21",
                taxCategoryType: .realEstate,
                mainCategory: .vermoegen,
                category: .immobilien,
                descriptionDe: "Liegenschaften (gemäss Verzeichnis)",
                descriptionEn: "Real estate (per schedule)",
                descriptionFr: "Immeubles (selon liste)",
                descriptionIt: "Immobili (secondo elenco)",
                pageNumber: 4,
                sortOrder: 210,
                isRequired: false
            ),

            // LIABILITIES FIELDS (Schulden)

            TaxFormField.zurichField(
                fieldNumber: "30",
                taxCategoryType: .mortgage,
                mainCategory: .schulden,
                category: .hypotheken,
                descriptionDe: "Hypothekarschulden (gemäss Schuldenverzeichnis)",
                descriptionEn: "Mortgage debts (per debt schedule)",
                descriptionFr: "Dettes hypothécaires (selon liste des dettes)",
                descriptionIt: "Debiti ipotecari (secondo elenco dei debiti)",
                pageNumber: 4,
                sortOrder: 300,
                isRequired: false
            ),

            TaxFormField.zurichField(
                fieldNumber: "31",
                taxCategoryType: .loanDebt,
                mainCategory: .schulden,
                category: .kredite,
                descriptionDe: "Übrige Schulden (gemäss Schuldenverzeichnis)",
                descriptionEn: "Other debts (per debt schedule)",
                descriptionFr: "Autres dettes (selon liste des dettes)",
                descriptionIt: "Altri debiti (secondo elenco dei debiti)",
                pageNumber: 4,
                sortOrder: 310,
                isRequired: false
            ),
        ]
    }

    // MARK: - Zug (ZG) Fields

    static func generateZugFields() -> [TaxFormField] {
        return [
            // INCOME FIELDS (Einkommen)

            // Employment Income
            TaxFormField.zugField(
                code: "100",
                taxCategoryType: .salary,
                mainCategory: .einkommen,
                category: .unselbstaendigeErwerbstaetigkeit,
                descriptionDe: "Nettolohn aus unselbständiger Erwerbstätigkeit",
                descriptionEn: "Net salary from employment",
                descriptionFr: "Salaire net d'une activité lucrative dépendante",
                descriptionIt: "Salario netto da attività lucrativa dipendente",
                pageNumber: 2,
                sortOrder: 10,
                isRequired: false
            ),

            TaxFormField.zugField(
                code: "101",
                taxCategoryType: .bonus,
                mainCategory: .einkommen,
                category: .unselbstaendigeErwerbstaetigkeit,
                subcategory: "Nebenerwerb",
                descriptionDe: "Nebeneinkünfte aus unselbständiger Erwerbstätigkeit",
                descriptionEn: "Side income from employment",
                descriptionFr: "Revenus accessoires d'une activité dépendante",
                descriptionIt: "Redditi accessori da attività dipendente",
                pageNumber: 2,
                sortOrder: 20,
                isRequired: false
            ),

            // Self-Employment
            TaxFormField.zugField(
                code: "110",
                taxCategoryType: .freelance,
                mainCategory: .einkommen,
                category: .selbstaendigeErwerbstaetigkeit,
                descriptionDe: "Einkommen aus selbständiger Erwerbstätigkeit",
                descriptionEn: "Income from self-employment",
                descriptionFr: "Revenu d'une activité lucrative indépendante",
                descriptionIt: "Reddito da attività lucrativa indipendente",
                pageNumber: 2,
                sortOrder: 30,
                isRequired: false
            ),

            // Investment Income
            TaxFormField.zugField(
                code: "120",
                taxCategoryType: .investment,
                mainCategory: .einkommen,
                category: .wertschriftenUndGuthaben,
                descriptionDe: "Einkünfte aus Wertschriften und Guthaben",
                descriptionEn: "Income from securities and credit balances",
                descriptionFr: "Revenus de titres et avoirs",
                descriptionIt: "Redditi da titoli e averi",
                pageNumber: 2,
                sortOrder: 40,
                isRequired: false
            ),

            // Property Income (Simplified in 2024)
            TaxFormField.zugField(
                code: "181",
                taxCategoryType: .rental,
                mainCategory: .einkommen,
                category: .liegenschaften,
                descriptionDe: "Einkünfte aus Liegenschaften (vereinfacht ab 2024)",
                descriptionEn: "Property income (simplified from 2024)",
                descriptionFr: "Revenus immobiliers (simplifié dès 2024)",
                descriptionIt: "Redditi immobiliari (semplificato dal 2024)",
                pageNumber: 2,
                sortOrder: 50,
                isRequired: false
            ),

            // Pension Income
            TaxFormField.zugField(
                code: "130",
                taxCategoryType: .pension,
                mainCategory: .einkommen,
                category: .vorsorge,
                descriptionDe: "Renten und andere wiederkehrende Leistungen",
                descriptionEn: "Pensions and other recurring benefits",
                descriptionFr: "Rentes et autres prestations périodiques",
                descriptionIt: "Rendite e altre prestazioni periodiche",
                pageNumber: 2,
                sortOrder: 60,
                isRequired: false
            ),

            // DEDUCTION FIELDS (Abzüge)

            // Professional Expenses
            TaxFormField.zugField(
                code: "200",
                taxCategoryType: .professionalExpenses,
                mainCategory: .abzuege,
                category: .berufsauslagen,
                descriptionDe: "Berufsauslagen",
                descriptionEn: "Professional expenses",
                descriptionFr: "Frais professionnels",
                descriptionIt: "Spese professionali",
                pageNumber: 3,
                sortOrder: 100,
                isRequired: false
            ),

            // Insurance Premiums
            TaxFormField.zugField(
                code: "210",
                taxCategoryType: .healthInsurance,
                mainCategory: .abzuege,
                category: .versicherungen,
                descriptionDe: "Versicherungsprämien und Sparzinsen",
                descriptionEn: "Insurance premiums and savings interest",
                descriptionFr: "Primes d'assurance et intérêts d'épargne",
                descriptionIt: "Premi assicurativi e interessi di risparmio",
                pageNumber: 3,
                sortOrder: 110,
                isRequired: false
            ),

            // Pillar 3a
            TaxFormField.zugField(
                code: "220",
                taxCategoryType: .pillar3a,
                mainCategory: .abzuege,
                category: .versicherungen,
                subcategory: "Säule 3a",
                descriptionDe: "Einlagen Säule 3a",
                descriptionEn: "Pillar 3a contributions",
                descriptionFr: "Cotisations pilier 3a",
                descriptionIt: "Contributi pilastro 3a",
                pageNumber: 3,
                sortOrder: 120,
                isRequired: false
            ),

            // Interest on Debts
            TaxFormField.zugField(
                code: "230",
                taxCategoryType: .mortgageInterest,
                mainCategory: .abzuege,
                category: .schuldzinsen,
                descriptionDe: "Schuldzinsen",
                descriptionEn: "Interest on debts",
                descriptionFr: "Intérêts passifs",
                descriptionIt: "Interessi passivi",
                pageNumber: 3,
                sortOrder: 130,
                isRequired: false
            ),

            // Donations
            TaxFormField.zugField(
                code: "240",
                taxCategoryType: .donations,
                mainCategory: .abzuege,
                category: .spenden,
                descriptionDe: "Spenden und Zuwendungen",
                descriptionEn: "Donations and contributions",
                descriptionFr: "Dons et libéralités",
                descriptionIt: "Donazioni e liberalità",
                pageNumber: 3,
                sortOrder: 140,
                isRequired: false
            ),

            // Childcare
            TaxFormField.zugField(
                code: "250",
                taxCategoryType: .childcare,
                mainCategory: .abzuege,
                category: .kinderbetreuung,
                descriptionDe: "Kinderbetreuungskosten",
                descriptionEn: "Childcare costs",
                descriptionFr: "Frais de garde d'enfants",
                descriptionIt: "Spese di custodia di figli",
                pageNumber: 3,
                sortOrder: 150,
                isRequired: false
            ),

            // WEALTH FIELDS (Vermögen)

            // Securities (Code 600)
            TaxFormField.zugField(
                code: "600",
                taxCategoryType: .securities,
                mainCategory: .vermoegen,
                category: .wertpapiere,
                descriptionDe: "Wertschriften und Guthaben",
                descriptionEn: "Securities and credit balances",
                descriptionFr: "Titres et avoirs",
                descriptionIt: "Titoli e averi",
                pageNumber: 4,
                sortOrder: 200,
                isRequired: false
            ),

            // Property Wealth (Simplified Code 610 in 2024)
            TaxFormField.zugField(
                code: "610",
                taxCategoryType: .realEstate,
                mainCategory: .vermoegen,
                category: .immobilien,
                descriptionDe: "Liegenschaften (vereinfacht ab 2024)",
                descriptionEn: "Real estate (simplified from 2024)",
                descriptionFr: "Immeubles (simplifié dès 2024)",
                descriptionIt: "Immobili (semplificato dal 2024)",
                pageNumber: 4,
                sortOrder: 210,
                isRequired: false
            ),

            // Vehicles
            TaxFormField.zugField(
                code: "620",
                taxCategoryType: .vehicle,
                mainCategory: .vermoegen,
                category: .fahrzeuge,
                descriptionDe: "Motorfahrzeuge, Schiffe und Flugzeuge",
                descriptionEn: "Motor vehicles, boats and aircraft",
                descriptionFr: "Véhicules à moteur, bateaux et aéronefs",
                descriptionIt: "Veicoli a motore, imbarcazioni e aeromobili",
                pageNumber: 4,
                sortOrder: 220,
                isRequired: false
            ),

            // LIABILITIES FIELDS (Schulden)

            TaxFormField.zugField(
                code: "700",
                taxCategoryType: .mortgage,
                mainCategory: .schulden,
                category: .hypotheken,
                descriptionDe: "Hypothekarschulden",
                descriptionEn: "Mortgage debts",
                descriptionFr: "Dettes hypothécaires",
                descriptionIt: "Debiti ipotecari",
                pageNumber: 4,
                sortOrder: 300,
                isRequired: false
            ),

            TaxFormField.zugField(
                code: "710",
                taxCategoryType: .loanDebt,
                mainCategory: .schulden,
                category: .kredite,
                descriptionDe: "Übrige Schulden",
                descriptionEn: "Other debts",
                descriptionFr: "Autres dettes",
                descriptionIt: "Altri debiti",
                pageNumber: 4,
                sortOrder: 310,
                isRequired: false
            ),
        ]
    }

    // MARK: - Basel-Stadt (BS) Fields

    static func generateBaselFields() -> [TaxFormField] {
        return [
            // INCOME FIELDS (Einkommen)

            // Field 8 - Employment Income
            TaxFormField.baselField(
                fieldNumber: "8",
                taxCategoryType: .salary,
                mainCategory: .einkommen,
                category: .unselbstaendigeErwerbstaetigkeit,
                descriptionDe: "Bruttolohn aus unselbständiger Erwerbstätigkeit",
                descriptionEn: "Gross salary from employment",
                descriptionFr: "Salaire brut d'une activité lucrative dépendante",
                descriptionIt: "Salario lordo da attività lucrativa dipendente",
                pageNumber: 2,
                sortOrder: 10,
                isRequired: false
            ),

            // Field 5 - Participation Rights
            TaxFormField.baselField(
                fieldNumber: "5",
                taxCategoryType: .stockOptions,
                mainCategory: .einkommen,
                category: .unselbstaendigeErwerbstaetigkeit,
                subcategory: "Beteiligungsrechte",
                descriptionDe: "Beteiligungsrechte gemäss Beilage",
                descriptionEn: "Participation rights per supplement",
                descriptionFr: "Droits de participation selon annexe",
                descriptionIt: "Diritti di partecipazione secondo allegato",
                pageNumber: 2,
                sortOrder: 20,
                isRequired: false
            ),

            // Field 6 - Board Compensation
            TaxFormField.baselField(
                fieldNumber: "6",
                taxCategoryType: .boardCompensation,
                mainCategory: .einkommen,
                category: .unselbstaendigeErwerbstaetigkeit,
                subcategory: "Verwaltungsratsentschädigung",
                descriptionDe: "Verwaltungsratsentschädigung",
                descriptionEn: "Board of directors' compensation",
                descriptionFr: "Indemnités de conseil d'administration",
                descriptionIt: "Indennità del consiglio di amministrazione",
                pageNumber: 2,
                sortOrder: 30,
                isRequired: false
            ),

            // Self-Employment
            TaxFormField.baselField(
                fieldNumber: "10",
                taxCategoryType: .freelance,
                mainCategory: .einkommen,
                category: .selbstaendigeErwerbstaetigkeit,
                descriptionDe: "Einkommen aus selbständiger Erwerbstätigkeit",
                descriptionEn: "Income from self-employment",
                descriptionFr: "Revenu d'une activité lucrative indépendante",
                descriptionIt: "Reddito da attività lucrativa indipendente",
                pageNumber: 2,
                sortOrder: 40,
                isRequired: false
            ),

            // Investment Income
            TaxFormField.baselField(
                fieldNumber: "15",
                taxCategoryType: .investment,
                mainCategory: .einkommen,
                category: .wertschriftenUndGuthaben,
                descriptionDe: "Einkünfte aus beweglichem Vermögen",
                descriptionEn: "Income from movable assets",
                descriptionFr: "Revenus de la fortune mobilière",
                descriptionIt: "Redditi della sostanza mobiliare",
                pageNumber: 2,
                sortOrder: 50,
                isRequired: false
            ),

            // Rental Income
            TaxFormField.baselField(
                fieldNumber: "18",
                taxCategoryType: .rental,
                mainCategory: .einkommen,
                category: .liegenschaften,
                descriptionDe: "Einkünfte aus unbeweglichem Vermögen",
                descriptionEn: "Income from real estate",
                descriptionFr: "Revenus immobiliers",
                descriptionIt: "Redditi immobiliari",
                pageNumber: 2,
                sortOrder: 60,
                isRequired: false
            ),

            // Pension
            TaxFormField.baselField(
                fieldNumber: "20",
                taxCategoryType: .pension,
                mainCategory: .einkommen,
                category: .vorsorge,
                descriptionDe: "Renten und andere wiederkehrende Leistungen",
                descriptionEn: "Pensions and other recurring benefits",
                descriptionFr: "Rentes et autres prestations périodiques",
                descriptionIt: "Rendite e altre prestazioni periodiche",
                pageNumber: 2,
                sortOrder: 70,
                isRequired: false
            ),

            // DEDUCTION FIELDS (Abzüge)

            // Field 9 - Social Contributions
            TaxFormField.baselField(
                fieldNumber: "9",
                taxCategoryType: .socialSecurity,
                mainCategory: .abzuege,
                category: .versicherungen,
                subcategory: "AHV/IV/EO/ALV",
                descriptionDe: "AHV/IV/EO/ALV/NBUV-Beiträge",
                descriptionEn: "Social security contributions",
                descriptionFr: "Cotisations AVS/AI/APG/AC",
                descriptionIt: "Contributi AVS/AI/IPG/AD",
                pageNumber: 3,
                sortOrder: 100,
                isRequired: false
            ),

            // Field 12 - Withholding Tax
            TaxFormField.baselField(
                fieldNumber: "12",
                taxCategoryType: .withholdingTax,
                mainCategory: .abzuege,
                category: .versicherungen,
                subcategory: "Quellensteuer",
                descriptionDe: "Abzug Quellensteuer",
                descriptionEn: "Withholding tax deduction",
                descriptionFr: "Déduction impôt à la source",
                descriptionIt: "Deduzione imposta alla fonte",
                pageNumber: 3,
                sortOrder: 110,
                isRequired: false
            ),

            // Field 13 - Expense Allowances
            TaxFormField.baselField(
                fieldNumber: "13",
                taxCategoryType: .professionalExpenses,
                mainCategory: .abzuege,
                category: .berufsauslagen,
                descriptionDe: "Spesenentschädigungen (nicht in Bruttolohn enthalten)",
                descriptionEn: "Expense allowances (not included in gross salary)",
                descriptionFr: "Indemnités pour frais (non comprises dans le salaire brut)",
                descriptionIt: "Indennità per spese (non comprese nel salario lordo)",
                pageNumber: 3,
                sortOrder: 120,
                isRequired: false
            ),

            // Insurance Premiums
            TaxFormField.baselField(
                fieldNumber: "30",
                taxCategoryType: .healthInsurance,
                mainCategory: .abzuege,
                category: .versicherungen,
                descriptionDe: "Versicherungsprämien und Sparzinsen",
                descriptionEn: "Insurance premiums and savings interest",
                descriptionFr: "Primes d'assurance et intérêts d'épargne",
                descriptionIt: "Premi assicurativi e interessi di risparmio",
                pageNumber: 3,
                sortOrder: 130,
                isRequired: false
            ),

            // Pillar 3a
            TaxFormField.baselField(
                fieldNumber: "32",
                taxCategoryType: .pillar3a,
                mainCategory: .abzuege,
                category: .versicherungen,
                subcategory: "Säule 3a",
                descriptionDe: "Einlagen gebundene Selbstvorsorge (Säule 3a)",
                descriptionEn: "Tied pension contributions (pillar 3a)",
                descriptionFr: "Versements prévoyance liée (pilier 3a)",
                descriptionIt: "Versamenti previdenza vincolata (pilastro 3a)",
                pageNumber: 3,
                sortOrder: 140,
                isRequired: false
            ),

            // Interest on Debts
            TaxFormField.baselField(
                fieldNumber: "35",
                taxCategoryType: .mortgageInterest,
                mainCategory: .abzuege,
                category: .schuldzinsen,
                descriptionDe: "Schuldzinsen",
                descriptionEn: "Interest on debts",
                descriptionFr: "Intérêts passifs",
                descriptionIt: "Interessi passivi",
                pageNumber: 3,
                sortOrder: 150,
                isRequired: false
            ),

            // Donations
            TaxFormField.baselField(
                fieldNumber: "40",
                taxCategoryType: .donations,
                mainCategory: .abzuege,
                category: .spenden,
                descriptionDe: "Zuwendungen an gemeinnützige Institutionen",
                descriptionEn: "Donations to charitable organizations",
                descriptionFr: "Dons à des institutions d'utilité publique",
                descriptionIt: "Donazioni a istituzioni di utilità pubblica",
                pageNumber: 3,
                sortOrder: 160,
                isRequired: false
            ),

            // Childcare
            TaxFormField.baselField(
                fieldNumber: "42",
                taxCategoryType: .childcare,
                mainCategory: .abzuege,
                category: .kinderbetreuung,
                descriptionDe: "Kinderbetreuungskosten durch Dritte",
                descriptionEn: "Third-party childcare costs",
                descriptionFr: "Frais de garde d'enfants par des tiers",
                descriptionIt: "Spese di custodia di figli da parte di terzi",
                pageNumber: 3,
                sortOrder: 170,
                isRequired: false
            ),

            // WEALTH FIELDS (Vermögen)

            TaxFormField.baselField(
                fieldNumber: "50",
                taxCategoryType: .securities,
                mainCategory: .vermoegen,
                category: .wertpapiere,
                descriptionDe: "Wertschriften und Guthaben",
                descriptionEn: "Securities and credit balances",
                descriptionFr: "Titres et avoirs",
                descriptionIt: "Titoli e averi",
                pageNumber: 4,
                sortOrder: 200,
                isRequired: false
            ),

            TaxFormField.baselField(
                fieldNumber: "55",
                taxCategoryType: .realEstate,
                mainCategory: .vermoegen,
                category: .immobilien,
                descriptionDe: "Liegenschaften",
                descriptionEn: "Real estate",
                descriptionFr: "Immeubles",
                descriptionIt: "Immobili",
                pageNumber: 4,
                sortOrder: 210,
                isRequired: false
            ),

            // LIABILITIES FIELDS (Schulden)

            TaxFormField.baselField(
                fieldNumber: "60",
                taxCategoryType: .mortgage,
                mainCategory: .schulden,
                category: .hypotheken,
                descriptionDe: "Hypothekarschulden",
                descriptionEn: "Mortgage debts",
                descriptionFr: "Dettes hypothécaires",
                descriptionIt: "Debiti ipotecari",
                pageNumber: 4,
                sortOrder: 300,
                isRequired: false
            ),

            TaxFormField.baselField(
                fieldNumber: "65",
                taxCategoryType: .loanDebt,
                mainCategory: .schulden,
                category: .kredite,
                descriptionDe: "Übrige Schulden",
                descriptionEn: "Other debts",
                descriptionFr: "Autres dettes",
                descriptionIt: "Altri debiti",
                pageNumber: 4,
                sortOrder: 310,
                isRequired: false
            ),
        ]
    }

    // MARK: - Solothurn (SO) Fields

    static func generateSolothurnFields() -> [TaxFormField] {
        return [
            // INCOME FIELDS (Einkommen)

            // Index 100-102 - Employment Income Person 1
            TaxFormField.solothurnField(
                index: "100",
                taxCategoryType: .salary,
                mainCategory: .einkommen,
                category: .unselbstaendigeErwerbstaetigkeit,
                subcategory: "Person 1",
                descriptionDe: "Einkommen aus unselbständiger Erwerbstätigkeit (Haupterwerb) Person 1",
                descriptionEn: "Income from employment (main occupation) person 1",
                descriptionFr: "Revenu d'une activité lucrative dépendante (activité principale) personne 1",
                descriptionIt: "Reddito da attività lucrativa dipendente (attività principale) persona 1",
                pageNumber: 2,
                sortOrder: 10,
                isRequired: false
            ),

            TaxFormField.solothurnField(
                index: "101",
                taxCategoryType: .bonus,
                mainCategory: .einkommen,
                category: .unselbstaendigeErwerbstaetigkeit,
                subcategory: "Person 1 - Nebenerwerb",
                descriptionDe: "Einkommen aus unselbständiger Erwerbstätigkeit (Nebenerwerb) Person 1",
                descriptionEn: "Income from employment (secondary occupation) person 1",
                descriptionFr: "Revenu d'une activité lucrative dépendante (activité accessoire) personne 1",
                descriptionIt: "Reddito da attività lucrativa dipendente (attività accessoria) persona 1",
                pageNumber: 2,
                sortOrder: 20,
                isRequired: false
            ),

            // Index 110-111 - Employment Income Person 2
            TaxFormField.solothurnField(
                index: "110",
                taxCategoryType: .salary,
                mainCategory: .einkommen,
                category: .unselbstaendigeErwerbstaetigkeit,
                subcategory: "Person 2",
                descriptionDe: "Einkommen aus unselbständiger Erwerbstätigkeit (Haupterwerb) Person 2",
                descriptionEn: "Income from employment (main occupation) person 2",
                descriptionFr: "Revenu d'une activité lucrative dépendante (activité principale) personne 2",
                descriptionIt: "Reddito da attività lucrativa dipendente (attività principale) persona 2",
                pageNumber: 2,
                sortOrder: 30,
                isRequired: false
            ),

            TaxFormField.solothurnField(
                index: "111",
                taxCategoryType: .bonus,
                mainCategory: .einkommen,
                category: .unselbstaendigeErwerbstaetigkeit,
                subcategory: "Person 2 - Nebenerwerb",
                descriptionDe: "Einkommen aus unselbständiger Erwerbstätigkeit (Nebenerwerb) Person 2",
                descriptionEn: "Income from employment (secondary occupation) person 2",
                descriptionFr: "Revenu d'une activité lucrative dépendante (activité accessoire) personne 2",
                descriptionIt: "Reddito da attività lucrativa dipendente (attività accessoria) persona 2",
                pageNumber: 2,
                sortOrder: 40,
                isRequired: false
            ),

            // Index 120-121 - Self-Employment
            TaxFormField.solothurnField(
                index: "120",
                taxCategoryType: .freelance,
                mainCategory: .einkommen,
                category: .selbstaendigeErwerbstaetigkeit,
                subcategory: "Person 1",
                descriptionDe: "Einkommen aus selbständiger Erwerbstätigkeit Person 1",
                descriptionEn: "Income from self-employment person 1",
                descriptionFr: "Revenu d'une activité lucrative indépendante personne 1",
                descriptionIt: "Reddito da attività lucrativa indipendente persona 1",
                pageNumber: 2,
                sortOrder: 50,
                isRequired: false
            ),

            TaxFormField.solothurnField(
                index: "121",
                taxCategoryType: .freelance,
                mainCategory: .einkommen,
                category: .selbstaendigeErwerbstaetigkeit,
                subcategory: "Person 2",
                descriptionDe: "Einkommen aus selbständiger Erwerbstätigkeit Person 2",
                descriptionEn: "Income from self-employment person 2",
                descriptionFr: "Revenu d'une activité lucrative indépendante personne 2",
                descriptionIt: "Reddito da attività lucrativa indipendente persona 2",
                pageNumber: 2,
                sortOrder: 60,
                isRequired: false
            ),

            // Index 122-123 - Secondary Self-Employment
            TaxFormField.solothurnField(
                index: "122",
                taxCategoryType: .freelance,
                mainCategory: .einkommen,
                category: .selbstaendigeErwerbstaetigkeit,
                subcategory: "Person 1 - Nebenerwerb",
                descriptionDe: "Einkommen aus nebenberuflicher selbständiger Erwerbstätigkeit Person 1",
                descriptionEn: "Income from part-time self-employment person 1",
                descriptionFr: "Revenu d'une activité lucrative indépendante accessoire personne 1",
                descriptionIt: "Reddito da attività lucrativa indipendente accessoria persona 1",
                pageNumber: 2,
                sortOrder: 70,
                isRequired: false
            ),

            TaxFormField.solothurnField(
                index: "123",
                taxCategoryType: .freelance,
                mainCategory: .einkommen,
                category: .selbstaendigeErwerbstaetigkeit,
                subcategory: "Person 2 - Nebenerwerb",
                descriptionDe: "Einkommen aus nebenberuflicher selbständiger Erwerbstätigkeit Person 2",
                descriptionEn: "Income from part-time self-employment person 2",
                descriptionFr: "Revenu d'une activité lucrative indépendante accessoire personne 2",
                descriptionIt: "Reddito da attività lucrativa indipendente accessoria persona 2",
                pageNumber: 2,
                sortOrder: 80,
                isRequired: false
            ),

            // Index 130-131 - Pension Fund Benefits
            TaxFormField.solothurnField(
                index: "130",
                taxCategoryType: .pension,
                mainCategory: .einkommen,
                category: .vorsorge,
                subcategory: "Person 1",
                descriptionDe: "Leistungen aus Vorsorgeeinrichtungen Person 1",
                descriptionEn: "Pension fund benefits person 1",
                descriptionFr: "Prestations d'institutions de prévoyance personne 1",
                descriptionIt: "Prestazioni da istituzioni di previdenza persona 1",
                pageNumber: 2,
                sortOrder: 90,
                isRequired: false
            ),

            TaxFormField.solothurnField(
                index: "131",
                taxCategoryType: .pension,
                mainCategory: .einkommen,
                category: .vorsorge,
                subcategory: "Person 2",
                descriptionDe: "Leistungen aus Vorsorgeeinrichtungen Person 2",
                descriptionEn: "Pension fund benefits person 2",
                descriptionFr: "Prestations d'institutions de prévoyance personne 2",
                descriptionIt: "Prestazioni da istituzioni di previdenza persona 2",
                pageNumber: 2,
                sortOrder: 100,
                isRequired: false
            ),

            // Index 140-141 - Other Pensions
            TaxFormField.solothurnField(
                index: "140",
                taxCategoryType: .pension,
                mainCategory: .einkommen,
                category: .vorsorge,
                subcategory: "Person 1 - Übrige Renten",
                descriptionDe: "Übrige Renten Person 1",
                descriptionEn: "Other pensions person 1",
                descriptionFr: "Autres rentes personne 1",
                descriptionIt: "Altre rendite persona 1",
                pageNumber: 2,
                sortOrder: 110,
                isRequired: false
            ),

            TaxFormField.solothurnField(
                index: "141",
                taxCategoryType: .pension,
                mainCategory: .einkommen,
                category: .vorsorge,
                subcategory: "Person 2 - Übrige Renten",
                descriptionDe: "Übrige Renten Person 2",
                descriptionEn: "Other pensions person 2",
                descriptionFr: "Autres rentes personne 2",
                descriptionIt: "Altre rendite persona 2",
                pageNumber: 2,
                sortOrder: 120,
                isRequired: false
            ),

            // Index 150-151 - Investment Income
            TaxFormField.solothurnField(
                index: "150",
                taxCategoryType: .investment,
                mainCategory: .einkommen,
                category: .wertschriftenUndGuthaben,
                subcategory: "Person 1",
                descriptionDe: "Einkünfte aus beweglichem Vermögen Person 1",
                descriptionEn: "Income from movable assets person 1",
                descriptionFr: "Revenus de la fortune mobilière personne 1",
                descriptionIt: "Redditi della sostanza mobiliare persona 1",
                pageNumber: 2,
                sortOrder: 130,
                isRequired: false
            ),

            TaxFormField.solothurnField(
                index: "151",
                taxCategoryType: .investment,
                mainCategory: .einkommen,
                category: .wertschriftenUndGuthaben,
                subcategory: "Person 2",
                descriptionDe: "Einkünfte aus beweglichem Vermögen Person 2",
                descriptionEn: "Income from movable assets person 2",
                descriptionFr: "Revenus de la fortune mobilière personne 2",
                descriptionIt: "Redditi della sostanza mobiliare persona 2",
                pageNumber: 2,
                sortOrder: 140,
                isRequired: false
            ),

            // Index 160-161 - Rental Income
            TaxFormField.solothurnField(
                index: "160",
                taxCategoryType: .rental,
                mainCategory: .einkommen,
                category: .liegenschaften,
                subcategory: "Person 1",
                descriptionDe: "Einkünfte aus unbeweglichem Vermögen Person 1",
                descriptionEn: "Income from real estate person 1",
                descriptionFr: "Revenus immobiliers personne 1",
                descriptionIt: "Redditi immobiliari persona 1",
                pageNumber: 2,
                sortOrder: 150,
                isRequired: false
            ),

            TaxFormField.solothurnField(
                index: "161",
                taxCategoryType: .rental,
                mainCategory: .einkommen,
                category: .liegenschaften,
                subcategory: "Person 2",
                descriptionDe: "Einkünfte aus unbeweglichem Vermögen Person 2",
                descriptionEn: "Income from real estate person 2",
                descriptionFr: "Revenus immobiliers personne 2",
                descriptionIt: "Redditi immobiliari persona 2",
                pageNumber: 2,
                sortOrder: 160,
                isRequired: false
            ),

            // Index 170-172 - Other Income
            TaxFormField.solothurnField(
                index: "170",
                taxCategoryType: .childAllowance,
                mainCategory: .einkommen,
                category: .uebrigeEinkuenfte,
                subcategory: "Unterhalt",
                descriptionDe: "Erhaltene Unterhaltsbeiträge",
                descriptionEn: "Received alimony payments",
                descriptionFr: "Contributions d'entretien reçues",
                descriptionIt: "Contributi di mantenimento ricevuti",
                pageNumber: 2,
                sortOrder: 170,
                isRequired: false
            ),

            TaxFormField.solothurnField(
                index: "171",
                taxCategoryType: .unemploymentBenefits,
                mainCategory: .einkommen,
                category: .uebrigeEinkuenfte,
                subcategory: "Ersatzeinkommen",
                descriptionDe: "Ersatzeinkommen (Arbeitslosenentschädigung, Krankentaggeld, Militärersatz, etc.)",
                descriptionEn: "Replacement income (unemployment benefits, sick pay, military replacement, etc.)",
                descriptionFr: "Revenu de remplacement (indemnités de chômage, indemnités journalières maladie, solde militaire de remplacement, etc.)",
                descriptionIt: "Reddito sostitutivo (indennità di disoccupazione, indennità giornaliera di malattia, soldo militare sostitutivo, ecc.)",
                pageNumber: 2,
                sortOrder: 180,
                isRequired: false
            ),

            TaxFormField.solothurnField(
                index: "172",
                taxCategoryType: .lotteryWinnings,
                mainCategory: .einkommen,
                category: .uebrigeEinkuenfte,
                subcategory: "Gewinne",
                descriptionDe: "Gewinne aus Lotterien, Geschicklichkeitsspielen, Preisausschreiben",
                descriptionEn: "Winnings from lotteries, skill games, competitions",
                descriptionFr: "Gains de loteries, jeux d'adresse, concours",
                descriptionIt: "Vincite da lotterie, giochi d'abilità, concorsi",
                pageNumber: 2,
                sortOrder: 190,
                isRequired: false
            ),

            // Index 180-183 - Capital Settlements
            TaxFormField.solothurnField(
                index: "180",
                taxCategoryType: .pillar3a,
                mainCategory: .einkommen,
                category: .vorsorge,
                subcategory: "Kapitalabfindungen Bund",
                descriptionDe: "Kapitalabfindungen aus Vorsorge (separate Bundessteuer)",
                descriptionEn: "Capital settlements from pension (separate federal tax)",
                descriptionFr: "Versements en capital de prévoyance (impôt fédéral séparé)",
                descriptionIt: "Prestazioni in capitale da previdenza (imposta federale separata)",
                pageNumber: 2,
                sortOrder: 200,
                isRequired: false
            ),

            TaxFormField.solothurnField(
                index: "181",
                taxCategoryType: .pillar3a,
                mainCategory: .einkommen,
                category: .vorsorge,
                subcategory: "Kapitalabfindungen Kanton",
                descriptionDe: "Kapitalabfindungen aus Vorsorge (separate Kantonssteuer)",
                descriptionEn: "Capital settlements from pension (separate cantonal tax)",
                descriptionFr: "Versements en capital de prévoyance (impôt cantonal séparé)",
                descriptionIt: "Prestazioni in capitale da previdenza (imposta cantonale separata)",
                pageNumber: 2,
                sortOrder: 210,
                isRequired: false
            ),

            // DEDUCTION FIELDS (Abzüge)

            // Index 200-201 - Professional Expenses
            TaxFormField.solothurnField(
                index: "200",
                taxCategoryType: .professionalExpenses,
                mainCategory: .abzuege,
                category: .berufsauslagen,
                subcategory: "Person 1",
                descriptionDe: "Berufsauslagen Person 1",
                descriptionEn: "Professional expenses person 1",
                descriptionFr: "Frais professionnels personne 1",
                descriptionIt: "Spese professionali persona 1",
                pageNumber: 3,
                sortOrder: 300,
                isRequired: false
            ),

            TaxFormField.solothurnField(
                index: "201",
                taxCategoryType: .professionalExpenses,
                mainCategory: .abzuege,
                category: .berufsauslagen,
                subcategory: "Person 2",
                descriptionDe: "Berufsauslagen Person 2",
                descriptionEn: "Professional expenses person 2",
                descriptionFr: "Frais professionnels personne 2",
                descriptionIt: "Spese professionali persona 2",
                pageNumber: 3,
                sortOrder: 310,
                isRequired: false
            ),

            // Index 210 - Alimony Paid
            TaxFormField.solothurnField(
                index: "210",
                taxCategoryType: .alimony,
                mainCategory: .abzuege,
                category: .unterhalt,
                descriptionDe: "Bezahlte Unterhaltsbeiträge",
                descriptionEn: "Paid alimony",
                descriptionFr: "Contributions d'entretien versées",
                descriptionIt: "Contributi di mantenimento versati",
                pageNumber: 3,
                sortOrder: 320,
                isRequired: false
            ),

            // Index 220-221 - Voluntary Annuities
            TaxFormField.solothurnField(
                index: "220",
                taxCategoryType: .voluntaryAnnuities,
                mainCategory: .abzuege,
                category: .unterhalt,
                subcategory: "Person 1",
                descriptionDe: "Freiwillig erbrachte Leibrenten Person 1",
                descriptionEn: "Voluntary annuities person 1",
                descriptionFr: "Rentes viagères volontaires personne 1",
                descriptionIt: "Rendite vitalizie volontarie persona 1",
                pageNumber: 3,
                sortOrder: 330,
                isRequired: false
            ),

            TaxFormField.solothurnField(
                index: "221",
                taxCategoryType: .voluntaryAnnuities,
                mainCategory: .abzuege,
                category: .unterhalt,
                subcategory: "Person 2",
                descriptionDe: "Freiwillig erbrachte Leibrenten Person 2",
                descriptionEn: "Voluntary annuities person 2",
                descriptionFr: "Rentes viagères volontaires personne 2",
                descriptionIt: "Rendite vitalizie volontarie persona 2",
                pageNumber: 3,
                sortOrder: 340,
                isRequired: false
            ),

            // Index 230 - Support for Needy Persons
            TaxFormField.solothurnField(
                index: "230",
                taxCategoryType: .supportNeedyPersons,
                mainCategory: .abzuege,
                category: .unterhalt,
                descriptionDe: "Selbstgetragener Unterhalt bedürftiger Personen",
                descriptionEn: "Self-paid support for needy persons",
                descriptionFr: "Entretien assumé de personnes nécessiteuses",
                descriptionIt: "Mantenimento sostenuto di persone bisognose",
                pageNumber: 3,
                sortOrder: 350,
                isRequired: false
            ),

            // Index 240 - Interest on Debts
            TaxFormField.solothurnField(
                index: "240",
                taxCategoryType: .mortgageInterest,
                mainCategory: .abzuege,
                category: .schuldzinsen,
                descriptionDe: "Schuldzinsen",
                descriptionEn: "Interest on debts",
                descriptionFr: "Intérêts passifs",
                descriptionIt: "Interessi passivi",
                pageNumber: 3,
                sortOrder: 360,
                isRequired: false
            ),

            // Index 250 - Charitable Donations
            TaxFormField.solothurnField(
                index: "250",
                taxCategoryType: .donations,
                mainCategory: .abzuege,
                category: .spenden,
                descriptionDe: "Zuwendungen an gemeinnützige Institutionen",
                descriptionEn: "Donations to charitable organizations",
                descriptionFr: "Dons à des institutions d'utilité publique",
                descriptionIt: "Donazioni a istituzioni di utilità pubblica",
                pageNumber: 3,
                sortOrder: 370,
                isRequired: false
            ),

            // Index 260 - Political Donations
            TaxFormField.solothurnField(
                index: "260",
                taxCategoryType: .politicalDonations,
                mainCategory: .abzuege,
                category: .spenden,
                descriptionDe: "Zuwendungen an politische Parteien",
                descriptionEn: "Donations to political parties",
                descriptionFr: "Dons aux partis politiques",
                descriptionIt: "Donazioni a partiti politici",
                pageNumber: 3,
                sortOrder: 380,
                isRequired: false
            ),

            // Index 270-271 - Professional Association Fees
            TaxFormField.solothurnField(
                index: "270",
                taxCategoryType: .professionalAssociationFees,
                mainCategory: .abzuege,
                category: .weiterbildung,
                subcategory: "Person 1",
                descriptionDe: "Beiträge an Berufsverbände Person 1",
                descriptionEn: "Professional association fees person 1",
                descriptionFr: "Cotisations aux associations professionnelles personne 1",
                descriptionIt: "Contributi alle associazioni professionali persona 1",
                pageNumber: 3,
                sortOrder: 390,
                isRequired: false
            ),

            TaxFormField.solothurnField(
                index: "271",
                taxCategoryType: .professionalAssociationFees,
                mainCategory: .abzuege,
                category: .weiterbildung,
                subcategory: "Person 2",
                descriptionDe: "Beiträge an Berufsverbände Person 2",
                descriptionEn: "Professional association fees person 2",
                descriptionFr: "Cotisations aux associations professionnelles personne 2",
                descriptionIt: "Contributi alle associazioni professionali persona 2",
                pageNumber: 3,
                sortOrder: 400,
                isRequired: false
            ),

            // Index 280-283 - Pillar 2 Buyback
            TaxFormField.solothurnField(
                index: "280",
                taxCategoryType: .pillar2Buyback,
                mainCategory: .abzuege,
                category: .versicherungen,
                subcategory: "Person 1 - Einkauf Säule 2",
                descriptionDe: "Einkäufe in die berufliche Vorsorge Person 1",
                descriptionEn: "Pillar 2 buyback person 1",
                descriptionFr: "Rachats dans la prévoyance professionnelle personne 1",
                descriptionIt: "Riscatti nella previdenza professionale persona 1",
                pageNumber: 3,
                sortOrder: 410,
                isRequired: false
            ),

            TaxFormField.solothurnField(
                index: "281",
                taxCategoryType: .pillar2Buyback,
                mainCategory: .abzuege,
                category: .versicherungen,
                subcategory: "Person 2 - Einkauf Säule 2",
                descriptionDe: "Einkäufe in die berufliche Vorsorge Person 2",
                descriptionEn: "Pillar 2 buyback person 2",
                descriptionFr: "Rachats dans la prévoyance professionnelle personne 2",
                descriptionIt: "Riscatti nella previdenza professionale persona 2",
                pageNumber: 3,
                sortOrder: 420,
                isRequired: false
            ),

            // Index 290-291 - Pillar 3a Contributions
            TaxFormField.solothurnField(
                index: "290",
                taxCategoryType: .pillar3a,
                mainCategory: .abzuege,
                category: .versicherungen,
                subcategory: "Person 1 - Säule 3a",
                descriptionDe: "Einlagen Säule 3a Person 1",
                descriptionEn: "Pillar 3a contributions person 1",
                descriptionFr: "Cotisations pilier 3a personne 1",
                descriptionIt: "Contributi pilastro 3a persona 1",
                pageNumber: 3,
                sortOrder: 430,
                isRequired: false
            ),

            TaxFormField.solothurnField(
                index: "291",
                taxCategoryType: .pillar3a,
                mainCategory: .abzuege,
                category: .versicherungen,
                subcategory: "Person 2 - Säule 3a",
                descriptionDe: "Einlagen Säule 3a Person 2",
                descriptionEn: "Pillar 3a contributions person 2",
                descriptionFr: "Cotisations pilier 3a personne 2",
                descriptionIt: "Contributi pilastro 3a persona 2",
                pageNumber: 3,
                sortOrder: 440,
                isRequired: false
            ),

            // Index 300-301 - Special Deductions
            TaxFormField.solothurnField(
                index: "300",
                taxCategoryType: .specialDeductions,
                mainCategory: .abzuege,
                category: .versicherungen,
                subcategory: "Versicherungen und Sparzinsen",
                descriptionDe: "Versicherungsprämien und Sparzinsen",
                descriptionEn: "Insurance premiums and savings interest",
                descriptionFr: "Primes d'assurance et intérêts d'épargne",
                descriptionIt: "Premi assicurativi e interessi di risparmio",
                pageNumber: 3,
                sortOrder: 450,
                isRequired: false
            ),

            TaxFormField.solothurnField(
                index: "301",
                taxCategoryType: .childcare,
                mainCategory: .abzuege,
                category: .kinderbetreuung,
                descriptionDe: "Kinderbetreuungskosten durch Dritte",
                descriptionEn: "Third-party childcare costs",
                descriptionFr: "Frais de garde d'enfants par des tiers",
                descriptionIt: "Spese di custodia di figli da parte di terzi",
                pageNumber: 3,
                sortOrder: 460,
                isRequired: false
            ),

            // WEALTH FIELDS (Vermögen)

            // Index 500-501 - Securities and Credit Balances
            TaxFormField.solothurnField(
                index: "500",
                taxCategoryType: .securities,
                mainCategory: .vermoegen,
                category: .wertpapiere,
                subcategory: "Person 1",
                descriptionDe: "Wertschriften und Guthaben Person 1",
                descriptionEn: "Securities and credit balances person 1",
                descriptionFr: "Titres et avoirs personne 1",
                descriptionIt: "Titoli e averi persona 1",
                pageNumber: 4,
                sortOrder: 500,
                isRequired: false
            ),

            TaxFormField.solothurnField(
                index: "501",
                taxCategoryType: .securities,
                mainCategory: .vermoegen,
                category: .wertpapiere,
                subcategory: "Person 2",
                descriptionDe: "Wertschriften und Guthaben Person 2",
                descriptionEn: "Securities and credit balances person 2",
                descriptionFr: "Titres et avoirs personne 2",
                descriptionIt: "Titoli e averi persona 2",
                pageNumber: 4,
                sortOrder: 510,
                isRequired: false
            ),

            // Index 510-511 - Life Insurance
            TaxFormField.solothurnField(
                index: "510",
                taxCategoryType: .lifeInsurance,
                mainCategory: .vermoegen,
                category: .versicherungen,
                subcategory: "Person 1",
                descriptionDe: "Rückkaufswert Lebensversicherungen Person 1",
                descriptionEn: "Surrender value life insurance person 1",
                descriptionFr: "Valeur de rachat assurances-vie personne 1",
                descriptionIt: "Valore di riscatto assicurazioni vita persona 1",
                pageNumber: 4,
                sortOrder: 520,
                isRequired: false
            ),

            TaxFormField.solothurnField(
                index: "511",
                taxCategoryType: .lifeInsurance,
                mainCategory: .vermoegen,
                category: .versicherungen,
                subcategory: "Person 2",
                descriptionDe: "Rückkaufswert Lebensversicherungen Person 2",
                descriptionEn: "Surrender value life insurance person 2",
                descriptionFr: "Valeur de rachat assurances-vie personne 2",
                descriptionIt: "Valore di riscatto assicurazioni vita persona 2",
                pageNumber: 4,
                sortOrder: 530,
                isRequired: false
            ),

            // Index 520-521 - Household Goods
            TaxFormField.solothurnField(
                index: "520",
                taxCategoryType: .householdGoods,
                mainCategory: .vermoegen,
                category: .uebrigesVermoegen,
                subcategory: "Person 1",
                descriptionDe: "Hausrat und persönliche Gegenstände Person 1",
                descriptionEn: "Household goods and personal items person 1",
                descriptionFr: "Mobilier et effets personnels personne 1",
                descriptionIt: "Mobilio ed effetti personali persona 1",
                pageNumber: 4,
                sortOrder: 540,
                isRequired: false
            ),

            TaxFormField.solothurnField(
                index: "521",
                taxCategoryType: .householdGoods,
                mainCategory: .vermoegen,
                category: .uebrigesVermoegen,
                subcategory: "Person 2",
                descriptionDe: "Hausrat und persönliche Gegenstände Person 2",
                descriptionEn: "Household goods and personal items person 2",
                descriptionFr: "Mobilier et effets personnels personne 2",
                descriptionIt: "Mobilio ed effetti personali persona 2",
                pageNumber: 4,
                sortOrder: 550,
                isRequired: false
            ),

            // Index 530-531 - Real Estate Tax Value
            TaxFormField.solothurnField(
                index: "530",
                taxCategoryType: .realEstate,
                mainCategory: .vermoegen,
                category: .immobilien,
                subcategory: "Person 1",
                descriptionDe: "Steuerwert Liegenschaften Person 1",
                descriptionEn: "Real estate tax value person 1",
                descriptionFr: "Valeur fiscale immeubles personne 1",
                descriptionIt: "Valore fiscale immobili persona 1",
                pageNumber: 4,
                sortOrder: 560,
                isRequired: false
            ),

            TaxFormField.solothurnField(
                index: "531",
                taxCategoryType: .realEstate,
                mainCategory: .vermoegen,
                category: .immobilien,
                subcategory: "Person 2",
                descriptionDe: "Steuerwert Liegenschaften Person 2",
                descriptionEn: "Real estate tax value person 2",
                descriptionFr: "Valeur fiscale immeubles personne 2",
                descriptionIt: "Valore fiscale immobili persona 2",
                pageNumber: 4,
                sortOrder: 570,
                isRequired: false
            ),

            // Index 540-541 - Other Assets
            TaxFormField.solothurnField(
                index: "540",
                taxCategoryType: .otherAssets,
                mainCategory: .vermoegen,
                category: .uebrigesVermoegen,
                subcategory: "Person 1",
                descriptionDe: "Übriges Vermögen Person 1",
                descriptionEn: "Other assets person 1",
                descriptionFr: "Autre fortune personne 1",
                descriptionIt: "Altra sostanza persona 1",
                pageNumber: 4,
                sortOrder: 580,
                isRequired: false
            ),

            TaxFormField.solothurnField(
                index: "541",
                taxCategoryType: .otherAssets,
                mainCategory: .vermoegen,
                category: .uebrigesVermoegen,
                subcategory: "Person 2",
                descriptionDe: "Übriges Vermögen Person 2",
                descriptionEn: "Other assets person 2",
                descriptionFr: "Autre fortune personne 2",
                descriptionIt: "Altra sostanza persona 2",
                pageNumber: 4,
                sortOrder: 590,
                isRequired: false
            ),

            // Index 550 - Total Assets
            TaxFormField.solothurnField(
                index: "550",
                taxCategoryType: .totalAssets,
                mainCategory: .vermoegen,
                category: .uebrigesVermoegen,
                descriptionDe: "Total Vermögen (Summe)",
                descriptionEn: "Total assets (sum)",
                descriptionFr: "Fortune totale (somme)",
                descriptionIt: "Sostanza totale (somma)",
                pageNumber: 4,
                sortOrder: 600,
                isRequired: false
            ),

            // Index 560 - Shareholdings
            TaxFormField.solothurnField(
                index: "560",
                taxCategoryType: .shareholdings,
                mainCategory: .vermoegen,
                category: .wertpapiere,
                descriptionDe: "Beteiligungen von mindestens 10% am Grund- oder Stammkapital",
                descriptionEn: "Shareholdings of at least 10% of share capital",
                descriptionFr: "Participations d'au moins 10% du capital-actions ou social",
                descriptionIt: "Partecipazioni di almeno il 10% del capitale azionario o sociale",
                pageNumber: 4,
                sortOrder: 610,
                isRequired: false
            ),

            // LIABILITIES FIELDS (Schulden)

            // Index 900 - Total Liabilities
            TaxFormField.solothurnField(
                index: "900",
                taxCategoryType: .totalLiabilities,
                mainCategory: .schulden,
                category: .uebrigeSchulden,
                descriptionDe: "Total Schulden (Summe)",
                descriptionEn: "Total liabilities (sum)",
                descriptionFr: "Dettes totales (somme)",
                descriptionIt: "Debiti totali (somma)",
                pageNumber: 4,
                sortOrder: 900,
                isRequired: false
            ),

            // Index 910-913 - Securities Debts
            TaxFormField.solothurnField(
                index: "910",
                taxCategoryType: .securitiesDebt,
                mainCategory: .schulden,
                category: .kredite,
                subcategory: "Wertschriftendeckung",
                descriptionDe: "Schulden mit Wertschriftendeckung",
                descriptionEn: "Debts with securities collateral",
                descriptionFr: "Dettes avec couverture par titres",
                descriptionIt: "Debiti con copertura titoli",
                pageNumber: 4,
                sortOrder: 910,
                isRequired: false
            ),

            // Index 920-921 - Private Loans
            TaxFormField.solothurnField(
                index: "920",
                taxCategoryType: .privateLoan,
                mainCategory: .schulden,
                category: .kredite,
                subcategory: "Person 1",
                descriptionDe: "Privatdarlehen Person 1",
                descriptionEn: "Private loans person 1",
                descriptionFr: "Prêts privés personne 1",
                descriptionIt: "Prestiti privati persona 1",
                pageNumber: 4,
                sortOrder: 920,
                isRequired: false
            ),

            TaxFormField.solothurnField(
                index: "921",
                taxCategoryType: .privateLoan,
                mainCategory: .schulden,
                category: .kredite,
                subcategory: "Person 2",
                descriptionDe: "Privatdarlehen Person 2",
                descriptionEn: "Private loans person 2",
                descriptionFr: "Prêts privés personne 2",
                descriptionIt: "Prestiti privati persona 2",
                pageNumber: 4,
                sortOrder: 930,
                isRequired: false
            ),

            // Index 999 - Net Wealth
            TaxFormField.solothurnField(
                index: "999",
                taxCategoryType: .totalAssets,
                mainCategory: .vermoegen,
                category: .uebrigesVermoegen,
                descriptionDe: "Reinvermögen (Vermögen - Schulden)",
                descriptionEn: "Net wealth (assets - liabilities)",
                descriptionFr: "Fortune nette (fortune - dettes)",
                descriptionIt: "Sostanza netta (sostanza - debiti)",
                pageNumber: 4,
                sortOrder: 999,
                isRequired: false
            ),
        ]
    }
}
