#!/usr/bin/env swift

import Foundation

// Script to create test documents via Firebase
let script = """
// Add test documents to Firestore for UI testing
// Run this in the Swift REPL or as a test

import FirebaseFirestore
import FirebaseAuth

func createTestDocuments() async {
    let db = Firestore.firestore()

    // Assuming user is logged in as "hello@test.com"
    guard let userId = Auth.auth().currentUser?.uid else {
        print("No user logged in")
        return
    }

    let documents = [
        [
            "customerId": userId,
            "name": "Lohnausweis_2024.pdf",
            "storageUrl": "https://example.com/doc1.pdf",
            "category": "income",
            "status": "pending",
            "taxYear": 2024,
            "amount": 85000.50,
            "aiConfidence": 0.95,
            "aiSummary": "Lohnausweis from employer XYZ AG",
            "uploadedAt": FieldValue.serverTimestamp()
        ],
        [
            "customerId": userId,
            "name": "Versicherungspolice_2024.pdf",
            "storageUrl": "https://example.com/doc2.pdf",
            "category": "deduction",
            "status": "pending",
            "taxYear": 2024,
            "amount": 2500.00,
            "aiConfidence": 0.87,
            "aiSummary": "Health insurance premium statement",
            "uploadedAt": FieldValue.serverTimestamp()
        ]
    ]

    for doc in documents {
        try await db.collection("documents").addDocument(data: doc)
    }

    print("Test documents created successfully")
}

// Call this function in your app
Task {
    await createTestDocuments()
}
"""

print(script)