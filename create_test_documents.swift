#!/usr/bin/env swift

import Foundation

// Script to create test documents in Firestore for testing the Documents view
// Run with: swift create_test_documents.swift <user_id>

let testDocuments = """
[
  {
    "name": "Lohnausweis_2024.pdf",
    "category": "income_proof",
    "subcategory": "lohnausweis",
    "status": "pending",
    "taxYear": 2024,
    "aiConfidence": 0.95,
    "aiSummary": "Lohnausweis from employer XYZ AG",
    "amount": 85000.50,
    "canton": "ZH"
  },
  {
    "name": "Spesenbeleg_Restaurant.pdf",
    "category": "expense",
    "subcategory": "spesenbeleg",
    "status": "pending",
    "taxYear": 2024,
    "aiConfidence": 0.88,
    "aiSummary": "Business lunch expense - Restaurant ABC",
    "amount": 125.80,
    "canton": "ZH"
  },
  {
    "name": "Bank_Statement_UBS.pdf",
    "category": "wealth",
    "subcategory": "bank_statement",
    "status": "pending",
    "taxYear": 2024,
    "aiConfidence": 0.91,
    "aiSummary": "UBS Bank Statement - December 2024",
    "amount": 45000.00,
    "canton": "ZH"
  },
  {
    "name": "Health_Insurance_Premium.pdf",
    "category": "deductions",
    "subcategory": "health_insurance",
    "status": "pending",
    "taxYear": 2024,
    "aiConfidence": 0.93,
    "aiSummary": "CSS Health Insurance Annual Premium",
    "amount": 4500.00,
    "canton": "ZH"
  },
  {
    "name": "Pillar_3a_Certificate.pdf",
    "category": "deductions",
    "subcategory": "pillar_3a",
    "status": "approved",
    "taxYear": 2024,
    "aiConfidence": 0.97,
    "aiSummary": "Pillar 3a contribution certificate",
    "amount": 7056.00,
    "canton": "ZH"
  }
]
"""

print("📄 Test Documents JSON")
print("Copy this data and add it to Firestore Console:")
print("")
print("1. Go to Firebase Console → Firestore Database")
print("2. Create collection: 'documents'")
print("3. For each document below, click 'Add Document'")
print("4. Set customerId to your user ID")
print("5. Add uploadedAt timestamp (current time)")
print("6. Add storageUrl (any test URL)")
print("")
print(testDocuments)
