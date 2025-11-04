//
//  ChecklistService.swift
//  TaxedGmbH_IOS
//
//  Service to manage and persist expat checklist state
//

import Foundation
import Combine

@MainActor
class ChecklistService: ObservableObject {
    static let shared = ChecklistService()

    @Published var checkedItems: Set<String> = []
    @Published var completionPercentage: Double = 0.0

    private let userDefaults = UserDefaults.standard
    private let checkedItemsKey = "expatChecklist_checkedItems"

    // Total items in checklist
    let totalItems = 20

    init() {
        loadCheckedItems()
        updateCompletionPercentage()
    }

    // MARK: - Persistence

    /// Load checked items from UserDefaults
    private func loadCheckedItems() {
        if let savedItems = userDefaults.array(forKey: checkedItemsKey) as? [String] {
            checkedItems = Set(savedItems)
        }
    }

    /// Save checked items to UserDefaults
    private func saveCheckedItems() {
        userDefaults.set(Array(checkedItems), forKey: checkedItemsKey)
        updateCompletionPercentage()
    }

    // MARK: - Item Management

    /// Toggle a checklist item
    func toggleItem(_ itemId: String) {
        if checkedItems.contains(itemId) {
            checkedItems.remove(itemId)
        } else {
            checkedItems.insert(itemId)
        }
        saveCheckedItems()
    }

    /// Check if an item is checked
    func isItemChecked(_ itemId: String) -> Bool {
        return checkedItems.contains(itemId)
    }

    /// Get number of checked items
    var checkedCount: Int {
        return checkedItems.count
    }

    /// Update completion percentage
    private func updateCompletionPercentage() {
        completionPercentage = Double(checkedItems.count) / Double(totalItems)
    }

    /// Check if checklist is complete
    var isComplete: Bool {
        return checkedItems.count == totalItems
    }

    // MARK: - Reset

    /// Reset all checked items
    func resetChecklist() {
        checkedItems.removeAll()
        saveCheckedItems()
    }

    // MARK: - Firebase Sync (Optional - for future implementation)

    /// Sync checklist to Firebase (placeholder)
    func syncToFirebase(userId: String) async throws {
        // TODO: Implement Firebase sync
        // This would save the checklist state to Firestore
        // so it's accessible across devices
    }
}
